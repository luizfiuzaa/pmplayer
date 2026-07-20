import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Escolhe uma imagem para usar como capa de playlist.
abstract interface class CoverImagePicker {
  /// Abre o seletor de imagens; devolve o caminho salvo, ou `null` se cancelar.
  Future<String?> pickCover();
}

/// Implementação real com `file_picker`, copiando a imagem para o
/// armazenamento do app (para persistir de forma estável).
class FileSelectorCoverImagePicker implements CoverImagePicker {
  @override
  Future<String?> pickCover() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    final path = result.files.single.path;
    if (path == null) return null;

    final file = File(path);

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
