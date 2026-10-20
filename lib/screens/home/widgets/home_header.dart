import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';
import '../../../shared/widgets/profile_button.dart';
import '../../../shared/widgets/tap_target.dart';

/// Top bar: the player's country flag (left) and the profile button (right).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    super.key,
    this.country,
    this.onCountryTap,
    this.onProfileTap,
  });

  static const double height = 56;

  /// Null while loading: the flag is left out.
  final Country? country;
  final VoidCallback? onCountryTap;
  final VoidCallback? onProfileTap;

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
          if (country != null)
            Positioned(
              left: 42,
              top: 5,
              child: TapTarget(
                label: 'Country: ${country.name}',
                onTap: onCountryTap,
                child: SizedBox.square(
                  dimension: 40,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 5.90, bottom: 6.60),
                    child: AppSvg(
                      AppAssets.flag(country.code),
                      excludeFromSemantics: true,
                      fallback: FittedBox(child: Text(country.flag)),
                    ),
                  ),
                ),
              ),
            ),
          Positioned(
            right: 28,
            top: 6,
            child: ProfileButton(onTap: onProfileTap),
          ),
        ],
      ),
    );
  }
}
