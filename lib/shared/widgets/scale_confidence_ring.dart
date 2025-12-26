import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An animated circular ring that displays scale confidence (0-100%)
/// Colors transition: Red (0-50%) → Yellow (50-80%) → Green (80-100%)
class ScaleConfidenceRing extends StatefulWidget {
  /// Confidence value from 0.0 to 1.0
  final double confidence;

  /// Diameter of the ring
  final double size;

  /// Width of the ring stroke
  final double strokeWidth;

  /// Duration for animation
  final Duration animationDuration;

  /// Whether to show the percentage text in center
  final bool showPercentage;

  /// Optional child widget to display in center
  final Widget? child;

  const ScaleConfidenceRing({
    super.key,
    required this.confidence,
    this.size = 120,
    this.strokeWidth = 8,
    this.animationDuration = const Duration(milliseconds: 800),
    this.showPercentage = true,
    this.child,
  });

  @override
  State<ScaleConfidenceRing> createState() => _ScaleConfidenceRingState();
}

class _ScaleConfidenceRingState extends State<ScaleConfidenceRing>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  double _oldConfidence = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );

    _animation = Tween<double>(
      begin: 0.0,
      end: widget.confidence.clamp(0.0, 1.0),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _controller.forward();
  }

  @override
  void didUpdateWidget(ScaleConfidenceRing oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.confidence != widget.confidence) {
      _oldConfidence = _animation.value;
      _animation = Tween<double>(
        begin: _oldConfidence,
        end: widget.confidence.clamp(0.0, 1.0),
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));

      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Get the color based on confidence value
  Color _getConfidenceColor(double confidence) {
    if (confidence < 0.5) {
      // Red to Yellow (0-50%)
      final t = confidence / 0.5;
      return Color.lerp(
        const Color(0xFFFF6B6B), // Soft Red
        const Color(0xFFFFBB33), // Yellow/Orange
        t,
      )!;
    } else if (confidence < 0.8) {
      // Yellow to Green (50-80%)
      final t = (confidence - 0.5) / 0.3;
      return Color.lerp(
        const Color(0xFFFFBB33), // Yellow/Orange
        const Color(0xFF2ECC71), // Emerald Green
        t,
      )!;
    } else {
      // Green (80-100%)
      return const Color(0xFF2ECC71); // Emerald Green
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final confidence = _animation.value;
        final percentage = (confidence * 100).round();
        final color = _getConfidenceColor(confidence);

        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background ring (grey track)
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: 1.0,
                  color: Colors.white.withValues(alpha: 0.2),
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Animated confidence ring
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _RingPainter(
                  progress: confidence,
                  color: color,
                  strokeWidth: widget.strokeWidth,
                ),
              ),
              // Center content
              if (widget.child != null)
                widget.child!
              else if (widget.showPercentage)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$percentage%',
                      style: TextStyle(
                        fontSize: widget.size * 0.22,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Scale',
                      style: TextStyle(
                        fontSize: widget.size * 0.1,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }
}

/// Custom painter for the ring arc
class _RingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _RingPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees) and sweep clockwise
    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(_RingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

/// Convenience extension for displaying confidence as a scale ring
extension ScaleConfidenceRingX on double {
  /// Create a ScaleConfidenceRing from this confidence value
  Widget toScaleRing({
    double size = 120,
    double strokeWidth = 8,
    bool showPercentage = true,
    Widget? child,
  }) {
    return ScaleConfidenceRing(
      confidence: this,
      size: size,
      strokeWidth: strokeWidth,
      showPercentage: showPercentage,
      child: child,
    );
  }
}
