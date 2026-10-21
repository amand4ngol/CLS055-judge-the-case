# Judge the Case: data models guide

This guide is for building the screens. Read it once from top to bottom, then use it as a reference.

**In one sentence:** your screens talk to one object, a `GameRepository`. It has two versions that behave the same: `FakeGameRepository` (fake data in memory, no network) and `FirestoreGameRepository` (the real database, filled by the pipeline). Switching from one to the other is a one-line change, and your screens do not change.

---

## 1. Where things are

| Path | What it contains |
|---|---|
| `lib/models.dart` | One import for every model. |
| `lib/models/` | The data classes (a case, a verdict, a player…) and the game rules. |
| `lib/data/game_repository.dart` | `GameRepository`: the list of everything a screen can ask for. |
| `lib/data/fake_game_repository.dart` | `FakeGameRepository`: an in-memory version of it. |
| `lib/data/firestore_game_repository.dart` | `FirestoreGameRepository`: the version on Firebase (Auth + Cloud Firestore). |
| `lib/data/account.dart` | Account errors (`AccountException`) and username rules (`Usernames`). |
| `lib/data/fake_data.dart` | `FakeData`: 9 cases, 3 countries and a new player. |
| `test/models_test.dart`, `test/repository_contract.dart` | Good examples of how everything is used. The contract runs the same scenarios on both repositories. |

Imports:

```dart
import 'package:judge_the_case/models.dart';
import 'package:judge_the_case/data/game_repository.dart';
import 'package:judge_the_case/data/fake_game_repository.dart';
import 'package:judge_the_case/data/fake_data.dart';
```

Run the tests with `flutter test`.

---

## 2. Quick start

```dart
// A new player. For a player with some history, see section 8.
final GameRepository repo = FakeGameRepository(player: FakeData.newPlayer);

final player = (await repo.currentPlayer())!;                                // the signed-in player
final categories = await repo.categories(player.countryCode);                // category chips
final column = await repo.caseColumn(player.countryCode, categories.first); // cases of one chip

final slot = column.firstWhere((s) => s.state == CaseSlotState.next);        // "NEXT CASE · ENTER"
final ruling = await repo.openCase(slot.courtCase);                          // the player enters the case

final result = await repo.deliverVerdict(                                    // "Deliver Verdict"
  slot.courtCase,
  const PlayerVerdict(options: {VerdictOption.fine}, fineEur: 500),
);
print(result.isCorrect);        // did the player match the court?
print(result.newAchievements);  // achievements to celebrate
```

Create **one** repository when the app starts and share it with every screen. The course uses `provider` with a `ChangeNotifier`; that works well here: keep the `GameRepository` inside your app state class.

Every method returns a `Future`, so show a loading state. `FakeGameRepository` waits 150 ms on each call on purpose, so you see those states.

---

## 3. The big picture

### Where the data lives

The app stores its data in **Cloud Firestore**, the database of Firebase. Each model matches one Firestore document:

| Firestore document | Written by | Model | Used on |
|---|---|---|---|
| `cases/{ECLI}` | the case import | `CourtCase` | home, case page, trigger warning |
| `verdicts/{ECLI}` | the case import | `CaseVerdict` | result, revise |
| `countries/{code}` | the case import | `Country` | country picker |
| `users/{uid}` | the app | `PlayerProfile` | profile, settings, create account |
| `users/{uid}/rulings/{ECLI}` | the app | `PlayerRuling` | home (CONTINUE), revise list |

- **ECLI** is the official id of a court decision, for example `ECLI:NL:RBNHO:2026:13327`. It is the id of a case everywhere.
- **uid** is the Firebase Auth user id.
- You never read or write Firestore yourself: the repository does it.

### Two verdicts, never mixed

| | `PlayerVerdict` | `CaseVerdict` |
|---|---|---|
| What | What the **player** chose | What the **court** decided |
| Where | Inside `PlayerRuling.verdict` | `verdicts/{ECLI}` |
| When you get it | While the player is playing | Only **after** "Deliver Verdict" |

The court's answer is stored apart from the case on purpose: a phone that reads `cases/{ECLI}` cannot see the answer. **Never show the court's verdict before the player has delivered theirs.** The repository enforces this (see section 9).

