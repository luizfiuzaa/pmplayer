import 'package:audio_service/audio_service.dart';
import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_widget.dart';
import 'core/data/database/app_database.dart';
import 'core/data/drift_library_repository.dart';
import 'core/playback/audio_service_engine.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';

import 'core/playback/pm_audio_handler.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Platform.isAndroid) {
    if (await Permission.notification.status.isDenied) {
      await Permission.notification.request();
    }
  }
  final handler = await AudioService.init(
    builder: () => PmAudioHandler(AudioPlayer()),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.example.pmplayer.channel.audio',
      androidNotificationChannelName: 'Audio playback',
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );
  final repository = DriftLibraryRepository(AppDatabase());
  final snapshot = await repository.load();
  final prefs = await SharedPreferences.getInstance();

  runApp(
    PmPlayerApp(
      initial: snapshot,
      repository: repository,
      engine: AudioServiceEngine(handler),
      prefs: prefs,
    ),
  );
}
