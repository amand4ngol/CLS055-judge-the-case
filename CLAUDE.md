# Judge the Case : contexte du projet

Ce fichier résume la phase de R&D (octobre 2026) pour qu'une session Claude Code reprenne le travail sans repartir de zéro. Le dépôt contient le code ; ce fichier dit **pourquoi** il est comme ça.

## Le produit

« Judge the Case » est une app mobile **Flutter** (iOS d'abord, testée sur le simulateur iPhone) où le joueur lit une **vraie affaire pénale**, puis rend son verdict (amende, prison, travail d'intérêt général, sursis, acquittement, classement) avant de découvrir ce que le tribunal a réellement décidé.

Architecture :

```
Rechtspraak Open Data (XML néerlandais)
        │  pipeline backend (à écrire) : récupère, appelle un LLM, valide
        ▼
Firestore  cases/{ECLI}  verdicts/{ECLI}  countries/{code}
        ▲
        │  lecture seule pour les affaires ; écrit users/{uid}/…
App Flutter (le frontend ne parle jamais à Rechtspraak ni au LLM)
```

## Décisions prises (ne pas rouvrir sans raison)

| Décision | Pourquoi |
|---|---|
| **Source unique : Rechtspraak Open Data** (justice néerlandaise, `https://data.rechtspraak.nl/uitspraken`), gratuit, sans clé | Sur 15 décisions pénales lues, 15/15 ont les chefs d'accusation, la réquisition, la peine exacte et la motivation. Données pseudonymisées par les tribunaux. Alternatives écartées : UK Find Case Law (appel seulement, vrais noms, licence requise pour traitement IA), CourtListener (peines rarement exploitables, 125 req/jour), Judilibre FR (pas de tribunaux correctionnels). |
| Le texte néerlandais est **traduit en anglais par le pipeline IA** | L'app est en anglais. |
| **Affaires pénales uniquement** | Le schéma ne modélise que des issues pénales. Le prompt rejette le civil et l'administratif (`status: "rejected"`). |
| Firestore découpé en **`cases/{ECLI}`** (avant verdict) et **`verdicts/{ECLI}`** (la réponse) | Firestore envoie le document entier au téléphone : la réponse doit être dans un autre document pour qu'une règle de sécurité la cache tant que le joueur n'a pas voté. |
| Identifiant = **ECLI** (ex. `ECLI:NL:RBNHO:2026:13327`) | Identifiant officiel européen, stable. |
| Lien vers la décision : `https://deeplink.rechtspraak.nl/uitspraak?id=<ECLI>`, **construit par le code**, jamais par le LLM | Lien permanent garanti par Rechtspraak. |
| **13 catégories** (base CBS) : homicide, violence, sexual_offences, theft, fraud, financial, drugs, traffic, weapons, cybercrime, environmental, public_order, other | Correspond aux chips du design. |
| **Boutons de verdict (choix multiple)** : fine, prison, community_service, probation, acquitted, case_dismissed. Montants dans `verdict.sentence` ; interdiction de conduire, indemnisation, confiscation, TBS… dans `otherMeasures` | Les peines néerlandaises sont presque toujours composées (14/15 avaient plusieurs parties). |
| Modèles Dart en **Dart pur**, sans dépendance Firebase : `fromFirestore(id, map)` / `toMap()` | Utilisables par l'app, par le backend Dart et dans les tests. |

## Où sont les choses (dans ce dépôt)

