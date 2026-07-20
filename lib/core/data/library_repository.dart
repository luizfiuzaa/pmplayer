import '../models/playlist.dart';
import '../models/song.dart';

/// Foto do acervo carregada na inicialização (faixas, favoritas e playlists).
class LibrarySnapshot {
  const LibrarySnapshot({
    this.songs = const [],
    this.favoriteIds = const [],
    this.playlists = const [],
  });

  final List<Song> songs;
  final List<String> favoriteIds;
  final List<Playlist> playlists;
}

/// Persistência do acervo, com operações granulares para não reescrever tudo a
/// cada mudança. Abstraída para trocar o backend sem afetar o resto do app.
abstract interface class LibraryRepository {
  Future<LibrarySnapshot> load();
  Future<void> addSongs(List<Song> songs);
  Future<void> setFavorite(String songId, bool favorite);
  Future<void> addPlaylist(Playlist playlist);
  Future<void> setPlaylistCover(String playlistId, String? coverPath);
}
