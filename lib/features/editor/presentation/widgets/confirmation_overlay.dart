import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/theme/blueprint_colors.dart';

/// Particle burst confirmation overlay for save animations
class ConfirmationOverlay extends StatefulWidget {
  /// Text to display in the center
  final String text;

  /// Duration of the animation
  final Duration duration;

  const ConfirmationOverlay({
    super.key,
    this.text = 'Saved!',
    this.duration = const Duration(milliseconds: 1500),
  });

  @override
  State<ConfirmationOverlay> createState() => _ConfirmationOverlayState();
}

class _ConfirmationOverlayState extends State<ConfirmationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeIn;
  late final Animation<double> _scale;
  late final Animation<double> _fadeOut;
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );

    _fadeIn = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );

    _scale = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.elasticOut),
      ),
    );

    _fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.7, 1.0, curve: Curves.easeIn),
      ),
    );

    // Generate particles
    _particles = List.generate(
      24,
      (i) => _Particle(
        angle: (i / 24) * 2 * math.pi,
        radius: 80 + math.Random().nextDouble() * 40,
        size: 4 + math.Random().nextDouble() * 6,
        speed: 0.8 + math.Random().nextDouble() * 0.4,
      ),
    );

    // Trigger haptic feedback
    HapticFeedback.heavyImpact();

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeIn.value * _fadeOut.value,
          child: Container(
            color: Colors.black.withValues(alpha: 0.6),
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Particles
                  ..._particles.map((p) => _buildParticle(p)),

                  // Center content
                  Transform.scale(
                    scale: _scale.value,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 24,
                      ),
                      decoration: BoxDecoration(
                        color: BlueprintColors.successState,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: BlueprintColors.successState
                                .withValues(alpha: 0.4),
                            blurRadius: 20,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildParticle(_Particle particle) {
    final progress = (_controller.value * particle.speed).clamp(0.0, 1.0);
    final distance = particle.radius * Curves.easeOut.transform(progress);
    final opacity = (1.0 - progress).clamp(0.0, 1.0);

    return Transform.translate(
      offset: Offset(
        math.cos(particle.angle) * distance,
        math.sin(particle.angle) * distance,
      ),
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: particle.size,
          height: particle.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.white.withValues(alpha: 0.5),
                blurRadius: 4,
                spreadRadius: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Particle {
  final double angle;
  final double radius;
  final double size;
  final double speed;

  _Particle({
    required this.angle,
    required this.radius,
    required this.size,
    required this.speed,
  });
}

/// Simple success checkmark animation
class SuccessCheckmark extends StatefulWidget {
  final double size;
  final Color color;

  const SuccessCheckmark({
    super.key,
    this.size = 64,
    this.color = BlueprintColors.successState,
  });

  @override
  State<SuccessCheckmark> createState() => _SuccessCheckmarkState();
}

class _SuccessCheckmarkState extends State<SuccessCheckmark>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _checkProgress;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _checkProgress = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _CheckmarkPainter(
            progress: _checkProgress.value,
            color: widget.color,
          ),
        );
      },
    );
  }
}

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({
    required this.progress,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.1
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw circle background
    final circlePaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(
      Offset(size.width / 2, size.height / 2),
      size.width / 2,
      circlePaint,
    );

    // Draw checkmark path
    final path = Path();
    final startX = size.width * 0.25;
    final startY = size.height * 0.5;
    final midX = size.width * 0.42;
    final midY = size.height * 0.65;
    final endX = size.width * 0.75;
    final endY = size.height * 0.35;

    path.moveTo(startX, startY);

    if (progress <= 0.5) {
      // First segment
      final segProgress = progress * 2;
      path.lineTo(
        startX + (midX - startX) * segProgress,
        startY + (midY - startY) * segProgress,
      );
    } else {
      // First segment complete
      path.lineTo(midX, midY);
      // Second segment
      final segProgress = (progress - 0.5) * 2;
      path.lineTo(
        midX + (endX - midX) * segProgress,
        midY + (endY - midY) * segProgress,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return progress != oldDelegate.progress || color != oldDelegate.color;
  }
}
