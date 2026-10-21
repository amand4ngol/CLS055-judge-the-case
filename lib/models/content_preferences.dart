import 'court_case.dart';
import 'enums.dart';
import 'firestore_parsing.dart';

/// Settings > Content preferences, and the trigger warning's
/// "Do not show me sensitive cases again". Stored in `users/{uid}.preferences`.
class ContentPreferences {
  const ContentPreferences({
    this.hideSensitiveCases = false,
    this.filteredTopics = const {},
    this.hasSeenTriggerWarning = false,
  });

  static const none = ContentPreferences();

  /// Hides every case with at least one content warning.
  final bool hideSensitiveCases;

  /// Topics filtered one by one in the settings.
  final Set<ContentWarning> filteredTopics;

  /// The trigger warning shows once: after "Enter anyways", the player
  /// manages sensitive cases from the settings instead.
  final bool hasSeenTriggerWarning;

  /// Whether [c] appears in the case columns.
  bool allows(CourtCase c) =>
      hideSensitiveCases ? !c.isSensitive : !c.isHiddenBy(filteredTopics);

  /// Whether to show the trigger warning before [c].
  bool needsWarning(CourtCase c) =>
      !hasSeenTriggerWarning && allows(c) && c.isSensitive;

  ContentPreferences copyWith({
    bool? hideSensitiveCases,
    Set<ContentWarning>? filteredTopics,
    bool? hasSeenTriggerWarning,
  }) => ContentPreferences(
    hideSensitiveCases: hideSensitiveCases ?? this.hideSensitiveCases,
    filteredTopics: filteredTopics ?? this.filteredTopics,
    hasSeenTriggerWarning: hasSeenTriggerWarning ?? this.hasSeenTriggerWarning,
  );

  ContentPreferences toggleTopic(ContentWarning topic) => copyWith(
    filteredTopics: filteredTopics.contains(topic)
        ? ({...filteredTopics}..remove(topic))
        : {...filteredTopics, topic},
  );

  factory ContentPreferences.fromMap(Map<String, dynamic> map) =>
      ContentPreferences(
        hideSensitiveCases: parseBool(map['hideSensitiveCases']),
        filteredTopics: parseStringList(
          map['filteredTopics'],
        ).map(ContentWarning.fromValue).whereType<ContentWarning>().toSet(),
        hasSeenTriggerWarning: parseBool(map['hasSeenTriggerWarning']),
      );

  Map<String, dynamic> toMap() => {
    'hideSensitiveCases': hideSensitiveCases,
    'filteredTopics': ContentWarning.values
        .where(filteredTopics.contains)
        .map((w) => w.value)
        .toList(),
    'hasSeenTriggerWarning': hasSeenTriggerWarning,
  };
}
