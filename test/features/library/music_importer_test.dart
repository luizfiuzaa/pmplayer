import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/features/library/import/music_importer.dart';

void main() {
  test('usa título e artista dos metadados quando presentes', () {
    final song = songFromMetadata(
      path: '/m/faixa.mp3',
      title: 'Maré Cheia',
      artist: 'Luíza Sol',
      durationSeconds: 214,
      coverPath: '/capas/x.jpg',
    );
    expect(song.title, 'Maré Cheia');
    expect(song.artist, 'Luíza Sol');
    expect(song.durationSeconds, 214);
    expect(song.uri, '/m/faixa.mp3');
    expect(song.id, '/m/faixa.mp3');
    expect(song.coverPath, '/capas/x.jpg');
    expect(song.isLocalFile, isTrue);
    expect(song.isGeneric, isTrue);
  });

  test('sem título nos metadados, deriva do nome do arquivo', () {
    final song = songFromMetadata(path: '/m/Minha Música.flac', title: '  ');
    expect(song.title, 'Minha Música');
  });

  test('sem artista nos metadados, usa o padrão', () {
    final song = songFromMetadata(path: '/m/x.mp3');
    expect(song.artist, 'Artista desconhecido');
    expect(song.durationSeconds, 0);
    expect(song.coverPath, isNull);
  });
}
