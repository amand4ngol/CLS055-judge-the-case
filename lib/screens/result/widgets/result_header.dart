import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_svg.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/tap_target.dart';

/// Home pillar and profile button, or a single back arrow on a recap.
class ResultHeader extends StatelessWidget {
  const ResultHeader({
    super.key,
    required this.onBack,
    this.onProfile,
    this.isRecap = false,
  });

  static const double height = 50;

  final VoidCallback onBack;
  final VoidCallback? onProfile;
  final bool isRecap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.beige,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TapTarget(
            label: isRecap ? 'Back' : 'Return to home',
            onTap: onBack,
            child: SizedBox.square(
              dimension: 30,
              child: isRecap
                  ? const Icon(Icons.arrow_back, color: AppColors.brown)
                  : const AppSvg(
                      AppAssets.resultHome,
                      excludeFromSemantics: true,
                    ),
            ),
          ),
          if (!isRecap) ProfileButton(onTap: onProfile),
        ],
      ),
    );
  }
}
