import 'court_case.dart';
import 'enums.dart';
import 'firestore_parsing.dart';
import 'player_verdict.dart';
import 'ruling_comparison.dart';

/// One case as played by one player: `users/{uid}/rulings/{caseId}`.
///
/// Created when the player enters a case (status `in_progress`, drives the
/// CONTINUE button and its progress ring), then completed when the verdict is
/// delivered. Its existence with status `completed` is what the security
/// rules check before letting the player read `verdicts/{caseId}`.
///
/// It copies a few fields of the case so the profile ("Revise your previous
/// cases") and the progress counters need no extra read.
class PlayerRuling {
  const PlayerRuling({
    required this.caseId,
    required this.status,
    required this.caseTitle,
    required this.category,
    required this.country,
    required this.year,
    required this.argumentsCount,
    this.argumentsRead = 0,
    this.verdict = PlayerVerdict.empty,
    this.isCorrect,
    this.startedAt,
    this.submittedAt,
  });

  /// A new in-progress ruling when the player enters [courtCase].
  factory PlayerRuling.start(CourtCase courtCase, {DateTime? at}) => PlayerRuling(
        caseId: courtCase.id,
        status: RulingStatus.inProgress,
        caseTitle: courtCase.title,
        category: courtCase.category,
        country: courtCase.country,
        year: courtCase.year,
        argumentsCount: courtCase.arguments.length,
        startedAt: at ?? DateTime.now(),
      );

  final String caseId;
  final RulingStatus status;
  final String caseTitle;
  final CaseCategory category;
  final String country;
  final int year;

  /// Argument cards in the case, and how many the player swiped through.
  final int argumentsCount;
  final int argumentsRead;

  /// Draft selection while in progress, the delivered verdict once completed.
  final PlayerVerdict verdict;

  /// Null until the verdict has been compared with the court's.
  final bool? isCorrect;
  final DateTime? startedAt;
  final DateTime? submittedAt;

  bool get isCompleted => status == RulingStatus.completed;

  /// 0 to 1, for the CONTINUE progress ring: arguments read count for 80%,
  /// a verdict selection for the rest.
  double get progress {
    if (isCompleted) return 1;
    final args = argumentsCount == 0 ? 1.0 : argumentsRead / argumentsCount;
    return (args.clamp(0, 1) * 0.8 + (verdict.options.isEmpty ? 0 : 0.2)).toDouble();
  }

  /// Saves where the player is in the case (argument cards read, draft verdict).
  PlayerRuling withProgress({int? argumentsRead, PlayerVerdict? verdict}) => _copy(
        argumentsRead: argumentsRead?.clamp(this.argumentsRead, argumentsCount).toInt(),
        verdict: verdict,
      );

  /// The delivered verdict, once compared with the court's.
  PlayerRuling complete(RulingComparison comparison, {DateTime? at}) => _copy(
        status: RulingStatus.completed,
        argumentsRead: argumentsCount,
        verdict: comparison.player,
        isCorrect: comparison.isCorrect,
        submittedAt: at ?? DateTime.now(),
      );

  PlayerRuling _copy({
    RulingStatus? status,
    int? argumentsRead,
    PlayerVerdict? verdict,
    bool? isCorrect,
    DateTime? submittedAt,
  }) =>
      PlayerRuling(
        caseId: caseId,
        status: status ?? this.status,
        caseTitle: caseTitle,
        category: category,
        country: country,
        year: year,
        argumentsCount: argumentsCount,
        argumentsRead: argumentsRead ?? this.argumentsRead,
        verdict: verdict ?? this.verdict,
        isCorrect: isCorrect ?? this.isCorrect,
        startedAt: startedAt,
        submittedAt: submittedAt ?? this.submittedAt,
      );

  factory PlayerRuling.fromFirestore(String caseId, Map<String, dynamic> map) => PlayerRuling(
        caseId: caseId,
        status: RulingStatus.fromValue(map['status'] as String?),
        caseTitle: map['caseTitle'] as String? ?? '',
        category: CaseCategory.fromValue(map['category'] as String?),
        country: map['country'] as String? ?? '',
        year: parseInt(map['year']) ?? 0,
        argumentsCount: parseInt(map['argumentsCount']) ?? 0,
        argumentsRead: parseInt(map['argumentsRead']) ?? 0,
        verdict: PlayerVerdict.fromMap(parseMap(map['verdict'])),
        isCorrect: map['isCorrect'] as bool?,
        startedAt: parseDate(map['startedAt']),
        submittedAt: parseDate(map['submittedAt']),
      );

  Map<String, dynamic> toMap() => {
        'status': status.value,
        'caseTitle': caseTitle,
        'category': category.value,
        'country': country,
        'year': year,
        'argumentsCount': argumentsCount,
        'argumentsRead': argumentsRead,
        'verdict': verdict.toMap(),
        'isCorrect': isCorrect,
        'startedAt': startedAt,
        'submittedAt': submittedAt,
      };
}
