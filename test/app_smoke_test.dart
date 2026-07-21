import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pmplayer/core/data/library_repository.dart';
import 'package:pmplayer/core/widgets/skeleton.dart';
import 'package:pmplayer/features/player/lyrics_artwork.dart';
import 'package:pmplayer/features/player/player_view_model.dart';
import 'package:pmplayer/core/data/sample_music_repository.dart';
import 'package:pmplayer/core/models/song.dart';
import 'package:pmplayer/core/playback/audio_engine.dart';
import 'package:pmplayer/features/library/import/music_importer.dart';
import 'package:pmplayer/app_widget.dart';

/// Engine de áudio inerte para os testes de widget.
class InertAudioEngine implements AudioEngine {
  @override
  Future<Duration?> load(Song song) async => null;
  @override
  Future<void> play() async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Stream<Duration> get positionStream => const Stream.empty();
  @override
  Stream<void> get onCompleted => const Stream.empty();
  @override
  Stream<PlayerRemoteAction> get remoteActions => const Stream.empty();
  @override
  void setShuffleActive(bool value) {}
  @override
  Future<void> dispose() async {}
}

/// Importador falso que emite uma lista fixa em um único lote.
class FakeImporter implements MusicImporter {
  FakeImporter(this.songs);
  final List<Song> songs;
  @override
  Stream<List<Song>> importChunked({int chunkSize = 8}) async* {
    if (songs.isNotEmpty) yield songs;
  }
}

/// Importador controlável: emite quando [future] completar (para testar o
/// estado de carregamento).
class AsyncImporter implements MusicImporter {
  AsyncImporter(this.future);
  final Future<List<Song>> future;
  @override
  Stream<List<Song>> importChunked({int chunkSize = 8}) async* {
    final songs = await future;
    if (songs.isNotEmpty) yield songs;
  }
}

/// Importador que repassa lotes de um [StreamController] (testar progresso).
class StreamImporter implements MusicImporter {
  StreamImporter(this.controller);
  final StreamController<List<Song>> controller;
  @override
  Stream<List<Song>> importChunked({int chunkSize = 8}) => controller.stream;
}

Song _song(String id) =>
    Song(id: id, title: id, artist: 'x', durationSeconds: 1, uri: id);

PmPlayerApp buildApp({
  LibrarySnapshot? initial,
  MusicImporter? importer,
}) {
  return PmPlayerApp(
    initial: initial ?? SampleMusicRepository().snapshot(),
    engine: InertAudioEngine(),
    importer: importer,
  );
}

