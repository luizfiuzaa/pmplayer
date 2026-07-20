import 'package:flutter/foundation.dart';

/// As telas do app. As quatro primeiras são conteúdo de aba; [nowPlaying] é um
/// overlay que cobre a aba atual. Espelha `state.screen` do DCLogic.
enum AppScreen { library, playlists, favorites, detail, nowPlaying }

/// Controla a navegação entre abas, o overlay de reprodução e o sheet de
/// criação de playlist. Espelha `screen`/`prevTab`/`activePlaylist`/`createOpen`.
class NavigationController extends ChangeNotifier {
  AppScreen _screen = AppScreen.library;
  AppScreen _prevTab = AppScreen.library;
  String _activePlaylistId = 'p1';
  bool _createSheetOpen = false;

  AppScreen get screen => _screen;
  AppScreen get prevTab => _prevTab;
  String get activePlaylistId => _activePlaylistId;
  bool get createSheetOpen => _createSheetOpen;

  /// Aba ativa no menu inferior (o detalhe conta como Playlists).
  bool get isLibraryTab => _screen == AppScreen.library;
  bool get isPlaylistsTab =>
      _screen == AppScreen.playlists || _screen == AppScreen.detail;
  bool get isFavoritesTab => _screen == AppScreen.favorites;

  void go(AppScreen tab) {
    _screen = tab;
    notifyListeners();
  }

  void openPlaylist(String id) {
    _screen = AppScreen.detail;
    _activePlaylistId = id;
    notifyListeners();
  }

  void backToPlaylists() => go(AppScreen.playlists);

  /// Abre o player, lembrando a aba de origem para restaurar ao minimizar.
  void openNowPlaying() {
    if (_screen != AppScreen.nowPlaying) _prevTab = _screen;
    _screen = AppScreen.nowPlaying;
    notifyListeners();
  }

  void minimize() {
    _screen = _prevTab;
    notifyListeners();
  }

  void openCreateSheet() {
    _createSheetOpen = true;
    notifyListeners();
  }

  void closeCreateSheet() {
    _createSheetOpen = false;
    notifyListeners();
  }
}
