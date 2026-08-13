import '../../translate/services/hand_landmarker_service.dart';

class TranslatorController {
  final HandLandmarkerService _handService = HandLandmarkerService();

  Future<void> initialize() async {
    await _handService.initialize();
  }

  HandLandmarkerService get handService => _handService;

  Future<void> dispose() async {
    await _handService.dispose();
  }
}