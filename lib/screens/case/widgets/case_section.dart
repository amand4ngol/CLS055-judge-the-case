import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One block of the case screen, with the thin divider the design draws
/// above or below it.
class CaseSection extends StatelessWidget {
  const CaseSection({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(vertical: 20),
    this.dividerBelow = true,
    this.dividerAbove = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final bool dividerBelow;
  final bool dividerAbove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        border: Border(
          top: dividerAbove
              ? const BorderSide(
                  color: AppColors.caseRulingDivider,
                  width: 0.696,
                )
              : BorderSide.none,
          bottom: dividerBelow
              ? const BorderSide(color: AppColors.caseDivider, width: 0.696)
              : BorderSide.none,
        ),
      ),
      child: child,
    );
  }
}
