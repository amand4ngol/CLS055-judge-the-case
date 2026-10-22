import 'package:country_flags/country_flags.dart';
import 'package:flutter/widgets.dart';

import '../../core/constants/app_assets.dart';
import 'app_svg.dart';

/// A country's flag: the exported SVG when there is one (only the
/// Netherlands so far), else a flag drawn in the same 26×18 rounded frame,
/// so every flag takes the same room.
class FlagIcon extends StatelessWidget {
  const FlagIcon(this.countryCode, {super.key});

  static const Size size = Size(26, 18);

  final String countryCode;

  @override
  Widget build(BuildContext context) {
    return AppSvg(
      AppAssets.flag(countryCode),
      excludeFromSemantics: true,
      fallback: FittedBox(
        fit: BoxFit.fill,
        child: CountryFlag.fromCountryCode(
          countryCode,
          theme: ImageTheme(
            width: size.width,
            height: size.height,
            shape: const RoundedRectangle(4),
          ),
        ),
      ),
    );
  }
}
