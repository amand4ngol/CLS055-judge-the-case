import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models.dart';
import '../../shared/widgets/app_svg.dart';
import '../../shared/widgets/primary_button.dart';
import '../profile/profile_screen.dart';
import '../result/result_screen.dart';
import '../result/widgets/result_header.dart';

/// "New achievement!", shown after the result screen for each achievement
/// the verdict just unlocked.
class AchievementScreen extends StatelessWidget {
  const AchievementScreen({
    super.key,
    required this.achievement,
    this.isLast = true,
  });

  /// Completes with [ResultAction.nextCase] when the player taps the button
  /// ("Continue" on all pages but the last), [ResultAction.home] with the
  /// home pillar, or null on back.
  static Route<ResultAction> route(
    Achievement achievement, {
    bool isLast = true,
  }) => MaterialPageRoute(
    builder: (context) =>
        AchievementScreen(achievement: achievement, isLast: isLast),
  );

  /// Shows [achievements] one page after another. Completes with
  /// [ResultAction.nextCase] only if the last page asked for the next case;
  /// leaving any page another way stops there and goes home.
  static Future<ResultAction> showAll(
    NavigatorState navigator,
    List<Achievement> achievements,
  ) async {
    for (final (i, achievement) in achievements.indexed) {
      final action = await navigator.push(
        route(achievement, isLast: i == achievements.length - 1),
      );
      if (action != ResultAction.nextCase) return ResultAction.home;
    }
    return ResultAction.nextCase;
  }

  final Achievement achievement;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            ResultHeader(
              onBack: () => Navigator.of(context).pop(ResultAction.home),
              onProfile: () =>
                  Navigator.of(context).push(ProfileScreen.route()),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 48, bottom: 24),
                child: Column(
                  children: [
                    Semantics(
                      header: true,
                      label: 'New achievement: ${achievement.title}',
                      excludeSemantics: true,
                      child: Column(
                        children: [
                          const _Banner(),
                          const SizedBox(height: 32),
                          _Badge(achievement.badge),
                          const SizedBox(height: 8),
                          _Bench(achievement.title),
                        ],
                      ),
                    ),
                    Container(height: 1, color: AppColors.textDark),
                    const SizedBox(height: 28),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        achievement.unlockMessage,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.achievementMessage,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 512),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: Column(
                    children: [
                      Text(
                        'Keep up the good work, Judge',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.achievementCheer,
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: isLast ? 'NEXT CASE →' : 'CONTINUE →',
                        height: 56,
                        labelStyle: AppTextStyles.resultNextCase,
                        onPressed: () =>
                            Navigator.of(context).pop(ResultAction.nextCase),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width blue band between two white lines.
class _Banner extends StatelessWidget {
  const _Banner();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: const BoxDecoration(
        border: Border.symmetric(
          horizontal: BorderSide(color: AppColors.white, width: 4),
        ),
        gradient: LinearGradient(
          colors: [
            AppColors.achievementBannerEdge,
            AppColors.statStreak,
            AppColors.achievementBannerEdge,
          ],
        ),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text('New achievement!', style: AppTextStyles.achievementBanner),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(this.badge);

  final String badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 125,
      height: 125,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.statAccuracy,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.white, width: 5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(badge, style: AppTextStyles.achievementBadgeLarge),
        ),
      ),
    );
  }
}

/// The judge's bench, with the achievement's title written left of the
/// gavel. The bench stands on the floor line drawn under it.
class _Bench extends StatelessWidget {
  const _Bench(this.title);

  final String title;

  // Size of judge_bench.svg; its desk top is at y = 49.
  static const _size = Size(264, 149);

  @override
  Widget build(BuildContext context) {
    return SizedBox.fromSize(
      size: _size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned.fill(
            child: AppSvg(AppAssets.judgeBench, excludeFromSemantics: true),
          ),
          // Left of the gavel, whose handle starts at x ≈ 178.
          Positioned(
            left: 12,
            width: 156,
            top: 6,
            height: 40,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomCenter,
              child: Text(title, style: AppTextStyles.achievementScreenTitle),
            ),
          ),
        ],
      ),
    );
  }
}
