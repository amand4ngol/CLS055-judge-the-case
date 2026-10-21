import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';

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

  Widget _row(PlayerRuling ruling) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => widget.onPreview(ruling),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 8),
        child: Row(
          children: [
            // Green when the player matched the court, red when not.
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: switch (ruling.isCorrect) {
                  true => AppColors.resultCorrect,
                  false => AppColors.resultIncorrect,
                  null => AppColors.previousCaseDot,
                },
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ruling.caseTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.previousCaseTitle,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${ruling.category.label} · ${ruling.year}',
                    style: AppTextStyles.previousCaseDetail,
                  ),
                ],
              ),
            ),
            Text('Preview', style: AppTextStyles.previousCaseAction),
          ],
        ),
      ),
    );
  }
}
