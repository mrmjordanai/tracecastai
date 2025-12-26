import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/search_provider.dart';
import '../../../core/providers/project_providers.dart';
import '../../../shared/widgets/project_list_tile.dart';

/// Search Screen - search projects by name or tags
///
/// Features:
/// - Auto-focused search TextField
/// - Debounced search (300ms)
/// - Results using existing ProjectListTile
/// - Empty and no-results states
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    // Auto-focus the search field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    ref.read(searchQueryProvider.notifier).state = query;
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).state = '';
  }

  @override
  Widget build(BuildContext context) {
    final query = ref.watch(searchQueryProvider);
    final searchResults = ref.watch(searchResultsProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Clear search state when leaving
            clearSearch(ref);
            context.pop();
          },
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _focusNode,
          onChanged: _onSearchChanged,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.white,
              ),
          decoration: InputDecoration(
            hintText: 'Search projects...',
            hintStyle: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
            ),
            border: InputBorder.none,
            suffixIcon: query.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear),
                    color: Colors.white70,
                    onPressed: _clearSearch,
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
        ),
        backgroundColor: BlueprintColors.primaryBackground,
      ),
      body: _buildBody(query, searchResults),
    );
  }

  Widget _buildBody(
      String query, AsyncValue<List<ProjectModel>> searchResults) {
    // Empty query state
    if (query.isEmpty || query.length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: BlueprintColors.secondaryForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'Search your projects',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BlueprintColors.primaryForeground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Type at least 2 characters to search',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
            ),
          ],
        ),
      );
    }

    // Search results
    return searchResults.when(
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, _) => Center(
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
              'Search failed',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BlueprintColors.primaryForeground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
      data: (projects) {
        if (projects.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.search_off,
                  size: 64,
                  color: BlueprintColors.secondaryForeground,
                ),
                const SizedBox(height: 16),
                Text(
                  'No results found',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: BlueprintColors.primaryForeground,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try a different search term',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: BlueprintColors.secondaryForeground,
                      ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
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
        );
      },
    );
  }
}
