import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../models.dart';
import '../../../shared/widgets/flag_icon.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/tap_target.dart';

/// Top bar: the player's country flag (left) and the profile button (right).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.country,
    this.onCountryTap,
    this.onProfileTap,
    this.countryKey,
    this.profileKey,
  });

  static const double height = 56;

  /// Null while loading: the flag is left out.
  final Country? country;
  final VoidCallback? onCountryTap;
  final VoidCallback? onProfileTap;

  /// Mark the flag and the profile button for the first-time tour.
  final GlobalKey? countryKey;
  final GlobalKey? profileKey;

  @override
  Widget build(BuildContext context) {
    final country = this.country;
    return DecoratedBox(
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.hairline, width: 0.696),
        ),
      ),
      child: Stack(
        children: [
          // Positioned(
          //   left: 5,
          //   top: 10,
          //   child: Center(
          //     child: AppSvg(AppAssets.caseHome, excludeFromSemantics: true),
          //   ),
          // ),
          if (country != null)
            Positioned(
              left: 20,
              top: 10,
              child: TapTarget(
                key: countryKey,
                label: 'Country: ${country.name}',
                onTap: onCountryTap,
                child: SizedBox.square(
                  dimension: 40,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.90, bottom: 6.60),
                    child: FlagIcon(country.code),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 28,
            top: 6,
            child: ProfileButton(key: profileKey, onTap: onProfileTap),
          ),
        ],
      ),
    );
  }
}
