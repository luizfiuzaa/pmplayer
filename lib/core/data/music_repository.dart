import '../models/playlist.dart';
import '../models/song.dart';

/// Fonte das faixas, playlists e favoritas iniciais.
///
/// Abstraída para permitir trocar a origem (catálogo de exemplo ⇄ varredura
/// dos arquivos locais do dispositivo) sem tocar nas ViewModels nem na UI.
abstract interface class MusicRepository {
  List<Song> songs();
  List<Playlist> playlists();
  List<String> initialFavoriteIds();
}
