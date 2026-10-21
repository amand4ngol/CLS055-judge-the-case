import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';

/// "Sensitive case filter". Opens in place with one checkbox to hide every
/// sensitive case and one per topic.
class SensitiveFilter extends StatefulWidget {
  const SensitiveFilter({
    super.key,
    required this.preferences,
    required this.onChanged,
  });

  final ContentPreferences preferences;
  final ValueChanged<ContentPreferences> onChanged;

  @override
  State<SensitiveFilter> createState() => _SensitiveFilterState();
}

class _SensitiveFilterState extends State<SensitiveFilter> {
  bool _isOpen = false;

  /// "No filter selected", "All sensitive cases hidden" or "Violence, Death".
  String get _summary {
    final preferences = widget.preferences;
    if (preferences.hideSensitiveCases) return 'All sensitive cases hidden';
    if (preferences.filteredTopics.isEmpty) return 'No filter selected';
    return ContentWarning.values
        .where(preferences.filteredTopics.contains)
        .map((topic) => topic.label)
        .join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final preferences = widget.preferences;
    return Material(
      color: AppColors.argumentCard,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isOpen = !_isOpen),
            child: Container(
              height: 60,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sensitive case filter',
                          style: AppTextStyles.settingsItem,
                        ),
                        Text(
                          _summary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.settingsItemDetail,
                        ),
                      ],
                    ),
                  ),
                  RotatedBox(
                    quarterTurns: _isOpen ? 2 : 0,
                    child: const SizedBox.square(
                      dimension: 20,
                      child: AppSvg(AppAssets.chevronDownDark),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_isOpen) ...[
            const Divider(height: 1, color: AppColors.caseDivider),
            _checkbox(
              'Hide all sensitive cases',
              preferences.hideSensitiveCases,
              (value) => widget.onChanged(
                preferences.copyWith(hideSensitiveCases: value),
              ),
            ),
            // Topics only matter when not every sensitive case is hidden.
            for (final topic in ContentWarning.values)
              _checkbox(
                topic.label,
                preferences.filteredTopics.contains(topic),
                preferences.hideSensitiveCases
                    ? null
                    : (_) => widget.onChanged(preferences.toggleTopic(topic)),
              ),
          ],
        ],
      ),
    );
  }

  Widget _checkbox(String label, bool value, ValueChanged<bool>? onChanged) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged == null ? null : (v) => onChanged(v ?? false),
      title: Text(label, style: AppTextStyles.settingsItem),
      activeColor: AppColors.blue,
      dense: true,
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
    );
  }
}
