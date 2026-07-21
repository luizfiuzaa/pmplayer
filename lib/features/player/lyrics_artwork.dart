import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/models/lyrics.dart';
import '../../core/models/song.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_typography.dart';
import 'player_view_model.dart';

/// Capa "virável": um toque (ou arrasto horizontal) gira a arte para revelar a
/// letra da faixa no verso. No verso, um botão no canto superior direito
/// expande a letra em tela cheia (rolável) e um (X) volta ao quadrado.
class LyricsArtwork extends StatefulWidget {
  const LyricsArtwork({super.key, required this.front, required this.song});

  final Widget front;
  final Song song;

  @override
  State<LyricsArtwork> createState() => _LyricsArtworkState();
}

class _LyricsArtworkState extends State<LyricsArtwork>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flip = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 460),
  );

  @override
  void dispose() {
    _flip.dispose();
    super.dispose();
  }

  // Direção da rotação (+1 = para a direita, -1 = para a esquerda), seguindo o
  // sentido do arrasto.
  double _direction = 1;

  void _toggle([double direction = 1]) {
    setState(() => _direction = direction);
    if (_flip.value < 0.5) {
      _flip.forward();
    } else {
      _flip.reverse();
    }
  }

  void _openFull() {
    LyricsFullView.show(context, widget.song);
  }

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: AspectRatio(
        aspectRatio: 1,
        child: GestureDetector(
          onTap: () => _toggle(),
          onHorizontalDragEnd: (d) {
            final velocity = d.primaryVelocity ?? 0;
            // Arrastar para a esquerda gira para a esquerda; direita, direita.
            if (velocity.abs() > 120) _toggle(velocity < 0 ? -1 : 1);
          },
          child: AnimatedBuilder(
            animation: _flip,
            builder: (context, _) {
              final angle = _flip.value * math.pi * _direction;
              final showBack = _flip.value > 0.5;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0012)
                  ..rotateY(angle),
                child: showBack
                    ? Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()..rotateY(math.pi),
                        child: _LyricsFace(
                          song: widget.song,
                          onExpand: _openFull,
                        ),
                      )
                    : widget.front,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Verso quadrado com a letra rolável e o botão de expandir.
class _LyricsFace extends StatelessWidget {
  const _LyricsFace({required this.song, required this.onExpand});

  final Song song;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final lyrics = Lyrics.parse(song.lyrics);
    final hasLyrics = lyrics.isNotEmpty;
    return Container(
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(32),
        boxShadow: AppShadows.lg,
        border: Border.all(color: context.colors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(18, 12, 12, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'LETRA',
                style: AppTypography.bodyStyle(
                  size: 11,
                  weight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: context.colors.neutral600,
                ),
              ),
              const Spacer(),
              if (hasLyrics)
                _RoundIconButton(
                  icon: Icons.open_in_full,
                  tooltip: 'Expandir letra',
                  onTap: onExpand,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: hasLyrics
                ? SingleChildScrollView(
                    child: Text(
                      lyrics.plainText,
                      style: AppTypography.bodyStyle(
                        size: 14,
                        height: 1.6,
                        color: context.colors.text,
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      'Sem letra disponível',
                      style: AppTypography.bodyStyle(
                        color: context.colors.neutral500,
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onTap,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final button = Material(
      color: context.colors.alpha(context.colors.text, 0.06),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 18, color: context.colors.text),
        ),
      ),
    );
    return tooltip == null ? button : Tooltip(message: tooltip, child: button);
  }
}

/// Letra em tela cheia, rolável, sobre o gradiente do player. Quando a letra é
/// sincronizada (LRC), destaca a linha atual e rola sozinha acompanhando a
/// reprodução. (X) volta.
class LyricsFullView extends StatefulWidget {
  const LyricsFullView({super.key, required this.song});

  final Song song;

  static Future<void> show(BuildContext context, Song song) {
    return showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Letra',
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (_, _, _) => LyricsFullView(song: song),
      transitionBuilder: (_, animation, _, child) => FadeTransition(
        opacity: animation,
        child: child,
      ),
    );
  }

  @override
  State<LyricsFullView> createState() => _LyricsFullViewState();
}

class _LyricsFullViewState extends State<LyricsFullView> {
  late final Lyrics _lyrics = Lyrics.parse(widget.song.lyrics);
  final ScrollController _scroll = ScrollController();
  late final List<GlobalKey> _keys =
      List.generate(_lyrics.lines.length, (_) => GlobalKey());
  int _activeIndex = -1;

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _syncTo(int index) {
    if (index == _activeIndex) return;
    _activeIndex = index;
    if (index < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ctx = _keys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(
          ctx,
          alignment: 0.35,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final song = widget.song;
    final first = song.palette?.first ?? context.colors.accent2_300;
    final topColor = Color.lerp(context.colors.bg, first, 0.4)!;

    final int active;
    if (_lyrics.synced) {
      final position =
          context.select<PlayerViewModel, Duration>((p) => p.position);
      active = _lyrics.activeIndex(position);
      _syncTo(active);
    } else {
      active = -1;
    }

    return Material(
      color: context.colors.bg,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [topColor, context.colors.bg],
            stops: const [0.0, 0.55],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 12, 18, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                            style: AppTypography.headingStyle(size: 24),
                          ),
                          Text(
                            song.artist,
                            style: AppTypography.bodyStyle(
                              size: 14,
                              weight: FontWeight.w600,
                              color: context.colors.accent2_800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _RoundIconButton(
                      icon: Icons.close,
                      tooltip: 'Fechar',
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: _lyrics.isEmpty
                      ? Text(
                          'Sem letra disponível',
                          style: AppTypography.bodyStyle(
                            size: 18,
                            color: context.colors.neutral500,
                          ),
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.only(right: 8, bottom: 40),
                          itemCount: _lyrics.lines.length,
                          itemBuilder: (context, i) {
                            final line = _lyrics.lines[i];
                            final isActive = i == active;
                            final dim = active >= 0 && !isActive;
                            // Tocar em uma linha sincronizada pula para o seu
                            // instante na música.
                            final onTap = line.time != null
                                ? () => context
                                      .read<PlayerViewModel>()
                                      .seekTo(line.time!)
                                : null;
                            return InkWell(
                              key: _keys[i],
                              onTap: onTap,
                              borderRadius: BorderRadius.circular(10),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 7,
                                  horizontal: 4,
                                ),
                                // Transição suave ao avançar a letra: a linha
                                // ativa cresce/realça e as demais recuam.
                                child: AnimatedDefaultTextStyle(
                                  duration: const Duration(milliseconds: 320),
                                  curve: Curves.easeOutCubic,
                                  style: AppTypography.bodyStyle(
                                    size: isActive ? 21 : 18,
                                    weight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    height: 1.5,
                                    color: dim
                                        ? context.colors.alpha(
                                            context.colors.text, 0.4)
                                        : context.colors.text,
                                  ),
                                  child: Text(line.text),
                                ),
                              ),
                            );
                          },
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
