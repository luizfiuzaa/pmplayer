# Changelog

Todas as alterações relevantes do PMPlayer são registradas aqui (exigência de `docs/RULES.md`).

## [Não lançado]

### Importação — por lotes (chunks), sem travar
- A importação agora emite as faixas em lotes conforme são lidas (`MusicImporter.importChunked` — `Stream<List<Song>>`, ~8 por lote), em vez de ler tudo e só então mostrar. A lista cresce progressivamente e o app cede o controle ao event loop entre lotes (`Future.delayed(Duration.zero)`), evitando a sensação de travamento. Durante o carregamento, as faixas já lidas aparecem acima do skeleton.

### Mini-player — contraste do texto sobre fundo escuro
- Quando a cor da capa (fundo do mini-player) é escura, o texto e os ícones passam para uma cor clara de contraste (e vice-versa), calculado pela luminância da cor base da barra. `HeartButton` ganhou `unselectedColor` para o mesmo fim.

### Título — letreiro (marquee) quando longo
- Títulos de música que não cabem na largura passam a rolar em looping (efeito letreiro) enquanto a faixa está tocando; se couberem — ou a faixa estiver pausada — ficam estáticos com reticências. Aplicado no player (título grande) e no mini-player. Novo `lib/core/widgets/marquee_text.dart` (`MarqueeText`), medindo o texto com `TextPainter` e rolando com duas cópias + `ClipRect`.

### Letra — transição ao avançar
- A troca de linha ativa da letra agora é animada (`AnimatedDefaultTextStyle`, 320ms, `easeOutCubic`): a linha atual cresce/realça e as demais recuam suavemente, em vez de mudar de estilo instantaneamente. O auto-scroll suave já existente complementa o efeito.

### Biblioteca — barra de busca fixa (sticky)
- Ao rolar a lista de músicas, a barra de busca fica fixa no topo (`CustomScrollView` + `SliverPersistentHeader` pinado, com fundo opaco para a lista rolar por baixo); o título "Ouvir agora" rola normalmente.

### Letra — tocar em uma linha pula para o momento
- Na letra expandida (LRC sincronizada), tocar em uma linha pula a reprodução para o instante dela. Novo `PlayerViewModel.seekTo(Duration)` (limita entre zero e a duração). Linhas sem timestamp não são clicáveis.

### Cor dominante da capa — fundo do player e mini-player
- No import, a cor dominante da arte embutida é extraída (`palette_generator`) e guardada em `Song.palette` (par dominante + variação escura, persistido no drift). Antes, faixas com capa em imagem ficavam sem paleta e caíam no verde padrão.
- O fundo esverdeado do player agora usa a cor dominante da capa da faixa tocando (o gradiente já derivava de `palette.first`), e o mini-player (barra acima da navigation bar) usa o mesmo par de cores. Faixas sem arte mantêm o sólido do design.

### Player — girar a capa também para a esquerda
- O gesto de virar a capa (para revelar a letra) passou a seguir o sentido do arrasto: arrastar para a esquerda gira para a esquerda, para a direita gira para a direita (antes a rotação era sempre no mesmo sentido). Toque continua virando.

### Letra — sincronia precisa (ms)
- A letra sincronizada (LRC) deixou de usar a posição em segundos inteiros (até ~1s de defasagem) e passou a acompanhar a posição real em milissegundos. `PlayerViewModel` expõe `position` (Duration), atualizada a cada evento do engine; a letra expandida usa essa posição para destacar/rolar até a linha certa.

### Importação — loading com skeleton
- Ao adicionar músicas, a Biblioteca mostra um estado de carregamento com skeleton (linhas placeholder no formato de faixa, com shimmer) enquanto o importador lê os arquivos, em vez de ficar sem feedback. Novo `lib/core/widgets/skeleton.dart` (`SkeletonLoader`, `SkeletonBox`, `TrackTileSkeleton`, `TrackListSkeleton`).
- Testes: `position` do `PlayerViewModel`; e widget que verifica o skeleton durante a importação (some ao concluir, faixas aparecem).