### All models are immutable

You never change a model. You get a new copy instead (`copyWith`, `toggle`, `withFine`, `withProgress`…). This makes them safe to keep in widget state: replace the old value and call `setState`.

---

## 4. Screen by screen

The screens in the design, in the order the player sees them.

### 01 Create account (and log in)

```dart
final player = await repo.createPlayer(
  name: 'Isabella',
  username: 'isabella',
  password: 'secret1',
  countryCode: 'NL',
);
```

- `currentPlayer()` returns `null` when no one is signed in: use it to decide whether to show this screen. Firebase keeps the player signed in between launches.
- Players log in with their **username and password** (no email in the design): `repo.signIn(username:, password:)`. `repo.signOut()` logs out.
- Usernames: 3 to 20 characters among `a-z`, `0-9`, `.`, `_`, `-`, stored in lower case (`Usernames.isValid`). Passwords: at least 6 characters (`Usernames.minPasswordLength`).
- The password goes to Firebase Auth only. It is never stored in the profile. There is no "forgot password" (no email to send it to).
- Errors come as `AccountException`, whose `error` tells the screen what to show:

| `AccountError` | When |
|---|---|
| `invalidUsername` | the username breaks the rules above |
| `weakPassword` | the password is too short |
| `usernameTaken` | another player already has this username |
| `wrongCredentials` | log-in with a wrong username or password |
| `network` | no connection, or too many attempts: try again later |

### 02 Country picker

```dart
final countries = await repo.countries();
for (final c in countries) {
  print('${c.flag} ${c.name} ${c.progressLabel(player.stats)}'); // 🇳🇱 Netherlands 22% done
}
final updated = await repo.setCountry('NL');
```

| On screen | Code |
|---|---|
| Flag | `country.flag` (emoji built from the code) |
| Name | `country.name` |
| "22% done" | `country.progressLabel(player.stats)` |
| Progress bar | `country.progressFor(player.stats)` (0 to 1) |

### 03–05 Home

```dart
final categories = await repo.categories(player.countryCode);   // only categories that have cases
final column = await repo.caseColumn(player.countryCode, CaseCategory.homicide);
```

A **category** is one chip. Its label is `category.label` ("Theft & Burglary").

`caseColumn` returns a list of `CaseSlot`, one per case, oldest first, ready to draw:

| `slot.state` | Meaning | Design |
|---|---|---|
| `CaseSlotState.completed` | Verdict delivered | Gold bookmark; tap to revise |
| `CaseSlotState.inProgress` | Opened, not finished | CONTINUE + progress ring |
| `CaseSlotState.next` | First unfinished case, never opened | NEXT CASE · ENTER |
| `CaseSlotState.locked` | Comes after an unfinished case | Padlock, "Complete the previous case" |

Other useful fields:

| On screen | Code |
|---|---|
| "CASE 05" | `slot.label` |
| Case title | `slot.courtCase.title` |
| Progress ring of CONTINUE | `slot.ruling!.progress` (0 to 1) |
| Can the player tap it? | `slot.isPlayable` |

**Progression rule:** inside a category, case X+1 stays locked until case X is completed. Opening case X without finishing it (a draft) is not enough. At most one case per column is `next` or `inProgress`.

Cases the player filtered out in the settings are not in the column at all.

### 06 Case page

When the player taps a playable case:

1. If `player.preferences.needsWarning(courtCase)` is true, show the trigger warning first (07).
2. Call `openCase`. It creates the player's ruling, or returns the existing one if they already started this case (that is how CONTINUE resumes).

```dart
var ruling = await repo.openCase(courtCase);
```

**Reading the case**

| On screen | Code |
|---|---|
| "CRIMINAL" badge | `courtCase.legalArea.label` ("Criminal": display it in capitals) |
| Title | `courtCase.title` |
| "Netherlands · 2026" | `courtCase.originLabel` |
| Charges filed | `courtCase.charges` (list of strings) |
| Case summary SHORT / LONG | `courtCase.summaryShort` / `courtCase.summaryLong` |
| Argument cards | `courtCase.arguments`: each has `side.label` (Prosecution, Defence, Context) and `text` |
| "0/6" | `ruling.argumentsRead` / `ruling.argumentsCount` |

