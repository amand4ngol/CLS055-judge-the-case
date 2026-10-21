import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/providers/home_provider.dart';
import 'package:judge_the_case/screens/result/widgets/ruling_cards.dart';

void main() {
  test('verdicts read as a list with the slider amounts', () {
    expect(
      RulingCards.describeVerdict(
        [VerdictOption.fine, VerdictOption.prison, VerdictOption.probation],
        fineEur: 36500,
        prisonMonths: 49,
      ),
      'Fine 36,500 €, Prison 49 months, Probation',
    );
    expect(RulingCards.describeVerdict(const []), '—');
  });

  test('a completed case can be revised from the home screen', () async {
    final home = HomeProvider(await FakeGameRepository.withHistory());
    await home.load();

    final result = await home.pastResult(FakeData.shoplifterId);
    expect(result, isNotNull);
    expect(result!.courtVerdict.actualSentence, isNotEmpty);

    // Not completed yet: the court's verdict stays hidden.
    expect(await home.pastResult(FakeData.whistleblowerId), isNull);
  });

  test('"Next Case" finds the next playable case of the category', () async {
    final home = HomeProvider(await FakeGameRepository.withHistory());
    await home.load();

    final next = home.nextCase;
    expect(next, isNotNull);
    expect(next!.isPlayable, isTrue);
    expect(next.state, isNot(CaseSlotState.completed));
  });
}
