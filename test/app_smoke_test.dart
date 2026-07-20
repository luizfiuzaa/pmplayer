import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/data/library_repository.dart';
import 'package:pmplayer/core/data/sample_music_repository.dart';
import 'package:pmplayer/core/models/song.dart';
import 'package:pmplayer/core/playback/audio_engine.dart';
import 'package:pmplayer/features/library/import/music_importer.dart';
import 'package:pmplayer/main.dart';

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
  Future<void> dispose() async {}
}

/// Importador falso que devolve uma lista fixa.
class FakeImporter implements MusicImporter {
  FakeImporter(this.songs);
  final List<Song> songs;
  @override
  Future<List<Song>> pickAndImport() async => songs;
}

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

}
