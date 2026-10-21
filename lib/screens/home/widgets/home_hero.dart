import 'package:flutter/material.dart';

import '../../../core/theme/app_text_styles.dart';

/// "REAL COURT CASES / Take your place on the bench." intro text.
class HomeHero extends StatelessWidget {
  const HomeHero({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('REAL COURT CASES', style: AppTextStyles.labelSmall),
        const SizedBox(height: 13),
        Text('Take your place\non the bench.', style: AppTextStyles.display),
        const SizedBox(height: 13),

        Text(
          'Examine the evidence. Apply the law.\nDeliver your judgment.',
          style: AppTextStyles.body,
        ),
      ],
    );
  }
}
