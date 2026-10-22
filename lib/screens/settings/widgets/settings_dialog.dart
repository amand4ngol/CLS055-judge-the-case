import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

class SettingsDialog extends StatelessWidget {
  const SettingsDialog({
    super.key,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
    this.children = const [],
    this.error,
    this.isLoading = false,
    this.destructive = false,
  });

  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  /// Fields between the message and the buttons.
  final List<Widget> children;

  /// Why the last attempt failed, ready to show.
  final String? error;
  final bool isLoading;

  /// Red action button, for "Delete account".
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.beige,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(message, style: AppTextStyles.settingsBody),
            if (children.isNotEmpty) ...[
              const SizedBox(height: 20),
              Center(child: Column(children: children)),
            ],
            if (error != null) ...[
              const SizedBox(height: 12),
              Text(error!, style: AppTextStyles.fieldError),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SettingsDialogButton(
                    label: 'Cancel',
                    color: AppColors.argumentCard,
                    textColor: AppColors.countryPickerName,
                    onTap: isLoading
                        ? null
                        : () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SettingsDialogButton(
                    label: actionLabel,
                    color: destructive
                        ? AppColors.resultIncorrect
                        : AppColors.blue,
                    textColor: AppColors.white,
                    isLoading: isLoading,
                    onTap: onAction,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsDialogButton extends StatelessWidget {
  const SettingsDialogButton({
    super.key,
    required this.label,
    required this.color,
    required this.textColor,
    required this.onTap,
    this.isLoading = false,
  });

  final String label;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          height: 48,
          child: Center(
            child: isLoading
                ? SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: textColor,
                    ),
                  )
                : Text(
                    label,
                    style: AppTextStyles.settingsItem.copyWith(
                      color: textColor,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
