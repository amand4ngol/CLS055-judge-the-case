import '../../data/game_repository.dart';

abstract final class AccountValidators {
  static const maxNameLength = 30;

  static String? name(String? value) {
    final name = value?.trim() ?? '';
    if (name.isEmpty) return 'Enter your name.';
    if (name.length > maxNameLength) {
      return 'Use at most $maxNameLength characters.';
    }
    return null;
  }

  static String? newUsername(String? value) {
    final username = value?.trim() ?? '';
    if (username.isEmpty) return 'Choose a username.';
    if (username.length < 3 || username.length > 20) {
      return 'Use 3 to 20 characters.';
    }
    if (!Usernames.isValid(username)) {
      return 'Only letters, numbers, ".", "_" and "-".';
    }
    return null;
  }

  static String? newPassword(String? value) {
    final password = value ?? '';
    if (password.isEmpty) return 'Choose a password.';
    if (password.length < Usernames.minPasswordLength) {
      return 'Use at least ${Usernames.minPasswordLength} characters.';
    }
    return null;
  }

  /// On "Log in" only emptiness is checked: a wrong value gets "Wrong
  /// username or password." from the server.
  static String? username(String? value) =>
      (value?.trim() ?? '').isEmpty ? 'Enter your username.' : null;

  static String? password(String? value) =>
      (value ?? '').isEmpty ? 'Enter your password.' : null;
}
