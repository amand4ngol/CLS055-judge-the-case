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

/// [MockFirebaseAuth] accepts any password and never forgets a user. This one keeps the accounts
/// as Firebase Auth does: wrong passwords and deleted accounts are refused.
class _AccountsAuth extends MockFirebaseAuth {
  final _passwords = <String, String>{};
  final _users = <String, MockUser>{};

  /// Runs once a user is created, as another phone could act between two steps of "Create account".
  Future<void> Function()? afterCreate;

  @override
  Future<UserCredential> createUserWithEmailAndPassword({required String email, required String password}) async {
    if (_passwords.containsKey(email)) throw FirebaseAuthException(code: 'email-already-in-use');
    final created = await super.createUserWithEmailAndPassword(email: email, password: password);
    _passwords[email] = password;
    mockUser = _users[email] = _Account(this, uid: created.user!.uid, email: email);
    await afterCreate?.call();
    return signInWithCredential(null);
  }

  @override
  Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    if (_passwords[email] != password) throw FirebaseAuthException(code: 'invalid-credential');
    mockUser = _users[email];
    return super.signInWithEmailAndPassword(email: email, password: password);
  }
}

// ignore: must_be_immutable
class _Account extends MockUser {
  _Account(this._auth, {super.uid, super.email});

  final _AccountsAuth _auth;

  @override
  Future<UserCredential> reauthenticateWithCredential(AuthCredential? credential) async {
    if (_auth._passwords[email] != (credential as EmailAuthCredential).password) {
      throw FirebaseAuthException(code: 'invalid-credential');
    }
    return super.reauthenticateWithCredential(credential);
  }

  @override
  Future<void> delete() async {
    _auth._passwords.remove(email);
    _auth._users.remove(email);
    await _auth.signOut();
  }
}

void main() {
  repositoryContract('FakeGameRepository', () async => FakeGameRepository(latency: Duration.zero));
  repositoryContract(
    'FirestoreGameRepository',
    () async => FirestoreGameRepository(firestore: await seededFirestore(), auth: _AccountsAuth()),
  );

  group('FirestoreGameRepository', () {
    late FakeFirebaseFirestore db;
    late _AccountsAuth auth;
    late FirestoreGameRepository repo;
    setUp(() async {
      db = await seededFirestore();
      auth = _AccountsAuth();
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

    Future<Map<String, dynamic>?> usernameEntry(String username) async =>
        (await db.collection('usernames').doc(username).get()).data();

    test('an account is a Firebase Auth user with an internal email, users/{uid} and usernames/{username}', () async {
      final player = await repo.createPlayer(name: 'Anna', username: 'Anna', password: 'secret1', countryCode: 'NL');
      final email = auth.currentUser!.email!;
      expect(email, allOf(startsWith('account-'), endsWith('@users.judge-the-case.app')));
      expect(await usernameEntry('anna'), {'uid': player.uid, 'email': email});
      final doc = (await db.collection('users').doc(player.uid).get()).data()!;
      expect((doc['name'], doc['username'], doc['countryCode']), ('Anna', 'anna', 'NL'));
      expect(doc['stats'], PlayerStats.zero.toMap());
    });

    test('a new username moves the usernames/ entry and keeps the Firebase Auth email', () async {
      final player = await repo.createPlayer(name: 'Anna', username: 'anna', password: 'secret1', countryCode: 'NL');
      final email = auth.currentUser!.email;
      await repo.updateProfile(username: 'anne');
      expect(await usernameEntry('anna'), isNull);
      expect(await usernameEntry('anne'), {'uid': player.uid, 'email': email});
      expect((await db.collection('users').doc(player.uid).get()).data()!['username'], 'anne');
      expect(auth.currentUser!.email, email);
    });

    test('a username taken during "Create account" deletes the new Firebase Auth user', () async {
      auth.afterCreate = () => db.collection('usernames').doc('anna').set({'uid': 'someone', 'email': 'x'});
      expect(await accountError(() => repo.createPlayer(name: 'A', username: 'anna', password: 'secret1', countryCode: 'NL')),
          AccountError.usernameTaken);
      expect(auth.currentUser, isNull);
      expect(auth._passwords, isEmpty);
      expect((await db.collection('users').get()).docs, isEmpty);
    });

    test('an account from before usernames/ logs in with its old email and claims its username', () async {
      final email = Usernames.legacyEmail('anna');
      final user = (await auth.createUserWithEmailAndPassword(email: email, password: 'secret1')).user!;
      await db
          .collection('users')
          .doc(user.uid)
          .set(PlayerProfile(uid: user.uid, name: 'Anna', username: 'anna', countryCode: 'NL').toMap());
      await auth.signOut();

      expect((await repo.signIn(username: 'anna', password: 'secret1')).uid, user.uid);
      expect(await usernameEntry('anna'), {'uid': user.uid, 'email': email});
      await repo.updateProfile(username: 'anne');
      await repo.signOut();
      expect(await accountError(() => repo.signIn(username: 'anna', password: 'secret1')), AccountError.wrongCredentials);
      expect(auth.currentUser, isNull);
      expect((await repo.signIn(username: 'anne', password: 'secret1')).uid, user.uid);
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

    test('deleting the account deletes users/{uid}, its rulings, its username and the Firebase Auth user', () async {
      final player = await repo.createPlayer(name: 'Anna', username: 'anna', password: 'secret1', countryCode: 'NL');
      await repo.deliverVerdict(await repo.caseById(FakeData.whistleblowerId),
          const PlayerVerdict(options: {VerdictOption.communityService}));
      await repo.openCase(await repo.caseById(FakeData.healingWeekendId));
      final userDoc = db.collection('users').doc(player.uid);
      expect((await userDoc.collection('rulings').get()).docs, hasLength(2));

      await repo.deleteAccount(password: 'secret1');
      expect((await userDoc.get()).exists, isFalse);
      expect(await usernameEntry('anna'), isNull);
      expect((await userDoc.collection('rulings').get()).docs, isEmpty);
      expect(auth.currentUser, isNull);
      expect(await accountError(() => repo.signIn(username: 'anna', password: 'secret1')), AccountError.wrongCredentials);
    });

    test('dates come back from Firestore as DateTime', () async {
      final player = await repo.createPlayer(name: 'Anna', username: 'anna', password: 'secret1', countryCode: 'NL');
      final raw = (await db.collection('users').doc(player.uid).get()).data()!;
      expect(raw['createdAt'], isA<Timestamp>());
      expect((await repo.currentPlayer())!.createdAt, isNotNull);
    });
  });
}
