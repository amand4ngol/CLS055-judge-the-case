import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/app.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';

void main() {
  testWidgets('the home screen loads with bundled fonts', (tester) async {
    final repository = await FakeGameRepository.withHistory();
    await tester.pumpWidget(JudgeApp(repository: repository));
    await tester.pumpAndSettle();

    expect(find.text('REAL COURT CASES'), findsOneWidget);
    expect(find.text('NEXT CASE'), findsWidgets);
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
