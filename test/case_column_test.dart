import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/screens/home/widgets/case_column.dart';

void main() {
  /// The slot of [caseId] in the column of its category.
  Future<CaseSlot> slotOf(FakeGameRepository repository, String caseId) async {
    final courtCase = await repository.caseById(caseId);
    final column = await repository.caseColumn(
      courtCase.country,
      courtCase.category,
    );
    return column.firstWhere((s) => s.courtCase.id == caseId);
  }

  Future<void> pumpColumn(WidgetTester tester, CaseSlot slot) =>
      tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: CaseColumn(slot: slot)),
          ),
        ),
      );

  testWidgets('a case the player opened shows "CONTINUE"', (tester) async {
    final repository = await FakeGameRepository.withHistory();
    final slot = await slotOf(repository, FakeData.healingWeekendId);
    expect(slot.state, CaseSlotState.inProgress);
    expect(slot.ruling!.progress, greaterThan(0));

    await pumpColumn(tester, slot);

    expect(find.text('CONTINUE'), findsOneWidget);
    expect(find.text('ENTER'), findsNothing);
  });

  testWidgets('a case never opened shows "ENTER"', (tester) async {
    final repository = FakeGameRepository(
      player: FakeData.newPlayer,
      latency: Duration.zero,
    );
    final slot = await slotOf(repository, FakeData.redLightId);
    expect(slot.state, CaseSlotState.next);

    await pumpColumn(tester, slot);

    expect(find.text('ENTER'), findsOneWidget);
    expect(find.text('CONTINUE'), findsNothing);
  });
}
