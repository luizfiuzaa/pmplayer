import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/models/song.dart';
import 'package:pmplayer/core/theme/app_colors.dart';
import 'package:pmplayer/core/theme/app_theme.dart';
import 'package:pmplayer/features/player/lyrics_artwork.dart';

const _song = Song(
  id: 's1',
  title: 'Maré Cheia',
  artist: 'Luíza Sol',
  durationSeconds: 214,
  lyrics: 'Verso um da canção\nVerso dois da canção',
);

Widget _host(Song song) => MaterialApp(
  theme: AppTheme.build(AppColors.light, Brightness.light),
  home: Scaffold(
    body: Center(
      child: LyricsArtwork(song: song, front: const Text('CAPA')),
    ),
  ),
);

void main() {
  testWidgets('vira a capa e revela a letra', (tester) async {
    await tester.pumpWidget(_host(_song));
    expect(find.text('CAPA'), findsOneWidget);
    expect(find.textContaining('Verso um'), findsNothing);

    await tester.tap(find.byType(LyricsArtwork));
    await tester.pumpAndSettle();

    expect(find.text('LETRA'), findsOneWidget);
    expect(find.textContaining('Verso um'), findsWidgets);
  });

  testWidgets('arrastar para a esquerda também vira a capa', (tester) async {
    await tester.pumpWidget(_host(_song));
    expect(find.text('LETRA'), findsNothing);

    await tester.fling(find.byType(LyricsArtwork), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();

    expect(find.text('LETRA'), findsOneWidget);
    expect(find.textContaining('Verso um'), findsWidgets);
  });

  testWidgets('expande a letra em tela cheia e o (X) fecha', (tester) async {
    await tester.pumpWidget(_host(_song));
    await tester.tap(find.byType(LyricsArtwork));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.open_in_full));
    await tester.pumpAndSettle();
    expect(find.byType(LyricsFullView), findsOneWidget);
    expect(find.text('Luíza Sol'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(find.byType(LyricsFullView), findsNothing);
    // Continua no verso (letra visível) após fechar.
    expect(find.text('LETRA'), findsOneWidget);
  });

  testWidgets('sem letra mostra aviso e esconde o expandir', (tester) async {
    await tester.pumpWidget(
      _host(const Song(id: 's', title: 't', artist: 'a', durationSeconds: 1)),
    );
    await tester.tap(find.byType(LyricsArtwork));
    await tester.pumpAndSettle();

    expect(find.text('Sem letra disponível'), findsOneWidget);
    expect(find.byIcon(Icons.open_in_full), findsNothing);
  });
}
