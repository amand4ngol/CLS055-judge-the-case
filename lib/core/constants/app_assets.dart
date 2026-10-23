abstract final class AppAssets {
  // Images
  static const pillar = 'assets/images/pillar.svg';

  /// Judge's bench with a gavel on it.
  static const judgeBench = 'assets/images/judge_bench.svg';
  static const profile = 'assets/icons/profile.svg';

  // Icons
  /// Completed case medallion.
  static const bookmark = 'assets/icons/bookmark.svg';
  static const lock = 'assets/icons/lock.svg';

  /// splash screen logo.
  static const courthouse = 'assets/icons/courthouse.svg';

  // Country picker
  static const search = 'assets/icons/search.svg';
  static const chevronUp = 'assets/icons/chevron_up.svg';

  /// Closed country dropdown on "Create account".
  static const chevronDown = 'assets/icons/chevron_down.svg';

  // Result screen header
  static const resultHome = 'assets/icons/result_home.svg';

  /// Pillar button at the top of the case screen (back to home).
  static const caseHome = 'assets/icons/case_home.svg';

  /// Scales on the first argument card.
  static const scales = 'assets/icons/scales.svg';

  // Profile screen
  static const profileScales = 'assets/icons/profile_scales.svg';
  static const settings = 'assets/icons/settings.svg';
  static const arrowDropDown = 'assets/icons/arrow_drop_down.svg';

  // Settings screen
  static const chevronDownDark = 'assets/icons/chevron_down_dark.svg';
  static const edit = 'assets/icons/edit.svg';

  // Verdict buttons
  static const verdictFine = 'assets/icons/verdict_fine.svg';
  static const verdictPrison = 'assets/icons/verdict_prison.svg';
  static const verdictCommunityService =
      'assets/icons/verdict_community_service.svg';
  static const verdictProbation = 'assets/icons/verdict_probation.svg';
  static const verdictAcquitted = 'assets/icons/verdict_acquitted.svg';

  /// Flag of a country by ISO code, e.g. `NL` -> assets/icons/flag_nl.svg.
  static String flag(String countryCode) =>
      'assets/icons/flag_${countryCode.toLowerCase()}.svg';
}
