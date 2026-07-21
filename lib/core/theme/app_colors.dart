import 'package:flutter/material.dart';

class AppColors extends ThemeExtension<AppColors> {
  final Color bg;
  final Color surface;
  final Color text;
  final Color accent;
  final Color accent2;
  final Color neutral100;
  final Color neutral200;
  final Color neutral300;
  final Color neutral400;
  final Color neutral500;
  final Color neutral600;
  final Color neutral700;
  final Color neutral800;
  final Color neutral900;
  final Color accent100;
  final Color accent200;
  final Color accent300;
  final Color accent400;
  final Color accent500;
  final Color accent600;
  final Color accent700;
  final Color accent800;
  final Color accent900;
  final Color accent2_100;
  final Color accent2_200;
  final Color accent2_300;
  final Color accent2_400;
  final Color accent2_500;
  final Color accent2_600;
  final Color accent2_700;
  final Color accent2_800;
  final Color accent2_900;

  const AppColors({
    required this.bg,
    required this.surface,
    required this.text,
    required this.accent,
    required this.accent2,
    required this.neutral100,
    required this.neutral200,
    required this.neutral300,
    required this.neutral400,
    required this.neutral500,
    required this.neutral600,
    required this.neutral700,
    required this.neutral800,
    required this.neutral900,
    required this.accent100,
    required this.accent200,
    required this.accent300,
    required this.accent400,
    required this.accent500,
    required this.accent600,
    required this.accent700,
    required this.accent800,
    required this.accent900,
    required this.accent2_100,
    required this.accent2_200,
    required this.accent2_300,
    required this.accent2_400,
    required this.accent2_500,
    required this.accent2_600,
    required this.accent2_700,
    required this.accent2_800,
    required this.accent2_900,
  });

  Color get divider => text.withValues(alpha: 0.16);
  Color alpha(Color color, double pct) =>
      color.withValues(alpha: pct.clamp(0.0, 1.0));
  Color mix(Color a, Color b, double pctA) =>
      Color.lerp(b, a, pctA.clamp(0.0, 1.0))!;

