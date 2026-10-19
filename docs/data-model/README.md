# Modèle de données « Judge the Case » (schéma v2)

Le pipeline IA lit une décision Rechtspraak (XML) et produit un JSON validé contre `case.schema.json`. Le code du pipeline l'écrit ensuite dans Firestore en **deux documents** portant le même identifiant (l'ECLI) :

| Collection | Contenu | Quand l'app le lit |
|---|---|---|
| `cases/{ECLI}` | Bloc `case` (+ bloc `pipeline`, ignoré par l'app) | Accueil, fiche affaire, avant le verdict |
| `verdicts/{ECLI}` | Bloc `verdict` | Écran résultat, révision des affaires passées |

**Pourquoi deux documents** : Firestore envoie le document entier au téléphone. En séparant la réponse, une règle de sécurité peut n'autoriser la lecture de `verdicts/{id}` qu'après l'envoi du verdict du joueur (par exemple si `users/{uid}/rulings/{id}` existe). Tant que cette règle n'est pas écrite, le découpage ne coûte rien et ne bloque rien.

## Fichiers
- `case.schema.json` : schéma JSON (draft 2020-12), à donner au modèle IA comme format de sortie puis à utiliser pour valider.
- `prompt-rechtspraak-to-case.md` : prompt du pipeline, champs remplis par le code et contrôles automatiques.
- `example-case.json` : exemple rempli à partir d'une vraie décision (ECLI:NL:RBNHO:2026:13327). Il passe la validation.
- Les modèles Dart de l'app (affaires et données joueur), avec des fausses données, sont dans le package `packages/judge_the_case_models/` (`lib/models/`, `lib/data/`). Mode d'emploi : `packages/judge_the_case_models/MODELS.md`.

## Correspondance avec le design

| Élément du design | Champ |
|---|---|
| Drapeau, choix du pays, « 22% done » | `case.country`, `case.countryName`, et `countries/{code}.publishedCases` comparé aux affaires complétées par le joueur |
| Chips de catégorie (Homicide, Fraud, Financial…) | `case.category` |
| Ordre des affaires dans une colonne (Case 04 verrouillée…) | `case.addedAt` |
| Badge CRIMINAL | `case.legalArea` |
| Titre, « United States · 2023 » | `case.title`, `case.countryName`, `case.year` |
| Charges filed | `case.charges` |
| Case summary Short / Long | `case.summaryShort`, `case.summaryLong` |
| Arguments 0/6 (cartes à faire défiler) | `case.arguments` (4 à 6 cartes) |
| Trigger warning, filtre des sujets dans les réglages | `case.contentWarnings` |
| Boutons de verdict (choix multiple) | `verdict.courtRuled` |
| Curseurs Fine et Prison | `verdict.sentence.fineEur`, `verdict.sentence.prisonMonths` |
| Court ruled / Actual sentence | `verdict.courtRuled`, `verdict.actualSentence` |
| Why the court decided this | `verdict.courtReasoning` |
| « Get to the detailed case here » | `case.sourceUrl` (lien officiel permanent `https://deeplink.rechtspraak.nl/uitspraak?id=<ECLI>`) |

Les profils, statistiques, séries et succès sont des données joueur : ils ne viennent pas du pipeline et ne sont pas dans ce schéma. L'app les écrit dans `users/{uid}` et `users/{uid}/rulings/{ECLI}` (voir `packages/judge_the_case_models/MODELS.md`).

Quand le pipeline publie une affaire, il incrémente aussi `countries/{code}.publishedCases` (et crée le document avec `name` s'il n'existe pas) : le sélecteur de pays et le pourcentage « 22% done » s'en servent.

## Ce qui a été retiré par rapport à la v1
`source` (données brutes néerlandaises, résumé officiel qui contient la réponse, numéros d'affaire, liens entre instances), `display.location`, `offenceDate`, `defendant`, `victims`, `prosecutorDemand`, `defenceArguments` (fusionnés dans `arguments`), `keyFactors` (remplacés par `arguments`), `verdict.chargeOutcomes`, `guidelineNote`, `appeal`, `scoring`, `difficulty`, `random`. Aucun de ces champs n'apparaît dans le design final.

## Catégories

Elles s'appuient sur la classification officielle des infractions du CBS (Standaardclassificatie Misdrijven 2010), regroupée en catégories lisibles par un joueur. Le pipeline classe chaque affaire selon l'infraction principale.

| Valeur | Libellé app | Infractions néerlandaises |
|---|---|---|
| `homicide` | Homicide | moord, doodslag, tentatives, dood door schuld (hors circulation) |
| `violence` | Violence | mishandeling, bedreiging, belaging, vrijheidsberoving, mensenhandel |
| `sexual_offences` | Sexual Offences | verkrachting, aanranding, kinderpornografie |
| `theft` | Theft & Burglary | diefstal, inbraak, heling, afpersing |
| `fraud` | Fraud | oplichting, valsheid in geschrift, fraude aux aides sociales |
| `financial` | Financial | witwassen, fraude fiscale, verduistering, omkoping, délit d'initié, bankbreuk |
| `drugs` | Drugs | Opiumwet, plantations de cannabis, trafic |
| `traffic` | Traffic | Wegenverkeerswet : alcool au volant, accident mortel ou avec blessés |
| `weapons` | Weapons | Wet wapens en munitie, explosifs |
| `cybercrime` | Cybercrime | computervredebreuk, ransomware, DDoS |
| `environmental` | Environmental | pollution, déchets, nature, bien-être animal, WED environnement |
| `public_order` | Vandalism & Public Order | vernieling, brandstichting, émeutes, wederspannigheid |
| `other` | Other | le reste |

## Types de peine

Base : article 9 du Code pénal néerlandais (peines principales et accessoires), titre IIA (mesures), articles 9a et 14a (absence de peine, sursis).

| Ce que dit la décision | Bouton du design | Où c'est stocké |
|---|---|---|
| gevangenisstraf, hechtenis, jeugddetentie (prison, détention courte, détention des mineurs) | Prison | `sentence.prisonMonths`, `prisonSuspendedMonths` |
| partie « voorwaardelijk » avec « proeftijd » (sursis avec mise à l'épreuve) | Probation | `sentence.probationMonths` |
| taakstraf / werkstraf (travail d'intérêt général) | Community Service | `sentence.communityServiceHours` |
| geldboete (amende) | Fine | `sentence.fineEur` |
| vrijspraak sur toutes les charges | Acquitted | aucun montant |
| ontslag van alle rechtsvervolging, OM niet-ontvankelijk, art. 9a (pas de peine) | Case Dismissed | aucun montant |
| retrait de permis, indemnisation de la victime, confiscation, TBS, PIJ, ISD, interdiction de contact ou de zone, déchéance de droits, publication | aucun bouton | `verdict.otherMeasures`, et texte de `actualSentence` |

Une décision combine souvent plusieurs boutons (14 des 15 décisions pénales étudiées en R&D) : par exemple 8 mois de prison dont 4 avec sursis donnent `["prison", "probation"]`.

## Règles de conversion
- Dates : chaînes ISO dans le JSON, à convertir en `Timestamp` Firestore à l'écriture (`decisionDate`, `addedAt`, `extractedAt`, `sourceModifiedAt`).
- `prisonMonths` = peine totale prononcée, sursis compris. Les jours sont divisés par 30, les années multipliées par 12.

## Index Firestore conseillés
- `cases` : `status` + `country` + `category` + `addedAt`, pour la colonne d'affaires d'une catégorie.
- `cases` : `pipeline.sourceModifiedAt`, pour la synchronisation incrémentale.
