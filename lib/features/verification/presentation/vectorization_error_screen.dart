import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';

/// Screen 22a: Vectorization Failed
///
/// Displayed when AI vectorization fails due to model errors,
/// malformed responses, or other processing issues.
class VectorizationErrorScreen extends ConsumerWidget {
  final String? errorCode;
  final String? errorMessage;
  final String? imagePath;
  final String? mode;

  const VectorizationErrorScreen({
    super.key,
    this.errorCode,
    this.errorMessage,
    this.imagePath,
    this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Processing Failed'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/'),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: BlueprintColors.errorState.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  size: 48,
                  color: BlueprintColors.errorState,
                ),
              ),
              const SizedBox(height: 24),

              // Error title
              Text(
                'Couldn\'t Analyze Pattern',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BlueprintColors.primaryForeground,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Error description
              Text(
                _getErrorDescription(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BlueprintColors.secondaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Error code (if available)
              if (errorCode != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: BlueprintColors.surfaceOverlay,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Error: $errorCode',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: BlueprintColors.tertiaryForeground,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),

              const Spacer(),

              // Suggestions
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
                      'Tips for better results:',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: BlueprintColors.primaryForeground,
                          ),
                    ),
                    const SizedBox(height: 12),
                    _SuggestionItem(
                      icon: Icons.wb_sunny_outlined,
                      text: 'Ensure good lighting',
                    ),
                    const SizedBox(height: 8),
                    _SuggestionItem(
                      icon: Icons.crop_free,
                      text: 'Keep pattern flat and centered',
                    ),
                    const SizedBox(height: 8),
                    _SuggestionItem(
                      icon: Icons.contrast,
                      text: 'Use high contrast background',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _retryCapture(context),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
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
                  onPressed: () => _takeNewPhoto(context),
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Take New Photo'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BlueprintColors.primaryForeground,
                    side: const BorderSide(
                      color: BlueprintColors.primaryForeground,
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

  String _getErrorDescription() {
    if (errorMessage != null && errorMessage!.isNotEmpty) {
      return errorMessage!;
    }

    switch (errorCode) {
      case 'AI_UNAVAILABLE':
        return 'Our AI service is temporarily unavailable. Please try again in a moment.';
      case 'INVALID_RESPONSE':
        return 'We couldn\'t process the AI response. Please try again.';
      case 'TIMEOUT':
        return 'The request timed out. Check your connection and try again.';
      default:
        return 'Something went wrong while analyzing your pattern. Please try again.';
    }
  }

  void _retryCapture(BuildContext context) {
    // Go back to try the same image again
    if (imagePath != null && mode != null) {
      context.go('/analysis/retry', extra: {
        'imagePath': imagePath,
        'mode': mode,
      });
    } else {
      context.go('/scan');
    }
  }

  void _takeNewPhoto(BuildContext context) {
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
