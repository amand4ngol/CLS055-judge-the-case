import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/data/firestore_game_repository.dart';
import 'package:judge_the_case/data/game_repository.dart';
import 'package:judge_the_case/models.dart';
import 'package:mock_exceptions/mock_exceptions.dart';

import 'repository_contract.dart';

/// A fake database holding what the pipeline writes: [FakeData]'s cases, verdicts and countries.
Future<FakeFirebaseFirestore> seededFirestore() async {
  final db = FakeFirebaseFirestore();
  for (final (collection, docs) in [
    ('cases', FakeData.cases),
    ('verdicts', FakeData.verdicts),
    ('countries', FakeData.countries),
  ]) {
    for (final e in docs.entries) {
      await db.collection(collection).doc(e.key).set(e.value);
    }
  }
  return db;
}

void main() {
  repositoryContract('FakeGameRepository', () async => FakeGameRepository(latency: Duration.zero));
  repositoryContract(
    'FirestoreGameRepository',
    () async => FirestoreGameRepository(firestore: await seededFirestore(), auth: MockFirebaseAuth()),
  );

  group('FirestoreGameRepository', () {
    late FakeFirebaseFirestore db;
    late MockFirebaseAuth auth;
    late FirestoreGameRepository repo;
    setUp(() async {
      db = await seededFirestore();
      auth = MockFirebaseAuth();
      repo = FirestoreGameRepository(firestore: db, auth: auth);
    });

    Future<AccountError?> accountError(Future<Object?> Function() action) async {
      try {
        await action();
        return null;
      } on AccountException catch (e) {
        return e.error;
      }
    }

    test('an account is a Firebase Auth user with an internal email and a users/{uid} document', () async {
      final player = await repo.createPlayer(name: 'Anna', username: 'Anna', password: 'secret1', countryCode: 'NL');
      expect(auth.currentUser!.email, 'anna@users.judge-the-case.app');
      final doc = (await db.collection('users').doc(player.uid).get()).data()!;
      expect((doc['name'], doc['username'], doc['countryCode']), ('Anna', 'anna', 'NL'));
      expect(doc['stats'], PlayerStats.zero.toMap());
    });

    test('account errors are checked before Firebase, or translated from it', () async {
      expect(await accountError(() => repo.createPlayer(name: 'A', username: 'a b', password: 'secret1', countryCode: 'NL')),
          AccountError.invalidUsername);
      expect(await accountError(() => repo.createPlayer(name: 'A', username: 'anna', password: '12345', countryCode: 'NL')),
          AccountError.weakPassword);
      whenCalling(Invocation.method(#createUserWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'email-already-in-use'));
      expect(await accountError(() => repo.createPlayer(name: 'A', username: 'anna', password: 'secret1', countryCode: 'NL')),
          AccountError.usernameTaken);
      whenCalling(Invocation.method(#signInWithEmailAndPassword, null))
          .on(auth)
          .thenThrow(FirebaseAuthException(code: 'invalid-credential'));
      expect(await accountError(() => repo.signIn(username: 'anna', password: 'wrong!')), AccountError.wrongCredentials);
      expect(await accountError(() => repo.signIn(username: 'x', password: 'secret1')), AccountError.wrongCredentials);
    });

    test('a draft case does not count in the categories or the columns', () async {
      await repo.createPlayer(name: 'Anna', username: 'anna', password: 'secret1', countryCode: 'NL');
      final draft = Map<String, dynamic>.from(FakeData.cases[FakeData.redLightId]!)
        ..['status'] = 'draft'
        ..['category'] = 'weapons';
      await db.collection('cases').doc('ECLI:NL:DRAFT:2026:1').set(draft);
      expect(await repo.categories('NL'), isNot(contains(CaseCategory.weapons)));
      expect(await repo.caseColumn('NL', CaseCategory.weapons), isEmpty);
    });

    test('a verdict left without its result by an interruption is finished, and counted once', () async {
      final player = await repo.createPlayer(name: 'Anna', username: 'anna', password: 'secret1', countryCode: 'NL');
      final c = await repo.caseById(FakeData.whistleblowerId);
      const verdict = PlayerVerdict(options: {VerdictOption.communityService});
      await db.collection('users').doc(player.uid).collection('rulings').doc(c.id).set({
        ...PlayerRuling.start(c).toMap(),
        'status': 'completed',
        'verdict': verdict.toMap(),
        'submittedAt': DateTime.now(),
      });
      final result = await repo.deliverVerdict(c, const PlayerVerdict(options: {VerdictOption.fine}, fineEur: 500));
      expect(result.comparison.player, verdict);
      expect(result.isCorrect, isTrue);
      final stored = (await db.collection('users').doc(player.uid).collection('rulings').doc(c.id).get()).data()!;
      expect((stored['status'], stored['isCorrect']), ('completed', true));
      await repo.deliverVerdict(c, verdict);
      expect((await repo.currentPlayer())!.stats.casesJudged, 1);
    });

    test('saving progress needs an opened case', () async {
      await repo.createPlayer(name: 'Anna', username: 'anna', password: 'secret1', countryCode: 'NL');
      final c = await repo.caseById(FakeData.whistleblowerId);
      await expectLater(repo.saveProgress(PlayerRuling.start(c)), throwsStateError);
    });

    test('dates come back from Firestore as DateTime', () async {
      final player = await repo.createPlayer(name: 'Anna', username: 'anna', password: 'secret1', countryCode: 'NL');
      final raw = (await db.collection('users').doc(player.uid).get()).data()!;
      expect(raw['createdAt'], isA<Timestamp>());
      expect((await repo.currentPlayer())!.createdAt, isNotNull);
    });
  });
}