  @override
  AppColors copyWith({
    Color? bg,
    Color? surface,
    Color? text,
    Color? accent,
    Color? accent2,
    Color? neutral100,
    Color? neutral200,
    Color? neutral300,
    Color? neutral400,
    Color? neutral500,
    Color? neutral600,
    Color? neutral700,
    Color? neutral800,
    Color? neutral900,
    Color? accent100,
    Color? accent200,
    Color? accent300,
    Color? accent400,
    Color? accent500,
    Color? accent600,
    Color? accent700,
    Color? accent800,
    Color? accent900,
    Color? accent2_100,
    Color? accent2_200,
    Color? accent2_300,
    Color? accent2_400,
    Color? accent2_500,
    Color? accent2_600,
    Color? accent2_700,
    Color? accent2_800,
    Color? accent2_900,
  }) {
    return AppColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      text: text ?? this.text,
      accent: accent ?? this.accent,
      accent2: accent2 ?? this.accent2,
      neutral100: neutral100 ?? this.neutral100,
      neutral200: neutral200 ?? this.neutral200,
      neutral300: neutral300 ?? this.neutral300,
      neutral400: neutral400 ?? this.neutral400,
      neutral500: neutral500 ?? this.neutral500,
      neutral600: neutral600 ?? this.neutral600,
      neutral700: neutral700 ?? this.neutral700,
      neutral800: neutral800 ?? this.neutral800,
      neutral900: neutral900 ?? this.neutral900,
      accent100: accent100 ?? this.accent100,
      accent200: accent200 ?? this.accent200,
      accent300: accent300 ?? this.accent300,
      accent400: accent400 ?? this.accent400,
      accent500: accent500 ?? this.accent500,
      accent600: accent600 ?? this.accent600,
      accent700: accent700 ?? this.accent700,
      accent800: accent800 ?? this.accent800,
      accent900: accent900 ?? this.accent900,
      accent2_100: accent2_100 ?? this.accent2_100,
      accent2_200: accent2_200 ?? this.accent2_200,
      accent2_300: accent2_300 ?? this.accent2_300,
      accent2_400: accent2_400 ?? this.accent2_400,
      accent2_500: accent2_500 ?? this.accent2_500,
      accent2_600: accent2_600 ?? this.accent2_600,
      accent2_700: accent2_700 ?? this.accent2_700,
      accent2_800: accent2_800 ?? this.accent2_800,
      accent2_900: accent2_900 ?? this.accent2_900,
    );
  }

  @override
  AppColors lerp(ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      text: Color.lerp(text, other.text, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accent2: Color.lerp(accent2, other.accent2, t)!,
      neutral100: Color.lerp(neutral100, other.neutral100, t)!,
      neutral200: Color.lerp(neutral200, other.neutral200, t)!,
      neutral300: Color.lerp(neutral300, other.neutral300, t)!,
      neutral400: Color.lerp(neutral400, other.neutral400, t)!,
      neutral500: Color.lerp(neutral500, other.neutral500, t)!,
      neutral600: Color.lerp(neutral600, other.neutral600, t)!,
      neutral700: Color.lerp(neutral700, other.neutral700, t)!,
      neutral800: Color.lerp(neutral800, other.neutral800, t)!,
      neutral900: Color.lerp(neutral900, other.neutral900, t)!,
      accent100: Color.lerp(accent100, other.accent100, t)!,
      accent200: Color.lerp(accent200, other.accent200, t)!,
      accent300: Color.lerp(accent300, other.accent300, t)!,
      accent400: Color.lerp(accent400, other.accent400, t)!,
      accent500: Color.lerp(accent500, other.accent500, t)!,
      accent600: Color.lerp(accent600, other.accent600, t)!,
      accent700: Color.lerp(accent700, other.accent700, t)!,
      accent800: Color.lerp(accent800, other.accent800, t)!,
      accent900: Color.lerp(accent900, other.accent900, t)!,
      accent2_100: Color.lerp(accent2_100, other.accent2_100, t)!,
      accent2_200: Color.lerp(accent2_200, other.accent2_200, t)!,
      accent2_300: Color.lerp(accent2_300, other.accent2_300, t)!,
      accent2_400: Color.lerp(accent2_400, other.accent2_400, t)!,
      accent2_500: Color.lerp(accent2_500, other.accent2_500, t)!,
      accent2_600: Color.lerp(accent2_600, other.accent2_600, t)!,
      accent2_700: Color.lerp(accent2_700, other.accent2_700, t)!,
      accent2_800: Color.lerp(accent2_800, other.accent2_800, t)!,
      accent2_900: Color.lerp(accent2_900, other.accent2_900, t)!,
    );
  }

  static const light = AppColors(
    bg: Color(0xFFF5EAD8),
    surface: Color(0xFFEBDDC5),
    text: Color(0xFF201E1D),
    accent: Color(0xFFC67139),
    accent2: Color(0xFF7A8A5E),
    neutral100: Color(0xFFF9F4ED),
    neutral200: Color(0xFFEEE7DB),
    neutral300: Color(0xFFDCD3C4),
    neutral400: Color(0xFFC0B6A5),
    neutral500: Color(0xFFA19786),
    neutral600: Color(0xFF82796A),
    neutral700: Color(0xFF645C50),
    neutral800: Color(0xFF474238),
    neutral900: Color(0xFF2E2B25),
    accent100: Color(0xFFFFF2EB),
    accent200: Color(0xFFFFE1D0),
    accent300: Color(0xFFFFC6A5),
    accent400: Color(0xFFF6A06B),
    accent500: Color(0xFFD67F48),
    accent600: Color(0xFFB2622D),
    accent700: Color(0xFF8C491A),
    accent800: Color(0xFF643312),
    accent900: Color(0xFF402310),
    accent2_100: Color(0xFFF0FAE1),
    accent2_200: Color(0xFFE1EECC),
    accent2_300: Color(0xFFCCDBB2),
    accent2_400: Color(0xFFAEBF92),
    accent2_500: Color(0xFF8FA073),
    accent2_600: Color(0xFF728157),
    accent2_700: Color(0xFF56633F),
    accent2_800: Color(0xFF3D472B),
    accent2_900: Color(0xFF272E1B),
  );

  static const dark = AppColors(
    bg: Color(0xFF161413),
    surface: Color(0xFF221E1C),
    text: Color(0xFFEAE3DC),
    accent: Color(0xFFD98A57),
    accent2: Color(0xFF99A97C),
    neutral100: Color(0xFF2A2624),
    neutral200: Color(0xFF35302E),
    neutral300: Color(0xFF47413D),
    neutral400: Color(0xFF5C544F),
    neutral500: Color(0xFF7A706A),
    neutral600: Color(0xFF968B84),
    neutral700: Color(0xFFB0A59E),
    neutral800: Color(0xFFC4BDB7),
    neutral900: Color(0xFFF0EBE6),
    accent100: Color(0xFF2E1708),
    accent200: Color(0xFF45230D),
    accent300: Color(0xFF663616),
    accent400: Color(0xFF874921),
    accent500: Color(0xFFA95D2C),
    accent600: Color(0xFFC77745),
    accent700: Color(0xFFD98A57),
    accent800: Color(0xFFE9B390),
    accent900: Color(0xFFF6DBCD),
    accent2_100: Color(0xFF1D2413),
    accent2_200: Color(0xFF2D381E),
    accent2_300: Color(0xFF40502A),
    accent2_400: Color(0xFF566938),
    accent2_500: Color(0xFF71854D),
    accent2_600: Color(0xFF8DA266),
    accent2_700: Color(0xFFA6BB82),
    accent2_800: Color(0xFFC3D4A4),
    accent2_900: Color(0xFFE2ECCC),
  );
}

extension AppColorsExtension on BuildContext {
  AppColors get colors => Theme.of(this).extension<AppColors>()!;
}
