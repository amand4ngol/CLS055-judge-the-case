import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/app.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';

void main() {
  testWidgets('home screen fits with twice the system text size', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 2.0;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final repository = await FakeGameRepository.withHistory();
    await tester.pumpWidget(JudgeApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('REAL COURT CASES'), findsOneWidget);
  });
}
