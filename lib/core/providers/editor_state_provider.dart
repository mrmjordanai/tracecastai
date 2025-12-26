import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vectorize_result.dart';

/// Available editor tools
enum EditorTool {
  select,
  lassoErase,
  patchLine,
  smoothPath,
  addNotch,
  addGrainline,
  editLabel,
}

/// Layer visibility settings
@immutable
class LayerVisibility {
  final bool cutline;
  final bool markings;
  final bool labels;
  final bool grid;

  const LayerVisibility({
    this.cutline = true,
    this.markings = true,
    this.labels = true,
    this.grid = false,
  });

  LayerVisibility copyWith({
    bool? cutline,
    bool? markings,
    bool? labels,
    bool? grid,
  }) {
    return LayerVisibility(
      cutline: cutline ?? this.cutline,
      markings: markings ?? this.markings,
      labels: labels ?? this.labels,
      grid: grid ?? this.grid,
    );
  }
}

/// State for the vector editor
@immutable
class EditorState {
  /// The vectors being edited
  final VectorizeResult? result;

  /// Current tool selection
  final EditorTool currentTool;

  /// Selected path IDs
  final Set<String> selectedPathIds;

  /// Selected label IDs
  final Set<String> selectedLabelIds;

  /// Layer visibility settings
  final LayerVisibility layerVisibility;

  /// Whether the editor has unsaved changes
  final bool hasUnsavedChanges;

  /// Number of changes since last save
  final int changesSinceLastSave;

  /// Current zoom level (1.0 = 100%)
  final double zoomLevel;

  /// Pan offset in screen coordinates
  final Offset panOffset;

  /// Undo stack
  final List<EditorCommand> undoStack;

  /// Redo stack
  final List<EditorCommand> redoStack;

  /// Maximum undo history size
  static const int maxUndoStackSize = 20;

  const EditorState({
    this.result,
    this.currentTool = EditorTool.select,
    this.selectedPathIds = const {},
    this.selectedLabelIds = const {},
    this.layerVisibility = const LayerVisibility(),
    this.hasUnsavedChanges = false,
    this.changesSinceLastSave = 0,
    this.zoomLevel = 1.0,
    this.panOffset = Offset.zero,
    this.undoStack = const [],
    this.redoStack = const [],
  });

  bool get canUndo => undoStack.isNotEmpty;
  bool get canRedo => redoStack.isNotEmpty;
  bool get hasSelection =>
      selectedPathIds.isNotEmpty || selectedLabelIds.isNotEmpty;

  EditorState copyWith({
    VectorizeResult? result,
    EditorTool? currentTool,
    Set<String>? selectedPathIds,
    Set<String>? selectedLabelIds,
    LayerVisibility? layerVisibility,
    bool? hasUnsavedChanges,
    int? changesSinceLastSave,
    double? zoomLevel,
    Offset? panOffset,
    List<EditorCommand>? undoStack,
    List<EditorCommand>? redoStack,
  }) {
    return EditorState(
      result: result ?? this.result,
      currentTool: currentTool ?? this.currentTool,
      selectedPathIds: selectedPathIds ?? this.selectedPathIds,
      selectedLabelIds: selectedLabelIds ?? this.selectedLabelIds,
      layerVisibility: layerVisibility ?? this.layerVisibility,
      hasUnsavedChanges: hasUnsavedChanges ?? this.hasUnsavedChanges,
      changesSinceLastSave: changesSinceLastSave ?? this.changesSinceLastSave,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      panOffset: panOffset ?? this.panOffset,
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
    );
  }
}

/// Abstract base class for reversible editor commands
abstract class EditorCommand {
  /// Human-readable description for UI
  String get description;

  /// Execute the command and return the new result
  VectorizeResult execute(VectorizeResult current);

  /// Undo the command and return the previous result
  VectorizeResult undo(VectorizeResult current);
}

/// Command to delete paths
class DeletePathsCommand implements EditorCommand {
  final List<String> pathIds;
  final List<VectorPath> _deletedCutlines;
  final List<VectorPath> _deletedMarkings;

  DeletePathsCommand({
    required this.pathIds,
    List<VectorPath>? deletedCutlines,
    List<VectorPath>? deletedMarkings,
  })  : _deletedCutlines = deletedCutlines ?? [],
        _deletedMarkings = deletedMarkings ?? [];

  @override
  String get description =>
      'Delete ${pathIds.length} path${pathIds.length == 1 ? '' : 's'}';

  @override
  VectorizeResult execute(VectorizeResult current) {
    final newCutlines = current.layers.cutline
        .where((p) => !pathIds.contains(p.pathId))
        .toList();
    final newMarkings = current.layers.markings
        .where((p) => !pathIds.contains(p.pathId))
        .toList();

    return VectorizeResult(
      pieceId: current.pieceId,
      sourceImageId: current.sourceImageId,
      scaleMmPerPx: current.scaleMmPerPx,
      widthMm: current.widthMm,
      heightMm: current.heightMm,
      layers: VectorLayers(
        cutline: newCutlines,
        markings: newMarkings,
        labels: current.layers.labels,
      ),
      qa: current.qa,
    );
  }

