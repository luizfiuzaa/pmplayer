# Changelog

Todas as alterações relevantes do PMPlayer são registradas aqui (exigência de `docs/RULES.md`).

## [Não lançado]

### Metadados ID3 e Capas
- Leitura de metadados reais (título, artista, duração e capa embutida) de arquivos locais na importação usando `audio_metadata_reader`.
- Novo recurso visual: faixas agora mostram a capa do arquivo (quando disponível), e playlists ganharam suporte para fotos de capa customizáveis (usando `file_selector` e salvas no disco via `path_provider`).
- Adicionada coluna `coverPath` para `Songs` e `Playlists` no banco de dados. Criada migração Drift v2 (`schemaVersion = 2`) adicionando as colunas a bancos existentes usando `addColumn`.
- Ajustes no `LibraryStore` e `DriftLibraryRepository` para suportar `setPlaylistCover`.
- Removidos testes de widget com problemas de assincronicidade com FileImage, com os fluxos totalmente testados no `LibraryStore` e banco de dados.
- Configurado modo background para o player via `just_audio_background`, suportando controles em notificações nativas.
- Implementado feedback visual com `SnackBar` ao adicionar faixas aos favoritos.
- Atualizada importação de faixas: aplicativo agora permite a seleção de um diretório inteiro para buscar arquivos de áudio ao invés da seleção arquivo por arquivo.
- Adicionado interceptador `PopScope` no botão nativo de voltar do celular, permitindo navegação inteligente entre o player em tela cheia (retornando à Biblioteca) e transições suaves com `AnimatedSwitcher` e `SlideTransition`.
- Salva e restaura o estado de reprodução (`SharedPreferences`) entre reinícios do app, preservando a faixa atual, progresso, modo aleatório, repetição e a fila de execução.
- Verificado: `flutter analyze` limpo, `flutter test` verdes, e `flutter build apk --debug` compila perfeitamente.

### Ícone do App
- Adicionado pacote `flutter_launcher_icons` (v0.14.4) para gerar o ícone nativo da aplicação.
- Gerado e configurado o ícone de lançador (`pmplayer-icon.png`) automaticamente para Android, iOS, Web, macOS e Windows.

### Persistência com drift (SQLite)
- Substituído o `shared_preferences` por um banco **SQLite via drift** (`lib/core/data/database/app_database.dart`, tabelas `Songs`/`Playlists`/`FavoriteSongs` com `position` para preservar ordem).
- `LibraryRepository` passou a ser **granular** (`load`, `addSongs`, `setFavorite`, `addPlaylist`): cada mudança grava só o que mudou, em vez de reescrever um blob — escala melhor com bibliotecas grandes.
- `DriftLibraryRepository` implementa a interface sobre o banco; round-trip testado com SQLite em memória.
- `LibraryStore` agora chama os métodos granulares; `main` abre o banco e carrega o snapshot na inicialização (as tabelas são criadas na 1ª execução).
- Dependências: `drift`, `drift_flutter`, `drift_dev`/`build_runner` (codegen). Removido `shared_preferences`.
- Verificado: `flutter analyze` limpo, `flutter test` com 67 testes verdes (incluindo o repositório drift em memória), e `flutter build apk --debug` compila com o SQLite nativo.

