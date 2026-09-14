import 'dart:math' as math;

import 'package:flutter/material.dart';

class ReactNativeIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? centerColor;

  const ReactNativeIcon({
    super.key,
    this.size = 24,
    this.color,
    this.centerColor,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).colorScheme.primary;
    return CustomPaint(
      size: Size.square(size),
      painter: _ReactNativeIconPainter(
        color: resolvedColor,
        centerColor: centerColor ?? resolvedColor,
      ),
    );
  }
}

class _ReactNativeIconPainter extends CustomPainter {
  final Color color;
  final Color centerColor;

  const _ReactNativeIconPainter({
    required this.color,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide * 0.29;
    final strokeWidth = size.shortestSide * 0.095;
    final orbitPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    for (final rotation in <double>[0, math.pi / 3, -math.pi / 3]) {
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(rotation);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset.zero,
          width: size.shortestSide * 0.82,
          height: size.shortestSide * 0.38,
        ),
        orbitPaint,
      );
      canvas.restore();
    }

    canvas.drawCircle(center, radius, Paint()..color = centerColor);
  }

  @override
  bool shouldRepaint(covariant _ReactNativeIconPainter oldDelegate) {
    return color != oldDelegate.color || centerColor != oldDelegate.centerColor;
  }
}
