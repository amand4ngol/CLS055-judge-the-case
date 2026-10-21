# Rechtspraak → Claude → Firestore pipeline

This script fills the app's database. It fetches real Dutch criminal rulings from Rechtspraak Open Data, has Claude convert them into English in the app's format, checks them, then writes them to Firestore (Firebase's database).

It runs on your computer, never in the app: the keys stay with you.

## What it does for each ruling

The steps go from the cheapest to the most expensive, so you only pay for what is useful:

1. **Search** on Rechtspraak (free): criminal rulings with a full text, between two dates.
2. **Court filter** (free): district court, court of appeal or Supreme Court, read from the ECLI.
3. **Duplicate check** (free): one read of the registry for a whole page of results. A ruling already handled is skipped before any call to Claude.
4. **Pre-sort** by Claude Haiku 5.5 from the official summary (about $0.0003): category, and "is this a criminal judgment on the merits?".
5. **Full analysis** by Claude Sonnet 5.5 (about $0.05 to $0.15): title, summaries, arguments, the court's verdict.
6. **Automatic checks**: valid schema, sentence amounts present in the ruling, no hint of the outcome in the texts shown before the verdict. For the last one, a word search ("acquittal", "sentenced", "prison"…) is only a signal; when it finds something, Claude Haiku 5.5 judges whether the outcome is really revealed (about $0.001). A request by the defence or the prosecution is not a hint; the first-instance judgment of an appeal is one.
7. **Write** to Firestore, in a single operation: `cases/{ECLI}`, `verdicts/{ECLI}`, the `countries/NL.publishedCases` counter, and the `ingestion/{ECLI}` registry.

If a check fails, the case is **not published**: it is set aside (`needs_review`) with its JSON, for a human review.

## 1. Install

From the root of the repository:

```bash
flutter pub get
```

## 2. Add the keys

All keys go in `tool/pipeline/.env`. Git ignores this file: it is never committed.

```bash
cp tool/pipeline/.env.example tool/pipeline/.env
```

Then fill it in:

| Variable | Value |
|---|---|
| `ANTHROPIC_API_KEY` | Your Anthropic API key (`sk-ant-…`), created in the Claude Console under *API Keys*. |
| `FIREBASE_PROJECT_ID` | The Firebase project ID (step 4 of the setup below). |
| `GOOGLE_APPLICATION_CREDENTIALS` | The **absolute** path of the Firebase key file (step 6 of the setup). |

An environment variable with the same name (for example `export ANTHROPIC_API_KEY=…` in the terminal) takes precedence over the file.

Never put these keys in the app's code, in another file of the repository, or in a message.

## 3. Set up the Firebase project

This is done once.

1. Go to <https://console.firebase.google.com> and sign in with your Google account.
2. Click **Create a project**. Name: `judge-the-case`. Google Analytics is not needed: you can turn it off. Confirm.
3. In the left menu, open **Build** → **Firestore Database** → **Create database**:
   - **Location**: pick a region in Europe (for example `eur3 (europe-west)`). This choice is permanent.
   - **Mode**: **production**. Phones cannot read anything until the security rules are written; the pipeline is not affected, since it uses a service account.
4. **Project ID**: gear icon at the top left → **Project settings** → **General** tab → *Project ID* (for example `judge-the-case-1a2b3`). It is also the part after `/project/` in the console's address. Copy it into `FIREBASE_PROJECT_ID`.
5. **Service account key**: still in **Project settings**, **Service accounts** tab → **Firebase Admin SDK** → **Generate new private key**. A JSON file is downloaded.
6. Store this key **outside the repository** and protect it:

   ```bash
   mkdir -p ~/.config/judge-the-case
   ```

   ```bash
   mv ~/Downloads/<downloaded-file-name>.json ~/.config/judge-the-case/firebase-admin.json
   ```

   ```bash
   chmod 600 ~/.config/judge-the-case/firebase-admin.json
   ```

   Then put its full path (for example `/Users/<you>/.config/judge-the-case/firebase-admin.json`) in `GOOGLE_APPLICATION_CREDENTIALS`. `realpath ~/.config/judge-the-case/firebase-admin.json` prints it.

This key gives full rights on the database: never commit it, send it to anyone or put it in the app. If it leaks, delete it in the same tab and generate a new one.

The free **Spark** plan is enough: the pipeline makes a few reads and writes per case.

## 4. Run

Always from the root of the repository. An argument the script does not recognise stops the run, so that no filter is silently ignored.

**First try, without Firebase**: results go to `tool/pipeline/out/` (ignored by git).

```bash
dart run tool/pipeline/main.dart --local --limit 3
```

**For real**, in Firestore:

```bash
dart run tool/pipeline/main.dart --from 2026-01-01 --to 2026-06-30 --category traffic,drugs --limit 10
```

**One or more specific rulings**, comma-separated, without spaces:

```bash
dart run tool/pipeline/main.dart --ecli ECLI:NL:RBNHO:2026:13327,ECLI:NL:GHAMS:2026:2949
```

**Re-check the cases set aside** (`needs_review`) with the current checks, from their stored JSON: only Haiku is called, not Sonnet.

```bash
dart run tool/pipeline/main.dart --recheck
```

All options:

```bash
dart run tool/pipeline/main.dart --help
```

| Option | Purpose | Default |
|---|---|---|
| `--from`, `--to` | decision dates (YYYY-MM-DD) | one year ago → today |
| `--category` | one or more categories, comma-separated | all |
| `--court` | `district`, `appeal`, `supreme` | `district,appeal` |
| `--limit` | number of cases to publish, then stop | 10 |
| `--max-cost` | budget of the run in dollars, then stop | 5 |
| `--model` | `claude-sonnet-5-5` or `claude-opus-5-5` (twice the price) | Sonnet 5.5 |
| `--effort` | thinking effort of the full analysis | `high` |
| `--ecli` | process only these rulings, comma-separated | — |
| `--local` | work without Firebase, in `tool/pipeline/out/` | — |
| `--retry-failed` | retry the failed rulings | — |
| `--force` | process rulings already seen again, except published ones | — |
| `--recheck` | re-check the `needs_review` cases without a new full analysis | — |

Categories: `homicide`, `violence`, `sexual_offences`, `theft`, `fraud`, `financial`, `drugs`, `traffic`, `weapons`, `cybercrime`, `environmental`, `public_order`, `other`.

The pre-sort only reads the official summary, so it can get the category wrong. The full analysis sets the final category.

A run also stops after 3 failed analyses in a row: past that, the cause is most likely systematic.

## 5. Duplicate check: the `ingestion/{ECLI}` registry

Every ruling the pipeline touches has an entry in the `ingestion` collection (or in `tool/pipeline/out/registry.json` with `--local`). Running the pipeline again costs nothing for the rulings already seen.

| Status | Meaning | Processed again later? |
|---|---|---|
| `published` | in the app | never |
| `needs_review` | a check failed; the JSON is in the `result` field | with `--recheck` (no Sonnet), or `--force` (new analysis) |
| `rejected` | not a criminal judgment on the merits | never (unless `--force`) |
| `filtered` | not in the requested categories; its category is kept | yes, without a new pre-sort, when a run asks for its category |
| `failed` | error (network, refusal, invalid JSON) | only with `--retry-failed` |
| `processing` | being handled by a run | only if stuck for more than an hour |

Two runs at the same time never handle the same ruling: each one reserves it before paying for the full analysis.

## 6. Costs

The cost of each case and the total are printed during the run. The system prompt is cached between calls, which lowers the price of the following calls. `--max-cost` stops the run as soon as the budget is reached.

## 7. Tests

The pipeline tests make no network calls and cost nothing:

```bash
flutter test test/pipeline/
```

## Not done yet

- Publishing a `needs_review` case by hand after a human review.
- The daily sync of rulings modified or deleted on Rechtspraak.
- Firestore security rules: phones must not be able to read the `ingestion` collection.
- Connecting the app to Firebase (`flutterfire configure`).
