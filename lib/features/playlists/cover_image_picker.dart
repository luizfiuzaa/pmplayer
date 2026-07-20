import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Escolhe uma imagem para usar como capa de playlist.
abstract interface class CoverImagePicker {
  /// Abre o seletor de imagens; devolve o caminho salvo, ou `null` se cancelar.
  Future<String?> pickCover();
}

/// Implementação real com `file_selector`, copiando a imagem para o
/// armazenamento do app (para persistir de forma estável).
class FileSelectorCoverImagePicker implements CoverImagePicker {
  static const _imageGroup = XTypeGroup(
    label: 'Imagem',
    extensions: ['jpg', 'jpeg', 'png', 'webp', 'heic'],
    mimeTypes: ['image/*'],
  );

  @override
  Future<String?> pickCover() async {
    final file = await openFile(acceptedTypeGroups: [_imageGroup]);
    if (file == null) return null;

    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'covers'));
    if (!dir.existsSync()) dir.createSync(recursive: true);

    final extension = p.extension(file.path);
    final destination = File(
      p.join(dir.path, 'pl_${DateTime.now().microsecondsSinceEpoch}$extension'),
    );
    await destination.writeAsBytes(await file.readAsBytes());
    return destination.path;
  }
}
