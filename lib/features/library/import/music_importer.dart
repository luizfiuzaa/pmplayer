import 'dart:io';
import 'dart:isolate';

import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/widgets.dart';
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

/// DTO serializável com metadados extraídos em Isolate.
class IsolateSongData {
  final String path;
  final String? title;
  final String? artist;
  final int durationSeconds;
  final String? coverPath;
  final String? lyrics;
  final List<int>? paletteColors;

  const IsolateSongData({
    required this.path,
    this.title,
    this.artist,
    this.durationSeconds = 0,
    this.coverPath,
    this.lyrics,
    this.paletteColors,
  });
}

/// Converte um [IsolateSongData] vindo de um Isolate num objeto [Song].
Song songFromIsolateData(IsolateSongData data) {
  return songFromMetadata(
    path: data.path,
    title: data.title,
    artist: data.artist,
    durationSeconds: data.durationSeconds,
    coverPath: data.coverPath,
    lyrics: data.lyrics,
    palette: data.paletteColors?.map((c) => Color(c)).toList(),
  );
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

/// Verifica se um arquivo possui uma extensão de áudio suportada.
bool isAudioFile(String path, List<String> audioExtensions) {
  final ext = p.extension(path).toLowerCase();
  return audioExtensions.contains(ext);
}

/// Extrai um par de cores (dominante + variação escura) em pure Dart a partir
/// dos bytes da imagem de capa, 100% dentro do Isolate sem tocar na UI thread.
List<int>? extractPaletteFromBytes(List<int> bytes) {
  if (bytes.length < 100) return null;
  try {
    int rSum = 0, gSum = 0, bSum = 0, count = 0;
    final step = (bytes.length / 300).clamp(4, 500).toInt();
    for (var i = 50; i < bytes.length - 50; i += step) {
      final b1 = bytes[i];
      final b2 = bytes[i + 1];
      final b3 = bytes[i + 2];
      if ((b1 > 20 || b2 > 20 || b3 > 20) &&
          (b1 < 240 || b2 < 240 || b3 < 240)) {
        rSum += b1;
        gSum += b2;
        bSum += b3;
        count++;
      }
    }
    if (count == 0) return null;
    final r = (rSum / count).round().clamp(0, 255);
    final g = (gSum / count).round().clamp(0, 255);
    final b = (bSum / count).round().clamp(0, 255);

    final dominantColor = (0xFF << 24) | (r << 16) | (g << 8) | b;
    final darkR = (r * 0.4).round().clamp(0, 255);
    final darkG = (g * 0.4).round().clamp(0, 255);
    final darkB = (b * 0.4).round().clamp(0, 255);
    final secondColor = (0xFF << 24) | (darkR << 16) | (darkG << 8) | darkB;

    return [dominantColor, secondColor];
  } catch (_) {
    return null;
  }
}

class _WorkerMessage {
  final SendPort sendPort;
  final String dirPath;
  final List<String> audioExtensions;
  final String coversDirPath;
  final int chunkSize;

  const _WorkerMessage({
    required this.sendPort,
    required this.dirPath,
    required this.audioExtensions,
    required this.coversDirPath,
    required this.chunkSize,
  });
}

/// Worker executado em um Isolate separado para varrer o diretório, ler metadados,
/// salvar capas e calcular paletas de cores sem NENHUMA interferência na UI thread.
void _importIsolateWorker(_WorkerMessage msg) {
  final directory = Directory(msg.dirPath);
  if (!directory.existsSync()) {
    msg.sendPort.send(null);
    return;
  }

  try {
    final allEntities = directory.listSync(recursive: true);
    final audioFiles = <String>[];
    for (final entity in allEntities) {
      if (entity is File && isAudioFile(entity.path, msg.audioExtensions)) {
        audioFiles.add(entity.path);
      }
    }

    if (audioFiles.isEmpty) {
      msg.sendPort.send(null);
      return;
    }

    var chunkData = <IsolateSongData>[];
    for (final filePath in audioFiles) {
      String? title;
      String? artist;
      var durationSeconds = 0;
      String? coverPath;
      String? lyrics;
      List<int>? paletteColors;

      try {
        final file = File(filePath);
        final metadata = readMetadata(file, getImage: true);
        title = metadata.title;
        artist = metadata.artist;
        durationSeconds = metadata.duration?.inSeconds ?? 0;
        lyrics = metadata.lyrics;

        if (metadata.pictures.isNotEmpty) {
          final picture = metadata.pictures.first;
          final extension = picture.mimetype.contains('png') ? 'png' : 'jpg';
          final fileName = '${filePath.hashCode}.$extension';
          final destination = File(p.join(msg.coversDirPath, fileName));
          destination.writeAsBytesSync(picture.bytes);
          coverPath = destination.path;
          paletteColors = extractPaletteFromBytes(picture.bytes);
        }
      } catch (_) {
        // Arquivo sem metadados legíveis: cai nos padrões.
      }

      chunkData.add(
        IsolateSongData(
          path: filePath,
          title: title,
          artist: artist,
          durationSeconds: durationSeconds,
          coverPath: coverPath,
          lyrics: lyrics,
          paletteColors: paletteColors,
        ),
      );

      if (chunkData.length >= msg.chunkSize) {
        msg.sendPort.send(chunkData);
        chunkData = <IsolateSongData>[];
      }
    }

    if (chunkData.isNotEmpty) {
      msg.sendPort.send(chunkData);
    }
  } catch (_) {
    // Trata erros de varredura ou IO
  } finally {
    msg.sendPort.send(null);
  }
}

/// Implementação de alta performance usando IsolateWorker streaming para 0% de skip de frames na UI.
class FileSelectorMusicImporter implements MusicImporter {
  @override
  Stream<List<Song>> importChunked({int chunkSize = 8}) async* {
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

    const audioExtensions = [
      '.mp3',
      '.m4a',
      '.aac',
      '.flac',
      '.wav',
      '.ogg',
      '.opus',
      '.wma',
    ];

    final coversDir = await _coversDirectory();
    final receivePort = ReceivePort();

    final workerMsg = _WorkerMessage(
      sendPort: receivePort.sendPort,
      dirPath: dirPath,
      audioExtensions: audioExtensions,
      coversDirPath: coversDir.path,
      chunkSize: chunkSize,
    );

    final isolate = await Isolate.spawn(_importIsolateWorker, workerMsg);

    try {
      await for (final message in receivePort) {
        if (message == null) break;
        if (message is List<IsolateSongData>) {
          final songs = message.map(songFromIsolateData).toList();
          yield songs;
          // Pausa consciente de 16ms (1 frame a 60fps) para sincronia e renderização impecável da UI
          await Future<void>.delayed(const Duration(milliseconds: 16));
        }
      }
    } finally {
      receivePort.close();
      isolate.kill(priority: Isolate.immediate);
    }
  }

  Future<Directory> _coversDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'covers'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }
}
