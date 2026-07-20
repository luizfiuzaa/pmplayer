import 'package:pmplayer/features/navigation/navigation_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('começa na biblioteca, sem overlay nem sheet', () {
    final nav = NavigationController();
    expect(nav.screen, AppScreen.library);
    expect(nav.activePlaylistId, 'p1');
    expect(nav.createSheetOpen, isFalse);
  });

  test('go troca a aba visível', () {
    final nav = NavigationController();
    nav.go(AppScreen.favorites);
    expect(nav.screen, AppScreen.favorites);
  });

  test('openPlaylist abre o detalhe da playlist', () {
    final nav = NavigationController();
    nav.openPlaylist('p3');
    expect(nav.screen, AppScreen.detail);
    expect(nav.activePlaylistId, 'p3');
  });

  test('openNowPlaying guarda a aba de origem em prevTab', () {
    final nav = NavigationController();
    nav.go(AppScreen.favorites);
    nav.openNowPlaying();
    expect(nav.screen, AppScreen.nowPlaying);
    expect(nav.prevTab, AppScreen.favorites);
  });

  test('openNowPlaying não sobrescreve prevTab quando já está no player', () {
    final nav = NavigationController();
    nav.go(AppScreen.playlists);
    nav.openNowPlaying();
    nav.openNowPlaying();
    expect(nav.prevTab, AppScreen.playlists);
  });

  test('minimize volta para a aba de origem', () {
    final nav = NavigationController();
    nav.go(AppScreen.favorites);
    nav.openNowPlaying();
    nav.minimize();
    expect(nav.screen, AppScreen.favorites);
  });

  test('abre e fecha o sheet de criar playlist', () {
    final nav = NavigationController();
    nav.openCreateSheet();
    expect(nav.createSheetOpen, isTrue);
    nav.closeCreateSheet();
    expect(nav.createSheetOpen, isFalse);
  });
}
