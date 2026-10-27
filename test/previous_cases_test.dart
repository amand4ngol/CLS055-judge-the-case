import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/screens/profile/previous_cases_screen.dart';
import 'package:judge_the_case/screens/profile/widgets/previous_cases.dart';
import 'package:judge_the_case/screens/profile/widgets/stats_row.dart';

void main() {
  final rulings = [
    for (var i = 1; i <= 5; i++)
      PlayerRuling(
        caseId: 'ECLI:NL:TEST:$i',
        status: RulingStatus.completed,
        caseTitle: 'Case $i',
        category: CaseCategory.theft,
        country: 'NL',
        year: 2026,
        argumentsCount: 4,
        isCorrect: i.isEven,
      ),
  ];

  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );

  testWidgets('the profile shows three cases and "View More"', (tester) async {
    var viewAll = 0;
    PlayerRuling? previewed;
    await pump(
      tester,
      PreviousCases(
        rulings: rulings,
        onPreview: (ruling) => previewed = ruling,
        onViewAll: () => viewAll++,
      ),
    );

    expect(find.byType(PreviousCaseButton), findsNWidgets(3));
    expect(find.text('Case 4'), findsNothing);

    await tester.tap(find.text('Case 2'));
    expect(previewed, rulings[1]);

    await tester.tap(find.text('View More'));
    expect(viewAll, 1);
  });

  testWidgets('no "View More" when every case already shows', (tester) async {
    await pump(
      tester,
      PreviousCases(
        rulings: rulings.take(3).toList(),
        onPreview: (_) {},
        onViewAll: () {},
      ),
    );

    expect(find.text('View More'), findsNothing);
  });

  testWidgets('the cases tile opens the previous cases', (tester) async {
    var opened = 0;
    await pump(
      tester,
      StatsRow(
        stats: const PlayerStats(casesJudged: 5),
        onCasesTap: () => opened++,
      ),
    );

    await tester.tap(find.text('CASES'));
    expect(opened, 1);
  });

  testWidgets('the previous cases page lists every case', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PreviousCasesScreen(rulings: rulings, onPreview: (_) {}),
      ),
    );

    expect(find.text('PREVIOUS CASES'), findsOneWidget);
    expect(find.byType(PreviousCaseButton), findsNWidgets(5));
  });
}
