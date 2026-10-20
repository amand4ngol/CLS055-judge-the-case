/// Title under the player's name ("Law Student") and the milestone bar of the
/// profile ("0/5 · 5 more cases to reach your next milestone").
enum JudgeRank {
  lawStudent('Law Student', 0),
  courtClerk('Court Clerk', 5),
  juniorJudge('Junior Judge', 10),
  judge('Judge', 20),
  seniorJudge('Senior Judge', 35),
  chiefJustice('Chief Justice', 50);

  const JudgeRank(this.label, this.minCases);
  final String label;

  /// Completed cases needed to reach this rank.
  final int minCases;

  static JudgeRank forCases(int casesJudged) =>
      values.lastWhere((r) => casesJudged >= r.minCases);

  JudgeRank? get next => index + 1 < values.length ? values[index + 1] : null;
}

/// Progress from the current rank to the next one.
class RankProgress {
  RankProgress(this.casesJudged)
      : rank = JudgeRank.forCases(casesJudged);

  final int casesJudged;
  final JudgeRank rank;

  JudgeRank? get nextRank => rank.next;
  bool get isMaxRank => nextRank == null;

  /// Cases done in the current step ("0" in "0/5").
  int get done => casesJudged - rank.minCases;

  /// Cases in the current step ("5" in "0/5"); 0 at the last rank.
  int get target => isMaxRank ? 0 : nextRank!.minCases - rank.minCases;

  int get remaining => isMaxRank ? 0 : target - done;

  /// 0 to 1, for the bar.
  double get fraction => isMaxRank ? 1 : done / target;

  /// "0/5"
  String get counterLabel => isMaxRank ? '$casesJudged' : '$done/$target';

  /// "5 more cases to reach your next milestone."
  String get message => isMaxRank
      ? 'You reached the highest rank.'
      : '$remaining more ${remaining == 1 ? 'case' : 'cases'} to reach your next milestone.';
}
