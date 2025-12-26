import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/blueprint_colors.dart';

/// Empty state widget shown when the library has no projects
class EmptyLibraryState extends StatelessWidget {
  const EmptyLibraryState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BlueprintColors.surfaceElevated.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.camera_alt_outlined,
                size: 48,
                color: BlueprintColors.secondaryForeground,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              'No patterns yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: BlueprintColors.primaryForeground,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Description
            Text(
              'Scan a sewing pattern, quilting template, or stencil to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: BlueprintColors.secondaryForeground,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // CTA Button
            Semantics(
              button: true,
              label: 'Scan your first pattern',
              child: ElevatedButton.icon(
                onPressed: () {
                  // Navigate to scan screen
                  context.go('/scan');
                },
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Scan Your First Pattern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BlueprintColors.accentAction,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Secondary action
            TextButton(
              onPressed: () {
                // Navigate to help
                context.push('/help');
              },
              child: Text(
                'Learn how it works',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: BlueprintColors.secondaryForeground,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
