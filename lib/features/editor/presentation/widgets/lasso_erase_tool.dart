import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// Lasso erase tool for selecting and deleting paths by drawing a lasso
class LassoEraseTool extends ConsumerStatefulWidget {
  /// The vectorization result
  final VectorizeResult result;

  /// Display scale (mm to pixels)
  final double displayScale;

  /// Pan offset
  final Offset offset;

  /// Callback when paths are erased
  final ValueChanged<List<String>>? onPathsErased;

  const LassoEraseTool({
    super.key,
    required this.result,
    required this.displayScale,
    required this.offset,
    this.onPathsErased,
  });

  @override
  ConsumerState<LassoEraseTool> createState() => _LassoEraseToolState();
}

class _LassoEraseToolState extends ConsumerState<LassoEraseTool> {
  final List<Offset> _lassoPoints = [];
  bool _isDrawing = false;
  Set<String> _highlightedPaths = {};

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _LassoPainter(
          lassoPoints: _lassoPoints,
          highlightedPathIds: _highlightedPaths,
          result: widget.result,
          displayScale: widget.displayScale,
          offset: widget.offset,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _lassoPoints.clear();
      _lassoPoints.add(details.localPosition);
      _highlightedPaths = {};
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _lassoPoints.add(details.localPosition);
      _highlightedPaths = _findPathsInLasso();
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing) return;

    _isDrawing = false;

    // Close the lasso
    if (_lassoPoints.length > 2) {
      _lassoPoints.add(_lassoPoints.first);
    }

    // Find and delete paths
    final pathsToDelete = _findPathsInLasso().toList();

    if (pathsToDelete.isNotEmpty) {
      HapticFeedback.mediumImpact();

      // Collect paths for undo
      final cutlines = widget.result.layers.cutline
          .where((p) => pathsToDelete.contains(p.pathId))
          .toList();
      final markings = widget.result.layers.markings
          .where((p) => pathsToDelete.contains(p.pathId))
          .toList();

      // Create and execute command
      final command = DeletePathsCommand(
        pathIds: pathsToDelete,
        deletedCutlines: cutlines,
        deletedMarkings: markings,
      );

      ref.read(editorStateProvider.notifier).executeCommand(command);
      widget.onPathsErased?.call(pathsToDelete);
    }

    setState(() {
      _lassoPoints.clear();
      _highlightedPaths = {};
    });
  }

  Set<String> _findPathsInLasso() {
    if (_lassoPoints.length < 3) return {};

    final lassoPath = Path();
    lassoPath.moveTo(_lassoPoints.first.dx, _lassoPoints.first.dy);
    for (int i = 1; i < _lassoPoints.length; i++) {
      lassoPath.lineTo(_lassoPoints[i].dx, _lassoPoints[i].dy);
    }
    lassoPath.close();

    final pathIds = <String>{};

    // Check cutlines
    for (final vectorPath in widget.result.layers.cutline) {
      if (_isPathInLasso(vectorPath, lassoPath)) {
        pathIds.add(vectorPath.pathId);
      }
    }

    // Check markings
    for (final vectorPath in widget.result.layers.markings) {
      if (_isPathInLasso(vectorPath, lassoPath)) {
        pathIds.add(vectorPath.pathId);
      }
    }

    return pathIds;
  }

  bool _isPathInLasso(VectorPath vectorPath, Path lassoPath) {
    // Check if any point of the path is inside the lasso
    for (final point in vectorPath.points) {
      final screenPoint = Offset(
        point.xMm * widget.displayScale + widget.offset.dx,
        point.yMm * widget.displayScale + widget.offset.dy,
      );

      if (lassoPath.contains(screenPoint)) {
        return true;
      }
    }

    return false;
  }
}

class _LassoPainter extends CustomPainter {
  final List<Offset> lassoPoints;
  final Set<String> highlightedPathIds;
  final VectorizeResult result;
  final double displayScale;
  final Offset offset;

  _LassoPainter({
    required this.lassoPoints,
    required this.highlightedPathIds,
    required this.result,
    required this.displayScale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Draw highlighted paths (paths that will be deleted)
    if (highlightedPathIds.isNotEmpty) {
      final highlightPaint = Paint()
        ..color = BlueprintColors.errorState.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4.0;

      for (final path in result.layers.cutline) {
        if (highlightedPathIds.contains(path.pathId)) {
          _drawPath(canvas, path, highlightPaint);
        }
      }

      for (final path in result.layers.markings) {
        if (highlightedPathIds.contains(path.pathId)) {
          _drawPath(canvas, path, highlightPaint);
        }
      }
    }

    // Draw lasso
    if (lassoPoints.length > 1) {
      final lassoPaint = Paint()
        ..color = BlueprintColors.errorState
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round;

      final lassoPath = Path();
      lassoPath.moveTo(lassoPoints.first.dx, lassoPoints.first.dy);
      for (int i = 1; i < lassoPoints.length; i++) {
        lassoPath.lineTo(lassoPoints[i].dx, lassoPoints[i].dy);
      }

      // Draw dashed line
      canvas.drawPath(
        _createDashedPath(lassoPath, 8, 4),
        lassoPaint,
      );

      // Draw fill
      final lassoFillPaint = Paint()
        ..color = BlueprintColors.errorState.withValues(alpha: 0.1)
        ..style = PaintingStyle.fill;

      final closedPath = Path.from(lassoPath)..close();
      canvas.drawPath(closedPath, lassoFillPaint);
    }
  }

  void _drawPath(Canvas canvas, VectorPath vectorPath, Paint paint) {
    if (vectorPath.points.isEmpty) return;

    final path = Path();
    final firstPoint = Offset(
      vectorPath.points.first.xMm * displayScale + offset.dx,
      vectorPath.points.first.yMm * displayScale + offset.dy,
    );
    path.moveTo(firstPoint.dx, firstPoint.dy);

    for (int i = 1; i < vectorPath.points.length; i++) {
      final point = Offset(
        vectorPath.points[i].xMm * displayScale + offset.dx,
        vectorPath.points[i].yMm * displayScale + offset.dy,
      );
      path.lineTo(point.dx, point.dy);
    }

    if (vectorPath.closed) path.close();
    canvas.drawPath(path, paint);
  }

  Path _createDashedPath(Path source, double dashLength, double gapLength) {
    final result = Path();
    for (final metric in source.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        final len = math.min(dashLength, metric.length - distance);
        result.addPath(
          metric.extractPath(distance, distance + len),
          Offset.zero,
        );
        distance += dashLength + gapLength;
      }
    }
    return result;
  }

  @override
  bool shouldRepaint(covariant _LassoPainter oldDelegate) {
    return lassoPoints != oldDelegate.lassoPoints ||
        highlightedPathIds != oldDelegate.highlightedPathIds;
  }
}
