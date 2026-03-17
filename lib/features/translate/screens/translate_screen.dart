import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import '../../../core/utils/mediapipe_channel.dart';
import '../services/camera_service.dart';

class TranslateScreen extends StatefulWidget {
  const TranslateScreen({super.key});

  @override
  State<TranslateScreen> createState() => _TranslateScreenState();
}

class _TranslateScreenState extends State<TranslateScreen> {
  CameraController? controller;
  bool isLoading = true;
  bool isTestingNative = false;
  bool isDetectingHand = false;

  String statusText = 'Iniciando cámara...';
  String detectionText = 'MediaPipe aún no probado';
  String translatedWord = 'Hola';

  @override
  void initState() {
    super.initState();
    startCamera();
  }

  Future<void> startCamera() async {
    try {
      controller = await CameraService.initializeCamera();

      if (!mounted) return;

      setState(() {
        isLoading = false;
        statusText = 'Apunta la cámara al lenguaje de señas';
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
        statusText = 'No se pudo iniciar la cámara';
      });
    }
  }

  Future<void> testAndroidChannel() async {
    setState(() {
      isTestingNative = true;
      detectionText = 'Probando carga de MediaPipe...';
    });

    try {
      final result = await MediaPipeChannel.loadMediaPipe();

      if (!mounted) return;

      setState(() {
        detectionText = result;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        detectionText = 'Error al cargar MediaPipe: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar MediaPipe: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isTestingNative = false;
        });
      }
    }
  }

  Future<void> captureAndDetectHand() async {
    if (controller == null || !controller!.value.isInitialized) return;

    setState(() {
      isDetectingHand = true;
      detectionText = 'Capturando imagen...';
    });

    try {
      final XFile image = await controller!.takePicture();

      if (!mounted) return;

      setState(() {
        detectionText = 'Analizando mano con MediaPipe...';
      });

      final result = await MediaPipeChannel.detectHandFromImage(image.path);

      if (!mounted) return;

      String newWord = translatedWord;

      if (result.contains('Posible seña: Uno')) {
        newWord = 'Uno';
      } else if (result.contains('Posible seña: Dos')) {
        newWord = 'Dos';
      } else if (result.contains('Posible seña: Tres')) {
        newWord = 'Tres';
      } else if (result.contains('Posible seña: Cuatro')) {
        newWord = 'Cuatro';
      } else if (result.contains('Posible seña: Cinco')) {
        newWord = 'Cinco';
      } else if (result.contains('Posible seña: Puño')) {
        newWord = 'Puño';
      }

      setState(() {
        detectionText = result;
        translatedWord = newWord;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        detectionText = 'Error al detectar mano: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al detectar mano: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          isDetectingHand = false;
        });
      }
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (controller == null || !controller!.value.isInitialized) {
      return Center(
        child: Text(
          statusText,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    statusText,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    height: 420,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CameraPreview(controller!),
                        Positioned.fill(
                          child: Container(
                            color: Colors.black.withOpacity(0.08),
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 250,
                            height: 320,
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 16,
                          left: 16,
                          right: 16,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.55),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Coloca la mano dentro del recuadro',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isTestingNative ? null : testAndroidChannel,
                          icon: isTestingNative
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.memory),
                          label: Text(
                            isTestingNative
                                ? 'Cargando...'
                                : 'Probar MediaPipe',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: isDetectingHand ? null : captureAndDetectHand,
                          icon: isDetectingHand
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.pan_tool_alt),
                          label: Text(
                            isDetectingHand
                                ? 'Analizando...'
                                : 'Detectar mano',
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              elevation: 6,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.text_fields,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Traducción',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFFE1E8),
                              Color(0xFFDDFCF8),
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              translatedWord,
                              style: const TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFFF6B6B),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Seña detectada',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                detectionText,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}