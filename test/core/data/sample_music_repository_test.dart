import 'package:pmplayer/core/data/sample_music_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final repo = SampleMusicRepository();

  test('expõe as 10 faixas do catálogo do design, em ordem', () {
    final songs = repo.songs();
    expect(songs.map((s) => s.id).toList(), [
      's1',
      's2',
      's3',
      's4',
      's5',
      's6',
      's7',
      's8',
      's9',
      's10',
    ]);
    expect(songs.first.title, 'Maré Cheia');
    expect(songs.first.artist, 'Luíza Sol');
    expect(songs.first.durationSeconds, 214);
  });

  test('faixas sem paleta são genéricas (s3, s6, s9)', () {
    final byId = {for (final s in repo.songs()) s.id: s};
    expect(byId['s3']!.isGeneric, isTrue);
    expect(byId['s6']!.isGeneric, isTrue);
    expect(byId['s9']!.isGeneric, isTrue);
    expect(byId['s1']!.isGeneric, isFalse);
  });

  test('traz as três playlists iniciais com suas faixas', () {
    final playlists = repo.playlists();
    expect(playlists.map((p) => p.id).toList(), ['p1', 'p2', 'p3']);
    expect(playlists[0].name, 'Manhã Devagar');
    expect(playlists[0].songIds, ['s6', 's4', 's1', 's10']);
    expect(playlists[0].coverSlotId, 'pl-p1');
    expect(playlists[2].name, 'Foco & Calma');
    expect(playlists[2].coverSlotId, isNull);
  });

  test('favoritas iniciais são s1, s4 e s7', () {
    expect(repo.initialFavoriteIds(), ['s1', 's4', 's7']);
  });
}
