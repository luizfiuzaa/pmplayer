import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/models/lyrics.dart';

const _lrc = '''
[ti:Engine No. 9]
[ar:Deftones]
[by:SpotiFLAC-Mobile (source: LRCLIB)]

[00:04.41]Yeah!
[00:31.07] This ain't no motherfuckin'
stick up, pick the stick up
[00:33.60]And watch it roll real close,
rolling out of my hand 'til
[00:43.37]Round bumping around me, you'll want to run from underground [00:46.57]At the best, walk the line
''';

void main() {
  group('Lyrics.parse — LRC sincronizado', () {
    final lyrics = Lyrics.parse(_lrc);

    test('marca como sincronizado e ignora metadados', () {
      expect(lyrics.synced, isTrue);
      expect(lyrics.plainText, isNot(contains('ti:')));
      expect(lyrics.plainText, isNot(contains('SpotiFLAC')));
      expect(lyrics.plainText, isNot(contains('[00:')));
    });

    test('primeira linha tem tempo e texto corretos', () {
      expect(
        lyrics.lines.first.time,
        const Duration(seconds: 4, milliseconds: 410),
      );
      expect(lyrics.lines.first.text, 'Yeah!');
    });

    test('junta a linha quebrada à linha com timestamp', () {
      final line = lyrics.lines[1];
      expect(line.time, const Duration(seconds: 31, milliseconds: 70));
      expect(
        line.text,
        "This ain't no motherfuckin' stick up, pick the stick up",
      );
    });

    test('separa timestamp no meio do texto', () {
      final texts = lyrics.lines.map((l) => l.text).toList();
      expect(
        texts,
        contains(
          'Round bumping around me, you\'ll want to run from underground',
        ),
      );
      expect(texts, contains('At the best, walk the line'));
    });

    test('activeIndex acompanha a posição', () {
      expect(lyrics.activeIndex(const Duration(seconds: 2)), -1);
      expect(
        lyrics.activeIndex(const Duration(seconds: 4, milliseconds: 500)),
        0,
      );
      expect(lyrics.activeIndex(const Duration(seconds: 32)), 1);
    });
  });

  group('Lyrics.parse — texto simples e vazio', () {
    test('texto sem timestamps vira linhas não sincronizadas', () {
      final l = Lyrics.parse('Linha um\n\nLinha dois');
      expect(l.synced, isFalse);
      expect(l.lines.map((e) => e.text), ['Linha um', 'Linha dois']);
      expect(l.activeIndex(const Duration(seconds: 5)), -1);
    });

    test('nulo/vazio devolve vazio', () {
      expect(Lyrics.parse(null).isEmpty, isTrue);
      expect(Lyrics.parse('   ').isEmpty, isTrue);
    });
  });

  test('offset desloca os tempos', () {
    final l = Lyrics.parse('[offset:+500]\n[00:10.00]linha');
    expect(l.lines.first.time, const Duration(seconds: 10, milliseconds: 500));
  });
}
