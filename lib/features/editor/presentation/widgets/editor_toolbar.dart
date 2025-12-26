import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// Bottom toolbar for editor tools
class EditorToolbar extends ConsumerWidget {
  /// Callback when undo is pressed
  final VoidCallback? onUndo;

  /// Callback when redo is pressed
  final VoidCallback? onRedo;

  /// Callback when done is pressed
  final VoidCallback? onDone;

  const EditorToolbar({
    super.key,
    this.onUndo,
    this.onRedo,
    this.onDone,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final notifier = ref.read(editorStateProvider.notifier);

    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        border: Border(
          top: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Undo/Redo
            _UndoRedoButton(
              icon: Icons.undo,
              label: 'Undo',
              isEnabled: editorState.canUndo,
              onTap: onUndo ?? () => notifier.undo(),
            ),
            _UndoRedoButton(
              icon: Icons.redo,
              label: 'Redo',
              isEnabled: editorState.canRedo,
              onTap: onRedo ?? () => notifier.redo(),
            ),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 32,
              color: Colors.white.withValues(alpha: 0.2),
            ),
            const SizedBox(width: 8),
            // Tools
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _ToolButton(
                      icon: Icons.pan_tool_outlined,
                      label: 'Select',
                      tool: EditorTool.select,
                      currentTool: editorState.currentTool,
                      onTap: () => notifier.selectTool(EditorTool.select),
                    ),
                    _ToolButton(
                      icon: Icons.gesture,
                      label: 'Lasso',
                      tool: EditorTool.lassoErase,
                      currentTool: editorState.currentTool,
                      onTap: () => notifier.selectTool(EditorTool.lassoErase),
                    ),
                    _ToolButton(
                      icon: Icons.timeline,
                      label: 'Patch',
                      tool: EditorTool.patchLine,
                      currentTool: editorState.currentTool,
                      onTap: () => notifier.selectTool(EditorTool.patchLine),
                    ),
                    _ToolButton(
                      icon: Icons.auto_fix_high,
                      label: 'Smooth',
                      tool: EditorTool.smoothPath,
                      currentTool: editorState.currentTool,
                      onTap: () => notifier.selectTool(EditorTool.smoothPath),
                    ),
                    _ToolButton(
                      icon: Icons.expand_more,
                      label: 'Notch',
                      tool: EditorTool.addNotch,
                      currentTool: editorState.currentTool,
                      onTap: () => notifier.selectTool(EditorTool.addNotch),
                    ),
                    _ToolButton(
                      icon: Icons.swap_vert,
                      label: 'Grain',
                      tool: EditorTool.addGrainline,
                      currentTool: editorState.currentTool,
                      onTap: () => notifier.selectTool(EditorTool.addGrainline),
                    ),
                    _ToolButton(
                      icon: Icons.text_fields,
                      label: 'Label',
                      tool: EditorTool.editLabel,
                      currentTool: editorState.currentTool,
                      onTap: () => notifier.selectTool(EditorTool.editLabel),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Done button
            _DoneButton(
              onTap: onDone ?? () {},
              hasChanges: editorState.hasUnsavedChanges,
            ),
          ],
        ),
      ),
    );
  }
}

class _UndoRedoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isEnabled;
  final VoidCallback onTap;

  const _UndoRedoButton({
    required this.icon,
    required this.label,
    required this.isEnabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      button: true,
      enabled: isEnabled,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isEnabled
              ? () {
                  HapticFeedback.lightImpact();
                  onTap();
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(
              icon,
              size: 24,
              color: isEnabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final EditorTool tool;
  final EditorTool currentTool;
  final VoidCallback onTap;

  const _ToolButton({
    required this.icon,
    required this.label,
    required this.tool,
    required this.currentTool,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = tool == currentTool;

    return Semantics(
      label: '$label tool',
      button: true,
      selected: isSelected,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Material(
          color: isSelected ? BlueprintColors.accentAction : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              onTap();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: 56,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 22,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w400,
                      color: isSelected
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DoneButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasChanges;

  const _DoneButton({
    required this.onTap,
    required this.hasChanges,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Done editing',
      button: true,
      child: Material(
        color: BlueprintColors.successState,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasChanges)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                const Text(
                  'DONE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
