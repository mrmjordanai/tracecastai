import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/manual_scale_provider.dart';
import '../../../shared/widgets/scrubber_input.dart';
import 'widgets/scale_line_painter.dart';

/// Manual Scale Input Screen
///
/// Displayed when no reference object is detected and the user needs to
/// manually specify a known dimension to calculate scale.
///
/// Flow:
/// 1. Display captured image fullscreen
/// 2. User draws a line across a known dimension
/// 3. User enters the known dimension via ScrubberInput
/// 4. Calculate px→mm scale factor
/// 5. Navigate to analysis/projector with the scale
class ManualScaleScreen extends ConsumerStatefulWidget {
  final String imagePath;
  final String? projectId;
  final String mode;

  const ManualScaleScreen({
    super.key,
    required this.imagePath,
    this.projectId,
    required this.mode,
  });

  @override
  ConsumerState<ManualScaleScreen> createState() => _ManualScaleScreenState();
}

class _ManualScaleScreenState extends ConsumerState<ManualScaleScreen> {
  final GlobalKey _imageKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Reset state when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(manualScaleProvider.notifier).reset();
      _updateImageSize();
    });
  }

  void _updateImageSize() {
    final renderBox =
        _imageKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null) {
      ref.read(manualScaleProvider.notifier).setImageSize(renderBox.size);
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BlueprintColors.surfaceElevated,
        title: Row(
          children: [
            Icon(Icons.help_outline, color: BlueprintColors.accentAction),
            const SizedBox(width: 8),
            const Text('How to Set Scale'),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _HelpStep(
              number: '1',
              text: 'Draw a line across a feature with a known dimension',
            ),
            SizedBox(height: 12),
            _HelpStep(
              number: '2',
              text: 'Enter the exact measurement of that feature',
            ),
            SizedBox(height: 12),
            _HelpStep(
              number: '3',
              text: 'Tap Continue to use this scale for your pattern',
            ),
            SizedBox(height: 16),
            Text(
              'Tip: Use a straight edge on your pattern, like a seam allowance marking or a known measurement indicator.',
              style: TextStyle(
                color: BlueprintColors.secondaryForeground,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  void _handleContinue() {
    final scaleState = ref.read(manualScaleProvider);

    if (!scaleState.hasValidLine) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please draw a line across a known dimension'),
          backgroundColor: BlueprintColors.errorState,
        ),
      );
      return;
    }

    final scaleMmPerPx = scaleState.scaleMmPerPx;

    if (scaleMmPerPx <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid scale. Please try again.'),
          backgroundColor: BlueprintColors.errorState,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    // Navigate to analysis with the calculated scale
    final projectId = widget.projectId ?? 'new-project';
    context.push('/analysis/$projectId', extra: {
      'imagePath': widget.imagePath,
      'mode': widget.mode,
      'scaleMmPerPx': scaleMmPerPx,
      'scaleSource': 'manual',
    });
  }

  void _clearLine() {
    ref.read(manualScaleProvider.notifier).clearLine();
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    final scaleState = ref.watch(manualScaleProvider);
    final notifier = ref.read(manualScaleProvider.notifier);

    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Set Scale Manually'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: _showHelpDialog,
            tooltip: 'Help',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Image area with drawing overlay
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BlueprintColors.primaryForeground.withValues(alpha: 0.3),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return ScaleLineDrawingArea(
                      startPoint: scaleState.startPoint,
                      endPoint: scaleState.endPoint,
                      isDrawing: scaleState.isDrawing,
                      onDrawStart: (point) {
                        HapticFeedback.selectionClick();
                        notifier.startDrawing(point);
                      },
                      onDrawUpdate: notifier.updateEndPoint,
                      onDrawEnd: notifier.finishDrawing,
                      onStartPointMoved: notifier.moveStartPoint,
                      onEndPointMoved: notifier.moveEndPoint,
                      child: Image.file(
                        File(widget.imagePath),
                        key: _imageKey,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.broken_image_outlined,
                                  size: 64,
                                  color: BlueprintColors.secondaryForeground,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Could not load image',
                                  style: TextStyle(
                                    color: BlueprintColors.secondaryForeground,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ),

            // Instructions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                scaleState.hasValidLine
                    ? 'Line drawn: ${scaleState.pixelDistance.round()} pixels'
                    : 'Draw a line across a known dimension',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: scaleState.hasValidLine
                          ? BlueprintColors.successState
                          : BlueprintColors.secondaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 16),

            // Controls section
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: BlueprintColors.surfaceElevated,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  children: [
                    // Dimension input
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Known Dimension',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                      color: BlueprintColors.primaryForeground,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Enter the actual length of the line you drew',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: BlueprintColors.secondaryForeground,
                                    ),
                              ),
                            ],
                          ),
                        ),
                        if (scaleState.hasValidLine)
                          TextButton(
                            onPressed: _clearLine,
                            child: const Text('Clear'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ScrubberInput for dimension
                    ScrubberInput(
                      value: scaleState.knownDimensionMm,
                      onChanged: notifier.setKnownDimension,
                      min: 10,
                      max: 1000,
                      step: 1,
                      suffix: 'mm',
                      decimalPlaces: 0,
                      semanticLabel: 'Known dimension in millimeters',
                      enabled: scaleState.hasValidLine,
                    ),

                    // Scale result
                    if (scaleState.hasValidLine) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: BlueprintColors.primaryBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.straighten,
                              size: 20,
                              color: BlueprintColors.accentAction,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Scale: ${scaleState.scaleMmPerPx.toStringAsFixed(3)} mm/px',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: BlueprintColors.primaryForeground,
                                    fontFamily: 'monospace',
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const Spacer(),

                    // Continue button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: scaleState.hasValidLine ? _handleContinue : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BlueprintColors.accentAction,
                          foregroundColor: BlueprintColors.primaryForeground,
                          disabledBackgroundColor:
                              BlueprintColors.accentAction.withValues(alpha: 0.3),
                          disabledForegroundColor:
                              BlueprintColors.primaryForeground.withValues(alpha: 0.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpStep extends StatelessWidget {
  final String number;
  final String text;

  const _HelpStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: BlueprintColors.accentAction,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: BlueprintColors.primaryForeground,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: BlueprintColors.primaryForeground,
            ),
          ),
        ),
      ],
    );
  }
}
