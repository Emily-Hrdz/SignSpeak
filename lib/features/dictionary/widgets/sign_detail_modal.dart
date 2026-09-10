import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/widgets/gradient_background.dart';
import '../../../core/widgets/clay_components.dart';
import '../../../data/models/sign_model.dart';
import 'category_chip.dart';

class SignDetailScreen extends StatefulWidget {
  const SignDetailScreen({required this.sign, super.key});
  final SignModel sign;

  @override
  State<SignDetailScreen> createState() => _SignDetailScreenState();
}

class _SignDetailScreenState extends State<SignDetailScreen> {
  late final VideoPlayerController _controller;
  late final Future<void> _initialization;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.asset(widget.sign.videoAsset);
    _initialization = _controller.initialize().then((_) {
      _controller
        ..setLooping(true)
        ..play();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    setState(
      () => _controller.value.isPlaying
          ? _controller.pause()
          : _controller.play(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sign = widget.sign;
    final color = colorForCategory(sign.category);
    return Scaffold(
      appBar: AppBar(title: Text(sign.name)),
      backgroundColor: Colors.transparent,
      body: GradientBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(18),
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: ColoredBox(
                  color: Colors.black,
                  child: AspectRatio(
                    aspectRatio: 9 / 16,
                    child: FutureBuilder<void>(
                      future: _initialization,
                      builder: (context, snapshot) {
                        if (snapshot.hasError) {
                          return const Center(
                            child: Text(
                              'No se pudo reproducir el video.',
                              style: TextStyle(color: Colors.white),
                            ),
                          );
                        }
                        if (snapshot.connectionState != ConnectionState.done) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        return GestureDetector(
                          onTap: _togglePlayback,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Center(
                                child: AspectRatio(
                                  aspectRatio: _controller.value.aspectRatio,
                                  child: VideoPlayer(_controller),
                                ),
                              ),
                              if (!_controller.value.isPlaying)
                                const Center(
                                  child: Icon(
                                    Icons.play_circle_fill,
                                    color: Colors.white,
                                    size: 72,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(iconForCategory(sign.category), color: color),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sign.name,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        Text(sign.category.label),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Cómo realizar la seña',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(sign.instructions),
              const SizedBox(height: 18),
              ClaySurface(
                borderRadius: 18,
                padding: const EdgeInsets.all(14),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.tips_and_updates_outlined),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Toca el video para pausarlo o reproducirlo. La demostración se repite automáticamente.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
