import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_svg.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/tap_target.dart';

class ResultHeader extends StatelessWidget {
  const ResultHeader({super.key, required this.onHome, this.onProfile});

  static const double height = 50;

  final VoidCallback onHome;
  final VoidCallback? onProfile;

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
            label: 'Return to home',
            onTap: onHome,
            child: const SizedBox.square(
              dimension: 30,
              child: AppSvg(AppAssets.resultHome, excludeFromSemantics: true),
            ),
          ),
          ProfileButton(onTap: onProfile),
        ],
      ),
    );
  }
}
