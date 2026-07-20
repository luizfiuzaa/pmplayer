import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/data/database/app_database.dart';
import 'core/data/drift_library_repository.dart';
import 'core/data/library_repository.dart';
import 'core/playback/audio_engine.dart';
import 'core/playback/just_audio_engine.dart';
import 'core/state/library_store.dart';
import 'core/theme/app_theme.dart';
import 'features/library/import/music_importer.dart';
import 'features/navigation/navigation_controller.dart';
import 'features/player/player_view_model.dart';
import 'features/playlists/cover_image_picker.dart';
import 'features/playlists/create_playlist_view_model.dart';
import 'features/shell/app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.example.pmplayer.channel.audio',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );
  final repository = DriftLibraryRepository(AppDatabase());
  final snapshot = await repository.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(PmPlayerApp(initial: snapshot, repository: repository, prefs: prefs));
}

/// PMPlayer — reprodutor de áudio offline, arquitetura MVVM feature-wise.
///
/// As dependências são injetáveis para permitir testes com dublês (engine de
/// áudio, importador e persistência falsos).
class PmPlayerApp extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LibraryStore(initial: initial, repository: repository),
        ),
        ChangeNotifierProvider(create: (_) => NavigationController()),
        ChangeNotifierProvider(
          create: (context) => PlayerViewModel(
            library: context.read<LibraryStore>(),
            navigation: context.read<NavigationController>(),
            engine: engine ?? JustAudioEngine(),
            prefs: prefs,
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => CreatePlaylistViewModel(
            library: context.read<LibraryStore>(),
            navigation: context.read<NavigationController>(),
          ),
        ),
        Provider<MusicImporter>(
          create: (_) => importer ?? FileSelectorMusicImporter(),
        ),
        Provider<CoverImagePicker>(
          create: (_) => coverPicker ?? FileSelectorCoverImagePicker(),
        ),
      ],
      child: MaterialApp(
        title: 'PMPlayer',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.build(),
        home: const AppShell(),
      ),
    );
  }
}
