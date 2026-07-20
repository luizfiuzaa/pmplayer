import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

/// Faixas importadas. `position` preserva a ordem de inserção.
@DataClassName('SongRow')
class Songs extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get artist => text()();
  IntColumn get durationSeconds => integer()();
  TextColumn get uri => text().nullable()();

  /// Paleta da capa como JSON (lista de inteiros ARGB); nula = capa genérica.
  TextColumn get paletteJson => text().nullable()();

  /// Caminho da imagem de capa (arte embutida extraída dos metadados).
  TextColumn get coverPath => text().nullable()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Playlists do usuário. `songIdsJson` guarda a lista ordenada de ids.
@DataClassName('PlaylistRow')
class Playlists extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get coverSlotId => text().nullable()();

  /// Caminho de uma imagem escolhida como capa da playlist.
  TextColumn get coverPath => text().nullable()();
  TextColumn get songIdsJson => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Favoritas — apenas o id da faixa e a ordem em que foram marcadas.
@DataClassName('FavoriteRow')
class FavoriteSongs extends Table {
  TextColumn get songId => text()();
  IntColumn get position => integer()();

  @override
  Set<Column<Object>> get primaryKey => {songId};
}

@DriftDatabase(tables: [Songs, Playlists, FavoriteSongs])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'pmplayer'));

  /// Construtor para testes (ex.: banco em memória).
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(songs, songs.coverPath);
        await m.addColumn(playlists, playlists.coverPath);
      }
    },
  );
}
