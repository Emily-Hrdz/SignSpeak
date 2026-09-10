import 'package:flutter/material.dart';

import '../../../data/models/sign_model.dart';

class CategoryFilterChip extends StatelessWidget {
  const CategoryFilterChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) => FilterChip(
    selected: selected,
    onSelected: (_) => onSelected(),
    avatar: Icon(icon, size: 18),
    label: Text(label),
    showCheckmark: false,
  );
}

IconData iconForCategory(SignCategory category) => switch (category) {
  SignCategory.alphabet => Icons.abc,
  SignCategory.numbers => Icons.pin_outlined,
  SignCategory.phrases => Icons.chat_bubble_outline,
};

Color colorForCategory(SignCategory category) => switch (category) {
  SignCategory.alphabet => const Color(0xFFFFC94D),
  SignCategory.numbers => const Color(0xFFFF8C4A),
  SignCategory.phrases => const Color(0xFF9B82F3),
};
