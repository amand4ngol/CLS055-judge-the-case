import '../models.dart';

export 'account.dart';

/// Everything the screens need from the backend. The app codes against this
/// interface: [FakeGameRepository] serves fake data, [FirestoreGameRepository]
/// the real database, and the screens work the same with both.
abstract interface class GameRepository {
  /// The signed-in player, or null when no one is signed in.
  Future<PlayerProfile?> currentPlayer();

  /// "Create account", then signs the player in. Throws [AccountException]
  /// for a taken or invalid username ([Usernames]) or a weak password.
  Future<PlayerProfile> createPlayer({
    required String name,
    required String username,
    required String password,
    required String countryCode,
  });

  /// Signs in with the username and password chosen on "Create account".
  /// Throws [AccountException] ([AccountError.wrongCredentials] when they do not match).
  Future<PlayerProfile> signIn({required String username, required String password});

  Future<void> signOut();

  /// "Delete account": deletes the player's rulings, profile and account, then signs out.
  /// The password is asked again; a wrong one throws [AccountException] ([AccountError.wrongCredentials]).
  Future<void> deleteAccount({required String password});

  /// Country picker: also changes the country the player rules in.
  Future<List<Country>> countries();
  Future<PlayerProfile> setCountry(String countryCode);

  /// Settings and the trigger warning checkbox.
  Future<PlayerProfile> savePreferences(ContentPreferences preferences);

  /// "Edit information": changes the name and/or the username, then the player logs in with the new
  /// username. Throws [AccountException] for a taken or invalid username, as on "Create account".
  Future<PlayerProfile> updateProfile({String? name, String? username});

  /// Category chips: categories with at least one published case.
  Future<List<CaseCategory>> categories(String countryCode);

  /// A category column on the home screen, ready to draw.
  Future<List<CaseSlot>> caseColumn(String countryCode, CaseCategory category);

  Future<CourtCase> caseById(String caseId);

  /// Called when the player enters a case, then as they read the argument
  /// cards and pick verdicts (CONTINUE resumes from there).
  ///
  /// Case X+1 of a category stays locked until case X is completed: like
  /// [deliverVerdict], these throw [StateError] for a case that is not
  /// playable in its column ([CaseSlot.isPlayable]).
  Future<PlayerRuling> openCase(CourtCase courtCase);
  Future<PlayerRuling> saveProgress(PlayerRuling ruling);

  /// "Deliver Verdict": saves the ruling, reads the court's verdict, updates
  /// stats and achievements, and returns what the result screen shows.
  /// Throws [StateError] if the case is locked.
  Future<RulingResult> deliverVerdict(CourtCase courtCase, PlayerVerdict verdict);

  /// "Revise your previous cases", newest first.
  Future<List<PlayerRuling>> completedRulings({int? limit});

  /// The court's verdict of a case the player already completed ("Preview").
  /// Throws [StateError] if the case is not completed: the app never reads
  /// a verdict before the player has ruled.
  Future<RulingResult> reviseCase(String caseId);
}
