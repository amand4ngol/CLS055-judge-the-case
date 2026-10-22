import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';

/// "Cases statistics": cases judged, accuracy and best streak.
class StatsRow extends StatelessWidget {
  const StatsRow({super.key, required this.stats});

  final PlayerStats stats;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _tile('${stats.casesJudged}', 'CASES', AppColors.statCases),
        const SizedBox(width: 8),
        _tile(stats.accuracyLabel, 'ACCURACY', AppColors.statAccuracy),
        const SizedBox(width: 8),
        _tile(stats.bestStreakLabel, 'BEST STREAK', AppColors.statStreak),
      ],
    );
  }

  Widget _tile(String value, String label, Color color) {
    return Expanded(
      child: Container(
        height: 77,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.1),
              offset: Offset(0, 1),
              blurRadius: 1.5,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(value, style: AppTextStyles.statValue),
            const SizedBox(height: 8),
            Text(label, style: AppTextStyles.statLabel),
          ],
        ),
      ),
    );
  }
}
