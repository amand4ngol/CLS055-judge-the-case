import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvg extends StatelessWidget {
  const AppSvg(
    this.assetPath, {
    super.key,
    this.fit = BoxFit.fill,
    this.fallback,
    this.excludeFromSemantics = false,
    this.colorFilter,
  });

  final String assetPath;
  final BoxFit fit;
  final Widget? fallback;
  final bool excludeFromSemantics;

  /// Recolors the picture, e.g. white icons on a selected card.
  final ColorFilter? colorFilter;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      key: ValueKey(assetPath),
      fit: fit,
      colorFilter: colorFilter,
      excludeFromSemantics: excludeFromSemantics,
      errorBuilder: (context, error, stackTrace) =>
          fallback ?? const SizedBox.shrink(),
    );
  }
}
