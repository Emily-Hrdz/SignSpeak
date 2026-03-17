import 'package:camera/camera.dart';

class CameraService {
  static Future<CameraController> initializeCamera() async {
    final cameras = await availableCameras();

    final CameraDescription selectedCamera = cameras.firstWhere(
      (camera) => camera.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      selectedCamera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.yuv420,
    );

    await controller.initialize();

    return controller;
  }
}