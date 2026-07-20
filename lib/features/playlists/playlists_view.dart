import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/playlist.dart';
import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cover_artwork.dart';
import '../navigation/navigation_controller.dart';

/// Tela "Playlists": botão de criar e a grade de coleções. Fiel ao bloco
/// PLAYLISTS do design.
class PlaylistsView extends StatelessWidget {
  const PlaylistsView({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final navigation = context.read<NavigationController>();
    final playlists = library.playlists;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 150),
      children: [
        Text('Playlists', style: AppTypography.headingStyle(size: 38)),
        SizedBox(height: 4),
        Text(
          'Suas coleções, do seu jeito.',
          style: AppTypography.bodyStyle(
            size: 14,
            color: context.colors.alpha(context.colors.text, 0.55),
          ),
        ),
        SizedBox(height: 22),
        _CreatePlaylistButton(onTap: navigation.openCreateSheet),
        SizedBox(height: 22),
        _PlaylistGrid(
          playlists: playlists,
          coverPaletteOf: (p) => _coverPalette(library, p),
          onOpen: navigation.openPlaylist,
        ),
      ],
    );
  }

  /// Capa da playlist: sálvia sólida quando tem slot próprio; senão, a paleta
  /// da primeira faixa. Porta a regra `coverBg` das playlists.
  static List<Color>? _coverPalette(LibraryStore library, Playlist p) {
    if (p.hasCoverSlot || p.songIds.isEmpty) return null;
    return library.songById(p.songIds.first).palette;
  }
}

class _CreatePlaylistButton extends StatelessWidget {
  const _CreatePlaylistButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: DottedBorderBox(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.accent2_500,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.add, size: 24, color: context.colors.bg),
              ),
              SizedBox(width: 12),
              Text(
                'Criar playlist',
                style: AppTypography.headingStyle(
                  size: 19,
                  color: context.colors.accent2_800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Caixa com borda tracejada e preenchimento sálvia claro (`border: 2px dashed`).
class DottedBorderBox extends StatelessWidget {
  const DottedBorderBox({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(context.colors.accent2_400),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: context.colors.accent2_100,
          borderRadius: BorderRadius.circular(28),
        ),
        child: child,
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  final Color color;
  _DashedBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(28),
    );
    final path = Path()..addRRect(rrect);
    const dash = 7.0;
    const gap = 5.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, distance + dash), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) => false;
}

class _PlaylistGrid extends StatelessWidget {
  const _PlaylistGrid({
    required this.playlists,
    required this.coverPaletteOf,
    required this.onOpen,
  });

  final List<Playlist> playlists;
  final List<Color>? Function(Playlist) coverPaletteOf;
  final void Function(String id) onOpen;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < playlists.length; i += 2) {
      final left = playlists[i];
      final right = i + 1 < playlists.length ? playlists[i + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(top: i == 0 ? 0 : 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _PlaylistCard(
                  playlist: left,
                  palette: coverPaletteOf(left),
                  onTap: () => onOpen(left.id),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: right == null
                    ? SizedBox()
                    : _PlaylistCard(
                        playlist: right,
                        palette: coverPaletteOf(right),
                        onTap: () => onOpen(right.id),
                      ),
              ),
            ],
          ),
        ),
      );
    }
    return Column(children: rows);
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({
    required this.playlist,
    required this.palette,
    required this.onTap,
  });

  final Playlist playlist;
  final List<Color>? palette;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: CoverArtwork(
              palette: palette,
              imagePath: playlist.coverPath,
              radius: 28,
              shadow: AppShadows.md,
            ),
          ),
          SizedBox(height: 9),
          Text(
            playlist.name,
            style: AppTypography.headingStyle(size: 17, height: 1.15),
          ),
          Text(
            '${playlist.songCount} músicas',
            style: AppTypography.bodyStyle(
              size: 12,
              color: context.colors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}