  @override
  VectorizeResult undo(VectorizeResult current) {
    return VectorizeResult(
      pieceId: current.pieceId,
      sourceImageId: current.sourceImageId,
      scaleMmPerPx: current.scaleMmPerPx,
      widthMm: current.widthMm,
      heightMm: current.heightMm,
      layers: VectorLayers(
        cutline: [...current.layers.cutline, ..._deletedCutlines],
        markings: [...current.layers.markings, ..._deletedMarkings],
        labels: current.layers.labels,
      ),
      qa: current.qa,
    );
  }
}

/// Command to add a path
class AddPathCommand implements EditorCommand {
  final VectorPath path;
  final bool isCutline;

  AddPathCommand({
    required this.path,
    this.isCutline = true,
  });

  @override
  String get description => 'Add ${path.pathType}';

  @override
  VectorizeResult execute(VectorizeResult current) {
    return VectorizeResult(
      pieceId: current.pieceId,
      sourceImageId: current.sourceImageId,
      scaleMmPerPx: current.scaleMmPerPx,
      widthMm: current.widthMm,
      heightMm: current.heightMm,
      layers: VectorLayers(
        cutline: isCutline
            ? [...current.layers.cutline, path]
            : current.layers.cutline,
        markings: !isCutline
            ? [...current.layers.markings, path]
            : current.layers.markings,
        labels: current.layers.labels,
      ),
      qa: current.qa,
    );
  }

  @override
  VectorizeResult undo(VectorizeResult current) {
    return VectorizeResult(
      pieceId: current.pieceId,
      sourceImageId: current.sourceImageId,
      scaleMmPerPx: current.scaleMmPerPx,
      widthMm: current.widthMm,
      heightMm: current.heightMm,
      layers: VectorLayers(
        cutline: current.layers.cutline
            .where((p) => p.pathId != path.pathId)
            .toList(),
        markings: current.layers.markings
            .where((p) => p.pathId != path.pathId)
            .toList(),
        labels: current.layers.labels,
      ),
      qa: current.qa,
    );
  }
}

/// Command to modify path points (smoothing, etc.)
class ModifyPathCommand implements EditorCommand {
  final String pathId;
  final List<VectorPoint> newPoints;
  final List<VectorPoint> _originalPoints;

  ModifyPathCommand({
    required this.pathId,
    required this.newPoints,
    required List<VectorPoint> originalPoints,
  }) : _originalPoints = originalPoints;

  @override
  String get description => 'Modify path';

  @override
  VectorizeResult execute(VectorizeResult current) {
    return _modifyPath(current, newPoints);
  }

  @override
  VectorizeResult undo(VectorizeResult current) {
    return _modifyPath(current, _originalPoints);
  }

  VectorizeResult _modifyPath(
      VectorizeResult current, List<VectorPoint> points) {
    VectorPath modifyPathInList(VectorPath path) {
      if (path.pathId != pathId) return path;
      return VectorPath(
        pathId: path.pathId,
        pathType: path.pathType,
        closed: path.closed,
        points: points,
        strokeHintMm: path.strokeHintMm,
        confidence: path.confidence,
      );
    }

    return VectorizeResult(
      pieceId: current.pieceId,
      sourceImageId: current.sourceImageId,
      scaleMmPerPx: current.scaleMmPerPx,
      widthMm: current.widthMm,
      heightMm: current.heightMm,
      layers: VectorLayers(
        cutline: current.layers.cutline.map(modifyPathInList).toList(),
        markings: current.layers.markings.map(modifyPathInList).toList(),
        labels: current.layers.labels,
      ),
      qa: current.qa,
    );
  }
}

/// Command to update a text label
class UpdateLabelCommand implements EditorCommand {
  final String labelId;
  final String newText;
  final String _originalText;

  UpdateLabelCommand({
    required this.labelId,
    required this.newText,
    required String originalText,
  }) : _originalText = originalText;

  @override
  String get description => 'Edit label';

  @override
  VectorizeResult execute(VectorizeResult current) {
    return _updateLabel(current, newText);
  }

  @override
  VectorizeResult undo(VectorizeResult current) {
    return _updateLabel(current, _originalText);
  }

  VectorizeResult _updateLabel(VectorizeResult current, String text) {
    return VectorizeResult(
      pieceId: current.pieceId,
      sourceImageId: current.sourceImageId,
      scaleMmPerPx: current.scaleMmPerPx,
      widthMm: current.widthMm,
      heightMm: current.heightMm,
      layers: VectorLayers(
        cutline: current.layers.cutline,
        markings: current.layers.markings,
        labels: current.layers.labels.map((label) {
          if (label.labelId != labelId) return label;
          return TextBox(
            labelId: label.labelId,
            text: text,
            position: label.position,
            size: label.size,
            confidence: label.confidence,
          );
        }).toList(),
      ),
      qa: current.qa,
    );
  }
}

