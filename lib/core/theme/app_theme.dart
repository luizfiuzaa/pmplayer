import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_typography.dart';

/// Monta o [ThemeData] do PMPlayer a partir dos tokens "Organic".
abstract final class AppTheme {
  static ThemeData build(AppColors colors, Brightness brightness) {
    final base = ThemeData(brightness: brightness, useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: colors.bg,
      canvasColor: colors.bg,
      colorScheme: base.colorScheme.copyWith(
        primary: colors.accent2_500,
        secondary: colors.accent,
        surface: colors.surface,
        onSurface: colors.text,
      ),
      extensions: [colors],
      // Toque suave (equivalente ao `.rowbtn:hover` do design).
      splashColor: colors.alpha(colors.text, 0.05),
      highlightColor: colors.alpha(colors.text, 0.04),
      textTheme: base.textTheme.apply(
        fontFamily: AppTypography.body,
        bodyColor: colors.text,
        displayColor: colors.text,
      ),
    );
  }
}
