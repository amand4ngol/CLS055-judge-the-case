import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../settings/widgets/settings_dialog.dart';

/// Every rank of the game with the cases it takes, the player's own one
/// highlighted. Opened from the rank on the welcome card.
class RanksDialog extends StatelessWidget {
  const RanksDialog({super.key, required this.progress});

  final RankProgress progress;

  static Future<void> show(BuildContext context, RankProgress progress) =>
      showDialog<void>(
        context: context,
        builder: (_) => RanksDialog(progress: progress),
      );

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.beige,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Judge ranks', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(
              'Your rank goes up as you judge more cases.',
              style: AppTextStyles.settingsBody,
            ),
            const SizedBox(height: 20),
            for (final rank in JudgeRank.values)
              _RankRow(
                rank: rank,
                isCurrent: rank == progress.rank,
                isReached: progress.casesJudged >= rank.minCases,
              ),
            const SizedBox(height: 18),
            SettingsDialogButton(
              label: 'Close',
              color: AppColors.blue,
              textColor: AppColors.white,
              onTap: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({
    required this.rank,
    required this.isCurrent,
    required this.isReached,
  });

  final JudgeRank rank;
  final bool isCurrent;
  final bool isReached;

  @override
  Widget build(BuildContext context) {
    final color = isCurrent
        ? AppColors.white
        : isReached
        ? AppColors.textDark
        : AppColors.textSubtle;
    final cases = rank.minCases == 0
        ? 'From the start'
        : '${rank.minCases} cases';
    return MergeSemantics(
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isCurrent ? AppColors.blue : null,
          borderRadius: BorderRadius.circular(8),
          border: isCurrent
              ? null
              : Border.all(color: AppColors.argumentCardBorder),
        ),
        child: Row(
          children: [
            Icon(
              isReached ? Icons.check_circle_outline : Icons.lock_outline,
              size: 18,
              color: color,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    rank.label,
                    style: AppTextStyles.settingsItem.copyWith(color: color),
                  ),
                  Text(
                    isCurrent ? 'Your rank · $cases' : cases,
                    style: AppTextStyles.settingsItemDetail.copyWith(
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
