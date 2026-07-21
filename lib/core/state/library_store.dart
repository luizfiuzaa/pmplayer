import 'package:flutter/foundation.dart';

import '../data/library_repository.dart';
import '../models/playlist.dart';
import '../models/song.dart';

/// Estado compartilhado do acervo: faixas, favoritas e playlists.
///
/// Construído a partir de um [LibrarySnapshot] e, quando um [LibraryRepository]
/// é fornecido, persiste cada mutação. Espelha a parte de dados do `state`.
class LibraryStore extends ChangeNotifier {
  LibraryStore({
    required LibrarySnapshot initial,
    LibraryRepository? repository,
  }) : _songs = List.of(initial.songs),
       _favoriteIds = List.of(initial.favoriteIds),
       _playlists = List.of(initial.playlists) {
    _repository = repository;
    _favoriteIdsSet = Set.of(_favoriteIds);
    _reindex();
  }

  late final LibraryRepository? _repository;
  final List<Song> _songs;
  final List<String> _favoriteIds;
  late final Set<String> _favoriteIdsSet;
  final List<Playlist> _playlists;
  Map<String, Song> _byId = {};

  void _reindex() => _byId = {for (final s in _songs) s.id: s};

  static final Map<int, String> _foldMap = {
    for (final c in 'áàâãäÁÀÂÃÄ'.codeUnits) c: 'a',
    for (final c in 'éèêëÉÈÊË'.codeUnits) c: 'e',
    for (final c in 'íìîïÍÌÎÏ'.codeUnits) c: 'i',
    for (final c in 'óòôõöÓÒÔÕÖ'.codeUnits) c: 'o',
    for (final c in 'úùûüÚÙÛÜ'.codeUnits) c: 'u',
    for (final c in 'çÇ'.codeUnits) c: 'c',
    for (final c in 'ñÑ'.codeUnits) c: 'n',
  };

  /// Filtra [songs] por título ou artista, ignorando maiúsculas e acentos.
  /// Query vazia devolve a lista intacta. Função pura e otimizada de alta performance.
  static List<Song> matching(List<Song> songs, String query) {
    final q = _fold(query);
    if (q.isEmpty) return List.of(songs);
    return songs
        .where((s) => _fold(s.title).contains(q) || _fold(s.artist).contains(q))
        .toList();
  }

  static String _fold(String value) {
    if (value.isEmpty) return '';
    final buffer = StringBuffer();
    final lower = value.trim().toLowerCase();
    for (final codeUnit in lower.codeUnits) {
      final replacement = _foldMap[codeUnit];
      if (replacement != null) {
        buffer.write(replacement);
      } else {
        buffer.writeCharCode(codeUnit);
      }
    }
    return buffer.toString();
  }

  // ── Faixas ─────────────────────────────────────────────────────────────
  List<Song> get songs => List.unmodifiable(_songs);
  List<String> get allSongIds => _songs.map((s) => s.id).toList();
  bool get hasSongs => _songs.isNotEmpty;
  Song songById(String id) => _byId[id]!;
  Song? songByIdOrNull(String id) => _byId[id];

  /// Anexa faixas importadas (ignora ids já presentes), notifica e persiste.
  void addSongs(List<Song> songs) {
    final added = <Song>[];
    for (final song in songs) {
      if (_byId.containsKey(song.id)) continue;
      _songs.add(song);
      _byId[song.id] = song;
      added.add(song);
    }
    if (added.isEmpty) return;
    _repository?.addSongs(added);
    notifyListeners();
  }

  // ── Favoritas ──────────────────────────────────────────────────────────
  List<String> get favoriteIds => List.unmodifiable(_favoriteIds);
  bool isFavorite(String id) => _favoriteIdsSet.contains(id);
  List<Song> get favoriteSongs => _favoriteIds.map((id) => _byId[id]!).toList();

  void toggleFavorite(String id) {
    if (_favoriteIdsSet.contains(id)) {
      _favoriteIdsSet.remove(id);
      _favoriteIds.remove(id);
      _repository?.setFavorite(id, false);
    } else {
      _favoriteIdsSet.add(id);
      _favoriteIds.add(id);
      _repository?.setFavorite(id, true);
    }
    notifyListeners();
  }

  // ── Playlists ──────────────────────────────────────────────────────────
  List<Playlist> get playlists => List.unmodifiable(_playlists);
  Playlist? playlistById(String id) {
    for (final p in _playlists) {
      if (p.id == id) return p;
    }
    return null;
  }

  void createPlaylist(String name, List<String> songIds) {
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    final playlist = Playlist(id: id, name: name, songIds: List.of(songIds));
    _playlists.add(playlist);
    _repository?.addPlaylist(playlist);
    notifyListeners();
  }

  /// Se a faixa está na playlist.
  bool playlistHasSong(String playlistId, String songId) {
    final playlist = playlistById(playlistId);
    return playlist != null && playlist.songIds.contains(songId);
  }

  /// Adiciona (no fim) ou remove a faixa da playlist, persiste e notifica.
  void toggleSongInPlaylist(String playlistId, String songId) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final current = _playlists[index];
    final songIds = List<String>.of(current.songIds);
    if (!songIds.remove(songId)) songIds.add(songId);
    _playlists[index] = current.copyWith(songIds: songIds);
    _repository?.setPlaylistSongs(playlistId, songIds);
    notifyListeners();
  }

  /// Define (ou limpa) a foto de capa de uma playlist.
  void setPlaylistCover(String playlistId, String? coverPath) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final current = _playlists[index];
    _playlists[index] = Playlist(
      id: current.id,
      name: current.name,
      songIds: current.songIds,
      coverSlotId: current.coverSlotId,
      coverPath: coverPath,
    );
    _repository?.setPlaylistCover(playlistId, coverPath);
    notifyListeners();
  }
}
