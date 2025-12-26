import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/sort_filter_providers.dart';
import '../../../../core/models/project_model.dart';

/// Sort/Filter Bottom Sheet - allows users to sort and filter projects
///
/// Features:
/// - Radio buttons for sort options
/// - Chips for mode filter
/// - Apply/Reset buttons
class SortFilterSheet extends ConsumerWidget {
  const SortFilterSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentSort = ref.watch(sortOptionProvider);
    final currentFilter = ref.watch(modeFilterProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sort & Filter',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              TextButton(
                onPressed: () => resetFilters(ref),
                child: Text(
                  'Reset',
                  style: TextStyle(
                    color: BlueprintColors.accentAction,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Sort options
          Text(
            'Sort by',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SortOption.values.map((option) {
              final isSelected = currentSort == option;
              return ChoiceChip(
                label: Text(option.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(sortOptionProvider.notifier).state = option;
                  }
                },
                selectedColor: BlueprintColors.accentAction,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Mode filter
          Text(
            'Filter by Mode',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white70,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              // "All" chip
              FilterChip(
                label: const Text('All'),
                selected: currentFilter == null,
                onSelected: (selected) {
                  if (selected) {
                    ref.read(modeFilterProvider.notifier).state = null;
                  }
                },
                selectedColor: BlueprintColors.accentAction,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                labelStyle: TextStyle(
                  color: currentFilter == null ? Colors.white : Colors.white70,
                  fontWeight: currentFilter == null
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                checkmarkColor: Colors.white,
              ),
              // Mode chips
              ...PatternMode.values.map((mode) {
                final isSelected = currentFilter == mode;
                return FilterChip(
                  label: Text(_formatMode(mode)),
                  selected: isSelected,
                  onSelected: (selected) {
                    ref.read(modeFilterProvider.notifier).state =
                        selected ? mode : null;
                  },
                  selectedColor: BlueprintColors.accentAction,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  checkmarkColor: Colors.white,
                  avatar: Icon(
                    _getModeIcon(mode),
                    size: 16,
                    color: isSelected ? Colors.white : Colors.white70,
                  ),
                );
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Apply button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: BlueprintColors.accentAction,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Apply'),
            ),
          ),

          // Bottom padding for safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  String _formatMode(PatternMode mode) {
    switch (mode) {
      case PatternMode.sewing:
        return 'Sewing';
      case PatternMode.quilting:
        return 'Quilting';
      case PatternMode.stencil:
        return 'Stencil';
      case PatternMode.maker:
        return 'Maker';
      case PatternMode.custom:
        return 'Custom';
    }
  }

  IconData _getModeIcon(PatternMode mode) {
    switch (mode) {
      case PatternMode.sewing:
        return Icons.content_cut;
      case PatternMode.quilting:
        return Icons.grid_4x4;
      case PatternMode.stencil:
        return Icons.format_paint;
      case PatternMode.maker:
        return Icons.handyman;
      case PatternMode.custom:
        return Icons.tune;
    }
  }
}

/// Show the sort/filter bottom sheet
void showSortFilterSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (context) => const SortFilterSheet(),
  );
}
