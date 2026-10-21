/// Why an account action failed, independent of Firebase.
enum AccountError { usernameTaken, invalidUsername, weakPassword, wrongCredentials, network }

class AccountException implements Exception {
  const AccountException(this.error);

  final AccountError error;

  @override
  String toString() => 'AccountException(${error.name})';
}

/// Players sign in with a username and a password, as on "Create account".
/// Firebase Auth needs an email, so each username maps to an internal address no one reads.
abstract final class Usernames {
  static final _valid = RegExp(r'^[a-z0-9._-]{3,20}$');

  static const minPasswordLength = 6;

  /// Usernames are stored in lower case, without surrounding spaces.
  static String normalize(String username) => username.trim().toLowerCase();

  /// 3 to 20 characters among a-z, 0-9, ".", "_" and "-".
  static bool isValid(String username) => _valid.hasMatch(normalize(username));

  static String email(String username) => '${normalize(username)}@users.judge-the-case.app';

  /// Throws [AccountException] for an invalid username or a password that is too short.
  static void check(String username, String password) {
    if (!isValid(username)) throw const AccountException(AccountError.invalidUsername);
    if (password.length < minPasswordLength) throw const AccountException(AccountError.weakPassword);
  }
}
