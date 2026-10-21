import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models.dart';
import 'game_repository.dart';

/// [GameRepository] on Cloud Firestore and Firebase Auth: the real database the pipeline fills.
/// Documents go through the models' `fromFirestore` / `toMap`, and the game rules stay in
/// [CaseSlot.column] and [RulingResult.evaluate], as in [FakeGameRepository].
class FirestoreGameRepository implements GameRepository {
  FirestoreGameRepository({FirebaseFirestore? firestore, FirebaseAuth? auth})
      : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  CollectionReference<Map<String, dynamic>> get _cases => _db.collection('cases');
  CollectionReference<Map<String, dynamic>> get _verdicts => _db.collection('verdicts');
  CollectionReference<Map<String, dynamic>> get _users => _db.collection('users');

  String get _uid => _auth.currentUser?.uid ?? (throw StateError('No player: sign in first'));
  DocumentReference<Map<String, dynamic>> get _userDoc => _users.doc(_uid);
  CollectionReference<Map<String, dynamic>> get _rulings => _userDoc.collection('rulings');

  Query<Map<String, dynamic>> _published(String country) => _cases
      .where('status', isEqualTo: CaseStatus.published.value)
      .where('country', isEqualTo: country);

  Future<PlayerProfile> _requirePlayer() async =>
      await currentPlayer() ?? (throw StateError('No player: create an account first'));

