import 'dart:io';

void main() {
  // app_typography
  var f = File('lib/core/theme/app_typography.dart');
  f.writeAsStringSync(f.readAsStringSync().replaceAll('AppColors.text', 'AppColors.light.text'));

  // sample_music_repository: remove const from songs
  f = File('lib/core/data/sample_music_repository.dart');
  var content = f.readAsStringSync();
  content = content.replaceAll('const Song(', 'Song(');
  content = content.replaceAll('const [', '['); // safe enough for this file
  f.writeAsStringSync(content);
  
  // music_glyph: remove const
  f = File('lib/core/widgets/music_glyph.dart');
  content = f.readAsStringSync();
  content = content.replaceAll('const Icon(', 'Icon(');
  f.writeAsStringSync(content);
  
  // song_cover: remove const
  f = File('lib/core/widgets/song_cover.dart');
  content = f.readAsStringSync();
  content = content.replaceAll('const Icon(', 'Icon(');
  f.writeAsStringSync(content);

  // fix 'undefined_identifier' for AppColors in main.dart
  f = File('lib/main.dart');
  content = f.readAsStringSync();
  if (!content.contains("import 'core/theme/app_colors.dart';")) {
    content = content.replaceFirst("import 'core/theme/app_theme.dart';", "import 'core/theme/app_theme.dart';\nimport 'core/theme/app_colors.dart';");
  }
  f.writeAsStringSync(content);

  // fix 'undefined_identifier' for context in playlists_view.dart:120:17
  f = File('lib/features/playlists/playlists_view.dart');
  content = f.readAsStringSync();
  content = content.replaceAll('context.colors.divider', 'AppColors.light.divider'); // wait, if context is undefined, it's not a build method.
  f.writeAsStringSync(content);
}
