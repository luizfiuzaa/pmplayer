import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/song.dart';
import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cover_artwork.dart';
import '../../core/widgets/music_glyph.dart';
import '../navigation/navigation_controller.dart';
import 'player_view_model.dart';

/// Player em tela cheia. Fiel ao bloco NOW PLAYING do design.
class NowPlayingView extends StatelessWidget {
  const NowPlayingView({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerViewModel>();
    final library = context.watch<LibraryStore>();
    final navigation = context.read<NavigationController>();
    final song = player.currentSong;
    if (song == null) return const SizedBox.shrink();

    final npFirst = song.palette?.first ?? AppColors.accent2_300;
    final topColor = Color.lerp(AppColors.bg, npFirst, 0.4)!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, AppColors.bg],
          stops: const [0.0, 0.6],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 20),
          child: Column(
            children: [
              _TopBar(
                contextLabel: player.contextLabel,
                onMinimize: navigation.minimize,
              ),
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: _Artwork(song: song, spinning: player.isPlaying),
                ),
              ),
              const SizedBox(height: 26),
              _TitleRow(
                song: song,
                isFavorite: library.isFavorite(song.id),
                onToggleFavorite: () => library.toggleFavorite(song.id),
              ),
              const SizedBox(height: 22),
              _ProgressBar(
                fraction: player.progressFraction,
                currentLabel: Song.formatSeconds(player.progressSeconds),
                durationLabel: song.durationLabel,
                onSeek: player.seekToFraction,
              ),
              const SizedBox(height: 14),
              _Controls(player: player),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.contextLabel, required this.onMinimize});

  final String contextLabel;
  final VoidCallback onMinimize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkResponse(
          onTap: onMinimize,
          radius: 24,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 26,
              color: AppColors.text,
            ),
          ),
        ),
        Expanded(
          child: Text(
            contextLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.bodyStyle(
              size: 11,
              weight: FontWeight.w700,
              height: 1.2,
              letterSpacing: 1.54,
              color: AppColors.accent2_800,
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.all(6),
          child: Icon(Icons.more_horiz, size: 24, color: AppColors.text),
        ),
      ],
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.song, required this.spinning});

  final Song song;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: AspectRatio(
        aspectRatio: 1,
        child: CoverArtwork(
          palette: song.palette,
          imagePath: song.coverPath,
          radius: 32,
          shadow: AppShadows.lg,
          child: song.isGeneric ? _SpinningDisc(spinning: spinning) : null,
        ),
      ),
    );
  }
}

class _SpinningDisc extends StatefulWidget {
  const _SpinningDisc({required this.spinning});

  final bool spinning;

  @override
  State<_SpinningDisc> createState() => _SpinningDiscState();
}

class _SpinningDiscState extends State<_SpinningDisc>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 8),
  );

  @override
  void initState() {
    super.initState();
    if (widget.spinning) _controller.repeat();
  }

  @override
  void didUpdateWidget(_SpinningDisc old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.spinning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RotationTransition(
      turns: _controller,
      child: Container(
        width: 120,
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.alpha(AppColors.accent2_500, 0.3),
        ),
        child: const MusicGlyph(
          size: 56,
          color: AppColors.accent2_800,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    required this.song,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Song song;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.headingStyle(size: 29, height: 1.08),
              ),
              const SizedBox(height: 2),
              Text(
                song.artist,
                style: AppTypography.bodyStyle(
                  size: 15,
                  weight: FontWeight.w600,
                  color: AppColors.accent2_800,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        InkResponse(
          onTap: onToggleFavorite,
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 28,
              color: isFavorite ? AppColors.accent : AppColors.neutral500,
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.fraction,
    required this.currentLabel,
    required this.durationLabel,
    required this.onSeek,
  });

  final double fraction;
  final String currentLabel;
  final String durationLabel;
  final ValueChanged<double> onSeek;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            void seek(double dx) => onSeek((dx / width).clamp(0.0, 1.0));
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => seek(d.localPosition.dx),
              onHorizontalDragUpdate: (d) => seek(d.localPosition.dx),
              child: SizedBox(
                height: 16,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppColors.alpha(AppColors.text, 0.15),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: fraction,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: AppColors.accent2_700,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        left: (width * fraction) - 7,
                        top: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColors.accent2_800,
                            shape: BoxShape.circle,
                            boxShadow: AppShadows.sm,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentLabel,
              style: AppTypography.bodyStyle(
                size: 11.5,
                color: AppColors.neutral600,
              ),
            ),
            Text(
              durationLabel,
              style: AppTypography.bodyStyle(
                size: 11.5,
                color: AppColors.neutral600,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Controls extends StatelessWidget {
  const _Controls({required this.player});

  final PlayerViewModel player;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        InkResponse(
          onTap: player.toggleShuffle,
          radius: 24,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.shuffle,
              size: 24,
              color: player.shuffle
                  ? AppColors.accent2_700
                  : AppColors.neutral500,
            ),
          ),
        ),
        InkResponse(
          onTap: player.prev,
          radius: 26,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.skip_previous, size: 34, color: AppColors.text),
          ),
        ),
        Material(
          color: AppColors.accent2_700,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: player.togglePlay,
            customBorder: const CircleBorder(),
            child: SizedBox(
              width: 78,
              height: 78,
              child: Icon(
                player.isPlaying ? Icons.pause : Icons.play_arrow,
                size: 34,
                color: AppColors.bg,
              ),
            ),
          ),
        ),
        InkResponse(
          onTap: player.next,
          radius: 26,
          child: const Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.skip_next, size: 34, color: AppColors.text),
          ),
        ),
        InkResponse(
          onTap: player.toggleRepeat,
          radius: 24,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.repeat,
              size: 24,
              color: player.repeat
                  ? AppColors.accent2_700
                  : AppColors.neutral500,
            ),
          ),
        ),
      ],
    );
  }
}
