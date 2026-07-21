import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/data/library_repository.dart';
import 'package:pmplayer/core/data/sample_music_repository.dart';
import 'package:pmplayer/core/models/song.dart';
import 'package:pmplayer/core/playback/audio_engine.dart';
import 'package:pmplayer/core/state/library_store.dart';
import 'package:pmplayer/features/navigation/navigation_controller.dart';
import 'package:pmplayer/features/player/player_view_model.dart';

/// Engine de áudio falso: registra chamadas e permite emitir posição/fim.
class FakeAudioEngine implements AudioEngine {
  final _position = StreamController<Duration>.broadcast();
  final _completed = StreamController<void>.broadcast();
  final _remote = StreamController<PlayerRemoteAction>.broadcast();
  String? loadedUri;
  bool playing = false;
  Duration? lastSeek;
  int loadCount = 0;
  bool? shuffleActive;

  @override
  Future<Duration?> load(Song song) async {
    loadedUri = song.uri;
    loadCount++;
    return const Duration(seconds: 200);
  }

  @override
  Future<void> play() async => playing = true;
  @override
  Future<void> pause() async => playing = false;
  @override
  Future<void> seek(Duration position) async => lastSeek = position;
  @override
  Stream<Duration> get positionStream => _position.stream;
  @override
  Stream<void> get onCompleted => _completed.stream;
  @override
  Stream<PlayerRemoteAction> get remoteActions => _remote.stream;
  @override
  void setShuffleActive(bool value) => shuffleActive = value;
  @override
  Future<void> dispose() async {}

  void emitPosition(int seconds) => _position.add(Duration(seconds: seconds));
  void emitCompleted() => _completed.add(null);
  void emitRemote(PlayerRemoteAction action) => _remote.add(action);
}

/// Snapshot com faixas que têm arquivo (uri), preservando ids/playlists/favoritas.
LibrarySnapshot snapshotWithFiles() {
  final sample = SampleMusicRepository();
  return LibrarySnapshot(
    songs: [
      for (final s in sample.songs())
        Song(
          id: s.id,
          title: s.title,
          artist: s.artist,
          durationSeconds: s.durationSeconds,
          palette: s.palette,
          uri: '/music/${s.id}.mp3',
        ),
    ],
    favoriteIds: sample.initialFavoriteIds(),
    playlists: sample.playlists(),
  );
}

class Harness {
  Harness({int seed = 1, LibrarySnapshot? snapshot}) {
    library = LibraryStore(initial: snapshot ?? snapshotWithFiles());
    navigation = NavigationController();
    engine = FakeAudioEngine();
    player = PlayerViewModel(
      library: library,
      navigation: navigation,
      engine: engine,
      random: Random(seed),
    );
  }
  late final LibraryStore library;
  late final NavigationController navigation;
  late final FakeAudioEngine engine;
  late final PlayerViewModel player;
}

