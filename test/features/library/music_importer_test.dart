import 'package:flutter/painting.dart';
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

  test('guarda a letra dos metadados quando presente', () {
    final song = songFromMetadata(
      path: '/m/x.mp3',
      lyrics: '  Linha 1\nLinha 2  ',
    );
    expect(song.hasLyrics, isTrue);
    expect(song.lyrics, 'Linha 1\nLinha 2');
  });

  test('letra vazia vira null', () {
    final song = songFromMetadata(path: '/m/x.mp3', lyrics: '   ');
    expect(song.lyrics, isNull);
    expect(song.hasLyrics, isFalse);
  });

  test('repassa a paleta (cor dominante) quando fornecida', () {
    final song = songFromMetadata(
      path: '/m/x.mp3',
      palette: const [Color(0xFF112233), Color(0xFF445566)],
    );
    expect(song.palette, hasLength(2));
    expect(song.isGeneric, isFalse);
  });

  test('converte IsolateSongData para objeto Song corretamente', () {
    const isolateData = IsolateSongData(
      path: '/music/song.mp3',
      title: 'Som do Isolate',
      artist: 'Artista Isolate',
      durationSeconds: 180,
      coverPath: '/covers/123.jpg',
      lyrics: 'Letra no isolate',
      paletteColors: [0xFF112233, 0xFF445566],
    );

    final song = songFromIsolateData(isolateData);
    expect(song.id, '/music/song.mp3');
    expect(song.title, 'Som do Isolate');
    expect(song.artist, 'Artista Isolate');
    expect(song.durationSeconds, 180);
    expect(song.coverPath, '/covers/123.jpg');
    expect(song.lyrics, 'Letra no isolate');
    expect(song.palette, equals(const [Color(0xFF112233), Color(0xFF445566)]));
  });

  test('filtra extensões de áudio suportadas corretamente', () {
    const audioExtensions = [
      '.mp3',
      '.m4a',
      '.aac',
      '.flac',
      '.wav',
      '.ogg',
      '.opus',
      '.wma',
    ];
    expect(isAudioFile('/caminho/musica.mp3', audioExtensions), isTrue);
    expect(isAudioFile('/caminho/musica.FLAC', audioExtensions), isTrue);
    expect(isAudioFile('/caminho/imagem.jpg', audioExtensions), isFalse);
    expect(isAudioFile('/caminho/texto.txt', audioExtensions), isFalse);
  });

  test('extrai paleta em pure Dart a partir de bytes de imagem no Isolate', () {
    final fakeImageBytes = List<int>.generate(600, (i) => (i * 7) % 256);
    final palette = extractPaletteFromBytes(fakeImageBytes);
    expect(palette, isNotNull);
    expect(palette, hasLength(2));
  });
}
