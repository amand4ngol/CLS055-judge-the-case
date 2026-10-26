import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';

/// Panel shown over a sensitive case before the player enters it.
class TriggerWarning extends StatelessWidget {
  const TriggerWarning({
    super.key,
    required this.warnings,
    required this.dontShowAgain,
    required this.onDontShowAgainChanged,
    required this.onEnter,
  });

  final Set<ContentWarning> warnings;

  /// "Do not show this warning again".
  final bool dontShowAgain;
  final ValueChanged<bool> onDontShowAgainChanged;
  final VoidCallback onEnter;

  /// "violence", "violence and death", "violence, drugs and death"
  String get _topics {
    final labels = [
      for (final w in ContentWarning.values)
        if (warnings.contains(w)) w.label.toLowerCase(),
    ];
    if (labels.length <= 1) return labels.join();
    return '${labels.sublist(0, labels.length - 1).join(', ')} '
        'and ${labels.last}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.warningOverlay,
      padding: const EdgeInsets.fromLTRB(43, 32, 35, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Trigger warning', style: AppTextStyles.warningTitle),
          const SizedBox(height: 8),
          Text(
            'This case contains sensitive descriptions of $_topics.\n\n'
            'You can choose to filter out these cases or continue with the '
            'case.\n\n'
            'Filter out specific topics in your profile settings.',
            style: AppTextStyles.warningBody,
          ),
          const SizedBox(height: 24),
          _DontShowAgainCheckbox(
            value: dontShowAgain,
            onChanged: onDontShowAgainChanged,
          ),
          const SizedBox(height: 41),
          Center(child: _EnterButton(onTap: onEnter)),
        ],
      ),
    );
  }
}

class _DontShowAgainCheckbox extends StatelessWidget {
  const _DontShowAgainCheckbox({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: value,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onChanged(!value),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.black),
              ),
              child: value
                  ? const Icon(Icons.check, size: 16, color: AppColors.black)
                  : null,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                'Do not show this warning again',
                style: AppTextStyles.warningCheckbox,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EnterButton extends StatelessWidget {
  const _EnterButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 276,
          height: 55.75,
          color: AppColors.warningButton,
          alignment: Alignment.center,
          child: Text('Enter anyways', style: AppTextStyles.warningButton),
        ),
      ),
    );
  }
}
