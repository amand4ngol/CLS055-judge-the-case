import 'package:flutter/foundation.dart';

import '../data/game_repository.dart';
import '../models.dart';

/// State of "Create account" and "Log in": the countries of the dropdown,
/// the request in flight and the error shown under the fields.
class AccountProvider extends ChangeNotifier {
  AccountProvider(this._repository);

  /// New players rule in the Netherlands unless they pick another country.
  static const defaultCountry = Country(
    code: 'NL',
    name: 'Netherlands',
    publishedCases: 0,
  );

  final GameRepository _repository;

  List<Country> _countries = const [defaultCountry];
  Country _country = defaultCountry;
  bool _hasChosenCountry = false;
  bool _isSubmitting = false;
  String? _error;
  bool _disposed = false;

  List<Country> get countries => _countries;

  /// The country the new player will rule in.
  Country get country => _country;

  /// False until the player picks a country in the dropdown, so it can say
  /// "Choose country to rule in" over the default flag.
  bool get hasChosenCountry => _hasChosenCountry;

  bool get isSubmitting => _isSubmitting;

  /// Why the last attempt failed, ready to show.
  String? get error => _error;

  /// Countries for the dropdown on "Create account".
  Future<void> loadCountries() async {
    try {
      final countries = await _repository.countries();
      if (countries.isEmpty) return;
      _countries = countries;
      _country =
          countries.where((c) => c.code == _country.code).firstOrNull ??
          countries.first;
      _notify();
    } catch (e) {
      // The Firestore rules only let signed-in players read the countries,
      // and no one is signed in yet: keep the default country.
      debugPrint('Could not load the countries: $e');
    }
  }

  void selectCountry(Country country) {
    _country = country;
    _hasChosenCountry = true;
    _notify();
  }

  /// Called when the player edits a field, so an old error goes away.
  void clearError() {
    if (_error == null) return;
    _error = null;
    _notify();
  }

  /// "Create account". True once the new player is signed in.
  Future<bool> createAccount({
    required String name,
    required String username,
    required String password,
  }) {
    return _submit(
      () => _repository.createPlayer(
        name: name,
        username: username,
        password: password,
        countryCode: _country.code,
      ),
    );
  }

  /// "Log in". True once the player is signed in.
  Future<bool> signIn({required String username, required String password}) =>
      _submit(() => _repository.signIn(username: username, password: password));

  Future<void> signOut() => _repository.signOut();

  Future<bool> _submit(Future<void> Function() action) async {
    if (_isSubmitting) return false;
    _isSubmitting = true;
    _error = null;
    _notify();
    try {
      await action();
      return true;
    } on AccountException catch (e) {
      _error = messageFor(e.error);
      return false;
    } catch (e) {
      debugPrint('Account request failed: $e');
      _error = 'Something went wrong. Please try again.';
      return false;
    } finally {
      _isSubmitting = false;
      _notify();
    }
  }

  static String messageFor(AccountError error) => switch (error) {
    AccountError.usernameTaken => 'This username is already taken.',
    AccountError.invalidUsername =>
      'Use 3 to 20 characters for your username: letters, numbers, '
          '".", "_" or "-".',
    AccountError.weakPassword =>
      'Your password needs at least ${Usernames.minPasswordLength} '
          'characters.',
    AccountError.wrongCredentials => 'Wrong username or password.',
    AccountError.network => 'No connection. Check your internet and try again.',
  };

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
