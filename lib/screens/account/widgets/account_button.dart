import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class AccountButton extends StatelessWidget {
  const AccountButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.secondary = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool secondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final style = secondary
        ? AppTextStyles.accountButtonSecondary
        : AppTextStyles.accountButton;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: secondary ? AppColors.white : AppColors.blue,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            // The label keeps its space under the spinner, so the button
            // does not change size.
            child: Stack(
              alignment: Alignment.center,
              children: [
                Opacity(
                  opacity: isLoading ? 0 : 1,
                  child: Text(label, style: style),
                ),
                if (isLoading)
                  SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: style.color,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
