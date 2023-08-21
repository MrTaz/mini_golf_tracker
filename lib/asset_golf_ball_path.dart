import 'package:flutter/material.dart';

class GolfBallPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint();
    Path path = Path();

    // Path number 1

    paint.color = const Color(0xFFDDDBDB);
    path = Path();
    path.lineTo(size.width * 1.41, size.height * 0.91);
    path.cubicTo(size.width * 1.41, size.height * 1.19, size.width * 1.19, size.height * 1.41, size.width * 0.91,
        size.height * 1.41);
    path.cubicTo(size.width * 0.63, size.height * 1.41, size.width * 0.41, size.height * 1.19, size.width * 0.41,
        size.height * 0.91);
    path.cubicTo(size.width * 0.41, size.height * 0.63, size.width * 0.63, size.height * 0.41, size.width * 0.91,
        size.height * 0.41);
    path.cubicTo(size.width * 1.19, size.height * 0.41, size.width * 1.41, size.height * 0.63, size.width * 1.41,
        size.height * 0.91);
    canvas.drawPath(path, paint);

    // Path number 2

    paint.color = const Color(0xFF000000).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.09, size.height * 1.29);
    path.cubicTo(size.width * 1.09, size.height * 1.32, size.width * 1.07, size.height * 1.33, size.width * 1.05,
        size.height * 1.33);
    path.cubicTo(size.width * 1.03, size.height * 1.33, size.width, size.height * 1.32, size.width, size.height * 1.29);
    path.cubicTo(
        size.width, size.height * 1.27, size.width * 1.03, size.height * 1.26, size.width * 1.05, size.height * 1.26);
    path.cubicTo(size.width * 1.07, size.height * 1.26, size.width * 1.09, size.height * 1.27, size.width * 1.09,
        size.height * 1.29);
    canvas.drawPath(path, paint);

    // Path number 3

    paint.color = const Color(0xFF000000).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.22, size.height * 1.22);
    path.cubicTo(size.width * 1.22, size.height * 1.24, size.width * 1.2, size.height * 1.26, size.width * 1.18,
        size.height * 1.26);
    path.cubicTo(size.width * 1.16, size.height * 1.26, size.width * 1.14, size.height * 1.24, size.width * 1.14,
        size.height * 1.22);
    path.cubicTo(size.width * 1.14, size.height * 1.2, size.width * 1.16, size.height * 1.18, size.width * 1.18,
        size.height * 1.18);
    path.cubicTo(size.width * 1.2, size.height * 1.18, size.width * 1.22, size.height * 1.2, size.width * 1.22,
        size.height * 1.22);
    canvas.drawPath(path, paint);

    // Path number 4

    paint.color = const Color(0xFF000000).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.31, size.height * 1.11);
    path.cubicTo(size.width * 1.31, size.height * 1.13, size.width * 1.3, size.height * 1.15, size.width * 1.27,
        size.height * 1.15);
    path.cubicTo(size.width * 1.25, size.height * 1.15, size.width * 1.24, size.height * 1.13, size.width * 1.24,
        size.height * 1.11);
    path.cubicTo(size.width * 1.24, size.height * 1.09, size.width * 1.25, size.height * 1.07, size.width * 1.27,
        size.height * 1.07);
    path.cubicTo(size.width * 1.3, size.height * 1.07, size.width * 1.31, size.height * 1.09, size.width * 1.31,
        size.height * 1.11);
    canvas.drawPath(path, paint);

    // Path number 5

    paint.color = const Color(0xFF000000).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.36, size.height);
    path.cubicTo(
        size.width * 1.36, size.height, size.width * 1.35, size.height * 1.03, size.width * 1.33, size.height * 1.03);
    path.cubicTo(size.width * 1.3, size.height * 1.03, size.width * 1.29, size.height, size.width * 1.29, size.height);
    path.cubicTo(size.width * 1.29, size.height * 0.97, size.width * 1.3, size.height * 0.95, size.width * 1.33,
        size.height * 0.95);
    path.cubicTo(
        size.width * 1.35, size.height * 0.95, size.width * 1.36, size.height * 0.97, size.width * 1.36, size.height);
    canvas.drawPath(path, paint);

    // Path number 6

    paint.color = const Color(0xFF000000).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.11, size.height * 1.18);
    path.cubicTo(size.width * 1.11, size.height * 1.2, size.width * 1.09, size.height * 1.22, size.width * 1.07,
        size.height * 1.22);
    path.cubicTo(size.width * 1.05, size.height * 1.22, size.width * 1.03, size.height * 1.2, size.width * 1.03,
        size.height * 1.18);
    path.cubicTo(size.width * 1.03, size.height * 1.16, size.width * 1.05, size.height * 1.14, size.width * 1.07,
        size.height * 1.14);
    path.cubicTo(size.width * 1.09, size.height * 1.14, size.width * 1.11, size.height * 1.16, size.width * 1.11,
        size.height * 1.18);
    canvas.drawPath(path, paint);

    // Path number 7

    paint.color = const Color(0xFF000000).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.19, size.height * 1.1);
    path.cubicTo(size.width * 1.19, size.height * 1.12, size.width * 1.17, size.height * 1.13, size.width * 1.15,
        size.height * 1.13);
    path.cubicTo(size.width * 1.13, size.height * 1.13, size.width * 1.11, size.height * 1.12, size.width * 1.11,
        size.height * 1.1);
    path.cubicTo(size.width * 1.11, size.height * 1.07, size.width * 1.13, size.height * 1.06, size.width * 1.15,
        size.height * 1.06);
    path.cubicTo(size.width * 1.17, size.height * 1.06, size.width * 1.19, size.height * 1.07, size.width * 1.19,
        size.height * 1.1);
    canvas.drawPath(path, paint);

    // Path number 8

    paint.color = const Color(0xFF000000).withOpacity(1);
    path = Path();
    path.lineTo(size.width * 1.26, size.height);
    path.cubicTo(size.width * 1.26, size.height * 1.03, size.width * 1.24, size.height * 1.04, size.width * 1.22,
        size.height * 1.04);
    path.cubicTo(
        size.width * 1.2, size.height * 1.04, size.width * 1.18, size.height * 1.03, size.width * 1.18, size.height);
    path.cubicTo(size.width * 1.18, size.height * 0.98, size.width * 1.2, size.height * 0.97, size.width * 1.22,
        size.height * 0.97);
    path.cubicTo(
        size.width * 1.24, size.height * 0.97, size.width * 1.26, size.height * 0.98, size.width * 1.26, size.height);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
