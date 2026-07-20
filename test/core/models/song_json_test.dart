import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/models/song.dart';

void main() {
  test('faixa local guarda o caminho do arquivo em uri', () {
    const song = Song(
      id: 'x',
      title: 'Minha',
      artist: 'Eu',
      durationSeconds: 100,
      uri: '/musicas/minha.mp3',
    );
    expect(song.uri, '/musicas/minha.mp3');
    expect(song.isLocalFile, isTrue);
  });

  test('faixa sem uri não é arquivo local', () {
    const song = Song(id: 'x', title: 't', artist: 'a', durationSeconds: 10);
    expect(song.isLocalFile, isFalse);
  });

  test('coverPath define a existência de capa real', () {
    const withCover = Song(
      id: 'x',
      title: 't',
      artist: 'a',
      durationSeconds: 10,
      coverPath: '/capas/x.jpg',
    );
    const withoutCover = Song(
      id: 'y',
      title: 't',
      artist: 'a',
      durationSeconds: 10,
    );
    expect(withCover.hasCover, isTrue);
    expect(withoutCover.hasCover, isFalse);
  });
}
