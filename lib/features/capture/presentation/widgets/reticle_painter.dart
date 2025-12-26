import 'dart:math';
import 'package:flutter/material.dart';

import '../../../../app/theme/blueprint_colors.dart';

/// CustomPainter for the technical reticle overlay
///
/// This painter draws:
/// - Corner brackets (viewfinder style)
/// - Center crosshair for alignment
/// - Level indicator showing device tilt
class ReticlePainter extends CustomPainter {
  /// Size of corner brackets in pixels
  final double cornerBracketSize;

  /// Thickness of corner bracket lines
  final double cornerBracketThickness;

  /// Size of center crosshair
  final double crosshairSize;

  /// Radius of level indicator
  final double levelIndicatorRadius;

  /// Device tilt angle in degrees (-90 to 90)
  final double tiltAngle;

  /// Whether reference is detected/locked
  final bool isLocked;

  /// Primary color (white normally, green when locked)
  final Color color;

  /// Animation progress (0.0 to 1.0) for pulse effect
  final double pulseProgress;

  ReticlePainter({
    this.cornerBracketSize = 40.0,
    this.cornerBracketThickness = 3.0,
    this.crosshairSize = 20.0,
    this.levelIndicatorRadius = 60.0,
    this.tiltAngle = 0.0,
    this.isLocked = false,
    Color? color,
    this.pulseProgress = 0.0,
  }) : color = color ??
            (isLocked
                ? BlueprintColors.successState
                : BlueprintColors.primaryForeground);

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate pulse scale for animation
    final pulseScale = 1.0 + (pulseProgress * 0.05);

    // Draw corner brackets
    _drawCornerBrackets(canvas, size, pulseScale);

    // Draw center crosshair
    _drawCrosshair(canvas, size);

    // Draw level indicator
    _drawLevelIndicator(canvas, size);
  }

  void _drawCornerBrackets(Canvas canvas, Size size, double scale) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.9)
      ..strokeWidth = cornerBracketThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Margin from edges
    const margin = 24.0;
    final bracketSize = cornerBracketSize * scale;

    // Top-left corner
    _drawCornerBracket(
      canvas,
      Offset(margin, margin),
      bracketSize,
      paint,
      topLeft: true,
    );

    // Top-right corner
    _drawCornerBracket(
      canvas,
      Offset(size.width - margin, margin),
      bracketSize,
      paint,
      topRight: true,
    );

    // Bottom-left corner
    _drawCornerBracket(
      canvas,
      Offset(margin, size.height - margin),
      bracketSize,
      paint,
      bottomLeft: true,
    );

    // Bottom-right corner
    _drawCornerBracket(
      canvas,
      Offset(size.width - margin, size.height - margin),
      bracketSize,
      paint,
      bottomRight: true,
    );
  }

  void _drawCornerBracket(
    Canvas canvas,
    Offset corner,
    double size,
    Paint paint, {
    bool topLeft = false,
    bool topRight = false,
    bool bottomLeft = false,
    bool bottomRight = false,
  }) {
    final path = Path();

    if (topLeft) {
      path.moveTo(corner.dx, corner.dy + size);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx + size, corner.dy);
    } else if (topRight) {
      path.moveTo(corner.dx - size, corner.dy);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx, corner.dy + size);
    } else if (bottomLeft) {
      path.moveTo(corner.dx, corner.dy - size);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx + size, corner.dy);
    } else if (bottomRight) {
      path.moveTo(corner.dx - size, corner.dy);
      path.lineTo(corner.dx, corner.dy);
      path.lineTo(corner.dx, corner.dy - size);
    }

    canvas.drawPath(path, paint);
  }

  void _drawCrosshair(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Horizontal line
    canvas.drawLine(
      Offset(center.dx - crosshairSize, center.dy),
      Offset(center.dx + crosshairSize, center.dy),
      paint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, center.dy - crosshairSize),
      Offset(center.dx, center.dy + crosshairSize),
      paint,
    );

    // Center dot
    final dotPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 3, dotPaint);
  }

  void _drawLevelIndicator(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 80);

    // Outer ring
    final ringPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, levelIndicatorRadius, ringPaint);

    // Tick marks
    _drawLevelTicks(canvas, center, levelIndicatorRadius);

    // Level bubble
    _drawLevelBubble(canvas, center, levelIndicatorRadius);
  }

  void _drawLevelTicks(Canvas canvas, Offset center, double radius) {
    final tickPaint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    // Draw tick marks at 45-degree intervals
    for (var angle = 0; angle < 360; angle += 45) {
      final radians = angle * pi / 180;
      final innerRadius = radius - 8;
      final outerRadius = radius - 2;

      final start = Offset(
        center.dx + innerRadius * cos(radians),
        center.dy + innerRadius * sin(radians),
      );
      final end = Offset(
        center.dx + outerRadius * cos(radians),
        center.dy + outerRadius * sin(radians),
      );

      canvas.drawLine(start, end, tickPaint);
    }
  }

  void _drawLevelBubble(Canvas canvas, Offset center, double radius) {
    // Calculate bubble position based on tilt
    // Clamp tilt to max displacement
    final maxDisplacement = radius * 0.6;
    final displacement = (tiltAngle / 90.0).clamp(-1.0, 1.0) * maxDisplacement;

    final bubbleCenter = Offset(
      center.dx + displacement,
      center.dy,
    );

    // Determine bubble color based on levelness
    final isLevel = tiltAngle.abs() < 2.0;
    final bubbleColor = isLevel
        ? BlueprintColors.successState
        : (tiltAngle.abs() < 10.0
            ? BlueprintColors.accentAction
            : BlueprintColors.errorState);

    // Bubble fill
    final bubbleFillPaint = Paint()
      ..color = bubbleColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(bubbleCenter, 12, bubbleFillPaint);

    // Bubble stroke
    final bubbleStrokePaint = Paint()
      ..color = bubbleColor
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(bubbleCenter, 12, bubbleStrokePaint);

    // Center target ring (shows where bubble should be)
    final targetPaint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, 14, targetPaint);
  }

  @override
  bool shouldRepaint(covariant ReticlePainter oldDelegate) {
    return oldDelegate.tiltAngle != tiltAngle ||
        oldDelegate.isLocked != isLocked ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.color != color;
  }
}
