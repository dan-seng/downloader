import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Animated 6-spoke reel / web-spool icon matching the SPIDEY faceplate.
class ReelSpinner extends StatefulWidget {
  final bool isSpinning;
  final Color reelColor;
  final Color spokeColor;
  final double size;

  const ReelSpinner({
    super.key,
    required this.isSpinning,
    this.reelColor = const Color(0xFF444444),
    this.spokeColor = const Color(0xFFCCCCCC),
    this.size = 30.0,
  });

  @override
  State<ReelSpinner> createState() => _ReelSpinnerState();
}

class _ReelSpinnerState extends State<ReelSpinner>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (widget.isSpinning) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant ReelSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpinning && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isSpinning && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return CustomPaint(
            painter: _ReelPainter(
              rotation: _controller.value * 2 * math.pi,
              reelColor: widget.reelColor,
              spokeColor: widget.spokeColor,
            ),
          );
        },
      ),
    );
  }
}

class _ReelPainter extends CustomPainter {
  final double rotation;
  final Color reelColor;
  final Color spokeColor;

  _ReelPainter({
    required this.rotation,
    required this.reelColor,
    required this.spokeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 2;

    // Outer dashed ring
    final outerPaint = Paint()
      ..color = reelColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw dashed circle
    const int dashCount = 12;
    final double dashAngle = (2 * math.pi) / dashCount;
    for (int i = 0; i < dashCount; i++) {
      if (i % 2 == 0) {
        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          i * dashAngle,
          dashAngle * 0.7,
          false,
          outerPaint,
        );
      }
    }

    // Inner rotating hub
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    final spokePaint = Paint()
      ..color = spokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3
      ..strokeCap = StrokeCap.round;

    // 6 spokes
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi) / 3;
      final x = math.cos(angle) * (radius - 1);
      final y = math.sin(angle) * (radius - 1);
      canvas.drawLine(Offset.zero, Offset(x, y), spokePaint);
    }

    // Center hub circle
    final hubFill = Paint()
      ..color = const Color(0xFF0A0A0A)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, 3.5, hubFill);
    canvas.drawCircle(Offset.zero, 3.5, spokePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ReelPainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.reelColor != reelColor ||
      oldDelegate.spokeColor != spokeColor;
}
