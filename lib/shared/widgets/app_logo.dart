import 'package:flutter/material.dart';

import '../../core/constants/app_assets.dart';
import '../../core/theme/app_text_styles.dart';
import 'app_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  static const double width = 261;

  static const double height = 136;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Semantics(
        label: 'Judge the Case, real court cases',
        excludeSemantics: true,

        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned(
                left: 10,
                top: 10,
                child: Text('Judge the Case', style: AppTextStyles.splashTitle),
              ),
              const Positioned(
                left: 10,
                top: 62,
                child: AppSvg(AppAssets.courthouse, excludeFromSemantics: true),
              ),
              Positioned(
                left: 0,
                right: 2,
                top: 92,
                child: Text(
                  'REAL COURT CASES',
                  maxLines: 1,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.labelSmall,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
