import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:judge_the_case/app.dart';
import 'package:judge_the_case/core/constants/app_assets.dart';
import 'package:judge_the_case/data/fake_data.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/data/game_repository.dart';
import 'package:judge_the_case/screens/account/create_account_screen.dart';
import 'package:judge_the_case/screens/account/log_in_screen.dart';
import 'package:judge_the_case/screens/home/home_screen.dart';
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/screens/profile/profile_screen.dart';
import 'package:judge_the_case/screens/result/result_screen.dart';
import 'package:judge_the_case/screens/settings/settings_screen.dart';
import 'package:judge_the_case/screens/splash/splash_screen.dart';
import 'package:judge_the_case/shared/widgets/app_svg.dart';

void main() {
  /// Starts the app on a phone the size of the design and waits for the
  /// splash screen to hand over.
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

  Future<void> fill(WidgetTester tester, String label, String text) =>
      tester.enterText(find.widgetWithText(TextField, label), text);

  /// Isabella has an account but is signed out.
  Future<FakeGameRepository> signedOutIsabella() async {
    final repository = FakeGameRepository(
      player: FakeData.newPlayer,
      latency: Duration.zero,
    );
    await repository.signOut();
    return repository;
  }

  testWidgets('a new player lands on "Create account"', (tester) async {
    await launch(tester, FakeGameRepository(latency: Duration.zero));

    expect(find.byType(CreateAccountScreen), findsOneWidget);
    expect(find.text('CREATE ACCOUNT TO START JUDGING'), findsOneWidget);
    expect(find.text('Choose country to rule in'), findsOneWidget);
  });

  testWidgets('creating an account opens home', (tester) async {
    final repository = FakeGameRepository(latency: Duration.zero);
    await launch(tester, repository);

    await fill(tester, 'Name', 'Amanda');
    await fill(tester, 'Username', 'amanda');
    await fill(tester, 'Password', 'secret1');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.byType(HomeScreen), findsOneWidget);
    final player = await repository.currentPlayer();
    expect(player?.username, 'amanda');
    expect(player?.countryCode, 'NL');
  });

  testWidgets('a taken username shows an error', (tester) async {
    await launch(tester, await signedOutIsabella());

    await fill(tester, 'Name', 'Another Isabella');
    await fill(tester, 'Username', 'isabella');
    await fill(tester, 'Password', 'secret1');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('This username is already taken.'), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
  });

  testWidgets('a missing name shows an error', (tester) async {
    await launch(tester, FakeGameRepository(latency: Duration.zero));

    await fill(tester, 'Username', 'amanda');
    await fill(tester, 'Password', 'secret1');
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your name.'), findsOneWidget);
  });

  testWidgets('each field of "Create account" is checked', (tester) async {
    final repository = FakeGameRepository(latency: Duration.zero);
    await launch(tester, repository);

    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsOneWidget);
    expect(find.text('Choose a username.'), findsOneWidget);
    expect(find.text('Choose a password.'), findsOneWidget);

    await fill(tester, 'Name', 'Amanda');
    await fill(tester, 'Username', 'a b');
    await fill(tester, 'Password', '123');
    await tester.pumpAndSettle();
    expect(find.text('Enter your name.'), findsNothing);
    expect(
      find.text('Only letters, numbers, ".", "_" and "-".'),
      findsOneWidget,
    );
    expect(find.text('Use at least 6 characters.'), findsOneWidget);
    expect(await repository.currentPlayer(), isNull);
  });

  testWidgets('"Log in" asks for both fields', (tester) async {
    await launch(tester, await signedOutIsabella());
    await tester.ensureVisible(find.text('I already have an account'));
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Enter your username.'), findsOneWidget);
    expect(find.text('Enter your password.'), findsOneWidget);
  });

  testWidgets('the eye button shows and hides the password', (tester) async {
    await launch(tester, FakeGameRepository(latency: Duration.zero));
    await fill(tester, 'Password', 'secret1');

    bool hidden() => tester
        .widget<EditableText>(
          find.descendant(
            of: find.widgetWithText(TextField, 'Password'),
            matching: find.byType(EditableText),
          ),
        )
        .obscureText;

    expect(hidden(), isTrue);
    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(hidden(), isFalse);
    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(hidden(), isTrue);
  });

  testWidgets('the country dropdown opens, filters and selects', (
    tester,
  ) async {
    await launch(tester, FakeGameRepository(latency: Duration.zero));

    await tester.tap(find.text('Choose country to rule in'));
    await tester.pumpAndSettle();
    expect(find.text('Search country'), findsOneWidget);

    await tester.tap(find.text('Netherlands'));
    await tester.pumpAndSettle();
    expect(find.text('Search country'), findsNothing);
    expect(find.text('Netherlands'), findsOneWidget);
  });

  testWidgets('log in with a wrong, then the right password', (tester) async {
    await launch(tester, await signedOutIsabella());

    await tester.ensureVisible(find.text('I already have an account'));
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    expect(find.byType(LogInScreen), findsOneWidget);
    expect(find.text('Welcome Back, Judge'), findsOneWidget);

    await fill(tester, 'Username', 'isabella');
    await fill(tester, 'Password', 'wrong-password');
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong username or password.'), findsOneWidget);

    await fill(tester, 'Password', FakeGameRepository.defaultPassword);
    await tester.tap(find.text('Log in'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byType(LogInScreen), findsNothing);
  });

  /// Home → profile → settings, for a player with a history.
  Future<FakeGameRepository> openSettings(WidgetTester tester) async {
    final repository = await FakeGameRepository.withHistory();
    await launch(tester, repository);
    await tester.tap(find.bySemanticsLabel('Open profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
    expect(find.text('Judge Isabella'), findsOneWidget);
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is AppSvg && w.assetPath == AppAssets.settings,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    return repository;
  }

  testWidgets('the profile button on the result screen opens the profile', (
    tester,
  ) async {
    final repository = await FakeGameRepository.withHistory();
    await launch(tester, repository);
    final result = await repository.reviseCase(FakeData.redLightId);
    Navigator.of(
      tester.element(find.byType(HomeScreen)),
    ).push(ResultScreen.route(result));
    await tester.pumpAndSettle();

    await tester.tap(find.bySemanticsLabel('Open profile'));
    await tester.pumpAndSettle();
    expect(find.byType(ProfileScreen), findsOneWidget);
  });

  testWidgets('the rank on the profile lists every rank', (tester) async {
    final repository = await FakeGameRepository.withHistory();
    await launch(tester, repository);
    await tester.tap(find.bySemanticsLabel('Open profile'));
    await tester.pumpAndSettle();
    final rank = (await repository.currentPlayer())!.rank;

    await tester.tap(
      find.bySemanticsLabel('Rank: ${rank.label}. Show all ranks'),
    );
    await tester.pumpAndSettle();

    expect(find.text('Judge ranks'), findsOneWidget);
    for (final r in JudgeRank.values) {
      expect(
        find.descendant(of: find.byType(Dialog), matching: find.text(r.label)),
        findsOneWidget,
      );
    }
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(Dialog), findsNothing);
  });

  testWidgets('the sensitive case filter saves the preferences', (
    tester,
  ) async {
    final repository = await openSettings(tester);
    expect(find.text('No filter selected'), findsOneWidget);

    await tester.tap(find.text('Sensitive case filter'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Violence'));
    await tester.pumpAndSettle();

    expect(find.text('No filter selected'), findsNothing);
    final player = await repository.currentPlayer();
    expect(player?.preferences.filteredTopics, {ContentWarning.violence});
  });

  testWidgets('the trigger warnings switch saves the preference', (
    tester,
  ) async {
    final repository = await openSettings(tester);
    expect(find.text('Shown before sensitive cases'), findsOneWidget);

    await tester.tap(find.text('Trigger warnings'));
    await tester.pumpAndSettle();

    expect(find.text('Sensitive cases open without a warning'), findsOneWidget);
    final player = await repository.currentPlayer();
    expect(player?.preferences.showTriggerWarnings, isFalse);
  });

  testWidgets('"Sign out" in the settings goes to "Log in"', (tester) async {
    final repository = await openSettings(tester);

    await tester.tap(find.text('Sign out'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(of: find.byType(Dialog), matching: find.text('Sign out')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(LogInScreen), findsOneWidget);
    expect(find.byType(HomeScreen), findsNothing);
    expect(await repository.currentPlayer(), isNull);
  });

  testWidgets('"Edit information" changes the name and username', (
    tester,
  ) async {
    final repository = await openSettings(tester);

    await tester.tap(find.text('Edit information'));
    await tester.pumpAndSettle();
    await fill(tester, 'Name', 'Bella');
    await fill(tester, 'Username', 'bella');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.byType(Dialog), findsNothing);
    final player = await repository.currentPlayer();
    expect(player?.name, 'Bella');
    expect(player?.username, 'bella');

    // The profile under the settings shows the new name.
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Judge Bella'), findsOneWidget);

    // The player now logs in with the new username.
    await repository.signOut();
    await expectLater(
      repository.signIn(
        username: 'isabella',
        password: FakeGameRepository.defaultPassword,
      ),
      throwsA(isA<AccountException>()),
    );
    await repository.signIn(
      username: 'bella',
      password: FakeGameRepository.defaultPassword,
    );
  });

  testWidgets('"Edit information" refuses a taken username', (tester) async {
    final repository = await FakeGameRepository.withHistory();
    await repository.createPlayer(
      name: 'Tom',
      username: 'tom',
      password: 'secret1',
      countryCode: 'NL',
    );
    await repository.signIn(
      username: 'isabella',
      password: FakeGameRepository.defaultPassword,
    );
    await launch(tester, repository);
    await tester.tap(find.bySemanticsLabel('Open profile'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byWidgetPredicate(
        (w) => w is AppSvg && w.assetPath == AppAssets.settings,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit information'));
    await tester.pumpAndSettle();
    await fill(tester, 'Username', 'tom');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(find.text('This username is already taken.'), findsOneWidget);
    expect((await repository.currentPlayer())?.username, 'isabella');
  });

  testWidgets('"Delete account" asks for the password, then starts over', (
    tester,
  ) async {
    final repository = await openSettings(tester);

    await tester.tap(find.text('Delete account'));
    await tester.pumpAndSettle();
    await fill(tester, 'Password', 'wrong-password');
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();
    expect(find.text('Wrong password.'), findsOneWidget);
    expect(await repository.currentPlayer(), isNotNull);

    await fill(tester, 'Password', FakeGameRepository.defaultPassword);
    await tester.tap(find.text('Delete'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateAccountScreen), findsOneWidget);
    expect(find.byType(SettingsScreen), findsNothing);
    expect(await repository.currentPlayer(), isNull);
    // The username is free again.
    await repository.createPlayer(
      name: 'Isabella',
      username: 'isabella',
      password: 'secret1',
      countryCode: 'NL',
    );
  });

  testWidgets('"Create new account" goes back to "Create account"', (
    tester,
  ) async {
    await launch(tester, FakeGameRepository(latency: Duration.zero));

    await tester.ensureVisible(find.text('I already have an account'));
    await tester.tap(find.text('I already have an account'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Create new account'));
    await tester.tap(find.text('Create new account'));
    await tester.pumpAndSettle();

    expect(find.byType(CreateAccountScreen), findsOneWidget);
    expect(find.byType(LogInScreen), findsNothing);
  });
}
