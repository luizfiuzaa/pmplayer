import 'package:flutter/material.dart';

/// Uma faixa de áudio. Espelha o catálogo do design (`SONGS` no DCLogic) e,
/// para arquivos locais, guarda o caminho do áudio e da capa (arte embutida).
@immutable
class Song {
  const Song({
    required this.id,
    required this.title,
    required this.artist,
    required this.durationSeconds,
    this.palette,
    this.uri,
    this.coverPath,
  });

  final String id;
  final String title;
  final String artist;
  final int durationSeconds;

  /// Par de cores da capa gerada. `null` = capa genérica (ícone).
  final List<Color>? palette;

  /// Caminho/URI do arquivo de áudio local. `null` = faixa de exemplo.
  final String? uri;

  /// Caminho de um arquivo de imagem de capa (arte embutida extraída dos
  /// metadados). `null` = usa paleta/capa genérica.
  final String? coverPath;

  /// `true` quando a faixa não tem paleta e usa a capa genérica.
  bool get isGeneric => palette == null;

  /// `true` quando há uma imagem de capa real.
  bool get hasCover => coverPath != null;

  /// `true` quando a faixa aponta para um arquivo de áudio reproduzível.
  bool get isLocalFile => uri != null;

  /// Duração no formato `m:ss` (ex.: `3:34`). Equivale a `fmt()` no design.
  String get durationLabel => formatSeconds(durationSeconds);

  /// Formata um total de segundos como `m:ss`.
  static String formatSeconds(int totalSeconds) {
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }
}