**Choosing the verdict**

Keep a `PlayerVerdict` in your widget state. Start from `ruling.verdict` (empty for a new case, the draft for CONTINUE).

```dart
var verdict = ruling.verdict;
verdict = verdict.toggle(VerdictOption.fine);   // tap a button
verdict = verdict.withFine(2500);               // move the fine slider
verdict = verdict.withPrison(18);               // move the prison slider
final canDeliver = verdict.isComplete;          // enables "Deliver Verdict"
```

| On screen | Code |
|---|---|
| The 6 buttons, in design order | `VerdictOption.values` |
| Button title / subtitle | `option.label` / `option.description` |
| Selected? | `verdict.isSelected(option)` |
| Has a slider? | `option.isAdjustable` (Fine and Prison) |
| Slider values | `verdict.fineEur` (euros), `verdict.prisonMonths` (months) |
| Slider bounds | `PlayerVerdict.fineMinEur`…`fineMaxEur` (100 to 10,000,000 €), `prisonMinMonths`…`prisonMaxMonths` (1 to 240 months) |

Button rules, already handled by `toggle`:
- The player may pick **several** buttons (Dutch sentences often combine a fine, prison and probation).
- **Acquitted** and **Case Dismissed** are exclusive: picking one clears every other button, and picking a penalty clears them.
- Selecting Fine or Prison sets its slider to the minimum. Unselecting it clears the value.

**Saving progress**

Save as the player swipes cards and picks buttons, so CONTINUE works if they leave:

```dart
ruling = await repo.saveProgress(ruling.withProgress(argumentsRead: 3, verdict: verdict));
```

`argumentsRead` never goes down, and never goes above the number of cards.

### 07 Trigger warning

| On screen | Code |
|---|---|
| Show it? | `player.preferences.needsWarning(courtCase)` |
| What the case contains | `courtCase.contentWarnings`: each has a `label` ("Sexual violence") |
| "Do not show me sensitive cases again" | see below |

```dart
await repo.savePreferences(player.preferences.copyWith(hideSensitiveCases: true));
```

After this, every case with a content warning disappears from the home columns.

### 08 Result

```dart
final result = await repo.deliverVerdict(courtCase, verdict);
```

`deliverVerdict` does everything at once: it saves the completed ruling, reads the court's verdict, and updates the stats, achievements and rank. Then show `result`:

| On screen | Code |
|---|---|
| "Correct verdict" / "Incorrect verdict – The court disagrees." | `result.isCorrect` |
| "You ruled" | `result.comparison.player.sortedOptions` |
| A "You ruled" button in red | `!result.comparison.isOptionCorrect(option)` (it is in `comparison.extra`) |
| "Court ruled" | `result.courtVerdict.courtRuled` (put in design order with `VerdictOption.values.where(courtRuled.contains)`) |
| Court buttons the player missed | `result.comparison.missed` |
| "Actual sentence" | `result.courtVerdict.actualSentence` |
| "Why the court decided this" | `result.courtVerdict.courtReasoning` |
| Amounts, if you want to show them | `result.courtVerdict.sentence` (see below) |
| Other measures (driving ban, compensation…) | `result.courtVerdict.otherMeasures`: each has a `label` |
| Gap with the court on the sliders | `result.comparison.fineGapEur`, `result.comparison.prisonGapMonths` (null unless both chose it) |
| "CRIMINAL · United Kingdom · 2021" | `result.courtCase.legalArea.label`, `result.courtCase.originLabel` |
| "Get to the detailed case here." | `result.courtCase.sourceUrl` (official page of the ruling) |

`Sentence` holds the court's amounts. A value is `null` when the court did not give that penalty:
`prisonMonths` (total, suspended part included), `prisonSuspendedMonths`, `prisonToServeMonths`, `fineEur`, `communityServiceHours`, `probationMonths`.

**When is a verdict correct?** When the player picked **exactly** the court's buttons: nothing missed, nothing extra. The slider amounts do not count; they are only shown for comparison.

"NEXT CASE" goes back to the column: the next case is now unlocked.

