import 'package:just_audio/just_audio.dart';

import 'audio_engine.dart';

/// Implementação real do [AudioEngine] usando o pacote `just_audio` para tocar
/// arquivos de áudio locais.
class JustAudioEngine implements AudioEngine {
  final AudioPlayer _player = AudioPlayer();

  @override
  Future<Duration?> load(String uri) =>
      _player.setAudioSource(AudioSource.file(uri));

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
