import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class DatasetStats {
  const DatasetStats({required this.total, required this.byLabel});

  final int total;
  final Map<String, int> byLabel;
}

class LandmarkDatasetService {
  static const _channel = MethodChannel('signspeak/mediapipe');

  Future<int> saveSample({
    required String label,
    required String handSide,
    required List<Landmark> landmarks,
  }) async {
    if (landmarks.length < 21) {
      throw ArgumentError('Se requieren los 21 puntos de la mano.');
    }

    final normalized = normalize(
      landmarks.take(21).toList(),
      mirrorHorizontally: handSide == 'Izquierda',
    );
    final count = await _channel.invokeMethod<int>('appendDatasetSample', {
      'label': label.trim().toUpperCase(),
      'handSide': handSide,
      'landmarks': normalized,
    });
    return count ?? 0;
  }

  Future<DatasetStats> getStats() async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'getDatasetStats',
    );
    final labels = <String, int>{};
    final rawLabels = response?['labels'];
    if (rawLabels is Map) {
      for (final entry in rawLabels.entries) {
        labels[entry.key.toString()] = (entry.value as num).toInt();
      }
    }
    return DatasetStats(
      total: (response?['total'] as num?)?.toInt() ?? 0,
      byLabel: labels,
    );
  }

  Future<void> clear() => _channel.invokeMethod<void>('clearDataset');

  Future<String?> deleteLastSample() async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'deleteLastDatasetSample',
    );
    return response?['label']?.toString();
  }

  Future<int> deleteSamplesForLabel(String label) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'deleteDatasetSamplesForLabel',
      {'label': label.trim().toUpperCase()},
    );
    return (response?['removed'] as num?)?.toInt() ?? 0;
  }

  Future<String> export() async {
    final path = await _channel.invokeMethod<String>('exportDataset');
    return path ?? 'Descargas/SignSpeak';
  }

  static List<double> normalize(
    List<Landmark> landmarks, {
    bool mirrorHorizontally = false,
  }) {
    final wrist = landmarks.first;
    final translated = landmarks.map((landmark) {
      final x = landmark.x - wrist.x;
      return (
        x: mirrorHorizontally ? -x : x,
        y: landmark.y - wrist.y,
        z: landmark.z - wrist.z,
      );
    }).toList();

    var scale = 0.0;
    for (final point in translated) {
      scale = math.max(
        scale,
        math.sqrt(point.x * point.x + point.y * point.y + point.z * point.z),
      );
    }
    if (scale < 0.000001) scale = 1;

    return [
      for (final point in translated) ...[
        point.x / scale,
        point.y / scale,
        point.z / scale,
      ],
    ];
  }
}
