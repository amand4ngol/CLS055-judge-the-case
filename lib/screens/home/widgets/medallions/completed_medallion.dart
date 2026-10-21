import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/tap_target.dart';
import 'medallion_parts.dart';

/// Gold medallion of a case the player already ruled on, with a check badge.
class CompletedMedallion extends StatelessWidget {
  const CompletedMedallion({
    super.key,
    required this.label,
    this.isPerfect = false,
    this.onTap,
  });

  /// "CASE 01"
  final String label;

  /// The player's verdict matched the court's.
  final bool isPerfect;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      label: '$label, ${isPerfect ? 'perfect' : 'completed'}',
      onTap: onTap,
      child: SizedBox.square(
        dimension: kMedallionSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(child: _GoldDisc()),
            const Positioned.fill(
              child: Padding(
                padding: EdgeInsets.all(kMedallionRing),
                child: CustomPaint(
                  painter: InsetBottomShadowPainter(
                    Color.fromRGBO(122, 89, 7, 0.17),
                    3.76,
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  kMedallionRing + 7.52,
                  kMedallionRing + 12.22,
                  kMedallionRing + 7.52,
                  kMedallionRing + 9.4,
                ),
                child: MedallionContent(
                  label: label,
                  labelStyle: AppTextStyles.medallionCompletedLabel,
                  icon: const MedallionIcon(
                    assetPath: AppAssets.caseIcon,
                    fallbackIcon: Icons.gavel,
                    fallbackColor: AppColors.medallionCompletedText,
                    box: Size.square(36.66),
                    offset: Offset(4.51, 5.27),
                    size: Size(30.70, 28.41),
                  ),
                ),
              ),
            ),
            const Positioned(left: 76.17, top: 68.67, child: _CheckBadge()),
          ],
        ),
      ),
    );
  }
}

class _GoldDisc extends StatelessWidget {
  const _GoldDisc();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.medallionGold,
        shape: BoxShape.circle,
        border: Border.fromBorderSide(
          BorderSide(color: AppColors.medallionGoldRing, width: kMedallionRing),
        ),
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(99, 75, 15, 0.3),
            offset: Offset(0, 8.46),
            blurRadius: 10.34,
          ),
        ],
      ),
    );
  }
}

class _CheckBadge extends StatelessWidget {
  const _CheckBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 25.38,
      height: 25.38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.medallionCheckBadge,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.cream, width: 3.271),
      ),
      child: const MedallionIcon(
        assetPath: AppAssets.check,
        fallbackIcon: Icons.check,
        fallbackColor: AppColors.white,
        box: Size.square(15.04),
        offset: Offset(2.58, 3.21),
        size: Size(9.89, 7.93),
      ),
    );
  }
}
