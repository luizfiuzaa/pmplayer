import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/heart_button.dart';
import '../../core/widgets/song_cover.dart';
import '../navigation/navigation_controller.dart';
import 'player_view_model.dart';
import '../../core/utils/ui_utils.dart';

/// Mini-player fixo acima do menu inferior. Abre o player ao toque.
/// Fiel ao bloco MINI-PLAYER do design.
class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerViewModel>();
    final library = context.watch<LibraryStore>();
    final navigation = context.read<NavigationController>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    return Material(
      color: AppColors.accent2_800,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: navigation.openNowPlaying,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 60,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppShadows.lg,
          ),
          child: Row(
            children: [
              SongCover(
                song: song,
                size: 44,
                radius: 12,
                glyphSize: 18,
                glyphColor: AppColors.accent2_100,
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      song.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStyle(
                        size: 14,
                        weight: FontWeight.w700,
                        height: 1.2,
                        color: AppColors.bg,
                      ),
                    ),
                    Text(
                      song.artist,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyStyle(
                        size: 11.5,
                        height: 1.3,
                        color: AppColors.alpha(AppColors.bg, 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              HeartButton(
                isFavorite: library.isFavorite(song.id),
                onPressed: () => UiUtils.toggleFavorite(context, song.id),
                size: 20,
              ),
              InkResponse(
                onTap: player.togglePlay,
                radius: 22,
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Icon(
                    player.isPlaying ? Icons.pause : Icons.play_arrow,
                    size: 24,
                    color: AppColors.bg,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
