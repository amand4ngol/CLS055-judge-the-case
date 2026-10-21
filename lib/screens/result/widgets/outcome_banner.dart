import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// "✗ INCORRECT VERDICT · The court disagrees." (or the correct version).
class OutcomeBanner extends StatelessWidget {
  const OutcomeBanner({super.key, required this.isCorrect});

  final bool isCorrect;

  @override
  Widget build(BuildContext context) {
    final color = isCorrect
        ? AppColors.resultCorrect
        : AppColors.resultIncorrect;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isCorrect
            ? AppColors.resultCorrectBackground
            : AppColors.resultIncorrectBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isCorrect
              ? AppColors.resultCorrectBorder
              : AppColors.resultIncorrectBorder,
          width: 0.624,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isCorrect ? '✓ CORRECT VERDICT' : '✗ INCORRECT VERDICT',
            style: AppTextStyles.resultOutcomeLabel.copyWith(color: color),
          ),
          const SizedBox(height: 4),
          Text(
            isCorrect ? 'The court agrees.' : 'The court disagrees.',
            style: AppTextStyles.resultOutcomeTitle,
          ),
        ],
      ),
    );
  }
}
