import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/vectorization_provider.dart';
import 'widgets/laser_sweep_painter.dart';

/// Screen showing analysis progress while vectorizing a pattern
class AnalysisScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String imagePath;
  final String mode;

  const AnalysisScreen({
    super.key,
    required this.projectId,
    required this.imagePath,
    required this.mode,
  });

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  late Animation<double> _sweepAnimation;
  late Animation<double> _pulseAnimation;
  int _currentStageIndex = 0;
  bool _isAnalyzing = true;

  final List<String> _stages = [
    'Uploading image...',
    'Analyzing pattern...',
    'Detecting edges...',
    'Extracting vectors...',
    'Validating results...',
  ];

  // Simulated detected points (normalized 0-1)
  final List<Offset> _detectedPoints = [];

  @override
  void initState() {
    super.initState();

    // Sweep animation (main scanning progress)
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    );

    _sweepAnimation = CurvedAnimation(
      parent: _sweepController,
      curve: Curves.easeInOut,
    );

    // Pulse animation for secondary effects
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start vectorization
    _startVectorization();
  }

  Future<void> _startVectorization() async {
    // Start the sweep animation
    _sweepController.forward();

    // Cycle through stages for visual feedback
    _cycleStages();

    // Add detected points progressively
    _addDetectedPointsProgressively();

    try {
      // Actually call the vectorization
      final notifier = ref.read(vectorizationProvider.notifier);
      await notifier.startVectorization(
        imagePath: widget.imagePath,
        projectId: widget.projectId,
        mode: widget.mode,
      );

      // Navigate to projector on success if still mounted
      if (mounted) {
        setState(() => _isAnalyzing = false);
        // Brief pause to show completed animation
        await Future.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          context.go('/projector/${widget.projectId}');
        }
      }
    } catch (e) {
      // Navigate to error screen
      if (mounted) {
        context.go('/error/vectorization', extra: {
          'errorMessage': e.toString(),
          'imagePath': widget.imagePath,
          'mode': widget.mode,
        });
      }
    }
  }

  void _cycleStages() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted && _currentStageIndex < _stages.length - 1 && _isAnalyzing) {
        setState(() {
          _currentStageIndex++;
        });
        _cycleStages();
      }
    });
  }

  void _addDetectedPointsProgressively() {
    // Simulate finding points during the scan
    final points = [
      const Offset(0.2, 0.15),
      const Offset(0.8, 0.25),
      const Offset(0.3, 0.4),
      const Offset(0.7, 0.55),
      const Offset(0.5, 0.7),
      const Offset(0.25, 0.85),
    ];

    for (int i = 0; i < points.length; i++) {
      Future.delayed(Duration(milliseconds: 1500 + i * 1200), () {
        if (mounted && _isAnalyzing) {
          setState(() {
            _detectedPoints.add(points[i]);
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      body: SafeArea(
        child: Column(
          children: [
            // Top spacing
            const SizedBox(height: 40),

            // Image preview with laser sweep
            _buildScanningPreview(),

            const SizedBox(height: 32),

            // Stage text with animation
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Text(
                _stages[_currentStageIndex],
                key: ValueKey(_currentStageIndex),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BlueprintColors.primaryForeground,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            const SizedBox(height: 12),

            // Progress indicator
            AnimatedBuilder(
              animation: _sweepAnimation,
              builder: (context, child) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: _sweepAnimation.value,
                          backgroundColor: BlueprintColors.surfaceOverlay,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            BlueprintColors.accentAction,
                          ),
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${(_sweepAnimation.value * 100).round()}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BlueprintColors.tertiaryForeground,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Detection count
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: BlueprintColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: BlueprintColors.successState
                          .withValues(alpha: 0.3 + 0.2 * _pulseAnimation.value),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: BlueprintColors.successState,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_detectedPoints.length} elements detected',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BlueprintColors.primaryForeground,
                            ),
                      ),
                    ],
                  ),
                );
              },
            ),

            const Spacer(),

            // Progress hint
            Text(
              'AI is analyzing your pattern',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'This may take up to 30 seconds',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BlueprintColors.tertiaryForeground,
                  ),
            ),
            const SizedBox(height: 24),

            // Cancel button
            Semantics(
              button: true,
              label: 'Cancel analysis',
              child: TextButton(
                onPressed: () => context.pop(),
                child: Text(
                  'Cancel',
                  style: TextStyle(color: BlueprintColors.secondaryForeground),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildScanningPreview() {
    return AnimatedBuilder(
      animation: _sweepAnimation,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          children: [
            // Image preview (if available)
            if (widget.imagePath.isNotEmpty)
              Container(
                width: 280,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: BlueprintColors.surfaceElevated,
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePreview(),
              ),

            // Laser sweep overlay
            LaserSweepWidget(
              progress: _sweepAnimation.value,
              isScanning: _isAnalyzing,
              detectedPoints: _detectedPoints,
              size: const Size(280, 200),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImagePreview() {
    if (widget.imagePath.isEmpty) {
      return Container(
        color: BlueprintColors.surfaceElevated,
        child: const Center(
          child: Icon(
            Icons.image_outlined,
            size: 48,
            color: BlueprintColors.tertiaryForeground,
          ),
        ),
      );
    }

    try {
      return Image.file(
        File(widget.imagePath),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: BlueprintColors.surfaceElevated,
            child: const Center(
              child: Icon(
                Icons.broken_image_outlined,
                size: 48,
                color: BlueprintColors.tertiaryForeground,
              ),
            ),
          );
        },
      );
    } catch (e) {
      return Container(
        color: BlueprintColors.surfaceElevated,
      );
    }
  }
}
