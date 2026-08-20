import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../../../core/widgets/gradient_background.dart';
import '../services/camera_service.dart';
import '../services/hand_landmarker_service.dart';
import '../widgets/hand_landmark_overlay.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final HandLandmarkerService _handLandmarker = HandLandmarkerService();

  CameraController? _cameraController;
  List<Hand> _hands = const [];
  bool _isInitializing = true;
  bool _isProcessingFrame = false;
  bool _isDetectionPaused = false;
  String? _errorMessage;
  DateTime? _lastProcessedAt;

  static const _minimumFrameInterval = Duration(milliseconds: 120);

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      final cameraController = await CameraService.initializeCamera();
      await _handLandmarker.initialize();

      if (!mounted) {
        await cameraController.dispose();
        await _handLandmarker.dispose();
        return;
      }

      _cameraController = cameraController;
      await cameraController.startImageStream(_processCameraImage);

      if (mounted) {
        setState(() => _isInitializing = false);
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _isInitializing = false;
          _errorMessage = 'No se pudo iniciar la detección: $error';
        });
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isProcessingFrame || _isDetectionPaused || !mounted) return;

    final now = DateTime.now();
    final lastProcessedAt = _lastProcessedAt;
    if (lastProcessedAt != null &&
        now.difference(lastProcessedAt) < _minimumFrameInterval) {
      return;
    }

    _isProcessingFrame = true;
    _lastProcessedAt = now;

    try {
      final controller = _cameraController;
      if (controller == null) return;

      final hands = _handLandmarker.detect(
        image,
        sensorOrientation: controller.description.sensorOrientation,
      );

      if (mounted) {
        setState(() {
          _hands = hands;
          _errorMessage = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Error al procesar la cámara: $error');
      }
    } finally {
      _isProcessingFrame = false;
    }
  }

  void _toggleDetection() {
    setState(() {
      _isDetectionPaused = !_isDetectionPaused;
      if (_isDetectionPaused) _hands = const [];
    });
  }

  @override
  void dispose() {
    final controller = _cameraController;
    if (controller?.value.isStreamingImages ?? false) {
      controller?.stopImageStream();
    }
    controller?.dispose();
    _handLandmarker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Center(child: CircularProgressIndicator());
    }

    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return _ErrorState(
        message: _errorMessage ?? 'La cámara no está disponible.',
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Traducción en vivo',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              'Coloca tus manos dentro de la cámara',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 14),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(
                        context,
                      ).colorScheme.shadow.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: ColoredBox(
                    color: Colors.black,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(controller),
                        if (!_isDetectionPaused)
                          HandLandmarkOverlay(
                            hands: _hands,
                            previewSize: controller.value.previewSize!,
                            lensDirection: controller.description.lensDirection,
                            sensorOrientation:
                                controller.description.sensorOrientation,
                          ),
                        Positioned(
                          top: 12,
                          left: 12,
                          right: 12,
                          child: _DetectionStatus(
                            isPaused: _isDetectionPaused,
                            handsCount: _hands.length,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (_errorMessage != null) ...[
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              const SizedBox(height: 10),
            ],
            GlassSurface(
              borderRadius: 20,
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _hands.isEmpty
                          ? 'Esperando una seña…'
                          : '${_hands.length} ${_hands.length == 1 ? 'mano localizada' : 'manos localizadas'}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: _toggleDetection,
                    icon: Icon(
                      _isDetectionPaused ? Icons.play_arrow : Icons.pause,
                    ),
                    label: Text(_isDetectionPaused ? 'Reanudar' : 'Pausar'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Seguimiento de manos activo · reconocimiento próximamente',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetectionStatus extends StatelessWidget {
  const _DetectionStatus({required this.isPaused, required this.handsCount});

  final bool isPaused;
  final int handsCount;

  @override
  Widget build(BuildContext context) {
    final text = isPaused
        ? 'Detección pausada'
        : handsCount == 0
        ? 'Coloca una mano frente a la cámara'
        : handsCount == 1
        ? '1 mano detectada'
        : '$handsCount manos detectadas';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(message, textAlign: TextAlign.center),
      ),
    );
  }
}
