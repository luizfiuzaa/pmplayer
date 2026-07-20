import 'package:flutter/foundation.dart';

import '../../core/state/library_store.dart';
import '../navigation/navigation_controller.dart';

/// Estado do sheet "Nova playlist": nome + faixas escolhidas.
/// Espelha `newName`/`newPick` e a ação `createPlaylist` do DCLogic.
class CreatePlaylistViewModel extends ChangeNotifier {
  CreatePlaylistViewModel({required this.library, required this.navigation});

  final LibraryStore library;
  final NavigationController navigation;

  String _name = '';
  final List<String> _pickedIds = [];

  String get name => _name;
  List<String> get pickedIds => List.unmodifiable(_pickedIds);
  int get pickCount => _pickedIds.length;
  bool isPicked(String id) => _pickedIds.contains(id);
  bool get canCreate => _name.trim().isNotEmpty;

  void setName(String value) {
    _name = value;
    notifyListeners();
  }

  void toggle(String id) {
    if (!_pickedIds.remove(id)) _pickedIds.add(id);
    notifyListeners();
  }

  /// Cria a playlist, reseta o formulário, fecha o sheet e volta para Playlists.
  void submit() {
    if (!canCreate) return;
    library.createPlaylist(_name.trim(), _pickedIds);
    _name = '';
    _pickedIds.clear();
    navigation.closeCreateSheet();
    navigation.go(AppScreen.playlists);
    notifyListeners();
  }
}
