import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../core/models/playlist.dart';
import '../../core/models/song.dart';
import '../../core/playback/audio_engine.dart';
import '../../core/state/library_store.dart';
import '../navigation/navigation_controller.dart';

/// Motor de reprodução sobre o [AudioEngine] (áudio real de arquivos locais).
/// Mantém a fila/ordem, shuffle, repeat e o progresso, e navega ao player.
class PlayerViewModel extends ChangeNotifier {
  PlayerViewModel({
    required this.library,
    required this.navigation,
    required AudioEngine engine,
    Random? random,
  }) : _random = random ?? Random() {
    _engine = engine;
    _currentId = library.allSongIds.isEmpty ? null : library.allSongIds.first;
    _base = library.allSongIds;
    _order = library.allSongIds;
    _positionSub = _engine.positionStream.listen(_onPosition);
    _completedSub = _engine.onCompleted.listen((_) => _onCompleted());
  }

  final LibraryStore library;
  final NavigationController navigation;
  late final AudioEngine _engine;
  final Random _random;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<void> _completedSub;

  String? _currentId;
  String? _loadedId;
  int _progress = 0;
  bool _playing = false;
  bool _shuffle = false;
  bool _repeat = false;
  late List<String> _base;
  late List<String> _order;
  String _contextLabel = 'Tocando da biblioteca';

  // ── Leitura para as views ────────────────────────────────────────────────
  bool get hasCurrent => _currentId != null && currentSong != null;
  String? get currentId => _currentId;
  Song? get currentSong =>
      _currentId == null ? null : library.songByIdOrNull(_currentId!);
  int get progressSeconds => _progress;
  bool get isPlaying => _playing;
  bool get shuffle => _shuffle;
  bool get repeat => _repeat;
  String get contextLabel => _contextLabel;
  List<String> get order => List.unmodifiable(_order);

  double get progressFraction {
    final song = currentSong;
    if (song == null || song.durationSeconds == 0) return 0;
    return (_progress / song.durationSeconds).clamp(0.0, 1.0);
  }

  // ── Comandos ──────────────────────────────────────────────────────────────
  void play(String id, {List<String>? context, String? label}) {
    final base = context ?? library.allSongIds;
    if (base.isEmpty) return;
    _base = List.of(base);
    _order = _shuffle ? _shuffled(base, first: id) : List.of(base);
    _currentId = id;
    _progress = 0;
    _playing = true;
    if (label != null) _contextLabel = label;
    _loadedId = null;
    _ensureLoaded();
    _engine.play();
    navigation.openNowPlaying();
    notifyListeners();
  }

  void togglePlay() {
    if (!hasCurrent) return;
    _playing = !_playing;
    if (_playing) {
      _ensureLoaded();
      _engine.play();
    } else {
      _engine.pause();
    }
    notifyListeners();
  }

  void next({bool auto = false}) {
    if (_order.isEmpty) return;
    final i = _order.indexOf(_currentId ?? '');
    _currentId = _order[(i + 1) % _order.length];
    _progress = 0;
    if (auto) _playing = true;
    _restartSource();
    notifyListeners();
  }

  void prev() {
    if (!hasCurrent) return;
    if (_progress > 3) {
      _progress = 0;
      _engine.seek(Duration.zero);
      notifyListeners();
      return;
    }
    final i = _order.indexOf(_currentId!);
    _currentId = _order[(i - 1 + _order.length) % _order.length];
    _progress = 0;
    _restartSource();
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _order = _shuffle ? _shuffled(_base, first: _currentId) : List.of(_base);
    notifyListeners();
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    notifyListeners();
  }

  void seekToFraction(double fraction) {
    final song = currentSong;
    if (song == null) return;
    _progress = (fraction.clamp(0.0, 1.0) * song.durationSeconds).round();
    _engine.seek(Duration(seconds: _progress));
    notifyListeners();
  }

  void playPlaylist(Playlist playlist, {bool shuffle = false}) {
    if (playlist.songIds.isEmpty) return;
    final first = shuffle
        ? _shuffled(playlist.songIds).first
        : playlist.songIds.first;
    if (shuffle && !_shuffle) _shuffle = true;
    play(first, context: playlist.songIds, label: 'Tocando · ${playlist.name}');
  }

  void playFavorites() {
    final favorites = library.favoriteIds;
    if (favorites.isEmpty) return;
    play(favorites.first, context: favorites, label: 'Suas favoritas');
  }

  void shuffleAll() {
    final all = library.allSongIds;
    if (all.isEmpty) return;
    if (!_shuffle) _shuffle = true;
    play(_shuffled(all).first, context: all, label: 'Modo aleatório');
  }

  // ── Interno ────────────────────────────────────────────────────────────────
  void _onPosition(Duration position) {
    final song = currentSong;
    if (song == null) return;
    final seconds = position.inSeconds;
    final clamped = seconds > song.durationSeconds
        ? song.durationSeconds
        : seconds;
    if (clamped == _progress) return;
    _progress = clamped;
    notifyListeners();
  }

  void _onCompleted() {
    if (!hasCurrent) return;
    if (_repeat) {
      _progress = 0;
      _engine.seek(Duration.zero);
      _engine.play();
      notifyListeners();
    } else {
      next(auto: true);
    }
  }

  /// Recarrega a fonte da faixa atual e retoma se estiver tocando.
  void _restartSource() {
    _loadedId = null;
    _ensureLoaded();
    if (_playing) _engine.play();
  }

  /// Carrega no engine o arquivo da faixa atual, se ainda não carregado.
  void _ensureLoaded() {
    final song = currentSong;
    if (song == null || _loadedId == _currentId) return;
    if (song.uri != null) {
      _engine.load(song.uri!);
      _loadedId = _currentId;
    }
  }

  List<String> _shuffled(List<String> source, {String? first}) {
    final rest = [
      for (final id in source)
        if (id != first) id,
    ];
    for (var i = rest.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final tmp = rest[i];
      rest[i] = rest[j];
      rest[j] = tmp;
    }
    return first != null ? [first, ...rest] : rest;
  }

  @override
  void dispose() {
    _positionSub.cancel();
    _completedSub.cancel();
    _engine.dispose();
    super.dispose();
  }
}
