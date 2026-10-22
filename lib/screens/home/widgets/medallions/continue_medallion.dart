import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/tap_target.dart';
import 'medallion_parts.dart';

/// Blue "CONTINUE" medallion of a case the player opened but has not ruled
/// on, with a white ring showing how far they got.
class ContinueMedallion extends StatelessWidget {
  const ContinueMedallion({super.key, required this.progress, this.onTap});

  static const double size = 100;

  /// The ring is wider than the disc and centred on it.
  static const double ringSize = 122;

  /// 0 to 1, the ruling's progress.
  final double progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const ringOffset = (size - ringSize) / 2;
    return TapTarget(
      label: 'Continue case, ${(progress * 100).round()}% done',
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
              left: ringOffset,
              top: ringOffset,
              width: ringSize,
              height: ringSize,
              child: CustomPaint(painter: _ProgressRingPainter(progress)),
            ),
            Center(
              child: Text(
                'CONTINUE',
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: AppTextStyles.medallionContinue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// White arc clockwise from the top over a faint track.
class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter(this.progress);

  static const double _stroke = 11;

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = (Offset.zero & size).deflate(_stroke / 2);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      rect,
      0,
      2 * pi,
      false,
      paint..color = AppColors.white.withValues(alpha: 0.35),
    );
    final value = progress.clamp(0.0, 1.0);
    if (value == 0) return;
    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * value,
      false,
      paint..color = AppColors.white,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) => old.progress != progress;
}
