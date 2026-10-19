import 'achievement.dart';
import 'content_preferences.dart';
import 'firestore_parsing.dart';
import 'judge_rank.dart';
import 'player_stats.dart';

/// The player: `users/{uid}`. Created by "Create account"; the password is
/// handled by Firebase Auth and never stored here.
class PlayerProfile {
  const PlayerProfile({
    required this.uid,
    required this.name,
    required this.username,
    required this.countryCode,
    this.preferences = ContentPreferences.none,
    this.stats = PlayerStats.zero,
    this.achievements = const {},
    this.createdAt,
  });

  final String uid;

  /// "Isabella" in "Judge Isabella".
  final String name;
  final String username;

  /// Country the player rules in (flag at the top of the home screen).
  final String countryCode;
  final ContentPreferences preferences;
  final PlayerStats stats;

  /// Unlock date of each achievement earned.
  final Map<Achievement, DateTime> achievements;
  final DateTime? createdAt;

  /// "Judge Isabella"
  String get displayName => 'Judge $name';

  JudgeRank get rank => JudgeRank.forCases(stats.casesJudged);
  RankProgress get rankProgress => RankProgress(stats.casesJudged);

  bool hasUnlocked(Achievement a) => achievements.containsKey(a);

  /// "0/8 unlocked"
  String get achievementsLabel => '${achievements.length}/${Achievement.values.length} unlocked';

  PlayerProfile copyWith({
    String? name,
    String? countryCode,
    ContentPreferences? preferences,
    PlayerStats? stats,
    Map<Achievement, DateTime>? achievements,
  }) =>
      PlayerProfile(
        uid: uid,
        name: name ?? this.name,
        username: username,
        countryCode: countryCode ?? this.countryCode,
        preferences: preferences ?? this.preferences,
        stats: stats ?? this.stats,
        achievements: achievements ?? this.achievements,
        createdAt: createdAt,
      );

  factory PlayerProfile.fromFirestore(String uid, Map<String, dynamic> map) {
    final unlocked = <Achievement, DateTime>{};
    parseMap(map['achievements']).forEach((id, at) {
      final a = Achievement.fromId(id);
      final date = parseDate(at);
      if (a != null && date != null) unlocked[a] = date;
    });
    return PlayerProfile(
      uid: uid,
      name: map['name'] as String? ?? '',
      username: map['username'] as String? ?? '',
      countryCode: map['countryCode'] as String? ?? 'NL',
      preferences: ContentPreferences.fromMap(parseMap(map['preferences'])),
      stats: PlayerStats.fromMap(parseMap(map['stats'])),
      achievements: unlocked,
      createdAt: parseDate(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'username': username,
        'countryCode': countryCode,
        'preferences': preferences.toMap(),
        'stats': stats.toMap(),
        'achievements': {for (final e in achievements.entries) e.key.id: e.value},
        'createdAt': createdAt,
      };
}
