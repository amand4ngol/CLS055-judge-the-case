import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:judge_the_case/data/firestore_game_repository.dart';
import 'package:judge_the_case/firebase_options.dart';
import 'package:judge_the_case/models.dart';

/// Plays one case on the real Firebase project with a throwaway account, then deletes the account
/// and everything it wrote. Run on a simulator: `flutter test integration_test/firebase_smoke_test.dart -d <device>`.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a throwaway player plays one real case', (_) async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    final db = FirebaseFirestore.instance;
    final repo = FirestoreGameRepository();
    const password = 'smoke-test-1';
    final username = 'smoke-${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}';
    await repo.createPlayer(
      name: 'Smoke test',
      username: username,
      password: password,
      countryCode: 'NL',
    );
    try {
      expect((await repo.countries()).map((c) => c.code), contains('NL'));
      final categories = await repo.categories('NL');
      expect(categories, isNotEmpty);
      final column = await repo.caseColumn('NL', categories.first);
      final next = column.firstWhere((s) => s.state == CaseSlotState.next).courtCase;
      if (column.length > 1) await expectLater(repo.openCase(column[1].courtCase), throwsStateError);
      await expectLater(db.collection('verdicts').doc(next.id).get(), throwsA(isA<FirebaseException>()));
      await expectLater(db.collection('ingestion').doc(next.id).get(), throwsA(isA<FirebaseException>()));

      final ruling = await repo.openCase(next);
      await repo.saveProgress(ruling.withProgress(argumentsRead: 1));
      final result = await repo.deliverVerdict(next, const PlayerVerdict(options: {VerdictOption.prison}, prisonMonths: 6));
      expect(result.courtVerdict.actualSentence, isNotEmpty);
      expect(result.profile.stats.casesJudged, 1);
      expect((await repo.completedRulings()).single.caseId, next.id);
      expect((await repo.reviseCase(next.id)).ruling.isCompleted, isTrue);
      expect((await repo.currentPlayer())!.stats.casesJudged, 1);

      await repo.updateProfile(username: '$username-b');
      await repo.signOut();
      expect((await repo.signIn(username: '$username-b', password: password)).stats.casesJudged, 1);
    } finally {
      await repo.deleteAccount(password: password);
    }
  });
}
