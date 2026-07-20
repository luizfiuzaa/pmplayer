import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/track_tile.dart';
import '../player/player_view_model.dart';

/// Tela "Favoritas": cabeçalho com o coração, botão Tocar e a lista de
/// favoritas (ou o estado vazio). Fiel ao bloco FAVORITES do design.
class FavoritesView extends StatelessWidget {
  const FavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final player = context.watch<PlayerViewModel>();
    final favorites = library.favoriteSongs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 150),
      children: [
        Row(
          children: [
            Container(
              width: 76,
              height: 76,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                boxShadow: AppShadows.md,
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.accent400, AppColors.accent700],
                ),
              ),
              child: const Icon(Icons.favorite, size: 34, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Favoritas', style: AppTypography.headingStyle(size: 32)),
                Text(
                  '${favorites.length} músicas curtidas',
                  style: AppTypography.bodyStyle(
                    size: 13,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerLeft,
          child: _PlayPill(onTap: () => player.playFavorites()),
        ),
        const SizedBox(height: 22),
        if (favorites.isEmpty)
          const _EmptyFavorites()
        else
          for (final song in favorites)
            TrackTile(
              song: song,
              isCurrent: song.id == player.currentId,
              isFavorite: library.isFavorite(song.id),
              onTap: () => player.play(song.id),
              onToggleFavorite: () => library.toggleFavorite(song.id),
            ),
      ],
    );
  }
}

class _PlayPill extends StatelessWidget {
  const _PlayPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent2_500,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.play_arrow, size: 18, color: AppColors.bg),
              const SizedBox(width: 8),
              Text(
                'Tocar',
                style: AppTypography.headingStyle(
                  size: 15,
                  color: AppColors.bg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
      child: Column(
        children: [
          Text(
            'Nada por aqui ainda',
            style: AppTypography.headingStyle(size: 19),
          ),
          const SizedBox(height: 6),
          Text(
            'Toque no coração de uma música para guardá-la.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyStyle(color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}
