/// Small helpers to read Firestore maps without depending on cloud_firestore.
library;

/// Accepts a Firestore `Timestamp` (anything with `toDate()`), a [DateTime]
/// or an ISO-8601 string.
DateTime? parseDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value);
  try {
    final date = (value as dynamic).toDate();
    if (date is DateTime) return date;
  } on NoSuchMethodError {
    return null;
  }
  return null;
}

double? parseDouble(Object? value) => value is num ? value.toDouble() : null;

int? parseInt(Object? value) => value is num ? value.toInt() : null;

List<String> parseStringList(Object? value) =>
    value is List ? value.whereType<String>().toList() : const [];

List<Map<String, dynamic>> parseMapList(Object? value) => value is List
    ? value.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList()
    : const [];

bool parseBool(Object? value, {bool fallback = false}) => value is bool ? value : fallback;

Map<String, int> parseIntMap(Object? value) => value is Map
    ? {
        for (final e in value.entries)
          if (e.key is String && e.value is num) e.key as String: (e.value as num).toInt(),
      }
    : const {};

Map<String, dynamic> parseMap(Object? value) =>
    value is Map ? Map<String, dynamic>.from(value) : const {};