### 09 Achievement unlocked

After the result, show each item of `result.newAchievements`, one screen per achievement:

| On screen | Code |
|---|---|
| Round badge | `achievement.badge` ("I", "III", "70", "X"…) |
| Title | `achievement.title` |
| Sentence | `achievement.unlockMessage` |

If `result.newRank` is not null, the player just reached a new rank: you can celebrate that too.

### 10 Profile

| On screen | Code |
|---|---|
| "Judge Isabella" | `player.displayName` |
| "Law Student" | `player.rank.label` |
| Milestone bar | `player.rankProgress.fraction` (0 to 1) |
| "0/5" | `player.rankProgress.counterLabel` |
| "5 more cases to reach your next milestone." | `player.rankProgress.message` |
| Cases | `player.stats.casesJudged` |
| Accuracy | `player.stats.accuracyLabel` ("–" before the first case, then "67%") |
| Best streak | `player.stats.bestStreakLabel` |
| "0/8 unlocked" | `player.achievementsLabel` |
| Achievement list | `Achievement.values`, then `player.hasUnlocked(a)`, `a.badge`, `a.title`, `a.description` |
| "Revise your previous cases" | `await repo.completedRulings(limit: 3)`: newest first, each with `caseTitle`, `category`, `country`, `year`, `isCorrect` |
| "Preview" of a past case | `await repo.reviseCase(caseId)`: a `RulingResult`, shown like screen 08 |

Revising a past case never changes the stats.

### 11 Settings

```dart
var prefs = player.preferences;
prefs = prefs.toggleTopic(ContentWarning.sexualViolence);   // tick or untick a topic
await repo.savePreferences(prefs);
```

| On screen | Code |
|---|---|
| Topics list | `ContentWarning.values`, with `label` |
| Ticked? | `prefs.filteredTopics.contains(topic)` |
| "Hide sensitive cases" | `prefs.hideSensitiveCases` |

`savePreferences` returns the updated player. Reload the home columns after it.

---

## 5. The models, one by one

Only what you need on screen. Every model also has `fromFirestore(id, map)` and `toMap()`; those are for the repository, not for you.

### `CourtCase`: a case, before the verdict

| Field | Type | Example |
|---|---|---|
| `id` | `String` | `ECLI:NL:RBNHO:2026:13327` |
| `title` | `String` | "Red Light at 130" |
| `category` | `CaseCategory` | `CaseCategory.traffic` |
| `legalArea` | `LegalArea` | always `criminal` for now |
| `country` / `countryName` | `String` | `NL` / "Netherlands" |
| `year`, `decisionDate` | `int`, `DateTime?` | 2026 |
| `court` | `String` | name of the court |
| `charges` | `List<String>` | the charges filed |
| `summaryShort`, `summaryLong` | `String` | never reveal the outcome |
| `arguments` | `List<CaseArgument>` | the swipeable cards |
| `contentWarnings` | `Set<ContentWarning>` | empty if not sensitive |
| `sourceUrl` | `Uri` | official ruling page |
| `addedAt` | `DateTime?` | orders cases in a column |
| `isSensitive` | getter | has at least one warning |
| `originLabel` | getter | "Netherlands · 2026" |

### `CaseVerdict`: what the court decided

| Field | Type |
|---|---|
| `caseId` | `String` (same ECLI) |
| `courtRuled` | `Set<VerdictOption>`: the buttons matching the decision |
| `sentence` | `Sentence`: the amounts |
| `otherMeasures` | `List<OtherMeasure>`: penalties with no button (`type`, `label`) |
| `actualSentence` | `String` |
| `courtReasoning` | `String` |

### `PlayerVerdict`: what the player chose

| Member | Purpose |
|---|---|
| `options` | `Set<VerdictOption>` |
| `fineEur`, `prisonMonths` | slider values, null when not selected |
| `toggle(option)` | tap a button |
| `withFine(eur)`, `withPrison(months)` | move a slider (values are clamped to the bounds) |
| `isSelected(option)` | is a button on |
| `isComplete` | at least one button, and every selected slider has a value |
| `sortedOptions` | selected buttons in design order |
| `PlayerVerdict.empty` | nothing selected |

