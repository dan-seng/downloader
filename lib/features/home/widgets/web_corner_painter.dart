import 'package:flutter/material.dart';

/// Custom painter rendering the subtle spiderweb corner motif from the SPIDEY spec.
class WebCornerPainter extends CustomPainter {
  final Color strokeColor;

  const WebCornerPainter({required this.strokeColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    // Radials originating from top-left (0, 0)
    canvas.drawLine(Offset.zero, Offset(size.width, size.height * 0.53), paint);
    canvas.drawLine(Offset.zero, Offset(size.width * 0.73, size.height), paint);
    canvas.drawLine(Offset.zero, Offset(size.width * 0.40, size.height), paint);
    canvas.drawLine(Offset.zero, Offset(size.width, size.height * 0.13), paint);
    canvas.drawLine(Offset.zero, Offset(size.width * 0.13, size.height), paint);

    // Curved spiral arcs connecting radials
    final arc1 = Path()
      ..moveTo(6, 0)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.07, size.width * 0.23, size.height * 0.23)
      ..quadraticBezierTo(size.width * 0.2, size.height * 0.39, 6, size.height * 0.44);
    canvas.drawPath(arc1, paint);

    final arc2 = Path()
      ..moveTo(14, 0)
      ..quadraticBezierTo(size.width * 0.37, size.height * 0.13, size.width * 0.44, size.height * 0.45)
      ..quadraticBezierTo(size.width * 0.4, size.height * 0.73, 14, size.height * 0.88);
    canvas.drawPath(arc2, paint);

    final arc3 = Path()
      ..moveTo(24, 0)
      ..quadraticBezierTo(size.width * 0.60, size.height * 0.23, size.width * 0.67, size.height * 0.68)
      ..quadraticBezierTo(size.width * 0.6, size.height * 0.93, 24, size.height);
    canvas.drawPath(arc3, paint);
  }

  @override
  bool shouldRepaint(covariant WebCornerPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor;
}
