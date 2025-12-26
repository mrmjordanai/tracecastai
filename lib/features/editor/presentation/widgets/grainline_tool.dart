import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// Tool for adding grainline directional arrows
class GrainlineTool extends ConsumerStatefulWidget {
  /// The vectorization result
  final VectorizeResult result;

  /// Display scale (mm to pixels)
  final double displayScale;

  /// Pan offset
  final Offset offset;

  /// Default grainline length in mm
  final double defaultLengthMm;

  /// Callback when grainline is added
  final ValueChanged<VectorPath>? onGrainlineAdded;

  const GrainlineTool({
    super.key,
    required this.result,
    required this.displayScale,
    required this.offset,
    this.defaultLengthMm = 50.0,
    this.onGrainlineAdded,
  });

  @override
  ConsumerState<GrainlineTool> createState() => _GrainlineToolState();
}

class _GrainlineToolState extends ConsumerState<GrainlineTool> {
  Offset? _startPoint;
  Offset? _endPoint;
  bool _isDrawing = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: CustomPaint(
        painter: _GrainlinePainter(
          startPoint: _startPoint,
          endPoint: _endPoint,
          displayScale: widget.displayScale,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onPanStart(DragStartDetails details) {
    setState(() {
      _isDrawing = true;
      _startPoint = details.localPosition;
      _endPoint = details.localPosition;
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isDrawing) return;

    setState(() {
      _endPoint = details.localPosition;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isDrawing || _startPoint == null || _endPoint == null) return;

    // Check minimum length (at least 20 pixels)
    final length = (_endPoint! - _startPoint!).distance;
    if (length > 20) {
      _addGrainline();
    }

    setState(() {
      _isDrawing = false;
      _startPoint = null;
      _endPoint = null;
    });
  }

  void _addGrainline() {
    HapticFeedback.mediumImpact();

    // Convert screen coordinates to mm
    final startMm = VectorPoint(
      xMm: (_startPoint!.dx - widget.offset.dx) / widget.displayScale,
      yMm: (_startPoint!.dy - widget.offset.dy) / widget.displayScale,
    );
    final endMm = VectorPoint(
      xMm: (_endPoint!.dx - widget.offset.dx) / widget.displayScale,
      yMm: (_endPoint!.dy - widget.offset.dy) / widget.displayScale,
    );

    // Calculate arrow points
    final dx = endMm.xMm - startMm.xMm;
    final dy = endMm.yMm - startMm.yMm;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    final ux = dx / len;
    final uy = dy / len;
    const arrowSize = 5.0; // mm

    // Arrow head points
    final arrowAngle = math.pi / 6; // 30 degrees
    final arrow1 = VectorPoint(
      xMm: endMm.xMm -
          arrowSize * (ux * math.cos(arrowAngle) - uy * math.sin(arrowAngle)),
      yMm: endMm.yMm -
          arrowSize * (uy * math.cos(arrowAngle) + ux * math.sin(arrowAngle)),
    );
    final arrow2 = VectorPoint(
      xMm: endMm.xMm -
          arrowSize * (ux * math.cos(-arrowAngle) - uy * math.sin(-arrowAngle)),
      yMm: endMm.yMm -
          arrowSize * (uy * math.cos(-arrowAngle) + ux * math.sin(-arrowAngle)),
    );

    // Create grainline with arrow
    final grainlinePath = VectorPath(
      pathId: const Uuid().v4(),
      pathType: 'grainline',
      closed: false,
      points: [
        startMm,
        endMm,
        arrow1,
        endMm,
        arrow2,
      ],
      strokeHintMm: 0.5,
      confidence: 1.0,
    );

    final command = AddPathCommand(
      path: grainlinePath,
      isCutline: false,
    );

    ref.read(editorStateProvider.notifier).executeCommand(command);
    widget.onGrainlineAdded?.call(grainlinePath);
  }
}

class _GrainlinePainter extends CustomPainter {
  final Offset? startPoint;
  final Offset? endPoint;
  final double displayScale;

  _GrainlinePainter({
    this.startPoint,
    this.endPoint,
    required this.displayScale,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (startPoint == null || endPoint == null) return;

    final mainPaint = Paint()
      ..color = BlueprintColors.accentAction
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    // Draw main line
    canvas.drawLine(startPoint!, endPoint!, mainPaint);

    // Draw arrow head
    final dx = endPoint!.dx - startPoint!.dx;
    final dy = endPoint!.dy - startPoint!.dy;
    final len = math.sqrt(dx * dx + dy * dy);
    if (len == 0) return;

    final ux = dx / len;
    final uy = dy / len;
    const arrowSize = 15.0;
    const arrowAngle = math.pi / 6;

    final arrow1 = Offset(
      endPoint!.dx -
          arrowSize * (ux * math.cos(arrowAngle) - uy * math.sin(arrowAngle)),
      endPoint!.dy -
          arrowSize * (uy * math.cos(arrowAngle) + ux * math.sin(arrowAngle)),
    );
    final arrow2 = Offset(
      endPoint!.dx -
          arrowSize * (ux * math.cos(-arrowAngle) - uy * math.sin(-arrowAngle)),
      endPoint!.dy -
          arrowSize * (uy * math.cos(-arrowAngle) + ux * math.sin(-arrowAngle)),
    );

    canvas.drawLine(endPoint!, arrow1, mainPaint);
    canvas.drawLine(endPoint!, arrow2, mainPaint);

    // Draw start circle
    canvas.drawCircle(
      startPoint!,
      5,
      Paint()..color = BlueprintColors.accentAction,
    );

    // Draw length indicator
    final midPoint = Offset(
      (startPoint!.dx + endPoint!.dx) / 2,
      (startPoint!.dy + endPoint!.dy) / 2,
    );
    final lengthMm = len / displayScale;

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${lengthMm.toStringAsFixed(0)}mm',
        style: TextStyle(
          color: BlueprintColors.accentAction,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          backgroundColor: Colors.black.withValues(alpha: 0.7),
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    canvas.save();
    canvas.translate(midPoint.dx, midPoint.dy);
    var angle = math.atan2(dy, dx);
    if (angle > math.pi / 2 || angle < -math.pi / 2) {
      angle += math.pi;
    }
    canvas.rotate(angle);
    textPainter.paint(
      canvas,
      Offset(-textPainter.width / 2, -textPainter.height - 8),
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GrainlinePainter oldDelegate) {
    return startPoint != oldDelegate.startPoint ||
        endPoint != oldDelegate.endPoint;
  }
}
