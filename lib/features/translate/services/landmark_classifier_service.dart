import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import 'landmark_dataset_service.dart';

class LandmarkPrediction {
  const LandmarkPrediction({required this.label, required this.confidence});

  final String label;
  final double confidence;
}

class LandmarkClassifierService {
  List<String> _labels = const [];
  List<double> _mean = const [];
  List<double> _scale = const [];
  List<List<double>> _hiddenWeights = const [];
  List<double> _hiddenBias = const [];
  List<List<double>> _outputWeights = const [];
  List<double> _outputBias = const [];

  bool get isInitialized => _labels.isNotEmpty;

  Future<void> initialize() async {
    if (isInitialized) return;
    final source = await rootBundle.loadString(
      'assets/models/landmark_classifier.json',
    );
    final model = jsonDecode(source) as Map<String, dynamic>;
    _labels = _stringList(model['labels']);
    _mean = _doubleList(model['mean']);
    _scale = _doubleList(model['scale']);
    _hiddenWeights = _matrix(model['hiddenWeights']);
    _hiddenBias = _doubleList(model['hiddenBias']);
    _outputWeights = _matrix(model['outputWeights']);
    _outputBias = _doubleList(model['outputBias']);

    if (_mean.length != 63 ||
        _scale.length != 63 ||
        _hiddenWeights.length != 63 ||
        _outputBias.length != _labels.length) {
      throw const FormatException('El modelo de reconocimiento no es válido.');
    }
  }

  LandmarkPrediction? predict(List<Landmark> landmarks) {
    if (!isInitialized || landmarks.length < 21) return null;

    final normal = LandmarkDatasetService.normalize(
      landmarks.take(21).toList(),
    );
    final mirrored = LandmarkDatasetService.normalize(
      landmarks.take(21).toList(),
      mirrorHorizontally: true,
    );
    final normalPrediction = predictFeatures(normal);
    final mirroredPrediction = predictFeatures(mirrored);
    return normalPrediction.confidence >= mirroredPrediction.confidence
        ? normalPrediction
        : mirroredPrediction;
  }

  LandmarkPrediction predictFeatures(List<double> features) {
    if (!isInitialized || features.length != _mean.length) {
      throw StateError('El clasificador no está inicializado correctamente.');
    }

    final standardized = List<double>.generate(
      features.length,
      (index) => (features[index] - _mean[index]) / _scale[index],
      growable: false,
    );
    final hidden = List<double>.generate(_hiddenBias.length, (hiddenIndex) {
      var value = _hiddenBias[hiddenIndex];
      for (
        var featureIndex = 0;
        featureIndex < standardized.length;
        featureIndex++
      ) {
        value +=
            standardized[featureIndex] *
            _hiddenWeights[featureIndex][hiddenIndex];
      }
      return math.max(0, value);
    }, growable: false);

    final logits = List<double>.generate(_labels.length, (labelIndex) {
      var value = _outputBias[labelIndex];
      for (var hiddenIndex = 0; hiddenIndex < hidden.length; hiddenIndex++) {
        value += hidden[hiddenIndex] * _outputWeights[hiddenIndex][labelIndex];
      }
      return value;
    }, growable: false);

    final maxLogit = logits.reduce(math.max);
    final exponentials = logits
        .map((value) => math.exp(value - maxLogit))
        .toList();
    final total = exponentials.fold<double>(0, (sum, value) => sum + value);
    final probabilities = exponentials.map((value) => value / total).toList();
    var bestIndex = 0;
    for (var index = 1; index < probabilities.length; index++) {
      if (probabilities[index] > probabilities[bestIndex]) bestIndex = index;
    }
    return LandmarkPrediction(
      label: _labels[bestIndex],
      confidence: probabilities[bestIndex],
    );
  }

  static List<String> _stringList(dynamic value) =>
      (value as List<dynamic>).map((item) => item.toString()).toList();

  static List<double> _doubleList(dynamic value) =>
      (value as List<dynamic>).map((item) => (item as num).toDouble()).toList();

  static List<List<double>> _matrix(dynamic value) =>
      (value as List<dynamic>).map((row) => _doubleList(row)).toList();
}
