"""Train and export the small A-E landmark classifier used by SignSpeak."""

from __future__ import annotations

import argparse
import json
from pathlib import Path

import numpy as np
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix
from sklearn.neighbors import KNeighborsClassifier
from sklearn.pipeline import make_pipeline
from sklearn.preprocessing import StandardScaler
from sklearn.linear_model import LogisticRegression
from sklearn.neural_network import MLPClassifier


def load_dataset(path: Path) -> tuple[np.ndarray, np.ndarray, np.ndarray, np.ndarray]:
    rows = [json.loads(line) for line in path.read_text(encoding="utf-8").splitlines() if line.strip()]
    features = np.asarray([row["landmarks"] for row in rows], dtype=np.float64)
    labels = np.asarray([row["label"] for row in rows])
    hands = np.asarray([row["handSide"] for row in rows])
    timestamps = np.asarray([row["capturedAt"] for row in rows], dtype=np.int64)
    return features, labels, hands, timestamps


def chronological_split(
    labels: np.ndarray, hands: np.ndarray, timestamps: np.ndarray
) -> tuple[np.ndarray, np.ndarray]:
    train_indices: list[int] = []
    test_indices: list[int] = []
    for label in sorted(set(labels)):
        for hand in sorted(set(hands)):
            indices = np.flatnonzero((labels == label) & (hands == hand))
            if len(indices) == 0:
                continue
            ordered = indices[np.argsort(timestamps[indices])]
            test_size = max(1, round(len(ordered) * 0.2))
            train_indices.extend(ordered[:-test_size])
            test_indices.extend(ordered[-test_size:])
    return np.asarray(train_indices), np.asarray(test_indices)


def evaluate(name: str, model, x_train, y_train, x_test, y_test) -> float:
    model.fit(x_train, y_train)
    predictions = model.predict(x_test)
    accuracy = accuracy_score(y_test, predictions)
    print(f"\n{name}: accuracy={accuracy:.4f}")
    print(confusion_matrix(y_test, predictions, labels=sorted(set(y_test))))
    print(classification_report(y_test, predictions, digits=3, zero_division=0))
    return accuracy


def export_mlp(model, output: Path, sample_count: int, validation_accuracy: float) -> None:
    scaler: StandardScaler = model.named_steps["standardscaler"]
    classifier: MLPClassifier = model.named_steps["mlpclassifier"]
    payload = {
        "version": 1,
        "modelType": "standard_scaler_mlp_relu_softmax",
        "labels": classifier.classes_.tolist(),
        "featureCount": int(classifier.n_features_in_),
        "sampleCount": sample_count,
        "validationAccuracy": round(validation_accuracy, 6),
        "mean": scaler.mean_.round(10).tolist(),
        "scale": scaler.scale_.round(10).tolist(),
        "hiddenWeights": classifier.coefs_[0].round(10).tolist(),
        "hiddenBias": classifier.intercepts_[0].round(10).tolist(),
        "outputWeights": classifier.coefs_[1].round(10).tolist(),
        "outputBias": classifier.intercepts_[1].round(10).tolist(),
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps(payload, separators=(",", ":")), encoding="utf-8")
    print(f"Exported model to {output} ({output.stat().st_size} bytes)")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("dataset", type=Path)
    parser.add_argument("--output", type=Path)
    args = parser.parse_args()

    features, labels, hands, timestamps = load_dataset(args.dataset)
    train_indices, test_indices = chronological_split(labels, hands, timestamps)
    x_train, x_test = features[train_indices], features[test_indices]
    y_train, y_test = labels[train_indices], labels[test_indices]
    print(f"samples={len(labels)} train={len(train_indices)} test={len(test_indices)}")

    candidates = {
        "logistic": make_pipeline(
            StandardScaler(),
            LogisticRegression(max_iter=3000, C=2.0, random_state=42),
        ),
        "knn": make_pipeline(StandardScaler(), KNeighborsClassifier(n_neighbors=5, weights="distance")),
        "mlp": make_pipeline(
            StandardScaler(),
            MLPClassifier(
                hidden_layer_sizes=(32,),
                activation="relu",
                alpha=0.001,
                max_iter=3000,
                random_state=42,
            ),
        ),
    }
    scores = {
        name: evaluate(name, model, x_train, y_train, x_test, y_test)
        for name, model in candidates.items()
    }

    if args.output:
        selected = candidates["mlp"]
        selected.fit(features, labels)
        export_mlp(selected, args.output, len(labels), scores["mlp"])


if __name__ == "__main__":
    main()
