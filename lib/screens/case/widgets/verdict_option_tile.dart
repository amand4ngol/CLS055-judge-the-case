import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/formatters.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';

/// One verdict button. Fine and Prison grow a slider while selected.
class VerdictOptionTile extends StatelessWidget {
  const VerdictOptionTile({
    super.key,
    required this.option,
    required this.verdict,
    required this.onTap,
    required this.onFineChanged,
    required this.onPrisonChanged,
    required this.onSliderChangeEnd,
  });

  final VerdictOption option;
  final PlayerVerdict verdict;
  final VoidCallback onTap;
  final ValueChanged<double> onFineChanged;
  final ValueChanged<double> onPrisonChanged;
  final VoidCallback onSliderChangeEnd;

  bool get _selected => verdict.isSelected(option);

  /// The amount chosen with the slider, formatted, or null.
  String? get _value => switch (option) {
    VerdictOption.fine when verdict.fineEur != null => Formatters.euro(
      verdict.fineEur!,
    ),
    VerdictOption.prison when verdict.prisonMonths != null => Formatters.months(
      verdict.prisonMonths!,
    ),
    _ => null,
  };

  String get _subtitle {
    if (!option.isAdjustable) return option.description;
    return _selected ? (_value ?? option.description) : 'Press to adjust';
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: selected ? AppColors.verdictSelected : null,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: selected ? AppColors.blue : AppColors.caseOutline,
          width: 0.696,
        ),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              button: true,
              selected: selected,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 65),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        _VerdictIcon(option),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                option.label,
                                style: selected
                                    ? AppTextStyles.verdictTitleSelected
                                    : AppTextStyles.verdictTitle,
                              ),
                              Text(
                                _subtitle,
                                style: AppTextStyles.verdictSubtitle,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (selected && option.isAdjustable) _sliderRow(),
          ],
        ),
      ),
    );
  }

  Widget _sliderRow() {
    final isFine = option == VerdictOption.fine;
    return Padding(
      padding: const EdgeInsets.only(left: 41, right: 16, bottom: 12),
      child: SizedBox(
        height: 20,
        child: Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: const SliderThemeData(
                  trackHeight: 4,
                  activeTrackColor: AppColors.blue,
                  inactiveTrackColor: Color.fromRGBO(255, 255, 255, 0.6),
                  thumbColor: AppColors.blue,
                  overlayColor: Color.fromRGBO(46, 69, 120, 0.12),
                  thumbShape: RoundSliderThumbShape(enabledThumbRadius: 8),
                  overlayShape: RoundSliderOverlayShape(overlayRadius: 16),
                ),
                child: Slider(
                  value: isFine
                      ? _FineScale.toSlider(verdict.fineEur!)
                      : verdict.prisonMonths!,
                  min: isFine ? 0 : PlayerVerdict.prisonMinMonths,
                  max: isFine ? 1 : PlayerVerdict.prisonMaxMonths,
                  divisions: isFine
                      ? null
                      : (PlayerVerdict.prisonMaxMonths -
                                PlayerVerdict.prisonMinMonths)
                            .round(),
                  semanticFormatterCallback: (_) => _value ?? '',
                  onChanged: (value) => isFine
                      ? onFineChanged(_FineScale.fromSlider(value))
                      : onPrisonChanged(value),
                  onChangeEnd: (_) => onSliderChangeEnd(),
                ),
              ),
            ),
            const SizedBox(width: 14),
            SizedBox(
              width: 105,
              child: Text(
                _value ?? '',
                textAlign: TextAlign.right,
                style: AppTextStyles.verdictValue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fines go from 100 € to 10,000,000 €, so the slider is logarithmic: the
/// first half covers 100 € to 10,000 €, the second half the rest.
abstract final class _FineScale {
  static const _min = PlayerVerdict.fineMinEur;
  static const _max = PlayerVerdict.fineMaxEur;

  static double toSlider(double eur) =>
      (math.log(eur / _min) / math.log(_max / _min)).clamp(0.0, 1.0);

  /// Rounded to two significant digits (36,512 -> 37,000) so the amounts
  /// read like real sentences.
  static double fromSlider(double t) {
    final eur = _min * math.pow(_max / _min, t);
    final step = math.pow(10, (math.log(eur) / math.ln10).floor() - 1);
    return ((eur / step).round() * step).toDouble();
  }
}

class _VerdictIcon extends StatelessWidget {
  const _VerdictIcon(this.option);

  final VerdictOption option;

  /// Asset and offset of the vector inside the 25x25 frame.
  (String, Offset)? get _icon => switch (option) {
    VerdictOption.fine => (AppAssets.verdictFine, const Offset(3.13, 3.13)),
    VerdictOption.prison => (AppAssets.verdictPrison, const Offset(2.08, 2.6)),
    VerdictOption.communityService => (
      AppAssets.verdictCommunityService,
      const Offset(2.08, 5.21),
    ),
    VerdictOption.probation => (
      AppAssets.verdictProbation,
      const Offset(3.13, 1.56),
    ),
    VerdictOption.acquitted => (
      AppAssets.verdictAcquitted,
      const Offset(1.56, 1.56),
    ),
    // Not in the design yet.
    VerdictOption.caseDismissed => null,
  };

  @override
  Widget build(BuildContext context) {
    final icon = _icon;
    return SizedBox.square(
      dimension: 25,
      child: icon == null
          ? const Icon(Icons.gavel, size: 22, color: AppColors.brown)
          : Padding(
              padding: EdgeInsets.only(left: icon.$2.dx, top: icon.$2.dy),
              child: Align(
                alignment: Alignment.topLeft,
                child: AppSvg(icon.$1, excludeFromSemantics: true),
              ),
            ),
    );
  }
}
