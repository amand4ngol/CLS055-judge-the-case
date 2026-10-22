import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/data/game_repository.dart';
import 'package:judge_the_case/models.dart';

void main() {
  group('case documents', () {
    final json = jsonDecode(File('test/fixtures/example-case.json').readAsStringSync()) as Map<String, dynamic>;
    final id = json['id'] as String;

    test('example-case.json reads into CourtCase and CaseVerdict', () {
      final c = CourtCase.fromFirestore(id, json['case'] as Map<String, dynamic>);
      final v = CaseVerdict.fromFirestore(id, json['verdict'] as Map<String, dynamic>);
      expect(c.category, CaseCategory.traffic);
      expect(c.originLabel, 'Netherlands · 2026');
      expect(c.arguments, hasLength(6));
      expect(c.sourceUrl.toString(), 'https://deeplink.rechtspraak.nl/uitspraak?id=$id');
      expect(v.courtRuled, {VerdictOption.prison, VerdictOption.probation});
      expect(v.sentence.prisonToServeMonths, 4);
      expect(v.otherMeasures.first.type, MeasureType.drivingBan);
    });

    test('toMap round-trips', () {
      final c = CourtCase.fromFirestore(id, json['case'] as Map<String, dynamic>);
      final again = CourtCase.fromFirestore(id, c.toMap());
      expect(again.decisionDate, c.decisionDate);
      expect(again.contentWarnings, c.contentWarnings);
    });

    test('every fake case and verdict is complete', () {
      for (final e in FakeData.cases.entries) {
        final c = CourtCase.fromFirestore(e.key, e.value);
        final v = CaseVerdict.fromFirestore(e.key, FakeData.verdicts[e.key]!);
        expect(c.arguments.length, inInclusiveRange(4, 6), reason: c.title);
        expect(c.summaryShort.length, lessThanOrEqualTo(400), reason: c.title);
        expect(v.courtRuled, isNotEmpty, reason: c.title);
      }
      expect(FakeData.verdicts.keys.toSet(), FakeData.cases.keys.toSet());
    });
  });

  group('player verdict', () {
    test('exclusive buttons clear the others and the other way round', () {
      var v = PlayerVerdict.empty.toggle(VerdictOption.fine).toggle(VerdictOption.prison);
      expect(v.options, {VerdictOption.fine, VerdictOption.prison});
      expect(v.fineEur, PlayerVerdict.fineMinEur);
      v = v.toggle(VerdictOption.acquitted);
      expect(v.options, {VerdictOption.acquitted});
      expect(v.fineEur, isNull);
      v = v.withPrison(500);
      expect(v.options, {VerdictOption.prison});
      expect(v.prisonMonths, PlayerVerdict.prisonMaxMonths);
      expect(v.isComplete, isTrue);
      expect(PlayerVerdict.empty.isComplete, isFalse);
    });

    test('comparison tells matched, missed and extra buttons apart', () {
      final court = CaseVerdict.fromFirestore(FakeData.redLightId, FakeData.verdicts[FakeData.redLightId]!);
      final cmp = RulingComparison.compare(
        const PlayerVerdict(options: {VerdictOption.prison, VerdictOption.fine}, prisonMonths: 12, fineEur: 500),
        court,
      );
      expect(cmp.isCorrect, isFalse);
      expect(cmp.matched, {VerdictOption.prison});
      expect(cmp.missed, {VerdictOption.probation});
      expect(cmp.extra, {VerdictOption.fine});
      expect(cmp.prisonGapMonths, 4);
      expect(cmp.fineGapEur, isNull);
      expect(
        RulingComparison.compare(
          const PlayerVerdict(options: {VerdictOption.probation, VerdictOption.prison}, prisonMonths: 3),
          court,
        ).isCorrect,
        isTrue,
      );
    });

    test('player documents round-trip', () {
      const v = PlayerVerdict(options: {VerdictOption.fine}, fineEur: 2500);
      expect(PlayerVerdict.fromMap(v.toMap()), v);
      final profile = FakeData.newPlayer.copyWith(
        preferences: const ContentPreferences(filteredTopics: {ContentWarning.death}),
        achievements: {Achievement.firstRuling: DateTime.utc(2026, 10, 19)},
      );
      final again = PlayerProfile.fromFirestore(profile.uid, profile.toMap());
      expect(again.preferences.filteredTopics, {ContentWarning.death});
      // Profiles saved before the setting existed keep their warnings.
      expect(ContentPreferences.fromMap({}).showTriggerWarnings, isTrue);
      expect(
        ContentPreferences.fromMap(
          const ContentPreferences(showTriggerWarnings: false).toMap(),
        ).showTriggerWarnings,
        isFalse,
      );
      expect(again.hasUnlocked(Achievement.firstRuling), isTrue);
    });
  });

  group('stats, rank and achievements', () {
    test('streaks, accuracy and labels', () {
      var s = PlayerStats.zero;
      expect(s.accuracyLabel, '–');
      for (final ok in [true, true, true, false, true]) {
        s = s.record(correct: ok, country: 'NL', category: 'fraud');
      }
      expect(s.casesJudged, 5);
      expect(s.bestStreak, 3);
      expect(s.currentStreak, 1);
      expect(s.accuracyLabel, '80%');
      expect(s.completedByCountry['NL'], 5);
    });

    test('rank progress matches the profile design', () {
      final p = RankProgress(0);
      expect(p.rank.label, 'Law Student');
      expect(p.counterLabel, '0/5');
      expect(p.message, '5 more cases to reach your next milestone.');
      expect(RankProgress(7).counterLabel, '2/5');
    });

    test('achievements unlock from stats', () {
      const before = PlayerStats(casesJudged: 2, correctVerdicts: 2, currentStreak: 2, bestStreak: 2);
      final after = before.record(correct: true, country: 'NL', category: 'theft');
      expect(Achievement.newlyEarned(before, after), [Achievement.onARoll]);
      expect(Achievement.sharpJudgment.isEarnedBy(after), isFalse, reason: 'needs 10 cases');
    });
  });

  group('fake repository', () {
    test('a new player sees the next case, then locked ones', () async {
      final repo = FakeGameRepository(player: FakeData.newPlayer, latency: Duration.zero);
      expect(await repo.categories('NL'), contains(CaseCategory.homicide));
      final column = await repo.caseColumn('NL', CaseCategory.fraud);
      expect(column.map((s) => s.state), [CaseSlotState.next, CaseSlotState.locked]);
      expect(column.last.label, 'CASE 02');
    });

    test('case X+1 stays locked until case X is completed, even with a draft', () async {
      final repo = FakeGameRepository(player: FakeData.newPlayer, latency: Duration.zero);
      var column = await repo.caseColumn('NL', CaseCategory.fraud);
      final first = column.first.courtCase;
      final second = column.last.courtCase;
      const verdict = PlayerVerdict(options: {VerdictOption.fine}, fineEur: 100);
      await expectLater(repo.openCase(second), throwsStateError);
      await expectLater(repo.saveProgress(PlayerRuling.start(second)), throwsStateError);
      await expectLater(repo.deliverVerdict(second, verdict), throwsStateError);

      final draft = await repo.openCase(first);
      await repo.saveProgress(draft.withProgress(argumentsRead: 1));
      column = await repo.caseColumn('NL', CaseCategory.fraud);
      expect(column.map((s) => s.state), [CaseSlotState.inProgress, CaseSlotState.locked]);
      expect(column.first.ruling!.argumentsRead, 1);
      await expectLater(repo.openCase(second), throwsStateError);

      await repo.deliverVerdict(first, verdict);
      column = await repo.caseColumn('NL', CaseCategory.fraud);
      expect(column.map((s) => s.state), [CaseSlotState.completed, CaseSlotState.next]);
      expect((await repo.openCase(second)).status, RulingStatus.inProgress);
    });

    test('accounts: create, sign out, sign in, and the errors the screens show', () async {
      final repo = FakeGameRepository(latency: Duration.zero);
      expect(await repo.currentPlayer(), isNull);
      Future<AccountError?> error(Future<Object?> Function() action) async {
        try {
          await action();
          return null;
        } on AccountException catch (e) {
          return e.error;
        }
      }

      expect(await error(() => repo.createPlayer(name: 'A', username: 'ab', password: 'secret1', countryCode: 'NL')),
          AccountError.invalidUsername);
      expect(await error(() => repo.createPlayer(name: 'A', username: 'anna', password: '123', countryCode: 'NL')),
          AccountError.weakPassword);
      final anna = await repo.createPlayer(name: ' Anna ', username: ' Anna ', password: 'secret1', countryCode: 'NL');
      expect((anna.name, anna.username), ('Anna', 'anna'));
      expect(await error(() => repo.createPlayer(name: 'B', username: 'ANNA', password: 'secret2', countryCode: 'NL')),
          AccountError.usernameTaken);

      await repo.deliverVerdict(await repo.caseById(FakeData.whistleblowerId),
          const PlayerVerdict(options: {VerdictOption.communityService}));
      await repo.signOut();
      expect(await repo.currentPlayer(), isNull);
      expect(await error(() => repo.signIn(username: 'anna', password: 'wrong!')), AccountError.wrongCredentials);

      await repo.createPlayer(name: 'Bob', username: 'bob', password: 'secret2', countryCode: 'NL');
      expect(await repo.completedRulings(), isEmpty);
      final back = await repo.signIn(username: 'ANNA', password: 'secret1');
      expect(back.stats.casesJudged, 1);
      expect(await repo.completedRulings(), hasLength(1));
    });

    test('delivering a verdict updates ruling, stats and achievements', () async {
      final repo = FakeGameRepository(player: FakeData.newPlayer, latency: Duration.zero);
      final c = await repo.caseById(FakeData.whistleblowerId);
      await expectLater(repo.reviseCase(c.id), throwsStateError);
      final r = await repo.deliverVerdict(c, const PlayerVerdict(options: {VerdictOption.communityService}));
      expect(r.isCorrect, isTrue);
      expect(r.newAchievements, [Achievement.firstRuling]);
      expect(r.profile.stats.casesJudged, 1);
      expect((await repo.currentPlayer())!.hasUnlocked(Achievement.firstRuling), isTrue);
      expect((await repo.completedRulings()).single.caseTitle, 'The Whistleblower Hacker');
      // Ruling the same case again changes nothing.
      final again = await repo.deliverVerdict(c, const PlayerVerdict(options: {VerdictOption.fine}, fineEur: 100));
      expect(again.profile.stats.casesJudged, 1);
      expect((await repo.reviseCase(c.id)).isCorrect, isTrue);
    });

    test('history fixture fills profile, column states and country progress', () async {
      final repo = await FakeGameRepository.withHistory();
      final player = (await repo.currentPlayer())!;
      expect(player.stats.casesJudged, 2);
      expect(player.stats.correctVerdicts, 1);
      final homicide = await repo.caseColumn('NL', CaseCategory.homicide);
      expect(homicide.first.state, CaseSlotState.inProgress);
      expect(homicide.first.ruling!.progress, closeTo(0.48, 1e-9));
      final traffic = await repo.caseColumn('NL', CaseCategory.traffic);
      expect(traffic.map((s) => s.state), [CaseSlotState.completed, CaseSlotState.next]);
      final nl = (await repo.countries()).firstWhere((c) => c.code == 'NL');
      expect(nl.progressLabel(player.stats), '22% done');
      expect(nl.flag, '🇳🇱');
    });

    test('content preferences hide sensitive cases', () async {
      final repo = FakeGameRepository(player: FakeData.newPlayer, latency: Duration.zero);
      await repo.savePreferences(const ContentPreferences(hideSensitiveCases: true));
      expect(await repo.caseColumn('NL', CaseCategory.homicide), isEmpty);
      expect(await repo.caseColumn('NL', CaseCategory.fraud), hasLength(2));
    });
  });
}
