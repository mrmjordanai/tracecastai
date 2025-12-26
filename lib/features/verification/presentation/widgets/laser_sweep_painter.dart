import 'package:flutter/material.dart';

import '../../../../app/theme/blueprint_colors.dart';

/// Laser sweep animation for the analysis screen
///
/// Creates a scanning effect with:
/// - Horizontal laser line sweeping vertically
/// - Grid overlay appearing as scanning progresses
/// - Detected points highlighting
class LaserSweepWidget extends StatefulWidget {
  /// Progress value 0.0 to 1.0
  final double progress;

  /// Whether the scan is active
  final bool isScanning;

  /// Detected points to highlight (normalized 0-1)
  final List<Offset>? detectedPoints;

  /// Size of the scan area
  final Size size;

  const LaserSweepWidget({
    super.key,
    required this.progress,
    this.isScanning = true,
    this.detectedPoints,
    this.size = const Size(280, 200),
  });

  @override
  State<LaserSweepWidget> createState() => _LaserSweepWidgetState();
}

class _LaserSweepWidgetState extends State<LaserSweepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        return CustomPaint(
          size: widget.size,
          painter: LaserSweepPainter(
            progress: widget.progress,
            glowIntensity: _glowController.value,
            isScanning: widget.isScanning,
            detectedPoints: widget.detectedPoints,
          ),
        );
      },
    );
  }
}

/// CustomPainter for the laser sweep effect
class LaserSweepPainter extends CustomPainter {
  final double progress;
  final double glowIntensity;
  final bool isScanning;
  final List<Offset>? detectedPoints;

