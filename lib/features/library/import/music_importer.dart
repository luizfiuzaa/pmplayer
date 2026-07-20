import 'dart:io';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/song.dart';

/// Importa faixas a partir de arquivos escolhidos pelo usuário.
abstract interface class MusicImporter {
  /// Abre o seletor de arquivos e devolve as faixas importadas
  /// (vazio se o usuário cancelar).
  Future<List<Song>> pickAndImport();
}

/// Monta um [Song] a partir do caminho e dos metadados lidos. Título e artista
/// caem para o nome do arquivo / "Artista desconhecido" quando ausentes.
Song songFromMetadata({
  required String path,
  String? title,
  String? artist,
  int durationSeconds = 0,
  String? coverPath,
}) {
  final resolvedTitle = (title != null && title.trim().isNotEmpty)
      ? title.trim()
      : p.basenameWithoutExtension(path);
  final resolvedArtist = (artist != null && artist.trim().isNotEmpty)
      ? artist.trim()
      : 'Artista desconhecido';
  return Song(
    id: path,
    title: resolvedTitle,
    artist: resolvedArtist,
    durationSeconds: durationSeconds,
    uri: path,
    coverPath: coverPath,
  );
}

/// Implementação real usando `file_picker`
class FileSelectorMusicImporter implements MusicImporter {
  @override
  Future<List<Song>> pickAndImport() async {
    // Solicita permissões de armazenamento/áudio.
    if (Platform.isAndroid) {
      if (await Permission.audio.status.isDenied) {
        await Permission.audio.request();
      }
      if (await Permission.storage.status.isDenied) {
        await Permission.storage.request();
      }
    }

    final dirPath = await FilePicker.getDirectoryPath();
    if (dirPath == null) return const [];

    final directory = Directory(dirPath);
    if (!directory.existsSync()) return const [];

    final allFiles = directory.listSync(recursive: true).whereType<File>();
    
    final audioExtensions = ['.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg', '.opus', '.wma'];
    final files = allFiles.where((file) {
      final ext = p.extension(file.path).toLowerCase();
      return audioExtensions.contains(ext);
    }).toList();

    if (files.isEmpty) return const [];

    final coversDir = await _coversDirectory();
    final songs = <Song>[];
    for (final file in files) {
      songs.add(await _readSong(file.path, coversDir));
    }
    return songs;
  }

  Future<Song> _readSong(String path, Directory coversDir) async {
    String? title;
    String? artist;
    var durationSeconds = 0;
    String? coverPath;
    try {
      final metadata = readMetadata(File(path), getImage: true);
      title = metadata.title;
      artist = metadata.artist;
      durationSeconds = metadata.duration?.inSeconds ?? 0;
      coverPath = await _saveCover(metadata.pictures, path, coversDir);
    } catch (_) {
      // Arquivo sem metadados legíveis: cai nos padrões.
    }
    return songFromMetadata(
      path: path,
      title: title,
      artist: artist,
      durationSeconds: durationSeconds,
      coverPath: coverPath,
    );
  }

  /// Grava a primeira arte embutida como arquivo e devolve seu caminho.
  Future<String?> _saveCover(
    List<Picture> pictures,
    String sourcePath,
    Directory coversDir,
  ) async {
    if (pictures.isEmpty) return null;
    final picture = pictures.first;
    final extension = picture.mimetype.contains('png') ? 'png' : 'jpg';
    final fileName = '${sourcePath.hashCode}.$extension';
    final destination = File(p.join(coversDir.path, fileName));
    await destination.writeAsBytes(picture.bytes);
    return destination.path;
  }

  Future<Directory> _coversDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'covers'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}
