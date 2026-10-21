import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models.dart';

class AchievementsGrid extends StatelessWidget {
  const AchievementsGrid({super.key, required this.player});

  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    const all = Achievement.values;
    // Rows of two cards that grow with their text (large text settings).
    return Column(
      children: [
        for (var i = 0; i < all.length; i += 2)
          Padding(
            padding: EdgeInsets.only(bottom: i + 2 < all.length ? 10 : 0),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _card(all[i])),
                  const SizedBox(width: 10),
                  Expanded(child: _card(all[i + 1])),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// How far the player is from a locked achievement: "2/10 cases".
  String _progress(Achievement achievement) {
    final stats = player.stats;
    String cases(int target) =>
        '${stats.casesJudged.clamp(0, target)}/$target cases';
    return switch (achievement) {
      Achievement.firstRuling => cases(1),
      Achievement.onARoll => '${stats.bestStreak.clamp(0, 3)}/3 in a row',
      // Accuracy only counts after a few cases (see the model).
      Achievement.sharpJudgment =>
        stats.casesJudged < Achievement.minCasesForAccuracy
            ? cases(Achievement.minCasesForAccuracy)
            : '${stats.accuracyLabel} accuracy',
      Achievement.casebook => cases(10),
      Achievement.caseScholar => cases(20),
      Achievement.courtRegular => cases(30),
      Achievement.seniorJurist => cases(40),
      Achievement.masterJudge => cases(50),
    };
  }

  Widget _card(Achievement achievement) {
    final unlockedAt = player.achievements[achievement];
    final unlocked = unlockedAt != null;
    // As in the design: the next four locked achievements are visible
    // goals, the later ones are almost hidden. Unlocked cards turn dark blue.
    final locked = Achievement.values.where((a) => !player.hasUnlocked(a));
    final isNextGoal = locked.take(4).contains(achievement);
    final opacity = unlocked ? 1.0 : (isNextGoal ? 0.9 : 0.1);
    return Opacity(
      opacity: opacity,
      child: Container(
        constraints: const BoxConstraints(minHeight: 112),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: unlocked ? AppColors.statCases : AppColors.achievementCard,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: AppColors.achievementCardBorder,
            width: 0.624,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.beige,
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.achievementBadgeBorder,
                  width: 0.624,
                ),
              ),
              child: Text(
                achievement.badge,
                style: AppTextStyles.achievementBadge,
              ),
            ),
            const SizedBox(height: 12),
            Text(achievement.title, style: AppTextStyles.achievementTitle),
            const SizedBox(height: 4),
            Text(
              achievement.description,
              style: AppTextStyles.achievementDescription,
            ),
            const SizedBox(height: 8),
            Text(
              unlocked
                  ? 'Unlocked ${Formatters.date(unlockedAt)}'
                  : _progress(achievement),
              style: AppTextStyles.achievementTitle.copyWith(fontSize: 10),
            ),
          ],
        ),
      ),
    );
  }
}
