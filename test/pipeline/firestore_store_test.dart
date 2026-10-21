import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:judge_the_case/models.dart';

import '../../tool/pipeline/firestore_store.dart';
import '../../tool/pipeline/registry.dart';

void main() {
  const ecli = 'ECLI:NL:RBNHO:2026:13327';
  final entry = IngestEntry(ecli: ecli, status: IngestStatus.published, updatedAt: DateTime.utc(2026, 10, 20));

  test('Dart values round-trip through Firestore values', () {
    final data = {
      'text': 'a',
      'count': 3,
      'amount': 8.5,
      'flag': true,
      'none': null,
      'at': DateTime.utc(2026, 10, 1, 9),
      'list': ['x', 1],
      'map': {'nested': 2},
    };
    final value = FirestoreStore.toValue(data);
    expect(value.mapValue!.fields!['at']!.timestampValue, '2026-10-01T09:00:00.000Z');
    expect(value.mapValue!.fields!['count']!.integerValue, '3');
    expect(FirestoreStore.fromFields(value.mapValue!.fields!), data);
  });

  test('publishing is one commit that cannot publish a case twice', () {
    final store = FirestoreStore(MockClient((_) async => http.Response('{}', 200)), projectId: 'demo');
    final writes = store.publishWrites(
      entry: entry,
      caseDocument: {'country': 'NL', 'countryName': 'Netherlands', 'title': 'Red Light at 130'},
      verdictDocument: {'actualSentence': '8 months'},
    );
    expect(writes.map((w) => w.update!.name!.split('/documents/').last),
        ['cases/$ecli', 'verdicts/$ecli', 'countries/NL', 'ingestion/$ecli']);
    expect(writes[0].currentDocument!.exists, isFalse);
    expect(writes[2].updateMask!.fieldPaths, ['name']);
    expect(writes[2].updateTransforms!.single.fieldPath, 'publishedCases');
    expect(writes[2].updateTransforms!.single.increment!.integerValue, '1');
    expect(writes[3].update!.fields!['status']!.stringValue, 'published');
  });

  test('lookup reads the registry in one request', () async {
    final requests = <http.Request>[];
    final store = FirestoreStore(
      MockClient((req) async {
        requests.add(req);
        return http.Response(
            jsonEncode([
              {
                'found': {
                  'name': 'projects/demo/databases/(default)/documents/ingestion/$ecli',
                  'fields': {
                    'status': {'stringValue': 'filtered'},
                    'category': {'stringValue': 'theft'},
                    'updatedAt': {'timestampValue': '2026-10-20T00:00:00Z'},
                  },
                  'updateTime': '2026-10-20T00:00:01.000001Z',
                },
              },
              {'missing': 'projects/demo/databases/(default)/documents/ingestion/ECLI:NL:GHAMS:2026:1'},
            ]),
            200,
            headers: {'content-type': 'application/json'});
      }),
      projectId: 'demo',
    );
    final found = await store.lookup([ecli, 'ECLI:NL:GHAMS:2026:1']);
    expect(requests, hasLength(1));
    expect(requests.single.url.path, endsWith('/documents:batchGet'));
    expect(found.keys, [ecli]);
    expect(found[ecli]!.status, IngestStatus.filtered);
    expect(found[ecli]!.category, CaseCategory.theft);
    expect(found[ecli]!.version, '2026-10-20T00:00:01.000001Z');
  });

  test('a claim that loses the race returns false', () async {
    final store = FirestoreStore(
      MockClient((req) async {
        final write = (jsonDecode(req.body)['writes'] as List).single as Map;
        expect(write['currentDocument'], {'exists': false});
        return http.Response(
            jsonEncode({
              'error': {'code': 409, 'message': 'Document already exists', 'status': 'ALREADY_EXISTS'},
            }),
            409,
            headers: {'content-type': 'application/json'});
      }),
      projectId: 'demo',
    );
    final claim = IngestEntry(ecli: ecli, status: IngestStatus.processing, updatedAt: DateTime.utc(2026));
    expect(await store.claim(claim), isFalse);
  });
}
