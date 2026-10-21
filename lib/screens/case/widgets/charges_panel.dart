import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// "CHARGES FILED" box with one line per charge.
class ChargesPanel extends StatelessWidget {
  const ChargesPanel({super.key, required this.charges});

  final List<String> charges;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.casePanel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.casePanelBorder, width: 0.696),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('CHARGES FILED', style: AppTextStyles.caseSectionLabel),
          const SizedBox(height: 12),
          for (final (i, charge) in charges.indexed) ...[
            if (i > 0) const SizedBox(height: 8),
            _Charge(charge),
          ],
        ],
      ),
    );
  }
}

class _Charge extends StatelessWidget {
  const _Charge(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 16.37,
          child: Padding(
            padding: const EdgeInsets.only(top: 3.5),
            child: Text('▸', style: AppTextStyles.caseChargeBullet),
          ),
        ),
        Expanded(child: Text(text, style: AppTextStyles.caseCharge)),
      ],
    );
  }
}