### `PlayerRuling`: one case as played by the player

Created by `openCase`, completed by `deliverVerdict`.

| Field | Meaning |
|---|---|
| `caseId` | the ECLI |
| `status` | `RulingStatus.inProgress` (draft) or `RulingStatus.completed` |
| `isCompleted` | getter |
| `argumentsRead` / `argumentsCount` | cards read / total |
| `verdict` | the draft while in progress, the final verdict once completed |
| `progress` | 0 to 1, for the CONTINUE ring (see section 6) |
| `isCorrect` | null until completed |
| `startedAt`, `submittedAt` | dates |
| `caseTitle`, `category`, `country`, `year` | copied from the case, so the revise list needs no extra loading |
| `withProgress(argumentsRead:, verdict:)` | the updated draft to pass to `saveProgress` |

### `RulingResult`: what "Deliver Verdict" returns

| Member | Meaning |
|---|---|
| `isCorrect` | the verdict matches the court |
| `comparison` | `RulingComparison` (below) |
| `courtVerdict` | the `CaseVerdict` |
| `courtCase` | the `CourtCase` |
| `ruling` | the completed `PlayerRuling` |
| `profile` / `profileBefore` | the player after / before this case |
| `newAchievements` | `List<Achievement>`, may be empty |
| `newRank` | `JudgeRank?`, set only when the rank changed |

### `RulingComparison`: player vs court

| Member | Meaning |
|---|---|
| `player` / `court` | the two verdicts |
| `matched` | buttons both picked |
| `missed` | court buttons the player did not pick |
| `extra` | player buttons the court did not pick (red) |
| `isCorrect` | `missed` and `extra` are both empty |
| `isOptionCorrect(option)` | the option is in `matched` |
| `fineGapEur`, `prisonGapMonths` | player amount minus court amount, or null |

### `CaseSlot`: one case in a home column

| Member | Meaning |
|---|---|
| `courtCase` | the case |
| `number`, `label` | 1, "CASE 01" |
| `state` | `completed`, `inProgress`, `next` or `locked` |
| `ruling` | the player's ruling, if the case was opened |
| `isPlayable` | not locked |

### `PlayerProfile`: the player

| Member | Meaning |
|---|---|
| `uid`, `name`, `username` | identity |
| `displayName` | "Judge Isabella" |
| `countryCode` | the country they play in |
| `preferences` | `ContentPreferences` |
| `stats` | `PlayerStats` |
| `achievements` | `Map<Achievement, DateTime>`: unlock date of each earned one |
| `hasUnlocked(a)`, `achievementsLabel` | helpers |
| `rank`, `rankProgress` | `JudgeRank`, `RankProgress` |

### `PlayerStats`: the counters

`casesJudged`, `correctVerdicts`, `currentStreak`, `bestStreak`, `accuracy` (0 to 1, or null), `accuracyLabel`, `bestStreakLabel`, `completedByCountry`, `completedByCategory`.

### `ContentPreferences`: settings

`hideSensitiveCases`, `filteredTopics`, `allows(case)`, `needsWarning(case)`, `toggleTopic(topic)`, `copyWith(...)`.

### `Country`

`code` (`NL`), `name`, `publishedCases`, `flag`, `progressFor(stats)`, `progressLabel(stats)`.

### Enums

Each enum value has a `label` to show (and a `value`, the string stored in Firestore).

| Enum | Values |
|---|---|
| `CaseCategory` (13) | homicide, violence, sexualOffences, theft, fraud, financial, drugs, traffic, weapons, cybercrime, environmental, publicOrder, other |
| `VerdictOption` (6) | fine, prison, communityService, probation, acquitted, caseDismissed |
| `ContentWarning` (7) | violence, sexualViolence, death, minors, drugs, selfHarm, animalCruelty |
| `ArgumentSide` | prosecution, defence, context |
| `MeasureType` | drivingBan, compensation, confiscation, tbs, juvenileTreatmentOrder, repeatOffenderOrder, behaviouralOrder, lossOfRights, publication, other |
| `RulingStatus` | inProgress, completed |
| `JudgeRank` | see section 6 |
| `Achievement` | see section 6 |

---

## 6. Game rules

