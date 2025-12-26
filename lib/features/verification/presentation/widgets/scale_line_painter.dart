import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../app/theme/blueprint_colors.dart';

/// CustomPainter for drawing a scale reference line with endpoints
///
/// This painter draws:
/// - A dashed line between start and end points
/// - Circular handles at each endpoint (draggable)
/// - A pixel distance label at the midpoint
class ScaleLinePainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;
  final bool isDrawing;
  final double handleRadius;
  final bool showDistance;

  ScaleLinePainter({
    this.startPoint,
    this.endPoint,
    this.isDrawing = false,
    this.handleRadius = 16.0,
    this.showDistance = true,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || endPoint == null) return;

    final linePaint = Paint()
      ..color = BlueprintColors.accentAction
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final handleFillPaint = Paint()
      ..color = BlueprintColors.accentAction
      ..style = PaintingStyle.fill;

    final handleStrokePaint = Paint()
      ..color = BlueprintColors.primaryForeground
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw dashed line
    _drawDashedLine(canvas, startPoint!, endPoint!, linePaint);

    // Draw endpoint handles
    _drawHandle(canvas, startPoint!, handleFillPaint, handleStrokePaint);
    _drawHandle(canvas, endPoint!, handleFillPaint, handleStrokePaint);

    // Draw distance label
    if (showDistance) {
      _drawDistanceLabel(canvas, startPoint!, endPoint!);
    }
  }

  void _drawDashedLine(
      Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 8.0;
    const dashSpace = 4.0;

    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance == 0) return;

    final unitDx = dx / distance;
    final unitDy = dy / distance;

    var currentDistance = 0.0;
    var isDash = true;

    while (currentDistance < distance) {
      final segmentLength =
          isDash ? dashWidth : dashSpace;
      final endDistance = min(currentDistance + segmentLength, distance);

      if (isDash) {
        final segmentStart = Offset(
          start.dx + unitDx * currentDistance,
          start.dy + unitDy * currentDistance,
        );
        final segmentEnd = Offset(
          start.dx + unitDx * endDistance,
          start.dy + unitDy * endDistance,
        );
        canvas.drawLine(segmentStart, segmentEnd, paint);
      }

      currentDistance = endDistance;
      isDash = !isDash;
    }
  }

  void _drawHandle(
    Canvas canvas,
    Offset point,
    Paint fillPaint,
    Paint strokePaint,
  ) {
    // Outer circle (white stroke)
    canvas.drawCircle(point, handleRadius, strokePaint);

    // Inner circle (orange fill)
    canvas.drawCircle(point, handleRadius - 2, fillPaint);

    // Center dot
    final centerPaint = Paint()
      ..color = BlueprintColors.primaryForeground
      ..style = PaintingStyle.fill;
    canvas.drawCircle(point, 4, centerPaint);
  }

  void _drawDistanceLabel(Canvas canvas, Offset start, Offset end) {
    final dx = end.dx - start.dx;
    final dy = end.dy - start.dy;
    final distance = sqrt(dx * dx + dy * dy);
    final midpoint = Offset(
      (start.dx + end.dx) / 2,
      (start.dy + end.dy) / 2,
    );

    // Text setup
    final textSpan = TextSpan(
      text: '${distance.round()} px',
      style: const TextStyle(
        color: BlueprintColors.primaryForeground,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        backgroundColor: Color(0xCC4A90E2), // Semi-transparent Blueprint blue
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position label above the line
    final labelOffset = Offset(
      midpoint.dx - textPainter.width / 2,
      midpoint.dy - textPainter.height - 12,
    );

    // Background rect
    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        labelOffset.dx - 6,
        labelOffset.dy - 2,
        textPainter.width + 12,
        textPainter.height + 4,
      ),
      const Radius.circular(4),
    );

    final bgPaint = Paint()
      ..color = BlueprintColors.surfaceOverlay
      ..style = PaintingStyle.fill;

    canvas.drawRRect(bgRect, bgPaint);
    textPainter.paint(canvas, labelOffset);
  }

  @override
  bool shouldRepaint(covariant ScaleLinePainter oldDelegate) {
    return oldDelegate.startPoint != startPoint ||
        oldDelegate.endPoint != endPoint ||
        oldDelegate.isDrawing != isDrawing;
  }

  /// Check if a point is near the start handle
  bool isNearStartHandle(Offset point) {
    if (startPoint == null) return false;
    final dx = point.dx - startPoint!.dx;
    final dy = point.dy - startPoint!.dy;
    return sqrt(dx * dx + dy * dy) <= handleRadius * 1.5;
  }

  /// Check if a point is near the end handle
  bool isNearEndHandle(Offset point) {
    if (endPoint == null) return false;
    final dx = point.dx - endPoint!.dx;
    final dy = point.dy - endPoint!.dy;
    return sqrt(dx * dx + dy * dy) <= handleRadius * 1.5;
  }
}

/// Widget that provides gesture detection for the scale line painter
class ScaleLineDrawingArea extends StatefulWidget {
  final Offset? startPoint;
  final Offset? endPoint;
  final bool isDrawing;
  final ValueChanged<Offset> onDrawStart;
  final ValueChanged<Offset> onDrawUpdate;
  final VoidCallback onDrawEnd;
  final ValueChanged<Offset>? onStartPointMoved;
  final ValueChanged<Offset>? onEndPointMoved;
  final Widget child;

  const ScaleLineDrawingArea({
    super.key,
    this.startPoint,
    this.endPoint,
    this.isDrawing = false,
    required this.onDrawStart,
    required this.onDrawUpdate,
    required this.onDrawEnd,
    this.onStartPointMoved,
    this.onEndPointMoved,
    required this.child,
  });

  @override
  State<ScaleLineDrawingArea> createState() => _ScaleLineDrawingAreaState();
}

class _ScaleLineDrawingAreaState extends State<ScaleLineDrawingArea> {
  bool _isDraggingStart = false;
  bool _isDraggingEnd = false;
  static const double _handleRadius = 16.0;

  bool _isNearPoint(Offset point, Offset? target) {
    if (target == null) return false;
    final dx = point.dx - target.dx;
    final dy = point.dy - target.dy;
    return sqrt(dx * dx + dy * dy) <= _handleRadius * 1.5;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: (details) {
        final localPos = details.localPosition;

        // Check if dragging an existing handle
        if (widget.startPoint != null && widget.endPoint != null) {
          if (_isNearPoint(localPos, widget.startPoint)) {
            _isDraggingStart = true;
            return;
          }
          if (_isNearPoint(localPos, widget.endPoint)) {
            _isDraggingEnd = true;
            return;
          }
        }

        // Start new line
        widget.onDrawStart(localPos);
      },
      onPanUpdate: (details) {
        if (_isDraggingStart) {
          widget.onStartPointMoved?.call(details.delta);
        } else if (_isDraggingEnd) {
          widget.onEndPointMoved?.call(details.delta);
        } else {
          widget.onDrawUpdate(details.localPosition);
        }
      },
      onPanEnd: (details) {
        _isDraggingStart = false;
        _isDraggingEnd = false;
        widget.onDrawEnd();
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          widget.child,
          CustomPaint(
            painter: ScaleLinePainter(
              startPoint: widget.startPoint,
              endPoint: widget.endPoint,
              isDrawing: widget.isDrawing,
            ),
          ),
        ],
      ),
    );
  }
}
