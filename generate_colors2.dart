import 'dart:io';

void main() {
  final content = File('lib/core/theme/app_colors.dart').readAsStringSync();
  final regex = RegExp(r'static const Color (\w+) = Color\((0x[0-9A-Fa-f]+)\);');
  final matches = regex.allMatches(content);
  
  List<String> names = [];
  List<String> lightValues = [];
  
  for (var match in matches) {
    names.add(match.group(1)!);
    lightValues.add(match.group(2)!);
  }

  // Generate dark mode values programmatically or define overrides
  Map<String, String> darkOverrides = {
    'bg': '0xFF161413',
    'surface': '0xFF221E1C',
    'text': '0xFFEAE3DC',
    'neutral100': '0xFF2A2624',
    'neutral200': '0xFF35302E',
    'neutral300': '0xFF47413D',
    'neutral400': '0xFF5C544F',
    'neutral500': '0xFF7A706A',
    'neutral600': '0xFF968B84',
    'neutral700': '0xFFB0A59E',
    'neutral800': '0xFFC4BDB7',
    'neutral900': '0xFFF0EBE6',
    'accent': '0xFFD98A57',
    'accent2': '0xFF99A97C',
    'accent2_100': '0xFF1D2413',
    'accent2_200': '0xFF2D381E',
    'accent2_300': '0xFF40502A',
    'accent2_400': '0xFF566938',
    'accent2_500': '0xFF71854D',
    'accent2_600': '0xFF8DA266',
    'accent2_700': '0xFFA6BB82',
    'accent2_800': '0xFFC3D4A4',
    'accent2_900': '0xFFE2ECCC',
    'accent100': '0xFF2E1708',
    'accent200': '0xFF45230D',
    'accent300': '0xFF663616',
    'accent400': '0xFF874921',
    'accent500': '0xFFA95D2C',
    'accent600': '0xFFC77745',
    'accent700': '0xFFD98A57',
    'accent800': '0xFFE9B390',
    'accent900': '0xFFF6DBCD',
  };
  
  var sb = StringBuffer();
  sb.writeln("import 'package:flutter/material.dart';\n");
  sb.writeln('class AppColors extends ThemeExtension<AppColors> {');
  for (var name in names) {
    sb.writeln('  final Color $name;');
  }
  sb.writeln('\n  const AppColors({');
  for (var name in names) {
    sb.writeln('    required this.$name,');
  }
  sb.writeln('  });\n');
  
  sb.writeln('  Color get divider => text.withValues(alpha: 0.16);');
  sb.writeln('  Color alpha(Color color, double pct) => color.withValues(alpha: pct.clamp(0.0, 1.0));');
  sb.writeln('  Color mix(Color a, Color b, double pctA) => Color.lerp(b, a, pctA.clamp(0.0, 1.0))!;\n');
  
  sb.writeln('  @override');
  sb.writeln('  AppColors copyWith({');
  for (var name in names) {
    sb.writeln('    Color? $name,');
  }
  sb.writeln('  }) {');
  sb.writeln('    return AppColors(');
  for (var name in names) {
    sb.writeln('      $name: $name ?? this.$name,');
  }
  sb.writeln('    );');
  sb.writeln('  }\n');
  
  sb.writeln('  @override');
  sb.writeln('  AppColors lerp(ThemeExtension<AppColors>? other, double t) {');
  sb.writeln('    if (other is! AppColors) return this;');
  sb.writeln('    return AppColors(');
  for (var name in names) {
    sb.writeln('      $name: Color.lerp($name, other.$name, t)!,');
  }
  sb.writeln('    );');
  sb.writeln('  }\n');
  
  sb.writeln('  static const light = AppColors(');
  for (int i=0; i<names.length; i++) {
    sb.writeln('    ${names[i]}: Color(${lightValues[i]}),');
  }
  sb.writeln('  );\n');

  sb.writeln('  static const dark = AppColors(');
  for (int i=0; i<names.length; i++) {
    var val = darkOverrides[names[i]] ?? lightValues[i];
    sb.writeln('    ${names[i]}: Color($val),');
  }
  sb.writeln('  );\n');
  sb.writeln('}');
  
  sb.writeln('\nextension AppColorsExtension on BuildContext {');
  sb.writeln('  AppColors get colors => Theme.of(this).extension<AppColors>()!;');
  sb.writeln('}');

  File('lib/core/theme/app_colors.dart').writeAsStringSync(sb.toString());
}
