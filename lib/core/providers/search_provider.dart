import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_model.dart';
import '../services/project_service.dart';
import 'auth_provider.dart';

/// Current search query text
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Debounced search results provider
/// Uses existing ProjectService.searchProjects() with 300ms debounce
final searchResultsProvider =
    FutureProvider.autoDispose<List<ProjectModel>>((ref) async {
  final query = ref.watch(searchQueryProvider).trim();

  // Return empty list for empty/short queries
  if (query.isEmpty || query.length < 2) {
    return [];
  }

  // Debounce: wait 300ms before executing search
  // If query changes during this time, the provider is invalidated
  await Future.delayed(const Duration(milliseconds: 300));

  // Check if still the current query after debounce
  if (ref.watch(searchQueryProvider).trim() != query) {
    // Query changed during debounce, return empty (will be replaced by new search)
    return [];
  }

  final projectService = ref.watch(projectServiceProvider);
  final authState = ref.watch(authProvider);
  final userId = authState.user?.uid;

  if (userId == null) {
    return [];
  }

  return projectService.searchProjects(userId, query);
});

/// Clear search state
void clearSearch(WidgetRef ref) {
  ref.read(searchQueryProvider.notifier).state = '';
}
