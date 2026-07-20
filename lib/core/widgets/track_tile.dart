import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'heart_button.dart';
import 'song_cover.dart';

/// Linha de faixa reutilizável (Biblioteca, Favoritas, Detalhe da playlist).
/// A faixa em reprodução recebe o título em sálvia; a duração é opcional.
class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.song,
    required this.isCurrent,
    required this.isFavorite,
    required this.onTap,
    required this.onToggleFavorite,
    this.coverSize = 52,
    this.coverRadius = 13,
    this.glyphSize = 22,
    this.heartSize = 19,
    this.showDuration = false,
  });

  final Song song;
  final bool isCurrent;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;
  final double coverSize;
  final double coverRadius;
  final double glyphSize;
  final double heartSize;
  final bool showDuration;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            SongCover(
              song: song,
              size: coverSize,
              radius: coverRadius,
              glyphSize: glyphSize,
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    song.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStyle(
                      size: 15,
                      weight: FontWeight.w700,
                      height: 1.2,
                      color: isCurrent ? context.colors.accent2_700 : context.colors.text,
                    ),
                  ),
                  Text(
                    song.artist,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyStyle(
                      size: 12.5,
                      height: 1.3,
                      color: context.colors.neutral600,
                    ),
                  ),
                ],
              ),
            ),
            HeartButton(
              isFavorite: isFavorite,
              onPressed: onToggleFavorite,
              size: heartSize,
            ),
            if (showDuration)
              SizedBox(
                width: 38,
                child: Text(
                  song.durationLabel,
                  textAlign: TextAlign.right,
                  style: AppTypography.bodyStyle(
                    size: 12,
                    color: context.colors.neutral500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
