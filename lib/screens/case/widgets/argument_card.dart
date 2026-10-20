import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';

/// Paper card of the argument carousel. [ArgumentCard.intro] is the first
/// one ("Swipe to read the key arguments"), [ArgumentCard.argument] the
/// others.
class ArgumentCard extends StatelessWidget {
  const ArgumentCard.intro({super.key}) : argument = null;

  const ArgumentCard.argument(CaseArgument this.argument, {super.key});

  final CaseArgument? argument;

  @override
  Widget build(BuildContext context) {
    final argument = this.argument;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: AppColors.argumentCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.argumentCardBorder, width: 0.696),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.1),
            offset: Offset(4, 12),
            blurRadius: 5,
          ),
        ],
      ),
      child: Center(
        // Long arguments shrink instead of overflowing the fixed-height card.
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 290),
            child: argument == null
                ? const _IntroContent()
                : _ArgumentContent(argument),
          ),
        ),
      ),
    );
  }
}

class _IntroContent extends StatelessWidget {
  const _IntroContent();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const _ScalesBadge(),
        const SizedBox(height: 24),
        Text('KEY ARGUMENTS', style: AppTextStyles.argumentCardLabel),
        const SizedBox(height: 12),
        Text(
          'Swipe to read the key arguments',
          textAlign: TextAlign.center,
          style: AppTextStyles.argumentIntroTitle,
        ),
      ],
    );
  }
}

class _ArgumentContent extends StatelessWidget {
  const _ArgumentContent(this.argument);

  final CaseArgument argument;

  /// The prosecution's arguments are shown as "Accusation" in the design.
  String get _label => switch (argument.side) {
    ArgumentSide.prosecution => 'ACCUSATION',
    ArgumentSide.defence => 'DEFENCE',
    ArgumentSide.context => 'CONTEXT',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_label, style: AppTextStyles.argumentCardLabel),
        const SizedBox(height: 12),
        Text(
          argument.text,
          textAlign: TextAlign.center,
          style: AppTextStyles.argumentText,
        ),
      ],
    );
  }
}

class _ScalesBadge extends StatelessWidget {
  const _ScalesBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: AppColors.argumentScalesBackground,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.argumentScalesBorder, width: 0.696),
      ),
      alignment: Alignment.center,
      // The scales vector sits at (2.47, 6.07) inside a 36x36 frame.
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.topLeft,
        padding: const EdgeInsets.only(left: 2.47, top: 6.07),
        child: const AppSvg(
          AppAssets.scales,
          excludeFromSemantics: true,
          fallback: Icon(Icons.balance, color: AppColors.textSubtle),
        ),
      ),
    );
  }
}
