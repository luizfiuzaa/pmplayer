import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pmplayer/core/theme/app_colors.dart';
import 'package:pmplayer/core/theme/app_theme.dart';
import 'package:pmplayer/core/theme/app_typography.dart';

Color _resolvedColor(WidgetTester tester, String text) {
  final richText = tester.widget<RichText>(
    find.descendant(of: find.text(text), matching: find.byType(RichText)),
  );
  return (richText.text as TextSpan).style!.color!;
}

Future<void> _pump(
  WidgetTester tester,
  Brightness brightness,
  TextStyle style,
) {
  return tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.build(AppColors.light, Brightness.light),
      darkTheme: AppTheme.build(AppColors.dark, Brightness.dark),
      themeMode: brightness == Brightness.dark
          ? ThemeMode.dark
          : ThemeMode.light,
      home: Scaffold(body: Text('token', style: style)),
    ),
  );
}

void main() {
  group('AppTypography inherits theme text color', () {
    testWidgets('bodyStyle uses light text in dark mode', (tester) async {
      await _pump(tester, Brightness.dark, AppTypography.bodyStyle());
      expect(_resolvedColor(tester, 'token'), AppColors.dark.text);
    });

    testWidgets('headingStyle uses light text in dark mode', (tester) async {
      await _pump(
        tester,
        Brightness.dark,
        AppTypography.headingStyle(size: 20),
      );
      expect(_resolvedColor(tester, 'token'), AppColors.dark.text);
    });

    testWidgets('bodyStyle uses dark text in light mode', (tester) async {
      await _pump(tester, Brightness.light, AppTypography.bodyStyle());
      expect(_resolvedColor(tester, 'token'), AppColors.light.text);
    });

    testWidgets('explicit color still wins', (tester) async {
      await _pump(
        tester,
        Brightness.dark,
        AppTypography.bodyStyle(color: AppColors.dark.accent),
      );
      expect(_resolvedColor(tester, 'token'), AppColors.dark.accent);
    });

    test('heading usa Figtree no estilo Spotify em vez de fonte cursiva', () {
      expect(AppTypography.heading, 'Figtree');
      final style = AppTypography.headingStyle(size: 24);
      expect(style.fontFamily, 'Figtree');
      expect(style.fontWeight, FontWeight.w700);
    });
  });
}
