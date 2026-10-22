import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';

/// "Trigger warnings": turns the warning before sensitive cases back on after
/// "Do not show this warning again", or off from here.
class TriggerWarningsSwitch extends StatelessWidget {
  const TriggerWarningsSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.argumentCard,
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.blue,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        title: Text('Trigger warnings', style: AppTextStyles.settingsItem),
        subtitle: Text(
          value
              ? 'Shown before sensitive cases'
              : 'Sensitive cases open without a warning',
          style: AppTextStyles.settingsItemDetail,
        ),
      ),
    );
  }
}
