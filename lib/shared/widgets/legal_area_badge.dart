import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models.dart';

/// Red outlined "CRIMINAL" badge of a case.
class LegalAreaBadge extends StatelessWidget {
  const LegalAreaBadge(this.legalArea, {super.key});

  final LegalArea legalArea;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.badgeRedBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: AppColors.badgeRedBorder, width: 0.696),
      ),
      child: Text(
        legalArea.label.toUpperCase(),
        style: AppTextStyles.caseBadge,
      ),
    );
  }
}
