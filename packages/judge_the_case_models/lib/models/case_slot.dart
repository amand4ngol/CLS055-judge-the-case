import 'content_preferences.dart';
import 'court_case.dart';
import 'player_ruling.dart';

/// How a case looks in its category column on the home screen.
enum CaseSlotState {
  /// Verdict delivered (gold bookmark); can be revised.
  completed,

  /// Opened but not delivered (CONTINUE with a progress ring).
  inProgress,

  /// First case not completed yet (NEXT CASE · ENTER).
  next,

  /// Later cases ("Complete the previous case", padlock).
  locked,
}

/// One case of a category column, with its number ("CASE 05") and state.
class CaseSlot {
  const CaseSlot({required this.courtCase, required this.number, required this.state, this.ruling});

  final CourtCase courtCase;

  /// 1-based position in the column.
  final int number;
  final CaseSlotState state;

  /// The player's ruling, if the case was opened.
  final PlayerRuling? ruling;

  /// "CASE 05"
  String get label => 'CASE ${number.toString().padLeft(2, '0')}';

  bool get isPlayable => state != CaseSlotState.locked;

  /// Builds a category column: cases the player filtered out are removed,
  /// the rest are ordered by `addedAt`; every case before the first one not
  /// completed is open, that one is next (or in progress), the others locked.
  static List<CaseSlot> column(
    Iterable<CourtCase> cases,
    Map<String, PlayerRuling> rulings,
    ContentPreferences preferences,
  ) {
    final visible = cases.where(preferences.allows).toList()
      ..sort((a, b) => (a.addedAt ?? DateTime(0)).compareTo(b.addedAt ?? DateTime(0)));
    final slots = <CaseSlot>[];
    var unlockedNext = false;
    for (final (i, c) in visible.indexed) {
      final ruling = rulings[c.id];
      final CaseSlotState state;
      if (ruling?.isCompleted ?? false) {
        state = CaseSlotState.completed;
      } else if (!unlockedNext) {
        unlockedNext = true;
        state = ruling == null ? CaseSlotState.next : CaseSlotState.inProgress;
      } else {
        state = CaseSlotState.locked;
      }
      slots.add(CaseSlot(courtCase: c, number: i + 1, state: state, ruling: ruling));
    }
    return slots;
  }
}
