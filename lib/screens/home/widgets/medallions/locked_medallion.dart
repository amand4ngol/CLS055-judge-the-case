import 'package:flutter/material.dart';

import '../../../../core/constants/app_assets.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'medallion_parts.dart';

/// Faded medallion with a padlock: the previous case must be completed first.
class LockedMedallion extends StatelessWidget {
  const LockedMedallion({super.key, required this.label});

  /// "CASE 05"
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label, locked',
      child: Opacity(
        opacity: 0.48,
        child: Container(
          width: kMedallionSize,
          height: kMedallionSize,
          padding: const EdgeInsets.fromLTRB(7.52, 12.22, 7.52, 9.4),
          decoration: BoxDecoration(
            color: AppColors.medallionLocked,
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.medallionLockedRing,
              width: kMedallionRing,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color.fromRGBO(53, 49, 42, 0.12),
                offset: Offset(0, 6.58),
                blurRadius: 14.1,
              ),
            ],
          ),
          child: MedallionContent(
            label: label,
            labelStyle: AppTextStyles.medallionLockedLabel,
            icon: const Opacity(
              opacity: 0.9,
              child: MedallionIcon(
                assetPath: AppAssets.lock,
                fallbackIcon: Icons.lock,
                fallbackColor: AppColors.medallionLockedText,
                box: Size(25.38, 36.66),
                offset: Offset(4.39, 7.94),
                size: Size(16.60, 20.78),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
