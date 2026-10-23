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
      // No entrance or glow: the glow never stops, and these tests are about
      // the pages, not the animation.
      MediaQuery(
        data: const MediaQueryData(disableAnimations: true),
        child: MaterialApp(
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

  /// How visible the button is: the lowest opacity of the fades around it.
  double buttonOpacity(WidgetTester tester) => tester
      .widgetList<FadeTransition>(
        find.ancestor(
          of: find.text('NEXT CASE →'),
          matching: find.byType(FadeTransition),
        ),
      )
      .map((fade) => fade.opacity.value)
      .reduce((a, b) => a < b ? a : b);

  testWidgets('the entrance plays, then the glow keeps going', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MaterialApp(
        home: AchievementScreen(achievement: Achievement.firstRuling),
      ),
    );

    // Mid-entrance the button has not faded in yet.
    await tester.pump(const Duration(milliseconds: 300));
    expect(buttonOpacity(tester), 0);

    // After the entrance everything is in place and the badge keeps glowing.
    await tester.pump(const Duration(milliseconds: 1500));
    expect(buttonOpacity(tester), 1);
    await tester.pump(const Duration(seconds: 10));
    expect(tester.hasRunningAnimations, isTrue);
    expect(find.text('First ruling!'), findsOneWidget);
  });

  testWidgets('"Reduce motion" shows the screen at once', (tester) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      const MediaQuery(
        data: MediaQueryData(disableAnimations: true),
        child: MaterialApp(
          home: AchievementScreen(achievement: Achievement.firstRuling),
        ),
      ),
    );
    await tester.pump();

    expect(buttonOpacity(tester), 1);
    expect(tester.hasRunningAnimations, isFalse);
  });
}
