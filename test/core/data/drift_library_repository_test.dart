import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/data/database/app_database.dart';
import 'package:pmplayer/core/data/drift_library_repository.dart';
import 'package:pmplayer/core/models/playlist.dart';
import 'package:pmplayer/core/models/song.dart';

void main() {
  late AppDatabase db;
  late DriftLibraryRepository repo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DriftLibraryRepository(db);
  });
  tearDown(() => db.close());

  test('banco novo carrega snapshot vazio', () async {
    final snapshot = await repo.load();
    expect(snapshot.songs, isEmpty);
    expect(snapshot.favoriteIds, isEmpty);
    expect(snapshot.playlists, isEmpty);
  });

  test('addSongs persiste e recarrega na ordem, com uri e paleta', () async {
    await repo.addSongs(const [
      Song(
        id: 'a',
        title: 'Uma',
        artist: 'X',
        durationSeconds: 100,
        uri: '/a.mp3',
        palette: [Color(0xFF112233), Color(0xFF445566)],
      ),
      Song(
        id: 'b',
        title: 'Duas',
        artist: 'Y',
        durationSeconds: 90,
        uri: '/b.mp3',
      ),
    ]);

    final snapshot = await repo.load();
    expect(snapshot.songs.map((s) => s.id), ['a', 'b']);
    expect(snapshot.songs.first.uri, '/a.mp3');
    expect(snapshot.songs.first.palette, const [
      Color(0xFF112233),
      Color(0xFF445566),
    ]);
    expect(snapshot.songs[1].isGeneric, isTrue);
  });

  test('addSongs não duplica ids repetidos', () async {
    const song = Song(
      id: 'a',
      title: 'Uma',
      artist: 'X',
      durationSeconds: 100,
      uri: '/a.mp3',
    );
    await repo.addSongs(const [song]);
    await repo.addSongs(const [song]);
    final snapshot = await repo.load();
    expect(snapshot.songs.length, 1);
  });

  test('setFavorite adiciona e remove, preservando a ordem', () async {
    await repo.setFavorite('s1', true);
    await repo.setFavorite('s3', true);
    await repo.setFavorite('s2', true);
    expect((await repo.load()).favoriteIds, ['s1', 's3', 's2']);

    await repo.setFavorite('s3', false);
    expect((await repo.load()).favoriteIds, ['s1', 's2']);
  });

  test('addPlaylist persiste nome, faixas e ordem', () async {
    await repo.addPlaylist(
      const Playlist(id: 'p1', name: 'Manhã', songIds: ['a', 'b']),
    );
    await repo.addPlaylist(
      const Playlist(id: 'p2', name: 'Noite', songIds: ['c']),
    );
    final playlists = (await repo.load()).playlists;
    expect(playlists.map((p) => p.id), ['p1', 'p2']);
    expect(playlists.first.name, 'Manhã');
    expect(playlists.first.songIds, ['a', 'b']);
  });

  test('addSongs persiste o caminho da capa (coverPath)', () async {
    await repo.addSongs(const [
      Song(
        id: 'a',
        title: 'Com capa',
        artist: 'X',
        durationSeconds: 100,
        uri: '/a.mp3',
        coverPath: '/capas/a.jpg',
      ),
    ]);
    expect((await repo.load()).songs.single.coverPath, '/capas/a.jpg');
  });

  test('setPlaylistCover define e limpa a foto da playlist', () async {
    await repo.addPlaylist(
      const Playlist(id: 'p1', name: 'Manhã', songIds: ['a']),
    );
    await repo.setPlaylistCover('p1', '/capas/p1.jpg');
    expect((await repo.load()).playlists.single.coverPath, '/capas/p1.jpg');

    await repo.setPlaylistCover('p1', null);
    expect((await repo.load()).playlists.single.coverPath, isNull);
  });
}
