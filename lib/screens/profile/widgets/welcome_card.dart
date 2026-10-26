import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';
import '../../../shared/widgets/tap_target.dart';
import 'ranks_dialog.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.player});

  final PlayerProfile player;

  @override
  Widget build(BuildContext context) {
    final progress = player.rankProgress;
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(30, 20, 10, 0.18),
            offset: Offset(0, 7),
            blurRadius: 14,
          ),
        ],
      ),
      child: Stack(
        children: [
          // The two thin circles in the top right corner.
          Positioned(right: -40, top: -48, child: _circle(128)),
          Positioned(right: 16, top: -24, child: _circle(96)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('WELCOME', style: AppTextStyles.profileWelcome),
                          const SizedBox(height: 4),
                          Text(
                            'Judge ${player.name}',
                            style: AppTextStyles.profileName,
                          ),
                          _RankButton(progress),
                        ],
                      ),
                    ),
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: AppColors.profileBadge,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color.fromRGBO(0, 0, 0, 0.1),
                            offset: Offset(0, 4),
                            blurRadius: 3,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox.square(
                        dimension: 32,
                        child: AppSvg(AppAssets.profileScales),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    progress.counterLabel,
                    style: AppTextStyles.profileCounter,
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.fraction,
                    minHeight: 6,
                    backgroundColor: AppColors.profileBarTrack,
                    color: AppColors.profileBarFill,
                  ),
                ),
                const SizedBox(height: 8),
                Text(progress.message, style: AppTextStyles.profileMilestone),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.profileCircle, width: 0.624),
      ),
    );
  }
}

/// "Rank: Court Clerk ⓘ"; opens the list of every rank.
class _RankButton extends StatelessWidget {
  const _RankButton(this.progress);

  final RankProgress progress;

  @override
  Widget build(BuildContext context) {
    // Its own semantics node, so it is not merged into the card's text.
    return Semantics(
      container: true,
      child: TapTarget(
        label: 'Rank: ${progress.rank.label}. Show all ranks',
        onTap: () => RanksDialog.show(context, progress),
        // The label above already says it; the text is not read twice.
        child: ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text.rich(
                  TextSpan(
                    text: 'Rank: ',
                    children: [
                      TextSpan(
                        text: progress.rank.label,
                        style: AppTextStyles.profileRankValue,
                      ),
                    ],
                  ),
                  style: AppTextStyles.profileRank,
                ),
              ),
              // 44x44: the minimum touch target on iOS.
              SizedBox.square(
                dimension: 44,
                child: Icon(
                  Icons.info_outline,
                  size: 22,
                  color: AppTextStyles.profileRank.color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
