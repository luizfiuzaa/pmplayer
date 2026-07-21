import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/playlist.dart';
import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Sheet para adicionar/remover a faixa atual das playlists, com um checkbox
/// por playlist. A superfície é pintada no build para acompanhar o tema.
class AddToPlaylistSheet extends StatelessWidget {
  const AddToPlaylistSheet({super.key, required this.songId});

  final String songId;

  static Future<void> show(BuildContext context, String songId) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddToPlaylistSheet(songId: songId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final playlists = library.playlists;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.7;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                margin: const EdgeInsets.only(top: 14, bottom: 18),
                decoration: BoxDecoration(
                  color: context.colors.neutral400,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
              child: Text(
                'Adicionar a playlist',
                style: AppTypography.headingStyle(size: 22),
              ),
            ),
            if (playlists.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Text(
                  'Você ainda não tem playlists. Crie uma na aba Playlists.',
                  style: AppTypography.bodyStyle(color: context.colors.neutral600),
                ),
              )
            else
              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
                  shrinkWrap: true,
                  children: [
                    for (final playlist in playlists)
                      _PlaylistRow(
                        playlist: playlist,
                        checked: library.playlistHasSong(playlist.id, songId),
                        onTap: () =>
                            library.toggleSongInPlaylist(playlist.id, songId),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PlaylistRow extends StatelessWidget {
  const _PlaylistRow({
    required this.playlist,
    required this.checked,
    required this.onTap,
  });

  final Playlist playlist;
  final bool checked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.colors.accent2_100,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                Icons.queue_music,
                size: 22,
                color: context.colors.accent2_700,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    playlist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStyle(
                      size: 15,
                      weight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  Text(
                    '${playlist.songCount} músicas',
                    style: AppTypography.bodyStyle(
                      size: 12,
                      height: 1.3,
                      color: context.colors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _Checkbox(checked: checked),
          ],
        ),
      ),
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: checked ? context.colors.accent2_500 : Colors.transparent,
        border: Border.all(
          color: checked ? context.colors.accent2_500 : context.colors.neutral400,
          width: 2,
        ),
      ),
      child: checked
          ? Icon(Icons.check, size: 15, color: context.colors.bg)
          : null,
    );
  }
}
