import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_svg.dart';

class AppLogo extends StatelessWidget {
  const AppLogo({super.key});

  static const double width = 261;

  static const double _taglineOffset = 30;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withNoTextScaling(
      child: Semantics(
        label: 'Judge the Case, real court cases',
        excludeSemantics: true,
        child: SizedBox(
          width: width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 0, 0.8),
                child: Text('Judge the Case', style: AppTextStyles.splashTitle),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 10, right: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppSvg(AppAssets.courthouse, excludeFromSemantics: true),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          'REAL COURT CASES',
                          textAlign: TextAlign.right,
                          style: AppTextStyles.labelSmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
