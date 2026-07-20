import '../models/playlist.dart';
import '../models/song.dart';
import '../theme/app_colors.dart';
import 'library_repository.dart';
import 'music_repository.dart';

/// Catálogo de exemplo idêntico ao do design (`SONGS` / `state.playlists`).
/// Torna o app executável e os testes determinísticos sem depender do
/// dispositivo; uma implementação que varre os arquivos locais pode substituí-la
/// sem alterar a UI nem os fluxos.
class SampleMusicRepository implements MusicRepository {
  @override
  List<Song> songs() => [
    Song(
      id: 's1',
      title: 'Maré Cheia',
      artist: 'Luíza Sol',
      durationSeconds: 214,
      palette: [AppColors.light.accent2_400, AppColors.light.accent2_700],
    ),
    Song(
      id: 's2',
      title: 'Terra Vermelha',
      artist: 'Baobá',
      durationSeconds: 187,
      palette: [AppColors.light.accent400, AppColors.light.accent700],
    ),
    Song(id: 's3', title: 'Sereno', artist: 'Manu Vale', durationSeconds: 243),
    Song(
      id: 's4',
      title: 'Cio da Terra',
      artist: 'Flor de Sal',
      durationSeconds: 198,
      palette: [AppColors.light.accent2_300, AppColors.light.accent600],
    ),
    Song(
      id: 's5',
      title: 'Vento Norte',
      artist: 'Os Aroeira',
      durationSeconds: 221,
      palette: [AppColors.light.accent500, AppColors.light.accent2_800],
    ),
    Song(
      id: 's6',
      title: 'Café com Sol',
      artist: 'Nina Cardoso',
      durationSeconds: 176,
    ),
    Song(
      id: 's7',
      title: 'Raiz',
      artist: 'Coletivo Barro',
      durationSeconds: 259,
      palette: [AppColors.light.accent2_500, AppColors.light.accent2_900],
    ),
    Song(
      id: 's8',
      title: 'Lua de Sertão',
      artist: 'Aline Prado',
      durationSeconds: 205,
      palette: [AppColors.light.accent300, AppColors.light.accent2_700],
    ),
    Song(id: 's9', title: 'Rio Abaixo', artist: 'Tuim', durationSeconds: 168),
    Song(
      id: 's10',
      title: 'Amanhecer',
      artist: 'Joana Erê',
      durationSeconds: 232,
      palette: [AppColors.light.accent2_400, AppColors.light.accent800],
    ),
  ];

  @override
  List<Playlist> playlists() => [
    Playlist(
      id: 'p1',
      name: 'Manhã Devagar',
      songIds: ['s6', 's4', 's1', 's10'],
      coverSlotId: 'pl-p1',
    ),
    Playlist(
      id: 'p2',
      name: 'Estrada de Terra',
      songIds: ['s2', 's5', 's7', 's8'],
      coverSlotId: 'pl-p2',
    ),
    Playlist(id: 'p3', name: 'Foco & Calma', songIds: ['s3', 's9', 's1', 's6']),
  ];

  @override
  List<String> initialFavoriteIds() => ['s1', 's4', 's7'];

  /// Snapshot de exemplo (usado em testes e como demonstração).
  LibrarySnapshot snapshot() => LibrarySnapshot(
    songs: songs(),
    favoriteIds: initialFavoriteIds(),
    playlists: playlists(),
  );
}
