import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_fonts.dart';

abstract final class AppTextStyles {
  // ---------------------------------------------------------------------------
  // Type scale (used by the app theme and by screens)
  // ---------------------------------------------------------------------------

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

  /// Small caps label, 12 (e.g. "REAL COURT CASES").
  static final labelSmall = _dmSans(
    12,
    FontWeight.w700,
    AppColors.brown,
    letterSpacing: 2.42,
    lineHeight: 16.5,
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

  // ---------------------------------------------------------------------------
  // Home screen
  // ---------------------------------------------------------------------------

  static final swipeArrow = _dmSans(
    14,
    FontWeight.w400,
    AppColors.brown,
    letterSpacing: 0.8,
    lineHeight: 21,
  );
  static final swipeHint = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textMuted,
    letterSpacing: 0.8,
    lineHeight: 15,
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
    7.52,
    FontWeight.w700,
    AppColors.medallionGoldLabel,
    letterSpacing: 1.128,
    lineHeight: 11.28,
  );
  static final titleCardTitle = _caslon(
    15.98,
    AppColors.titleCardTitle,
    lineHeight: 16.779,
  );
  static final titleCardSubtitle = _dmSans(
    7.52,
    FontWeight.w400,
    AppColors.titleCardSubtitle,
    lineHeight: 11.28,
  );

  // The 0.72 alpha on the two medallion labels comes from the design.
  static final medallionCompletedLabel = _dmSans(
    7.52,
    FontWeight.w700,
    AppColors.medallionCompletedText.withValues(alpha: 0.72),
    letterSpacing: 0.9024,
    lineHeight: 11.28,
  );
  static final medallionLockedLabel = _dmSans(
    7.52,
    FontWeight.w700,
    AppColors.medallionLockedText.withValues(alpha: 0.72),
    letterSpacing: 0.9024,
    lineHeight: 11.28,
  );
  static final medallionNextCase = _dmSans(
    16,
    FontWeight.w700,
    AppColors.white,
    letterSpacing: 0.9024,
    lineHeight: 11.28,
  );
  static final medallionEnter = _dmSans(
    7.52,
    FontWeight.w800,
    AppColors.brown,
    letterSpacing: 0.6016,
    lineHeight: 11.28,
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
  // Case screen
  // ---------------------------------------------------------------------------

  // Header
  static final caseBadge = _dmSans(
    12,
    FontWeight.w400,
    AppColors.badgeRedText,
    letterSpacing: 1.2,
    lineHeight: 16,
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
    12,
    FontWeight.w400,
    AppColors.brown,
    letterSpacing: 1.2,
    lineHeight: 15,
  );

  // Charges and summary
  static final caseChargeBullet = _inter(12, FontWeight.w400, AppColors.brown);
  static final caseCharge = _caslon(16, AppColors.textDark, lineHeight: 21);
  static final caseSummary = _caslon(16, AppColors.textDark, lineHeight: 22.75);
  static final caseToggleSelected = _dmSans(
    10,
    FontWeight.w700,
    AppColors.beige,
    letterSpacing: 0.5,
    lineHeight: 15,
  );
  static final caseToggleIdle = _dmSans(
    10,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 0.5,
    lineHeight: 15,
  );

  // Arguments
  static final argumentsCount = _dmSans(
    10,
    FontWeight.w700,
    AppColors.brown,
    lineHeight: 15,
  );
  static final argumentCardLabel = _dmSans(
    9,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 1.8,
    lineHeight: 13.5,
  );
  static final argumentIntroTitle = _caslon(
    32,
    AppColors.textDark,
    lineHeight: 33,
  );
  static final argumentText = _caslon(28, AppColors.textDark, lineHeight: 31);

  // Verdict
  static final rulingEyebrow = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 30,
  );
  static final rulingTitle = _caslon(24, AppColors.text, lineHeight: 30);
  static final rulingHint = _inter(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 16,
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
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 16,
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
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 0.6,
    lineHeight: 16,
  );

  // ---------------------------------------------------------------------------
  // Result screen
  // ---------------------------------------------------------------------------

  /// "✗ INCORRECT VERDICT"; the color comes from the outcome.
  static final resultOutcomeLabel = _dmSans(
    12,
    FontWeight.w400,
    AppColors.resultIncorrect,
    letterSpacing: 3,
    lineHeight: 16,
  );
  static final resultOutcomeTitle = _caslon(
    24,
    AppColors.textDark,
    lineHeight: 32,
  );

  /// "YOU RULED", "COURT RULED".
  static final resultCardLabel = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 0.9,
    lineHeight: 13.5,
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
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    letterSpacing: 1,
    lineHeight: 15,
  );
  static final resultSentence = _caslon(20, AppColors.textDark, lineHeight: 26);
  static final resultReasoning = _caslon(
    16,
    AppColors.textDark,
    lineHeight: 22.75,
  );
  static final resultOrigin = _dmSans(
    12,
    FontWeight.w400,
    AppColors.textSubtle,
    lineHeight: 15,
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

  // ---------------------------------------------------------------------------
  // Trigger warning
  // ---------------------------------------------------------------------------

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
