import 'package:flutter/foundation.dart';

/// Uma coleção de faixas criada pelo usuário. Espelha `state.playlists`.
@immutable
class Playlist {
  const Playlist({
    required this.id,
    required this.name,
    required this.songIds,
    this.coverSlotId,
    this.coverPath,
  });

  final String id;
  final String name;
  final List<String> songIds;

  /// Identificador do slot de capa do design. `null` = usa a capa da 1ª faixa.
  final String? coverSlotId;

  /// Caminho de uma imagem escolhida como capa da playlist (o "image-slot"
  /// do design). `null` = sem foto definida.
  final String? coverPath;

  bool get hasCoverSlot => coverSlotId != null;
  bool get hasCover => coverPath != null;
  int get songCount => songIds.length;

  Playlist copyWith({
    String? name,
    List<String>? songIds,
    String? coverSlotId,
    String? coverPath,
  }) {
    return Playlist(
      id: id,
      name: name ?? this.name,
      songIds: songIds ?? this.songIds,
      coverSlotId: coverSlotId ?? this.coverSlotId,
      coverPath: coverPath ?? this.coverPath,
    );
  }
}
