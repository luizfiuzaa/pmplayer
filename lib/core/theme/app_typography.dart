import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Tipografia do design system: Caprasimo (títulos) sobre Figtree (corpo).
abstract final class AppTypography {
  static const String heading = 'Caprasimo';
  static const String body = 'Figtree';

  /// Estilo de título (Caprasimo 400) com a altura de linha e tracking do DS.
  static TextStyle headingStyle({
    required double size,
    Color color = AppColors.text,
    double height = 1.12,
  }) => TextStyle(
    fontFamily: heading,
    fontWeight: FontWeight.w400,
    fontSize: size,
    height: height,
    letterSpacing: -0.015 * size,
    color: color,
  );

  /// Estilo de corpo (Figtree) com peso configurável.
  static TextStyle bodyStyle({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color color = AppColors.text,
    double height = 1.55,
    double? letterSpacing,
  }) => TextStyle(
    fontFamily: body,
    fontWeight: weight,
    fontSize: size,
    height: height,
    letterSpacing: letterSpacing,
    color: color,
  );
}
