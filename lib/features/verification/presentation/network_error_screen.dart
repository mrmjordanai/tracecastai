import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/connectivity_provider.dart';

/// Screen 22b: Network Error
///
/// Displayed when the device is offline and unable to process
/// the pattern. Shows that the capture is saved for later.
class NetworkErrorScreen extends ConsumerWidget {
  final String? imagePath;
  final String? mode;

  const NetworkErrorScreen({
    super.key,
    this.imagePath,
    this.mode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOnline = ref.watch(isOnlineProvider);

    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      appBar: AppBar(
        title: const Text('No Connection'),
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
              // Offline icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: BlueprintColors.accentAction.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off_rounded,
                  size: 48,
                  color: BlueprintColors.accentAction,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'You\'re Offline',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BlueprintColors.primaryForeground,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Pattern analysis requires an internet connection. Don\'t worry - your photo has been saved!',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BlueprintColors.secondaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Saved confirmation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: BlueprintColors.successState.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: BlueprintColors.successState.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: BlueprintColors.successState,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Photo Saved',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  color: BlueprintColors.primaryForeground,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'We\'ll process it automatically when you\'re back online.',
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
                  ],
                ),
              ),

              const Spacer(),

              // Connection status indicator
              if (isOnline)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: BlueprintColors.successState.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.wifi,
                        color: BlueprintColors.successState,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'You\'re back online!',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: BlueprintColors.successState,
                            ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isOnline ? () => _tryNow(context) : null,
                  icon: const Icon(Icons.refresh),
                  label: Text(isOnline ? 'Process Now' : 'Try Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isOnline
                        ? BlueprintColors.successState
                        : BlueprintColors.accentAction,
                    foregroundColor: BlueprintColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    disabledBackgroundColor: BlueprintColors.surfaceOverlay,
                    disabledForegroundColor: BlueprintColors.tertiaryForeground,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => context.go('/'),
                  icon: const Icon(Icons.home_outlined),
                  label: const Text('Go to Library'),
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

  void _tryNow(BuildContext context) {
    // Go back to analysis to retry
    if (imagePath != null && mode != null) {
      context.go('/analysis/retry', extra: {
        'imagePath': imagePath,
        'mode': mode,
      });
    } else {
      context.go('/');
    }
  }
}
