import 'package:flutter/material.dart';

import '../../../../core/models/vectorize_result.dart';

/// CustomPainter that renders vector paths as white lines on black background
class VectorPainter extends CustomPainter {
  final VectorizeResult result;
  final double displayScale; // mm to screen pixels
  final Offset offset; // Pan offset

  VectorPainter({
    required this.result,
    this.displayScale = 1.0,
    this.offset = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Cutline paint - white, thicker stroke
    final cutlinePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Marking paint - white, thinner stroke
    final markingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Draw cutlines
    for (final path in result.layers.cutline) {
      _drawVectorPath(canvas, path, cutlinePaint);
    }

    // Draw markings
    for (final path in result.layers.markings) {
      _drawVectorPath(canvas, path, markingPaint);
    }

    // Draw labels (optional - could be text or just indicators)
    for (final label in result.layers.labels) {
      _drawLabel(canvas, label);
    }
  }

  void _drawVectorPath(Canvas canvas, VectorPath vectorPath, Paint paint) {
    if (vectorPath.points.isEmpty) return;

    final path = Path();
    final firstPoint = _transformPoint(vectorPath.points.first);
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < vectorPath.points.length; i++) {
      final point = _transformPoint(vectorPath.points[i]);
      path.lineTo(point.dx, point.dy);
    }

    if (vectorPath.closed && vectorPath.points.length > 2) {
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  void _drawLabel(Canvas canvas, TextBox label) {
    final position = _transformPoint(label.position);

    // Draw a small indicator dot for text labels
    final indicatorPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(position, 4.0, indicatorPaint);

    // Optionally draw text (simplified for projector mode)
    final textPainter = TextPainter(
      text: TextSpan(
        text: label.text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, position + const Offset(8, -5));
  }

  Offset _transformPoint(VectorPoint point) {
    // Convert mm to screen pixels and apply pan offset
    return Offset(
      point.xMm * displayScale + offset.dx,
      point.yMm * displayScale + offset.dy,
    );
  }

  @override
  bool shouldRepaint(covariant VectorPainter oldDelegate) {
    return result != oldDelegate.result ||
        displayScale != oldDelegate.displayScale ||
        offset != oldDelegate.offset;
  }
}
