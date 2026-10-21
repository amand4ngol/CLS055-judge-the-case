import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// A crime category in the row above the cases. The selected one is a brown
/// pill, the others white rounded rectangles.
class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  static const double height = 56;

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: height,
          constraints: const BoxConstraints(minWidth: 90),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.brown : AppColors.chipIdleBackground,
            borderRadius: BorderRadius.circular(selected ? 100 : 8),
          ),
          child: Text(
            label,
            maxLines: 1,
            style: selected
                ? AppTextStyles.chipSelected
                : AppTextStyles.chipIdle,
          ),
        ),
      ),
    );
  }
}
