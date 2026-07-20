import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Desenha uma capa. Prioridade: imagem de arquivo (arte real) → gradiente da
/// paleta + brilho radial → preenchimento sálvia sólido (genérica).
/// Porta `coverBg()` do design e realiza o "image-slot".
class CoverArtwork extends StatelessWidget {
  const CoverArtwork({
    super.key,
    required this.palette,
    required this.radius,
    this.imagePath,
    this.size,
    this.shadow,
    this.child,
  });

  /// Par de cores da capa; `null` = capa sólida (`--color-accent-2-200`).
  final List<Color>? palette;

  /// Caminho de uma imagem local; quando presente, tem prioridade.
  final String? imagePath;

  /// Lado do quadrado; `null` preenche o espaço disponível (ex.: grade).
  final double? size;
  final double radius;
  final List<BoxShadow>? shadow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final hasImage = imagePath != null;
    final generic = palette == null;
    final borderRadius = BorderRadius.circular(radius);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: shadow,
        color: hasImage || !generic ? null : context.colors.accent2_200,
        gradient: hasImage || generic
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: palette!,
              ),
        image: hasImage
            ? DecorationImage(
                image: FileImage(File(imagePath!)),
                fit: BoxFit.cover,
              )
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (!hasImage && !generic)
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment(-0.4, -0.56),
                    radius: 0.9,
                    colors: [Color(0x6BFFFFFF), Color(0x00FFFFFF)],
                    stops: [0.0, 0.58],
                  ),
                ),
              ),
            if (!hasImage && child != null) Center(child: child),
          ],
        ),
      ),
    );
  }
}
