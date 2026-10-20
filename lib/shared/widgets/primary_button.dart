import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Full-width blue button ("Deliver Verdict"). Faded while [onPressed] is
/// null; shows a spinner while [isLoading].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.height = 52,
    this.labelStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double height;

  /// Defaults to [AppTextStyles.primaryButton].
  final TextStyle? labelStyle;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onPressed == null ? 0.5 : 1,
          child: Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.blue,
              borderRadius: BorderRadius.circular(4),
              boxShadow: const [
                BoxShadow(
                  color: Color.fromRGBO(0, 0, 0, 0.1),
                  offset: Offset(0, 1),
                  blurRadius: 3,
                ),
              ],
            ),
            child: isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.beige,
                    ),
                  )
                : Text(label, style: labelStyle ?? AppTextStyles.primaryButton),
          ),
        ),
      ),
    );
  }
}
