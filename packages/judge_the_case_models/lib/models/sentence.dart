import 'firestore_parsing.dart';

/// Amounts behind the adjustable verdicts. A value is null when the court did
/// not impose that penalty.
class Sentence {
  const Sentence({
    this.prisonMonths,
    this.prisonSuspendedMonths,
    this.fineEur,
    this.communityServiceHours,
    this.probationMonths,
  });

  /// Total custodial sentence, suspended part included.
  final double? prisonMonths;
  final double? prisonSuspendedMonths;
  final double? fineEur;
  final int? communityServiceHours;

  /// Probation period (proeftijd).
  final int? probationMonths;

  /// Months actually to be served.
  double? get prisonToServeMonths =>
      prisonMonths == null ? null : prisonMonths! - (prisonSuspendedMonths ?? 0);

  factory Sentence.fromMap(Map<String, dynamic> map) => Sentence(
        prisonMonths: parseDouble(map['prisonMonths']),
        prisonSuspendedMonths: parseDouble(map['prisonSuspendedMonths']),
        fineEur: parseDouble(map['fineEur']),
        communityServiceHours: parseInt(map['communityServiceHours']),
        probationMonths: parseInt(map['probationMonths']),
      );

  Map<String, dynamic> toMap() => {
        'prisonMonths': prisonMonths,
        'prisonSuspendedMonths': prisonSuspendedMonths,
        'fineEur': fineEur,
        'communityServiceHours': communityServiceHours,
        'probationMonths': probationMonths,
      };
}
