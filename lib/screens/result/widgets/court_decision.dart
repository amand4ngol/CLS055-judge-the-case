import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// "ACTUAL SENTENCE" card with the sentence in quotes.
class ActualSentenceCard extends StatelessWidget {
  const ActualSentenceCard({super.key, required this.sentence});

  final String sentence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.argumentCard,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.resultCardBorder, width: 0.624),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ACTUAL SENTENCE', style: AppTextStyles.resultSectionLabel),
          const SizedBox(height: 8),
          Text('"$sentence"', style: AppTextStyles.resultSentence),
        ],
      ),
    );
  }
}

/// "WHY THE COURT DECIDED THIS" with a brown rule on the left.
class CourtReasoning extends StatelessWidget {
  const CourtReasoning({super.key, required this.reasoning});

  final String reasoning;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(left: 16),
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: AppColors.brown, width: 1.872)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY THE COURT DECIDED THIS',
            style: AppTextStyles.resultSectionLabel,
          ),
          const SizedBox(height: 8),
          Text(reasoning, style: AppTextStyles.resultReasoning),
        ],
      ),
    );
  }
}
