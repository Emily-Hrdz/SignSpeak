import 'package:flutter/material.dart';

class ClaySurface extends StatelessWidget {
  const ClaySurface({
    required this.child,
    this.color,
    this.padding,
    this.borderRadius = 24,
    this.hardShadow = false,
    super.key,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final double borderRadius;
  final bool hardShadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surfaceColor =
        color ?? (isDark ? const Color(0xFF202B40) : const Color(0xFFF8FBFF));
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.82),
            offset: const Offset(-4, -4),
            blurRadius: 8,
          ),
          BoxShadow(
            color: isDark ? const Color(0xFF080D17) : const Color(0xFFC5D5EA),
            offset: const Offset(0, 6),
            blurRadius: hardShadow ? 0 : 10,
          ),
        ],
      ),
      child: child,
    );
  }
}

class ClayButton extends StatelessWidget {
  const ClayButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0xFF2563B8), offset: Offset(0, 6)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, color: Colors.white, size: 20),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
