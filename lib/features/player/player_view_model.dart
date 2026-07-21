import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    this.prefs,
    Random? random,
  }) : _random = random ?? Random() {
    _engine = engine;
    _currentId = library.allSongIds.isEmpty ? null : library.allSongIds.first;
    _base = library.allSongIds;
    _order = library.allSongIds;

    if (prefs != null) {
      final savedId = prefs!.getString('player_current_id');
      if (savedId != null && library.songByIdOrNull(savedId) != null) {
        _currentId = savedId;
      }
      _progress = prefs!.getInt('player_progress') ?? 0;
      _shuffle = prefs!.getBool('player_shuffle') ?? false;
      _repeat = prefs!.getBool('player_repeat') ?? false;

      final savedBase = prefs!.getStringList('player_base');
      if (savedBase != null && savedBase.isNotEmpty) _base = savedBase;

      final savedOrder = prefs!.getStringList('player_order');
      if (savedOrder != null && savedOrder.isNotEmpty) _order = savedOrder;

      _contextLabel =
          prefs!.getString('player_context') ?? 'Tocando da biblioteca';
    }

    _positionSub = _engine.positionStream.listen(_onPosition);
    _completedSub = _engine.onCompleted.listen((_) => _onCompleted());
    _remoteSub = _engine.remoteActions.listen(_onRemoteAction);
    _engine.setShuffleActive(_shuffle);

    if (_currentId != null && _progress > 0) {
      _ensureLoaded();
      _engine.seek(Duration(seconds: _progress));
    }
  }

  final LibraryStore library;
  final NavigationController navigation;
  late final AudioEngine _engine;
  final SharedPreferences? prefs;
  final Random _random;
  late final StreamSubscription<Duration> _positionSub;
  late final StreamSubscription<void> _completedSub;
  late final StreamSubscription<PlayerRemoteAction> _remoteSub;

  String? _currentId;
  String? _loadedId;
  int _progress = 0;
  Duration _position = Duration.zero;
  bool _playing = false;
  bool _scrubbing = false;
  bool _wasPlayingBeforeScrub = false;
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

  /// Posição de reprodução com precisão de milissegundos (para sincronizar a
  /// letra); [progressSeconds] continua em segundos para o resto da UI.
  Duration get position => _position;
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

  void _saveState() {
    if (prefs == null) return;
    if (_currentId != null) prefs!.setString('player_current_id', _currentId!);
    prefs!.setInt('player_progress', _progress);
    prefs!.setBool('player_shuffle', _shuffle);
    prefs!.setBool('player_repeat', _repeat);
    prefs!.setStringList('player_base', _base);
    prefs!.setStringList('player_order', _order);
    prefs!.setString('player_context', _contextLabel);
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
    _engine.setShuffleActive(_shuffle);
    _engine.play();
    navigation.openNowPlaying();
    _saveState();
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
    _saveState();
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
    _saveState();
    notifyListeners();
  }

  void toggleShuffle() {
    _shuffle = !_shuffle;
    _order = _shuffle ? _shuffled(_base, first: _currentId) : List.of(_base);
    _engine.setShuffleActive(_shuffle);
    _saveState();
    notifyListeners();
  }

  /// Traduz um toque nos controles da notificação em comando de reprodução,
  /// mantendo o [PlayerViewModel] como fonte única de verdade.
  void _onRemoteAction(PlayerRemoteAction action) {
    switch (action) {
      case PlayerRemoteAction.play:
        if (!_playing) togglePlay();
      case PlayerRemoteAction.pause:
        if (_playing) togglePlay();
      case PlayerRemoteAction.next:
        next();
      case PlayerRemoteAction.previous:
        prev();
      case PlayerRemoteAction.shuffle:
        toggleShuffle();
    }
  }

  void toggleRepeat() {
    _repeat = !_repeat;
    _saveState();
    notifyListeners();
  }

  void seekToFraction(double fraction) {
    final song = currentSong;
    if (song == null) return;
    _progress = (fraction.clamp(0.0, 1.0) * song.durationSeconds).round();
    _position = Duration(seconds: _progress);
    _engine.seek(Duration(seconds: _progress));
    prefs?.setInt('player_progress', _progress);
    notifyListeners();
  }

  /// Posiciona a reprodução num instante exato (ex.: tocar em uma linha da
  /// letra sincronizada). Limita entre zero e a duração da faixa.
  void seekTo(Duration position) {
    final song = currentSong;
    if (song == null) return;
    final max = Duration(seconds: song.durationSeconds);
    final clamped = position < Duration.zero
        ? Duration.zero
        : (position > max ? max : position);
    _position = clamped;
    _progress = clamped.inSeconds;
    _engine.seek(clamped);
    prefs?.setInt('player_progress', _progress);
    notifyListeners();
  }

  bool get isScrubbing => _scrubbing;

  /// Entra no modo de arrastar o tempo: pausa o áudio (fluido, sem lutar com o
  /// stream de posição) e lembra se estava tocando para retomar ao soltar.
  void beginScrub() {
    if (!hasCurrent || _scrubbing) return;
    _scrubbing = true;
    _wasPlayingBeforeScrub = _playing;
    if (_playing) _engine.pause();
  }

  /// Sai do modo de arrastar: posiciona na fração final e só então retoma.
  void endScrub(double fraction) {
    if (!_scrubbing) return;
    _scrubbing = false;
    seekToFraction(fraction);
    if (_wasPlayingBeforeScrub) _engine.play();
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
    if (_scrubbing) return;
    final song = currentSong;
    if (song == null) return;
    final max = Duration(seconds: song.durationSeconds);
    _position = position > max ? max : position;
    final seconds = _position.inSeconds;
    if (seconds != _progress) {
      _progress = seconds;
      prefs?.setInt('player_progress', _progress);
    }
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
      _engine.load(song);
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
    _remoteSub.cancel();
    _engine.dispose();
    super.dispose();
  }
}
