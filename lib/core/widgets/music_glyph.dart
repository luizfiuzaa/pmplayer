import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Glifo "música" do Lucide (nota com duas cabeças), traço 2.75 — a marca
/// visual das capas genéricas do design.
class MusicGlyph extends StatelessWidget {
  const MusicGlyph({
    super.key,
    required this.size,
    this.color = AppColors.accent2_700,
    this.strokeWidth = 2.75,
  });

  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _MusicGlyphPainter(color, strokeWidth)),
    );
  }
}

class _MusicGlyphPainter extends CustomPainter {
  _MusicGlyphPainter(this.color, this.strokeWidth);

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 24.0;
    canvas.scale(scale);

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Hastes: M9 18 V5 l12-2 v13  →  (9,18)-(9,5)-(21,3)-(21,16)
    final stems = Path()
      ..moveTo(9, 18)
      ..lineTo(9, 5)
      ..lineTo(21, 3)
      ..lineTo(21, 16);
    canvas.drawPath(stems, paint);

    // Cabeças da nota.
    canvas.drawCircle(const Offset(6, 18), 3, paint);
    canvas.drawCircle(const Offset(18, 16), 3, paint);
  }

  @override
  bool shouldRepaint(_MusicGlyphPainter old) =>
      old.color != color || old.strokeWidth != strokeWidth;
}
