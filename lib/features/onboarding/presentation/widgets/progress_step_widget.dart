import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// ProgressStepWidget - CAD-style animation with status text
/// Screen 11: Shows animated drawing effect with status text sequence
class ProgressStepWidget extends StatefulWidget {
  final OnboardingStepDefinition step;
  final Map<String, dynamic> answers;
  final VoidCallback onComplete;

  const ProgressStepWidget({
    super.key,
    required this.step,
    required this.answers,
    required this.onComplete,
  });

  @override
  State<ProgressStepWidget> createState() => _ProgressStepWidgetState();
}

class _ProgressStepWidgetState extends State<ProgressStepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _statusIndex = 0;
  Timer? _statusTimer;
  Timer? _completeTimer;

  static const List<String> _statusMessages = [
    'Analyzing your preferences...',
    'Setting up your workspace...',
    'Configuring projector settings...',
    'Personalizing your experience...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 4),
      vsync: this,
    );
    _controller.forward();

    // Cycle through status messages
    _statusTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
      if (_statusIndex < _statusMessages.length - 1) {
        setState(() {
          _statusIndex++;
        });
      }
    });

    // Auto-advance after 5 seconds
    _completeTimer = Timer(const Duration(seconds: 5), () {
      widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _statusTimer?.cancel();
    _completeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // CAD drawing animation
            SizedBox(
              width: 200,
              height: 200,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return CustomPaint(
                    painter: _CADDrawingPainter(
                      progress: _controller.value,
                    ),
                    size: const Size(200, 200),
                  );
                },
              ),
            ),

            const SizedBox(height: 48),

            // Status text
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _statusMessages[_statusIndex],
                key: ValueKey(_statusIndex),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BlueprintColors.primaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
            ),

            const SizedBox(height: 24),

            // Progress indicator
            SizedBox(
              width: 200,
              child: LinearProgressIndicator(
                value: _controller.value,
                backgroundColor: BlueprintColors.surfaceOverlay,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  BlueprintColors.primaryForeground,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CADDrawingPainter extends CustomPainter {
  _CADDrawingPainter({required this.progress});

  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BlueprintColors.primaryForeground
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    // Draw a simple pattern shape that "reveals" based on progress
    final path = Path();
    final cx = size.width / 2;
    final cy = size.height / 2;
    final radius = size.width * 0.35;

    // Draw rectangle
    path.addRect(Rect.fromCenter(
      center: Offset(cx, cy),
      width: radius * 2,
      height: radius * 1.5,
    ));

    // Add some internal lines
    path.moveTo(cx - radius * 0.6, cy - radius * 0.4);
    path.lineTo(cx + radius * 0.6, cy - radius * 0.4);
    path.moveTo(cx - radius * 0.6, cy);
    path.lineTo(cx + radius * 0.6, cy);
    path.moveTo(cx - radius * 0.6, cy + radius * 0.4);
    path.lineTo(cx + radius * 0.6, cy + radius * 0.4);

    // Calculate path metrics for animation
    final pathMetrics = path.computeMetrics();
    final totalLength = pathMetrics.fold<double>(
      0.0,
      (sum, metric) => sum + metric.length,
    );

    // Draw the animated path
    var drawnLength = 0.0;
    final targetLength = totalLength * progress;

    for (final metric in pathMetrics) {
      if (drawnLength >= targetLength) break;

      final remainingLength = targetLength - drawnLength;
      final extractLength = remainingLength.clamp(0.0, metric.length);

      final extractedPath = metric.extractPath(0, extractLength);
      canvas.drawPath(extractedPath, paint);

      drawnLength += metric.length;
    }

    // Draw grid dots (always visible but faded)
    final dotPaint = Paint()
      ..color = BlueprintColors.tertiaryForeground
      ..style = PaintingStyle.fill;

    const gridSize = 5;
    final spacing = size.width / (gridSize + 1);
    for (var i = 1; i <= gridSize; i++) {
      for (var j = 1; j <= gridSize; j++) {
        canvas.drawCircle(
          Offset(spacing * i, spacing * j),
          2,
          dotPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CADDrawingPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
