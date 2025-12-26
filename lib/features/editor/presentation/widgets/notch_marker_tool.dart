import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// Tool for adding V-shaped notch markers to paths
class NotchMarkerTool extends ConsumerStatefulWidget {
  /// The vectorization result
  final VectorizeResult result;

  /// Display scale (mm to pixels)
  final double displayScale;

  /// Pan offset
  final Offset offset;

  /// Notch size in mm
  final double notchSizeMm;

  /// Callback when a notch is added
  final ValueChanged<VectorPath>? onNotchAdded;

  const NotchMarkerTool({
    super.key,
    required this.result,
    required this.displayScale,
    required this.offset,
    this.notchSizeMm = 6.0,
    this.onNotchAdded,
  });

  @override
  ConsumerState<NotchMarkerTool> createState() => _NotchMarkerToolState();
}

class _NotchMarkerToolState extends ConsumerState<NotchMarkerTool> {
  _NotchPreview? _preview;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      child: CustomPaint(
        painter: _NotchPreviewPainter(
          preview: _preview,
          displayScale: widget.displayScale,
          offset: widget.offset,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onTapDown(TapDownDetails details) {
    // Find nearest point on any path
    final nearestPoint = _findNearestPathPoint(details.localPosition);
    if (nearestPoint != null) {
      setState(() {
        _preview = nearestPoint;
      });
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (_preview != null) {
      _addNotch(_preview!);
    }
    setState(() {
      _preview = null;
    });
  }

  _NotchPreview? _findNearestPathPoint(Offset screenPos) {
    const tolerance = 30.0; // Pixel tolerance for finding path
    _NotchPreview? nearest;
    double minDist = double.infinity;

    // Check cutlines
    for (final path in widget.result.layers.cutline) {
      final result = _findPointOnPath(path, screenPos, tolerance);
      if (result != null && result.distance < minDist) {
        minDist = result.distance;
        nearest = result;
      }
    }

    return nearest;
  }

  _NotchPreview? _findPointOnPath(
      VectorPath path, Offset screenPos, double tolerance) {
    if (path.points.length < 2) return null;

    for (int i = 0; i < path.points.length - 1; i++) {
      final p1 = path.points[i];
      final p2 = path.points[i + 1];

      final p1Screen = Offset(
        p1.xMm * widget.displayScale + widget.offset.dx,
        p1.yMm * widget.displayScale + widget.offset.dy,
      );
      final p2Screen = Offset(
        p2.xMm * widget.displayScale + widget.offset.dx,
        p2.yMm * widget.displayScale + widget.offset.dy,
      );

      final closest = _closestPointOnSegment(screenPos, p1Screen, p2Screen);
      final dist = (screenPos - closest).distance;

      if (dist <= tolerance) {
        // Calculate position in mm
        final t = _parameterOnSegment(closest, p1Screen, p2Screen);
        final pointMm = VectorPoint(
          xMm: p1.xMm + (p2.xMm - p1.xMm) * t,
          yMm: p1.yMm + (p2.yMm - p1.yMm) * t,
        );

        // Calculate normal direction
        final dx = p2.xMm - p1.xMm;
        final dy = p2.yMm - p1.yMm;
        final normalAngle = math.atan2(-dx, dy);

        return _NotchPreview(
          pathId: path.pathId,
          point: pointMm,
          angle: normalAngle,
          distance: dist,
        );
      }
    }

    return null;
  }

  Offset _closestPointOnSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final lengthSquared = ab.distanceSquared;
    if (lengthSquared == 0) return a;

    var t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / lengthSquared;
    t = t.clamp(0.0, 1.0);

    return a + ab * t;
  }

  double _parameterOnSegment(Offset p, Offset a, Offset b) {
    final ab = b - a;
    final ap = p - a;
    final lengthSquared = ab.distanceSquared;
    if (lengthSquared == 0) return 0;
    return (ap.dx * ab.dx + ap.dy * ab.dy) / lengthSquared;
  }

  void _addNotch(_NotchPreview preview) {
    HapticFeedback.mediumImpact();

    final halfSize = widget.notchSizeMm / 2;
    final depth = widget.notchSizeMm * 0.6;

    // Calculate notch points
    final dx = math.cos(preview.angle);
    final dy = math.sin(preview.angle);
    final perpDx = -dy;
    final perpDy = dx;

    final point1 = VectorPoint(
      xMm: preview.point.xMm + perpDx * halfSize,
      yMm: preview.point.yMm + perpDy * halfSize,
    );
    final point2 = VectorPoint(
      xMm: preview.point.xMm + dx * depth,
      yMm: preview.point.yMm + dy * depth,
    );
    final point3 = VectorPoint(
      xMm: preview.point.xMm - perpDx * halfSize,
      yMm: preview.point.yMm - perpDy * halfSize,
    );

    final notchPath = VectorPath(
      pathId: const Uuid().v4(),
      pathType: 'notch',
      closed: false,
      points: [point1, point2, point3],
      strokeHintMm: 0.5,
      confidence: 1.0,
    );

    final command = AddPathCommand(
      path: notchPath,
      isCutline: false, // Notches go in markings
    );

    ref.read(editorStateProvider.notifier).executeCommand(command);
    widget.onNotchAdded?.call(notchPath);
  }
}

class _NotchPreview {
  final String pathId;
  final VectorPoint point;
  final double angle;
  final double distance;

  _NotchPreview({
    required this.pathId,
    required this.point,
    required this.angle,
    required this.distance,
  });
}

class _NotchPreviewPainter extends CustomPainter {
  final _NotchPreview? preview;
  final double displayScale;
  final Offset offset;

  _NotchPreviewPainter({
    this.preview,
    required this.displayScale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (preview == null) return;

    final center = Offset(
      preview!.point.xMm * displayScale + offset.dx,
      preview!.point.yMm * displayScale + offset.dy,
    );

    // Draw preview notch
    const notchSize = 12.0;
    const depth = notchSize * 0.6;

    final dx = math.cos(preview!.angle);
    final dy = math.sin(preview!.angle);
    final perpDx = -dy;
    final perpDy = dx;

    final point1 =
        center + Offset(perpDx * notchSize / 2, perpDy * notchSize / 2);
    final point2 = center + Offset(dx * depth, dy * depth);
    final point3 =
        center - Offset(perpDx * notchSize / 2, perpDy * notchSize / 2);

    final path = Path()
      ..moveTo(point1.dx, point1.dy)
      ..lineTo(point2.dx, point2.dy)
      ..lineTo(point3.dx, point3.dy);

    final paint = Paint()
      ..color = BlueprintColors.accentAction
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, paint);

    // Draw center dot
    canvas.drawCircle(
      center,
      4,
      Paint()..color = BlueprintColors.accentAction,
    );
  }

  @override
  bool shouldRepaint(covariant _NotchPreviewPainter oldDelegate) {
    return preview != oldDelegate.preview;
  }
}
