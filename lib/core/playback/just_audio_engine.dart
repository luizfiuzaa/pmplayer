import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

import '../models/song.dart';
import 'audio_engine.dart';

/// Implementação real do [AudioEngine] usando o pacote `just_audio` para tocar
/// arquivos de áudio locais.
class JustAudioEngine implements AudioEngine {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<Duration?> load(Song song) {
    if (song.uri == null) return Future.value(null);
    return _player.setAudioSource(
      AudioSource.file(
        song.uri!,
        tag: MediaItem(
          id: song.id,
          title: song.title,
          artist: song.artist,
          artUri: song.hasCover ? Uri.file(song.coverPath!) : null,
        ),
      ),
    );
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Stream<Duration> get positionStream => _player.positionStream;

  @override
  Stream<void> get onCompleted => _player.processingStateStream.where(
    (state) => state == ProcessingState.completed,
  );

  @override
  Future<void> dispose() => _player.dispose();
}