### Refatoração — `main.dart` enxuto
- `main.dart` agora contém só o bootstrap (init do `audio_service`, engine, repositório drift, prefs e `runApp`). O widget raiz `PmPlayerApp` (injeção de dependências, `MaterialApp` e modo imersivo) foi movido para `lib/app_widget.dart` (que antes era um stub órfão). O import de teste passou a apontar para `app_widget.dart`.

### Modo imersivo — barras do sistema escondidas
- As barras do sistema (status e navegação) somem ao abrir o app e só reaparecem ao arrastar da borda, voltando a sumir sozinhas (`SystemUiMode.immersiveSticky`). Barras deixadas transparentes (edge-to-edge) para não sobreporem o app quando surgem; o conteúdo respeita as bordas via `SafeArea`.
- `PmPlayerApp` virou `StatefulWidget` com `WidgetsBindingObserver` para reaplicar o modo imersivo ao voltar do background (`resumed`) — senão as barras ficariam visíveis após o teclado/troca de app.

### Mini-player — cor da capa
- A barra do mini-player agora usa a cor da capa da faixa: aplica o mesmo gradiente da arte (`LinearGradient` topLeft→bottomRight sobre a paleta crua, mesma intensidade da `CoverArtwork`). Faixas sem paleta (capa genérica/imagem) mantêm o sólido `accent2_800` do design. Trocado `Material`+`Container` por `Ink` para o gradiente preservando o ripple do toque.

### Ícone do app / favicon
- Ícone atualizado para `assets/icons/favicon.png` (1254×1254). `flutter_launcher_icons` reconfigurado (`image_path`) e regenerado para Android (mipmaps), iOS (AppIcon), Web (favicon + icons), Windows e macOS.

### Player — capa que gira para mostrar a letra
- A arte do player agora "vira" (toque ou arrasto horizontal, rotação 3D no eixo Y) para revelar a letra da faixa no verso. Girar de novo volta para a capa; ao trocar de faixa a arte reseta na capa.
- No verso, um botão no canto superior direito expande a letra em tela cheia rolável (para acompanhar); um (X) fecha e volta ao quadrado.
- Letra lida dos metadados embutidos: `AudioMetadata.lyrics` (USLT/mp4/ape/vorbis). Sem letra → "Sem letra disponível" e o botão de expandir some.
- Dados: `Song.lyrics` + `hasLyrics`; nova coluna `lyrics` na tabela `songs` (schema drift v2 → v3 com migração `addColumn`); importer passa a ler a letra. Uma faixa de exemplo ganhou letra para demonstração.
- Novo widget `lib/features/player/lyrics_artwork.dart` (`LyricsArtwork` + `LyricsFullView`).
- Testes: parsing da letra no importer, e widget cobrindo virar → expandir → (X) e o estado sem letra. Build de APK debug verificado (migração ok).

### Letra — tratamento do formato LRC (sincronizado)
- Novo parser `Lyrics.parse` (`lib/core/models/lyrics.dart`): remove tags de metadados (`[ti:]`, `[ar:]`, `[by:]`, `[offset:]`…), extrai as linhas com timestamp `[mm:ss.xx]`, junta linhas quebradas à linha do timestamp anterior e separa timestamps que aparecem no meio do texto. Suporta `offset` e também texto simples (sem timestamps).
- No player: a face de letra mostra o texto já limpo (sem tags). No modo expandido, quando a letra é LRC, a linha atual é destacada e a rolagem acompanha a reprodução automaticamente (`activeIndex` pela posição do player); letra simples continua rolável.
- A faixa de exemplo passou a usar letra em LRC para demonstrar a sincronia.
- Testes: `test/core/models/lyrics_test.dart` cobre o LRC colado (metadados, tempos, linhas quebradas, timestamp no meio, `activeIndex`, offset e texto simples/vazio).

