import 'package:flutter/material.dart';

class GolfBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // 1. Draw ball background with a subtle radial gradient to look 3D spherical
    final ballPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          Colors.grey.shade200,
          Colors.grey.shade400,
        ],
        stops: const [0.0, 0.75, 1.0],
        center: const Alignment(-0.25, -0.25),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, ballPaint);

    // 2. Draw subtle border/shadow to give depth
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawCircle(center, radius, borderPaint);

    // 3. Draw clean, beautiful dimples (small circles) distributed on the ball
    final dimplePaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.black.withValues(alpha: 0.08),
          Colors.white.withValues(alpha: 0.15),
        ],
        center: const Alignment(-0.2, -0.2),
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    final dimpleBorderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    // A list of relative offsets from the center for the dimples (within the ball circle)
    final List<Offset> dimpleOffsets = [
      const Offset(-0.45, -0.45),
      const Offset(0.0, -0.6),
      const Offset(0.45, -0.45),
      const Offset(-0.6, 0.0),
      const Offset(-0.15, -0.15),
      const Offset(0.35, -0.1),
      const Offset(-0.35, 0.35),
      const Offset(0.1, 0.55),
      const Offset(0.55, 0.3),
      const Offset(-0.25, -0.4),
      const Offset(0.2, -0.35),
      const Offset(-0.4, 0.1),
      const Offset(0.0, 0.2),
      const Offset(0.35, 0.35),
      const Offset(-0.1, 0.6),
      const Offset(-0.55, -0.2),
      const Offset(0.6, -0.1),
    ];

    final dimpleRadius = radius * 0.11;

    for (var offset in dimpleOffsets) {
      final dimpleCenter =
          center + Offset(offset.dx * radius * 0.85, offset.dy * radius * 0.85);
      canvas.drawCircle(dimpleCenter, dimpleRadius, dimplePaint);
      canvas.drawCircle(dimpleCenter, dimpleRadius, dimpleBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
