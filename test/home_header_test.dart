import 'package:country_flags/country_flags.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/screens/home/widgets/home_header.dart';
import 'package:judge_the_case/shared/widgets/flag_icon.dart';

void main() {
  const netherlands = Country(code: 'NL', name: 'Netherlands', publishedCases: 1);
  const france = Country(code: 'FR', name: 'France', publishedCases: 0);

  Future<void> show(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
    // The SVG asset loads outside the fake clock.
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 100)),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the header flag follows the selected country', (tester) async {
    Widget header(Country country) => SizedBox(
          height: HomeHeader.height,
          child: HomeHeader(country: country),
        );

    await show(tester, header(netherlands));
    expect(find.byType(CountryFlag), findsNothing);

    // No FR asset: the drawn flag replaces the Netherlands one.
    await show(tester, header(france));
    expect(find.byType(CountryFlag), findsOneWidget);
  });

  testWidgets('a drawn flag is as large as the Netherlands SVG', (
    tester,
  ) async {
    await show(tester, const Center(child: FlagIcon('NL')));
    expect(tester.getSize(find.byType(SvgPicture)), FlagIcon.size);

    await show(tester, const Center(child: FlagIcon('FR')));
    expect(tester.getSize(find.byType(CountryFlag)), FlagIcon.size);
  });
}
