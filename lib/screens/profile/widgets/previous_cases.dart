import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';
import '../../../shared/widgets/tap_target.dart';

class PreviousCases extends StatefulWidget {
  const PreviousCases({
    super.key,
    required this.rulings,
    required this.onPreview,
  });

  /// Newest first.
  final List<PlayerRuling> rulings;
  final ValueChanged<PlayerRuling> onPreview;

  @override
  State<PreviousCases> createState() => _PreviousCasesState();
}

class _PreviousCasesState extends State<PreviousCases> {
  static const _shownAtFirst = 3;

  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final rulings = widget.rulings;
    if (rulings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Text(
          'No cases judged yet.',
          style: AppTextStyles.previousCaseAction,
        ),
      );
    }

    final shown = _showAll ? rulings : rulings.take(_shownAtFirst);
    return Column(
      children: [
        for (final ruling in shown) _row(ruling),
        if (rulings.length > _shownAtFirst)
          GestureDetector(
            onTap: () => setState(() => _showAll = !_showAll),
            child: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _showAll ? 'View Less' : 'View More',
                    style: AppTextStyles.previousCaseAction,
                  ),
                  RotatedBox(
                    quarterTurns: _showAll ? 2 : 0,
                    child: const SizedBox.square(
                      dimension: 24,
                      child: AppSvg(AppAssets.arrowDropDown),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  /// One button per case; tapping it opens the case's result.
  Widget _row(PlayerRuling ruling) {
    final outcome = switch (ruling.isCorrect) {
      true => 'correct verdict',
      false => 'incorrect verdict',
      null => 'not judged yet',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapTarget(
        label: '${ruling.caseTitle}, $outcome. Preview',
        onTap: () => widget.onPreview(ruling),
        child: ExcludeSemantics(
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.fromLTRB(27, 12, 16, 12),
            decoration: BoxDecoration(
              color: AppColors.previousCaseCard,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                CustomPaint(
                  size: const Size(5, 9),
                  painter: _TrianglePainter(switch (ruling.isCorrect) {
                    true => AppColors.previousCaseCorrect,
                    false => AppColors.previousCaseIncorrect,
                    null => AppColors.previousCaseDot,
                  }),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    ruling.caseTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.previousCaseTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small "▸" in front of a previous case, colored by its outcome.
class _TrianglePainter extends CustomPainter {
  const _TrianglePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..lineTo(size.width, size.height / 2)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_TrianglePainter oldDelegate) =>
      oldDelegate.color != color;
}
