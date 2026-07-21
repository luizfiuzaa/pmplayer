import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/state/settings_store.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

class SettingsSheet extends StatelessWidget {
  const SettingsSheet({super.key});

  static Future<void> show(BuildContext context) {
    // Fundo transparente no modal; a superfície é pintada no build (via
    // `context.colors`) para acompanhar a troca de tema feita dentro do sheet.
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SettingsSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsStore>();
    final mode = settings.themeMode;

    return Container(
      decoration: BoxDecoration(
        color: context.colors.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48,
              height: 4,
              decoration: BoxDecoration(
                color: context.colors.neutral300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Configurações',
            style: AppTypography.headingStyle(
              size: 24,
              color: context.colors.text,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Aparência',
            style: AppTypography.bodyStyle(
              size: 16,
              weight: FontWeight.w600,
              color: context.colors.neutral600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _ThemeOption(
                label: 'Claro',
                icon: Icons.light_mode_outlined,
                isSelected: mode == ThemeMode.light,
                onTap: () => settings.setThemeMode(ThemeMode.light),
              ),
              const SizedBox(width: 12),
              _ThemeOption(
                label: 'Escuro',
                icon: Icons.dark_mode_outlined,
                isSelected: mode == ThemeMode.dark,
                onTap: () => settings.setThemeMode(ThemeMode.dark),
              ),
              const SizedBox(width: 12),
              _ThemeOption(
                label: 'Sistema',
                icon: Icons.brightness_auto,
                isSelected: mode == ThemeMode.system,
                onTap: () => settings.setThemeMode(ThemeMode.system),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final fg = isSelected ? colors.bg : colors.text;
    final bg = isSelected ? colors.text : colors.surface;
    final border = isSelected ? Colors.transparent : colors.neutral300;

    return Expanded(
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: border),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Icon(icon, color: fg),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: AppTypography.bodyStyle(
                    size: 14,
                    weight: FontWeight.w500,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
