import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/app.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/screens/home/widgets/guide_tour.dart';
import 'package:judge_the_case/screens/splash/splash_screen.dart';

void main() {
  Future<void> launch(
    WidgetTester tester,
    FakeGameRepository repository,
  ) async {
    tester.view.physicalSize = const Size(402, 874);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(JudgeApp(repository: repository));
    await tester.pump(SplashScreen.minimumDuration);
    await tester.pumpAndSettle();
  }

  FakeGameRepository newPlayer() =>
      FakeGameRepository(player: FakeData.newPlayer, latency: Duration.zero);

  testWidgets(
    'a new player is walked through country, categories, cases and profile',
    (tester) async {
      await launch(tester, newPlayer());

      expect(find.textContaining('YOUR COUNTRY'), findsOneWidget);
      expect(find.text('1/4'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('SWIPE AND PICK A CATEGORY'), findsOneWidget);
      expect(find.text('2/4'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('YOUR CASES IN THE CATEGORY'), findsOneWidget);
      expect(find.text('3/4'), findsOneWidget);

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.textContaining('YOUR PROFILE'), findsOneWidget);
      expect(find.text('Skip'), findsNothing);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.byType(GuideTour), findsNothing);
    },
  );

  testWidgets('"Skip" closes the tour', (tester) async {
    await launch(tester, newPlayer());

    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();
    expect(find.byType(GuideTour), findsNothing);
  });

  testWidgets('a player who already judged cases gets no tour', (tester) async {
    await launch(tester, await FakeGameRepository.withHistory());
    expect(find.byType(GuideTour), findsNothing);
  });
}
