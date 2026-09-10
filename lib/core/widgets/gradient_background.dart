import 'package:flutter/material.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: isDark ? const Color(0xFF121A2A) : const Color(0xFFEEF4FF),
      child: child,
    );
  }
}

class GlassSurface extends StatelessWidget {
  const GlassSurface({
    required this.child,
    this.padding,
    this.borderRadius = 24,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF202B40) : const Color(0xFFF8FBFF),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.95),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: isDark ? const Color(0xFF080D17) : const Color(0xFFC5D5EA),
            offset: const Offset(0, 6),
            blurRadius: 0,
          ),
        ],
      ),
      child: child,
    );
  }
}
