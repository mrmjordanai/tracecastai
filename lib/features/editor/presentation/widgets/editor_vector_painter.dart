import 'package:flutter/material.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// CustomPainter for rendering vectors in the editor with selection and confidence highlighting
class EditorVectorPainter extends CustomPainter {
  final VectorizeResult result;
  final double displayScale;
  final Offset offset;
  final Set<String> selectedPathIds;
  final LayerVisibility layerVisibility;
  final bool showConfidenceHighlights;
  final double gridSpacingMm;

  EditorVectorPainter({
    required this.result,
    this.displayScale = 1.0,
    this.offset = Offset.zero,
    this.selectedPathIds = const {},
    this.layerVisibility = const LayerVisibility(),
    this.showConfidenceHighlights = true,
    this.gridSpacingMm = 10.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw grid if enabled
    if (layerVisibility.grid) {
      _drawGrid(canvas, size);
    }

    // Draw cutlines
    if (layerVisibility.cutline) {
      for (final path in result.layers.cutline) {
        _drawVectorPath(canvas, path, isCutline: true);
      }
    }

    // Draw markings
    if (layerVisibility.markings) {
      for (final path in result.layers.markings) {
        _drawVectorPath(canvas, path, isCutline: false);
      }
    }

    // Draw labels
    if (layerVisibility.labels) {
      for (final label in result.layers.labels) {
        _drawLabel(canvas, label);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    final gridSpacingPx = gridSpacingMm * displayScale;

    // Vertical lines
    for (double x = offset.dx % gridSpacingPx;
        x < size.width;
        x += gridSpacingPx) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    // Horizontal lines
    for (double y = offset.dy % gridSpacingPx;
        y < size.height;
        y += gridSpacingPx) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
  }

  void _drawVectorPath(Canvas canvas, VectorPath vectorPath,
      {required bool isCutline}) {
    if (vectorPath.points.isEmpty) return;

    final isSelected = selectedPathIds.contains(vectorPath.pathId);
    final isLowConfidence =
        showConfidenceHighlights && vectorPath.confidence < 0.5;

    // Determine path color
    Color pathColor;
    if (isSelected) {
      pathColor = BlueprintColors.primaryBackground; // Blue for selection
    } else if (isLowConfidence) {
      pathColor = BlueprintColors.accentAction; // Orange for low confidence
    } else {
      pathColor = Colors.white;
    }

    final paint = Paint()
      ..color = pathColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isSelected ? 3.0 : (isCutline ? 2.0 : 1.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw selection halo
    if (isSelected) {
      final haloPaint = Paint()
        ..color = BlueprintColors.primaryBackground.withValues(alpha: 0.3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      _drawPath(canvas, vectorPath, haloPaint);
    }

    // Draw the path
    _drawPath(canvas, vectorPath, paint);

    // Draw confidence indicator if low
    if (isLowConfidence && vectorPath.points.isNotEmpty) {
      final midIndex = vectorPath.points.length ~/ 2;
      final midPoint = _transformPoint(vectorPath.points[midIndex]);

      final warningPaint = Paint()
        ..color = BlueprintColors.accentAction
        ..style = PaintingStyle.fill;

      canvas.drawCircle(midPoint, 6, warningPaint);

      // Draw warning icon
      final iconPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;

      canvas.drawLine(
        midPoint + const Offset(0, -3),
        midPoint + const Offset(0, 0),
        iconPaint,
      );
      canvas.drawCircle(
          midPoint + const Offset(0, 2), 0.8, Paint()..color = Colors.white);
    }
  }

  void _drawPath(Canvas canvas, VectorPath vectorPath, Paint paint) {
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
    final isLowConfidence = showConfidenceHighlights && label.confidence < 0.5;

    // Draw background
    final bgColor = isLowConfidence
        ? BlueprintColors.accentAction.withValues(alpha: 0.2)
        : Colors.black.withValues(alpha: 0.5);

    final textPainter = TextPainter(
      text: TextSpan(
        text: label.text,
        style: TextStyle(
          color: isLowConfidence ? BlueprintColors.accentAction : Colors.white,
          fontSize: 12 * displayScale.clamp(0.5, 2.0),
          fontWeight: FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    final bgRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        position.dx - 4,
        position.dy - 4,
        textPainter.width + 8,
        textPainter.height + 8,
      ),
      const Radius.circular(4),
    );
    canvas.drawRRect(bgRect, Paint()..color = bgColor);

    textPainter.paint(canvas, position);
  }

  Offset _transformPoint(VectorPoint point) {
    return Offset(
      point.xMm * displayScale + offset.dx,
      point.yMm * displayScale + offset.dy,
    );
  }

  @override
  bool shouldRepaint(covariant EditorVectorPainter oldDelegate) {
    return result != oldDelegate.result ||
        displayScale != oldDelegate.displayScale ||
        offset != oldDelegate.offset ||
        selectedPathIds != oldDelegate.selectedPathIds ||
        layerVisibility != oldDelegate.layerVisibility ||
        showConfidenceHighlights != oldDelegate.showConfidenceHighlights;
  }

  /// Hit test for path selection
  /// Returns the path ID if a path is hit, null otherwise
  String? hitTestPath(Offset position, {double tolerance = 10.0}) {
    // Check cutlines
    if (layerVisibility.cutline) {
      for (final path in result.layers.cutline.reversed) {
        if (_isPointNearPath(position, path, tolerance)) {
          return path.pathId;
        }
      }
    }

    // Check markings
    if (layerVisibility.markings) {
      for (final path in result.layers.markings.reversed) {
        if (_isPointNearPath(position, path, tolerance)) {
          return path.pathId;
        }
      }
    }

    return null;
  }

  bool _isPointNearPath(Offset point, VectorPath vectorPath, double tolerance) {
    if (vectorPath.points.length < 2) return false;

    for (int i = 0; i < vectorPath.points.length - 1; i++) {
      final p1 = _transformPoint(vectorPath.points[i]);
      final p2 = _transformPoint(vectorPath.points[i + 1]);

      if (_distanceToLineSegment(point, p1, p2) <= tolerance) {
        return true;
      }
    }

    // Check closing segment for closed paths
    if (vectorPath.closed && vectorPath.points.length > 2) {
      final p1 = _transformPoint(vectorPath.points.last);
      final p2 = _transformPoint(vectorPath.points.first);
      if (_distanceToLineSegment(point, p1, p2) <= tolerance) {
        return true;
      }
    }

    return false;
  }

  double _distanceToLineSegment(
      Offset point, Offset lineStart, Offset lineEnd) {
    final line = lineEnd - lineStart;
    final lengthSquared = line.distanceSquared;

    if (lengthSquared == 0) {
      return (point - lineStart).distance;
    }

    var t =
        ((point - lineStart).dx * line.dx + (point - lineStart).dy * line.dy) /
            lengthSquared;
    t = t.clamp(0.0, 1.0);

    final projection = lineStart + line * t;
    return (point - projection).distance;
  }
}
