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
    _reindex();
  }

  late final LibraryRepository? _repository;
  final List<Song> _songs;
  final List<String> _favoriteIds;
  final List<Playlist> _playlists;
  Map<String, Song> _byId = {};

  void _reindex() => _byId = {for (final s in _songs) s.id: s};

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
  bool isFavorite(String id) => _favoriteIds.contains(id);
  List<Song> get favoriteSongs => _favoriteIds.map((id) => _byId[id]!).toList();

  void toggleFavorite(String id) {
    if (!_favoriteIds.remove(id)) _favoriteIds.add(id);
    _repository?.setFavorite(id, _favoriteIds.contains(id));
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
