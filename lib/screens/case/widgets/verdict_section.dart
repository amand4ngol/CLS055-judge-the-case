import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/primary_button.dart';
import 'case_section.dart';
import 'verdict_option_tile.dart';

/// "YOUR TIME TO RULE": the verdict buttons and "Deliver Verdict".
class VerdictSection extends StatelessWidget {
  const VerdictSection({
    super.key,
    required this.verdict,
    required this.canDeliver,
    required this.isDelivering,
    required this.onToggle,
    required this.onFineChanged,
    required this.onPrisonChanged,
    required this.onSliderChangeEnd,
    required this.onDeliver,
  });

  final PlayerVerdict verdict;
  final bool canDeliver;
  final bool isDelivering;
  final ValueChanged<VerdictOption> onToggle;
  final ValueChanged<double> onFineChanged;
  final ValueChanged<double> onPrisonChanged;
  final VoidCallback onSliderChangeEnd;
  final VoidCallback onDeliver;

  @override
  Widget build(BuildContext context) {
    return CaseSection(
      padding: const EdgeInsets.only(top: 20, bottom: 8),
      dividerAbove: true,
      dividerBelow: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('YOUR TIME TO RULE', style: AppTextStyles.rulingEyebrow),
          Text('Decide The Verdict', style: AppTextStyles.rulingTitle),
          Text('Choose one or more verdicts', style: AppTextStyles.rulingHint),
          const SizedBox(height: 16),
          for (final (i, option) in VerdictOption.values.indexed) ...[
            if (i > 0) const SizedBox(height: 10),
            VerdictOptionTile(
              option: option,
              verdict: verdict,
              onTap: () => onToggle(option),
              onFineChanged: onFineChanged,
              onPrisonChanged: onPrisonChanged,
              onSliderChangeEnd: onSliderChangeEnd,
            ),
          ],
          const SizedBox(height: 48),
          PrimaryButton(
            label: 'Deliver Verdict',
            onPressed: canDeliver ? onDeliver : null,
            isLoading: isDelivering,
          ),
        ],
      ),
    );
  }
}
