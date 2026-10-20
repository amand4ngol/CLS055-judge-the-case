import 'player_stats.dart';

/// The 8 achievements of the profile screen. They are computed from
/// [PlayerStats]; the profile only stores when each one was unlocked.
enum Achievement {
  firstRuling('first_ruling', 'I', 'First ruling!', 'Complete your first case',
      'Your first case is closed!'),
  onARoll('on_a_roll', 'III', 'On a roll!', 'Reach a 3-case streak', '3 correctly judged cases in a row!'),
  sharpJudgment('sharp_judgment', '70', 'Sharp judgment!', 'Reach 70% accuracy',
      '70% of your verdicts match the court!'),
  casebook('casebook', 'X', 'Casebook!', 'Review 10 cases', '10 cases judged!'),
  caseScholar('case_scholar', 'XX', 'Case scholar', 'Review 20 cases', '20 cases judged!'),
  courtRegular('court_regular', 'XXX', 'Court regular', 'Review 30 cases', '30 cases judged!'),
  seniorJurist('senior_jurist', 'XL', 'Senior jurist', 'Review 40 cases', '40 cases judged!'),
  masterJudge('master_judge', 'L', 'Master judge', 'Review 50 cases', '50 cases judged!');

  const Achievement(this.id, this.badge, this.title, this.description, this.unlockMessage);

  /// Key in `users/{uid}.achievements`.
  final String id;

  /// Text in the round badge (Roman numeral or number).
  final String badge;
  final String title;

  /// Condition shown under the title.
  final String description;

  /// Sentence under the badge on "You have completed an achievement!".
  final String unlockMessage;

  /// Accuracy only counts after this many cases, so one lucky verdict does
  /// not unlock "Sharp judgment".
  static const minCasesForAccuracy = 10;

  bool isEarnedBy(PlayerStats s) => switch (this) {
        firstRuling => s.casesJudged >= 1,
        onARoll => s.bestStreak >= 3,
        sharpJudgment => s.casesJudged >= minCasesForAccuracy && (s.accuracy ?? 0) >= 0.7,
        casebook => s.casesJudged >= 10,
        caseScholar => s.casesJudged >= 20,
        courtRegular => s.casesJudged >= 30,
        seniorJurist => s.casesJudged >= 40,
        masterJudge => s.casesJudged >= 50,
      };

  /// Achievements earned by [after] that [before] had not earned, in design order.
  static List<Achievement> newlyEarned(PlayerStats before, PlayerStats after) =>
      values.where((a) => a.isEarnedBy(after) && !a.isEarnedBy(before)).toList();

  static Achievement? fromId(String id) {
    for (final a in values) {
      if (a.id == id) return a;
    }
    return null;
  }
}
