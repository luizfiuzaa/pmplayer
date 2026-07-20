import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/track_tile.dart';
import '../player/player_view_model.dart';
import 'import/music_importer.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/scale_on_press.dart';
import '../settings/settings_sheet.dart';

/// Tela "Ouvir agora": cabeçalho, busca (decorativa), ação de adicionar faixas,
/// modo aleatório e a lista de todas as faixas. Fiel ao bloco LIBRARY do design.
class LibraryView extends StatelessWidget {
  const LibraryView({super.key});

  Future<void> _import(BuildContext context) async {
    final importer = context.read<MusicImporter>();
    final library = context.read<LibraryStore>();
    final songs = await importer.pickAndImport();
    if (songs.isNotEmpty) library.addSongs(songs);
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final player = context.watch<PlayerViewModel>();
    final songs = library.songs;

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 12, 22, 150),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        'Ouvir agora',
                        style: AppTypography.headingStyle(size: 38),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.settings_outlined, color: context.colors.neutral600),
                        onPressed: () => SettingsSheet.show(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            ScaleOnPress(
              onTap: songs.isEmpty
                  ? null
                  : () {
                      if (player.shuffle) player.toggleShuffle();
                      player.play(
                        songs.first.id,
                        label: 'Tocando da biblioteca',
                      );
                    },
              child: Material(
                color: context.colors.accent2_500,
                shape: CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: Container(
                  width: 46,
                  height: 46,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.play_arrow_rounded,
                    size: 28,
                    color: context.colors.bg,
                  ),
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: 20),
        const _SearchField(),
        SizedBox(height: 22),
        if (songs.isEmpty)
          _EmptyLibrary(onAdd: () => _import(context))
        else ...[
          _ShuffleAllButton(
            count: songs.length,
            onTap: () => player.shuffleAll(),
          ),
          SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Todas as faixas',
                style: AppTypography.headingStyle(size: 22),
              ),
              SizedBox(width: 8),
              Text(
                '${songs.length}',
                style: AppTypography.bodyStyle(
                  size: 12,
                  color: context.colors.neutral600,
                ),
              ),
              const Spacer(),
              _AddButton(onTap: () => _import(context)),
            ],
          ),
          SizedBox(height: 10),
          for (final song in songs)
            TrackTile(
              song: song,
              isCurrent: song.id == player.currentId,
              isFavorite: library.isFavorite(song.id),
              showDuration: true,
              onTap: () => player.play(song.id),
              onToggleFavorite: () => UiUtils.toggleFavorite(context, song.id),
            ),
        ],
      ],
    );
  }
}

/// Campo de busca do design — decorativo (o design não filtra a lista).
class _SearchField extends StatelessWidget {
  const _SearchField();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 16, right: 14),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: context.colors.neutral600),
          SizedBox(width: 10),
          Text(
            'Buscar músicas e artistas',
            style: AppTypography.bodyStyle(
              size: 14,
              color: context.colors.neutral600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Botão discreto para importar faixas, com a mesma linguagem do design.
class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleOnPress(
      onTap: onTap,
      child: Material(
        color: context.colors.accent2_100,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: context.colors.accent2_800),
              SizedBox(width: 6),
              Text(
                'Adicionar',
                style: AppTypography.bodyStyle(
                  size: 13,
                  weight: FontWeight.w700,
                  color: context.colors.accent2_800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ShuffleAllButton extends StatelessWidget {
  const _ShuffleAllButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ScaleOnPress(
      onTap: onTap,
      child: Material(
        color: context.colors.accent2_500,
        borderRadius: BorderRadius.circular(28),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.colors.alpha(Colors.white, 0.22),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.shuffle, size: 22, color: context.colors.bg),
              ),
              SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Modo aleatório',
                    style: AppTypography.headingStyle(
                      size: 19,
                      color: context.colors.bg,
                    ),
                  ),
                  Text(
                    '$count músicas na mistura',
                    style: AppTypography.bodyStyle(
                      size: 12.5,
                      height: 1.3,
                      color: context.colors.alpha(context.colors.bg, 0.85),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Estado vazio: nenhuma faixa importada ainda. Convida a adicionar arquivos.
class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.colors.accent2_100,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Icon(
              Icons.library_music_outlined,
              size: 34,
              color: context.colors.accent2_700,
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Sua biblioteca está vazia',
            style: AppTypography.headingStyle(size: 22),
          ),
          SizedBox(height: 6),
          Text(
            'Adicione arquivos de áudio do seu aparelho para começar a ouvir.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyStyle(color: context.colors.neutral600),
          ),
          SizedBox(height: 20),
          ScaleOnPress(
            onTap: onAdd,
            child: Material(
              color: context.colors.accent2_500,
              borderRadius: BorderRadius.circular(999),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add, size: 20, color: context.colors.bg),
                    SizedBox(width: 8),
                    Text(
                      'Adicionar músicas',
                      style: AppTypography.headingStyle(
                        size: 16,
                        color: context.colors.bg,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}