import 'package:flutter/foundation.dart';

/// Uma linha de letra. [time] nulo quando a letra não é sincronizada (sem
/// timestamps LRC).
@immutable
class LyricLine {
  const LyricLine(this.time, this.text);

  final Duration? time;
  final String text;
}

/// Letra já tratada. Aceita texto simples ou o formato LRC (com timestamps
/// `[mm:ss.xx]` e tags de metadados `[ti:]`, `[ar:]`, `[by:]`, `[offset:]`…).
@immutable
class Lyrics {
  const Lyrics(this.lines, {required this.synced});

  final List<LyricLine> lines;

  /// `true` quando há timestamps (permite acompanhar/rolar em sincronia).
  final bool synced;

  bool get isEmpty => lines.isEmpty;
  bool get isNotEmpty => lines.isNotEmpty;

  /// Todas as linhas juntas, sem timestamps nem metadados.
  String get plainText => lines.map((l) => l.text).join('\n');

  static const empty = Lyrics(<LyricLine>[], synced: false);

  // Metadados LRC (`[ti:...]`, `[ar:...]`, `[by:...]`, `[offset:...]`): a chave
  // começa com letra. Timestamps começam com dígito, então não casam aqui.
  static final _meta = RegExp(r'\[[a-zA-Z][a-zA-Z0-9]*:[^\]]*\]');
  static final _timestamp = RegExp(r'\[(\d{1,3}):(\d{2})(?:[.:](\d{1,3}))?\]');
  static final _offset = RegExp(
    r'\[offset:\s*([+-]?\d+)\s*\]',
    caseSensitive: false,
  );
  static final _spaces = RegExp(r'\s+');

  /// Interpreta a letra crua (LRC ou texto simples).
  factory Lyrics.parse(String? raw) {
    if (raw == null || raw.trim().isEmpty) return empty;

    final offsetMatch = _offset.firstMatch(raw);
    final offsetMs = offsetMatch != null
        ? (int.tryParse(offsetMatch.group(1)!) ?? 0)
        : 0;

    final cleaned = raw.replaceAll(_meta, '');
    final matches = _timestamp.allMatches(cleaned).toList();

    // Sem timestamps: texto simples, uma linha por linha não vazia.
    if (matches.isEmpty) {
      final lines = <LyricLine>[
        for (final line in cleaned.split('\n'))
          if (line.trim().isNotEmpty) LyricLine(null, line.trim()),
      ];
      return lines.isEmpty ? empty : Lyrics(lines, synced: false);
    }

    // Com timestamps: o texto entre um timestamp e o próximo pertence a ele
    // (trata linhas quebradas e timestamps no meio do texto).
    final lines = <LyricLine>[];
    for (var i = 0; i < matches.length; i++) {
      final m = matches[i];
      final end = i + 1 < matches.length
          ? matches[i + 1].start
          : cleaned.length;
      final text = cleaned
          .substring(m.end, end)
          .replaceAll('\n', ' ')
          .replaceAll(_spaces, ' ')
          .trim();
      if (text.isEmpty) continue;

      final minutes = int.parse(m.group(1)!);
      final seconds = int.parse(m.group(2)!);
      final fraction = m.group(3);
      final millis = fraction == null
          ? 0
          : int.parse(fraction.padRight(3, '0').substring(0, 3));
      var time =
          Duration(minutes: minutes, seconds: seconds, milliseconds: millis) +
          Duration(milliseconds: offsetMs);
      if (time < Duration.zero) time = Duration.zero;
      lines.add(LyricLine(time, text));
    }

    if (lines.isEmpty) return empty;
    lines.sort((a, b) => a.time!.compareTo(b.time!));
    return Lyrics(lines, synced: true);
  }

  /// Índice da linha ativa em [position] (a última cujo tempo já passou);
  /// `-1` antes da primeira ou quando não sincronizada.
  int activeIndex(Duration position) {
    if (!synced) return -1;
    var index = -1;
    for (var i = 0; i < lines.length; i++) {
      if (lines[i].time! <= position) {
        index = i;
      } else {
        break;
      }
    }
    return index;
  }
}
