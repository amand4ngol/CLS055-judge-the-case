import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/providers/home_provider.dart';

void main() {
  test('loads the player, country, categories and first column', () async {
    final home = HomeProvider(await FakeGameRepository.withHistory());
    await home.load();

    expect(home.status, HomeStatus.ready);
    expect(home.country?.code, 'NL');
    expect(home.categories, isNotEmpty);
    expect(home.cases, isNotEmpty);
    expect(
      home.cases.every((s) => s.courtCase.category == home.selectedCategory),
      isTrue,
    );
  });

  test('focuses the next case and switches category', () async {
    final home = HomeProvider(await FakeGameRepository.withHistory());
    await home.load();

    final focused = home.cases[home.focusedCaseIndex].state;
    expect(
      focused,
      anyOf(
        CaseSlotState.next,
        CaseSlotState.inProgress,
        CaseSlotState.completed,
      ),
    );

    await home.selectCategory(1);
    expect(home.selectedCategoryIndex, 1);
    expect(home.isLoadingCases, isFalse);
    expect(
      home.cases.every((s) => s.courtCase.category == home.categories[1]),
      isTrue,
    );
  });

  test(
    'Netherlands is selected by default and the country can change',
    () async {
      final home = HomeProvider(await FakeGameRepository.withHistory());
      await home.load();

      expect(home.country?.code, 'NL');
      expect(
        home.countries.map((c) => c.code),
        containsAll(['NL', 'OM', 'PT']),
      );

      await home.selectCountry('PT');
      expect(home.status, HomeStatus.ready);
      expect(home.country?.code, 'PT');
      expect(home.categories, isEmpty); // no Portuguese cases yet
    },
  );

  test('a category with only sensitive cases is reported as hidden', () async {
    final home = HomeProvider(await FakeGameRepository.withHistory());
    await home.load();
    await home.setPreferences(
      home.player!.preferences.copyWith(hideSensitiveCases: true),
    );

    // Every homicide case in the fake data has content warnings.
    await home.selectCategory(home.categories.indexOf(CaseCategory.homicide));
    expect(home.isCategoryHidden, isTrue);
    expect(home.hidesSensitiveCases, isTrue);

    await home.showSensitiveCases();
    expect(home.hidesSensitiveCases, isFalse);
    expect(home.isCategoryHidden, isFalse);
    expect(home.cases, isNotEmpty);
  });

  test('reports signed out when nobody is signed in', () async {
    final home = HomeProvider(FakeGameRepository(latency: Duration.zero));
    await home.load();

    expect(home.status, HomeStatus.signedOut);
    expect(home.player, isNull);
  });

  test('the guide shows until the player picks a category', () async {
    final home = HomeProvider(
      FakeGameRepository(player: FakeData.newPlayer, latency: Duration.zero),
    );
    await home.load();
    expect(home.showsGuide, isTrue);

    await home.selectCategory(1);
    expect(home.showsGuide, isFalse);

    // A new load (e.g. another player signing in) shows it again.
    await home.load();
    expect(home.showsGuide, isTrue);
    home.dismissGuide();
    expect(home.showsGuide, isFalse);
  });

  test('no guide once the player has judged a case', () async {
    final home = HomeProvider(await FakeGameRepository.withHistory());
    await home.load();
    expect(home.showsGuide, isFalse);
  });
}
