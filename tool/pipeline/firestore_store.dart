// googleapis' Firestore library is deprecated for google_cloud_firestore_v1, still experimental.
// ignore_for_file: deprecated_member_use
import 'dart:io';

import 'package:googleapis/firestore/v1.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

import 'registry.dart';

/// Firestore store, through the REST API with a service account (which bypasses the security rules).
class FirestoreStore implements CaseStore {
  FirestoreStore(http.Client client, {required this.projectId}) : _api = FirestoreApi(client);

  /// Signs in with the service account key at [credentialsPath].
  static Future<FirestoreStore> connect({required String projectId, required String credentialsPath}) async {
    final credentials = ServiceAccountCredentials.fromJson(File(credentialsPath).readAsStringSync());
    final client = await clientViaServiceAccount(credentials, [FirestoreApi.datastoreScope]);
    return FirestoreStore(client, projectId: projectId);
  }

  final FirestoreApi _api;
  final String projectId;

  String get _database => 'projects/$projectId/databases/(default)';
  String _doc(String collection, String id) => '$_database/documents/$collection/$id';
  String _ingestion(String ecli) => _doc('ingestion', ecli);

  @override
  Future<Map<String, IngestEntry>> lookup(List<String> eclis) async {
    if (eclis.isEmpty) return {};
    final response = await _api.projects.databases.documents.batchGet(
      BatchGetDocumentsRequest(
        documents: [for (final e in eclis) _ingestion(e)],
        mask: DocumentMask(fieldPaths: ['status', 'category', 'attempts', 'updatedAt', 'costUsd', 'model']),
      ),
      _database,
    );
    return {
      for (final element in response)
        if (element.found case final doc?)
          doc.name!.split('/').last: IngestEntry.fromMap(
            doc.name!.split('/').last,
            fromFields(doc.fields ?? {}),
            version: doc.updateTime,
          ),
    };
  }

  @override
  Future<List<IngestEntry>> listStatus(IngestStatus status) async {
    final response = await _api.projects.databases.documents.runQuery(
      RunQueryRequest(
        structuredQuery: StructuredQuery(
          from: [CollectionSelector(collectionId: 'ingestion')],
          where: Filter(
            fieldFilter: FieldFilter(
              field: FieldReference(fieldPath: 'status'),
              op: 'EQUAL',
              value: Value(stringValue: status.value),
            ),
          ),
        ),
      ),
      '$_database/documents',
    );
    return [
      for (final element in response)
        if (element.document case final doc?)
          IngestEntry.fromMap(doc.name!.split('/').last, fromFields(doc.fields ?? {}), version: doc.updateTime),
    ];
  }

  @override
  Future<bool> claim(IngestEntry entry, {IngestEntry? previous}) async {
    final precondition = previous?.version == null
        ? Precondition(exists: false)
        : Precondition(updateTime: previous!.version);
    try {
      await _commit([_set('ingestion', entry.ecli, entry.toMap(), precondition: precondition)]);
      return true;
    } on DetailedApiRequestError catch (e) {
      final conflict = e.status == 409 ||
          '${e.message}'.toLowerCase().contains('precondition') ||
          '${e.jsonResponse}'.contains('FAILED_PRECONDITION');
      if (conflict) return false;
      rethrow;
    }
  }

  @override
  Future<void> record(IngestEntry entry) => _commit([_set('ingestion', entry.ecli, entry.toMap())]);

  @override
  Future<void> publish({
    required IngestEntry entry,
    required Map<String, dynamic> caseDocument,
    required Map<String, dynamic> verdictDocument,
  }) =>
      _commit(publishWrites(entry: entry, caseDocument: caseDocument, verdictDocument: verdictDocument));

  /// The writes of [publish], in one atomic commit: the case cannot be published twice.
  List<Write> publishWrites({
    required IngestEntry entry,
    required Map<String, dynamic> caseDocument,
    required Map<String, dynamic> verdictDocument,
  }) =>
      [
        _set('cases', entry.ecli, caseDocument, precondition: Precondition(exists: false)),
        _set('verdicts', entry.ecli, verdictDocument),
        Write(
          update: Document(
            name: _doc('countries', caseDocument['country'] as String),
            fields: toFields({'name': caseDocument['countryName']}),
          ),
          updateMask: DocumentMask(fieldPaths: ['name']),
          updateTransforms: [
            FieldTransform(fieldPath: 'publishedCases', increment: Value(integerValue: '1')),
          ],
        ),
        _set('ingestion', entry.ecli, entry.toMap()),
      ];

  Write _set(String collection, String id, Map<String, dynamic> data, {Precondition? precondition}) => Write(
        update: Document(name: _doc(collection, id), fields: toFields(data)),
        currentDocument: precondition,
      );

  Future<void> _commit(List<Write> writes) => _api.projects.databases.documents.commit(
        CommitRequest(writes: writes),
        _database,
      );

  static Map<String, Value> toFields(Map<String, dynamic> map) => {
        for (final e in map.entries) e.key: toValue(e.value),
      };

  /// A Dart value as a Firestore value; [DateTime] becomes a timestamp.
  static Value toValue(Object? v) => switch (v) {
        null => Value(nullValue: 'NULL_VALUE'),
        bool b => Value(booleanValue: b),
        int i => Value(integerValue: '$i'),
        double d => Value(doubleValue: d),
        String s => Value(stringValue: s),
        DateTime d => Value(timestampValue: d.toUtc().toIso8601String()),
        Map m => Value(mapValue: MapValue(fields: {for (final e in m.entries) '${e.key}': toValue(e.value)})),
        Iterable l => Value(arrayValue: ArrayValue(values: [for (final x in l) toValue(x)])),
        _ => throw ArgumentError('Type non pris en charge par Firestore : ${v.runtimeType}'),
      };

  static Map<String, dynamic> fromFields(Map<String, Value> fields) => {
        for (final e in fields.entries) e.key: fromValue(e.value),
      };

  /// A Firestore value as a Dart value; a timestamp becomes a [DateTime].
  static Object? fromValue(Value v) {
    if (v.booleanValue != null) return v.booleanValue;
    if (v.integerValue != null) return int.parse(v.integerValue!);
    if (v.doubleValue != null) return v.doubleValue;
    if (v.stringValue != null) return v.stringValue;
    if (v.timestampValue != null) return DateTime.parse(v.timestampValue!);
    if (v.mapValue != null) return fromFields(v.mapValue!.fields ?? {});
    if (v.arrayValue != null) return [for (final x in v.arrayValue!.values ?? <Value>[]) fromValue(x)];
    return null;
  }
}
