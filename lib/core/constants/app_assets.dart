abstract final class AppAssets {
  // Images
  static const pillar = 'assets/images/pillar.svg';
  static const profile = 'assets/icons/profile.svg';

  // Icons
  static const caseIcon = 'assets/icons/case_icon.svg';
  static const check = 'assets/icons/check.svg';
  static const lock = 'assets/icons/lock.svg';

  // Country picker
  static const search = 'assets/icons/search.svg';
  static const chevronUp = 'assets/icons/chevron_up.svg';

  // Result screen header
  static const resultHome = 'assets/icons/result_home.svg';

  /// Pillar button at the top of the case screen (back to home).
  static const caseHome = 'assets/icons/case_home.svg';

  /// Scales on the first argument card.
  static const scales = 'assets/icons/scales.svg';

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
