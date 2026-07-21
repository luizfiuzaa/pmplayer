import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/library_store.dart';

class UiUtils {
  static void toggleFavorite(BuildContext context, String songId) {
    final library = context.read<LibraryStore>();
    library.toggleFavorite(songId);

    if (library.isFavorite(songId)) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Faixa adicionada aos favoritos'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}
