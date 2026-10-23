import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../providers/home_provider.dart';
import '../../../shared/widgets/snap_carousel.dart';
import 'case_column.dart';
import 'category_bar.dart';
import 'category_chip.dart';
import 'hidden_cases_notice.dart';
import 'swipe_hint.dart';

/// Everything below the hero: the category chips on the page background,
/// then the beige band with the swipeable case pillars.
///
class CasesSection extends StatelessWidget {
  const CasesSection({
    super.key,
    this.onCaseTap,
    this.categoriesKey,
    this.casesKey,
  });

  static const double backgroundTop = 100;
  static const double _backgroundHeight = 569;
  static const double height = backgroundTop + _backgroundHeight;

  final ValueChanged<CaseSlot>? onCaseTap;

  /// Mark the category chips and the case board for the first-time tour.
  final GlobalKey? categoriesKey;
  final GlobalKey? casesKey;

  @override
  Widget build(BuildContext context) {
    final home = context.watch<HomeProvider>();

    return Stack(
      children: [
        const Positioned(
          top: backgroundTop,
          left: 0,
          right: 0,
          bottom: 0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.sectionGradientTop,
                  AppColors.sectionGradientBottom,
                ],
              ),
            ),
          ),
        ),
        ...switch (home.status) {
          // Signed out only lasts until the account screens replace home.
          HomeStatus.loading || HomeStatus.signedOut => [
            const _InBackground(child: CircularProgressIndicator()),
          ],
          HomeStatus.error => [
            _InBackground(
              child: _Message(
                text: 'Could not load the cases.',
                actionLabel: 'Try again',
                onAction: home.load,
              ),
            ),
          ],
          HomeStatus.ready when home.categories.isEmpty => [
            const _InBackground(
              child: _Message(text: 'No cases published for your country yet.'),
            ),
          ],
          HomeStatus.ready => _board(home),
        },
      ],
    );
  }

  List<Widget> _board(HomeProvider home) {
    final onCaseTap = this.onCaseTap;
    return [
      Positioned(
        top: _CasesBoard.columnsTop,
        left: 0,
        right: 0,
        height: CaseColumn.height,
        key: casesKey,
        child: home.isLoadingCases
            ? const Center(child: CircularProgressIndicator())
            : home.isCategoryHidden
            ? Center(
                child: HiddenCasesNotice(
                  categoryLabel: home.selectedCategory!.label,
                  hidesSensitiveCases: home.hidesSensitiveCases,
                  onShowSensitiveCases: home.showSensitiveCases,
                ),
              )
            : _CasesBoard(cases: home.cases, home: home, onCaseTap: onCaseTap),
      ),
      // After the pillars, so the chips get taps where the two overlap.
      Positioned(
        top: 0,
        left: 0,
        right: 0,
        height: CategoryChip.height,
        key: categoriesKey,
        child: CategoryBar(
          categories: home.categories,
          selectedIndex: home.selectedCategoryIndex,
          onSelected: home.selectCategory,
        ),
      ),
      const Positioned(
        top: backgroundTop + 521,
        left: 0,
        right: 0,
        height: 68,
        child: SwipeHint(),
      ),
    ];
  }
}

/// The swipeable pillars of the selected category.
class _CasesBoard extends StatelessWidget {
  const _CasesBoard({required this.cases, required this.home, this.onCaseTap});

  /// The pillars start above the beige band so their capitals sit on its
  /// top edge
  static const double columnsTop = CasesSection.backgroundTop - 78.45;

  // Case columns are 170 wide with an 8 gap.
  static const double _caseSpacing = CaseColumn.width + 8;

  final List<CaseSlot> cases;
  final HomeProvider home;
  final ValueChanged<CaseSlot>? onCaseTap;

  @override
  Widget build(BuildContext context) {
    final onCaseTap = this.onCaseTap;
    return SnapCarousel(
      // A new list (new category, or refreshed after a verdict) rebuilds
      // the carousel on its next case.
      key: ObjectKey(cases),
      itemSpacing: _caseSpacing,
      itemCount: cases.length,
      initialIndex: home.focusedCaseIndex,
      itemBuilder: (context, i) => CaseColumn(
        slot: cases[i],
        onTap: onCaseTap == null ? null : () => onCaseTap(cases[i]),
      ),
    );
  }
}

/// Centers [child] in the beige band.
class _InBackground extends StatelessWidget {
  const _InBackground({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: CasesSection.backgroundTop,
      left: 0,
      right: 0,
      bottom: 0,
      child: Center(child: child),
    );
  }
}

/// Centered message with an optional button, for the empty and error states.
class _Message extends StatelessWidget {
  const _Message({required this.text, this.actionLabel, this.onAction});

  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final actionLabel = this.actionLabel;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, textAlign: TextAlign.center, style: AppTextStyles.body),
          if (actionLabel != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ],
        ],
      ),
    );
  }
}
