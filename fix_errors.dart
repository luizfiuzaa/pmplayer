import 'dart:io';

void main() {
  // Fix sample_music_repository
  var f = File('lib/core/data/sample_music_repository.dart');
  f.writeAsStringSync(f.readAsStringSync().replaceAll('context.colors.', 'AppColors.light.'));

  // Fix app_typography
  f = File('lib/core/theme/app_typography.dart');
  f.writeAsStringSync(f.readAsStringSync().replaceAll('context.colors.', 'AppColors.light.'));

  // Fix music_glyph
  f = File('lib/core/widgets/music_glyph.dart');
  f.writeAsStringSync(f.readAsStringSync().replaceAll('context.colors.', 'AppColors.light.'));

  // Fix song_cover
  f = File('lib/core/widgets/song_cover.dart');
  f.writeAsStringSync(f.readAsStringSync().replaceAll('context.colors.', 'AppColors.light.'));

  // Fix main.dart
  f = File('lib/main.dart');
  f.writeAsStringSync(f.readAsStringSync().replaceAll('theme: AppTheme.build(),', 'theme: AppTheme.build(AppColors.light, Brightness.light),'));
}
