# Modèles de données de l'app « Judge the Case »

Tout s'importe avec `import 'package:judge_the_case_models/judge_the_case_models.dart';`. Les modèles sont en Dart pur (aucune dépendance à Firebase) : chacun a un `fromFirestore(id, map)` et un `toMap()`. Les dates acceptent un `Timestamp` Firestore, un `DateTime` ou une chaîne ISO.

## Où vivent les données

| Document Firestore | Écrit par | Modèle | Écrans |
|---|---|---|---|
| `cases/{ECLI}` | pipeline | `CourtCase` | accueil, fiche affaire, trigger warning |
| `verdicts/{ECLI}` | pipeline | `CaseVerdict` | résultat, révision |
| `countries/{code}` | pipeline (compteur `publishedCases`) | `Country` | sélecteur de pays, « 22% done » |
| `users/{uid}` | app | `PlayerProfile` (+ `PlayerStats`, `ContentPreferences`, succès) | profil, réglages, création de compte |
| `users/{uid}/rulings/{ECLI}` | app | `PlayerRuling` (+ `PlayerVerdict`) | CONTINUE, « Revise your previous cases », complétion |

Le mot de passe de « Create account » va dans Firebase Auth, jamais dans `users/{uid}`.

## Réponse du joueur et vraie réponse

Les deux ne sont jamais mélangées :
- **`PlayerVerdict`** : ce que le joueur a choisi (boutons + curseurs Fine et Prison). Il est rangé dans `PlayerRuling.verdict`.
- **`CaseVerdict`** : ce que le tribunal a décidé. Il vient de `verdicts/{ECLI}` et n'est jamais copié chez le joueur.
- **`RulingComparison.compare(joueur, tribunal)`** : boutons corrects (`matched`), oubliés (`missed`) et en trop (`extra`, en rouge sur l'écran), `isCorrect`, et l'écart sur l'amende ou la prison quand les deux en ont mis.

**Règle de correction (choix par défaut)** : un verdict est correct si le joueur a choisi exactement les mêmes boutons que le tribunal. Les montants des curseurs ne comptent pas pour « correct », on les affiche seulement en comparaison. C'est le seul endroit à changer si vous voulez une règle plus souple.

## Complétion d'une affaire

1. Le joueur entre dans l'affaire : `PlayerRuling.start(case)` crée `users/{uid}/rulings/{ECLI}` avec le statut `in_progress`.
2. Pendant la lecture, on sauvegarde avec `withProgress(argumentsRead:, verdict:)`. `progress` (0 à 1) dessine l'anneau du bouton CONTINUE.
3. « Deliver Verdict » : `RulingResult.evaluate(...)` calcule tout d'un coup :
   - la ruling complétée (`isCorrect`, `submittedAt`) ;
   - les nouvelles stats (affaires jugées, précision, série, compteurs par pays et par catégorie) ;
   - les succès débloqués à afficher (écran « You have completed an achievement! ») ;
   - un éventuel changement de rang.
4. Rejouer une affaire déjà complétée ne change rien (mode révision).

La `PlayerRuling` copie le titre, la catégorie, le pays et l'année de l'affaire : la liste « Revise your previous cases » et les compteurs ne demandent donc aucune lecture de plus.

## Écran d'accueil

`CaseSlot.column(cases, rulings, preferences)` renvoie une colonne prête à dessiner :
- les affaires sont triées par `addedAt` et numérotées (« CASE 05 ») ;
- celles que le joueur a filtrées dans ses réglages sont retirées ;
- chaque affaire a un état : `completed` (marque-page doré), `inProgress` (CONTINUE), `next` (NEXT CASE · ENTER) ou `locked` (cadenas).

## Profil

| Élément du design | Code |
|---|---|
| « Judge Isabella » | `profile.displayName` |
| « Law Student », barre 0/5, « 5 more cases… » | `profile.rankProgress` (`JudgeRank`, `counterLabel`, `message`, `fraction`) |
| Cases / Accuracy / Best streak | `stats.casesJudged`, `stats.accuracyLabel`, `stats.bestStreakLabel` (« – » avant la première affaire) |
| Achievements 0/8 | `Achievement.values`, `profile.hasUnlocked(a)`, `profile.achievementsLabel` |

**Rangs (choix par défaut, à ajuster)** : Law Student (0), Court Clerk (5), Junior Judge (10), Judge (20), Senior Judge (35), Chief Justice (50).

**Succès** : les 8 du design. Les « Review N cases » comptent les affaires jugées. « Sharp judgment » (70 %) ne se débloque qu'à partir de 10 affaires, pour qu'un seul bon verdict ne suffise pas.

## Réglages et trigger warning

`ContentPreferences` contient deux choses :
- `filteredTopics` : les sujets cochés dans les réglages ;
- `hideSensitiveCases` : la case « Do not show me sensitive cases again ».

`allows(case)` dit si l'affaire apparaît, et `needsWarning(case)` s'il faut afficher le trigger warning avant.

## Fausses données (`lib/data/`)

- `GameRepository` : l'interface que les écrans utilisent (profil, pays, colonnes, ouverture d'une affaire, verdict, révision).
- `FakeGameRepository` : la version en mémoire, avec un petit délai simulé. Elle passe par les mêmes `fromFirestore` / `toMap` et les mêmes règles que la future version Firestore.
  - `FakeGameRepository(player: FakeData.newPlayer)` donne un joueur neuf.
  - `await FakeGameRepository.withHistory()` donne un joueur avec 2 affaires jugées (une juste, une fausse) et une en cours.
- `FakeData` : 9 affaires néerlandaises dans 6 catégories, avec leurs verdicts, et 3 pays (Pays-Bas, Oman, Portugal). « Red Light at 130 » est une vraie décision. Les autres sont inventées : leur ECLI et leur lien n'existent pas.

Pour passer au vrai backend, il suffira d'écrire un `FirestoreGameRepository` qui implémente la même interface.

## Règles de sécurité Firestore (brouillon, non testé)

```
match /cases/{id}    { allow read: if request.auth != null; }
match /countries/{c} { allow read: if request.auth != null; }
match /verdicts/{id} {
  allow read: if request.auth != null
    && get(/databases/$(database)/documents/users/$(request.auth.uid)/rulings/$(id)).data.status == 'completed';
}
match /users/{uid} {
  allow read, write: if request.auth.uid == uid;
  match /rulings/{id} { allow read, write: if request.auth.uid == uid; }
}
```

Limite : c'est l'app qui calcule `isCorrect` et les stats, donc un joueur qui modifie l'app pourrait tricher sur son propre score. Pour un jeu solo, c'est acceptable. Pour un classement ou du multijoueur, il faudra déplacer `RulingResult.evaluate` dans une Cloud Function : le code est pur Dart et les règles du jeu sont au même endroit, donc ce sera simple à faire.
