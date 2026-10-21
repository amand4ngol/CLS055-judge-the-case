import 'dart:convert';
import 'dart:io';

import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/models/firestore_parsing.dart';

/// Where a ruling stands in `ingestion/{ECLI}`, the pipeline's anti-duplicate registry.
enum IngestStatus {
  processing('processing'),
  filtered('filtered'),
  rejected('rejected'),
  failed('failed'),
  needsReview('needs_review'),
  published('published');

  const IngestStatus(this.value);
  final String value;

  static IngestStatus fromValue(String? value) =>
      values.firstWhere((s) => s.value == value, orElse: () => failed);
}

/// One registry entry. [version] is the store's revision, used to claim it safely; it is not saved.
class IngestEntry {
  const IngestEntry({
    required this.ecli,
    required this.status,
    required this.updatedAt,
    this.category,
    this.reason,
    this.model,
    this.costUsd = 0,
    this.attempts = 0,
    this.result,
    this.version,
  });

  final String ecli;
  final IngestStatus status;
  final DateTime updatedAt;
  final CaseCategory? category;
  final String? reason;
  final String? model;
  final double costUsd;
  final int attempts;

  /// The converted case, kept for rulings set aside for review.
  final Map<String, dynamic>? result;
  final String? version;

  static const claimTimeout = Duration(hours: 1);

  /// Whether a new run should spend tokens on this ruling.
  bool shouldProcess({required bool Function(CaseCategory) wants, required bool retryFailed, required DateTime now}) =>
      switch (status) {
        IngestStatus.published || IngestStatus.needsReview || IngestStatus.rejected => false,
        IngestStatus.filtered => category == null || wants(category!),
        IngestStatus.failed => retryFailed,
        IngestStatus.processing => now.difference(updatedAt) > claimTimeout,
      };

  factory IngestEntry.fromMap(String ecli, Map<String, dynamic> map, {String? version}) => IngestEntry(
        ecli: ecli,
        status: IngestStatus.fromValue(map['status'] as String?),
        updatedAt: parseDate(map['updatedAt']) ?? DateTime.fromMillisecondsSinceEpoch(0),
        category: map['category'] == null ? null : CaseCategory.fromValue(map['category'] as String?),
        reason: map['reason'] as String?,
        model: map['model'] as String?,
        costUsd: parseDouble(map['costUsd']) ?? 0,
        attempts: parseInt(map['attempts']) ?? 0,
        result: map['result'] is Map ? Map<String, dynamic>.from(map['result'] as Map) : null,
        version: version,
      );

  Map<String, dynamic> toMap() => {
        'status': status.value,
        'updatedAt': updatedAt.toUtc(),
        'category': category?.value,
        'reason': reason,
        'model': model,
        'costUsd': costUsd,
        'attempts': attempts,
        if (result != null) 'result': result,
      };
}

/// Where the pipeline reads its registry and writes cases: Firestore, or local files with --local.
abstract interface class CaseStore {
  /// Registry entries of [eclis] that exist, in one read.
  Future<Map<String, IngestEntry>> lookup(List<String> eclis);

  /// Marks [entry] as being processed by this run. False if another run changed it since [previous] was read.
  Future<bool> claim(IngestEntry entry, {IngestEntry? previous});

  Future<void> record(IngestEntry entry);

  /// Every registry entry with [status], with its stored result.
  Future<List<IngestEntry>> listStatus(IngestStatus status);

  /// Writes the case, its verdict, the country counter and the registry entry, all or nothing.
  Future<void> publish({
    required IngestEntry entry,
    required Map<String, dynamic> caseDocument,
    required Map<String, dynamic> verdictDocument,
  });
}

/// File-based store in `tool/pipeline/out/`, to try the pipeline without Firebase.
class LocalStore implements CaseStore {
  LocalStore(this.dir);

  final Directory dir;

  File get _registryFile => File('${dir.path}/registry.json');

  Map<String, dynamic> _read(File f) =>
      f.existsSync() ? Map<String, dynamic>.from(jsonDecode(f.readAsStringSync()) as Map) : <String, dynamic>{};

  void _write(File f, Object data) {
    f.parent.createSync(recursive: true);
    f.writeAsStringSync(const JsonEncoder.withIndent('  ', _encodable).convert(data));
  }

  static Object? _encodable(Object? o) => o is DateTime ? o.toUtc().toIso8601String() : o.toString();

  static String _fileName(String ecli) => ecli.replaceAll(':', '_');

  @override
  Future<Map<String, IngestEntry>> lookup(List<String> eclis) async {
    final registry = _read(_registryFile);
    return {
      for (final ecli in eclis)
        if (registry[ecli] is Map)
          ecli: IngestEntry.fromMap(ecli, Map<String, dynamic>.from(registry[ecli] as Map)),
    };
  }

  @override
  Future<List<IngestEntry>> listStatus(IngestStatus status) async => [
        for (final e in _read(_registryFile).entries)
          if ((e.value as Map)['status'] == status.value)
            IngestEntry.fromMap(e.key, Map<String, dynamic>.from(e.value as Map)),
      ];

  @override
  Future<bool> claim(IngestEntry entry, {IngestEntry? previous}) async {
    final current = (await lookup([entry.ecli]))[entry.ecli];
    if (current?.status != previous?.status || current?.updatedAt != previous?.updatedAt) return false;
    await record(entry);
    return true;
  }

  @override
  Future<void> record(IngestEntry entry) async {
    final registry = _read(_registryFile)..[entry.ecli] = entry.toMap();
    _write(_registryFile, registry);
  }

  @override
  Future<void> publish({
    required IngestEntry entry,
    required Map<String, dynamic> caseDocument,
    required Map<String, dynamic> verdictDocument,
  }) async {
    final caseFile = File('${dir.path}/cases/${_fileName(entry.ecli)}.json');
    if (caseFile.existsSync()) throw StateError('${entry.ecli} is already published');
    _write(caseFile, caseDocument);
    _write(File('${dir.path}/verdicts/${_fileName(entry.ecli)}.json'), verdictDocument);
    final countriesFile = File('${dir.path}/countries.json');
    final countries = _read(countriesFile);
    final code = caseDocument['country'] as String;
    final country = Map<String, dynamic>.from(countries[code] as Map? ?? {});
    countries[code] = {
      'name': caseDocument['countryName'],
      'publishedCases': (country['publishedCases'] as int? ?? 0) + 1,
    };
    _write(countriesFile, countries);
    await record(entry);
  }
}