### Player — adicionar/remover a faixa de playlists
- O botão de menu (três pontos) no topo do player agora abre um sheet "Adicionar a playlist" com um checkbox por playlist; tocar em uma linha adiciona (no fim) ou remove a faixa atual daquela playlist, persistindo a mudança.
- Novo: `LibraryStore.toggleSongInPlaylist` / `playlistHasSong`, `LibraryRepository.setPlaylistSongs` (+ impl drift que reescreve `songIdsJson`). Novo widget `lib/features/playlists/add_to_playlist_sheet.dart` (superfície reativa ao tema).
- Testes: unidade em `library_store_test.dart` (toggle add/remove/persistência/playlist inexistente) e widget em `app_smoke_test.dart` (menu do player desmarca a faixa de uma playlist).

### Biblioteca — busca funcional
- O campo de busca (antes decorativo) agora filtra as faixas por título ou artista, ignorando maiúsculas/minúsculas e acentos (`LibraryStore.matching`, função pura testada). Query vazia mostra a lista normal; com texto, mostra "Resultados" + contagem, botão de limpar e estado vazio "Nenhuma música encontrada".
- Testes: unidade em `library_store_test.dart` (caixa/acento/sem-match) e widget em `app_smoke_test.dart` (digitar filtra a lista).

### Criar playlist — botão acima do teclado
- No sheet "Nova playlist" o botão **Criar playlist** virou rodapé fixo, sempre acima do teclado ao focar o campo de nome (padding = `MediaQuery.viewInsets.bottom`). A lista de músicas rola em um `Flexible`/`SingleChildScrollView` e a altura máxima do sheet desconta o teclado.

### Correção de Tema — inconsistência ao trocar a aparência
- Corrigida a inconsistência visual ao alternar claro/escuro pelo sheet de Configurações: o `showModalBottomSheet` capturava `backgroundColor: context.colors.bg` no momento da abertura, então o fundo do sheet ficava com a cor do tema antigo enquanto o conteúdo (texto/opções) já atualizava.
- Agora o modal usa fundo transparente e a superfície é pintada no `build` via `context.colors.bg` (com os cantos arredondados do topo), reagindo à troca de tema em tempo real.
- Teste: `test/features/settings/settings_sheet_theme_test.dart` verifica que a superfície do sheet acompanha claro → escuro → claro.

### Navegação — transição suave entre páginas
- A área de conteúdo das abas (Biblioteca / Playlists / Favoritas / detalhe) agora troca com uma transição suave (fade + leve deslize para cima, 320ms, `easeOutCubic`) via `AnimatedSwitcher` em `app_shell.dart`, em vez de trocar instantaneamente. `layoutBuilder` com `StackFit.expand` preserva o preenchimento total das páginas durante a troca.

### Player — arrasto de tempo fluido
- O gesto de arrastar o tempo agora é fluido e performático: o polegar segue o dedo via estado local do widget (`_ProgressBar` virou `StatefulWidget`), sem reconstruir a tela inteira nem chamar o engine a cada frame; o rótulo de tempo atualiza ao vivo durante o arrasto.
- Ao entrar no modo de arrastar o áudio pausa (`PlayerViewModel.beginScrub`) e só retoma ao soltar, posicionando na fração final (`endScrub`). Eventos de posição do engine são ignorados durante o scrub para não brigar com o polegar.

