import '../models/song.dart';

/// Ações disparadas remotamente (notificação / controles de mídia do sistema),
/// entregues ao [PlayerViewModel] para dirigir a fila/estado a partir de uma
/// única fonte de verdade.
enum PlayerRemoteAction { play, pause, next, previous, shuffle }

/// Reprodução de áudio de arquivos locais, abstraída para (a) testar o
/// [PlayerViewModel] sem áudio real e (b) trocar a implementação sem mexer na UI.
abstract interface class AudioEngine {
  /// Carrega uma faixa. Devolve a duração, se conhecida.
  Future<Duration?> load(Song song);
  Future<void> play();
  Future<void> pause();
  Future<void> seek(Duration position);

  /// Posição atual da reprodução (dispara ~a cada segundo).
  Stream<Duration> get positionStream;

  /// Dispara quando a faixa chega ao fim.
  Stream<void> get onCompleted;

  /// Ações vindas dos controles de mídia do sistema (notificação).
  Stream<PlayerRemoteAction> get remoteActions;

  /// Reflete o estado de shuffle no ícone da notificação.
  void setShuffleActive(bool value);

  Future<void> dispose();
}
