import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import 'cover_artwork.dart';
import 'music_glyph.dart';

/// Capa de uma faixa: gradiente da paleta ou capa sálvia com o glifo de música
/// (para faixas genéricas).
class SongCover extends StatelessWidget {
  const SongCover({
    super.key,
    required this.song,
    this.size = 56,
    this.radius = 8,
    this.glyphSize = 24,
    this.glyphColor,
    this.shadow,
  });

  final Song song;
  final double size;
  final double radius;
  final double glyphSize;
  final Color? glyphColor;
  final List<BoxShadow>? shadow;

  @override
  Widget build(BuildContext context) {
    return CoverArtwork(
      palette: song.palette,
      imagePath: song.coverPath,
      size: size,
      radius: radius,
      shadow: shadow,
      child: song.isGeneric
          ? MusicGlyph(
              size: glyphSize, 
              color: glyphColor ?? AppColors.light.accent2_700,
            )
          : null,
    );
  }
}
