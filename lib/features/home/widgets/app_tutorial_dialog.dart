import 'package:flutter/material.dart';

import '../../../core/widgets/clay_components.dart';

class AppTutorialDialog extends StatefulWidget {
  const AppTutorialDialog({super.key});

  @override
  State<AppTutorialDialog> createState() => _AppTutorialDialogState();
}

class _AppTutorialDialogState extends State<AppTutorialDialog> {
  final _controller = PageController();
  int _currentPage = 0;

  static const _pages = [
    _TutorialPage(
      icon: Icons.camera_alt_rounded,
      color: Color(0xFF4285F4),
      title: 'Traduce con la cámara',
      description:
          'Coloca una mano completa dentro de la cámara y mantén la seña estable mientras SignSpeak la reconoce.',
    ),
    _TutorialPage(
      icon: Icons.record_voice_over_rounded,
      color: Color(0xFFFF91AA),
      title: 'Convierte señas en voz',
      description:
          'Las letras aparecen en Texto traducido. Puedes corregirlas, agregar espacios y tocar el altavoz para escucharlas.',
    ),
    _TutorialPage(
      icon: Icons.menu_book_rounded,
      color: Color(0xFFFFC94D),
      title: 'Consulta el diccionario',
      description:
          'Busca letras, números y frases básicas de LENSEGUA. Cada entrada incluye video e instrucciones.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage == _pages.length - 1) {
      Navigator.pop(context, true);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return PopScope(
      canPop: false,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: ClaySurface(
            borderRadius: 28,
            padding: const EdgeInsets.all(22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Conoce SignSpeak',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Omitir'),
                    ),
                  ],
                ),
                SizedBox(
                  height: 270,
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (index) =>
                        setState(() => _currentPage = index),
                    itemBuilder: (context, index) {
                      final item = _pages[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 92,
                              height: 92,
                              decoration: BoxDecoration(
                                color: item.color,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.color.withValues(alpha: 0.38),
                                    offset: const Offset(0, 8),
                                    blurRadius: 12,
                                  ),
                                ],
                              ),
                              child: Icon(
                                item.icon,
                                color: Colors.white,
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 10),
                            Text(item.description, textAlign: TextAlign.center),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var index = 0; index < _pages.length; index++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? page.color
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 20),
                ClayButton(
                  label: _currentPage == _pages.length - 1
                      ? 'Comenzar'
                      : 'Siguiente',
                  icon: _currentPage == _pages.length - 1
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  onPressed: _next,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TutorialPage {
  const _TutorialPage({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;
}
