import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/widgets/marquee_text.dart';

const _long = 'Um título de música muito muito muito longo demais';

Widget _host(String text, {required bool enabled, required double width}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: width,
          child: MarqueeText(
            text: text,
            enabled: enabled,
            style: const TextStyle(fontSize: 20),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('rola (2 cópias) quando transborda e está tocando', (
    tester,
  ) async {
    await tester.pumpWidget(_host(_long, enabled: true, width: 60));
    await tester.pump();
    expect(find.text(_long), findsNWidgets(2));
  });

  testWidgets('estático quando o texto cabe', (tester) async {
    await tester.pumpWidget(_host('Oi', enabled: true, width: 300));
    await tester.pump();
    expect(find.text('Oi'), findsOneWidget);
  });

  testWidgets('não rola quando pausado (enabled false)', (tester) async {
    await tester.pumpWidget(_host(_long, enabled: false, width: 60));
    await tester.pump();
    expect(find.text(_long), findsOneWidget);
  });
}