All rules live in the models, each in one place. Screens only display the results.

| Rule | Value | Where |
|---|---|---|
| Correct verdict | exactly the court's buttons; slider amounts do not count | `RulingComparison` |
| Exclusive buttons | Acquitted and Case Dismissed cannot be combined with anything | `PlayerVerdict.toggle` |
| Progression | case X+1 is locked until case X is completed | `CaseSlot.column`, enforced by the repository |
| Case order in a column | by `addedAt`, oldest first | `CaseSlot.column` |
| CONTINUE ring | 80% for the cards read + 20% once at least one button is selected | `PlayerRuling.progress` |
| Streak | +1 for a correct verdict, back to 0 for an incorrect one | `PlayerStats.record` |
| Accuracy | correct verdicts / cases judged | `PlayerStats.accuracy` |
| Country progress | completed cases in that country / published cases | `Country.progressFor` |
| Replaying a completed case | changes nothing | `RulingResult.evaluate` |

**Ranks** (cases judged needed):

| Rank | Cases |
|---|---|
| Law Student | 0 |
| Court Clerk | 5 |
| Junior Judge | 10 |
| Judge | 20 |
| Senior Judge | 35 |
| Chief Justice | 50 |

**Achievements** (8):

| Badge | Title | Unlocked when |
|---|---|---|
| I | First ruling! | 1 case judged |
| III | On a roll! | best streak reaches 3 |
| 70 | Sharp judgment! | accuracy ≥ 70%, counted only after 10 cases |
| X | Casebook! | 10 cases judged |
| XX | Case scholar | 20 cases judged |
| XXX | Court regular | 30 cases judged |
| XL | Senior jurist | 40 cases judged |
| L | Master judge | 50 cases judged |

The thresholds and the correctness rule are first choices; they may still change. Since each lives in one place, your screens will not need to change if they do.

---

## 7. `GameRepository`: every method

| Method | Returns | Used on |
|---|---|---|
| `currentPlayer()` | `PlayerProfile?` (null when no one is signed in) | app start |
| `createPlayer(name:, username:, password:, countryCode:)` | `PlayerProfile`, signed in | 01 |
| `signIn(username:, password:)` | `PlayerProfile` | log-in |
| `signOut()` | — | profile, settings |
| `countries()` | `List<Country>` | 02 |
| `setCountry(code)` | `PlayerProfile` | 02 |
| `savePreferences(prefs)` | `PlayerProfile` | 07, 11 |
| `categories(countryCode)` | `List<CaseCategory>` that have cases | home chips |
| `caseColumn(countryCode, category)` | `List<CaseSlot>` | home |
| `caseById(caseId)` | `CourtCase` | anywhere you only have an id |
| `openCase(courtCase)` | `PlayerRuling` (new or existing) | 06 |
| `saveProgress(ruling)` | `PlayerRuling` | 06 |
| `deliverVerdict(courtCase, verdict)` | `RulingResult` | 06 → 08 |
| `completedRulings(limit:)` | `List<PlayerRuling>`, newest first | 10 |
| `reviseCase(caseId)` | `RulingResult` | 10 (Preview) |

Methods that return a `PlayerProfile` give you the updated player: use it, do not keep the old one.

---

## 8. Fake data

### Two ways to start

```dart
// A brand new player: every column starts on NEXT CASE.
final repo = FakeGameRepository(player: FakeData.newPlayer);

// A player who already played: 2 cases judged (1 correct, 1 incorrect)
// and 1 case in progress. Good for the profile, CONTINUE and revise screens.
final repo = await FakeGameRepository.withHistory();

// No player yet: currentPlayer() is null, to build "Create account".
final repo = FakeGameRepository();
```

`FakeData.newPlayer` can log in again after `signOut()` with the username `isabella` and the password `FakeGameRepository.defaultPassword` (`password`). Accounts created with `createPlayer` work the same, each with its own progress.

The delay is 150 ms by default; pass `latency: Duration.zero` to remove it (useful in tests). `withHistory()` has no delay unless you pass one: `FakeGameRepository.withHistory(latency: const Duration(milliseconds: 150))`. Nothing is saved between app launches.

### The player

