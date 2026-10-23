import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

abstract final class AppTextStyles {
  // Type scale (used by the app theme and by screens)

  static final display = _caslon(
    48,
    AppColors.textDark,
    letterSpacing: -1.8287,
    lineHeight: 51.204,
  );
  static final headline = _caslon(32, AppColors.textDark);
  static final title = _caslon(24, AppColors.textDark);
  static final body = _caslon(16, AppColors.textDark, lineHeight: 22.1);

  /// Small caps label, 14.
  static final label = _dmSans(14, FontWeight.w700, AppColors.brown);

  /// Small caps label, 13 (e.g. "REAL COURT CASES").
  static final labelSmall = _dmSans(
    13,
    FontWeight.w700,
    AppColors.brown,
    letterSpacing: 2.62,
    lineHeight: 17.88,
  );

  /// Material [TextTheme] built from the scale above, for [ThemeData].
  static TextTheme get textTheme => TextTheme(
    displayLarge: display,
    headlineMedium: headline,
    titleLarge: title,
    bodyLarge: body,
    bodyMedium: _dmSans(14, FontWeight.w400, AppColors.text),
    labelLarge: label,
    labelMedium: labelSmall,
  );

  // Splash screen ("REAL COURT CASES" under it uses [labelSmall])

  static final splashTitle = _caslon(
    50,
    AppColors.brown,
    letterSpacing: -1.8287,
    lineHeight: 51.204,
  );

  // Home screen

