import '../models.dart';

/// Everything the screens need from the backend. The app codes against this
/// interface: [FakeGameRepository] serves fake data today, a Firestore
/// implementation will replace it without touching the screens.
abstract interface class GameRepository {
  /// The signed-in player, or null before "Create account".
  Future<PlayerProfile?> currentPlayer();

  /// "Create account". The password goes to Firebase Auth, not here.
  Future<PlayerProfile> createPlayer({
    required String name,
    required String username,
    required String countryCode,
  });

  /// Country picker; also changes the country the player rules in.
  Future<List<Country>> countries();
  Future<PlayerProfile> setCountry(String countryCode);

  /// Settings and the trigger warning checkbox.
  Future<PlayerProfile> savePreferences(ContentPreferences preferences);

  /// Category chips: categories with at least one published case.
  Future<List<CaseCategory>> categories(String countryCode);

  /// A category column on the home screen, ready to draw.
  Future<List<CaseSlot>> caseColumn(String countryCode, CaseCategory category);

  Future<CourtCase> caseById(String caseId);

  /// Called when the player enters a case, then as they read the argument
  /// cards and pick verdicts (CONTINUE resumes from there).
  Future<PlayerRuling> openCase(CourtCase courtCase);
  Future<PlayerRuling> saveProgress(PlayerRuling ruling);

  /// "Deliver Verdict": saves the ruling, reads the court's verdict, updates
  /// stats and achievements, and returns what the result screen shows.
  Future<RulingResult> deliverVerdict(CourtCase courtCase, PlayerVerdict verdict);

  /// "Revise your previous cases", newest first.
  Future<List<PlayerRuling>> completedRulings({int? limit});

  /// The court's verdict of a case the player already completed ("Preview").
  /// Throws [StateError] if the case is not completed: the app never reads
  /// a verdict before the player has ruled.
  Future<RulingResult> reviseCase(String caseId);
}
