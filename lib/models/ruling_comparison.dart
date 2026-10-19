import 'case_verdict.dart';
import 'enums.dart';
import 'player_verdict.dart';

/// The player's verdict set against the court's, for the result screen
/// ("You ruled" / "Court ruled", correct or incorrect).
///
/// A verdict is correct when the player selected exactly the court's buttons.
/// Slider amounts do not change correctness; their gap is given for display.
class RulingComparison {
  RulingComparison._({
    required this.player,
    required this.court,
    required this.matched,
    required this.missed,
    required this.extra,
    required this.fineGapEur,
    required this.prisonGapMonths,
  });

  factory RulingComparison.compare(PlayerVerdict player, CaseVerdict court) {
    final courtOptions = court.courtRuled;
    final bothFine = player.options.contains(VerdictOption.fine) && courtOptions.contains(VerdictOption.fine);
    final bothPrison =
        player.options.contains(VerdictOption.prison) && courtOptions.contains(VerdictOption.prison);
    final s = court.sentence;
    return RulingComparison._(
      player: player,
      court: court,
      matched: player.options.intersection(courtOptions),
      missed: courtOptions.difference(player.options),
      extra: player.options.difference(courtOptions),
      fineGapEur: bothFine && player.fineEur != null && s.fineEur != null ? player.fineEur! - s.fineEur! : null,
      prisonGapMonths: bothPrison && player.prisonMonths != null && s.prisonMonths != null
          ? player.prisonMonths! - s.prisonMonths!
          : null,
    );
  }

  final PlayerVerdict player;
  final CaseVerdict court;

  /// Buttons both picked (shown as correct in "You ruled").
  final Set<VerdictOption> matched;

  /// Court buttons the player did not pick.
  final Set<VerdictOption> missed;

  /// Player buttons the court did not pick (shown in red).
  final Set<VerdictOption> extra;

  /// Player fine minus court fine, when both chose a fine.
  final double? fineGapEur;

  /// Player prison months minus court prison months (suspended part
  /// included), when both chose prison.
  final double? prisonGapMonths;

  /// "Correct verdict" / "Incorrect verdict – The court disagrees."
  bool get isCorrect => missed.isEmpty && extra.isEmpty;

  bool isOptionCorrect(VerdictOption option) => matched.contains(option);
}
