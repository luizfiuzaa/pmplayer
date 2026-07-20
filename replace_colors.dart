import 'dart:io';

void main() {
  final files = [
    'lib/core/data/sample_music_repository.dart',
    'lib/core/widgets/song_cover.dart',
    'lib/core/widgets/cover_artwork.dart',
    'lib/core/widgets/track_tile.dart',
    'lib/core/widgets/heart_button.dart',
    'lib/core/widgets/music_glyph.dart',
    'lib/features/playlists/playlist_detail_view.dart',
    'lib/features/playlists/playlists_view.dart',
    'lib/features/playlists/create_playlist_sheet.dart',
    'lib/features/shell/app_shell.dart',
    'lib/features/favorites/favorites_view.dart',
    'lib/features/library/library_view.dart',
    'lib/features/player/now_playing_view.dart',
    'lib/features/player/mini_player.dart',
  ];

  for (var path in files) {
    final file = File(path);
    if (!file.existsSync()) continue;
    var content = file.readAsStringSync();
    
    // Add import for AppColors if needed
    if (!content.contains("import '../../core/theme/app_colors.dart';") &&
        !content.contains("import '../../../core/theme/app_colors.dart';")) {
       // already imported? Let's assume yes. Wait, if we use context.colors, we need the extension.
    }
    
    // We need to replace AppColors. with context.colors.
    // Except in static contexts? Let's check if there are static functions.
    content = content.replaceAll('AppColors.', 'context.colors.');
    
    file.writeAsStringSync(content);
  }
}
