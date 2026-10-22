import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/game_repository.dart';
import 'package:judge_the_case/models.dart';

/// The behaviour every [GameRepository] must share, so the screens work the same on fake and real data.
/// [create] returns a repository holding [FakeData]'s cases, with no one signed in.
void repositoryContract(String name, Future<GameRepository> Function() create) {
  group('$name contract', () {
    late GameRepository repo;
    setUp(() async {
      repo = await create();
      await repo.createPlayer(name: 'Isabella', username: 'isabella', password: 'secret1', countryCode: 'NL');
    });

    Future<CourtCase> caseOf(String id) => repo.caseById(id);

    Matcher throwsAccountError(AccountError error) =>
        throwsA(isA<AccountException>().having((e) => e.error, 'error', error));

    test('a new player gets the categories, then a next case and locked ones', () async {
      final player = (await repo.currentPlayer())!;
      expect((player.name, player.username, player.countryCode), ('Isabella', 'isabella', 'NL'));
      expect(await repo.categories('NL'), [
        CaseCategory.homicide,
        CaseCategory.theft,
        CaseCategory.fraud,
        CaseCategory.financial,
        CaseCategory.traffic,
        CaseCategory.cybercrime,
      ]);
      final column = await repo.caseColumn('NL', CaseCategory.fraud);
      expect(column.map((s) => s.state), [CaseSlotState.next, CaseSlotState.locked]);
      expect(column.map((s) => s.label), ['CASE 01', 'CASE 02']);
      expect((await repo.countries()).map((c) => c.code), containsAll(['NL', 'OM', 'PT']));
    });

    test('case X+1 stays locked until case X is completed, even with a draft', () async {
      var column = await repo.caseColumn('NL', CaseCategory.fraud);
      final first = column.first.courtCase;
      final second = column.last.courtCase;
      const verdict = PlayerVerdict(options: {VerdictOption.fine}, fineEur: 100);
      await expectLater(repo.openCase(second), throwsStateError);
      await expectLater(repo.deliverVerdict(second, verdict), throwsStateError);

      final draft = await repo.openCase(first);
      await repo.saveProgress(draft.withProgress(argumentsRead: 2, verdict: verdict));
      column = await repo.caseColumn('NL', CaseCategory.fraud);
      expect(column.map((s) => s.state), [CaseSlotState.inProgress, CaseSlotState.locked]);
      expect(column.first.ruling!.argumentsRead, 2);
      expect((await repo.openCase(first)).verdict, verdict);
      await expectLater(repo.openCase(second), throwsStateError);

      await repo.deliverVerdict(first, verdict);
      column = await repo.caseColumn('NL', CaseCategory.fraud);
      expect(column.map((s) => s.state), [CaseSlotState.completed, CaseSlotState.next]);
      expect((await repo.openCase(second)).status, RulingStatus.inProgress);
    });

    test('delivering a verdict updates the ruling, stats and achievements, once', () async {
      final c = await caseOf(FakeData.whistleblowerId);
      await expectLater(repo.reviseCase(c.id), throwsStateError);
      final r = await repo.deliverVerdict(c, const PlayerVerdict(options: {VerdictOption.communityService}));
      expect(r.isCorrect, isTrue);
      expect(r.newAchievements, [Achievement.firstRuling]);
      expect(r.ruling.isCompleted, isTrue);
      final player = (await repo.currentPlayer())!;
      expect(player.stats.casesJudged, 1);
      expect(player.hasUnlocked(Achievement.firstRuling), isTrue);

      final again = await repo.deliverVerdict(c, const PlayerVerdict(options: {VerdictOption.fine}, fineEur: 100));
      expect(again.isCorrect, isTrue);
      expect((await repo.currentPlayer())!.stats.casesJudged, 1);
      expect((await repo.reviseCase(c.id)).courtVerdict.courtRuled, {VerdictOption.communityService});
    });

    test('completed rulings come newest first', () async {
      await repo.deliverVerdict(await caseOf(FakeData.whistleblowerId),
          const PlayerVerdict(options: {VerdictOption.communityService}));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await repo.deliverVerdict(await caseOf(FakeData.shoplifterId),
          const PlayerVerdict(options: {VerdictOption.caseDismissed}));
      expect((await repo.completedRulings()).map((r) => r.caseTitle),
          ["The Shoplifter's Dilemma", 'The Whistleblower Hacker']);
      expect((await repo.completedRulings(limit: 1)).single.caseId, FakeData.shoplifterId);
    });

    test('settings and country are saved on the player', () async {
      await repo.savePreferences(const ContentPreferences(hideSensitiveCases: true));
      expect(await repo.caseColumn('NL', CaseCategory.homicide), isEmpty);
      await repo.setCountry('PT');
      final player = (await repo.currentPlayer())!;
      expect(player.preferences.hideSensitiveCases, isTrue);
      expect(player.countryCode, 'PT');
    });

    test('signing out and in again keeps the progress', () async {
      await repo.deliverVerdict(await caseOf(FakeData.whistleblowerId),
          const PlayerVerdict(options: {VerdictOption.communityService}));
      await repo.signOut();
      expect(await repo.currentPlayer(), isNull);
      final back = await repo.signIn(username: 'Isabella', password: 'secret1');
      expect(back.stats.casesJudged, 1);
      expect(await repo.completedRulings(), hasLength(1));
    });

    test('deleting the account erases the player and frees the username', () async {
      await repo.deliverVerdict(await caseOf(FakeData.whistleblowerId),
          const PlayerVerdict(options: {VerdictOption.communityService}));
      await expectLater(repo.deleteAccount(password: 'wrong!'), throwsAccountError(AccountError.wrongCredentials));
      expect((await repo.currentPlayer())!.stats.casesJudged, 1);

      await repo.deleteAccount(password: 'secret1');
      expect(await repo.currentPlayer(), isNull);
      await expectLater(
          repo.signIn(username: 'isabella', password: 'secret1'), throwsAccountError(AccountError.wrongCredentials));

      await repo.createPlayer(name: 'Isabella', username: 'isabella', password: 'secret2', countryCode: 'NL');
      expect((await repo.currentPlayer())!.stats.toMap(), PlayerStats.zero.toMap());
      expect(await repo.completedRulings(), isEmpty);
    });
  });
}
