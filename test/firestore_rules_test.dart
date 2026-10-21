import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Tests `firestore.rules` on the local Firestore emulator, through its REST API. Run with:
/// `npx -y firebase-tools emulators:exec --only firestore --project demo-judge-the-case "flutter test test/firestore_rules_test.dart"`
/// Without the emulator (a plain `flutter test`), the tests are skipped.
void main() {
  final host = Platform.environment['FIRESTORE_EMULATOR_HOST'];
  const project = 'demo-judge-the-case';
  final base = 'http://$host/v1/projects/$project/databases/(default)/documents';

  /// An unsigned ID token, which the emulator accepts for any user.
  String token(String uid) {
    String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return '${b64({'alg': 'none', 'typ': 'JWT'})}.${b64({
      'iss': 'https://securetoken.google.com/$project',
      'aud': project,
      'sub': uid,
      'user_id': uid,
      'iat': now,
      'exp': now + 3600,
      'auth_time': now,
      'firebase': {'sign_in_provider': 'password', 'identities': <String, dynamic>{}},
    })}.';
  }

  Map<String, String> headers(String? uid) => {
        'content-type': 'application/json',
        if (uid == 'owner') 'authorization': 'Bearer owner' else if (uid != null) 'authorization': 'Bearer ${token(uid)}',
      };

  Map<String, dynamic> fields(Map<String, String> values) => {
        'fields': {for (final e in values.entries) e.key: {'stringValue': e.value}},
      };

  Future<int> write(String path, Map<String, String> values, {required String? as}) async =>
      (await http.patch(Uri.parse('$base/$path'), headers: headers(as), body: jsonEncode(fields(values)))).statusCode;

  Future<int> read(String path, {required String? as}) async =>
      (await http.get(Uri.parse('$base/$path'), headers: headers(as))).statusCode;

  Future<int> queryPublishedCases({required String? as, bool filtered = true}) async {
    final body = {
      'structuredQuery': {
        'from': [
          {'collectionId': 'cases'},
        ],
        if (filtered)
          'where': {
            'fieldFilter': {
              'field': {'fieldPath': 'status'},
              'op': 'EQUAL',
              'value': {'stringValue': 'published'},
            },
          },
      },
    };
    return (await http.post(Uri.parse('$base:runQuery'), headers: headers(as), body: jsonEncode(body))).statusCode;
  }

  group('firestore.rules', skip: host == null ? 'needs the Firestore emulator (FIRESTORE_EMULATOR_HOST)' : false, () {
    setUp(() async {
      await http.delete(Uri.parse('http://$host/emulator/v1/projects/$project/databases/(default)/documents'));
      await write('cases/C1', {'status': 'published', 'category': 'traffic'}, as: 'owner');
      await write('cases/D1', {'status': 'draft'}, as: 'owner');
      await write('verdicts/C1', {'actualSentence': '8 months'}, as: 'owner');
      await write('countries/NL', {'name': 'Netherlands'}, as: 'owner');
      await write('ingestion/C1', {'status': 'published'}, as: 'owner');
      await write('users/alice', {'name': 'Alice'}, as: 'owner');
    });

    test('a signed-in player reads published cases and countries, nothing when signed out', () async {
      expect(await read('cases/C1', as: 'alice'), 200);
      expect(await read('countries/NL', as: 'alice'), 200);
      expect(await queryPublishedCases(as: 'alice'), 200);
      expect(await read('cases/C1', as: null), 403);
      expect(await read('countries/NL', as: null), 403);
    });

    test('draft cases and unfiltered case queries are denied', () async {
      expect(await read('cases/D1', as: 'alice'), 403);
      expect(await queryPublishedCases(as: 'alice', filtered: false), 403);
    });

    test('the verdict is hidden until the player has delivered theirs', () async {
      expect(await read('verdicts/C1', as: 'alice'), 403);
      expect(await write('users/alice/rulings/C1', {'status': 'in_progress'}, as: 'alice'), 200);
      expect(await read('verdicts/C1', as: 'alice'), 403);
      expect(await write('users/alice/rulings/C1', {'status': 'completed'}, as: 'alice'), 200);
      expect(await read('verdicts/C1', as: 'alice'), 200);
      expect(await read('verdicts/C1', as: 'bob'), 403);
    });

    test("a player only reads and writes their own data", () async {
      expect(await read('users/alice', as: 'alice'), 200);
      expect(await write('users/alice', {'name': 'Alice B.'}, as: 'alice'), 200);
      expect(await read('users/alice', as: 'bob'), 403);
      expect(await write('users/alice', {'name': 'Hacked'}, as: 'bob'), 403);
      expect(await write('users/alice/rulings/C1', {'status': 'completed'}, as: 'bob'), 403);
    });

    test('the pipeline collections cannot be read or written by players', () async {
      expect(await read('ingestion/C1', as: 'alice'), 403);
      expect(await write('cases/C2', {'status': 'published'}, as: 'alice'), 403);
      expect(await write('verdicts/C1', {'actualSentence': 'none'}, as: 'alice'), 403);
      expect(await write('countries/NL', {'name': 'X'}, as: 'alice'), 403);
    });
  });
}