void main() {
  testWidgets('abre na Biblioteca com faixas', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('Ouvir agora'), findsOneWidget);
    expect(find.text('Maré Cheia'), findsWidgets);
  });

  testWidgets('o menu inferior troca de aba', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Playlists').last);
    await tester.pumpAndSettle();
    expect(find.text('Suas coleções, do seu jeito.'), findsOneWidget);
  });

  testWidgets('tocar uma faixa abre o player', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Terra Vermelha'));
    await tester.pumpAndSettle();
    expect(find.text('TOCANDO DA BIBLIOTECA'), findsOneWidget);
  });

  testWidgets('a busca filtra a lista de faixas', (tester) async {
    await tester.pumpWidget(buildApp());
    expect(find.text('Sereno'), findsWidgets);

    await tester.enterText(find.byType(TextField), 'Terra');
    await tester.pumpAndSettle();

    // Casa por título, ignorando acento/caixa: "Terra Vermelha" e "Cio da Terra".
    expect(find.text('Terra Vermelha'), findsWidgets);
    expect(find.text('Cio da Terra'), findsWidgets);
    expect(find.text('Sereno'), findsNothing);
    expect(find.text('Resultados'), findsOneWidget);
  });

  testWidgets('no player, o menu (3 pontos) adiciona a faixa a uma playlist', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Terra Vermelha'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_horiz));
    await tester.pumpAndSettle();
    expect(find.text('Adicionar a playlist'), findsOneWidget);

    // "Estrada de Terra" (p2) já contém "Terra Vermelha" (s2): começa marcada.
    expect(find.byIcon(Icons.check), findsOneWidget);
    await tester.tap(find.text('Estrada de Terra'));
    await tester.pumpAndSettle();
    // Toque remove a faixa: some o check.
    expect(find.byIcon(Icons.check), findsNothing);
  });

  testWidgets('tocar em uma linha da letra pula para aquele momento', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    // s1 "Maré Cheia" tem letra LRC; tocar abre o player.
    await tester.tap(find.text('Maré Cheia').first);
    await tester.pumpAndSettle();

    // Vira a capa (arrasto p/ esquerda) e expande a letra.
    await tester.fling(find.byType(LyricsArtwork), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();

    // Toca na linha em [00:05] → pula para 5s.
    await tester.tap(find.text('A maré subiu devagar'));
    await tester.pump();

    final context = tester.element(find.byType(LyricsFullView));
    final player = Provider.of<PlayerViewModel>(context, listen: false);
    expect(player.progressSeconds, 5);
  });

  testWidgets('abre o sheet de criar playlist', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.tap(find.text('Playlists').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Criar playlist'));
    await tester.pumpAndSettle();
    expect(find.text('Nova playlist'), findsOneWidget);
  });

  testWidgets('biblioteca vazia mostra estado vazio e importa arquivos', (
    tester,
  ) async {
    final importer = FakeImporter(const [
      Song(
        id: '/m/Nova.mp3',
        title: 'Nova',
        artist: 'Artista desconhecido',
        durationSeconds: 100,
        uri: '/m/Nova.mp3',
      ),
    ]);
    await tester.pumpWidget(
      buildApp(initial: const LibrarySnapshot(), importer: importer),
    );

    expect(find.text('Sua biblioteca está vazia'), findsOneWidget);
    await tester.tap(find.text('Adicionar músicas'));
    await tester.pumpAndSettle();

    expect(find.text('Nova'), findsOneWidget);
    expect(find.text('Todas as faixas'), findsOneWidget);
  });

  testWidgets('mostra skeleton de carregamento enquanto adiciona músicas', (
    tester,
  ) async {
    final completer = Completer<List<Song>>();
    await tester.pumpWidget(
      buildApp(
        initial: const LibrarySnapshot(),
        importer: AsyncImporter(completer.future),
      ),
    );

    await tester.tap(find.text('Adicionar músicas'));
    await tester.pump(); // setState importing = true

    expect(find.text('Adicionando músicas…'), findsOneWidget);
    expect(find.byType(TrackListSkeleton), findsOneWidget);

    completer.complete(const [
      Song(
        id: '/m/A.mp3',
        title: 'Faixa A',
        artist: 'x',
        durationSeconds: 1,
        uri: '/m/A.mp3',
      ),
    ]);
    await tester.pump(); // resolve a future
    await tester.pump(); // setState importing = false

    expect(find.byType(TrackListSkeleton), findsNothing);
    expect(find.text('Faixa A'), findsWidgets);
  });

  testWidgets('adiciona as faixas em lotes, progressivamente', (tester) async {
    final controller = StreamController<List<Song>>();
    await tester.pumpWidget(
      buildApp(
        initial: const LibrarySnapshot(),
        importer: StreamImporter(controller),
      ),
    );

    await tester.tap(find.text('Adicionar músicas'));
    await tester.pump();
    expect(find.byType(TrackListSkeleton), findsOneWidget);

    controller.add([_song('Lote1')]);
    await tester.pump();
    // Já visível durante o carregamento (com skeleton ainda presente).
    expect(find.text('Lote1'), findsWidgets);
    expect(find.byType(TrackListSkeleton), findsOneWidget);

    controller.add([_song('Lote2')]);
    await tester.pump();
    expect(find.text('Lote2'), findsWidgets);

    await controller.close();
    await tester.pump();
    await tester.pump();

    expect(find.byType(TrackListSkeleton), findsNothing);
    expect(find.text('Lote1'), findsWidgets);
    expect(find.text('Lote2'), findsWidgets);
  });
}
