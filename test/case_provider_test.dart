import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/core/utils/formatters.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/providers/case_provider.dart';
import 'package:judge_the_case/providers/home_provider.dart';

void main() {
  test('a case without content warnings opens straight away', () async {
    final repo = await FakeGameRepository.withHistory();
    final provider = CaseProvider(repo, FakeData.whistleblowerId);
    await provider.load();

    expect(provider.status, CaseScreenStatus.ready);
    expect(provider.argumentsRead, 0);
    expect(provider.canDeliver, isFalse);
  });

  test('a sensitive case waits behind the trigger warning', () async {
    final repo = await FakeGameRepository.withHistory();
    final provider = CaseProvider(repo, FakeData.deathAtTheWheelId);
    await provider.load();
    expect(provider.status, CaseScreenStatus.warning);

    // No ruling until the player chooses to enter.
    final column = await repo.caseColumn('NL', CaseCategory.traffic);
    final slot = column.firstWhere(
      (s) => s.courtCase.id == FakeData.deathAtTheWheelId,
    );
    expect(slot.state, CaseSlotState.next);

    await provider.enterCase();
    expect(provider.status, CaseScreenStatus.ready);
  });

  test('reading arguments and delivering a verdict', () async {
    final repo = await FakeGameRepository.withHistory();
    final provider = CaseProvider(repo, FakeData.whistleblowerId);
    await provider.load();

    provider.showArgumentPage(2);
    provider.showArgumentPage(1); // swiping back does not lower progress
    expect(provider.argumentsRead, 2);
    expect(provider.argumentPage, 1); // but the progress bar follows the card

    // Reopening the case starts at the furthest argument reached.
    final reopened = CaseProvider(repo, FakeData.whistleblowerId);
    await reopened.load();
    expect(reopened.argumentPage, 2);

    provider.toggleOption(VerdictOption.fine);
    provider.setFine(36500);
    expect(provider.verdict.fineEur, 36500);
    expect(provider.canDeliver, isTrue);

    final result = await provider.deliver();
    expect(result, isNotNull);
    expect(provider.exit.result, same(result));
  });

  test('"Do not show this warning again" stops the warnings', () async {
    final repo = await FakeGameRepository.withHistory();
    final home = HomeProvider(repo);
    await home.load();

    final provider = CaseProvider(repo, FakeData.deathAtTheWheelId);
    await provider.load();
    provider.setDontShowWarningAgain(true);
    await provider.enterCase();
    expect(provider.exit.turnOffTriggerWarnings, isTrue);

    await home.afterCase(provider.exit);
    expect(home.player?.preferences.showTriggerWarnings, isFalse);
    // Sensitive cases still show, now without the warning.
    expect(home.player?.preferences.hideSensitiveCases, isFalse);
    final next = CaseProvider(repo, FakeData.deathAtTheWheelId);
    await next.load();
    expect(next.status, CaseScreenStatus.ready);
  });

  test('the checkbox changes nothing if the player leaves', () async {
    final repo = await FakeGameRepository.withHistory();
    final provider = CaseProvider(repo, FakeData.deathAtTheWheelId);
    await provider.load();
    provider.setDontShowWarningAgain(true);

    expect(provider.exit.turnOffTriggerWarnings, isFalse);
  });

  test('turning trigger warnings back on shows them again', () async {
    final repo = await FakeGameRepository.withHistory();
    final home = HomeProvider(repo);
    await home.load();
    final preferences = home.player!.preferences;

    await home.setPreferences(preferences.copyWith(showTriggerWarnings: false));
    await home.setPreferences(preferences.copyWith(showTriggerWarnings: true));

    final provider = CaseProvider(repo, FakeData.deathAtTheWheelId);
    await provider.load();
    expect(provider.status, CaseScreenStatus.warning);
  });

  test('formatters', () {
    expect(Formatters.euro(36500), '36,500 €');
    expect(Formatters.euro(100), '100 €');
    expect(Formatters.euro(10000000), '10,000,000 €');
    expect(Formatters.months(1), '1 month');
    expect(Formatters.months(49), '49 months');
  });
}
