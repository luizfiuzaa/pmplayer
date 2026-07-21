import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/heart_button.dart';
import '../../core/widgets/marquee_text.dart';
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

    final palette = song.palette;
    final radius = BorderRadius.circular(20);

    // Cor de base da barra (média do gradiente ou o sólido). Se for escura, o
    // texto/ícones vão para uma cor clara de contraste, e vice-versa.
    final barBase = palette != null
        ? Color.lerp(palette.first, palette.last, 0.5)!
        : context.colors.accent2_800;
    final onBar = barBase.computeLuminance() < 0.42
        ? const Color(0xFFF6F2EC)
        : const Color(0xFF1B1A18);

    return Material(
      color: Colors.transparent,
      borderRadius: radius,
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.lg,
          // Cor da capa: mesmo gradiente da arte (topLeft→bottomRight, paleta
          // crua). Sem paleta (capa genérica/imagem) mantém o sólido do design.
          gradient: palette != null
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: palette,
                )
              : null,
          color: palette == null ? context.colors.accent2_800 : null,
        ),
        child: InkWell(
          onTap: navigation.openNowPlaying,
          borderRadius: radius,
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                SongCover(
                  song: song,
                  size: 44,
                  radius: 12,
                  glyphSize: 18,
                  glyphColor: onBar,
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      MarqueeText(
                        text: song.title,
                        enabled: player.isPlaying,
                        style: AppTypography.bodyStyle(
                          size: 14,
                          weight: FontWeight.w700,
                          height: 1.2,
                          color: onBar,
                        ),
                      ),
                      Text(
                        song.artist,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyStyle(
                          size: 11.5,
                          height: 1.3,
                          color: context.colors.alpha(onBar, 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
                HeartButton(
                  isFavorite: library.isFavorite(song.id),
                  onPressed: () => UiUtils.toggleFavorite(context, song.id),
                  size: 20,
                  unselectedColor: context.colors.alpha(onBar, 0.75),
                ),
                InkResponse(
                  onTap: player.togglePlay,
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(
                      player.isPlaying ? Icons.pause : Icons.play_arrow,
                      size: 24,
                      color: onBar,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
