import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'project_providers.dart';

/// Available sort options for project library
enum SortOption {
  dateNewest('Newest First'),
  dateOldest('Oldest First'),
  nameAZ('Name A-Z'),
  nameZA('Name Z-A'),
  confidenceHigh('Confidence High'),
  confidenceLow('Confidence Low');

  final String label;
  const SortOption(this.label);
}

/// Current sort option
final sortOptionProvider =
    StateProvider<SortOption>((ref) => SortOption.dateNewest);

/// Optional mode filter (null = show all modes)
final modeFilterProvider = StateProvider<PatternMode?>((ref) => null);

/// Sorted and filtered projects provider
/// Combines sort and filter options with the projects list
final sortedFilteredProjectsProvider = Provider<List<ProjectModel>>((ref) {
  final projects = ref.watch(projectsProvider).projects;
  final sortOption = ref.watch(sortOptionProvider);
  final modeFilter = ref.watch(modeFilterProvider);

  // Apply mode filter first
  var filtered = modeFilter != null
      ? projects.where((p) => p.mode == modeFilter).toList()
      : List<ProjectModel>.from(projects);

  // Then apply sorting
  switch (sortOption) {
    case SortOption.dateNewest:
      filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      break;
    case SortOption.dateOldest:
      filtered.sort((a, b) => a.updatedAt.compareTo(b.updatedAt));
      break;
    case SortOption.nameAZ:
      filtered
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      break;
    case SortOption.nameZA:
      filtered
          .sort((a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()));
      break;
    case SortOption.confidenceHigh:
      // For now, sort by piece count as proxy (will be replaced with actual confidence)
      filtered.sort((a, b) => b.pieceCount.compareTo(a.pieceCount));
      break;
    case SortOption.confidenceLow:
      filtered.sort((a, b) => a.pieceCount.compareTo(b.pieceCount));
      break;
  }

  return filtered;
});

/// Reset all filters to defaults
void resetFilters(WidgetRef ref) {
  ref.read(sortOptionProvider.notifier).state = SortOption.dateNewest;
  ref.read(modeFilterProvider.notifier).state = null;
}

/// Check if any filters are active
final hasActiveFiltersProvider = Provider<bool>((ref) {
  final sortOption = ref.watch(sortOptionProvider);
  final modeFilter = ref.watch(modeFilterProvider);
  return sortOption != SortOption.dateNewest || modeFilter != null;
});
