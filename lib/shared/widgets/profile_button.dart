import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_colors.dart';
import 'app_svg.dart';
import 'tap_target.dart';

/// Round profile button shown on the right of every header.
class ProfileButton extends StatelessWidget {
  const ProfileButton({super.key, this.onTap});

  static const double size = 40;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return TapTarget(
      label: 'Open profile',
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.brown,
          shape: BoxShape.circle,
        ),
        child: const SizedBox.square(
          dimension: 16,
          child: AppSvg(AppAssets.profile, excludeFromSemantics: true),
        ),
      ),
    );
  }
}