  @override
  Future<PlayerProfile?> currentPlayer() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final data = (await _users.doc(user.uid).get()).data();
    return data == null ? null : PlayerProfile.fromFirestore(user.uid, data);
  }

  @override
  Future<PlayerProfile> createPlayer({
    required String name,
    required String username,
    required String password,
    required String countryCode,
  }) async {
    Usernames.check(username, password);
    final id = Usernames.normalize(username);
    final credential = await _account(
        () => _auth.createUserWithEmailAndPassword(email: Usernames.email(id), password: password));
    final profile = PlayerProfile(
      uid: credential.user!.uid,
      name: name.trim(),
      username: id,
      countryCode: countryCode,
      createdAt: DateTime.now(),
    );
    await _users.doc(profile.uid).set(profile.toMap());
    return profile;
  }

  @override
  Future<PlayerProfile> signIn({required String username, required String password}) async {
    if (!Usernames.isValid(username)) throw const AccountException(AccountError.wrongCredentials);
    await _account(() => _auth.signInWithEmailAndPassword(email: Usernames.email(username), password: password));
    return _requirePlayer();
  }

  @override
  Future<void> signOut() => _auth.signOut();

  static Future<T> _account<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      final error = switch (e.code) {
        'email-already-in-use' => AccountError.usernameTaken,
        'invalid-email' => AccountError.invalidUsername,
        'weak-password' => AccountError.weakPassword,
        'invalid-credential' || 'wrong-password' || 'user-not-found' || 'user-disabled' =>
          AccountError.wrongCredentials,
        'network-request-failed' || 'too-many-requests' => AccountError.network,
        _ => null,
      };
      if (error == null) rethrow;
      throw AccountException(error);
    }
  }

  @override
  Future<List<Country>> countries() async {
    final snap = await _db.collection('countries').get();
    return [for (final d in snap.docs) Country.fromFirestore(d.id, d.data())];
  }

  @override
  Future<PlayerProfile> setCountry(String countryCode) async {
    final player = await _requirePlayer();
    await _userDoc.update({'countryCode': countryCode});
    return player.copyWith(countryCode: countryCode);
  }

  @override
  Future<PlayerProfile> savePreferences(ContentPreferences preferences) async {
    final player = await _requirePlayer();
    await _userDoc.update({'preferences': preferences.toMap()});
    return player.copyWith(preferences: preferences);
  }

  /// One count query per category, each billed as a single read.
  @override
  Future<List<CaseCategory>> categories(String countryCode) async {
    final counts = await Future.wait([
      for (final c in CaseCategory.values)
        _published(countryCode).where('category', isEqualTo: c.value).count().get(),
    ]);
    return [
      for (final (i, c) in CaseCategory.values.indexed)
        if ((counts[i].count ?? 0) > 0) c,
    ];
  }

  @override
  Future<List<CaseSlot>> caseColumn(String countryCode, CaseCategory category) async =>
      _column(await _requirePlayer(), countryCode, category);

  Future<List<CaseSlot>> _column(PlayerProfile player, String country, CaseCategory category) async {
    final (cases, rulings) = await (
      _published(country).where('category', isEqualTo: category.value).orderBy('addedAt').get(),
      _rulings.where('category', isEqualTo: category.value).get(),
    ).wait;
    return CaseSlot.column(
      [for (final d in cases.docs) CourtCase.fromFirestore(d.id, d.data())],
      {for (final d in rulings.docs) d.id: PlayerRuling.fromFirestore(d.id, d.data())},
      player.preferences,
    );
  }

  /// The case's slot in the player's column; throws if it is locked or hidden by the settings.
  Future<CaseSlot> _playableSlot(PlayerProfile player, CourtCase courtCase) async {
    final slot = (await _column(player, courtCase.country, courtCase.category))
        .where((s) => s.courtCase.id == courtCase.id)
        .firstOrNull;
    if (slot == null || !slot.isPlayable) {
      throw StateError('Case ${courtCase.id} is locked: complete the previous case of its category first');
    }
    return slot;
  }

  @override
  Future<CourtCase> caseById(String caseId) async {
    final data = (await _cases.doc(caseId).get()).data();
    if (data == null) throw StateError('Unknown case $caseId');
    return CourtCase.fromFirestore(caseId, data);
  }

  Future<CaseVerdict> _verdict(String caseId) async {
    final data = (await _verdicts.doc(caseId).get()).data();
    if (data == null) throw StateError('No verdict for case $caseId');
    return CaseVerdict.fromFirestore(caseId, data);
  }

  @override
  Future<PlayerRuling> openCase(CourtCase courtCase) async {
    final slot = await _playableSlot(await _requirePlayer(), courtCase);
    if (slot.ruling case final existing?) return existing;
    final ruling = PlayerRuling.start(courtCase);
    await _rulings.doc(courtCase.id).set(ruling.toMap());
    return ruling;
  }

  @override
  Future<PlayerRuling> saveProgress(PlayerRuling ruling) async {
    if (ruling.isCompleted) return ruling;
    final doc = _rulings.doc(ruling.caseId);
    final stored = (await doc.get()).data();
    if (stored == null) throw StateError('Case ${ruling.caseId} was not opened: call openCase first');
    final current = PlayerRuling.fromFirestore(ruling.caseId, stored);
    if (current.isCompleted) return current;
    await doc.set(ruling.toMap());
    return ruling;
  }

  /// Writes the ruling as completed first: the security rules only let the player read
  /// `verdicts/{id}` after that. A ruling left completed without `isCorrect` by an interruption
  /// is finished on the next call, so its stats are counted once.
  @override
  Future<RulingResult> deliverVerdict(CourtCase courtCase, PlayerVerdict verdict) async {
    if (!verdict.isComplete) throw ArgumentError('Verdict is incomplete');
    final player = await _requirePlayer();
    final stored = (await _playableSlot(player, courtCase)).ruling;
    if (stored != null && stored.isCompleted && stored.isCorrect != null) {
      return RulingResult.evaluate(
        profile: player,
        courtCase: courtCase,
        ruling: stored,
        verdict: stored.verdict,
        courtVerdict: await _verdict(courtCase.id),
      );
    }

    final doc = _rulings.doc(courtCase.id);
    final pending = stored != null && stored.isCompleted;
    final played = pending ? stored.verdict : verdict;
    final inProgress = stored == null
        ? PlayerRuling.start(courtCase)
        : PlayerRuling.fromFirestore(courtCase.id, {...stored.toMap(), 'status': RulingStatus.inProgress.value});
    if (!pending) {
      await doc.set({
        ...inProgress.toMap(),
        'status': RulingStatus.completed.value,
        'verdict': played.toMap(),
        'submittedAt': DateTime.now(),
      });
    }

    final result = RulingResult.evaluate(
      profile: player,
      courtCase: courtCase,
      ruling: inProgress,
      verdict: played,
      courtVerdict: await _verdict(courtCase.id),
    );
    final profile = result.profile.toMap();
    await (_db.batch()
          ..set(doc, result.ruling.toMap())
          ..update(_userDoc, {'stats': profile['stats'], 'achievements': profile['achievements']}))
        .commit();
    return result;
  }

  @override
  Future<List<PlayerRuling>> completedRulings({int? limit}) async {
    var query = _rulings
        .where('status', isEqualTo: RulingStatus.completed.value)
        .orderBy('submittedAt', descending: true);
    if (limit != null) query = query.limit(limit);
    final snap = await query.get();
    return [for (final d in snap.docs) PlayerRuling.fromFirestore(d.id, d.data())];
  }

  @override
  Future<RulingResult> reviseCase(String caseId) async {
    final player = await _requirePlayer();
    final data = (await _rulings.doc(caseId).get()).data();
    final ruling = data == null ? null : PlayerRuling.fromFirestore(caseId, data);
    if (ruling == null || !ruling.isCompleted) {
      throw StateError('Case $caseId is not completed: its verdict stays hidden');
    }
    final (courtCase, courtVerdict) = await (caseById(caseId), _verdict(caseId)).wait;
    return RulingResult.evaluate(
      profile: player,
      courtCase: courtCase,
      ruling: ruling,
      verdict: ruling.verdict,
      courtVerdict: courtVerdict,
    );
  }
}
