import 'enums.dart';
import 'firestore_parsing.dart';

/// What the player chose on "Decide The Verdict": one or more buttons, plus
/// the slider values for Fine and Prison. Immutable; the toggle and setters
/// return a new value, so it can sit directly in widget state.
class PlayerVerdict {
  const PlayerVerdict({this.options = const {}, this.fineEur, this.prisonMonths});

  static const empty = PlayerVerdict();

  /// Slider bounds, in the same units as the court's [Sentence].
  static const fineMinEur = 100.0;
  static const fineMaxEur = 10000000.0;
  static const prisonMinMonths = 1.0;
  static const prisonMaxMonths = 240.0;

  final Set<VerdictOption> options;

  /// Set only while [VerdictOption.fine] is selected.
  final double? fineEur;

  /// Set only while [VerdictOption.prison] is selected.
  final double? prisonMonths;

  bool isSelected(VerdictOption option) => options.contains(option);

  /// "Deliver Verdict" is enabled once at least one button is selected and
  /// each selected slider has a value.
  bool get isComplete =>
      options.isNotEmpty &&
      (!isSelected(VerdictOption.fine) || fineEur != null) &&
      (!isSelected(VerdictOption.prison) || prisonMonths != null);

  /// Selects or unselects [option]. Acquitted and Case Dismissed exclude every
  /// other button, so picking one of them clears the rest, and picking a
  /// penalty clears them.
  PlayerVerdict toggle(VerdictOption option) {
    if (isSelected(option)) {
      return PlayerVerdict(
        options: {...options}..remove(option),
        fineEur: option == VerdictOption.fine ? null : fineEur,
        prisonMonths: option == VerdictOption.prison ? null : prisonMonths,
      );
    }
    if (option.isExclusive) return PlayerVerdict(options: {option});
    final kept = options.where((o) => !o.isExclusive).toSet()..add(option);
    return PlayerVerdict(
      options: kept,
      fineEur: option == VerdictOption.fine ? fineMinEur : fineEur,
      prisonMonths: option == VerdictOption.prison ? prisonMinMonths : prisonMonths,
    );
  }

  PlayerVerdict withFine(double eur) => PlayerVerdict(
        options: {...options.where((o) => !o.isExclusive), VerdictOption.fine},
        fineEur: eur.clamp(fineMinEur, fineMaxEur).toDouble(),
        prisonMonths: prisonMonths,
      );

  PlayerVerdict withPrison(double months) => PlayerVerdict(
        options: {...options.where((o) => !o.isExclusive), VerdictOption.prison},
        fineEur: fineEur,
        prisonMonths: months.clamp(prisonMinMonths, prisonMaxMonths).toDouble(),
      );

  /// Buttons in design order, for "You ruled".
  List<VerdictOption> get sortedOptions =>
      VerdictOption.values.where(options.contains).toList();

  factory PlayerVerdict.fromMap(Map<String, dynamic> map) => PlayerVerdict(
        options: parseStringList(map['options'])
            .map(VerdictOption.fromValue)
            .whereType<VerdictOption>()
            .toSet(),
        fineEur: parseDouble(map['fineEur']),
        prisonMonths: parseDouble(map['prisonMonths']),
      );

  Map<String, dynamic> toMap() => {
        'options': sortedOptions.map((o) => o.value).toList(),
        'fineEur': fineEur,
        'prisonMonths': prisonMonths,
      };

  @override
  bool operator ==(Object other) =>
      other is PlayerVerdict &&
      other.fineEur == fineEur &&
      other.prisonMonths == prisonMonths &&
      other.options.length == options.length &&
      other.options.containsAll(options);

  @override
  int get hashCode => Object.hash(Object.hashAllUnordered(options), fineEur, prisonMonths);
}
