import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import 'case_section.dart';

/// "CASE SUMMARY" with the Short / Long toggle and the summary text.
class CaseSummarySection extends StatelessWidget {
  const CaseSummarySection({
    super.key,
    required this.shortSummary,
    required this.longSummary,
    required this.showLong,
    required this.onShowLongChanged,
  });

  final String shortSummary;
  final String longSummary;
  final bool showLong;
  final ValueChanged<bool> onShowLongChanged;

  @override
  Widget build(BuildContext context) {
    return CaseSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('CASE SUMMARY', style: AppTextStyles.caseSectionLabel),
              _SummaryToggle(showLong: showLong, onChanged: onShowLongChanged),
            ],
          ),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            alignment: Alignment.topCenter,
            child: Text(
              showLong ? longSummary : shortSummary,
              style: AppTextStyles.caseSummary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryToggle extends StatelessWidget {
  const _SummaryToggle({required this.showLong, required this.onChanged});

  final bool showLong;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.caseOutline, width: 0.696),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ToggleButton(
            label: 'SHORT',
            selected: !showLong,
            onTap: () => onChanged(false),
          ),
          _ToggleButton(
            label: 'LONG',
            selected: showLong,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          height: 24,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          alignment: Alignment.center,
          color: selected ? AppColors.brown : null,
          child: Text(
            label,
            style: selected
                ? AppTextStyles.caseToggleSelected
                : AppTextStyles.caseToggleIdle,
          ),
        ),
      ),
    );
  }
}
