import 'package:flutter/material.dart';
import 'package:pmplayer/core/models/song.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Song.durationLabel', () {
    test('formata segundos como m:ss com zero à esquerda', () {
      expect(
        const Song(
          id: 's',
          title: 't',
          artist: 'a',
          durationSeconds: 214,
        ).durationLabel,
        '3:34',
      );
    });

    test('preenche os segundos abaixo de dez', () {
      expect(
        const Song(
          id: 's',
          title: 't',
          artist: 'a',
          durationSeconds: 205,
        ).durationLabel,
        '3:25',
      );
    });

    test('trata durações abaixo de um minuto', () {
      expect(
        const Song(
          id: 's',
          title: 't',
          artist: 'a',
          durationSeconds: 9,
        ).durationLabel,
        '0:09',
      );
    });
  });

  group('Song.isGeneric', () {
    test('é genérica quando não há paleta', () {
      expect(
        const Song(
          id: 's',
          title: 't',
          artist: 'a',
          durationSeconds: 10,
        ).isGeneric,
        isTrue,
      );
    });

    test('não é genérica quando há paleta', () {
      expect(
        const Song(
          id: 's',
          title: 't',
          artist: 'a',
          durationSeconds: 10,
          palette: [Color(0xFF000000), Color(0xFFFFFFFF)],
        ).isGeneric,
        isFalse,
      );
    });
  });
}
