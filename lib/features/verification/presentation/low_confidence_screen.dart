import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';

/// Screen 22c: Low Confidence
///
/// Displayed when AI vectorization succeeds but with low confidence.
/// Warns the user about potential accuracy issues.
class LowConfidenceScreen extends ConsumerWidget {
  final double confidenceScore;
  final String? projectId;
  final String? imagePath;
  final String? mode;

  const LowConfidenceScreen({
    super.key,
    required this.confidenceScore,
    this.projectId,
    this.imagePath,
    this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confidencePercent = (confidenceScore * 100).round();

    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Accuracy Warning'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(flex: 1),

              // Warning icon with confidence score
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 100,
                    height: 100,
                    child: CircularProgressIndicator(
                      value: confidenceScore,
                      strokeWidth: 8,
                      backgroundColor:
                          BlueprintColors.errorState.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getConfidenceColor(),
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$confidencePercent%',
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(
                              color: BlueprintColors.primaryForeground,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Confidence',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: BlueprintColors.secondaryForeground,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Warning title
              Text(
                'Low Accuracy Detected',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BlueprintColors.primaryForeground,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Warning description
              Text(
                'The extracted pattern may not be accurate. This could be due to image quality, lighting, or pattern complexity.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BlueprintColors.secondaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Suggestions for better results
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BlueprintColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'For better accuracy:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: BlueprintColors.primaryForeground,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _SuggestionItem(
                      icon: Icons.wb_sunny_outlined,
                      text: 'Use even, bright lighting',
                    ),
                    const SizedBox(height: 8),
                    _SuggestionItem(
                      icon: Icons.straighten,
                      text: 'Flatten the pattern completely',
                    ),
                    const SizedBox(height: 8),
                    _SuggestionItem(
                      icon: Icons.photo_camera,
                      text: 'Hold camera directly above',
                    ),
                    const SizedBox(height: 8),
                    _SuggestionItem(
                      icon: Icons.grid_on,
                      text: 'Use a cutting mat for reference',
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 2),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _proceedAnyway(context),
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Proceed Anyway'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlueprintColors.accentAction,
                    foregroundColor: BlueprintColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _retakePhoto(context),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Retake Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BlueprintColors.successState,
                    side: const BorderSide(
                      color: BlueprintColors.successState,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor() {
    if (confidenceScore >= 0.7) {
      return BlueprintColors.successState;
    } else if (confidenceScore >= 0.5) {
      return BlueprintColors.accentAction;
    } else {
      return BlueprintColors.errorState;
    }
  }

  void _proceedAnyway(BuildContext context) {
    if (projectId != null) {
      context.go('/projector/$projectId');
    } else {
      context.go('/');
    }
  }

  void _retakePhoto(BuildContext context) {
    final captureMode = mode ?? 'sewing';
    context.go('/capture/$captureMode');
  }
}

class _SuggestionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _SuggestionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: text,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: BlueprintColors.accentAction,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
