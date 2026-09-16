import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';

class FaceReference {
  const FaceReference({
    required this.bounds,
    required this.landmarks,
    required this.capturedAt,
  });

  final Rect bounds;
  final Map<String, Offset> landmarks;
  final DateTime capturedAt;

  bool get isFresh =>
      DateTime.now().difference(capturedAt) < const Duration(milliseconds: 800);

  Map<String, Object> toJson() => {
    'bounds': [bounds.left, bounds.top, bounds.right, bounds.bottom],
    'landmarks': {
      for (final entry in landmarks.entries)
        entry.key: [entry.value.dx, entry.value.dy],
    },
  };
}

class FaceLandmarkService {
  FaceLandmarkService()
    : _detector = FaceDetector(
        options: FaceDetectorOptions(
          enableLandmarks: true,
          enableTracking: true,
          performanceMode: FaceDetectorMode.fast,
          minFaceSize: 0.18,
        ),
      );

  final FaceDetector _detector;

  Future<FaceReference?> detect(
    CameraImage image, {
    required int sensorOrientation,
  }) async {
    if (image.planes.length < 3) return null;

    final rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    if (rotation == null) return null;

    final input = InputImage.fromBytes(
      bytes: _toNv21(image),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: InputImageFormat.nv21,
        bytesPerRow: image.width,
      ),
    );
    final faces = await _detector.processImage(input);
    if (faces.isEmpty) return null;

    final face = faces.reduce((first, second) {
      final firstArea = first.boundingBox.width * first.boundingBox.height;
      final secondArea = second.boundingBox.width * second.boundingBox.height;
      return firstArea >= secondArea ? first : second;
    });
    final rotated = sensorOrientation == 90 || sensorOrientation == 270;
    final orientedWidth = (rotated ? image.height : image.width).toDouble();
    final orientedHeight = (rotated ? image.width : image.height).toDouble();

    double x(num value) => (value / orientedWidth).clamp(0.0, 1.0);
    double y(num value) => (value / orientedHeight).clamp(0.0, 1.0);

    const names = <FaceLandmarkType, String>{
      FaceLandmarkType.leftEye: 'leftEye',
      FaceLandmarkType.rightEye: 'rightEye',
      FaceLandmarkType.leftEar: 'leftEar',
      FaceLandmarkType.rightEar: 'rightEar',
      FaceLandmarkType.leftMouth: 'leftMouth',
      FaceLandmarkType.rightMouth: 'rightMouth',
      FaceLandmarkType.bottomMouth: 'bottomMouth',
      FaceLandmarkType.noseBase: 'noseBase',
    };
    final points = <String, Offset>{};
    for (final entry in names.entries) {
      final landmark = face.landmarks[entry.key];
      if (landmark != null) {
        points[entry.value] = Offset(
          x(landmark.position.x),
          y(landmark.position.y),
        );
      }
    }

    return FaceReference(
      bounds: Rect.fromLTRB(
        x(face.boundingBox.left),
        y(face.boundingBox.top),
        x(face.boundingBox.right),
        y(face.boundingBox.bottom),
      ),
      landmarks: points,
      capturedAt: DateTime.now(),
    );
  }

  Uint8List _toNv21(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final output = Uint8List(width * height + (width * height ~/ 2));
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];
    var outputIndex = 0;

    for (var row = 0; row < height; row++) {
      final rowStart = row * yPlane.bytesPerRow;
      for (var column = 0; column < width; column++) {
        output[outputIndex++] = yPlane.bytes[rowStart + column];
      }
    }

    final uvPixelStride = math.max(
      1,
      uPlane.bytesPerPixel ?? vPlane.bytesPerPixel ?? 1,
    );
    for (var row = 0; row < height ~/ 2; row++) {
      for (var column = 0; column < width ~/ 2; column++) {
        final uIndex = row * uPlane.bytesPerRow + column * uvPixelStride;
        final vIndex = row * vPlane.bytesPerRow + column * uvPixelStride;
        output[outputIndex++] = vPlane.bytes[vIndex];
        output[outputIndex++] = uPlane.bytes[uIndex];
      }
    }
    return output;
  }

  Future<void> dispose() => _detector.close();
}