- Racine : **l'app Flutter** (`lib/`, `test/`, `ios/`, `android/`…, créée avec `flutter create`). Elle dépend du package des modèles en `path: packages/judge_the_case_models`.
- `packages/judge_the_case_models/` : **les modèles de l'app**, les règles du jeu, l'interface `GameRepository`, les fausses données (`FakeData`, `FakeGameRepository`) et 13 tests. Mode d'emploi : `packages/judge_the_case_models/MODELS.md`.
- `docs/data-model/` : `case.schema.json` (sortie du pipeline, JSON Schema 2020-12, **source de vérité**), `example-case.json` (vraie décision, valide), `README.md` (correspondance design ↔ champs), `prompt-rechtspraak-to-case.md` (prompt du pipeline).
- `docs/design/` : les 11 écrans du design final, numérotés dans l'ordre du parcours.
- `docs/pipeline-mockup/` : code Dart de la maquette qui a servi à tester le pipeline (appel Rechtspraak, appel Claude, validation, contrôles). **Référence pour le backend, pas du code de production** : il importe `../models.dart` (l'équivalent de `package:judge_the_case_models/models.dart`) et dépend de `http`, `xml`, `json_schema`. Il n'est pas compilé : `docs/**` est exclu de l'analyse dans `analysis_options.yaml`.
- Référence complète des champs Rechtspraak (anglais) : https://claude.ai/code/artifact/a29e20e0-bc47-4b84-a175-2e4b0dda3d70

## Commandes et conventions

- Package des modèles (Dart pur, testé seul) : `cd packages/judge_the_case_models && dart pub get && dart analyze && dart test` (13 tests).
- App : `flutter pub get`, `flutter analyze`, `flutter test` depuis la racine. L'analyse de l'app exclut `packages/**` (chaque package a ses propres règles) et `docs/**`.
- Commits au format Conventional Commits (`chore: …`, `feat: …`). Branches de travail préfixées par le type (`chore/…`, `feat/…`), fusionnées dans `main` par pull request.
- Pas de CI pour l'instant.

## Modèle de données en bref

| Document | Écrit par | Modèle Dart |
|---|---|---|
| `cases/{ECLI}` | pipeline | `CourtCase` |
| `verdicts/{ECLI}` | pipeline | `CaseVerdict` |
| `countries/{code}` | pipeline (compteur `publishedCases`) | `Country` |
| `users/{uid}` | app | `PlayerProfile` (+ `PlayerStats`, `ContentPreferences`, succès) |
| `users/{uid}/rulings/{ECLI}` | app | `PlayerRuling` (+ `PlayerVerdict`) |

`PlayerVerdict` (ce que le joueur a choisi) et `CaseVerdict` (ce que le tribunal a décidé) ne sont jamais mélangés. `RulingComparison.compare` les compare, `RulingResult.evaluate` calcule d'un coup la ruling complétée, les stats, les succès et le rang.

Quand le pipeline publie une affaire, il écrit `cases/{ECLI}` et `verdicts/{ECLI}`, et incrémente `countries/{code}.publishedCases`.

## Pièges à connaître

- **Ne jamais montrer le résumé officiel (`inhoudsindicatie`) avant le verdict** : il révèle presque toujours la peine. Le pipeline réécrit les résumés sans l'issue, et un contrôle cherche les mots « sentenced », « acquitted », « convicted », « found guilty » dans les textes d'avant-verdict.
- **Ne jamais stocker de clé API** (Anthropic ou autre) dans le dépôt : variable d'environnement ou secret manager.
- Rechtspraak : 10 requêtes/s maximum, **pas de téléchargement de toute la base** par l'API ; ne récupérer que les affaires gardées. Réponses en **XML**, pas JSON. Les URI de domaine juridique sont sensibles à la casse (`http://psi.rechtspraak.nl/rechtsgebied#strafrecht`, encoder `#` en `%23`). Synchro quotidienne avec `modified=<date>` ; les entrées `deleted` doivent être retirées de Firestore.
- Les intitulés de section varient selon le tribunal : le pipeline doit trouver les sections par leur sens.
- Contenus lourds (viol, homicide…) : `case.contentWarnings` alimente le trigger warning et les filtres des réglages.
- Les fausses affaires de `FakeData` sauf « Red Light at 130 » sont **inventées** : leur ECLI et leur lien n'existent pas.
- Le prompt du pipeline n'a **jamais été testé sur un vrai modèle à grande échelle** : l'essayer d'abord sur une dizaine de décisions et vérifier les contrôles automatiques (section « Contrôles automatiques conseillés » du prompt).

## Choix par défaut encore à confirmer

Ces règles ont été posées par défaut pendant la R&D ; chacune est à un seul endroit du code.

1. **Verdict correct** = exactement les mêmes boutons que le tribunal ; les montants des curseurs ne comptent pas (`RulingComparison`).
2. **Rangs** : Law Student (0), Court Clerk (5), Junior Judge (10), Judge (20), Senior Judge (35), Chief Justice (50) (`JudgeRank`).
3. Le succès **« Sharp judgment » (70 % de précision)** ne compte qu'après 10 affaires jugées (`Achievement`).
4. **Règles de sécurité Firestore** : brouillon non testé dans `MODELS.md` (lecture de `verdicts/{id}` seulement si la ruling du joueur est `completed`).
5. Les stats sont calculées côté app (triche possible). Pour un classement ou du multijoueur, déplacer `RulingResult.evaluate` dans une Cloud Function.

## Prochaines étapes

1. ~~**Commiter les modèles**~~ : fait (branche `chore/add-models-package`). Le développeur frontend construit les écrans avec `FakeGameRepository`.
2. Backend : pipeline Rechtspraak → LLM → validation contre `case.schema.json` → écriture Firestore (`cases`, `verdicts`, `countries`).
3. `FirestoreGameRepository` qui implémente `GameRepository` ; les écrans ne changent pas.
4. Règles de sécurité Firestore et index (voir `docs/data-model/README.md`).
