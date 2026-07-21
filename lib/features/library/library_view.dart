import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/library_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/skeleton.dart';
import '../../core/widgets/track_tile.dart';
import '../player/player_view_model.dart';
import 'import/music_importer.dart';
import '../../core/utils/ui_utils.dart';
import '../../core/widgets/scale_on_press.dart';
import '../settings/settings_sheet.dart';

/// Tela "Ouvir agora": cabeçalho, busca, ação de adicionar faixas, modo
/// aleatório e a lista de faixas. Fiel ao bloco LIBRARY do design.
class LibraryView extends StatefulWidget {
  const LibraryView({super.key});

  @override
  State<LibraryView> createState() => _LibraryViewState();
}

class _LibraryViewState extends State<LibraryView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  bool _importing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _import() async {
    final importer = context.read<MusicImporter>();
    final library = context.read<LibraryStore>();
    setState(() => _importing = true);
    try {
      // Adiciona em lotes conforme chegam: a lista cresce progressivamente em
      // vez de esperar tudo, sem travar a UI.
      await for (final chunk in importer.importChunked()) {
        if (!mounted) break;
        library.addSongs(chunk);
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryStore>();
    final player = context.watch<PlayerViewModel>();
    final songs = library.songs;
    final query = _query.trim();
    final searching = query.isNotEmpty;
    final results = searching ? LibraryStore.matching(songs, query) : songs;

    final headerRow = Row(
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
                    icon: Icon(
                      Icons.settings_outlined,
                      color: context.colors.neutral600,
                    ),
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
                  player.play(songs.first.id, label: 'Tocando da biblioteca');
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
    );

    final content = <Widget>[
      if (_importing) ...[
        Text('Adicionando músicas…', style: AppTypography.headingStyle(size: 22)),
        SizedBox(height: 10),
        // Faixas já lidas aparecem progressivamente; o skeleton indica o resto.
        for (final song in songs)
          TrackTile(
            song: song,
            isCurrent: song.id == player.currentId,
            isFavorite: library.isFavorite(song.id),
            showDuration: true,
            onTap: () => player.play(song.id),
            onToggleFavorite: () => UiUtils.toggleFavorite(context, song.id),
          ),
        if (songs.isNotEmpty) SizedBox(height: 8),
        const TrackListSkeleton(count: 3),
      ] else if (songs.isEmpty)
        _EmptyLibrary(onAdd: _import)
      else if (searching) ...[
        Row(
          children: [
            Text('Resultados', style: AppTypography.headingStyle(size: 22)),
            SizedBox(width: 8),
            Text(
              '${results.length}',
              style: AppTypography.bodyStyle(
                size: 12,
                color: context.colors.neutral600,
              ),
            ),
          ],
        ),
        SizedBox(height: 10),
        if (results.isEmpty)
          _NoResults(query: query)
        else
          for (final song in results)
            TrackTile(
              song: song,
              isCurrent: song.id == player.currentId,
              isFavorite: library.isFavorite(song.id),
              showDuration: true,
              onTap: () => player.play(song.id),
              onToggleFavorite: () => UiUtils.toggleFavorite(context, song.id),
            ),
      ] else ...[
        _ShuffleAllButton(count: songs.length, onTap: () => player.shuffleAll()),
        SizedBox(height: 26),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text('Todas as faixas', style: AppTypography.headingStyle(size: 22)),
            SizedBox(width: 8),
            Text(
              '${songs.length}',
              style: AppTypography.bodyStyle(
                size: 12,
                color: context.colors.neutral600,
              ),
            ),
            const Spacer(),
            _AddButton(onTap: _import),
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
    ];

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
          sliver: SliverToBoxAdapter(child: headerRow),
        ),
        // Search bar fixa no topo ao rolar a lista.
        SliverPersistentHeader(
          pinned: true,
          delegate: _StickySearchBar(
            child: _SearchField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              onClear: () => setState(() => _query = ''),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 150),
          sliver: SliverList(delegate: SliverChildListDelegate(content)),
        ),
      ],
    );
  }
}

/// Cabeçalho persistente (pinned) que mantém a barra de busca no topo, com
/// fundo opaco para a lista rolar por baixo.
class _StickySearchBar extends SliverPersistentHeaderDelegate {
  _StickySearchBar({required this.child});

  final Widget child;

  static const double _fieldHeight = 46;
  static const double _top = 12;
  static const double _bottom = 16;
  double get _extent => _fieldHeight + _top + _bottom;

  @override
  double get minExtent => _extent;
  @override
  double get maxExtent => _extent;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlaps) {
    return Container(
      color: context.colors.bg,
      padding: const EdgeInsets.fromLTRB(22, _top, 22, _bottom),
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant _StickySearchBar old) => true;
}

/// Campo de busca funcional: filtra a lista por título/artista.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      padding: const EdgeInsets.only(left: 16, right: 6),
      decoration: BoxDecoration(
        color: context.colors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.colors.divider),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 18, color: context.colors.neutral600),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textAlignVertical: TextAlignVertical.center,
              cursorColor: context.colors.accent,
              style: AppTypography.bodyStyle(size: 14),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                hintText: 'Buscar músicas e artistas',
                hintStyle: AppTypography.bodyStyle(
                  size: 14,
                  color: context.colors.neutral600,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.close, size: 18, color: context.colors.neutral600),
              splashRadius: 18,
              onPressed: () {
                controller.clear();
                onClear();
              },
            ),
        ],
      ),
    );
  }
}

/// Estado vazio de busca: nenhuma faixa casou com a query.
class _NoResults extends StatelessWidget {
  const _NoResults({required this.query});

  final String query;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Center(
        child: Text(
          'Nenhuma música encontrada para "$query".',
          textAlign: TextAlign.center,
          style: AppTypography.bodyStyle(color: context.colors.neutral600),
        ),
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