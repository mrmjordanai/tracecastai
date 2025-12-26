import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';

/// Screen 22d: No Reference Detected
///
/// Displayed when no reference object (cutting mat grid, credit card,
/// ArUco markers) is detected in the image for scale calculation.
class NoReferenceScreen extends ConsumerWidget {
  final String? imagePath;
  final String? mode;
  final String? projectId;

  const NoReferenceScreen({
    super.key,
    this.imagePath,
    this.mode,
    this.projectId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      appBar: AppBar(
        title: const Text('Scale Reference Needed'),
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
              const SizedBox(height: 16),

              // Info icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: BlueprintColors.accentAction.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.straighten_outlined,
                  size: 48,
                  color: BlueprintColors.accentAction,
                ),
              ),
              const SizedBox(height: 24),

              // Title
              Text(
                'No Scale Reference Found',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: BlueprintColors.primaryForeground,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),

              // Description
              Text(
                'To ensure your pattern is the correct size, we need a reference object in the photo to calculate scale.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BlueprintColors.secondaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Reference options
              Expanded(
                child: ListView(
                  children: [
                    _ReferenceOption(
                      icon: Icons.grid_on,
                      title: 'Cutting Mat',
                      description: 'Place pattern on a gridded cutting mat',
                      recommended: true,
                    ),
                    const SizedBox(height: 12),
                    _ReferenceOption(
                      icon: Icons.credit_card,
                      title: 'Credit Card',
                      description: 'Place a standard card next to the pattern',
                    ),
                    const SizedBox(height: 12),
                    _ReferenceOption(
                      icon: Icons.qr_code_2,
                      title: 'TraceCast Reference Sheet',
                      description: 'Download and print our calibration sheet',
                      onTap: () => _showReferenceSheetInfo(context),
                    ),
                    const SizedBox(height: 12),
                    _ReferenceOption(
                      icon: Icons.edit,
                      title: 'Enter Scale Manually',
                      description: 'Measure a known dimension yourself',
                      onTap: () => _goToManualScale(context),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _goToManualScale(context),
                  icon: const Icon(Icons.straighten),
                  label: const Text('Enter Scale Manually'),
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
                  label: const Text('Retake with Reference'),
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

  void _goToManualScale(BuildContext context) {
    context.push('/review/manual-scale', extra: {
      'imagePath': imagePath,
      'mode': mode,
      'projectId': projectId,
    });
  }

  void _retakePhoto(BuildContext context) {
    final captureMode = mode ?? 'sewing';
    context.go('/capture/$captureMode');
  }

  void _showReferenceSheetInfo(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BlueprintColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.qr_code_2,
              size: 48,
              color: BlueprintColors.accentAction,
            ),
            const SizedBox(height: 16),
            Text(
              'TraceCast Reference Sheet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BlueprintColors.primaryForeground,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Print our calibration sheet with ArUco markers for the most accurate scale detection. Available in A4 and US Letter sizes.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Download A4 PDF
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BlueprintColors.primaryForeground,
                      side: const BorderSide(
                        color: BlueprintColors.primaryForeground,
                      ),
                    ),
                    child: const Text('A4'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Download Letter PDF
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: BlueprintColors.primaryForeground,
                      side: const BorderSide(
                        color: BlueprintColors.primaryForeground,
                      ),
                    ),
                    child: const Text('Letter'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _ReferenceOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final bool recommended;
  final VoidCallback? onTap;

  const _ReferenceOption({
    required this.icon,
    required this.title,
    required this.description,
    this.recommended = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title. $description${recommended ? '. Recommended' : ''}',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BlueprintColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: recommended
                ? Border.all(
                    color: BlueprintColors.accentAction.withValues(alpha: 0.5),
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: BlueprintColors.primaryBackground,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: BlueprintColors.primaryForeground,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (recommended) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BlueprintColors.accentAction,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'Best',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: BlueprintColors.primaryForeground,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (onTap != null)
                Icon(
                  Icons.chevron_right,
                  color: BlueprintColors.secondaryForeground,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
