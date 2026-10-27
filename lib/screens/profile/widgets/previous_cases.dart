import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/tap_target.dart';

/// The newest previous cases on the profile, and "View More" to open the
/// page with all of them.
class PreviousCases extends StatelessWidget {
  const PreviousCases({
    super.key,
    required this.rulings,
    required this.onPreview,
    required this.onViewAll,
  });

  static const shownOnProfile = 3;

  /// Newest first.
  final List<PlayerRuling> rulings;
  final ValueChanged<PlayerRuling> onPreview;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    if (rulings.isEmpty) return const NoPreviousCases();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final ruling in rulings.take(shownOnProfile))
          PreviousCaseButton(ruling, onTap: () => onPreview(ruling)),
        if (rulings.length > shownOnProfile) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: _ViewMoreButton(onPressed: onViewAll),
          ),
        ],
      ],
    );
  }
}

/// Small blue "View More →" button, as wide as its label.
class _ViewMoreButton extends StatelessWidget {
  const _ViewMoreButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'View More',
      excludeSemantics: true,
      child: Material(
        color: AppColors.blue,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: ConstrainedBox(
            // 44: the minimum touch target on iOS.
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View More', style: AppTextStyles.viewMoreButton),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.arrow_forward,
                    size: 18,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class NoPreviousCases extends StatelessWidget {
  const NoPreviousCases({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Text(
        'No cases judged yet.',
        style: AppTextStyles.previousCaseAction,
      ),
    );
  }
}

/// One previous case; tapping it opens the case's result.
class PreviousCaseButton extends StatelessWidget {
  const PreviousCaseButton(this.ruling, {super.key, required this.onTap});

  final PlayerRuling ruling;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final outcome = switch (ruling.isCorrect) {
      true => 'correct verdict',
      false => 'incorrect verdict',
      null => 'not judged yet',
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapTarget(
        label:
            '${ruling.caseTitle}, ${ruling.category.label} ${ruling.year}, '
            '$outcome. Preview',
        onTap: onTap,
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
