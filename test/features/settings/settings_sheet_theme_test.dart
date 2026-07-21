import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:pmplayer/core/state/settings_store.dart';
import 'package:pmplayer/core/theme/app_colors.dart';
import 'package:pmplayer/core/theme/app_theme.dart';
import 'package:pmplayer/features/settings/settings_sheet.dart';

/// App mínimo que amarra o tema ao [SettingsStore], como no `main.dart`.
Widget _host() {
  return ChangeNotifierProvider(
    create: (_) => SettingsStore(null),
    child: Consumer<SettingsStore>(
      builder: (_, settings, child) => MaterialApp(
        themeMode: settings.themeMode,
        theme: AppTheme.build(AppColors.light, Brightness.light),
        darkTheme: AppTheme.build(AppColors.dark, Brightness.dark),
        home: const Scaffold(body: SettingsSheet()),
      ),
    ),
  );
}

Color _surfaceColor(WidgetTester tester) {
  final container = tester.widget<Container>(
    find
        .ancestor(
          of: find.text('Configurações'),
          matching: find.byType(Container),
        )
        .last,
  );
  return (container.decoration as BoxDecoration).color!;
}

void main() {
  testWidgets('a superfície do sheet acompanha a troca de tema', (tester) async {
    await tester.pumpWidget(_host());
    // Começa no tema do sistema (claro no teste).
    expect(_surfaceColor(tester), AppColors.light.bg);

    await tester.tap(find.text('Escuro'));
    await tester.pumpAndSettle();
    expect(_surfaceColor(tester), AppColors.dark.bg);

    await tester.tap(find.text('Claro'));
    await tester.pumpAndSettle();
    expect(_surfaceColor(tester), AppColors.light.bg);
  });
}
