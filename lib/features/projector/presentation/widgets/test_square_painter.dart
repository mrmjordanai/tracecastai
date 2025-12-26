import 'package:flutter/material.dart';

/// CustomPainter for rendering a test square during calibration
///
/// This painter draws:
/// - A white square outline on black background
/// - Corner tick marks for precise measurement
/// - Size label showing expected dimension
class TestSquarePainter extends CustomPainter {
  /// Size of the square in millimeters
  final double sizeMm;

  /// Current display scale (pixels per mm)
  final double displayScale;

  /// Whether to show corner tick marks
  final bool showTicks;

  /// Whether to show the size label
  final bool showLabel;

  /// Unit label (mm or in)
  final String unitLabel;

  /// Size value in display units (mm or inches)
  final double displaySize;

  TestSquarePainter({
    required this.sizeMm,
    required this.displayScale,
    this.showTicks = true,
    this.showLabel = true,
    this.unitLabel = 'mm',
    this.displaySize = 100.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Calculate square size in pixels
    final squareSizePx = sizeMm * displayScale;

    // Square bounds
    final rect = Rect.fromCenter(
      center: center,
      width: squareSizePx,
      height: squareSizePx,
    );

    // Main square paint
    final squarePaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    // Draw square
    canvas.drawRect(rect, squarePaint);

    // Draw corner tick marks
    if (showTicks) {
      _drawCornerTicks(canvas, rect, squarePaint);
    }

    // Draw center crosshair
    _drawCenterCrosshair(canvas, center, 10.0);

    // Draw size label
    if (showLabel) {
      _drawSizeLabel(canvas, rect);
    }
  }

  void _drawCornerTicks(Canvas canvas, Rect rect, Paint paint) {
    const tickLength = 12.0;
    const tickInset = 4.0;

    // Tick paint (slightly thicker)
    final tickPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Top-left corner
    canvas.drawLine(
      Offset(rect.left - tickInset, rect.top),
      Offset(rect.left - tickInset - tickLength, rect.top),
      tickPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top - tickInset),
      Offset(rect.left, rect.top - tickInset - tickLength),
      tickPaint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(rect.right + tickInset, rect.top),
      Offset(rect.right + tickInset + tickLength, rect.top),
      tickPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top - tickInset),
      Offset(rect.right, rect.top - tickInset - tickLength),
      tickPaint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(rect.left - tickInset, rect.bottom),
      Offset(rect.left - tickInset - tickLength, rect.bottom),
      tickPaint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.bottom + tickInset),
      Offset(rect.left, rect.bottom + tickInset + tickLength),
      tickPaint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(rect.right + tickInset, rect.bottom),
      Offset(rect.right + tickInset + tickLength, rect.bottom),
      tickPaint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.bottom + tickInset),
      Offset(rect.right, rect.bottom + tickInset + tickLength),
      tickPaint,
    );
  }

  void _drawCenterCrosshair(Canvas canvas, Offset center, double size) {
    final crosshairPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - size, center.dy),
      Offset(center.dx + size, center.dy),
      crosshairPaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - size),
      Offset(center.dx, center.dy + size),
      crosshairPaint,
    );
  }

  void _drawSizeLabel(Canvas canvas, Rect rect) {
    final sizeText = displaySize == displaySize.roundToDouble()
        ? '${displaySize.round()} $unitLabel'
        : '${displaySize.toStringAsFixed(2)} $unitLabel';

    final textSpan = TextSpan(
      text: sizeText,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        fontFamily: 'monospace',
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();

    // Position below the square
    final labelOffset = Offset(
      rect.center.dx - textPainter.width / 2,
      rect.bottom + 24,
    );

    textPainter.paint(canvas, labelOffset);

    // Draw dimension arrows on top edge
    _drawDimensionArrow(
      canvas,
      Offset(rect.left, rect.top - 20),
      Offset(rect.right, rect.top - 20),
    );
  }

  void _drawDimensionArrow(Canvas canvas, Offset start, Offset end) {
    final arrowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Main line
    canvas.drawLine(start, end, arrowPaint);

    // Arrow heads
    const arrowSize = 6.0;

    // Left arrow head
    canvas.drawLine(
      start,
      Offset(start.dx + arrowSize, start.dy - arrowSize),
      arrowPaint,
    );
    canvas.drawLine(
      start,
      Offset(start.dx + arrowSize, start.dy + arrowSize),
      arrowPaint,
    );

    // Right arrow head
    canvas.drawLine(
      end,
      Offset(end.dx - arrowSize, end.dy - arrowSize),
      arrowPaint,
    );
    canvas.drawLine(
      end,
      Offset(end.dx - arrowSize, end.dy + arrowSize),
      arrowPaint,
    );

    // Vertical end caps
    canvas.drawLine(
      Offset(start.dx, start.dy - 8),
      Offset(start.dx, start.dy + 8),
      arrowPaint,
    );
    canvas.drawLine(
      Offset(end.dx, end.dy - 8),
      Offset(end.dx, end.dy + 8),
      arrowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TestSquarePainter oldDelegate) {
    return oldDelegate.sizeMm != sizeMm ||
        oldDelegate.displayScale != displayScale ||
        oldDelegate.showTicks != showTicks ||
        oldDelegate.showLabel != showLabel;
  }
}

/// Widget that displays a test square for calibration
class TestSquareDisplay extends StatelessWidget {
  final double sizeMm;
  final double displayScale;
  final bool useMetric;

  const TestSquareDisplay({
    super.key,
    this.sizeMm = 100.0,
    this.displayScale = 1.0,
    this.useMetric = true,
  });

  @override
  Widget build(BuildContext context) {
    final displaySize = useMetric ? sizeMm : sizeMm / 25.4;
    final unitLabel = useMetric ? 'mm' : 'in';

    return Container(
      color: Colors.black,
      child: CustomPaint(
        painter: TestSquarePainter(
          sizeMm: sizeMm,
          displayScale: displayScale,
          showTicks: true,
          showLabel: true,
          unitLabel: unitLabel,
          displaySize: displaySize,
        ),
        size: Size.infinite,
      ),
    );
  }
}
