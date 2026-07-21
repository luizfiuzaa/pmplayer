import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/song.dart';
import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/cover_artwork.dart';
import '../../core/widgets/marquee_text.dart';
import '../../core/widgets/music_glyph.dart';
import '../../core/widgets/scale_on_press.dart';
import '../navigation/navigation_controller.dart';
import '../playlists/add_to_playlist_sheet.dart';
import 'lyrics_artwork.dart';
import 'player_view_model.dart';
import '../../core/utils/ui_utils.dart';

/// Player em tela cheia. Fiel ao bloco NOW PLAYING do design.
class NowPlayingView extends StatelessWidget {
  const NowPlayingView({super.key});

  @override
  Widget build(BuildContext context) {
    final song = context.select<PlayerViewModel, Song?>((p) => p.currentSong);
    final contextLabel = context.select<PlayerViewModel, String>(
      (p) => p.contextLabel,
    );
    final isPlaying = context.select<PlayerViewModel, bool>((p) => p.isPlaying);
    final player = context.read<PlayerViewModel>();
    final library = context.watch<LibraryStore>();
    final navigation = context.read<NavigationController>();
    if (song == null) return SizedBox.shrink();

    final npFirst = song.palette?.first ?? context.colors.accent2_300;
    final topColor = Color.lerp(context.colors.bg, npFirst, 0.4)!;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [topColor, context.colors.bg],
          stops: const [0.0, 0.6],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(26, 8, 26, 20),
          child: Column(
            children: [
              _TopBar(
                contextLabel: contextLabel,
                onMinimize: navigation.minimize,
                onMore: () => AddToPlaylistSheet.show(context, song.id),
              ),
              SizedBox(height: 24),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 400),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  child: Center(
                    key: ValueKey(song.id),
                    child: LyricsArtwork(
                      song: song,
                      front: _Artwork(song: song, spinning: isPlaying),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 26),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                child: _TitleRow(
                  key: ValueKey(song.id),
                  song: song,
                  playing: isPlaying,
                  isFavorite: library.isFavorite(song.id),
                  onToggleFavorite: () =>
                      UiUtils.toggleFavorite(context, song.id),
                ),
              ),
              SizedBox(height: 22),
              Selector<PlayerViewModel, double>(
                selector: (_, p) => p.progressFraction,
                builder: (context, fraction, _) {
                  return _ProgressBar(
                    fraction: fraction,
                    durationSeconds: song.durationSeconds,
                    durationLabel: song.durationLabel,
                    onScrubStart: player.beginScrub,
                    onScrubEnd: player.endScrub,
                  );
                },
              ),
              SizedBox(height: 14),
              _Controls(player: player),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.contextLabel,
    required this.onMinimize,
    required this.onMore,
  });

  final String contextLabel;
  final VoidCallback onMinimize;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ScaleOnPress(
          onTap: onMinimize,
          child: Padding(
            padding: EdgeInsets.all(6),
            child: Icon(
              Icons.keyboard_arrow_down,
              size: 26,
              color: context.colors.text,
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
              color: context.colors.accent2_800,
            ),
          ),
        ),
        ScaleOnPress(
          onTap: onMore,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(Icons.more_horiz, size: 24, color: context.colors.text),
          ),
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
    return CoverArtwork(
      palette: song.palette,
      imagePath: song.coverPath,
      radius: 32,
      shadow: AppShadows.lg,
      child: song.isGeneric ? _SpinningDisc(spinning: spinning) : null,
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
          color: context.colors.alpha(context.colors.accent2_500, 0.3),
        ),
        child: MusicGlyph(
          size: 56,
          color: context.colors.accent2_800,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _TitleRow extends StatelessWidget {
  const _TitleRow({
    super.key,
    required this.song,
    required this.playing,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final Song song;
  final bool playing;
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
              MarqueeText(
                text: song.title,
                enabled: playing,
                style: AppTypography.headingStyle(size: 29, height: 1.08),
              ),
              SizedBox(height: 2),
              Text(
                song.artist,
                style: AppTypography.bodyStyle(
                  size: 15,
                  weight: FontWeight.w600,
                  color: context.colors.accent2_800,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        InkResponse(
          onTap: onToggleFavorite,
          radius: 28,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              size: 28,
              color: isFavorite
                  ? context.colors.accent
                  : context.colors.neutral500,
            ),
          ),
        ),
      ],
    );
  }
}

/// Barra de progresso com arrasto fluido: durante o gesto o polegar segue o
/// dedo localmente (sem reconstruir a tela toda nem falar com o engine a cada
/// frame). O áudio pausa em [onScrubStart] e retoma/posiciona em [onScrubEnd].
class _ProgressBar extends StatefulWidget {
  const _ProgressBar({
    required this.fraction,
    required this.durationSeconds,
    required this.durationLabel,
    required this.onScrubStart,
    required this.onScrubEnd,
  });

