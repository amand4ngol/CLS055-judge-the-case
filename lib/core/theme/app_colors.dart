import 'package:flutter/painting.dart';

abstract final class AppColors {
  /// Main blue: primary actions ("NEXT CASE").
  static const blue = Color(0xFF2E4578);

  /// Page background.
  static const beige = Color(0xFFF5F0E8);

  /// Darker background (sections, cards).
  static const beigeDark = Color(0xFFCDC6B7);

  /// Darker brown: secondary actions, selected chip, small caps labels.
  static const brown = Color(0xFF706859);

  /// Headlines and strong text.
  static const textDark = Color(0xFF1E140A);

  /// Body text.
  static const text = Color(0xFF4C473D);

  static const white = Color(0xFFFFFFFF);

  /// Accent gold, for special use
  static const accentGold = Color(0xFFFCE449);

  // Neutrals

  /// Thin divider lines.
  static const hairline = Color.fromRGBO(49, 46, 37, 0.12);

  /// Muted text, e.g. "Swipe to explore cases".
  static const textMuted = Color(0xFF6F695E);

  /// Round profile button in the header.
  static const profileButton = Color(0xFF333B32);

  static const cream = Color(0xFFEEE9DF);

  /// Splash screen. Also set as the native launch background in
  /// android/app/src/main/res/values/colors.xml and
  /// ios/Runner/Base.lproj/LaunchScreen.storyboard; keep them in sync.
  static const splashBackground = Color(0xFFDFDACD);

  // Home: cases section

  static const sectionGradientTop = Color.fromRGBO(220, 214, 201, 0.78);
  static const sectionGradientBottom = Color.fromRGBO(205, 198, 183, 0.94);

  static const chipIdleBackground = Color(0xFFFFFFFF);

  static const titleCardBackground = Color.fromRGBO(247, 244, 237, 0.95);
  static const titleCardTitle = Color(0xFF181814);
  static const titleCardSubtitle = Color(0xFF777267);

  // Home: medallions (round button on each case column)

  static const medallionGold = Color(0xFFDFBD4F);
  static const medallionGoldRing = Color(0xFFFFF8DF);
  static const medallionGoldLabel = Color(0xFF98751D);
  static const medallionCompletedText = Color(0xFF2C281D);
  static const medallionCheckBadge = Color(0xFF28332A);
  static const medallionEnterBorder = Color(0xFFEBE5D9);

  static const medallionLocked = Color.fromRGBO(226, 221, 211, 0.72);
  static const medallionLockedRing = Color.fromRGBO(231, 226, 216, 0.72);
  static const medallionLockedText = Color(0xFF706D65);

  // Home: country picker

  static const countryPickerBar = Color(0xFF7B7365);
  static const countryPickerRow = Color(0xFFFFFFFF);
  static const countryPickerRowSelected = Color(0xFFE1DFDC);
  static const countryPickerName = Color(0xFF1D1B20);
  static const countryPickerProgress = Color(0xFF49454F);
  static const countryPickerProgressSelected = Color(0xFF4A4459);

  // Account screens ("Create account", "Log in"), on [splashBackground]

  /// Outline of the text fields.
  static const fieldOutline = Color(0xFF79747E);

  /// Label in the outline of a text field ("Name").
  static const fieldLabel = Color(0xFF49454F);

  /// Open country list under the dropdown.
  static const countryListBackground = Color.fromRGBO(255, 255, 255, 0.5);
  static const countryListDivider = Color(0xFFCAC4D0);

  // Profile screen

  /// Round badge with the scales on the welcome card.
  static const profileBadge = Color(0xFF314D91);
  static const profileCircle = Color.fromRGBO(255, 255, 255, 0.1);
  static const profileCounter = Color(0xFF5167A7);
  static const profileBarTrack = Color.fromRGBO(255, 255, 255, 0.2);
  static const profileBarFill = Color(0xFF5D9B75);

  /// The three statistics tiles, darkest first.
  static const statCases = Color(0xFF304B85);
  static const statAccuracy = Color(0xFF6579A6);
  static const statStreak = Color(0xFF929FBC);

  /// Dot in front of each previous case.
  static const previousCaseDot = Color(0xFFA9A18F);

  static const achievementCard = Color(0xFF929FBC);
  static const achievementCardBorder = Color(0xFF8F9CB8);
  static const achievementBadgeBorder = Color.fromRGBO(30, 20, 10, 0.1);

  /// "0/8 unlocked".
  static const achievementCount = Color(0xFF7C4F2A);

  // Settings screen

  /// "Preferences save automatically" note.
  static const settingsNote = Color.fromRGBO(45, 106, 70, 0.1);
  static const settingsNoteBorder = Color.fromRGBO(45, 106, 70, 0.2);

  // Case screen

  /// Secondary text: origin line, small labels, hints.
  static const textSubtle = Color(0xFF7A6450);

  /// Dividers between the case sections.
  static const caseDivider = Color.fromRGBO(30, 20, 10, 0.08);
  static const caseRulingDivider = Color(0xFFE4DED6);

  /// Thin outline of buttons and toggles.
  static const caseOutline = Color.fromRGBO(30, 20, 10, 0.15);

  static const badgeRedBackground = Color.fromRGBO(251, 44, 54, 0.08);
  static const badgeRedBorder = Color.fromRGBO(251, 44, 54, 0.4);
  static const badgeRedText = Color(0xFFFF6467);

  /// "Charges filed" panel.
  static const casePanel = Color(0xFFE3DCCF);
  static const casePanelBorder = Color.fromRGBO(76, 71, 61, 0.12);

  /// Selected half of the Short / Long summary toggle.
  static const caseToggleSelected = Color(0xFF263027);

  /// Argument progress segments not read yet.
  static const caseProgressInactive = Color(0xFFD6CCBC);

  /// Argument cards.
  static const argumentCard = Color(0xFFEDE7DB);
  static const argumentCardBorder = Color.fromRGBO(76, 71, 61, 0.15);
  static const argumentScalesBackground = Color.fromRGBO(124, 79, 42, 0.08);
  static const argumentScalesBorder = Color.fromRGBO(124, 79, 42, 0.25);

  /// Background of a selected verdict button.
  static const verdictSelected = Color(0xFFB2ACA0);

  // Result screen

  /// "✗ Incorrect verdict" banner and the player's wrong buttons.
  static const resultIncorrect = Color(0xFF952525);
  static const resultIncorrectBackground = Color.fromRGBO(149, 37, 37, 0.08);
  static const resultIncorrectBorder = Color.fromRGBO(149, 37, 37, 0.4);

  /// "✓ Correct verdict".
  static const resultCorrect = Color(0xFF2F6B3A);
  static const resultCorrectBackground = Color.fromRGBO(47, 107, 58, 0.08);
  static const resultCorrectBorder = Color.fromRGBO(47, 107, 58, 0.4);

  /// "You ruled" and "Actual sentence" cards.
  static const resultCardBorder = Color.fromRGBO(76, 71, 61, 0.08);

  /// "Court ruled" card.
  static const resultCourtCard = Color.fromRGBO(124, 79, 42, 0.05);
  static const resultCourtCardBorder = Color.fromRGBO(76, 71, 61, 0.3);

  // Trigger warning

  static const warningOverlay = Color.fromRGBO(255, 255, 255, 0.85);
  static const warningButton = Color(0xFFD9D9D9);
  static const black = Color(0xFF000000);
}
