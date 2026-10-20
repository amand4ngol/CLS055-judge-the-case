import 'achievement.dart';
import 'case_verdict.dart';
import 'court_case.dart';
import 'judge_rank.dart';
import 'player_profile.dart';
import 'player_ruling.dart';
import 'player_verdict.dart';
import 'ruling_comparison.dart';

/// Everything that changes when the player taps "Deliver Verdict", and what
/// the result and achievement screens show. [evaluate] is pure, so the fake
/// repository and the Firestore one apply the same rules.
class RulingResult {
  const RulingResult({
    required this.courtCase,
    required this.comparison,
    required this.ruling,
    required this.profileBefore,
    required this.profile,
    required this.newAchievements,
  });

  static RulingResult evaluate({
    required PlayerProfile profile,
    required CourtCase courtCase,
    required PlayerRuling ruling,
    required PlayerVerdict verdict,
    required CaseVerdict courtVerdict,
    DateTime? at,
  }) {
    final now = at ?? DateTime.now();
    final comparison = RulingComparison.compare(verdict, courtVerdict);
    if (ruling.isCompleted) {
      // Revising a past case changes nothing.
      return RulingResult(
        courtCase: courtCase,
        comparison: RulingComparison.compare(ruling.verdict, courtVerdict),
        ruling: ruling,
        profileBefore: profile,
        profile: profile,
        newAchievements: const [],
      );
    }
    final stats = profile.stats.record(
      correct: comparison.isCorrect,
      country: courtCase.country,
      category: courtCase.category.value,
    );
    final earned = Achievement.newlyEarned(profile.stats, stats)
        .where((a) => !profile.hasUnlocked(a))
        .toList();
    return RulingResult(
      courtCase: courtCase,
      comparison: comparison,
      ruling: ruling.complete(comparison, at: now),
      profileBefore: profile,
      profile: profile.copyWith(
        stats: stats,
        achievements: {...profile.achievements, for (final a in earned) a: now},
      ),
      newAchievements: earned,
    );
  }

  final CourtCase courtCase;
  final RulingComparison comparison;

  /// The completed ruling to save in `users/{uid}/rulings/{caseId}`.
  final PlayerRuling ruling;
  final PlayerProfile profileBefore;

  /// The updated profile to save in `users/{uid}`.
  final PlayerProfile profile;

  /// Shown one by one on "You have completed an achievement!".
  final List<Achievement> newAchievements;

  CaseVerdict get courtVerdict => comparison.court;
  bool get isCorrect => comparison.isCorrect;

  /// Set when this case moved the player to a new rank.
  JudgeRank? get newRank => profile.rank != profileBefore.rank ? profile.rank : null;
}
