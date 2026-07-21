import 'package:flutter/material.dart';

/// Texto de uma linha que rola em looping (letreiro) quando não cabe na largura
/// disponível e [enabled] é `true` (ex.: enquanto a faixa toca). Se couber — ou
/// [enabled] for `false` — mostra o texto estático com reticências.
class MarqueeText extends StatefulWidget {
  const MarqueeText({
    super.key,
    required this.text,
    required this.style,
    this.enabled = true,
    this.gap = 48,
    this.velocity = 32,
  });

  final String text;
  final TextStyle style;

  /// Só rola quando `true` (e o texto transbordar).
  final bool enabled;

  /// Espaço entre o fim de uma cópia e o início da próxima.
  final double gap;

  /// Velocidade da rolagem em pixels por segundo.
  final double velocity;

  @override
  State<MarqueeText> createState() => _MarqueeTextState();
}

class _MarqueeTextState extends State<MarqueeText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _apply({required bool animate, required double total}) {
    if (!mounted) return;
    if (animate) {
      final seconds = (total / widget.velocity).clamp(3.0, 30.0);
      final duration = Duration(milliseconds: (seconds * 1000).round());
      if (_controller.duration != duration) {
        _controller.duration = duration;
        if (_controller.isAnimating) _controller.repeat();
      }
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating || _controller.value != 0) {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: widget.text, style: widget.style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout();
        final textWidth = painter.width;
        final overflow = textWidth > constraints.maxWidth + 0.5;
        final animate = overflow && widget.enabled;
        final total = textWidth + widget.gap;

        WidgetsBinding.instance.addPostFrameCallback(
          (_) => _apply(animate: animate, total: total),
        );

        if (!animate) {
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          );
        }

        final item = Text(
          widget.text,
          style: widget.style,
          maxLines: 1,
          softWrap: false,
        );

        return SizedBox(
          height: painter.height,
          child: ClipRect(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Transform.translate(
                  offset: Offset(-_controller.value * total, 0),
                  child: OverflowBox(
                    minWidth: 0,
                    maxWidth: double.infinity,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        item,
                        SizedBox(width: widget.gap),
                        item,
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