  final double fraction;
  final int durationSeconds;
  final String durationLabel;
  final VoidCallback onScrubStart;
  final ValueChanged<double> onScrubEnd;

  @override
  State<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends State<_ProgressBar> {
  double? _dragFraction;

  double get _effectiveFraction => _dragFraction ?? widget.fraction;

  void _start(double fraction) {
    widget.onScrubStart();
    setState(() => _dragFraction = fraction.clamp(0.0, 1.0));
  }

  void _move(double fraction) {
    setState(() => _dragFraction = fraction.clamp(0.0, 1.0));
  }

  void _end() {
    final fraction = _dragFraction;
    if (fraction != null) widget.onScrubEnd(fraction);
    setState(() => _dragFraction = null);
  }

  @override
  Widget build(BuildContext context) {
    final currentLabel = Song.formatSeconds(
      (_effectiveFraction * widget.durationSeconds).round(),
    );
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            double at(double dx) => (dx / width).clamp(0.0, 1.0);
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) => _start(at(d.localPosition.dx)),
              onTapUp: (_) => _end(),
              onTapCancel: _end,
              onHorizontalDragStart: (d) => _start(at(d.localPosition.dx)),
              onHorizontalDragUpdate: (d) => _move(at(d.localPosition.dx)),
              onHorizontalDragEnd: (_) => _end(),
              onHorizontalDragCancel: _end,
              child: SizedBox(
                height: 16,
                child: Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          color: context.colors.alpha(
                            context.colors.text,
                            0.15,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      FractionallySizedBox(
                        widthFactor: _effectiveFraction,
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: context.colors.accent2_700,
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      Positioned(
                        left: (width * _effectiveFraction) - 7,
                        top: -4,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: context.colors.accent2_800,
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
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              currentLabel,
              style: AppTypography.bodyStyle(
                size: 11.5,
                color: context.colors.neutral600,
              ),
            ),
            Text(
              widget.durationLabel,
              style: AppTypography.bodyStyle(
                size: 11.5,
                color: context.colors.neutral600,
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
    final isPlaying = context.select<PlayerViewModel, bool>((p) => p.isPlaying);
    final shuffle = context.select<PlayerViewModel, bool>((p) => p.shuffle);
    final repeat = context.select<PlayerViewModel, bool>((p) => p.repeat);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ScaleOnPress(
          onTap: player.toggleShuffle,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.shuffle,
              size: 24,
              color: shuffle
                  ? context.colors.accent2_700
                  : context.colors.neutral500,
            ),
          ),
        ),
        ScaleOnPress(
          onTap: player.prev,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(
              Icons.skip_previous,
              size: 34,
              color: context.colors.text,
            ),
          ),
        ),
        ScaleOnPress(
          onTap: player.togglePlay,
          child: Material(
            color: context.colors.accent2_700,
            shape: CircleBorder(),
            child: SizedBox(
              width: 78,
              height: 78,
              child: Icon(
                isPlaying ? Icons.pause : Icons.play_arrow,
                size: 34,
                color: context.colors.bg,
              ),
            ),
          ),
        ),
        ScaleOnPress(
          onTap: player.next,
          child: Padding(
            padding: EdgeInsets.all(8),
            child: Icon(Icons.skip_next, size: 34, color: context.colors.text),
          ),
        ),
        ScaleOnPress(
          onTap: player.toggleRepeat,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              Icons.repeat,
              size: 24,
              color: repeat
                  ? context.colors.accent2_700
                  : context.colors.neutral500,
            ),
          ),
        ),
      ],
    );
  }
}
