import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_svg.dart';
import '../../../shared/widgets/tap_target.dart';

/// Top bar with the pillar button that returns to the home screen.
class CaseHeader extends StatelessWidget {
  const CaseHeader({super.key, required this.onBack});

  static const double height = 50;

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.beige,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: TapTarget(
        label: 'Return to home',
        onTap: onBack,
        child: const SizedBox.square(
          dimension: 40,
          child: Center(
            child: AppSvg(
              AppAssets.caseHome,
              excludeFromSemantics: true,
              fallback: Icon(Icons.arrow_back, color: AppColors.brown),
            ),
          ),
        ),
      ),
    );
  }
}