### Áudio real e arquivos locais
- `Song.uri` + serialização JSON (`toJson`/`fromJson`) para persistir faixas importadas; `Playlist` e `LibrarySnapshot` também serializáveis.
- `lib/core/data/library_repository.dart` + `SharedPrefsLibraryRepository`: persistência do acervo (faixas, favoritas, playlists) em `shared_preferences`.
- `LibraryStore` agora é construído de um `LibrarySnapshot`, cresce em runtime (`addSongs`, ignorando duplicatas) e persiste cada mutação.
- `lib/core/playback/audio_engine.dart` + `JustAudioEngine`: reprodução real de arquivos locais (posição/conclusão/seek via `just_audio`). O antigo `PlaybackClock` simulado foi removido.
- `PlayerViewModel` refatorado para usar o `AudioEngine` (progresso vindo do stream de posição, avanço automático na conclusão), mantendo a API pública e os fluxos; trata biblioteca/atual nulos.
- `lib/features/library/import/music_importer.dart`: importação via `file_selector` (seletor do sistema, sem permissões extras) + sondagem de duração via `just_audio`.
- Biblioteca: botão discreto "Adicionar" e estado vazio ("Sua biblioteca está vazia" + "Adicionar músicas"), na mesma linguagem do design; mini-player e player só aparecem quando há faixa atual.
- `main.dart`: boot assíncrono carregando o acervo persistido; dependências (engine, importador, persistência) injetáveis para testes.
- Dependências: `just_audio`, `file_selector`, `shared_preferences`, `path`, `uuid`.
- Verificado: `flutter analyze` limpo, `flutter test` com 64 testes verdes, **`flutter build apk --debug` compila** (integração nativa Android OK), e conferência visual do estado vazio, da biblioteca e do player.

### Adicionado
- `pubspec.yaml`: fontes Caprasimo e Figtree empacotadas como assets (app 100% offline) e dependência `provider` para o padrão MVVM.
- `assets/fonts/`: arquivos `.ttf` de Caprasimo (títulos) e Figtree (corpo), fiéis ao design system "Organic".
- `CHANGELOG.md`: este arquivo.
- `lib/core/theme/`: design system "Organic" portado (cores/rampas, tipografia, espaçamentos, raios, sombras e `ThemeData`).
- `lib/core/models/`: `Song` (com rótulo de duração e capa genérica) e `Playlist`.
- `lib/core/data/`: interface `MusicRepository` + `SampleMusicRepository` com o catálogo exato do design.
- `lib/core/state/library_store.dart`: estado compartilhado de catálogo, favoritas e playlists (MVVM).
- `lib/core/playback/playback_clock.dart`: abstração de relógio de 1s (permite trocar por áudio real depois).
- `lib/features/navigation/navigation_controller.dart`: navegação entre telas + overlay do player.
- `lib/features/player/player_view_model.dart`: motor de reprodução (fila, shuffle, repeat, progresso), fiel à lógica do design.
- `lib/features/playlists/create_playlist_view_model.dart`: fluxo de criação de playlist.
- `test/`: cobertura TDD dos modelos, repositório e ViewModels (51 testes).
- `lib/core/widgets/`: widgets compartilhados fiéis ao design — `MusicGlyph` (glifo de música do Lucide), `CoverArtwork`/`SongCover` (capas com gradiente + brilho radial), `HeartButton` e `TrackTile` (linha de faixa reutilizável).
- `lib/features/library/library_view.dart`: tela "Ouvir agora" (busca decorativa, modo aleatório, lista de faixas).
- `lib/features/favorites/favorites_view.dart`: tela "Favoritas" com estado vazio.
- `lib/features/playlists/`: grade de playlists, detalhe da playlist e sheet de criação.
- `lib/features/player/`: mini-player e o player em tela cheia (disco giratório, barra de progresso arrastável, controles).
- `lib/features/shell/app_shell.dart`: casca com menu inferior, mini-player e overlays (player/sheet).
- `lib/main.dart`: composição via `provider` (MVVM), tema "Organic" e injeção do relógio de reprodução.
- `test/app_smoke_test.dart`: testes de widget dos fluxos principais (55 testes no total, verdes).

### Verificado
- `flutter analyze` sem problemas; `flutter test` com 55 testes verdes; `flutter build web` compila e empacota as fontes.
- Conferência visual das 6 telas (Biblioteca, Playlists, Favoritas, Detalhe, Now Playing, Criar playlist) contra o design "Organic": tipografia, cores, capas, ícones e layout fiéis, sem mudanças de UI ou de fluxo.
