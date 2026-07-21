import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

import 'audio_engine.dart';

/// Handler do `audio_service`: espelha o estado real do [AudioPlayer] na
/// notificação e traduz os toques dos botões em [PlayerRemoteAction], sem
/// tocar diretamente no player (a fila/estado moram no [PlayerViewModel]).
///
/// Botões da notificação: shuffle · faixa anterior · play/pause · próxima faixa.
class PmAudioHandler extends BaseAudioHandler {
  PmAudioHandler(this.player) {
    // Qualquer evento do player republica o estado (posição, playing, etc.).
    player.playbackEventStream.listen((_) => _broadcast());
    player.playingStream.listen((_) => _broadcast());
    player.processingStateStream.listen((_) => _broadcast());
  }

  final AudioPlayer player;
  final _remote = StreamController<PlayerRemoteAction>.broadcast();
  bool _shuffle = false;

  Stream<PlayerRemoteAction> get remoteActions => _remote.stream;

  void setShuffleActive(bool value) {
    if (_shuffle == value) return;
    _shuffle = value;
    _broadcast();
  }

  void setNowPlaying(MediaItem item) => mediaItem.add(item);

  // ── Botões da notificação → ações remotas ────────────────────────────────
  @override
  Future<void> play() async => _remote.add(PlayerRemoteAction.play);

  @override
  Future<void> pause() async => _remote.add(PlayerRemoteAction.pause);

  @override
  Future<void> skipToNext() async => _remote.add(PlayerRemoteAction.next);

  @override
  Future<void> skipToPrevious() async =>
      _remote.add(PlayerRemoteAction.previous);

  @override
  Future<void> seek(Duration position) => player.seek(position);

  @override
  Future<dynamic> customAction(String name, [Map<String, dynamic>? extras]) async {
    if (name == 'shuffle') _remote.add(PlayerRemoteAction.shuffle);
  }

  Future<void> shutdown() async {
    await _remote.close();
    await player.dispose();
  }

  static const _processingStates = {
    ProcessingState.idle: AudioProcessingState.idle,
    ProcessingState.loading: AudioProcessingState.loading,
    ProcessingState.buffering: AudioProcessingState.buffering,
    ProcessingState.ready: AudioProcessingState.ready,
    ProcessingState.completed: AudioProcessingState.completed,
  };

  void _broadcast() {
    final playing = player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.custom(
            androidIcon:
                _shuffle ? 'drawable/ic_shuffle_on' : 'drawable/ic_shuffle',
            label: 'Shuffle',
            name: 'shuffle',
          ),
          MediaControl.skipToPrevious,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
        ],
        systemActions: const {MediaAction.seek},
        androidCompactActionIndices: const [1, 2, 3],
        processingState: _processingStates[player.processingState]!,
        playing: playing,
        updatePosition: player.position,
        bufferedPosition: player.bufferedPosition,
        speed: player.speed,
      ),
    );
  }
}
