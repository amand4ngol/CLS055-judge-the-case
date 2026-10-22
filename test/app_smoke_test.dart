import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/app.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/screens/home/home_screen.dart';
import 'package:judge_the_case/screens/splash/splash_screen.dart';

void main() {
  testWidgets('the splash screen opens the home screen', (tester) async {
    final repository = await FakeGameRepository.withHistory();
    await tester.pumpWidget(JudgeApp(repository: repository));

    // Splash first, even though the fake data loads instantly.
    expect(find.text('Judge the Case'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);

    await tester.pump(SplashScreen.minimumDuration);
    await tester.pumpAndSettle();

    expect(find.byType(SplashScreen), findsNothing);
    expect(find.byType(HomeScreen), findsOneWidget);
    // This player left a case half read.
    expect(find.text('CONTINUE'), findsWidgets);
  });

  test('every bundled font and license file is in the asset bundle', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    const files = [
      'assets/fonts/LibreCaslonDisplay/LibreCaslonDisplay-Regular.ttf',
      'assets/fonts/DMSans/DMSans-Light.ttf',
      'assets/fonts/DMSans/DMSans-Regular.ttf',
      'assets/fonts/DMSans/DMSans-Medium.ttf',
      'assets/fonts/DMSans/DMSans-SemiBold.ttf',
      'assets/fonts/DMSans/DMSans-Bold.ttf',
      'assets/fonts/DMSans/DMSans-ExtraBold.ttf',
      'assets/fonts/Inter/Inter-Regular.ttf',
      'assets/fonts/Inter/Inter-SemiBold.ttf',
      'assets/fonts/Roboto/Roboto-Regular.ttf',
      'assets/fonts/Roboto/Roboto-Medium.ttf',
      'assets/fonts/DMSans/OFL.txt',
      'assets/fonts/LibreCaslonDisplay/OFL.txt',
      'assets/fonts/Inter/OFL.txt',
      'assets/fonts/Roboto/OFL.txt',
    ];
    for (final file in files) {
      final data = await rootBundle.load(file);
      expect(data.lengthInBytes, greaterThan(0), reason: file);
    }
  });
}
