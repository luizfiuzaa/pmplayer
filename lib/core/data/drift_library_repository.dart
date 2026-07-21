import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/material.dart';

import '../models/playlist.dart';
import '../models/song.dart';
import 'database/app_database.dart';
import 'library_repository.dart';

/// Implementação do [LibraryRepository] sobre o banco SQLite (drift).
/// Faz inserções/remoções granulares; a ordem é preservada por `position`.
class DriftLibraryRepository implements LibraryRepository {
  DriftLibraryRepository(this._db);

  final AppDatabase _db;

  int _nextPosition() => DateTime.now().microsecondsSinceEpoch;

  @override
  Future<LibrarySnapshot> load() async {
    final songRows = await (_db.select(
      _db.songs,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    final favRows = await (_db.select(
      _db.favoriteSongs,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();
    final playlistRows = await (_db.select(
      _db.playlists,
    )..orderBy([(t) => OrderingTerm(expression: t.position)])).get();

    return LibrarySnapshot(
      songs: songRows.map(_toSong).toList(),
      favoriteIds: favRows.map((r) => r.songId).toList(),
      playlists: playlistRows.map(_toPlaylist).toList(),
    );
  }

  @override
  Future<void> addSongs(List<Song> songs) async {
    final base = _nextPosition();
    await _db.batch((batch) {
      for (var i = 0; i < songs.length; i++) {
        final song = songs[i];
        batch.insert(
          _db.songs,
          SongsCompanion.insert(
            id: song.id,
            title: song.title,
            artist: song.artist,
            durationSeconds: song.durationSeconds,
            uri: Value(song.uri),
            paletteJson: Value(_encodePalette(song.palette)),
            coverPath: Value(song.coverPath),
            lyrics: Value(song.lyrics),
            position: base + i,
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  @override
  Future<void> setFavorite(String songId, bool favorite) async {
    if (favorite) {
      await _db
          .into(_db.favoriteSongs)
          .insert(
            FavoriteSongsCompanion.insert(
              songId: songId,
              position: _nextPosition(),
            ),
            mode: InsertMode.insertOrReplace,
          );
    } else {
      await (_db.delete(
        _db.favoriteSongs,
      )..where((t) => t.songId.equals(songId))).go();
    }
  }

  @override
  Future<void> addPlaylist(Playlist playlist) async {
    await _db
        .into(_db.playlists)
        .insert(
          PlaylistsCompanion.insert(
            id: playlist.id,
            name: playlist.name,
            coverSlotId: Value(playlist.coverSlotId),
            coverPath: Value(playlist.coverPath),
            songIdsJson: jsonEncode(playlist.songIds),
            position: _nextPosition(),
          ),
          mode: InsertMode.insertOrReplace,
        );
  }

  @override
  Future<void> setPlaylistCover(String playlistId, String? coverPath) async {
    await (_db.update(_db.playlists)..where((t) => t.id.equals(playlistId)))
        .write(PlaylistsCompanion(coverPath: Value(coverPath)));
  }

  @override
  Future<void> setPlaylistSongs(String playlistId, List<String> songIds) async {
    await (_db.update(_db.playlists)..where((t) => t.id.equals(playlistId)))
        .write(PlaylistsCompanion(songIdsJson: Value(jsonEncode(songIds))));
  }

  // ── Mapeamento linha ⇄ modelo ────────────────────────────────────────────
  Song _toSong(SongRow row) => Song(
    id: row.id,
    title: row.title,
    artist: row.artist,
    durationSeconds: row.durationSeconds,
    uri: row.uri,
    palette: _decodePalette(row.paletteJson),
    coverPath: row.coverPath,
    lyrics: row.lyrics,
  );

  Playlist _toPlaylist(PlaylistRow row) => Playlist(
    id: row.id,
    name: row.name,
    coverSlotId: row.coverSlotId,
    coverPath: row.coverPath,
    songIds: (jsonDecode(row.songIdsJson) as List<dynamic>)
        .map((e) => e as String)
        .toList(),
  );

  String? _encodePalette(List<Color>? palette) => palette == null
      ? null
      : jsonEncode(palette.map((c) => c.toARGB32()).toList());

  List<Color>? _decodePalette(String? json) => json == null
      ? null
      : (jsonDecode(json) as List<dynamic>)
            .map((v) => Color(v as int))
            .toList();
}
