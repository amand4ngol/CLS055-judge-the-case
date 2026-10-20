import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_fonts.dart';
import 'app_text_styles.dart';

abstract final class AppTheme {
  static final ThemeData light = _buildLight();

  static ThemeData _buildLight() {
    final colorScheme = ColorScheme.fromSeed(seedColor: AppColors.blue)
        .copyWith(
          primary: AppColors.blue,
          onPrimary: AppColors.white,
          secondary: AppColors.brown,
          onSecondary: AppColors.white,
          surface: AppColors.beige,
          onSurface: AppColors.textDark,
          surfaceContainer: AppColors.beigeDark,
          outlineVariant: AppColors.hairline,
        );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.beige,
      // Default for widgets without an AppTextStyles style (snackbars,
      // Material buttons).
      fontFamily: AppFonts.dmSans,
      textTheme: AppTextStyles.textTheme,
      dividerTheme: const DividerThemeData(
        color: AppColors.hairline,
        thickness: 0.696,
        space: 0.696,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.brown,
      ),
    );
  }
}
