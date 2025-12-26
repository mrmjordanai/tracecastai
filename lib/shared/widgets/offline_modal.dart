import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme/blueprint_colors.dart';

/// Modal shown when user tries to scan while offline
class OfflineModal extends StatelessWidget {
  const OfflineModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const OfflineModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: BlueprintColors.tertiaryForeground,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),

              // Offline icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: BlueprintColors.primaryBackground,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.cloud_off,
                  size: 40,
                  color: BlueprintColors.primaryForeground,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'You\'re Offline',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BlueprintColors.primaryForeground,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'Scanning requires an internet connection to process your patterns with AI. Connect to Wi-Fi or mobile data to continue.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BlueprintColors.secondaryForeground,
                    ),
              ),
              const SizedBox(height: 24),

              // Library button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go('/');
                  },
                  icon: const Icon(Icons.folder_open),
                  label: const Text('Go to Library'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlueprintColors.primaryForeground,
                    foregroundColor: BlueprintColors.primaryBackground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Dismiss button
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Dismiss'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline offline banner for app bar or screen top
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: BlueprintColors.errorState.withValues(alpha: 0.9),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.cloud_off,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 8),
          Text(
            'No internet connection',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );
  }
}
