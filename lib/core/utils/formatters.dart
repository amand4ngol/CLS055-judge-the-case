/// Display formats shared by the screens.
abstract final class Formatters {
  /// 36500 -> "36,500 €"
  static String euro(double amount) => '${_thousands(amount.round())} €';

  /// 1 -> "1 month", 49 -> "49 months"
  static String months(double months) {
    final count = months.round();
    return count == 1 ? '1 month' : '$count months';
  }

  static String _thousands(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer(value < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
