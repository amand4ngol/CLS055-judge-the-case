import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class CaseTitleCard extends StatelessWidget {
  const CaseTitleCard({
    super.key,
    required this.label,
    required this.title,
    this.subtitle,
  });

  final String label;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final subtitle = this.subtitle;
    // The title always takes two lines of room, so every card in the row has
    // the same height whether its title wraps or not.
    final titleStyle = AppTextStyles.titleCardTitle;
    final titleMinHeight =
        2 *
        MediaQuery.textScalerOf(context).scale(titleStyle.fontSize!) *
        titleStyle.height!;
    return Container(
      constraints: const BoxConstraints(minHeight: 77.08),
      padding: const EdgeInsets.fromLTRB(9.4, 12.22, 9.4, 10.34),
      decoration: const BoxDecoration(
        color: AppColors.titleCardBackground,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(62, 57, 48, 0.15),
            offset: Offset(0, 6.58),
            blurRadius: 18.8,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.titleCardLabel,
          ),
          const SizedBox(height: 4.7),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: titleMinHeight),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: titleStyle,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4.7),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: AppTextStyles.titleCardSubtitle,
            ),
          ],
        ],
      ),
    );
  }
}
