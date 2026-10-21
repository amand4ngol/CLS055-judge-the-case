import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/tap_target.dart';
import 'medallion_parts.dart';

/// Blue "NEXT CASE" medallion with a gold "ENTER" pill: the case the player
/// can open now.
class NextCaseMedallion extends StatelessWidget {
  const NextCaseMedallion({super.key, this.onTap});

  static const double size = 120;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      label: 'Next case, enter',
      onTap: onTap,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.blue,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(38, 35, 29, 0.28),
                      offset: Offset(0, 8.46),
                      blurRadius: 10.34,
                    ),
                  ],
                ),
              ),
            ),
            const Positioned.fill(
              child: CustomPaint(
                painter: InsetBottomShadowPainter(
                  Color.fromRGBO(0, 0, 0, 0.13),
                  3.76,
                ),
              ),
            ),
            Positioned(
              top: 54,
              left: 1,
              right: 0,
              child: Text(
                'NEXT CASE',
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: AppTextStyles.medallionNextCase,
              ),
            ),
            const Positioned(left: 75, top: 83, child: _EnterPill()),
          ],
        ),
      ),
    );
  }
}

class _EnterPill extends StatelessWidget {
  const _EnterPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 39.48),
      padding: const EdgeInsets.symmetric(horizontal: 6.58, vertical: 4.7),
      decoration: BoxDecoration(
        color: AppColors.medallionGold,
        borderRadius: BorderRadius.circular(93.06),
        border: Border.all(color: AppColors.medallionEnterBorder, width: 2.617),
      ),
      child: Text(
        'ENTER',
        textAlign: TextAlign.center,
        style: AppTextStyles.medallionEnter,
      ),
    );
  }
}
