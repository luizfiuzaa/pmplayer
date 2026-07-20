import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Botão de favoritar: coração preenchido (terracota) quando favorita, ou
/// contornado (neutro) caso contrário. Porta o `<svg>` de coração do design.
class HeartButton extends StatelessWidget {
  const HeartButton({
    super.key,
    required this.isFavorite,
    required this.onPressed,
    this.size = 19,
  });

  final bool isFavorite;
  final VoidCallback onPressed;
  final double size;

  @override
  Widget build(BuildContext context) {
    return InkResponse(
      onTap: onPressed,
      radius: size,
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(
          isFavorite ? Icons.favorite : Icons.favorite_border,
          size: size,
          color: isFavorite ? AppColors.accent : AppColors.neutral500,
        ),
      ),
    );
  }
}
