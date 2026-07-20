import '../models/song.dart';

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

  Future<void> dispose();
}
