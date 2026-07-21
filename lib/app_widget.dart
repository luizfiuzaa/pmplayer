import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/library_repository.dart';
import 'core/playback/audio_engine.dart';
import 'core/state/library_store.dart';
import 'core/state/settings_store.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/library/import/music_importer.dart';
import 'features/navigation/navigation_controller.dart';
import 'features/player/player_view_model.dart';
import 'features/playlists/cover_image_picker.dart';
import 'features/playlists/create_playlist_view_model.dart';
import 'features/shell/app_shell.dart';

/// Esconde as barras do sistema (status/navigation); reaparecem só ao arrastar
/// da borda e voltam a sumir sozinhas. Barras transparentes (edge-to-edge) para
/// nunca sobreporem o app quando surgem — o conteúdo respeita as bordas via
/// `SafeArea`.
void _applyImmersiveMode() {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
}

/// PMPlayer — reprodutor de áudio offline, arquitetura MVVM feature-wise.
///
/// Monta a injeção de dependências (stores/view-models) e o [MaterialApp]. As
/// dependências são injetáveis para permitir testes com dublês (engine de
/// áudio, importador e persistência falsos).
class PmPlayerApp extends StatefulWidget {
  const PmPlayerApp({
    super.key,
    this.initial = const LibrarySnapshot(),
    this.repository,
    this.engine,
    this.importer,
    this.coverPicker,
    this.prefs,
  });

  final LibrarySnapshot initial;
  final LibraryRepository? repository;
  final AudioEngine? engine;
  final MusicImporter? importer;
  final CoverImagePicker? coverPicker;
  final SharedPreferences? prefs;

  @override
  State<PmPlayerApp> createState() => _PmPlayerAppState();
}

class _PmPlayerAppState extends State<PmPlayerApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _applyImmersiveMode();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Reaplica o modo imersivo ao voltar do background / após o teclado, senão as
  // barras do sistema podem ficar visíveis.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyImmersiveMode();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsStore(widget.prefs)),
        ChangeNotifierProvider(
          create: (_) => LibraryStore(
            initial: widget.initial,
            repository: widget.repository,
          ),
        ),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(
          create: (context) => PlayerViewModel(
            library: context.read<LibraryStore>(),
            navigation: context.read<NavigationController>(),
            engine:
                widget.engine ??
                (throw StateError('PmPlayerApp requer um AudioEngine')),
            prefs: widget.prefs,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CreatePlaylistViewModel(
            library: context.read<LibraryStore>(),
            navigation: context.read<NavigationController>(),
          ),
        ),
        Provider<MusicImporter>(
          create: (_) => widget.importer ?? FileSelectorMusicImporter(),
        ),
        Provider<CoverImagePicker>(
          create: (_) => widget.coverPicker ?? FileSelectorCoverImagePicker(),
        ),
      ],
      child: Consumer<SettingsStore>(
        builder: (context, settings, _) {
          return MaterialApp(
            title: 'PMPlayer',
            debugShowCheckedModeBanner: false,
            themeMode: settings.themeMode,
            theme: AppTheme.build(AppColors.light, Brightness.light),
            darkTheme: AppTheme.build(AppColors.dark, Brightness.dark),
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
