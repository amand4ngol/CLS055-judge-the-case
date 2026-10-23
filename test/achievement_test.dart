import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/screens/achievement/achievement_screen.dart';
import 'package:judge_the_case/screens/result/result_screen.dart';

void main() {
  /// Shows [achievements] from a button, as home does after a result, and
  /// records what the pages decided.
  Future<List<ResultAction>> open(
    WidgetTester tester,
    List<Achievement> achievements,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final actions = <ResultAction>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => TextButton(
            onPressed: () async => actions.add(
              await AchievementScreen.showAll(
                Navigator.of(context),
                achievements,
              ),
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

  testWidgets('one achievement shows its badge, title and message', (
    tester,
  ) async {
    final actions = await open(tester, [Achievement.firstRuling]);

    expect(find.bySemanticsLabel('New achievement: First ruling!'), findsOne);
    expect(find.text('I'), findsOneWidget);
    expect(find.text('First ruling!'), findsOneWidget);
    expect(find.text('Your first case is closed!'), findsOneWidget);
    expect(find.text('Keep up the good work, Judge'), findsOneWidget);
    expect(find.text('CONTINUE →'), findsNothing);

    await tester.tap(find.text('NEXT CASE →'));
    await tester.pumpAndSettle();
    expect(find.byType(AchievementScreen), findsNothing);
    expect(actions, [ResultAction.nextCase]);
  });

  testWidgets('two achievements show one page each', (tester) async {
    final actions = await open(tester, [
      Achievement.sharpJudgment,
      Achievement.casebook,
    ]);

    expect(find.text('Sharp judgment!'), findsOneWidget);
    await tester.tap(find.text('CONTINUE →'));
    await tester.pumpAndSettle();

    expect(find.text('Casebook!'), findsOneWidget);
    expect(find.text('CONTINUE →'), findsNothing);
    await tester.tap(find.text('NEXT CASE →'));
    await tester.pumpAndSettle();
    expect(actions, [ResultAction.nextCase]);
  });

  testWidgets('the home pillar skips the remaining pages', (tester) async {
    final actions = await open(tester, [
      Achievement.sharpJudgment,
      Achievement.casebook,
    ]);

    await tester.tap(find.bySemanticsLabel('Return to home'));
    await tester.pumpAndSettle();

    expect(find.byType(AchievementScreen), findsNothing);
    expect(actions, [ResultAction.home]);
  });
}
