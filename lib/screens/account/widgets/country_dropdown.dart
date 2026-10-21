import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';

/// "Choose country to rule in". Tapping it opens a search bar and the
/// country list in place, which pushes the button below down.
class CountryDropdown extends StatefulWidget {
  const CountryDropdown({
    super.key,
    required this.countries,
    required this.selected,
    required this.showSelectedName,
    required this.onSelected,
  });

  final List<Country> countries;
  final Country selected;

  /// False until the player picks a country, so the bar says "Choose
  /// country to rule in" next to the default flag.
  final bool showSelectedName;
  final ValueChanged<Country> onSelected;

  @override
  State<CountryDropdown> createState() => _CountryDropdownState();
}

class _CountryDropdownState extends State<CountryDropdown> {
  bool _isOpen = false;
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final countries = widget.countries
        .where((c) => c.name.toLowerCase().contains(_search.toLowerCase()))
        .toList();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        width: 262,
        child: Column(
          children: [
            _isOpen ? _searchBar() : _closedBar(),
            if (_isOpen)
              Container(
                color: AppColors.countryListBackground,
                child: Column(
                  children: [
                    for (final country in countries) ...[
                      if (country != countries.first)
                        const Divider(
                          height: 1,
                          indent: 16,
                          endIndent: 16,
                          color: AppColors.countryListDivider,
                        ),
                      _countryRow(country),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _closedBar() {
    return GestureDetector(
      onTap: () => setState(() => _isOpen = true),
      child: Container(
        height: 56,
        color: AppColors.countryPickerBar,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _flag(widget.selected),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                widget.showSelectedName
                    ? widget.selected.name
                    : 'Choose country to rule in',
                style: AppTextStyles.countryDropdown,
              ),
            ),
            const SizedBox.square(
              dimension: 20,
              child: AppSvg(AppAssets.chevronDown),
            ),
          ],
        ),
      ),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 56,
      color: AppColors.countryPickerBar,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              autofocus: true,
              onChanged: (value) => setState(() => _search = value),
              style: AppTextStyles.countryDropdown,
              cursorColor: AppColors.white,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Search country',
                hintStyle: AppTextStyles.countryDropdownHint,
              ),
            ),
          ),
          const SizedBox.square(dimension: 20, child: AppSvg(AppAssets.search)),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => setState(() {
              _isOpen = false;
              _search = '';
            }),
            child: const SizedBox.square(
              dimension: 20,
              child: AppSvg(AppAssets.chevronUp),
            ),
          ),
        ],
      ),
    );
  }

  Widget _countryRow(Country country) {
    return InkWell(
      onTap: () {
        setState(() {
          _isOpen = false;
          _search = '';
        });
        widget.onSelected(country);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _flag(country),
            const SizedBox(width: 12),
            Text(country.name, style: AppTextStyles.countryPickerName),
          ],
        ),
      ),
    );
  }

  /// Only the Netherlands flag is exported so far;
  Widget _flag(Country country) {
    return SizedBox(
      width: 26,
      height: 18,
      child: AppSvg(
        AppAssets.flag(country.code),
        fallback: FittedBox(child: Text(country.flag)),
      ),
    );
  }
}
