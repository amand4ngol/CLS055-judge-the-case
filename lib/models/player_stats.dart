import 'firestore_parsing.dart';

/// Counters on the profile ("Cases statistics") and behind the achievements,
/// the rank and the country progress. Stored in `users/{uid}.stats` and
/// updated once per completed case with [record].
class PlayerStats {
  const PlayerStats({
    this.casesJudged = 0,
    this.correctVerdicts = 0,
    this.currentStreak = 0,
    this.bestStreak = 0,
    this.completedByCountry = const {},
    this.completedByCategory = const {},
  });

  static const zero = PlayerStats();

  final int casesJudged;
  final int correctVerdicts;

  /// Correct verdicts in a row, reset by an incorrect one.
  final int currentStreak;
  final int bestStreak;

  /// Completed cases per country code, for "22% done" in the country picker.
  final Map<String, int> completedByCountry;

  /// Completed cases per category value.
  final Map<String, int> completedByCategory;

  /// 0 to 1, or null before the first case (the design shows "–").
  double? get accuracy => casesJudged == 0 ? null : correctVerdicts / casesJudged;

  /// "–" or "67%".
  String get accuracyLabel => accuracy == null ? '–' : '${(accuracy! * 100).round()}%';

  /// "–" or "3".
  String get bestStreakLabel => casesJudged == 0 ? '–' : '$bestStreak';

  /// Stats after one more completed case.
  PlayerStats record({required bool correct, required String country, required String category}) {
    final streak = correct ? currentStreak + 1 : 0;
    return PlayerStats(
      casesJudged: casesJudged + 1,
      correctVerdicts: correctVerdicts + (correct ? 1 : 0),
      currentStreak: streak,
      bestStreak: streak > bestStreak ? streak : bestStreak,
      completedByCountry: {...completedByCountry, country: (completedByCountry[country] ?? 0) + 1},
      completedByCategory: {...completedByCategory, category: (completedByCategory[category] ?? 0) + 1},
    );
  }

  factory PlayerStats.fromMap(Map<String, dynamic> map) => PlayerStats(
        casesJudged: parseInt(map['casesJudged']) ?? 0,
        correctVerdicts: parseInt(map['correctVerdicts']) ?? 0,
        currentStreak: parseInt(map['currentStreak']) ?? 0,
        bestStreak: parseInt(map['bestStreak']) ?? 0,
        completedByCountry: parseIntMap(map['completedByCountry']),
        completedByCategory: parseIntMap(map['completedByCategory']),
      );

  Map<String, dynamic> toMap() => {
        'casesJudged': casesJudged,
        'correctVerdicts': correctVerdicts,
        'currentStreak': currentStreak,
        'bestStreak': bestStreak,
        'completedByCountry': completedByCountry,
        'completedByCategory': completedByCategory,
      };
}
