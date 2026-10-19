import 'case_argument.dart';
import 'enums.dart';
import 'firestore_parsing.dart';

/// A case as read from Firestore `cases/{ecli}`: everything the app shows
/// before the player delivers a verdict. The answer lives in [CaseVerdict].
class CourtCase {
  const CourtCase({
    required this.id,
    required this.status,
    required this.country,
    required this.countryName,
    required this.year,
    required this.decisionDate,
    required this.legalArea,
    required this.category,
    required this.title,
    required this.court,
    required this.charges,
    required this.summaryShort,
    required this.summaryLong,
    required this.arguments,
    required this.contentWarnings,
    required this.sourceUrl,
    required this.addedAt,
  });

  /// ECLI, also the document id in `cases` and `verdicts`.
  final String id;
  final CaseStatus status;

  /// ISO 3166-1 alpha-2 code, e.g. `NL`.
  final String country;
  final String countryName;
  final int year;
  final DateTime? decisionDate;
  final LegalArea legalArea;
  final CaseCategory category;
  final String title;
  final String court;
  final List<String> charges;
  final String summaryShort;
  final String summaryLong;
  final List<CaseArgument> arguments;
  final Set<ContentWarning> contentWarnings;

  /// Official ruling on rechtspraak.nl ("Get to the detailed case here").
  final Uri sourceUrl;

  /// Orders cases inside a category column.
  final DateTime? addedAt;

  bool get isSensitive => contentWarnings.isNotEmpty;

  /// "Netherlands · 2026"
  String get originLabel => '$countryName · $year';

  /// True when the case touches a topic the player chose to filter out.
  bool isHiddenBy(Set<ContentWarning> filteredTopics) =>
      contentWarnings.any(filteredTopics.contains);

  factory CourtCase.fromFirestore(String id, Map<String, dynamic> map) => CourtCase(
        id: id,
        status: CaseStatus.fromValue(map['status'] as String?),
        country: map['country'] as String? ?? '',
        countryName: map['countryName'] as String? ?? '',
        year: parseInt(map['year']) ?? 0,
        decisionDate: parseDate(map['decisionDate']),
        legalArea: LegalArea.fromValue(map['legalArea'] as String?),
        category: CaseCategory.fromValue(map['category'] as String?),
        title: map['title'] as String? ?? '',
        court: map['court'] as String? ?? '',
        charges: parseStringList(map['charges']),
        summaryShort: map['summaryShort'] as String? ?? '',
        summaryLong: map['summaryLong'] as String? ?? '',
        arguments: parseMapList(map['arguments']).map(CaseArgument.fromMap).toList(),
        contentWarnings: parseStringList(map['contentWarnings'])
            .map(ContentWarning.fromValue)
            .whereType<ContentWarning>()
            .toSet(),
        sourceUrl: Uri.parse(map['sourceUrl'] as String? ?? 'https://deeplink.rechtspraak.nl/uitspraak?id=$id'),
        addedAt: parseDate(map['addedAt']),
      );

  /// Plain map; dates are [DateTime], which cloud_firestore stores as Timestamp.
  Map<String, dynamic> toMap() => {
        'status': status.value,
        'country': country,
        'countryName': countryName,
        'year': year,
        'decisionDate': decisionDate,
        'legalArea': legalArea.value,
        'category': category.value,
        'title': title,
        'court': court,
        'charges': charges,
        'summaryShort': summaryShort,
        'summaryLong': summaryLong,
        'arguments': arguments.map((a) => a.toMap()).toList(),
        'contentWarnings': contentWarnings.map((w) => w.value).toList(),
        'sourceUrl': sourceUrl.toString(),
        'addedAt': addedAt,
      };
}
