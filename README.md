# 🎵 PMPlayer

> **Player de Música Offline de Alta Performance para Flutter**  
> Um tocador de áudio local moderno, fluído (60/120 FPS), responsivo e totalmente offline, construído com arquitetura MVVM orientada a recursos (*feature-wise*) e design refinado no padrão dos grandes players.

---

## 📸 Destaques do Projeto

- 🎨 **Design Moderno & Tipografia Spotify**: Interface visual refinada utilizando a tipografia geométrica moderna **Figtree**, degradês dinâmicos adaptados às cores da capa do álbum, efeito glassmorphic e suporte a temas.
- ⚡ **Desempenho Ponta a Ponta**: 0% de travamento ou skip de frames. Varredura recursiva de arquivos e leitura de metadados em segundo plano via **Isolates em streaming**.
- 🔄 **Controles por Gestos (Swipe)**: Deslize o miniplayer para a esquerda para avançar de faixa ou para a direita para voltar, além dos botões rápidos integrados.
- 🎤 **Letras Sincronizadas & Arte 3D**: Efeito de cartão 3D giratório para alternar entre a capa de alta resolução e as letras da música.
- 🔍 **Busca Instantânea O(1)**: Algoritmo de normalização de texto ultrarrápido por código de caracteres (`codeUnits`) e consulta de faixas favoritas em tempo constante.
- 📱 **100% Offline & Seguro**: Varredura direta de arquivos locais do dispositivo sem dependência de conexões de rede ou servidores externos.

---

## 🏗️ Arquitetura & Tecnologias

O projeto segue estritamente o padrão **MVVM Feature-Wise** e os princípios do **Clean Code** e **TDD**:

```
lib/
├── app_widget.dart               # Configuração global de temas, rotas e providers
├── main.dart                     # Ponto de entrada do aplicativo
├── core/                         # Módulos compartilhados e infraestrutura
│   ├── data/                     # Repositório SQLite (Drift) e modelos de dados
│   ├── models/                   # Entidades imutáveis (Song, Playlist, Lyrics)
│   ├── playback/                 # Motor de áudio (just_audio / audio_service)
│   ├── state/                    # Estado global da biblioteca (LibraryStore)
│   ├── theme/                    # Tokens de cor, sombras e tipografia (Figtree)
│   ├── utils/                    # Utilitários de UI e normalização
│   └── widgets/                  # Componentes reutilizáveis (MarqueeText, CoverArtwork, etc.)
└── features/                     # Recursos organizados por contexto (MVVM)
    ├── favorites/                # Tela de músicas favoritas
    ├── library/                  # Tela principal de reprodução e importador Isolate
    ├── navigation/               # Navegação e controlador de abas
    ├── player/                   # Miniplayer, player em tela cheia e letras
    ├── playlists/                # Gerenciamento de playlists e sheets
    ├── settings/                 # Configurações de tema e preferências
    └── shell/                    # App Shell e estrutura de layouts
```

### Principais Bibliotecas Utilizadas
- **Flutter Framework** (`Material 3`)
- **State Management & DI**: `provider`
- **Áudio & Notificações**: `just_audio`, `audio_service`
- **Leitura de Metadados**: `audio_metadata_reader`
- **Banco de Dados Local**: `drift`, `sqlite3_flutter_libs`
- **Arquivos & Permissões**: `file_picker`, `permission_handler`, `path_provider`

---

## 🚀 Engenharia de Performance

Para atingir taxa constante de **60/120 FPS** sem nenhum consumo excessivo de CPU ou memória:

1. **Streaming Isolate Worker (`_importIsolateWorker`)**: A varredura de diretórios, extração de capas e leitura de metadados ID3/MP4/FLAC rodam em um Isolate dedicado via `Isolate.spawn`, transmitindo chunks via `ReceivePort` sem travar a UI thread.
2. **Cálculo de Cores de Paleta em Pure Dart**: Extração de cores dominantes feita diretamente dos bytes em Dart puro dentro do Isolate, eliminando o overhead de decodificação `dart:ui`/`PaletteGenerator` na thread principal.
3. **Reconstruções Seletivas (`context.select`)**: Os tiques de milissegundos do progresso de áudio são isolados com `Selector`, garantindo que apenas o slider de progresso seja reconstruído durante a reprodução.
4. **Otimização de Memória RAM em Capas**: Utilização de `ResizeImage` sobre `FileImage` para decodificar capas locais exatamente nas dimensões de exibição do display.
5. **Busca O(1)**: `Set<String>` indexado em memória para checagem imediata de favoritas.

---

## 🛠️ Como Executar o Projeto

### Pré-requisitos
- **Flutter SDK**: 3.29.0 ou superior
- **Dart SDK**: 3.7.0 ou superior

### Passos para Instalação e Execução

```bash
# 1. Clone o repositório
git clone https://github.com/luizfiuzaa/pmplayer.git
cd pmplayer

# 2. Instale as dependências
flutter pub get

# 3. Execute a análise estática
flutter analyze

# 4. Execute a suíte completa de testes automatizados
flutter test

# 5. Execute o projeto no seu dispositivo ou emulador
flutter run
```

---

## 🧪 Testes Automatizados

O projeto possui cobertura completa de testes unitários e de widgets (127+ testes passando):

```bash
# Executar todos os testes
flutter test

# Executar arquivo de teste específico
flutter test test/features/player/mini_player_test.dart

# Executar teste por nome
flutter test test/features/player/mini_player_test.dart --name "Arrastar"
```

---

## 📄 Licença e Registro de Alterações

Todas as melhorias, otimizações e novos recursos são mantidos e documentados rigorosamente no arquivo [`CHANGELOG.md`](./CHANGELOG.md).
