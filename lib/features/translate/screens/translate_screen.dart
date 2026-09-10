import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:hand_landmarker/hand_landmarker.dart';

import '../../../core/widgets/gradient_background.dart';
import '../services/camera_service.dart';
import '../services/hand_landmarker_service.dart';
import '../services/landmark_classifier_service.dart';
import '../services/speech_service.dart';
import '../widgets/hand_landmark_overlay.dart';
import '../widgets/dataset_capture_sheet.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  final HandLandmarkerService _handLandmarker = HandLandmarkerService();
  final LandmarkClassifierService _classifier = LandmarkClassifierService();
  final SpeechService _speech = SpeechService();
  final TextEditingController _translationController = TextEditingController();
  final FocusNode _translationFocusNode = FocusNode();

  CameraController? _cameraController;
  List<Hand> _hands = const [];
  bool _isInitializing = true;
  bool _isProcessingFrame = false;
  bool _isDetectionPaused = false;
  String? _errorMessage;
  DateTime? _lastProcessedAt;
  final List<LandmarkPrediction> _predictionHistory = [];
  String? _stablePrediction;
  double _stableConfidence = 0;
  String? _lastCommittedPrediction;
  DateTime? _lastHandSeenAt;
  bool _isSpeaking = false;
  bool _isEditingTranslation = false;
  bool _resumeDetectionAfterEditing = false;

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
      await _classifier.initialize();

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

  void _updatePrediction(List<Hand> hands) {
    if (hands.length != 1 || hands.first.landmarks.length < 21) {
      final lastHandSeenAt = _lastHandSeenAt;
      if (lastHandSeenAt != null &&
          DateTime.now().difference(lastHandSeenAt) >
              const Duration(milliseconds: 700)) {
        _lastCommittedPrediction = null;
      }
      _predictionHistory.clear();
      _stablePrediction = null;
      _stableConfidence = 0;
      return;
    }

    _lastHandSeenAt = DateTime.now();

    final prediction = _classifier.predict(hands.first.landmarks);
    if (prediction == null || prediction.confidence < 0.60) {
      if (_predictionHistory.isNotEmpty) _predictionHistory.removeAt(0);
      _stablePrediction = null;
      _stableConfidence = 0;
      return;
    }

    _predictionHistory.add(prediction);
    if (_predictionHistory.length > 7) _predictionHistory.removeAt(0);

    final counts = <String, int>{};
    for (final item in _predictionHistory) {
      counts[item.label] = (counts[item.label] ?? 0) + 1;
    }
    final winner = counts.entries.reduce(
      (first, second) => first.value >= second.value ? first : second,
    );
    final winnerPredictions = _predictionHistory
        .where((item) => item.label == winner.key)
        .toList();
    final averageConfidence =
        winnerPredictions.fold<double>(
          0,
          (sum, item) => sum + item.confidence,
        ) /
        winnerPredictions.length;

    if (winner.value >= 5 && averageConfidence >= 0.72) {
      _stablePrediction = winner.key;
      _stableConfidence = averageConfidence;
      _commitPrediction(winner.key);
    } else {
      _stablePrediction = null;
      _stableConfidence = 0;
    }
  }

  void _commitPrediction(String label) {
    if (_lastCommittedPrediction == label) return;
    final updatedText = '${_translationController.text}$label';
    _translationController
      ..text = updatedText
      ..selection = TextSelection.collapsed(offset: updatedText.length);
    _lastCommittedPrediction = label;
  }

  void _addSpace() {
    final text = _translationController.text.trimRight();
    _translationController
      ..text = text.isEmpty ? '' : '$text '
      ..selection = TextSelection.collapsed(
        offset: text.isEmpty ? 0 : text.length + 1,
      );
    setState(() {});
  }

  void _removeLastCharacter() {
    final text = _translationController.text;
    if (text.isEmpty) return;
    final updatedText = text.substring(0, text.length - 1);
    _translationController
      ..text = updatedText
      ..selection = TextSelection.collapsed(offset: updatedText.length);
    setState(() {});
  }

  void _clearTranslation() {
    _translationController.clear();
    _lastCommittedPrediction = null;
    setState(() {});
  }

  Future<void> _speakTranslation() async {
    if (_translationController.text.trim().isEmpty || _isSpeaking) return;
    setState(() => _isSpeaking = true);
    try {
      await _speech.speak(_translationController.text);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudo reproducir la voz en este dispositivo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSpeaking = false);
    }
  }

  void _startTextEditing() {
    setState(() {
      _resumeDetectionAfterEditing = !_isDetectionPaused;
      _isEditingTranslation = true;
      _isDetectionPaused = true;
      _hands = const [];
      _predictionHistory.clear();
      _stablePrediction = null;
      _stableConfidence = 0;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _translationFocusNode.requestFocus();
    });
  }

  void _finishTextEditing() {
    _translationFocusNode.unfocus();
    setState(() {
      _isEditingTranslation = false;
      if (_resumeDetectionAfterEditing) _isDetectionPaused = false;
      _resumeDetectionAfterEditing = false;
    });
  }

  void _toggleTextEditing() {
    if (_isEditingTranslation) {
      _finishTextEditing();
    } else {
      _startTextEditing();
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

      if (mounted && !_isDetectionPaused) {
        _updatePrediction(hands);
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
      if (_isDetectionPaused) {
        _predictionHistory.clear();
        _stablePrediction = null;
        _stableConfidence = 0;
      }
    });
  }

  Future<void> _openDatasetCapture() async {
    if (_isDetectionPaused) {
      setState(() => _isDetectionPaused = false);
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DatasetCaptureSheet(handsProvider: () => _hands),
    );
  }

  @override
  void dispose() {
    final controller = _cameraController;
    if (controller?.value.isStreamingImages ?? false) {
      controller?.stopImageStream();
    }
    controller?.dispose();
    _handLandmarker.dispose();
    _speech.stop();
    _translationController.dispose();
    _translationFocusNode.dispose();
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
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
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
            AspectRatio(
              aspectRatio: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF080D17)
                          : const Color(0xFFC5D5EA),
                      offset: const Offset(0, 7),
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
                        if (_stablePrediction != null)
                          Positioned(
                            bottom: 14,
                            left: 14,
                            right: 14,
                            child: _RecognitionResult(
                              label: _stablePrediction!,
                              confidence: _stableConfidence,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Texto traducido',
                          style: TextStyle(fontWeight: FontWeight.w900),
                        ),
                      ),
                      IconButton.filled(
                        tooltip: 'Reproducir texto',
                        onPressed:
                            _translationController.text.trim().isEmpty ||
                                _isSpeaking
                            ? null
                            : _speakTranslation,
                        icon: _isSpeaking
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.volume_up_rounded),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        tooltip: _isDetectionPaused ? 'Reanudar' : 'Pausar',
                        onPressed: _isEditingTranslation
                            ? null
                            : _toggleDetection,
                        icon: Icon(
                          _isDetectionPaused ? Icons.play_arrow : Icons.pause,
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: _translationController,
                    focusNode: _translationFocusNode,
                    readOnly: !_isEditingTranslation,
                    showCursor: _isEditingTranslation,
                    minLines: 1,
                    maxLines: 2,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Las letras reconocidas aparecerán aquí',
                      helperText: _isEditingTranslation
                          ? 'Corrige el mensaje y pulsa Listo.'
                          : 'Toca el lápiz para editar manualmente.',
                      suffixIcon: IconButton(
                        tooltip: _isEditingTranslation
                            ? 'Finalizar edición'
                            : 'Editar texto',
                        onPressed: _toggleTextEditing,
                        icon: Icon(
                          _isEditingTranslation
                              ? Icons.check_circle_rounded
                              : Icons.edit_rounded,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      IconButton(
                        tooltip: 'Borrar último carácter',
                        onPressed: _translationController.text.isEmpty
                            ? null
                            : _removeLastCharacter,
                        icon: const Icon(Icons.backspace_outlined),
                      ),
                      TextButton.icon(
                        onPressed: _translationController.text.trim().isEmpty
                            ? null
                            : _addSpace,
                        icon: const Icon(Icons.space_bar_rounded),
                        label: const Text('Espacio'),
                      ),
                      IconButton(
                        tooltip: 'Limpiar texto',
                        onPressed: _translationController.text.isEmpty
                            ? null
                            : _clearTranslation,
                        icon: const Icon(Icons.delete_sweep_outlined),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _isEditingTranslation ? null : _openDatasetCapture,
                icon: const Icon(Icons.dataset_outlined),
                label: const Text('Crear muestras'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecognitionResult extends StatelessWidget {
  const _RecognitionResult({required this.label, required this.confidence});

  final String label;
  final double confidence;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Color(0xFF2563B8), offset: Offset(0, 5)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.translate_rounded, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '${(confidence * 100).round()}%',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w700,
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
