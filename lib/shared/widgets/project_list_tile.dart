import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../core/models/project_model.dart';

/// A list tile for displaying a project in the library
/// Features: thumbnail preview, swipe-to-delete, long-press context menu
class ProjectListTile extends StatelessWidget {
  final ProjectModel project;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onDuplicate;
  final VoidCallback? onOpenInProjector;

  const ProjectListTile({
    super.key,
    required this.project,
    this.onTap,
    this.onDelete,
    this.onDuplicate,
    this.onOpenInProjector,
  });

  /// Format mode name for display
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

  /// Format relative time for display
  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      final mins = difference.inMinutes;
      return '$mins ${mins == 1 ? 'minute' : 'minutes'} ago';
    } else if (difference.inDays < 1) {
      final hours = difference.inHours;
      return '$hours ${hours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inDays < 7) {
      final days = difference.inDays;
      return '$days ${days == 1 ? 'day' : 'days'} ago';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ${months == 1 ? 'month' : 'months'} ago';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years ${years == 1 ? 'year' : 'years'} ago';
    }
  }

  /// Show context menu on long press
  void _showContextMenu(BuildContext context, Offset position) {
    final RenderBox overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;

    showMenu<String>(
      context: context,
      position: RelativeRect.fromRect(
        Rect.fromLTWH(position.dx, position.dy, 0, 0),
        Offset.zero & overlay.size,
      ),
      items: [
        const PopupMenuItem<String>(
          value: 'open',
          child: Row(
            children: [
              Icon(Icons.folder_open, size: 20),
              SizedBox(width: 12),
              Text('Open'),
            ],
          ),
        ),
        if (onOpenInProjector != null)
          const PopupMenuItem<String>(
            value: 'projector',
            child: Row(
              children: [
                Icon(Icons.cast, size: 20),
                SizedBox(width: 12),
                Text('Open in Projector'),
              ],
            ),
          ),
        if (onDuplicate != null)
          const PopupMenuItem<String>(
            value: 'duplicate',
            child: Row(
              children: [
                Icon(Icons.copy, size: 20),
                SizedBox(width: 12),
                Text('Duplicate'),
              ],
            ),
          ),
        if (onDelete != null)
          const PopupMenuItem<String>(
            value: 'delete',
            child: Row(
              children: [
                Icon(Icons.delete, size: 20, color: Colors.red),
                SizedBox(width: 12),
                Text('Delete', style: TextStyle(color: Colors.red)),
              ],
            ),
          ),
      ],
    ).then((value) {
      switch (value) {
        case 'open':
          onTap?.call();
          break;
        case 'projector':
          onOpenInProjector?.call();
          break;
        case 'duplicate':
          onDuplicate?.call();
          break;
        case 'delete':
          onDelete?.call();
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dismissible(
      key: ValueKey(project.projectId),
      direction: onDelete != null
          ? DismissDirection.endToStart
          : DismissDirection.none,
      confirmDismiss: (_) async {
        // Show confirmation dialog
        return await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Delete Project?'),
                content: Text(
                  'Are you sure you want to delete "${project.name}"? '
                  'This will also delete all ${project.pieceCount} pieces.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Delete'),
                  ),
                ],
              ),
            ) ??
            false;
      },
      onDismissed: (_) => onDelete?.call(),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: GestureDetector(
        onLongPressStart: (details) =>
            _showContextMenu(context, details.globalPosition),
        child: Semantics(
          label:
              '${project.name}, ${_formatMode(project.mode)} project with ${project.pieceCount} pieces',
          button: true,
          child: Material(
            color: theme.colorScheme.surface.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    // Thumbnail
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: project.thumbnailUrl != null
                          ? CachedNetworkImage(
                              imageUrl: project.thumbnailUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => const Center(
                                child: SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white54,
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => const Icon(
                                Icons.pattern,
                                color: Colors.white54,
                              ),
                            )
                          : Icon(
                              _getModeIcon(project.mode),
                              color: Colors.white54,
                              size: 28,
                            ),
                    ),
                    const SizedBox(width: 16),
                    // Project info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            project.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _formatMode(project.mode),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${project.pieceCount} ${project.pieceCount == 1 ? 'piece' : 'pieces'}',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatRelativeTime(project.updatedAt),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.white38,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Chevron
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
