<div align="center">
<img src="https://github.com/user-attachments/assets/270699c1-c627-4ff0-840c-7e9a39c0faa9" alt="Judge the Case logo" width="96" />

# Judge the Case

**Read. Decide. Discover the ruling.**

A mobile game where you read a real criminal case, deliver your own verdict
and compare it with what the court actually decided.

![Flutter](https://img.shields.io/badge/Flutter-02569B?logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-0175C2?logo=dart&logoColor=white)
![Firebase](https://img.shields.io/badge/Firebase-FFCA28?logo=firebase&logoColor=black)
![Platform](https://img.shields.io/badge/platform-Android%20%7C%20iOS-lightgrey)

</div>

---

## About

People hold strong opinions about sentencing, often based on a headline
rather than the full case. Research shows that when people know all the
facts, they tend to choose sentences similar to, or milder than, those of
judges.

**Judge the Case** puts you on the bench. Each case is a real, pseudonymised
criminal judgment from the Dutch courts, translated and summarised in plain
English. You weigh the arguments of the prosecution and the defence, choose a
sentence, and then see the court's decision and its reasoning.

The project connects to the UN Sustainable Development Goals, mainly
**SDG 16 – Peace, Justice and Strong Institutions** (public access to
information and trust in the rule of law) and **SDG 4 – Quality Education**.

> Built as a group project in the course *Mobile Computing: Design and
> Implementation* at Chalmers University of Technology / University of
> Gothenburg.

## Screenshots
<table>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/be2f4344-b96f-4281-b3e9-02bc5e8afb7e" width="200" alt="Home screen"/><br/><b>Home</b><br/>Cases as pillars, by category</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/8818bf2b-7051-4632-bbd9-425eb306860d" width="200" alt="Case screen"/><br/><b>Case</b><br/>Read the case</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/085c279b-0783-4aeb-b3a6-8a724c5a5610" width="200" alt="Case screen"/><br/><b>Case</b><br/>Swipe through the arguments</td>
    </tr>
  <tr>
    <td align="center"><img src="https://github.com/user-attachments/assets/f82a79e4-6612-4579-a79e-3641f3e08bd6" width="200" alt="Result screen"/><br/><b>Verdict</b><br/>Your verdict</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/583c43d8-5c62-42e2-a32d-36679dc446df" width="200" alt="Result screen"/><br/><b>Result</b><br/>Your verdict vs. the court's</td>
    <td align="center"><img src="https://github.com/user-attachments/assets/893535a3-43a7-4859-b2d2-404c8743a969" width="200" alt="Profile screen"/><br/><b>Profile</b><br/>Rank, statistics and achievements</td>
  </tr>
</table>

## Features

- **Real court cases** – pseudonymised Dutch criminal judgments, summarised
  for non-lawyers, with a link to the official ruling.
- **Weigh both sides** – swipeable argument cards, colour-coded for the
  prosecution, the defence and neutral context.
- **Realistic verdicts** – combine a fine, prison, community service and
  probation, or choose acquittal or dismissal. Amounts can be set with a
  slider or typed in.
- **Compare with the court** – see both verdicts side by side, the actual
  sentence and the court's reasoning.
- **Progression** – climb from *Law Student* to *Chief Justice*, keep a
  streak and unlock eight achievements. Completed cases turn gold when your
  verdict matched the court and silver when it did not.
- **Case history** – revisit past cases with both verdicts.
- **Guided onboarding** – an interactive tour with an animated hand showing
  which gesture to use.
- **Sensitive content controls** – trigger warnings before sensitive cases,
  plus a separate filter to hide specific topics.

## How it works

```
Rechtspraak Open Data  ──►  Case pipeline (LLM)  ──►  Firebase  ──►  Flutter app
   Dutch judgments           translate, summarise,                   read, judge,
   (pseudonymised)           hide the outcome,                       compare
                             structure the data
```

1. Criminal judgments are fetched from the
   [Open Data service of the Dutch judiciary](https://www.rechtspraak.nl/uitspraken/open-data).
2. A pipeline uses a large language model to translate and summarise each
   judgment into plain English and extract the charges, the arguments, the
   prosecutor's demand, the sentence and the court's reasoning.
3. Automated checks make sure, for example, that a summary does not reveal
   the court's decision before the player has judged the case.
4. The processed cases are stored in Firebase and loaded by the app.

A verdict counts as **matching the court** when the player chose the same
types of sanction; the amounts are shown for comparison but not scored.

## Tech stack

| Layer | Technology |
|---|---|
| App | Flutter (Dart), Provider for state management |
| Backend | Firebase |
| Data | Rechtspraak Open Data (Dutch judiciary) |
| Case processing | Large language model pipeline |
| Design | Figma, Material 3 |

## Getting started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (stable channel)
- An Android emulator, iOS simulator or a physical device
- A Firebase project (for your own setup)

### Run the app

```bash
git clone https://github.com/amand4ngol/CLS055-judge-the-case.git
cd CLS055-judge-the-case
flutter pub get
flutter run
```

### Firebase configuration

The app needs a Firebase configuration to load cases. To use your own
Firebase project:

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

This generates `lib/firebase_options.dart` for your project.

## Project structure

```
lib/
├── main.dart          # App entry point
├── screens/           # Home, case, verdict, result, profile, onboarding
├── widgets/           # Reusable UI components
├── providers/         # State management (Provider)
├── models/            # Case, verdict and user data models
└── repositories/      # Data access (Firebase)
docs/
└── screenshots/       # Images used in this README
```

## Limitations and future work

- All cases currently come from the Netherlands, the only source we found
  with free, pseudonymised first-instance judgments that state the charges,
  the demand, the sentence and the reasoning.
- Planned: cases from other countries, so players can compare how the same
  offence is punished in different legal systems.
- Ideas: showing the relevant laws in each case, re-judging a case after
  reading the court's reasoning, and comparing your verdict with other
  players'.

## Team

| Name | Role |
|---|---|
| Aman Dangol | Development |
| Teo Maitrot | Development, data pipeline |
| Josefin Alström | Design |
| Rozet Hachicho | Design |



## Acknowledgements

- Case data: [De Rechtspraak – Open Data](https://www.rechtspraak.nl/uitspraken/open-data)
- Course: Mobile Computing: Design and Implementation, Chalmers University of
  Technology / University of Gothenburg

---

<sub>This app is an educational project. Summaries may simplify the original
judgments; always refer to the official ruling for the full decision.</sub>
