import 'package:flutter/material.dart';

/// Cores do design system "Organic", portadas 1:1 de
/// `docs/design/_ds/.../styles.css`. Não usar hex cru fora deste arquivo.
abstract final class AppColors {
  // Papéis base
  static const Color bg = Color(0xFFF5EAD8);
  static const Color surface = Color(0xFFEBDDC5);
  static const Color text = Color(0xFF201E1D);
  static const Color accent = Color(0xFFC67139);
  static const Color accent2 = Color(0xFF7A8A5E);

  /// `--color-divider`: text a 16%.
  static Color get divider => text.withValues(alpha: 0.16);

  // Rampa neutra 100–900
  static const Color neutral100 = Color(0xFFF9F4ED);
  static const Color neutral200 = Color(0xFFEEE7DB);
  static const Color neutral300 = Color(0xFFDCD3C4);
  static const Color neutral400 = Color(0xFFC0B6A5);
  static const Color neutral500 = Color(0xFFA19786);
  static const Color neutral600 = Color(0xFF82796A);
  static const Color neutral700 = Color(0xFF645C50);
  static const Color neutral800 = Color(0xFF474238);
  static const Color neutral900 = Color(0xFF2E2B25);

  // Rampa accent (terracota) 100–900
  static const Color accent100 = Color(0xFFFFF2EB);
  static const Color accent200 = Color(0xFFFFE1D0);
  static const Color accent300 = Color(0xFFFFC6A5);
  static const Color accent400 = Color(0xFFF6A06B);
  static const Color accent500 = Color(0xFFD67F48);
  static const Color accent600 = Color(0xFFB2622D);
  static const Color accent700 = Color(0xFF8C491A);
  static const Color accent800 = Color(0xFF643312);
  static const Color accent900 = Color(0xFF402310);

  // Rampa accent-2 (sálvia) 100–900
  static const Color accent2_100 = Color(0xFFF0FAE1);
  static const Color accent2_200 = Color(0xFFE1EECC);
  static const Color accent2_300 = Color(0xFFCCDBB2);
  static const Color accent2_400 = Color(0xFFAEBF92);
  static const Color accent2_500 = Color(0xFF8FA073);
  static const Color accent2_600 = Color(0xFF728157);
  static const Color accent2_700 = Color(0xFF56633F);
  static const Color accent2_800 = Color(0xFF3D472B);
  static const Color accent2_900 = Color(0xFF272E1B);

  /// Equivalente a `color-mix(in srgb, [color] [pct]%, transparent)`:
  /// a mesma cor com alfa proporcional.
  static Color alpha(Color color, double pct) =>
      color.withValues(alpha: pct.clamp(0.0, 1.0));

  /// Equivalente a `color-mix(in srgb, [a] [pctA]%, [b])` opaco.
  static Color mix(Color a, Color b, double pctA) =>
      Color.lerp(b, a, pctA.clamp(0.0, 1.0))!;
}
