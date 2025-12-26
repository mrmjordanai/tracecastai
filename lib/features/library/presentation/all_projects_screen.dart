import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/project_providers.dart';
import '../../../core/providers/sort_filter_providers.dart';
import '../../../shared/widgets/project_list_tile.dart';
import 'widgets/sort_filter_sheet.dart';

/// All Projects Screen - displays all projects with sort/filter
///
/// Features:
/// - Full project list
/// - Sort options in AppBar dropdown
/// - Filter by pattern mode
/// - Search button navigation
class AllProjectsScreen extends ConsumerWidget {
  const AllProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsState = ref.watch(projectsProvider);
    final sortedProjects = ref.watch(sortedFilteredProjectsProvider);
    final currentSort = ref.watch(sortOptionProvider);
    final hasActiveFilters = ref.watch(hasActiveFiltersProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('All Projects'),
        actions: [
          // Search button
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Search projects',
            onPressed: () => context.push('/search'),
          ),
          // Sort/Filter button with indicator
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Sort & Filter',
                onPressed: () => showSortFilterSheet(context),
              ),
              if (hasActiveFilters)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: BlueprintColors.accentAction,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: projectsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : projectsState.error != null
              ? _buildErrorState(context, ref, projectsState.error!)
              : sortedProjects.isEmpty
                  ? _buildEmptyState(
                      context, ref, projectsState.projects.isEmpty)
                  : _buildProjectList(
                      context, ref, sortedProjects, currentSort),
    );
  }

  Widget _buildErrorState(BuildContext context, WidgetRef ref, String error) {
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
              onPressed: () => ref.invalidate(projectsStreamProvider),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      BuildContext context, WidgetRef ref, bool noProjectsAtAll) {
    // No projects with current filter vs no projects at all
    if (noProjectsAtAll) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.folder_open,
                size: 64,
                color: BlueprintColors.secondaryForeground,
              ),
              const SizedBox(height: 16),
              Text(
                'No projects yet',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: BlueprintColors.primaryForeground,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Scan a pattern to create your first project',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: BlueprintColors.secondaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => context.go('/scan'),
                icon: const Icon(Icons.add_a_photo),
                label: const Text('Scan Pattern'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: BlueprintColors.accentAction,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // No projects matching current filter
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.filter_list_off,
              size: 64,
              color: BlueprintColors.secondaryForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'No matching projects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BlueprintColors.primaryForeground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => resetFilters(ref),
              icon: const Icon(Icons.clear),
              label: const Text('Clear Filters'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectList(
    BuildContext context,
    WidgetRef ref,
    List<ProjectModel> projects,
    SortOption currentSort,
  ) {
    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(projectsStreamProvider);
      },
      color: BlueprintColors.accentAction,
      child: Column(
        children: [
          // Sort indicator bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: BlueprintColors.surfaceOverlay,
            child: Row(
              children: [
                Text(
                  '${projects.length} ${projects.length == 1 ? 'project' : 'projects'}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BlueprintColors.secondaryForeground,
                      ),
                ),
                const Spacer(),
                Text(
                  currentSort.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: BlueprintColors.secondaryForeground,
                      ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.sort,
                  size: 14,
                  color: BlueprintColors.secondaryForeground,
                ),
              ],
            ),
          ),
          // Project list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
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
          ),
        ],
      ),
    );
  }
}