void main() {
  group('estado inicial', () {
    test('com faixas, aponta para a primeira, parado no início', () {
      final h = Harness();
      expect(h.player.currentId, 's1');
      expect(h.player.progressSeconds, 0);
      expect(h.player.isPlaying, isFalse);
      expect(h.player.hasCurrent, isTrue);
      expect(h.player.order, h.library.allSongIds);
    });

    test('biblioteca vazia não tem faixa atual', () {
      final h = Harness(snapshot: const LibrarySnapshot());
      expect(h.player.hasCurrent, isFalse);
      expect(h.player.currentSong, isNull);
    });
  });

  group('play', () {
    test('carrega o arquivo, toca e abre o player', () {
      final h = Harness();
      h.player.play('s5');
      expect(h.player.currentId, 's5');
      expect(h.player.isPlaying, isTrue);
      expect(h.engine.loadedUri, '/music/s5.mp3');
      expect(h.engine.playing, isTrue);
      expect(h.navigation.screen, AppScreen.nowPlaying);
    });
  });

  group('togglePlay', () {
    test('a partir de parado, carrega a atual e toca', () {
      final h = Harness();
      h.player.togglePlay();
      expect(h.player.isPlaying, isTrue);
      expect(h.engine.loadedUri, '/music/s1.mp3');
      expect(h.engine.playing, isTrue);
    });

    test('tocando, pausa sem recarregar', () {
      final h = Harness();
      h.player.play('s1');
      h.player.togglePlay();
      expect(h.player.isPlaying, isFalse);
      expect(h.engine.playing, isFalse);
    });
  });

  group('next / prev', () {
    test('next avança na ordem e recarrega', () {
      final h = Harness();
      h.player.play('s1');
      h.player.next();
      expect(h.player.currentId, 's2');
      expect(h.engine.loadedUri, '/music/s2.mp3');
    });

    test('next dá a volta no fim', () {
      final h = Harness();
      h.player.play('s10');
      h.player.next();
      expect(h.player.currentId, 's1');
    });

    test('prev reinicia a faixa quando passou de 3s', () async {
      final h = Harness();
      h.player.play('s5');
      h.engine.emitPosition(120);
      await Future<void>.delayed(Duration.zero);
      h.player.prev();
      expect(h.player.currentId, 's5');
      expect(h.player.progressSeconds, 0);
      expect(h.engine.lastSeek, Duration.zero);
    });

    test('prev vai à anterior quando no começo', () {
      final h = Harness();
      h.player.play('s5');
      h.player.prev();
      expect(h.player.currentId, 's4');
    });
  });

  group('shuffle / repeat', () {
    test('shuffle mantém a atual em primeiro', () {
      final h = Harness();
      h.player.play('s1');
      h.player.toggleShuffle();
      expect(h.player.order.first, 's1');
      expect(h.player.order.toSet(), h.library.allSongIds.toSet());
    });

    test('desligar shuffle restaura a ordem base', () {
      final h = Harness();
      h.player.toggleShuffle();
      h.player.toggleShuffle();
      expect(h.player.order, h.library.allSongIds);
    });

    test('repeat alterna', () {
      final h = Harness();
      h.player.toggleRepeat();
      expect(h.player.repeat, isTrue);
    });
  });

  group('seek e progresso', () {
    test('a posição do engine dirige o progresso', () async {
      final h = Harness();
      h.player.play('s1');
      h.engine.emitPosition(42);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.progressSeconds, 42);
    });

    test('seekToFraction posiciona o engine e o progresso', () {
      final h = Harness();
      h.player.play('s1'); // dur 214
      h.player.seekToFraction(0.5);
      expect(h.player.progressSeconds, 107);
      expect(h.player.position, const Duration(seconds: 107));
      expect(h.engine.lastSeek, const Duration(seconds: 107));
    });

    test('seekTo posiciona o engine, progresso e position', () {
      final h = Harness();
      h.player.play('s1'); // dur 214
      h.player.seekTo(const Duration(seconds: 31, milliseconds: 70));
      expect(h.engine.lastSeek, const Duration(seconds: 31, milliseconds: 70));
      expect(h.player.position, const Duration(seconds: 31, milliseconds: 70));
      expect(h.player.progressSeconds, 31);
    });

    test('seekTo além da duração é limitado ao fim', () {
      final h = Harness();
      h.player.play('s1'); // dur 214
      h.player.seekTo(const Duration(seconds: 999));
      expect(h.player.progressSeconds, 214);
    });

    test('position expõe a posição vinda do engine', () async {
      final h = Harness();
      h.player.play('s1');
      h.engine.emitPosition(42);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.position, const Duration(seconds: 42));
    });
  });

  group('scrub (arrastar o tempo)', () {
    test('beginScrub pausa o áudio mas mantém a intenção de tocar', () {
      final h = Harness();
      h.player.play('s1');
      expect(h.engine.playing, isTrue);
      h.player.beginScrub();
      expect(h.engine.playing, isFalse);
      expect(h.player.isPlaying, isTrue);
    });

    test('endScrub posiciona o engine e retoma se estava tocando', () {
      final h = Harness();
      h.player.play('s1'); // dur 214
      h.player.beginScrub();
      h.player.endScrub(0.5);
      expect(h.player.progressSeconds, 107);
      expect(h.engine.lastSeek, const Duration(seconds: 107));
      expect(h.engine.playing, isTrue);
    });

    test('endScrub não retoma se estava pausado', () {
      final h = Harness();
      h.player.play('s1');
      h.player.togglePlay(); // pausa
      h.player.beginScrub();
      h.player.endScrub(0.25);
      expect(h.player.progressSeconds, 54);
      expect(h.engine.playing, isFalse);
    });

    test('eventos de posição são ignorados durante o scrub', () async {
      final h = Harness();
      h.player.play('s1');
      h.player.beginScrub();
      h.engine.emitPosition(99);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.progressSeconds, 0);
    });
  });

  group('ações remotas (notificação)', () {
    test('play remoto retoma quando pausado', () async {
      final h = Harness();
      h.player.play('s1');
      h.player.togglePlay(); // pausa
      h.engine.emitRemote(PlayerRemoteAction.play);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.isPlaying, isTrue);
      expect(h.engine.playing, isTrue);
    });

    test('pause remoto pausa quando tocando', () async {
      final h = Harness();
      h.player.play('s1');
      h.engine.emitRemote(PlayerRemoteAction.pause);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.isPlaying, isFalse);
      expect(h.engine.playing, isFalse);
    });

    test('next remoto avança a faixa', () async {
      final h = Harness();
      h.player.play('s1');
      h.engine.emitRemote(PlayerRemoteAction.next);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.currentId, 's2');
    });

    test('previous remoto volta a faixa', () async {
      final h = Harness();
      h.player.play('s5');
      h.engine.emitRemote(PlayerRemoteAction.previous);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.currentId, 's4');
    });

    test('shuffle remoto alterna e sincroniza o ícone', () async {
      final h = Harness();
      h.player.play('s1');
      h.engine.emitRemote(PlayerRemoteAction.shuffle);
      await Future<void>.delayed(Duration.zero);
      expect(h.player.shuffle, isTrue);
      expect(h.engine.shuffleActive, isTrue);
    });
  });

  group('conclusão da faixa', () {
    test('sem repeat, pula para a próxima', () async {
      final h = Harness();
      h.player.play('s1');
      h.engine.emitCompleted();
      await Future<void>.delayed(Duration.zero);
      expect(h.player.currentId, 's2');
    });

    test('com repeat, reinicia a mesma', () async {
      final h = Harness();
      h.player.play('s1');
      h.player.toggleRepeat();
      h.engine.emitCompleted();
      await Future<void>.delayed(Duration.zero);
      expect(h.player.currentId, 's1');
      expect(h.player.progressSeconds, 0);
      expect(h.engine.lastSeek, Duration.zero);
    });
  });

  group('atalhos de reprodução', () {
    test('playPlaylist toca a primeira com o rótulo do contexto', () {
      final h = Harness();
      final p = h.library.playlistById('p1')!; // [s6,s4,s1,s10]
      h.player.playPlaylist(p);
      expect(h.player.currentId, 's6');
      expect(h.player.order, ['s6', 's4', 's1', 's10']);
      expect(h.player.contextLabel, 'Tocando · Manhã Devagar');
    });

    test('playPlaylist com shuffle liga o modo', () {
      final h = Harness();
      final p = h.library.playlistById('p1')!;
      h.player.playPlaylist(p, shuffle: true);
      expect(h.player.shuffle, isTrue);
      expect(h.player.order.toSet(), {'s6', 's4', 's1', 's10'});
    });

    test('playFavorites toca a primeira favorita', () {
      final h = Harness();
      h.player.playFavorites();
      expect(h.player.currentId, 's1');
      expect(h.player.order, ['s1', 's4', 's7']);
      expect(h.player.contextLabel, 'Suas favoritas');
    });

    test('shuffleAll toca no contexto de todas', () {
      final h = Harness();
      h.player.shuffleAll();
      expect(h.player.shuffle, isTrue);
      expect(h.player.contextLabel, 'Modo aleatório');
      expect(h.player.order.toSet(), h.library.allSongIds.toSet());
    });

    test('atalhos não fazem nada com biblioteca vazia', () {
      final h = Harness(snapshot: const LibrarySnapshot());
      h.player.shuffleAll();
      h.player.playFavorites();
      expect(h.player.hasCurrent, isFalse);
      expect(h.navigation.screen, AppScreen.library);
    });
  });
}
