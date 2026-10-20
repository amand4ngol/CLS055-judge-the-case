import 'package:flutter/material.dart';

import '../../../core/constants/app_assets.dart';
import '../../../models.dart';
import '../../../shared/widgets/app_svg.dart';
import 'case_title_card.dart';
import 'medallions/completed_medallion.dart';
import 'medallions/locked_medallion.dart';
import 'medallions/next_case_medallion.dart';

/// One case drawn as a stone pillar, with its medallion button and, for
/// completed and locked cases, a title card.
class CaseColumn extends StatelessWidget {
  const CaseColumn({super.key, required this.slot, this.onTap});

  static const double width = 170;
  static const double height = 560;

  static const double _pillarTop = 64; // puts the base at y≈556
  static const double _pillarHeight = 494;
  static const double _medallionTop = 195.27;
  static const double _titleCardTop = 315.59;

  final CaseSlot slot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final state = slot.state;
    final showTitleCard =
        state == CaseSlotState.completed || state == CaseSlotState.locked;

    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            left: 0,
            top: _pillarTop,
            width: width,
            height: _pillarHeight,
            child: AppSvg(
              AppAssets.pillar,
              fit: BoxFit.contain,
              excludeFromSemantics: true,
            ),
          ),
          if (showTitleCard)
            Positioned(
              left: 6.97,
              top: _titleCardTop,
              width: 156.04,
              child: Opacity(
                opacity: state == CaseSlotState.locked ? 0.58 : 1,
                child: CaseTitleCard(
                  label: slot.label,
                  title: slot.courtCase.title,
                  subtitle: _subtitle,
                ),
              ),
            ),
          _medallion(),
        ],
      ),
    );
  }

  String? get _subtitle => switch (slot.state) {
    CaseSlotState.completed =>
      slot.ruling?.isCorrect == true ? 'Perfect judgment' : 'Verdict delivered',
    CaseSlotState.locked => 'Complete the previous case',
    _ => null,
  };

  Widget _medallion() {
    return switch (slot.state) {
      CaseSlotState.completed => Positioned(
        left: 34.23,
        top: _medallionTop,
        child: CompletedMedallion(
          label: slot.label,
          isPerfect: slot.ruling?.isCorrect == true,
          onTap: onTap,
        ),
      ),
      // TODO: in-progress cases get their own "CONTINUE" medallion
      CaseSlotState.next || CaseSlotState.inProgress => Positioned(
        left: 25,
        top: _medallionTop,
        child: NextCaseMedallion(onTap: onTap),
      ),
      CaseSlotState.locked => Positioned(
        left: 34.23,
        top: _medallionTop,
        child: LockedMedallion(label: slot.label),
      ),
    };
  }
}