/// Editor state notifier
class EditorStateNotifier extends StateNotifier<EditorState> {
  EditorStateNotifier() : super(const EditorState());

  /// Initialize with vectorization result
  void initialize(VectorizeResult result) {
    state = EditorState(result: result);
  }

  /// Clear the editor state
  void clear() {
    state = const EditorState();
  }

  /// Select a tool
  void selectTool(EditorTool tool) {
    state = state.copyWith(currentTool: tool);
  }

  /// Toggle selection of a path
  void togglePathSelection(String pathId) {
    final newSelection = Set<String>.from(state.selectedPathIds);
    if (newSelection.contains(pathId)) {
      newSelection.remove(pathId);
    } else {
      newSelection.add(pathId);
    }
    state = state.copyWith(selectedPathIds: newSelection);
  }

  /// Select a single path (deselect others)
  void selectPath(String pathId) {
    state = state.copyWith(selectedPathIds: {pathId});
  }

  /// Clear all selections
  void clearSelection() {
    state = state.copyWith(
      selectedPathIds: {},
      selectedLabelIds: {},
    );
  }

  /// Toggle layer visibility
  void toggleLayer(String layer) {
    final visibility = state.layerVisibility;
    LayerVisibility newVisibility;
    switch (layer) {
      case 'cutline':
        newVisibility = visibility.copyWith(cutline: !visibility.cutline);
        break;
      case 'markings':
        newVisibility = visibility.copyWith(markings: !visibility.markings);
        break;
      case 'labels':
        newVisibility = visibility.copyWith(labels: !visibility.labels);
        break;
      case 'grid':
        newVisibility = visibility.copyWith(grid: !visibility.grid);
        break;
      default:
        return;
    }
    state = state.copyWith(layerVisibility: newVisibility);
  }

  /// Execute a command and add to undo stack
  void executeCommand(EditorCommand command) {
    if (state.result == null) return;

    final newResult = command.execute(state.result!);
    final newUndoStack = [...state.undoStack, command];

    // Trim undo stack if too large
    if (newUndoStack.length > EditorState.maxUndoStackSize) {
      newUndoStack.removeAt(0);
    }

    state = state.copyWith(
      result: newResult,
      undoStack: newUndoStack,
      redoStack: [], // Clear redo on new action
      hasUnsavedChanges: true,
      changesSinceLastSave: state.changesSinceLastSave + 1,
    );
  }

  /// Undo the last command
  void undo() {
    if (!state.canUndo || state.result == null) return;

    final command = state.undoStack.last;
    final newResult = command.undo(state.result!);
    final newUndoStack = state.undoStack.sublist(0, state.undoStack.length - 1);
    final newRedoStack = [...state.redoStack, command];

    state = state.copyWith(
      result: newResult,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      hasUnsavedChanges: true,
    );
  }

  /// Redo the last undone command
  void redo() {
    if (!state.canRedo || state.result == null) return;

    final command = state.redoStack.last;
    final newResult = command.execute(state.result!);
    final newRedoStack = state.redoStack.sublist(0, state.redoStack.length - 1);
    final newUndoStack = [...state.undoStack, command];

    state = state.copyWith(
      result: newResult,
      undoStack: newUndoStack,
      redoStack: newRedoStack,
      hasUnsavedChanges: true,
    );
  }

  /// Update zoom level
  void setZoom(double zoom) {
    state = state.copyWith(zoomLevel: zoom.clamp(0.25, 4.0));
  }

  /// Update pan offset
  void setPan(Offset offset) {
    state = state.copyWith(panOffset: offset);
  }

  /// Mark as saved
  void markSaved() {
    state = state.copyWith(
      hasUnsavedChanges: false,
      changesSinceLastSave: 0,
    );
  }

  /// Delete selected paths
  void deleteSelectedPaths() {
    if (!state.hasSelection || state.result == null) return;

    final pathIds = state.selectedPathIds.toList();

    // Collect paths for undo
    final deletedCutlines = state.result!.layers.cutline
        .where((p) => pathIds.contains(p.pathId))
        .toList();
    final deletedMarkings = state.result!.layers.markings
        .where((p) => pathIds.contains(p.pathId))
        .toList();

    final command = DeletePathsCommand(
      pathIds: pathIds,
      deletedCutlines: deletedCutlines,
      deletedMarkings: deletedMarkings,
    );

    executeCommand(command);
    clearSelection();
  }
}

/// Provider for editor state
final editorStateProvider =
    StateNotifierProvider<EditorStateNotifier, EditorState>((ref) {
  return EditorStateNotifier();
});
