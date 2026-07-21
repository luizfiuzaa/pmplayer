import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Aplica um brilho deslizante (shimmer) sobre os [child] cinzas do esqueleto.
/// Envolve várias caixas para que uma única onda percorra o grupo todo.
class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key, required this.child});

  final Widget child;

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = context.colors.alpha(context.colors.text, 0.08);
    final highlight = context.colors.alpha(context.colors.text, 0.16);
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: const [0.1, 0.5, 0.9],
            transform: _SlideTransform(_controller.value),
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Desloca o gradiente da esquerda para a direita conforme [progress] (0→1).
class _SlideTransform extends GradientTransform {
  const _SlideTransform(this.progress);

  final double progress;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final dx = (progress * 2 - 1) * bounds.width;
    return Matrix4.translationValues(dx, 0, 0);
  }
}

/// Caixa base do esqueleto (retângulo arredondado sólido).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 12,
    this.radius = 8,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.text,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Linha placeholder no formato de um item de faixa (capa + título + artista).
class TrackTileSkeleton extends StatelessWidget {
  const TrackTileSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          const SkeletonBox(width: 48, height: 48, radius: 12),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 160, height: 13),
                SizedBox(height: 8),
                SkeletonBox(width: 90, height: 11),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const SkeletonBox(width: 30, height: 11),
        ],
      ),
    );
  }
}

/// Lista de linhas-esqueleto com o shimmer, para estados de carregamento.
class TrackListSkeleton extends StatelessWidget {
  const TrackListSkeleton({super.key, this.count = 7});

  final int count;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Column(
        children: [for (var i = 0; i < count; i++) const TrackTileSkeleton()],
      ),
    );
  }
}
