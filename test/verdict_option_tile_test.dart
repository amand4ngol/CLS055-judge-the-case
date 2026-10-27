import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/screens/case/widgets/verdict_option_tile.dart';

void main() {
  /// Pumps one selected tile wired like the case screen: the verdict is
  /// updated with [PlayerVerdict.withFine] / [PlayerVerdict.withPrison].
  Future<List<PlayerVerdict>> pumpTile(
    WidgetTester tester,
    VerdictOption option,
  ) async {
    var verdict = PlayerVerdict.empty.toggle(option);
    final saved = <PlayerVerdict>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Column(
              children: [
                VerdictOptionTile(
                  option: option,
                  verdict: verdict,
                  onTap: () {},
                  onFineChanged: (eur) =>
                      setState(() => verdict = verdict.withFine(eur)),
                  onPrisonChanged: (months) =>
                      setState(() => verdict = verdict.withPrison(months)),
                  onSliderChangeEnd: () => saved.add(verdict),
                ),
                const Text('Outside'),
              ],
            ),
          ),
        ),
      ),
    );
    return saved;
  }

  Future<void> typeAndLeave(WidgetTester tester, String text) async {
    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.enterText(find.byType(TextField), text);
    FocusManager.instance.primaryFocus!.unfocus();
    await tester.pumpAndSettle();
  }

  testWidgets('a typed fine is applied and saved', (tester) async {
    final saved = await pumpTile(tester, VerdictOption.fine);
    expect(find.text('100'), findsOneWidget);

    await typeAndLeave(tester, '36,500');

    expect(saved.single.fineEur, 36500);
    expect(find.text('36,500'), findsOneWidget);
  });

  testWidgets('prison is typed in months', (tester) async {
    final saved = await pumpTile(tester, VerdictOption.prison);

    await typeAndLeave(tester, '18');

    expect(saved.single.prisonMonths, 18);
    expect(find.text('18'), findsOneWidget);
  });

  testWidgets('a typed amount stays within the slider limits', (tester) async {
    final saved = await pumpTile(tester, VerdictOption.prison);

    await typeAndLeave(tester, '500');

    expect(saved.single.prisonMonths, PlayerVerdict.prisonMaxMonths);
    expect(find.text('240'), findsOneWidget);
  });

  testWidgets('an empty field keeps the current amount', (tester) async {
    final saved = await pumpTile(tester, VerdictOption.prison);

    await typeAndLeave(tester, '');

    expect(saved, isEmpty);
    expect(find.text('1'), findsOneWidget);
  });
}
