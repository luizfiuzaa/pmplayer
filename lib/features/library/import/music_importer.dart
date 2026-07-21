import 'dart:io';
import 'dart:typed_data';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
import 'package:palette_generator/palette_generator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/models/song.dart';

/// Importa faixas a partir de arquivos escolhidos pelo usuário.
abstract interface class MusicImporter {
  /// Abre o seletor e emite as faixas em lotes (chunks) conforme são lidas,
  /// para a UI ir mostrando o progresso sem travar. Não emite nada se o
  /// usuário cancelar.
  Stream<List<Song>> importChunked({int chunkSize = 8});
}

/// Monta um [Song] a partir do caminho e dos metadados lidos. Título e artista
/// caem para o nome do arquivo / "Artista desconhecido" quando ausentes.
Song songFromMetadata({
  required String path,
  String? title,
  String? artist,
  int durationSeconds = 0,
  String? coverPath,
  String? lyrics,
  List<Color>? palette,
}) {
  final resolvedTitle = (title != null && title.trim().isNotEmpty)
      ? title.trim()
      : p.basenameWithoutExtension(path);
  final resolvedArtist = (artist != null && artist.trim().isNotEmpty)
      ? artist.trim()
      : 'Artista desconhecido';
  final resolvedLyrics = (lyrics != null && lyrics.trim().isNotEmpty)
      ? lyrics.trim()
      : null;
  return Song(
    id: path,
    title: resolvedTitle,
    artist: resolvedArtist,
    durationSeconds: durationSeconds,
    uri: path,
    coverPath: coverPath,
    lyrics: resolvedLyrics,
    palette: palette,
  );
}

/// Implementação real usando `file_picker`
class FileSelectorMusicImporter implements MusicImporter {
  @override
  Stream<List<Song>> importChunked({int chunkSize = 8}) async* {
    // Solicita permissões de armazenamento/áudio.
    if (Platform.isAndroid) {
      if (await Permission.audio.status.isDenied) {
        await Permission.audio.request();
      }
      if (await Permission.storage.status.isDenied) {
        await Permission.storage.request();
      }
    }

    final dirPath = await FilePicker.platform.getDirectoryPath();
    if (dirPath == null) return;

    final directory = Directory(dirPath);
    if (!directory.existsSync()) return;

    final allFiles = directory.listSync(recursive: true).whereType<File>();

    const audioExtensions = [
      '.mp3', '.m4a', '.aac', '.flac', '.wav', '.ogg', '.opus', '.wma',
    ];
    final files = allFiles.where((file) {
      final ext = p.extension(file.path).toLowerCase();
      return audioExtensions.contains(ext);
    }).toList();

    if (files.isEmpty) return;

    final coversDir = await _coversDirectory();
    var buffer = <Song>[];
    for (final file in files) {
      buffer.add(await _readSong(file.path, coversDir));
      if (buffer.length >= chunkSize) {
        yield buffer;
        buffer = <Song>[];
        // Devolve o controle ao event loop para a UI renderizar um frame.
        await Future<void>.delayed(Duration.zero);
      }
    }
    if (buffer.isNotEmpty) yield buffer;
  }

  Future<Song> _readSong(String path, Directory coversDir) async {
    String? title;
    String? artist;
    var durationSeconds = 0;
    String? coverPath;
    String? lyrics;
    List<Color>? palette;
    try {
      final metadata = readMetadata(File(path), getImage: true);
      title = metadata.title;
      artist = metadata.artist;
      durationSeconds = metadata.duration?.inSeconds ?? 0;
      coverPath = await _saveCover(metadata.pictures, path, coversDir);
      lyrics = metadata.lyrics;
      palette = await _dominantPalette(metadata.pictures);
    } catch (_) {
      // Arquivo sem metadados legíveis: cai nos padrões.
    }
    return songFromMetadata(
      path: path,
      title: title,
      artist: artist,
      durationSeconds: durationSeconds,
      coverPath: coverPath,
      lyrics: lyrics,
      palette: palette,
    );
  }

  /// Extrai um par de cores (dominante + variação escura) da arte embutida,
  /// usado para tingir o fundo do player e o mini-player. `null` sem arte.
  Future<List<Color>?> _dominantPalette(List<Picture> pictures) async {
    if (pictures.isEmpty) return null;
    try {
      final bytes = Uint8List.fromList(pictures.first.bytes);
      final generator = await PaletteGenerator.fromImageProvider(
        MemoryImage(bytes),
        maximumColorCount: 12,
      );
      final dominant = generator.dominantColor?.color ??
          generator.vibrantColor?.color ??
          generator.mutedColor?.color;
      if (dominant == null) return null;
      final second = generator.darkVibrantColor?.color ??
          generator.darkMutedColor?.color ??
          Color.lerp(dominant, const Color(0xFF000000), 0.4)!;
      return [dominant, second];
    } catch (_) {
      return null;
    }
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
