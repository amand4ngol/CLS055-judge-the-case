import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/app.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/screens/home/home_screen.dart';
import 'package:judge_the_case/screens/splash/splash_screen.dart';

void main() {
  testWidgets('splash and home fit with twice the system text size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = await FakeGameRepository.withHistory();
    await tester.pumpWidget(JudgeApp(repository: repository));

    // Any overflow on either screen fails the test.
    expect(find.byType(SplashScreen), findsOneWidget);
    await tester.pump(SplashScreen.minimumDuration);
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('REAL COURT CASES'), findsOneWidget);
  });
}
