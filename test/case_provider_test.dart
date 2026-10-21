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

    provider.markArgumentsRead(2);
    provider.markArgumentsRead(1); // swiping back does not lower progress
    expect(provider.argumentsRead, 2);

    provider.toggleOption(VerdictOption.fine);
    provider.setFine(36500);
    expect(provider.verdict.fineEur, 36500);
    expect(provider.canDeliver, isTrue);

    final result = await provider.deliver();
    expect(result, isNotNull);
    expect(provider.exit.result, same(result));
  });

  test(
    '"Do not show me sensitive cases again" is saved after leaving',
    () async {
      final repo = await FakeGameRepository.withHistory();
      final home = HomeProvider(repo);
      await home.load();

      await home.afterCase(const CaseExit(hideSensitiveCases: true));
      expect(home.player?.preferences.hideSensitiveCases, isTrue);
    },
  );

  test('formatters', () {
    expect(Formatters.euro(36500), '36,500 €');
    expect(Formatters.euro(100), '100 €');
    expect(Formatters.euro(10000000), '10,000,000 €');
    expect(Formatters.months(1), '1 month');
    expect(Formatters.months(49), '49 months');
  });
}