  static final swipeArrow = _dmSans(
    14,
    FontWeight.w400,
    AppColors.brown,
    letterSpacing: 0.8,
    lineHeight: 21,
  );
  static final swipeHint = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textMuted,
    letterSpacing: 0.87,
    lineHeight: 16.25,
  );

  // Category chips (Material 3 segmented buttons in the design, so Roboto)
  static final chipSelected = _roboto(
    16,
    FontWeight.w500,
    AppColors.white,
    letterSpacing: 0.15,
    lineHeight: 24,
  );
  static final chipIdle = chipSelected.copyWith(color: AppColors.brown);

  static final titleCardLabel = _dmSans(
    9.5,
    FontWeight.w700,
    AppColors.medallionGoldLabel,
    letterSpacing: 1.42,
    lineHeight: 14.25,
  );
  static final titleCardTitle = _caslon(
    15.98,
    AppColors.titleCardTitle,
    lineHeight: 16.779,
  );
  static final titleCardSubtitle = _dmSans(
    9.5,
    FontWeight.w400,
    AppColors.titleCardSubtitle,
    lineHeight: 14.25,
  );

  // The 0.72 alpha on the medallion label comes from the design.
  static final medallionLockedLabel = _dmSans(
    9.5,
    FontWeight.w700,
    AppColors.medallionLockedText.withValues(alpha: 0.72),
    letterSpacing: 1.14,
    lineHeight: 14.25,
  );
  static final medallionNextCase = _dmSans(
    16,
    FontWeight.w700,
    AppColors.white,
    letterSpacing: 0.9024,
    lineHeight: 11.28,
  );
  static final medallionContinue = _dmSans(
    14,
    FontWeight.w700,
    AppColors.white,
    letterSpacing: 0.9024,
    lineHeight: 11.28,
  );
  static final medallionEnter = _dmSans(
    9.5,
    FontWeight.w800,
    AppColors.brown,
    letterSpacing: 0.76,
    lineHeight: 14.25,
  );

  // Notice shown instead of an empty case column
  static final hiddenCasesBody = _dmSans(
    14,
    FontWeight.w400,
    AppColors.text,
    lineHeight: 20,
  );
  static final hiddenCasesButton = _dmSans(
    14,
    FontWeight.w500,
    AppColors.white,
    letterSpacing: 0.35,
    lineHeight: 20,
  );

  // ---------------------------------------------------------------------------
  // Home: country picker (Material 3 list in the design, so Roboto)
  // ---------------------------------------------------------------------------

  static final countryPickerSearch = _roboto(
    16,
    FontWeight.w400,
    AppColors.white,
    letterSpacing: 0.5,
    lineHeight: 24,
  );
  static final countryPickerSearchHint = countryPickerSearch.copyWith(
    color: AppColors.white.withValues(alpha: 0.5),
  );
  static final countryPickerName = _roboto(
    16,
    FontWeight.w400,
    AppColors.countryPickerName,
    letterSpacing: 0.5,
    lineHeight: 24,
  );
  static final countryPickerProgress = _roboto(
    14,
    FontWeight.w500,
    AppColors.countryPickerProgress,
    letterSpacing: 0.1,
    lineHeight: 20,
  );
  static final countryPickerProgressSelected = countryPickerProgress.copyWith(
    color: AppColors.countryPickerProgressSelected,
  );

  // ---------------------------------------------------------------------------
  // Account screens ("Create account", "Log in")
  // ---------------------------------------------------------------------------

  /// "CREATE ACCOUNT TO START JUDGING".
  static final accountEyebrow = _dmSans(
    13,
    FontWeight.w400,
    AppColors.brown,
    letterSpacing: 2.62,
    lineHeight: 17.88,
  );

  /// "Welcome Back, Judge".
  static final accountTitle = _caslon(
    36,
    AppColors.brown,
    letterSpacing: -1.8287,
    lineHeight: 51.204,
  );

  /// Label in the outline of a text field. Flutter draws a floating label at
  /// 75% of its size, so this is 16 to show the design's 12.
  static final fieldLabel = _dmSans(
    16,
    FontWeight.w400,
    AppColors.fieldLabel,
    letterSpacing: 0.4 / 0.75,
    lineHeight: 16 / 0.75,
  );
  static final fieldHint = _caslon(
    16,
    AppColors.brown,
    letterSpacing: 0.5,
    lineHeight: 24,
  );
  static final fieldInput = fieldHint.copyWith(color: AppColors.textDark);

  /// Error under the fields ("This username is already taken").
  static final fieldError = _dmSans(
    13,
    FontWeight.w400,
    AppColors.resultIncorrect,
    letterSpacing: 0.43,
    lineHeight: 17.33,
  );

  /// "Choose country to rule in" and the search field of the open dropdown.
  static final countryDropdown = _dmSans(
    14,
    FontWeight.w500,
    AppColors.white,
    letterSpacing: 0.1,
    lineHeight: 20,
  );
  static final countryDropdownHint = countryDropdown.copyWith(
    color: AppColors.white.withValues(alpha: 0.7),
  );

  /// "Create account", "Log in" (blue) and "Create new account" (white).
  static final accountButton = _caslon(
    20,
    AppColors.white,
    letterSpacing: 0.15,
    lineHeight: 24,
  );
  static final accountButtonSecondary = accountButton.copyWith(
    color: AppColors.brown,
  );

  /// "Forgot password?" and "I already have an account".
  static final accountLink =
      _caslon(
        16,
        AppColors.badgeRedText,
        letterSpacing: 0.15,
        lineHeight: 24,
      ).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.badgeRedText,
      );
  static final accountLinkMuted = accountLink.copyWith(
    color: AppColors.brown,
    decorationColor: AppColors.brown,
  );

  // ---------------------------------------------------------------------------
  // Profile screen
  // ---------------------------------------------------------------------------

  /// "MY PROFILE" in the header.
  static final profileHeader = _dmSans(
    14,
    FontWeight.w400,
    AppColors.textDark,
    letterSpacing: 1.98,
    lineHeight: 13.5,
  );

  // Welcome card
  static final profileWelcome = _dmSans(
    10,
    FontWeight.w400,
    AppColors.beige.withValues(alpha: 0.55),
    letterSpacing: 2.5,
    lineHeight: 15,
  );
  static final profileName = _dmSans(
    24,
    FontWeight.w700,
    AppColors.beige,
    lineHeight: 32,
  );
  static final profileUsername = _dmSans(
    13,
    FontWeight.w500,
    AppColors.beige.withValues(alpha: 0.8),
    lineHeight: 17.33,
  );
  static final profileRank = _dmSans(
    12,
    FontWeight.w400,
    AppColors.beige.withValues(alpha: 0.6),
    lineHeight: 18,
  );
  /// "Court Clerk" in "Rank: Court Clerk", brighter than the "Rank: " before it.
  static final profileRankValue = profileRank.copyWith(
    fontWeight: FontWeight.w600,
    color: AppColors.beige.withValues(alpha: 0.9),
  );
  static final profileCounter = _dmSans(
    11,
    FontWeight.w700,
    AppColors.profileCounter,
    lineHeight: 16.5,
  );
  static final profileMilestone = _dmSans(
    12,
    FontWeight.w400,
    AppColors.beige.withValues(alpha: 0.8),
    lineHeight: 18,
  );

  /// "CASES STATISTICS", "REVISE YOUR PREVIOUS CASES".
  static final profileSection = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 1.92,
    lineHeight: 14.4,
  );

  /// "ACHIEVEMENTS".
  static final profileSectionBold = _dmSans(
    13,
    FontWeight.w700,
    AppColors.textSubtle,
    letterSpacing: 1.73,
    lineHeight: 13,
  );

  // Statistics tiles (Lora in the design, which the app does not bundle)
  static final statValue = _caslon(20, AppColors.white, lineHeight: 28);
  static final statLabel = _dmSans(
    8,
    FontWeight.w400,
    AppColors.white.withValues(alpha: 0.8),
    letterSpacing: 1.44,
    lineHeight: 12,
  );

  // Previous cases
  static final previousCaseTitle = _dmSans(
    14,
    FontWeight.w400,
    AppColors.textDark,
    lineHeight: 16,
  );

  /// "Traffic · 2023" under a previous case.
  static final previousCaseDetail = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 16.8,
  );
  static final previousCaseAction = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 13,
  );

  // Achievements
  static final achievementCount = _dmSans(
    10,
    FontWeight.w700,
    AppColors.achievementCount,
    lineHeight: 15,
  );
  static final achievementBadge = _caslon(
    12,
    AppColors.textSubtle,
    lineHeight: 18,
  );
  static final achievementTitle = _dmSans(
    13,
    FontWeight.w600,
    AppColors.beige,
    lineHeight: 17.33,
  );
  static final achievementDescription = _dmSans(
    12,
    FontWeight.w400,
    AppColors.beige.withValues(alpha: 0.65),
    lineHeight: 16.5,
  );

  // ---------------------------------------------------------------------------
  // Settings screen ("SETTINGS" in the header uses [profileHeader])
  // ---------------------------------------------------------------------------

  /// "CONTENT PREFERENCES", "MANAGE ACCOUNT".
  static final settingsSection = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 1.73,
    lineHeight: 13,
  );
  static final settingsBody = _dmSans(
    14,
    FontWeight.w400,
    AppColors.textDark,
    lineHeight: 22.75,
  );

  /// "Sensitive case filter", "Edit information", "Sign out".
  static final settingsItem = _dmSans(
    14,
    FontWeight.w500,
    AppColors.countryPickerName,
    letterSpacing: 0.1,
    lineHeight: 20,
  );

  /// "No filter selected".
  static final settingsItemDetail = _dmSans(
    13,
    FontWeight.w400,
    AppColors.fieldLabel,
    letterSpacing: 0.43,
    lineHeight: 17.33,
  );
  static final settingsNote = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 21.12,
  );

  // Case screen

  // Header
  static final caseBadge = _dmSans(
    13,
    FontWeight.w400,
    AppColors.badgeRedText,
    letterSpacing: 1.3,
    lineHeight: 17.33,
  );
  static final caseTitle = _caslon(32, AppColors.textDark, lineHeight: 30);
  static final caseOrigin = _caslon(
    14,
    AppColors.textSubtle,
    letterSpacing: 0.6,
    lineHeight: 16,
  );

  /// "CHARGES FILED", "CASE SUMMARY", "ARGUMENTS".
  static final caseSectionLabel = _dmSans(
    13,
    FontWeight.w400,
    AppColors.brown,
    letterSpacing: 1.3,
    lineHeight: 16.25,
  );

  // Charges and summary
  static final caseChargeBullet = _inter(13, FontWeight.w400, AppColors.brown);
  static final caseCharge = _caslon(16, AppColors.textDark, lineHeight: 21);
  static final caseSummary = _caslon(16, AppColors.textDark, lineHeight: 22.75);
  static final caseToggleSelected = _dmSans(
    12,
    FontWeight.w700,
    AppColors.beige,
    letterSpacing: 0.6,
    lineHeight: 18,
  );
  static final caseToggleIdle = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 0.6,
    lineHeight: 18,
  );

  // Arguments
  static final argumentsCount = _dmSans(
    12,
    FontWeight.w700,
    AppColors.brown,
    lineHeight: 18,
  );
  static final argumentCardLabel = _dmSans(
    11,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 2.2,
    lineHeight: 16.5,
  );
  static final argumentIntroTitle = _caslon(
    32,
    AppColors.textDark,
    lineHeight: 33,
  );
  // DM Sans rather than the display serif: easier to read in long sentences.
  static final argumentText = _dmSans(
    20,
    FontWeight.w400,
    AppColors.textDark,
    lineHeight: 28,
  );

  // Verdict
  static final rulingEyebrow = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 32.5,
  );
  static final rulingTitle = _caslon(24, AppColors.text, lineHeight: 30);
  static final rulingHint = _inter(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 17.33,
  );
  static final verdictTitle = _inter(
    14,
    FontWeight.w600,
    AppColors.text,
    letterSpacing: 0.35,
    lineHeight: 20,
  );
  static final verdictTitleSelected = verdictTitle.copyWith(
    color: AppColors.white,
  );
  static final verdictSubtitle = _inter(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 17.33,
  );
  static final verdictValue = _inter(
    13,
    FontWeight.w600,
    AppColors.white,
    lineHeight: 20,
  );

  // Buttons
  static final primaryButton = _dmSans(
    14,
    FontWeight.w600,
    AppColors.beige,
    letterSpacing: 0.35,
    lineHeight: 20,
  );
  static final textButton = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 0.65,
    lineHeight: 17.33,
  );

  // Result screen

  /// "✗ INCORRECT VERDICT"; the color comes from the outcome.
  static final resultOutcomeLabel = _dmSans(
    13,
    FontWeight.w400,
    AppColors.resultIncorrect,
    letterSpacing: 3.25,
    lineHeight: 17.33,
  );
  static final resultOutcomeTitle = _caslon(
    24,
    AppColors.textDark,
    lineHeight: 32,
  );

  /// "YOU RULED", "COURT RULED".
  static final resultCardLabel = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 0.97,
    lineHeight: 14.62,
  );

  /// The verdict buttons inside those cards; the color comes from the outcome.
  static final resultCardValue = _dmSans(
    14,
    FontWeight.w700,
    AppColors.brown,
    letterSpacing: 0.7,
    lineHeight: 20,
  );

  /// "ACTUAL SENTENCE", "WHY THE COURT DECIDED THIS".
  static final resultSectionLabel = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 1.08,
    lineHeight: 16.25,
  );
  static final resultSentence = _caslon(20, AppColors.textDark, lineHeight: 26);
  static final resultReasoning = _caslon(
    16,
    AppColors.textDark,
    lineHeight: 22.75,
  );
  static final resultOrigin = _dmSans(
    13,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 16.25,
  );
  static final resultNextCase = _dmSans(
    14,
    FontWeight.w700,
    AppColors.beige,
    letterSpacing: 1.4,
    lineHeight: 20,
  );
  static final resultSourceLink =
      _dmSans(
        14,
        FontWeight.w400,
        AppColors.textSubtle,
        lineHeight: 20,
      ).copyWith(
        decoration: TextDecoration.underline,
        decorationColor: AppColors.textSubtle,
      );

  // Achievement screen

  /// "New achievement!" on the blue band.
  static final achievementBanner = _caslon(
    40,
    AppColors.white,
    lineHeight: 48,
  );

  /// Roman numeral in the big round badge.
  static final achievementBadgeLarge = _caslon(40, AppColors.white);

  /// Achievement title written on the bench, next to the gavel.
  static final achievementScreenTitle = _caslon(
    28,
    AppColors.textDark,
    lineHeight: 32,
  );

  /// The achievement's own sentence, under the floor.
  static final achievementMessage = _caslon(
    20,
    AppColors.text,
    lineHeight: 26,
  );

  /// "Keep up the good work, Judge".
  static final achievementCheer = _caslon(
    24,
    AppColors.textDark,
    lineHeight: 30,
  );

  // First-time guide

  static final guideTip = _dmSans(
    14,
    FontWeight.w400,
    AppColors.brown,
    lineHeight: 16.5,
  );

  /// "1/3" and "Skip".
  static final guideProgress = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 16,
  );

  /// "Next" and "Got it".
  static final guideAction = _dmSans(
    14,
    FontWeight.w700,
    AppColors.blue,
    lineHeight: 20,
  );

  // Trigger warning

  static final warningTitle = _dmSans(40, FontWeight.w300, AppColors.black);
  static final warningBody = _dmSans(20, FontWeight.w300, AppColors.text);
  static final warningCheckbox = _dmSans(16, FontWeight.w300, AppColors.black);
  static final warningButton = _dmSans(20, FontWeight.w300, AppColors.black);

  // ---------------------------------------------------------------------------
  // Builders
  // ---------------------------------------------------------------------------

  static TextStyle _roboto(
    double size,
    FontWeight weight,
    Color color, {
    double letterSpacing = 0,
    double? lineHeight,
  }) => _style(AppFonts.roboto, size, weight, color, letterSpacing, lineHeight);

  static TextStyle _inter(
    double size,
    FontWeight weight,
    Color color, {
    double letterSpacing = 0,
    double? lineHeight,
  }) => _style(AppFonts.inter, size, weight, color, letterSpacing, lineHeight);

  static TextStyle _dmSans(
    double size,
    FontWeight weight,
    Color color, {
    double letterSpacing = 0,
    double? lineHeight,
  }) => _style(AppFonts.dmSans, size, weight, color, letterSpacing, lineHeight);

  /// Libre Caslon Display only comes in one weight.
  static TextStyle _caslon(
    double size,
    Color color, {
    double letterSpacing = 0,
    double? lineHeight,
  }) => _style(
    AppFonts.caslon,
    size,
    FontWeight.w400,
    color,
    letterSpacing,
    lineHeight,
  );

  static TextStyle _style(
    String family,
    double size,
    FontWeight weight,
    Color color,
    double letterSpacing,
    double? lineHeight,
  ) => TextStyle(
    fontFamily: family,
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: _lineHeight(lineHeight, size),
  );

  static double? _lineHeight(double? pixels, double fontSize) =>
      pixels == null ? null : pixels / fontSize;
}
