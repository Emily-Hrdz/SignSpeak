import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'face_landmark_service.dart';
import 'landmark_classifier_service.dart';
import 'landmark_dataset_service.dart';

class SpatialLandmarkClassifierService {
  List<double> _mean = const [];
  List<double> _scale = const [];
  List<List<double>> _samples = const [];
  List<String> _sampleLabels = const [];
  int _neighborCount = 5;
  double _noveltyThreshold = 0;

  bool get isInitialized => _samples.isNotEmpty;

  Future<void> initialize() async {
    if (isInitialized) return;
    final source = await rootBundle.loadString(
      'assets/models/spatial_landmark_classifier.json',
    );
    final model = jsonDecode(source) as Map<String, dynamic>;
    _mean = _doubleList(model['mean']);
    _scale = _doubleList(model['scale']);
    _samples = _matrix(model['samples']);
    _sampleLabels = _stringList(model['sampleLabels']);
    _neighborCount = (model['neighborCount'] as num).toInt();
    _noveltyThreshold = (model['noveltyThreshold'] as num).toDouble();

    if (_mean.length != 105 ||
        _scale.length != 105 ||
        _samples.length != _sampleLabels.length ||
        _samples.any((sample) => sample.length != 105) ||
        _neighborCount < 1 ||
        _noveltyThreshold <= 0) {
      throw const FormatException(
        'El modelo de reconocimiento espacial no es válido.',
      );
    }
  }

  LandmarkPrediction? predict(
    List<Landmark> landmarks,
    FaceReference? faceReference,
  ) {
    if (!isInitialized ||
        landmarks.length < 21 ||
        faceReference == null ||
        !faceReference.isFresh ||
        faceReference.bounds.width < 0.000001 ||
        faceReference.bounds.height < 0.000001) {
      return null;
    }

    final candidates = <_SpatialCandidate>[];
    for (final mirror in const [false, true]) {
      final shape = LandmarkDatasetService.normalize(
        landmarks.take(21).toList(),
        mirrorHorizontally: mirror,
      );
      final features = <double>[
        ...shape,
        for (final landmark in landmarks.take(21)) ...[
          (landmark.x - faceReference.bounds.left) / faceReference.bounds.width,
          (landmark.y - faceReference.bounds.top) / faceReference.bounds.height,
        ],
      ];
      final candidate = _predictFeatures(features);
      if (candidate != null) candidates.add(candidate);
    }
    if (candidates.isEmpty) return null;

    candidates.sort((first, second) {
      final distanceOrder = first.nearestDistance.compareTo(
        second.nearestDistance,
      );
      return distanceOrder != 0
          ? distanceOrder
          : second.prediction.confidence.compareTo(first.prediction.confidence);
    });
    return candidates.first.prediction;
  }

  _SpatialCandidate? _predictFeatures(List<double> features) {
    final standardized = List<double>.generate(
      features.length,
      (index) => (features[index] - _mean[index]) / _scale[index],
      growable: false,
    );
    final nearestDistances = <double>[];
    final nearestLabels = <String>[];

    for (var sampleIndex = 0; sampleIndex < _samples.length; sampleIndex++) {
      var squaredDistance = 0.0;
      final sample = _samples[sampleIndex];
      for (var index = 0; index < standardized.length; index++) {
        final difference = standardized[index] - sample[index];
        squaredDistance += difference * difference;
      }
      final distance = math.sqrt(squaredDistance);
      var insertionIndex = 0;
      while (insertionIndex < nearestDistances.length &&
          nearestDistances[insertionIndex] <= distance) {
        insertionIndex++;
      }
      if (insertionIndex < _neighborCount) {
        nearestDistances.insert(insertionIndex, distance);
        nearestLabels.insert(insertionIndex, _sampleLabels[sampleIndex]);
        if (nearestDistances.length > _neighborCount) {
          nearestDistances.removeLast();
          nearestLabels.removeLast();
        }
      }
    }

    if (nearestDistances.isEmpty ||
        nearestDistances.first > _noveltyThreshold) {
      return null;
    }
    final votes = <String, double>{};
    var totalWeight = 0.0;
    for (var index = 0; index < nearestDistances.length; index++) {
      final weight = 1 / math.max(nearestDistances[index], 0.000001);
      votes[nearestLabels[index]] = (votes[nearestLabels[index]] ?? 0) + weight;
      totalWeight += weight;
    }
    final winner = votes.entries.reduce(
      (first, second) => first.value >= second.value ? first : second,
    );
    return _SpatialCandidate(
      prediction: LandmarkPrediction(
        label: winner.key,
        confidence: winner.value / totalWeight,
      ),
      nearestDistance: nearestDistances.first,
    );
  }

  static List<String> _stringList(dynamic value) =>
      (value as List<dynamic>).map((item) => item.toString()).toList();

  static List<double> _doubleList(dynamic value) =>
      (value as List<dynamic>).map((item) => (item as num).toDouble()).toList();

  static List<List<double>> _matrix(dynamic value) =>
      (value as List<dynamic>).map((row) => _doubleList(row)).toList();
}

class _SpatialCandidate {
  const _SpatialCandidate({
    required this.prediction,
    required this.nearestDistance,
  });

  final LandmarkPrediction prediction;
  final double nearestDistance;
}
