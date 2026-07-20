import 'package:flutter/material.dart';

/// Elevação do design system — sombras suaves tingidas de tinta (#2E2B25),
/// afinadas para o fundo claro. Portadas de `--shadow-sm/md/lg`.
abstract final class AppShadows {
  static const Color _ink = Color(0xFF2E2B25);

  /// `--shadow-sm`: 0 1px 2px ink@14%.
  static List<BoxShadow> get sm => [
    BoxShadow(
      color: _ink.withValues(alpha: 0.14),
      offset: const Offset(0, 1),
      blurRadius: 2,
    ),
  ];

  /// `--shadow-md`: 0 3px 10px ink@16%.
  static List<BoxShadow> get md => [
    BoxShadow(
      color: _ink.withValues(alpha: 0.16),
      offset: const Offset(0, 3),
      blurRadius: 10,
    ),
  ];

  /// `--shadow-lg`: 0 12px 32px ink@22%.
  static List<BoxShadow> get lg => [
    BoxShadow(
      color: _ink.withValues(alpha: 0.22),
      offset: const Offset(0, 12),
      blurRadius: 32,
    ),
  ];
}
