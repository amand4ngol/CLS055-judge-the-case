import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/app_svg.dart';
import '../../../../shared/widgets/tap_target.dart';
import 'medallion_parts.dart';

/// Frosted medallion with a bookmark, for a case the player already ruled on:
/// gold if the verdict matched the court's, grey otherwise.
class CompletedMedallion extends StatelessWidget {
  const CompletedMedallion({
    super.key,
    required this.label,
    this.isPerfect = false,
    this.onTap,
  });

  /// "CASE 01", read by screen readers only.
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
          children: [
            Positioned.fill(
              child: _Disc(
                color: isPerfect
                    ? AppColors.medallionCorrect
                    : AppColors.medallionIncorrect,
              ),
            ),
            const Positioned.fill(
              child: CustomPaint(
                painter: InsetBottomShadowPainter(
                  AppColors.medallionCompletedShadow,
                  3.76,
                ),
              ),
            ),
            const Center(
              child: SizedBox(
                width: 27.6,
                height: 37.5,
                child: AppSvg(
                  AppAssets.bookmark,
                  excludeFromSemantics: true,
                  fallback: FittedBox(
                    child: Icon(Icons.bookmark_border, color: AppColors.white),
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

class _Disc extends StatelessWidget {
  const _Disc({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    // Frosted glass: the translucent fill sits on a blur of the pillar behind.
    return ClipOval(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: ColoredBox(color: color),
      ),
    );
  }
}
