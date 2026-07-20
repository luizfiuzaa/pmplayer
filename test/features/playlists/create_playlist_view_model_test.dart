import 'package:pmplayer/core/data/sample_music_repository.dart';
import 'package:pmplayer/core/state/library_store.dart';
import 'package:pmplayer/features/navigation/navigation_controller.dart';
import 'package:pmplayer/features/playlists/create_playlist_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class Harness {
  Harness() {
    library = LibraryStore(initial: SampleMusicRepository().snapshot());
    navigation = NavigationController();
    vm = CreatePlaylistViewModel(library: library, navigation: navigation);
  }
  late final LibraryStore library;
  late final NavigationController navigation;
  late final CreatePlaylistViewModel vm;
}

void main() {
  test('não pode criar sem nome', () {
    final vm = Harness().vm;
    expect(vm.canCreate, isFalse);
    vm.setName('   ');
    expect(vm.canCreate, isFalse);
    vm.setName('Domingo');
    expect(vm.canCreate, isTrue);
  });

  test('alternar seleção adiciona e remove faixas, preservando a ordem', () {
    final vm = Harness().vm;
    vm.toggle('s2');
    vm.toggle('s5');
    expect(vm.pickedIds, ['s2', 's5']);
    expect(vm.isPicked('s2'), isTrue);
    expect(vm.pickCount, 2);
    vm.toggle('s2');
    expect(vm.pickedIds, ['s5']);
  });

  test('submit cria a playlist, fecha o sheet e volta para Playlists', () {
    final h = Harness();
    h.navigation.openCreateSheet();
    h.vm.setName('Domingo devagar');
    h.vm.toggle('s3');
    h.vm.submit();

    expect(h.library.playlists.last.name, 'Domingo devagar');
    expect(h.library.playlists.last.songIds, ['s3']);
    expect(h.navigation.createSheetOpen, isFalse);
    expect(h.navigation.screen, AppScreen.playlists);
  });

  test('submit reseta o formulário', () {
    final h = Harness();
    h.vm.setName('Nova');
    h.vm.toggle('s1');
    h.vm.submit();
    expect(h.vm.canCreate, isFalse);
    expect(h.vm.pickedIds, isEmpty);
  });

  test('submit sem nome não faz nada', () {
    final h = Harness();
    h.vm.submit();
    expect(h.library.playlists.length, 3);
  });
}
