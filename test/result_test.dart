import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/providers/home_provider.dart';
import 'package:judge_the_case/screens/result/result_screen.dart';
import 'package:judge_the_case/screens/result/widgets/ruling_cards.dart';
import 'package:judge_the_case/shared/widgets/profile_button.dart';

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

  test('after a recap the board gets a new list on the next case', () async {
    final home = HomeProvider(await FakeGameRepository.withHistory());
    await home.load();
    final before = home.cases;
    final focused = home.focusedCaseIndex;

    home.focusNextCase();

    expect(home.cases, isNot(same(before)));
    expect(home.cases, before);
    expect(home.focusedCaseIndex, focused);
  });

  group('result screen', () {
    late RulingResult result;

    setUpAll(() async {
      final home = HomeProvider(await FakeGameRepository.withHistory());
      await home.load();
      result = (await home.pastResult(FakeData.shoplifterId))!;
    });

    /// Opens the screen from a button, so it can be closed again.
    Future<List<ResultAction?>> open(
      WidgetTester tester, {
      required bool isRecap,
    }) async {
      final actions = <ResultAction?>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async => actions.add(
                await Navigator.of(
                  context,
                ).push(ResultScreen.route(result, isRecap: isRecap)),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      return actions;
    }

    testWidgets('a recap shows the case and closes with no action', (
      tester,
    ) async {
      final actions = await open(tester, isRecap: true);

      expect(find.text(result.courtCase.title), findsOneWidget);
      expect(find.text('CASE SUMMARY'), findsOneWidget);
      expect(find.text('ARGUMENTS'), findsOneWidget);
      expect(find.byType(ProfileButton), findsNothing);
      expect(find.text('NEXT CASE →'), findsNothing);

      await tester.ensureVisible(find.text('← CLOSE RECAP'));
      await tester.tap(find.text('← CLOSE RECAP'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsNothing);
      expect(actions, [null]);
    });

    testWidgets('the back arrow closes a recap too', (tester) async {
      final actions = await open(tester, isRecap: true);

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();
      expect(find.byType(ResultScreen), findsNothing);
      expect(actions, [null]);
    });

    testWidgets('after a verdict the screen offers the next case', (
      tester,
    ) async {
      final actions = await open(tester, isRecap: false);

      expect(find.text('CASE SUMMARY'), findsNothing);
      expect(find.byType(ProfileButton), findsOneWidget);

      await tester.ensureVisible(find.text('NEXT CASE →'));
      await tester.tap(find.text('NEXT CASE →'));
      await tester.pumpAndSettle();
      expect(actions, [ResultAction.nextCase]);
    });
  });
}
