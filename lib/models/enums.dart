/// Enums shared by the case models. Each value carries the string stored in
/// Firestore (`value`) and the label shown in the app (`label`).
library;

/// Player-facing crime category (home screen chips).
enum CaseCategory {
  homicide('homicide', 'Homicide'),
  violence('violence', 'Violence'),
  sexualOffences('sexual_offences', 'Sexual Offences'),
  theft('theft', 'Theft & Burglary'),
  fraud('fraud', 'Fraud'),
  financial('financial', 'Financial'),
  drugs('drugs', 'Drugs'),
  traffic('traffic', 'Traffic'),
  weapons('weapons', 'Weapons'),
  cybercrime('cybercrime', 'Cybercrime'),
  environmental('environmental', 'Environmental'),
  publicOrder('public_order', 'Vandalism & Public Order'),
  other('other', 'Other');

  const CaseCategory(this.value, this.label);
  final String value;
  final String label;

  static CaseCategory fromValue(String? value) =>
      values.firstWhere((e) => e.value == value, orElse: () => other);
}

/// Badge on the case screen (CRIMINAL).
enum LegalArea {
  criminal('criminal', 'Criminal');

  const LegalArea(this.value, this.label);
  final String value;
  final String label;

  static LegalArea fromValue(String? value) =>
      values.firstWhere((e) => e.value == value, orElse: () => criminal);
}

/// Verdict buttons. The player may select several; the court's decision is
/// stored as a set of the same values.
enum VerdictOption {
  fine('fine', 'Fine', 'Monetary penalty'),
  prison('prison', 'Prison', 'Custodial sentence'),
  communityService('community_service', 'Community Service', 'Unpaid community work'),
  probation('probation', 'Probation', 'Supervised release'),
  acquitted('acquitted', 'Acquitted', 'No conviction'),
  caseDismissed('case_dismissed', 'Case Dismissed', 'No penalty imposed');

  const VerdictOption(this.value, this.label, this.description);
  final String value;
  final String label;
  final String description;

  /// Fine and prison have a slider in the design.
  bool get isAdjustable => this == fine || this == prison;

  /// Acquitted and case dismissed cannot be combined with a penalty.
  bool get isExclusive => this == acquitted || this == caseDismissed;

  static VerdictOption? fromValue(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

/// Sensitive topics behind the trigger warning and the settings filter.
enum ContentWarning {
  violence('violence', 'Violence'),
  sexualViolence('sexual_violence', 'Sexual violence'),
  death('death', 'Death'),
  minors('minors', 'Minors involved'),
  drugs('drugs', 'Drugs'),
  selfHarm('self_harm', 'Self-harm'),
  animalCruelty('animal_cruelty', 'Animal cruelty');

  const ContentWarning(this.value, this.label);
  final String value;
  final String label;

  static ContentWarning? fromValue(String? value) {
    for (final e in values) {
      if (e.value == value) return e;
    }
    return null;
  }
}

/// Who an argument card speaks for.
enum ArgumentSide {
  prosecution('prosecution', 'Prosecution'),
  defence('defence', 'Defence'),
  context('context', 'Context');

  const ArgumentSide(this.value, this.label);
  final String value;
  final String label;

  static ArgumentSide fromValue(String? value) =>
      values.firstWhere((e) => e.value == value, orElse: () => context);
}

/// Penalties and measures with no verdict button.
enum MeasureType {
  drivingBan('driving_ban', 'Driving ban'),
  compensation('compensation', 'Compensation to the victim'),
  confiscation('confiscation', 'Confiscation'),
  tbs('tbs', 'Hospital order (TBS)'),
  juvenileTreatmentOrder('juvenile_treatment_order', 'Juvenile treatment order'),
  repeatOffenderOrder('repeat_offender_order', 'Repeat offender order'),
  behaviouralOrder('behavioural_order', 'Contact or area ban'),
  lossOfRights('loss_of_rights', 'Loss of rights'),
  publication('publication', 'Publication of the judgment'),
  other('other', 'Other measure');

  const MeasureType(this.value, this.label);
  final String value;
  final String label;

  static MeasureType fromValue(String? value) =>
      values.firstWhere((e) => e.value == value, orElse: () => other);
}

/// Publication state set by the pipeline. The app only queries `published`.
enum CaseStatus {
  draft('draft'),
  published('published'),
  rejected('rejected');

  const CaseStatus(this.value);
  final String value;

  static CaseStatus fromValue(String? value) =>
      values.firstWhere((e) => e.value == value, orElse: () => draft);
}

/// State of a player's ruling document (`users/{uid}/rulings/{caseId}`).
enum RulingStatus {
  /// Case opened, verdict not delivered yet (CONTINUE on the home screen).
  inProgress('in_progress'),

  /// Verdict delivered; the court's answer may be read.
  completed('completed');

  const RulingStatus(this.value);
  final String value;

  static RulingStatus fromValue(String? value) =>
      values.firstWhere((e) => e.value == value, orElse: () => inProgress);
}
