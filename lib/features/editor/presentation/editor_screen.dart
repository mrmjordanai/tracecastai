import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/models/vectorize_result.dart';
import '../../../core/providers/editor_state_provider.dart';
import '../../../core/providers/piece_version_provider.dart';
import 'widgets/vector_canvas.dart';
import 'widgets/editor_toolbar.dart';
import 'widgets/confirmation_overlay.dart';

/// Main editor screen for vector editing (Screen 23)
class EditorScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String pieceId;
  final VectorizeResult? initialResult;
  final String? imagePath;

  const EditorScreen({
    super.key,
    required this.projectId,
    required this.pieceId,
    this.initialResult,
    this.imagePath,
  });

  @override
  ConsumerState<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends ConsumerState<EditorScreen> {
  bool _showConfirmation = false;
  Timer? _autoSaveTimer;

  @override
  void initState() {
    super.initState();

    // Initialize editor with result
    if (widget.initialResult != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref
            .read(editorStateProvider.notifier)
            .initialize(widget.initialResult!);
      });
    }
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  void _startAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(seconds: PieceVersionState.autoSaveIdleSeconds),
      _autoSave,
    );
  }

  void _autoSave() {
    final state = ref.read(editorStateProvider);
    if (state.hasUnsavedChanges && state.result != null) {
      // Would save to Firestore here
      // For now, just mark as saved
      ref.read(editorStateProvider.notifier).markSaved();
    }
  }

  void _handleDone() {
    final state = ref.read(editorStateProvider);

    if (state.hasUnsavedChanges) {
      // Show save confirmation
      setState(() {
        _showConfirmation = true;
      });

      // Trigger save
      _autoSave();

      // Hide overlay after animation
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _showConfirmation = false;
          });
          _navigateToProjector();
        }
      });
    } else {
      _navigateToProjector();
    }
  }

  void _navigateToProjector() {
    HapticFeedback.mediumImpact();

    final state = ref.read(editorStateProvider);
    context.go('/projector/${widget.projectId}', extra: {
      'result': state.result,
      'pieceId': widget.pieceId,
    });
  }

  void _handleBack() {
    final state = ref.read(editorStateProvider);

    if (state.hasUnsavedChanges) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: BlueprintColors.surfaceOverlay,
          title: const Text(
            'Unsaved Changes',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'You have unsaved changes. Do you want to save before leaving?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ref.read(editorStateProvider.notifier).clear();
                context.pop();
              },
              child: const Text('Discard'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _autoSave();
                ref.read(editorStateProvider.notifier).clear();
                context.pop();
              },
              child: const Text('Save'),
            ),
          ],
        ),
      );
    } else {
      ref.read(editorStateProvider.notifier).clear();
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);

    // Start/reset auto-save timer on changes
    ref.listen<EditorState>(editorStateProvider, (previous, next) {
      if (next.changesSinceLastSave >=
          PieceVersionState.autoSaveChangeThreshold) {
        _autoSave();
      } else if (next.hasUnsavedChanges) {
        _startAutoSaveTimer();
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background image (if available)
          if (widget.imagePath != null)
            Positioned.fill(
              child: Opacity(
                opacity: 0.3,
                child: Image.file(
                  File(widget.imagePath!),
                  fit: BoxFit.contain,
                ),
              ),
            ),

          // Main content
          Column(
            children: [
              // App bar
              SafeArea(
                bottom: false,
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      // Back button
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _handleBack,
                      ),
                      const Spacer(),
                      // Title with unsaved indicator
                      Text(
                        'Quick Fix Editor',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                      if (editorState.hasUnsavedChanges)
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(left: 8),
                          decoration: const BoxDecoration(
                            color: BlueprintColors.accentAction,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const Spacer(),
                      // Layer toggles
                      IconButton(
                        icon: const Icon(Icons.layers, color: Colors.white),
                        onPressed: () => _showLayerSheet(context),
                      ),
                    ],
                  ),
                ),
              ),

              // Vector canvas
              Expanded(
                child: editorState.result != null
                    ? VectorCanvas(
                        result: editorState.result!,
                        showConfidenceHighlights: true,
                      )
                    : const Center(
                        child: CircularProgressIndicator(
                          color: BlueprintColors.accentAction,
                        ),
                      ),
              ),

              // Toolbar
              EditorToolbar(
                onDone: _handleDone,
              ),
            ],
          ),

          // Layer toggles overlay
          Positioned(
            top: MediaQuery.of(context).padding.top + 64,
            left: 16,
            child: const LayerToggles(),
          ),

          // Confirmation overlay
          if (_showConfirmation) const ConfirmationOverlay(),
        ],
      ),
    );
  }

  void _showLayerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BlueprintColors.surfaceOverlay,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const _LayerSettingsSheet(),
    );
  }
}

class _LayerSettingsSheet extends ConsumerWidget {
  const _LayerSettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility =
        ref.watch(editorStateProvider.select((s) => s.layerVisibility));
    final notifier = ref.read(editorStateProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Layers',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 24),
          _LayerSwitch(
            label: 'Cutline',
            subtitle: 'Main pattern outline',
            icon: Icons.crop_square,
            isEnabled: visibility.cutline,
            onChanged: (v) => notifier.toggleLayer('cutline'),
          ),
          _LayerSwitch(
            label: 'Markings',
            subtitle: 'Darts, notches, grainlines',
            icon: Icons.edit,
            isEnabled: visibility.markings,
            onChanged: (v) => notifier.toggleLayer('markings'),
          ),
          _LayerSwitch(
            label: 'Labels',
            subtitle: 'Text labels and annotations',
            icon: Icons.text_fields,
            isEnabled: visibility.labels,
            onChanged: (v) => notifier.toggleLayer('labels'),
          ),
          _LayerSwitch(
            label: 'Grid',
            subtitle: '10mm reference grid',
            icon: Icons.grid_on,
            isEnabled: visibility.grid,
            onChanged: (v) => notifier.toggleLayer('grid'),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

class _LayerSwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const _LayerSwitch({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.isEnabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: isEnabled ? Colors.white : Colors.white38,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isEnabled ? Colors.white : Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: isEnabled,
            onChanged: onChanged,
            activeColor: BlueprintColors.accentAction,
          ),
        ],
      ),
    );
  }
}