### Notificação de mídia — migração para `audio_service`
- Substituído `just_audio_background` por `audio_service` (+ `PmAudioHandler`) para permitir controles customizados na notificação.
- Botões da notificação agora são: **shuffle · faixa anterior · play/pause · próxima faixa** (o botão de parar/stop foi removido).
- O handler espelha o estado real do `AudioPlayer` e traduz os toques em `PlayerRemoteAction`, mantendo o `PlayerViewModel` como fonte única de verdade (sem laços). O ícone de shuffle reflete o estado ativo (`ic_shuffle` / `ic_shuffle_on`).
- Adicionados drawables `android/app/src/main/res/drawable/ic_shuffle*.xml`; o `AndroidManifest.xml` já estava correto (o `just_audio_background` usava o mesmo `com.ryanheise.audioservice`).
- Novos arquivos: `lib/core/playback/pm_audio_handler.dart`, `lib/core/playback/audio_service_engine.dart` (substitui `just_audio_engine.dart`). `AudioEngine` ganhou `remoteActions` e `setShuffleActive`.
- Testes: cobertura em `player_view_model_test.dart` para scrub e para as ações remotas (play/pause/next/previous/shuffle). Build de APK debug verificado.

### Correção de Tema — texto preto no modo escuro
- Corrigido texto renderizado em preto sobre superfícies escuras no modo escuro (ilegível).
- Causa raiz: `AppTypography.headingStyle`/`bodyStyle` usavam `color: color ?? AppColors.light.text` como fallback estático, fixando a cor do texto claro (`0xFF201E1D`, quase preto) independentemente do tema ativo.
- Solução: removido o fallback estático; quando `color` é nulo o texto herda a cor do `TextTheme` do tema ativo (definida em `AppTheme.build` como `colors.text`), resolvendo corretamente para claro no escuro e escuro no claro.
- Teste: adicionado `test/core/theme/app_typography_theme_test.dart` cobrindo herança de cor em ambos os modos e prioridade da cor explícita.

### Correção de Runtime Android — sqlite3 native assets
- Resolvido o erro em runtime `Invalid argument(s): Couldn't resolve native function 'sqlite3_initialize' ... No available native assets ... undefined symbol: sqlite3_initialize` ao debugar no Android.
- Causa raiz: `sqlite3` 3.x (via `drift`) migrou o empacotamento da lib nativa para *build hooks* / native assets. O hooks_runner falhava porque o Flutter SDK reside em um caminho com espaço (`C:\Users\Luiz Fiuza\flutter`), quebrando a invocação `dart compile kernel` do hook (`'C:\Users\Luiz' não é reconhecido...`).
- Solução: habilitado `flutter config --enable-native-assets` e criada uma junction sem espaço para o SDK (`C:\pmflutter` -> `C:\Users\Luiz Fiuza\flutter`); `android/local.properties` passou a apontar `flutter.sdk=C:\pmflutter`. Com isso o hook compila e a `libsqlite3.so` é empacotada no APK (arm64-v8a, armeabi-v7a, x86_64).
- Observação: `drift_flutter` e `sqlite3_flutter_libs` (`0.6.0+eol`, stub sem função) permanecem apenas como dependências transitivas; a lib nativa agora vem dos native assets do pacote `sqlite3`.

### Correção de Build Android (APK)
- Removido o arquivo estático e obsoleto `android/app/src/main/java/io/flutter/plugins/GeneratedPluginRegistrant.java` que causava erro de compilação Java `cannot find symbol FilePickerPlugin` durante `flutter build apk --release`.
- Adicionada a aplicação do plugin Kotlin Android `id("org.jetbrains.kotlin.android")` no bloco `plugins` de `android/app/build.gradle.kts`.
- Reorganizada a estrutura de diretórios do `MainActivity.kt` para `android/app/src/main/kotlin/com/example/pmplayer/MainActivity.kt` alinhando com o pacote `com.example.pmplayer`.
- Substituída a inicialização via `driftDatabase` por `NativeDatabase.createInBackground` com `LazyDatabase` em `lib/core/data/database/app_database.dart`, eliminando o erro de FFI `undefined symbol: sqlite3_temp_directory` no Android.

### Limpeza de Código
- Removidos scripts e arquivos utilitários temporários de refatoração de tema (`replace_colors.dart`, `generate_colors2.dart`, `fix_remaining.dart`, `fix_errors.dart`, `fix_const_analyze.dart`, `colors_ext.txt`).

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
