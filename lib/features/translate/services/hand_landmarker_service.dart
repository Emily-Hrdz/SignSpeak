import 'package:camera/camera.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

class HandLandmarkerService {
  HandLandmarkerPlugin? _landmarker;

  bool get isInitialized => _landmarker != null;

  Future<void> initialize() async {
    if (_landmarker != null) return;

    _landmarker = HandLandmarkerPlugin.create(
      numHands: 2,
      minHandDetectionConfidence: 0.65,
      delegate: HandLandmarkerDelegate.gpu,
    );
  }

  List<Hand> detect(CameraImage image, {required int sensorOrientation}) {
    final landmarker = _landmarker;
    if (landmarker == null) return const [];

    return landmarker.detect(image, sensorOrientation);
  }

  Future<void> dispose() async {
    _landmarker?.dispose();
    _landmarker = null;
  }
}
