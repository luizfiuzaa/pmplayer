import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/data/library_repository.dart';
import 'package:pmplayer/core/data/sample_music_repository.dart';
import 'package:pmplayer/core/models/playlist.dart';
import 'package:pmplayer/core/models/song.dart';
import 'package:pmplayer/core/state/library_store.dart';

/// Repositório em memória que registra as chamadas granulares.
class RecordingRepository implements LibraryRepository {
  final List<Song> addedSongs = [];
  final Map<String, bool> favorites = {};
  final List<Playlist> addedPlaylists = [];

  @override
  Future<LibrarySnapshot> load() async => const LibrarySnapshot();
  @override
  Future<void> addSongs(List<Song> songs) async => addedSongs.addAll(songs);
  @override
  Future<void> setFavorite(String songId, bool favorite) async =>
      favorites[songId] = favorite;
  @override
  Future<void> addPlaylist(Playlist playlist) async =>
      addedPlaylists.add(playlist);
  final Map<String, String?> playlistCovers = {};
  @override
  Future<void> setPlaylistCover(String playlistId, String? coverPath) async =>
      playlistCovers[playlistId] = coverPath;
  final Map<String, List<String>> playlistSongs = {};
  @override
  Future<void> setPlaylistSongs(String playlistId, List<String> songIds) async =>
      playlistSongs[playlistId] = songIds;
}

LibraryStore buildStore([LibraryRepository? repo]) =>
    LibraryStore(initial: SampleMusicRepository().snapshot(), repository: repo);

void main() {
  group('favoritas', () {
    test('parte das favoritas do snapshot', () {
      final store = buildStore();
      expect(store.favoriteIds, ['s1', 's4', 's7']);
      expect(store.isFavorite('s1'), isTrue);
    });

    test('desfavoritar remove a faixa', () {
      final store = buildStore();
      store.toggleFavorite('s1');
      expect(store.favoriteIds, ['s4', 's7']);
    });

    test('favoritar adiciona ao fim', () {
      final store = buildStore();
      store.toggleFavorite('s2');
      expect(store.favoriteIds, ['s1', 's4', 's7', 's2']);
    });

    test('persiste ao alternar favorita', () {
      final repo = RecordingRepository();
      buildStore(repo).toggleFavorite('s2');
      expect(repo.favorites['s2'], isTrue);
    });
  });

  group('busca (matching)', () {
    final songs = [
      const Song(id: 'a', title: 'Maré Cheia', artist: 'João Silva', durationSeconds: 1),
      const Song(id: 'b', title: 'Terra Vermelha', artist: 'Ana', durationSeconds: 1),
      const Song(id: 'c', title: 'Sol', artist: 'JOÃO Pereira', durationSeconds: 1),
    ];

    test('query vazia devolve tudo', () {
      expect(LibraryStore.matching(songs, '').length, 3);
      expect(LibraryStore.matching(songs, '   ').length, 3);
    });

    test('casa por título, ignorando caixa', () {
      final r = LibraryStore.matching(songs, 'TERRA');
      expect(r.map((s) => s.id), ['b']);
    });

    test('casa por artista, ignorando acento', () {
      final r = LibraryStore.matching(songs, 'joao');
      expect(r.map((s) => s.id), ['a', 'c']);
    });

    test('casa acento na query contra texto sem acento e vice-versa', () {
      final r = LibraryStore.matching(songs, 'maré');
      expect(r.map((s) => s.id), ['a']);
    });

    test('sem correspondência devolve vazio', () {
      expect(LibraryStore.matching(songs, 'zzz'), isEmpty);
    });
  });

  group('playlists', () {
    test('criar playlist anexa e persiste', () {
      final repo = RecordingRepository();
      final store = buildStore(repo);
      store.createPlaylist('Nova', ['s2', 's3']);
      expect(store.playlists.last.name, 'Nova');
      expect(repo.addedPlaylists.last.name, 'Nova');
    });

    test('playlistHasSong reflete o conteúdo', () {
      final store = buildStore();
      final p = store.playlists.first; // p1 = [s6, s4, s1, s10]
      expect(store.playlistHasSong(p.id, 's4'), isTrue);
      expect(store.playlistHasSong(p.id, 's2'), isFalse);
    });

    test('toggle adiciona faixa ausente, no fim, e persiste', () {
      final repo = RecordingRepository();
      final store = buildStore(repo);
      final id = store.playlists.first.id;
      store.toggleSongInPlaylist(id, 's2');
      expect(store.playlistHasSong(id, 's2'), isTrue);
      expect(store.playlistById(id)!.songIds.last, 's2');
      expect(repo.playlistSongs[id]!.last, 's2');
    });

    test('toggle remove faixa presente e persiste', () {
      final repo = RecordingRepository();
      final store = buildStore(repo);
      final id = store.playlists.first.id;
      store.toggleSongInPlaylist(id, 's4');
      expect(store.playlistHasSong(id, 's4'), isFalse);
      expect(repo.playlistSongs[id], isNot(contains('s4')));
    });

    test('toggle em playlist inexistente não quebra', () {
      final store = buildStore();
      store.toggleSongInPlaylist('nao-existe', 's1');
      expect(store.playlistById('nao-existe'), isNull);
    });
  });

  group('importar faixas', () {
    test('addSongs anexa novas faixas, notifica e persiste', () {
      final repo = RecordingRepository();
      final store = LibraryStore(
        initial: const LibrarySnapshot(),
        repository: repo,
      );
      var notified = 0;
      store.addListener(() => notified++);

      store.addSongs(const [
        Song(
          id: 'f1',
          title: 'Uma',
          artist: 'X',
          durationSeconds: 100,
          uri: '/1.mp3',
        ),
      ]);

      expect(store.songs.map((s) => s.id), ['f1']);
      expect(notified, 1);
      expect(repo.addedSongs.single.uri, '/1.mp3');
    });

    test('addSongs ignora faixas com id já existente', () {
      final store = LibraryStore(initial: const LibrarySnapshot());
      const song = Song(
        id: 'f1',
        title: 'Uma',
        artist: 'X',
        durationSeconds: 100,
        uri: '/1.mp3',
      );
      store.addSongs(const [song]);
      store.addSongs(const [song]);
      expect(store.songs.length, 1);
    });

    test('biblioteca começa vazia sem faixas', () {
      final store = LibraryStore(initial: const LibrarySnapshot());
      expect(store.songs, isEmpty);
      expect(store.hasSongs, isFalse);
    });
  });

  group('capa de playlist', () {
    test('setPlaylistCover atualiza a playlist, persiste e notifica', () {
      final repo = RecordingRepository();
      final store = LibraryStore(
        initial: const LibrarySnapshot(
          playlists: [
            Playlist(id: 'p1', name: 'Manhã', songIds: ['a']),
          ],
        ),
        repository: repo,
      );
      var notified = 0;
      store.addListener(() => notified++);

      store.setPlaylistCover('p1', '/capas/p1.jpg');

      expect(store.playlistById('p1')!.coverPath, '/capas/p1.jpg');
      expect(repo.playlistCovers['p1'], '/capas/p1.jpg');
      expect(notified, 1);
    });
  });
}
