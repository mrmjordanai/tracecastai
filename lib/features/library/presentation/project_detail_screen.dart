import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/project_providers.dart';
import '../../../core/services/project_service.dart';
import 'widgets/piece_list_tile.dart';

/// Project Detail Screen - displays project info and pieces
///
/// Features:
/// - Editable project name
/// - List of pieces with thumbnails
/// - "Open in Projector" CTA
/// - Delete/duplicate actions
class ProjectDetailScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectDetailScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectDetailScreen> createState() =>
      _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends ConsumerState<ProjectDetailScreen> {
  bool _isEditingName = false;
  late TextEditingController _nameController;
  final FocusNode _nameFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocusNode.dispose();
    super.dispose();
  }

  /// Start editing the project name
  void _startEditingName(String currentName) {
    setState(() {
      _isEditingName = true;
      _nameController.text = currentName;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      _nameFocusNode.requestFocus();
    });
  }

  /// Save the project name
  Future<void> _saveName() async {
    final newName = _nameController.text.trim();
    if (newName.isNotEmpty) {
      await ref.read(projectsProvider.notifier).updateProject(
            projectId: widget.projectId,
            name: newName,
          );
    }
    setState(() {
      _isEditingName = false;
    });
  }

  /// Show delete confirmation dialog
  Future<void> _confirmDelete(
      BuildContext context, ProjectModel project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text(
          'Are you sure you want to delete "${project.name}"? '
          'This will also delete all ${project.pieceCount} pieces. '
          'This action cannot be undone.',
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
    );

    if (confirmed == true && context.mounted) {
      await ref
          .read(projectsProvider.notifier)
          .deleteProject(project.projectId);
      if (context.mounted) {
        context.pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectAsync = ref.watch(projectProvider(widget.projectId));
    final piecesAsync = ref.watch(piecesStreamProvider(widget.projectId));

    return projectAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: BlueprintColors.errorState,
              ),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () =>
                    ref.invalidate(projectProvider(widget.projectId)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
      data: (project) {
        if (project == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Project not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => context.pop(),
            ),
            title: _isEditingName
                ? TextField(
                    controller: _nameController,
                    focusNode: _nameFocusNode,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    onSubmitted: (_) => _saveName(),
                    onEditingComplete: _saveName,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                  )
                : GestureDetector(
                    onTap: () => _startEditingName(project.name),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            project.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.edit,
                          size: 16,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
            actions: [
              if (_isEditingName)
                IconButton(
                  icon: const Icon(Icons.check),
                  onPressed: _saveName,
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) async {
                    switch (value) {
                      case 'duplicate':
                        final newProject = await ref
                            .read(projectsProvider.notifier)
                            .duplicateProject(project.projectId);
                        if (newProject != null && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content:
                                  Text('Duplicated as "${newProject.name}"'),
                            ),
                          );
                        }
                        break;
                      case 'delete':
                        await _confirmDelete(context, project);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy),
                          SizedBox(width: 12),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 12),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          body: Column(
            children: [
              // Project info header
              Container(
                padding: const EdgeInsets.all(16),
                color: BlueprintColors.surfaceOverlay,
                child: Row(
                  children: [
                    // Mode badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color:
                            BlueprintColors.accentAction.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _getModeIcon(project.mode),
                            size: 16,
                            color: BlueprintColors.accentAction,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatMode(project.mode),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: BlueprintColors.accentAction,
                                      fontWeight: FontWeight.w500,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Piece count
                    Text(
                      '${project.pieceCount} ${project.pieceCount == 1 ? 'piece' : 'pieces'}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: BlueprintColors.secondaryForeground,
                          ),
                    ),
                    const Spacer(),
                    // Tags
                    if (project.tags.isNotEmpty)
                      ...project.tags.take(2).map(
                            (tag) => Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text(tag),
                                labelStyle: const TextStyle(fontSize: 11),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                  ],
                ),
              ),

              // Pieces list
              Expanded(
                child: piecesAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(child: Text('Error: $error')),
                  data: (pieces) {
                    if (pieces.isEmpty) {
                      return _buildEmptyPiecesState(context);
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.invalidate(piecesStreamProvider(widget.projectId));
                      },
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: pieces.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final piece = pieces[index];
                          return PieceListTile(
                            piece: piece,
                            onTap: () {
                              context.push(
                                '/editor/${widget.projectId}',
                                extra: {'pieceId': piece.pieceId},
                              );
                            },
                            onEdit: () {
                              context.push(
                                '/editor/${widget.projectId}',
                                extra: {'pieceId': piece.pieceId},
                              );
                            },
                            onDelete: () async {
                              // ProjectService.deletePiece() already decrements pieceCount
                              final projectService =
                                  ref.read(projectServiceProvider);
                              final authState = ref.read(authProvider);
                              final userId = authState.user?.uid;
                              if (userId != null) {
                                await projectService.deletePiece(
                                  userId,
                                  widget.projectId,
                                  piece.pieceId,
                                );
                              }
                              // UI refreshes automatically via stream provider
                            },
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          // Open in Projector FAB
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              context.push('/projector/${widget.projectId}');
            },
            backgroundColor: BlueprintColors.accentAction,
            icon: const Icon(Icons.cast),
            label: const Text('Open in Projector'),
          ),
          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerFloat,
        );
      },
    );
  }

  Widget _buildEmptyPiecesState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.content_cut,
              size: 64,
              color: BlueprintColors.secondaryForeground,
            ),
            const SizedBox(height: 16),
            Text(
              'No pieces yet',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: BlueprintColors.primaryForeground,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Scan a pattern to add pieces to this project',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: BlueprintColors.secondaryForeground,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                context.push('/scan', extra: {'projectId': widget.projectId});
              },
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
}
