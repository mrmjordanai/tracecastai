import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/project_providers.dart';
import '../../../shared/widgets/scale_confidence_ring.dart';
import '../../../shared/widgets/project_list_tile.dart';
import 'widgets/empty_library_state.dart';

/// Home Screen - Main dashboard
///
/// Displays the Scale Confidence Ring, recent projects,
/// and quick access to key features.
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Projects are automatically loaded via stream provider
  }

  @override
  Widget build(BuildContext context) {
    final projectsState = ref.watch(projectsProvider);
    final recentProjects = ref.watch(recentProjectsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('TraceCast'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search projects',
            onPressed: () {
              context.push('/search');
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'Notifications',
            onPressed: () {
              // TODO: Show notifications
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          // Stream provider will auto-refresh, but force re-read
          ref.invalidate(projectsStreamProvider);
        },
        color: BlueprintColors.accentAction,
        child: projectsState.isLoading
            ? const Center(child: CircularProgressIndicator())
            : projectsState.error != null
                ? _buildErrorState(projectsState.error!)
                : projectsState.projects.isEmpty
                    ? const SingleChildScrollView(
                        physics: AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: 500, // Ensure scrollable for pull-to-refresh
                          child: EmptyLibraryState(),
                        ),
                      )
                    : _buildProjectList(context, recentProjects),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: BlueprintColors.errorState,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load projects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BlueprintColors.primaryForeground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(projectsStreamProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(BuildContext context, List<ProjectModel> projects) {
    // Use the async confidence provider
    final confidenceAsync = ref.watch(overallScaleConfidenceProvider);
    final averageConfidence = confidenceAsync.valueOrNull ?? 0.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scale Confidence Ring
          Center(
            child: Semantics(
              label:
                  'Scale confidence ${(averageConfidence * 100).round()} percent',
              child: ScaleConfidenceRing(
                confidence: averageConfidence,
                size: 160,
                strokeWidth: 10,
              ),
            ),
          ),

          const SizedBox(height: 8),

          // Stats summary
          Center(
            child: Text(
              '${projects.length} ${projects.length == 1 ? 'project' : 'projects'}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
            ),
          ),

          const SizedBox(height: 32),

          // Recent Projects section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Projects',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              if (projects.length > 5)
                TextButton(
                  onPressed: () {
                    // Navigate to all projects
                    context.push('/projects');
                  },
                  child: const Text('See all'),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Project list
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: projects.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final project = projects[index];
              return ProjectListTile(
                project: project,
                onTap: () {
                  ref.read(projectsProvider.notifier).selectProject(project);
                  context.push('/project/${project.projectId}');
                },
                onDelete: () async {
                  await ref
                      .read(projectsProvider.notifier)
                      .deleteProject(project.projectId);
                },
                onDuplicate: () async {
                  await ref
                      .read(projectsProvider.notifier)
                      .duplicateProject(project.projectId);
                },
                onOpenInProjector: () {
                  context.push('/projector/${project.projectId}');
                },
              );
            },
          ),

          const SizedBox(height: 32),

          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.grid_on,
                  label: 'Reference Sheet',
                  onTap: () {
                    context.push('/debug');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.tune,
                  label: 'Calibration',
                  onTap: () {
                    context.push('/calibration');
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Row(
            children: [
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.help_outline,
                  label: 'Help',
                  onTap: () {
                    context.push('/help');
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickActionCard(
                  icon: Icons.bug_report,
                  label: 'Debug',
                  onTap: () {
                    context.push('/debug');
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BlueprintColors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: BlueprintColors.primaryForeground,
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
