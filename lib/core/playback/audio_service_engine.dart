import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import '../models/song.dart';
import 'audio_engine.dart';
import 'pm_audio_handler.dart';

/// Implementação real do [AudioEngine]: toca arquivos locais com `just_audio` e
/// publica a mídia/controles na notificação via [PmAudioHandler] (`audio_service`).
class AudioServiceEngine implements AudioEngine {
  AudioServiceEngine(this._handler);

  final PmAudioHandler _handler;
  AudioPlayer get _player => _handler.player;

  @override
  Future<Duration?> load(Song song) {
    if (song.uri == null) return Future.value(null);
    _handler.setNowPlaying(
      MediaItem(
        id: song.id,
        title: song.title,
        artist: song.artist,
        duration: Duration(seconds: song.durationSeconds),
        artUri: song.hasCover ? Uri.file(song.coverPath!) : null,
      ),
    );
    return _player.setAudioSource(AudioSource.file(song.uri!));
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
  Stream<PlayerRemoteAction> get remoteActions => _handler.remoteActions;

  @override
  void setShuffleActive(bool value) => _handler.setShuffleActive(value);

  @override
  Future<void> dispose() => _handler.shutdown();
}
