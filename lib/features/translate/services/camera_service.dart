import 'package:camera/camera.dart';

class CameraService {

  static Future<CameraController> initializeCamera() async {

    final cameras = await availableCameras();

    final camera = cameras.first;

    final controller = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await controller.initialize();

    return controller;
  }
}