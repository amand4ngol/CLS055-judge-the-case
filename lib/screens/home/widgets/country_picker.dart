import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';
import '../../../shared/widgets/flag_icon.dart';
import '../../../shared/widgets/tap_target.dart';

/// "Switch country" dropdown opened from the flag in the home header: a
/// search bar, then one row per country with the player's progress there.
class CountryPicker extends StatefulWidget {
  const CountryPicker({
    super.key,
    required this.countries,
    required this.selectedCode,
    required this.stats,
    required this.onSelected,
    required this.onClose,
  });

  static const double width = 261;

  final List<Country> countries;
  final String? selectedCode;
  final PlayerStats stats;
  final ValueChanged<Country> onSelected;
  final VoidCallback onClose;

  @override
  State<CountryPicker> createState() => _CountryPickerState();
}

class _CountryPickerState extends State<CountryPicker> {
  String _query = '';

  List<Country> get _visibleCountries {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return widget.countries;
    return widget.countries
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final countries = _visibleCountries;
    return Material(
      type: MaterialType.transparency,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: CountryPicker.width,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _SearchBar(
                onChanged: (value) => setState(() => _query = value),
                onClose: widget.onClose,
              ),
              for (final country in countries) ...[
                const SizedBox(height: 2),
                _CountryRow(
                  country: country,
                  selected: country.code == widget.selectedCode,
                  progress: country.progressLabel(widget.stats),
                  onTap: () => widget.onSelected(country),
                ),
              ],
              if (countries.isEmpty) ...[
                const SizedBox(height: 2),
                Container(
                  color: AppColors.countryPickerRow,
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'No country found',
                    style: AppTextStyles.countryPickerProgress,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.onChanged, required this.onClose});

  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      color: AppColors.countryPickerBar,
      padding: const EdgeInsets.only(left: 16, right: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              onChanged: onChanged,
              style: AppTextStyles.countryPickerSearch,
              cursorColor: AppColors.white,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Switch country',
                hintStyle: AppTextStyles.countryPickerSearchHint,
              ),
            ),
          ),
          const SizedBox(width: 12),
          const SizedBox.square(
            dimension: 20,
            child: AppSvg(
              AppAssets.search,
              excludeFromSemantics: true,
              fallback: Icon(Icons.search, size: 20, color: AppColors.white),
            ),
          ),
          TapTarget(
            label: 'Close country list',
            onTap: onClose,
            child: const SizedBox(
              width: 32,
              height: 40,
              child: Center(
                child: SizedBox.square(
                  dimension: 20,
                  child: AppSvg(
                    AppAssets.chevronUp,
                    excludeFromSemantics: true,
                    fallback: Icon(
                      Icons.expand_less,
                      size: 20,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CountryRow extends StatelessWidget {
  const _CountryRow({
    required this.country,
    required this.selected,
    required this.progress,
    required this.onTap,
  });

  final Country country;
  final bool selected;

  /// "22% done" or "0%".
  final String progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: '${country.name}, $progress',
      excludeSemantics: true,
      child: Material(
        color: selected
            ? AppColors.countryPickerRowSelected
            : AppColors.countryPickerRow,
        borderRadius: BorderRadius.circular(4),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 26,
                    height: 28,
                    child: Center(
                      child: SizedBox.fromSize(
                        size: FlagIcon.size,
                        child: FlagIcon(country.code),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      country.name,
                      style: AppTextStyles.countryPickerName,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    progress,
                    textAlign: TextAlign.right,
                    style: selected
                        ? AppTextStyles.countryPickerProgressSelected
                        : AppTextStyles.countryPickerProgress,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
