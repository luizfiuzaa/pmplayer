import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Monta o [ThemeData] do PMPlayer a partir dos tokens "Organic".
abstract final class AppTheme {
  static ThemeData build() {
    final base = ThemeData(brightness: Brightness.light, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: AppColors.bg,
      canvasColor: AppColors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: AppColors.accent2_500,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.text,
      ),
      // Toque suave (equivalente ao `.rowbtn:hover` do design).
      splashColor: AppColors.alpha(AppColors.text, 0.05),
      highlightColor: AppColors.alpha(AppColors.text, 0.04),
      textTheme: base.textTheme.apply(
        fontFamily: AppTypography.body,
        bodyColor: AppColors.text,
        displayColor: AppColors.text,
      ),
    );
  }
}
