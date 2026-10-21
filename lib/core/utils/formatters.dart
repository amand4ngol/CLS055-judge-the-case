/// Display formats shared by the screens.
abstract final class Formatters {
  /// 36500 -> "36,500 €"
  static String euro(double amount) => '${_thousands(amount.round())} €';

  /// 1 -> "1 month", 49 -> "49 months"
  static String months(double months) {
    final count = months.round();
    return count == 1 ? '1 month' : '$count months';
  }

  /// 2026-10-21 -> "21 Oct 2026"
  static String date(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final local = date.toLocal();
    return '${local.day} ${months[local.month - 1]} ${local.year}';
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
