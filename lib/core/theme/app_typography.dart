import 'package:flutter/material.dart';

/// Tipografia do design system estilo Spotify: Figtree em negrito para títulos e corpo.
abstract final class AppTypography {
  static const String heading = 'Figtree';
  static const String body = 'Figtree';

  /// Estilo de título (Figtree Bold 700) no padrão geométrico moderno do Spotify.
  static TextStyle headingStyle({
    required double size,
    Color? color,
    FontWeight weight = FontWeight.w700,
    double height = 1.12,
  }) => TextStyle(
    fontFamily: heading,
    fontWeight: weight,
    fontSize: size,
    height: height,
    letterSpacing: -0.02 * size,
    color: color,
  );

  /// Estilo de corpo (Figtree) com peso configurável.
  static TextStyle bodyStyle({
    double size = 15,
    FontWeight weight = FontWeight.w400,
    Color? color,
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
