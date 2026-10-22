import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// Shown instead of the case columns when every case of a category is hidden
/// by the player's content preferences.
class HiddenCasesNotice extends StatelessWidget {
  const HiddenCasesNotice({
    super.key,
    required this.categoryLabel,
    required this.hidesSensitiveCases,
    required this.onShowSensitiveCases,
  });

  /// "Homicide or Sexual Assault" or "Drug Offense", etc. Used in the body text.
  final String categoryLabel;

  /// True when "Hide all sensitive cases" is on; false when only specific
  /// topics are filtered in the settings.
  final bool hidesSensitiveCases;
  final VoidCallback onShowSensitiveCases;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      decoration: const BoxDecoration(
        color: AppColors.titleCardBackground,
        borderRadius: BorderRadius.all(Radius.circular(4)),
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
          const Icon(
            Icons.visibility_off_outlined,
            size: 28,
            color: AppColors.brown,
          ),
          const SizedBox(height: 12),
          Text(
            'Sensitive cases hidden',
            textAlign: TextAlign.center,
            style: AppTextStyles.title,
          ),
          const SizedBox(height: 12),
          Text(
            hidesSensitiveCases
                ? 'You chose not to see sensitive cases, and every '
                      '$categoryLabel case deals with sensitive topics. '
                      'Turn them back on to judge these cases.'
                : 'Every $categoryLabel case covers a topic you filtered '
                      'out. You can change your content preferences in '
                      'Settings.',
            textAlign: TextAlign.center,
            style: AppTextStyles.hiddenCasesBody,
          ),
          if (hidesSensitiveCases) ...[
            const SizedBox(height: 20),
            _ShowButton(onTap: onShowSensitiveCases),
          ],
        ],
      ),
    );
  }
}

class _ShowButton extends StatelessWidget {
  const _ShowButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.brown,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Text(
            'Show sensitive cases',
            style: AppTextStyles.hiddenCasesButton,
          ),
        ),
      ),
    );
  }
}
