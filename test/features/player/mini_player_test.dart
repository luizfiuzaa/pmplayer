import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/app_widget.dart';
import 'package:pmplayer/core/data/sample_music_repository.dart';
import 'package:pmplayer/core/models/song.dart';
import 'package:pmplayer/core/playback/audio_engine.dart';
import 'package:pmplayer/features/player/mini_player.dart';

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

void main() {
  testWidgets(
    'MiniPlayer exibe botões na ordem: favorito, voltar, play/pause, avançar',
    (tester) async {
      final repository = SampleMusicRepository();
      await tester.pumpWidget(
        PmPlayerApp(initial: repository.snapshot(), engine: InertAudioEngine()),
      );

      // Toca a primeira faixa para exibir o miniplayer
      await tester.tap(find.text('Terra Vermelha'));
      await tester.pumpAndSettle();

      // Volta para a biblioteca fechando o player em tela cheia se estiver aberto
      // Na nossa app, tocar em uma faixa abre o now playing. Vamos fechar minimizando.
      final backButton = find.byIcon(Icons.keyboard_arrow_down);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      expect(find.byType(MiniPlayer), findsOneWidget);

      final miniPlayerFinder = find.byType(MiniPlayer);
      final prevFinder = find.descendant(
        of: miniPlayerFinder,
        matching: find.byIcon(Icons.skip_previous),
      );
      final playPauseFinder = find.descendant(
        of: miniPlayerFinder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              (w.icon == Icons.pause || w.icon == Icons.play_arrow),
        ),
      );
      final nextFinder = find.descendant(
        of: miniPlayerFinder,
        matching: find.byIcon(Icons.skip_next),
      );
      final heartFinder = find.descendant(
        of: miniPlayerFinder,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Icon &&
              (w.icon == Icons.favorite || w.icon == Icons.favorite_border),
        ),
      );

      expect(prevFinder, findsOneWidget);
      expect(playPauseFinder, findsOneWidget);
      expect(nextFinder, findsOneWidget);
      expect(heartFinder, findsOneWidget);

      // Verifica a ordem relativa da esquerda para a direita dos botões
      final heartDx = tester.getCenter(heartFinder).dx;
      final prevDx = tester.getCenter(prevFinder).dx;
      final playPauseDx = tester.getCenter(playPauseFinder).dx;
      final nextDx = tester.getCenter(nextFinder).dx;

      expect(
        heartDx < prevDx,
        isTrue,
        reason: 'Favorito deve vir antes de Voltar',
      );
      expect(
        prevDx < playPauseDx,
        isTrue,
        reason: 'Voltar deve vir antes de Play/Pause',
      );
      expect(
        playPauseDx < nextDx,
        isTrue,
        reason: 'Play/Pause deve vir antes de Avançar',
      );
    },
  );

  testWidgets(
    'MiniPlayer possui ClipRRect para recortar o gradiente nas bordas arredondadas',
    (tester) async {
      final repository = SampleMusicRepository();
      await tester.pumpWidget(
        PmPlayerApp(initial: repository.snapshot(), engine: InertAudioEngine()),
      );

      await tester.tap(find.text('Terra Vermelha'));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.keyboard_arrow_down);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      final miniPlayerFinder = find.byType(MiniPlayer);
      final clipRRectFinder = find.descendant(
        of: miniPlayerFinder,
        matching: find.byWidgetPredicate(
          (w) => w is ClipRRect && w.borderRadius == BorderRadius.circular(20),
        ),
      );
      expect(
        clipRRectFinder,
        findsOneWidget,
        reason:
            'MiniPlayer deve usar ClipRRect com raio 20 para conter o gradiente dentro dos cantos arredondados',
      );
    },
  );

  testWidgets('Botões de avançar e voltar funcionam no MiniPlayer', (
    tester,
  ) async {
    final repository = SampleMusicRepository();
    await tester.pumpWidget(
      PmPlayerApp(initial: repository.snapshot(), engine: InertAudioEngine()),
    );

    await tester.tap(find.text('Terra Vermelha'));
    await tester.pumpAndSettle();

    final backButton = find.byIcon(Icons.keyboard_arrow_down);
    if (backButton.evaluate().isNotEmpty) {
      await tester.tap(backButton);
      await tester.pumpAndSettle();
    }

    final miniPlayerFinder = find.byType(MiniPlayer);
    final nextFinder = find.descendant(
      of: miniPlayerFinder,
      matching: find.byIcon(Icons.skip_next),
    );

    await tester.tap(nextFinder);
    await tester.pumpAndSettle();

    // A faixa deve mudar para a próxima ("Sereno")
    expect(
      find.descendant(of: miniPlayerFinder, matching: find.text('Sereno')),
      findsOneWidget,
    );

    final prevFinder = find.descendant(
      of: miniPlayerFinder,
      matching: find.byIcon(Icons.skip_previous),
    );
    await tester.tap(prevFinder);
    await tester.pumpAndSettle();

    // Retorna para a faixa anterior ("Terra Vermelha")
    expect(
      find.descendant(
        of: miniPlayerFinder,
        matching: find.text('Terra Vermelha'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'Arrastar o MiniPlayer para a esquerda pula para a próxima faixa e para a direita volta a anterior',
    (tester) async {
      final repository = SampleMusicRepository();
      await tester.pumpWidget(
        PmPlayerApp(initial: repository.snapshot(), engine: InertAudioEngine()),
      );

      await tester.tap(find.text('Terra Vermelha'));
      await tester.pumpAndSettle();

      final backButton = find.byIcon(Icons.keyboard_arrow_down);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      final miniPlayerFinder = find.byType(MiniPlayer);
      expect(
        find.descendant(
          of: miniPlayerFinder,
          matching: find.text('Terra Vermelha'),
        ),
        findsOneWidget,
      );

      // Arrastar para a esquerda (drag left: offset negativo no x) -> Próxima faixa ('Sereno')
      await tester.drag(miniPlayerFinder, const Offset(-200, 0));
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: miniPlayerFinder, matching: find.text('Sereno')),
        findsOneWidget,
      );

      // Arrastar para a direita (drag right: offset positivo no x) -> Faixa anterior ('Terra Vermelha')
      await tester.drag(miniPlayerFinder, const Offset(200, 0));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: miniPlayerFinder,
          matching: find.text('Terra Vermelha'),
        ),
        findsOneWidget,
      );
    },
  );
}
