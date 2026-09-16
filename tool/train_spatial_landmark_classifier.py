"""Train and export the spatial G-I KNN classifier used by SignSpeak."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np


def build_features(row: dict) -> list[float]:
    shape = [float(value) for value in row["landmarks"]]
    image_landmarks = row["imageLandmarks"]
    left, top, right, bottom = row["face"]["bounds"]
    width = max(float(right) - float(left), 1e-6)
    height = max(float(bottom) - float(top), 1e-6)
    position: list[float] = []
    for index in range(0, len(image_landmarks), 2):
        position.extend(
            [
                (float(image_landmarks[index]) - float(left)) / width,
                (float(image_landmarks[index + 1]) - float(top)) / height,
            ]
        )
    return shape + position


def chronological_split(labels: np.ndarray, hands: np.ndarray, timestamps: np.ndarray):
    train_indices: list[int] = []
    test_indices: list[int] = []
    for label in sorted(set(labels)):
        for hand in sorted(set(hands)):
            indices = np.flatnonzero((labels == label) & (hands == hand))
            ordered = indices[np.argsort(timestamps[indices])]
            test_size = max(1, round(len(ordered) * 0.2))
            train_indices.extend(ordered[:-test_size])
            test_indices.extend(ordered[-test_size:])
    return np.asarray(train_indices), np.asarray(test_indices)


def nearest_neighbors(train: np.ndarray, query: np.ndarray, count: int = 5):
    distances = np.linalg.norm(train - query, axis=1)
    return np.argsort(distances)[:count], distances


def predict(train: np.ndarray, labels: np.ndarray, query: np.ndarray) -> str:
    indices, distances = nearest_neighbors(train, query)
    votes: dict[str, float] = {}
    for index in indices:
        label = str(labels[index])
        votes[label] = votes.get(label, 0.0) + 1.0 / max(float(distances[index]), 1e-6)
    return max(votes, key=votes.get)


def novelty_threshold(features: np.ndarray, labels: np.ndarray) -> float:
    nearest_same_label: list[float] = []
    for index, sample in enumerate(features):
        distances = np.linalg.norm(features - sample, axis=1)
        distances[index] = np.inf
        distances[labels != labels[index]] = np.inf
        nearest_same_label.append(float(np.min(distances)))
    # A small margin keeps natural variation while rejecting unfamiliar hand shapes.
    return float(np.percentile(nearest_same_label, 99) * 1.15)


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("datasets", type=Path, nargs="+")
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()

    rows = []
    for dataset in args.datasets:
        rows.extend(
            row
            for line in dataset.read_text(encoding="utf-8").splitlines()
            if line.strip()
            if (row := json.loads(line)).get("version") == 2
        )
    features = np.asarray([build_features(row) for row in rows], dtype=np.float64)
    labels = np.asarray([row["label"] for row in rows])
    hands = np.asarray([row["handSide"] for row in rows])
    timestamps = np.asarray([row["capturedAt"] for row in rows], dtype=np.int64)

    train_indices, test_indices = chronological_split(labels, hands, timestamps)
    mean = features[train_indices].mean(axis=0)
    scale = features[train_indices].std(axis=0)
    scale[scale < 1e-8] = 1.0
    train = (features[train_indices] - mean) / scale
    test = (features[test_indices] - mean) / scale
    predictions = [predict(train, labels[train_indices], sample) for sample in test]
    accuracy = float(np.mean(np.asarray(predictions) == labels[test_indices]))

    # The exported reference set includes every sample after validation.
    final_mean = features.mean(axis=0)
    final_scale = features.std(axis=0)
    final_scale[final_scale < 1e-8] = 1.0
    standardized = (features - final_mean) / final_scale
    threshold = novelty_threshold(standardized, labels)
    payload = {
        "version": 1,
        "modelType": "standard_scaler_knn_spatial",
        "labels": sorted(set(labels.tolist())),
        "featureCount": int(features.shape[1]),
        "sampleCount": int(features.shape[0]),
        "validationAccuracy": round(accuracy, 6),
        "neighborCount": 5,
        "noveltyThreshold": round(threshold, 6),
        "mean": final_mean.round(9).tolist(),
        "scale": final_scale.round(9).tolist(),
        "samples": standardized.round(6).tolist(),
        "sampleLabels": labels.tolist(),
    }
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")
    print(
        f"samples={len(labels)} train={len(train_indices)} test={len(test_indices)} "
        f"accuracy={accuracy:.4f} noveltyThreshold={threshold:.4f}"
    )
    print(f"Exported model to {args.output} ({args.output.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