  LaserSweepPainter({
    required this.progress,
    required this.glowIntensity,
    required this.isScanning,
    this.detectedPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;

    // Draw scan area background
    _drawScanBackground(canvas, rect);

    // Draw grid overlay (fades in with progress)
    _drawGridOverlay(canvas, rect);

    // Draw scanning laser line
    if (isScanning) {
      _drawLaserLine(canvas, rect);
    }

    // Draw detected points
    _drawDetectedPoints(canvas, rect);

    // Draw corner brackets
    _drawCornerBrackets(canvas, rect);
  }

  void _drawScanBackground(Canvas canvas, Rect rect) {
    final paint = Paint()
      ..color = BlueprintColors.primaryBackground
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      paint,
    );

    // Border
    final borderPaint = Paint()
      ..color = BlueprintColors.primaryForeground.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(12)),
      borderPaint,
    );
  }

  void _drawGridOverlay(Canvas canvas, Rect rect) {
    if (progress <= 0) return;

    final gridPaint = Paint()
      ..color =
          BlueprintColors.primaryForeground.withValues(alpha: 0.1 * progress)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    const gridSpacing = 20.0;

    // Vertical lines
    for (double x = rect.left + gridSpacing; x < rect.right; x += gridSpacing) {
      if ((x - rect.left) / rect.width <= progress) {
        canvas.drawLine(
          Offset(x, rect.top + 12),
          Offset(x, rect.bottom - 12),
          gridPaint,
        );
      }
    }

    // Horizontal lines
    for (double y = rect.top + gridSpacing; y < rect.bottom; y += gridSpacing) {
      if ((y - rect.top) / rect.height <= progress) {
        canvas.drawLine(
          Offset(rect.left + 12, y),
          Offset(rect.right - 12, y),
          gridPaint,
        );
      }
    }
  }

  void _drawLaserLine(Canvas canvas, Rect rect) {
    final laserY = rect.top + (rect.height * progress);

    // Laser glow (outer)
    final glowPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          BlueprintColors.accentAction.withValues(alpha: 0.0),
          BlueprintColors.accentAction
              .withValues(alpha: 0.3 + 0.2 * glowIntensity),
          BlueprintColors.accentAction.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(rect.left, laserY - 20, rect.width, 40));

    canvas.drawRect(
      Rect.fromLTWH(rect.left + 12, laserY - 20, rect.width - 24, 40),
      glowPaint,
    );

    // Laser line (core)
    final laserPaint = Paint()
      ..color = BlueprintColors.accentAction
      ..strokeWidth = 2 + glowIntensity;

    canvas.drawLine(
      Offset(rect.left + 12, laserY),
      Offset(rect.right - 12, laserY),
      laserPaint,
    );

    // Laser endpoint dots
    final dotPaint = Paint()
      ..color = BlueprintColors.accentAction
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(rect.left + 12, laserY), 4, dotPaint);
    canvas.drawCircle(Offset(rect.right - 12, laserY), 4, dotPaint);
  }

  void _drawDetectedPoints(Canvas canvas, Rect rect) {
    if (detectedPoints == null || detectedPoints!.isEmpty) return;

    final pointPaint = Paint()
      ..color = BlueprintColors.successState
      ..style = PaintingStyle.fill;

    final ringPaint = Paint()
      ..color = BlueprintColors.successState.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    for (final point in detectedPoints!) {
      // Only show points that have been "scanned"
      if (point.dy <= progress) {
        final x = rect.left + rect.width * point.dx;
        final y = rect.top + rect.height * point.dy;

        // Animated ring
        final ringRadius = 8 + 4 * glowIntensity;
        canvas.drawCircle(Offset(x, y), ringRadius, ringPaint);

        // Core dot
        canvas.drawCircle(Offset(x, y), 4, pointPaint);
      }
    }
  }

  void _drawCornerBrackets(Canvas canvas, Rect rect) {
    final bracketPaint = Paint()
      ..color = BlueprintColors.primaryForeground.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    const bracketLength = 20.0;
    const offset = 4.0;

    // Top-left
    canvas.drawLine(
      Offset(rect.left + offset, rect.top + offset + bracketLength),
      Offset(rect.left + offset, rect.top + offset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(rect.left + offset, rect.top + offset),
      Offset(rect.left + offset + bracketLength, rect.top + offset),
      bracketPaint,
    );

    // Top-right
    canvas.drawLine(
      Offset(rect.right - offset - bracketLength, rect.top + offset),
      Offset(rect.right - offset, rect.top + offset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(rect.right - offset, rect.top + offset),
      Offset(rect.right - offset, rect.top + offset + bracketLength),
      bracketPaint,
    );

    // Bottom-left
    canvas.drawLine(
      Offset(rect.left + offset, rect.bottom - offset - bracketLength),
      Offset(rect.left + offset, rect.bottom - offset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(rect.left + offset, rect.bottom - offset),
      Offset(rect.left + offset + bracketLength, rect.bottom - offset),
      bracketPaint,
    );

    // Bottom-right
    canvas.drawLine(
      Offset(rect.right - offset - bracketLength, rect.bottom - offset),
      Offset(rect.right - offset, rect.bottom - offset),
      bracketPaint,
    );
    canvas.drawLine(
      Offset(rect.right - offset, rect.bottom - offset),
      Offset(rect.right - offset, rect.bottom - offset - bracketLength),
      bracketPaint,
    );
  }

  @override
  bool shouldRepaint(LaserSweepPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowIntensity != glowIntensity ||
        oldDelegate.isScanning != isScanning;
  }
}

/// Bounding box animation widget
///
/// Shows animated boxes appearing around detected elements
class BoundingBoxOverlay extends StatelessWidget {
  final List<Rect> boxes;
  final double progress;
  final Size size;

  const BoundingBoxOverlay({
    super.key,
    required this.boxes,
    required this.progress,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: BoundingBoxPainter(
        boxes: boxes,
        progress: progress,
      ),
    );
  }
}

class BoundingBoxPainter extends CustomPainter {
  final List<Rect> boxes;
  final double progress;

  BoundingBoxPainter({
    required this.boxes,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (boxes.isEmpty) return;

    final boxPaint = Paint()
      ..color = BlueprintColors.accentAction
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = BlueprintColors.accentAction.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < boxes.length; i++) {
      // Show boxes progressively
      final boxProgress = (progress * boxes.length - i).clamp(0.0, 1.0);
      if (boxProgress <= 0) continue;

      final box = boxes[i];

      // Scale box from center
      final scaledBox = Rect.fromCenter(
        center: box.center,
        width: box.width * boxProgress,
        height: box.height * boxProgress,
      );

      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledBox, const Radius.circular(4)),
        fillPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(scaledBox, const Radius.circular(4)),
        boxPaint,
      );
    }
  }

  @override
  bool shouldRepaint(BoundingBoxPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
