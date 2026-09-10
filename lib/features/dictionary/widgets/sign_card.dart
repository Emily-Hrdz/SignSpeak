import 'package:flutter/material.dart';

import '../../../data/models/sign_model.dart';
import '../../../core/widgets/clay_components.dart';
import 'category_chip.dart';

class SignCard extends StatelessWidget {
  const SignCard({required this.sign, required this.onTap, super.key});

  final SignModel sign;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = colorForCategory(sign.category);
    return ClaySurface(
      borderRadius: 20,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(iconForCategory(sign.category), color: color),
                    ),
                    Icon(Icons.play_circle_fill, color: color, size: 28),
                  ],
                ),
                const Spacer(),
                Text(
                  sign.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  sign.category.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
