import 'firestore_parsing.dart';
import 'player_stats.dart';

/// A country of the picker: `countries/{code}`. The pipeline increments
/// [publishedCases] when it publishes a case, so the picker needs one query.
class Country {
  const Country({required this.code, required this.name, required this.publishedCases});

  /// ISO 3166-1 alpha-2 code, e.g. `NL`; also the document id.
  final String code;
  final String name;
  final int publishedCases;

  /// Flag emoji built from the code (NL → 🇳🇱).
  String get flag => String.fromCharCodes(code.toUpperCase().codeUnits.map((c) => 0x1F1E6 + c - 0x41));

  /// 0 to 1, share of this country's cases the player completed.
  double progressFor(PlayerStats stats) {
    if (publishedCases == 0) return 0;
    return ((stats.completedByCountry[code] ?? 0) / publishedCases).clamp(0, 1).toDouble();
  }

  /// "22% done" or "0%".
  String progressLabel(PlayerStats stats) {
    final pct = (progressFor(stats) * 100).round();
    return pct == 0 ? '0%' : '$pct% done';
  }

  factory Country.fromFirestore(String code, Map<String, dynamic> map) => Country(
        code: code,
        name: map['name'] as String? ?? code,
        publishedCases: parseInt(map['publishedCases']) ?? 0,
      );

  Map<String, dynamic> toMap() => {'name': name, 'publishedCases': publishedCases};
}
