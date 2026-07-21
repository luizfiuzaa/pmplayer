import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/song.dart';
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

/// Mini-player fixo acima do menu inferior. Abre o player ao toque e
/// permite trocar de faixa arrastando para os lados (swipe left / right).
class MiniPlayer extends StatefulWidget {
  const MiniPlayer({super.key});

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  double _dragDelta = 0;

  @override
  Widget build(BuildContext context) {
    final song = context.select<PlayerViewModel, Song?>((p) => p.currentSong);
    final isPlaying = context.select<PlayerViewModel, bool>((p) => p.isPlaying);
    final player = context.read<PlayerViewModel>();
    final library = context.watch<LibraryStore>();
    final navigation = context.read<NavigationController>();
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

    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: radius,
          boxShadow: AppShadows.lg,
        ),
        child: ClipRRect(
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Material(
            color: Colors.transparent,
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: radius,
                gradient: palette != null
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: palette,
                      )
                    : null,
                color: palette == null ? context.colors.accent2_800 : null,
              ),
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragUpdate: (details) {
                  _dragDelta += details.primaryDelta ?? 0;
                },
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0;
                  if (_dragDelta < -30 || velocity < -150) {
                    player.next();
                  } else if (_dragDelta > 30 || velocity > 150) {
                    player.prev();
                  }
                  _dragDelta = 0;
                },
                onHorizontalDragCancel: () => _dragDelta = 0,
                child: InkWell(
                  onTap: navigation.openNowPlaying,
                  borderRadius: radius,
                  child: Container(
                    height: 60,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
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
                                enabled: isPlaying,
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
                          onPressed: () =>
                              UiUtils.toggleFavorite(context, song.id),
                          size: 20,
                          unselectedColor: context.colors.alpha(onBar, 0.75),
                        ),
                        InkResponse(
                          onTap: player.prev,
                          radius: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.skip_previous,
                              size: 22,
                              color: onBar,
                            ),
                          ),
                        ),
                        InkResponse(
                          onTap: player.togglePlay,
                          radius: 22,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              isPlaying ? Icons.pause : Icons.play_arrow,
                              size: 24,
                              color: onBar,
                            ),
                          ),
                        ),
                        InkResponse(
                          onTap: player.next,
                          radius: 20,
                          child: Padding(
                            padding: const EdgeInsets.all(4),
                            child: Icon(
                              Icons.skip_next,
                              size: 22,
                              color: onBar,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
