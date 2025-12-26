import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/connectivity_provider.dart';
import '../../../shared/widgets/offline_modal.dart';

/// Scan Screen - Camera capture entry point
///
/// Provides mode selection and initiates the capture flow.
class ScanScreen extends ConsumerWidget {
  const ScanScreen({super.key});

  void _onModeSelected(BuildContext context, WidgetRef ref, String mode) {
    final isOnline = ref.read(isOnlineProvider);
    if (!isOnline) {
      OfflineModal.show(context);
      return;
    }
    context.push('/capture/$mode');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isOffline = ref.watch(isOfflineProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Scan'),
      ),
      body: Column(
        children: [
          // Offline banner
          if (isOffline) const OfflineBanner(),

          Expanded(
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'What are you scanning?',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select the type of pattern for best results',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BlueprintColors.secondaryForeground,
                          ),
                    ),
                    const SizedBox(height: 24),

                    // Mode selection cards
                    Expanded(
                      child: ListView(
                        children: [
                          _ModeCard(
                            icon: Icons.checkroom,
                            title: 'Sewing Pattern',
                            description:
                                'Garment patterns, tissue paper, PDF prints',
                            onTap: () =>
                                _onModeSelected(context, ref, 'sewing'),
                          ),
                          const SizedBox(height: 12),
                          _ModeCard(
                            icon: Icons.grid_4x4,
                            title: 'Quilting Template',
                            description:
                                'Quilt blocks, geometric shapes, appliqué',
                            onTap: () =>
                                _onModeSelected(context, ref, 'quilting'),
                          ),
                          const SizedBox(height: 12),
                          _ModeCard(
                            icon: Icons.brush,
                            title: 'Stencil / Art',
                            description:
                                'Decorative stencils, artistic patterns',
                            onTap: () =>
                                _onModeSelected(context, ref, 'stencil'),
                          ),
                          const SizedBox(height: 12),
                          _ModeCard(
                            icon: Icons.build,
                            title: 'Maker / Custom',
                            description:
                                'Woodworking, crafts, general templates',
                            onTap: () => _onModeSelected(context, ref, 'maker'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Quick scan button
                    ElevatedButton.icon(
                      onPressed: () => _onModeSelected(context, ref, 'sewing'),
                      icon: const Icon(Icons.bolt),
                      label: const Text('Quick Scan'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '$title. $description',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BlueprintColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
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
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              ExcludeSemantics(
                child: Icon(
                  Icons.chevron_right,
                  color: BlueprintColors.secondaryForeground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
