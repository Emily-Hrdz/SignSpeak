import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class HandLandmarkOverlay extends StatelessWidget {
  const HandLandmarkOverlay({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
    super.key,
  });

  final List<Hand> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _HandLandmarkPainter(
          hands: hands,
          previewSize: previewSize,
          lensDirection: lensDirection,
          sensorOrientation: sensorOrientation,
        ),
      ),
    );
  }
}

class _HandLandmarkPainter extends CustomPainter {
  const _HandLandmarkPainter({
    required this.hands,
    required this.previewSize,
    required this.lensDirection,
    required this.sensorOrientation,
  });

  final List<Hand> hands;
  final Size previewSize;
  final CameraLensDirection lensDirection;
  final int sensorOrientation;

  static const List<(int, int)> _connections = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (0, 5),
    (5, 6),
    (6, 7),
    (7, 8),
    (5, 9),
    (9, 10),
    (10, 11),
    (11, 12),
    (9, 13),
    (13, 14),
    (14, 15),
    (15, 16),
    (13, 17),
    (0, 17),
    (17, 18),
    (18, 19),
    (19, 20),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    if (previewSize.isEmpty || hands.isEmpty) return;

    final scale = size.width / previewSize.height;
    final pointPaint = Paint()
      ..color = const Color(0xFFFF6B6B)
      ..style = PaintingStyle.fill;
    final linePaint = Paint()
      ..color = const Color(0xFF63E6BE)
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 3 / scale;

    canvas.save();
    final center = Offset(size.width / 2, size.height / 2);
    canvas.translate(center.dx, center.dy);
    canvas.rotate(sensorOrientation * math.pi / 180);

    if (lensDirection == CameraLensDirection.front) {
      canvas.scale(-1, 1);
      canvas.rotate(math.pi);
    }

    canvas.scale(scale);

    for (final hand in hands) {
      if (hand.landmarks.length < 21) continue;

      Offset position(Landmark landmark) => Offset(
        (landmark.x - 0.5) * previewSize.width,
        (landmark.y - 0.5) * previewSize.height,
      );

      for (final connection in _connections) {
        canvas.drawLine(
          position(hand.landmarks[connection.$1]),
          position(hand.landmarks[connection.$2]),
          linePaint,
        );
      }

      for (final landmark in hand.landmarks) {
        canvas.drawCircle(position(landmark), 5 / scale, pointPaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _HandLandmarkPainter oldDelegate) {
    return oldDelegate.hands != hands ||
        oldDelegate.previewSize != previewSize ||
        oldDelegate.lensDirection != lensDirection ||
        oldDelegate.sensorOrientation != sensorOrientation;
  }
}
