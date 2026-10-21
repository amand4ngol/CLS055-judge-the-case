import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvg extends StatelessWidget {
  const AppSvg(
    this.assetPath, {
    super.key,
    this.fit = BoxFit.fill,
    this.fallback,
    this.excludeFromSemantics = false,
  });

  final String assetPath;
  final BoxFit fit;
  final Widget? fallback;
  final bool excludeFromSemantics;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      assetPath,
      fit: fit,
      excludeFromSemantics: excludeFromSemantics,
      errorBuilder: (context, error, stackTrace) =>
          fallback ?? const SizedBox.shrink(),
    );
  }
}
