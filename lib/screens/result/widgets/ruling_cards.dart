import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models.dart';

class RulingCards extends StatelessWidget {
  const RulingCards({super.key, required this.comparison});

  final RulingComparison comparison;

  @override
  Widget build(BuildContext context) {
    final court = comparison.court;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _RulingCard(
              label: 'YOU RULED',
              value: describeVerdict(
                comparison.player.sortedOptions,
                fineEur: comparison.player.fineEur,
                prisonMonths: comparison.player.prisonMonths,
              ),
              valueColor: comparison.isCorrect
                  ? AppColors.resultCorrect
                  : AppColors.resultIncorrect,
              background: AppColors.argumentCard,
              border: AppColors.resultCardBorder,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _RulingCard(
              label: 'COURT RULED',
              value: describeVerdict(
                VerdictOption.values.where(court.courtRuled.contains),
                fineEur: court.sentence.fineEur,
                prisonMonths: court.sentence.prisonMonths,
              ),
              valueColor: AppColors.brown,
              background: AppColors.resultCourtCard,
              border: AppColors.resultCourtCardBorder,
            ),
          ),
        ],
      ),
    );
  }

  /// "Fine 36,500 €, Prison 49 months, Probation"
  @visibleForTesting
  static String describeVerdict(
    Iterable<VerdictOption> options, {
    double? fineEur,
    double? prisonMonths,
  }) {
    final parts = [
      for (final option in options)
        switch (option) {
          VerdictOption.fine when fineEur != null =>
            '${option.label} ${Formatters.euro(fineEur)}',
          VerdictOption.prison when prisonMonths != null =>
            '${option.label} ${Formatters.months(prisonMonths)}',
          _ => option.label,
        },
    ];
    return parts.isEmpty ? '—' : parts.join(', ');
  }
}

class _RulingCard extends StatelessWidget {
  const _RulingCard({
    required this.label,
    required this.value,
    required this.valueColor,
    required this.background,
    required this.border,
  });

  final String label;
  final String value;
  final Color valueColor;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: border, width: 0.624),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.resultCardLabel),
          const SizedBox(height: 6),
          Text(
            value.toUpperCase(),
            style: AppTextStyles.resultCardValue.copyWith(color: valueColor),
          ),
        ],
      ),
    );
  }
}