`FakeData.newPlayer` is "Isabella" (`isabella`), playing in the Netherlands (`NL`).

### The countries

| Code | Name | Published cases |
|---|---|---|
| NL | Netherlands | 9 |
| OM | Oman | 0 |
| PT | Portugal | 0 |

Oman and Portugal have no cases: use them to build the empty state.

### The 9 cases (all in the Netherlands)

| Id constant | Title | Category | Content warnings | Court ruled |
|---|---|---|---|---|
| `FakeData.redLightId` | Red Light at 130 | traffic | violence, minors | prison, probation |
| `FakeData.deathAtTheWheelId` | Death at the Wheel | traffic | death | community service, probation |
| `FakeData.shoplifterId` | The Shoplifter's Dilemma | theft | none | case dismissed |
| `FakeData.insiderTraderId` | The Insider Trader | financial | none | fine, probation |
| `FakeData.whistleblowerId` | The Whistleblower Hacker | cybercrime | none | community service |
| `FakeData.healingWeekendId` | The Healing Weekend | homicide | death, drugs | prison, probation |
| `FakeData.silentWitnessId` | The Silent Witness | homicide | violence, death | acquitted |
| `FakeData.scootersId` | Seven Mobility Scooters | fraud | none | community service, probation |
| `FakeData.fakeInvoicesId` | The Fake Invoices | fraud | none | prison |

- Traffic, homicide and fraud have **2 cases**: use them to see the locked state.
- "Red Light at 130" is a **real** court decision. The 8 others are **invented**: their ECLI and link do not exist.
- In `withHistory()`: Red Light at 130 is completed (incorrect), The Shoplifter's Dilemma is completed (correct), The Healing Weekend is in progress (3 of 5 cards read).

---

## 9. Errors

| When | What happens |
|---|---|
| `openCase`, `saveProgress` or `deliverVerdict` on a **locked** case (or a case hidden by the settings) | `StateError` |
| `deliverVerdict` with a verdict that is not complete (`isComplete` is false) | `ArgumentError` |
| `reviseCase` on a case that is not completed | `StateError`: the court's verdict stays hidden |
| `caseById` with an unknown id | `StateError` |
| Any method that needs a player, called when no one is signed in | `StateError` |
| `createPlayer` or `signIn` with a bad username, password or connection | `AccountException` (see screen 01) |

If your screens follow the slot states and only enable "Deliver Verdict" when `verdict.isComplete`, none of these should happen. They are safety nets.

---

## 10. Do and don't

- **Do** go through `GameRepository` for everything. Never call Firestore from a screen.
- **Do** use the `label` of enums and the ready-made labels (`accuracyLabel`, `counterLabel`, `originLabel`…) instead of building text yourself.
- **Do** replace your copy of the player with the one each method returns.
- **Don't** show anything from `CaseVerdict` before "Deliver Verdict".
- **Don't** compute rules in the UI (correctness, locks, stats, achievements): read them from the models.
- **Don't** change a model in place: use `toggle`, `withFine`, `withProgress`, `copyWith`…

---

## 11. The real database

`FirestoreGameRepository` implements the same interface on Firebase. Firebase is set up in `main.dart` (`Firebase.initializeApp`); then only the line that creates the repository changes:

```dart
import 'package:judge_the_case/data/firestore_game_repository.dart';

final GameRepository repo = FirestoreGameRepository();
```

- It reads the cases the pipeline published (`cases`, `verdicts`, `countries`) and stores each player in `users/{uid}` and `users/{uid}/rulings/{ECLI}`.
- The security rules (`firestore.rules`) let a signed-in player read published cases and only their own data. The court's verdict of a case can only be read once the player has delivered theirs.
- It is the shared database: what you test with it lands next to real players' data. Use `FakeGameRepository` while building screens.
- Calls take real network time and can fail without a connection: show loading and error states.

Rules and indexes live in `firestore.rules` and `firestore.indexes.json`. Test the rules on the local emulator (no account needed), then deploy them:

```bash
npx -y firebase-tools emulators:exec --only firestore --project demo-judge-the-case "flutter test test/firestore_rules_test.dart"
```

```bash
firebase deploy --only firestore:rules,firestore:indexes
```
