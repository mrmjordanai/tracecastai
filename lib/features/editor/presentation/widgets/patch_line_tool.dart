import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// Patch line tool for connecting two endpoints with auto-snap
class PatchLineTool extends ConsumerStatefulWidget {
  /// The vectorization result
  final VectorizeResult result;

  /// Display scale (mm to pixels)
  final double displayScale;

  /// Pan offset
  final Offset offset;

  /// Snap radius in mm
  final double snapRadiusMm;

  /// Callback when a new path is created
  final ValueChanged<VectorPath>? onPathCreated;

  const PatchLineTool({
    super.key,
    required this.result,
    required this.displayScale,
    required this.offset,
    this.snapRadiusMm = 5.0,
    this.onPathCreated,
  });

  @override
  ConsumerState<PatchLineTool> createState() => _PatchLineToolState();
}

class _PatchLineToolState extends ConsumerState<PatchLineTool> {
  _Endpoint? _startEndpoint;
  _Endpoint? _hoveredEndpoint;
  Offset? _currentPosition;
  List<_Endpoint> _endpoints = [];

  @override
  void initState() {
    super.initState();
    _findEndpoints();
  }

  @override
  void didUpdateWidget(covariant PatchLineTool oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.result != oldWidget.result) {
      _findEndpoints();
    }
  }

  void _findEndpoints() {
    _endpoints = [];

    // Find endpoints from cutlines
    for (final path in widget.result.layers.cutline) {
      if (path.points.isEmpty) continue;

      if (!path.closed) {
        // Open paths have two endpoints
        _endpoints.add(_Endpoint(
          pathId: path.pathId,
          point: path.points.first,
          isStart: true,
        ));
        _endpoints.add(_Endpoint(
          pathId: path.pathId,
          point: path.points.last,
          isStart: false,
        ));
      }
    }

    // Find endpoints from markings
    for (final path in widget.result.layers.markings) {
      if (path.points.isEmpty) continue;

      if (!path.closed) {
        _endpoints.add(_Endpoint(
          pathId: path.pathId,
          point: path.points.first,
          isStart: true,
        ));
        _endpoints.add(_Endpoint(
          pathId: path.pathId,
          point: path.points.last,
          isStart: false,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _PatchLinePainter(
          endpoints: _endpoints,
          startEndpoint: _startEndpoint,
          hoveredEndpoint: _hoveredEndpoint,
          currentPosition: _currentPosition,
          displayScale: widget.displayScale,
          offset: widget.offset,
          snapRadiusMm: widget.snapRadiusMm,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    final localPos = details.localPosition;
    final nearestEndpoint = _findNearestEndpoint(localPos);

    if (nearestEndpoint != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _startEndpoint = nearestEndpoint;
        _currentPosition = localPos;
      });
    }
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_startEndpoint == null) return;

    final localPos = details.localPosition;
    final nearestEndpoint = _findNearestEndpoint(localPos);

    setState(() {
      _currentPosition = localPos;
      _hoveredEndpoint = nearestEndpoint;

      // Haptic feedback when snapping
      if (_hoveredEndpoint != null && _hoveredEndpoint != _startEndpoint) {
        // Only trigger haptic once when entering snap range
        // (This could be improved with a flag to prevent repeated triggers)
      }
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (_startEndpoint == null) return;

    if (_hoveredEndpoint != null &&
        _hoveredEndpoint!.pathId != _startEndpoint!.pathId) {
      // Create new path connecting the two endpoints
      _createPatchPath(_startEndpoint!, _hoveredEndpoint!);
    }

    setState(() {
      _startEndpoint = null;
      _hoveredEndpoint = null;
      _currentPosition = null;
    });
  }

  _Endpoint? _findNearestEndpoint(Offset screenPos) {
    final snapRadiusPx = widget.snapRadiusMm * widget.displayScale;
    _Endpoint? nearest;
    double minDist = double.infinity;

    for (final endpoint in _endpoints) {
      final endpointScreen = Offset(
        endpoint.point.xMm * widget.displayScale + widget.offset.dx,
        endpoint.point.yMm * widget.displayScale + widget.offset.dy,
      );

      final dist = (screenPos - endpointScreen).distance;
      if (dist < snapRadiusPx && dist < minDist) {
        minDist = dist;
        nearest = endpoint;
      }
    }

    return nearest;
  }

  void _createPatchPath(_Endpoint start, _Endpoint end) {
    HapticFeedback.mediumImpact();

    final newPath = VectorPath(
      pathId: const Uuid().v4(),
      pathType: 'patch',
      closed: false,
      points: [start.point, end.point],
      strokeHintMm: 0.5,
      confidence: 1.0, // User-created, so 100% confidence
    );

    final command = AddPathCommand(
      path: newPath,
      isCutline: false, // Patches go in markings layer
    );

    ref.read(editorStateProvider.notifier).executeCommand(command);
    widget.onPathCreated?.call(newPath);
  }
}

class _Endpoint {
  final String pathId;
  final VectorPoint point;
  final bool isStart;

  _Endpoint({
    required this.pathId,
    required this.point,
    required this.isStart,
  });
}

class _PatchLinePainter extends CustomPainter {
  final List<_Endpoint> endpoints;
  final _Endpoint? startEndpoint;
  final _Endpoint? hoveredEndpoint;
  final Offset? currentPosition;
  final double displayScale;
  final Offset offset;
  final double snapRadiusMm;

  _PatchLinePainter({
    required this.endpoints,
    this.startEndpoint,
    this.hoveredEndpoint,
    this.currentPosition,
    required this.displayScale,
    required this.offset,
    required this.snapRadiusMm,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final snapRadiusPx = snapRadiusMm * displayScale;

    // Draw endpoint indicators
    for (final endpoint in endpoints) {
      final pos = Offset(
        endpoint.point.xMm * displayScale + offset.dx,
        endpoint.point.yMm * displayScale + offset.dy,
      );

      final isActive = endpoint == startEndpoint || endpoint == hoveredEndpoint;

      // Draw snap zone
      final zonePaint = Paint()
        ..color = (isActive
                ? BlueprintColors.accentAction
                : BlueprintColors.primaryBackground)
            .withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, snapRadiusPx, zonePaint);

      // Draw endpoint dot
      final dotPaint = Paint()
        ..color = isActive
            ? BlueprintColors.accentAction
            : BlueprintColors.primaryBackground
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pos, isActive ? 8 : 5, dotPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(pos, isActive ? 8 : 5, borderPaint);
    }

    // Draw connection line
    if (startEndpoint != null && currentPosition != null) {
      final startPos = Offset(
        startEndpoint!.point.xMm * displayScale + offset.dx,
        startEndpoint!.point.yMm * displayScale + offset.dy,
      );

      Offset endPos = currentPosition!;

      // Snap to hovered endpoint
      if (hoveredEndpoint != null) {
        endPos = Offset(
          hoveredEndpoint!.point.xMm * displayScale + offset.dx,
          hoveredEndpoint!.point.yMm * displayScale + offset.dy,
        );
      }

      final linePaint = Paint()
        ..color = hoveredEndpoint != null
            ? BlueprintColors.successState
            : BlueprintColors.accentAction
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startPos, endPos, linePaint);

      // Draw endpoints of the line
      canvas.drawCircle(startPos, 6, linePaint..style = PaintingStyle.fill);
      canvas.drawCircle(endPos, 6, linePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _PatchLinePainter oldDelegate) {
    return startEndpoint != oldDelegate.startEndpoint ||
        hoveredEndpoint != oldDelegate.hoveredEndpoint ||
        currentPosition != oldDelegate.currentPosition ||
        endpoints.length != oldDelegate.endpoints.length;
  }
}
