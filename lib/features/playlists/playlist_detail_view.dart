import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/playlist.dart';
import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cover_artwork.dart';
import '../../core/widgets/track_tile.dart';
import '../navigation/navigation_controller.dart';
import '../player/player_view_model.dart';
import 'cover_image_picker.dart';
import '../../core/utils/ui_utils.dart';

/// Tela de detalhe de uma playlist: capa, ações e faixas. Fiel ao bloco
/// PLAYLIST DETAIL do design.
class PlaylistDetailView extends StatelessWidget {
  const PlaylistDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final currentId = context.select<PlayerViewModel, String?>(
      (p) => p.currentId,
    );
    final player = context.read<PlayerViewModel>();
    final navigation = context.read<NavigationController>();
    final playlist = library.playlistById(navigation.activePlaylistId);

    if (playlist == null) return SizedBox();

    final songs = playlist.songIds.map((id) => library.songById(id)).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 150),
      children: [
        _BackButton(onTap: navigation.backToPlaylists),
        SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _EditableCover(
              palette: _coverPalette(library, playlist),
              coverPath: playlist.coverPath,
              onTap: () => _pickCover(context, playlist.id),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'PLAYLIST',
                    style: AppTypography.bodyStyle(
                      size: 11,
                      weight: FontWeight.w700,
                      height: 1.2,
                      letterSpacing: 1.54,
                      color: context.colors.accent2_700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    playlist.name,
                    style: AppTypography.headingStyle(size: 30, height: 1.05),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${playlist.songCount} músicas',
                    style: AppTypography.bodyStyle(
                      size: 13,
                      color: context.colors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _PlayButton(onTap: () => player.playPlaylist(playlist)),
            ),
            SizedBox(width: 12),
            _ShuffleButton(
              onTap: () => player.playPlaylist(playlist, shuffle: true),
            ),
          ],
        ),
        SizedBox(height: 20),
        for (final song in songs)
          TrackTile(
            song: song,
            isCurrent: song.id == currentId,
            isFavorite: library.isFavorite(song.id),
            coverSize: 48,
            coverRadius: 12,
            glyphSize: 20,
            heartSize: 18,
            onTap: () => player.play(song.id),
            onToggleFavorite: () => UiUtils.toggleFavorite(context, song.id),
          ),
      ],
    );
  }

  static List<Color>? _coverPalette(LibraryStore library, Playlist p) {
    if (p.hasCoverSlot || p.songIds.isEmpty) return null;
    return library.songById(p.songIds.first).palette;
  }

  Future<void> _pickCover(BuildContext context, String playlistId) async {
    final picker = context.read<CoverImagePicker>();
    final library = context.read<LibraryStore>();
    final path = await picker.pickCover();
    if (path != null) library.setPlaylistCover(playlistId, path);
  }
}

/// Capa da playlist (120px) que abre o seletor de foto ao toque, com um selo
/// de câmera indicando que é editável — realiza o "image-slot" do design.
class _EditableCover extends StatelessWidget {
  const _EditableCover({
    required this.palette,
    required this.coverPath,
    required this.onTap,
  });

  final List<Color>? palette;
  final String? coverPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          CoverArtwork(
            palette: palette,
            imagePath: coverPath,
            size: 120,
            radius: 24,
            shadow: AppShadows.lg,
          ),
          Positioned(
            right: -4,
            bottom: -4,
            child: Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.accent2_500,
                shape: BoxShape.circle,
                border: Border.all(color: context.colors.bg, width: 3),
              ),
              child: Icon(
                Icons.photo_camera,
                size: 16,
                color: context.colors.bg,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: context.colors.surface,
        shape: CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: CircleBorder(),
          child: SizedBox(
            width: 38,
            height: 38,
            child: Icon(
              Icons.chevron_left,
              size: 22,
              color: context.colors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.accent2_500,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.play_arrow, size: 18, color: context.colors.bg),
              SizedBox(width: 8),
              Text(
                'Tocar',
                style: AppTypography.headingStyle(
                  size: 16,
                  color: context.colors.bg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShuffleButton extends StatelessWidget {
  const _ShuffleButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: context.colors.surface,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: SizedBox(
          width: 50,
          height: 50,
          child: Icon(
            Icons.shuffle,
            size: 20,
            color: context.colors.accent2_800,
          ),
        ),
      ),
    );
  }
}
