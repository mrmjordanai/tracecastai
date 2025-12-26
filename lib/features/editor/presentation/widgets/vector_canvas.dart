import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';
import 'editor_vector_painter.dart';

/// Main vector canvas widget with pan/zoom and path selection
class VectorCanvas extends ConsumerStatefulWidget {
  /// The vectorization result to display
  final VectorizeResult result;

  /// Callback when a path is tapped
  final ValueChanged<String?>? onPathTapped;

  /// Whether to show confidence-based highlighting
  final bool showConfidenceHighlights;

  /// Background color of the canvas
  final Color backgroundColor;

  const VectorCanvas({
    super.key,
    required this.result,
    this.onPathTapped,
    this.showConfidenceHighlights = true,
    this.backgroundColor = Colors.black,
  });

  @override
  ConsumerState<VectorCanvas> createState() => _VectorCanvasState();
}

class _VectorCanvasState extends ConsumerState<VectorCanvas> {
  final TransformationController _transformController =
      TransformationController();
  EditorVectorPainter? _painter;
  double _currentScale = 1.0;

  @override
  void initState() {
    super.initState();
    _transformController.addListener(_onTransformChanged);
  }

  @override
  void dispose() {
    _transformController.removeListener(_onTransformChanged);
    _transformController.dispose();
    super.dispose();
  }

  void _onTransformChanged() {
    final scale = _transformController.value.getMaxScaleOnAxis();
    if (scale != _currentScale) {
      _currentScale = scale;
      ref.read(editorStateProvider.notifier).setZoom(scale);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editorState = ref.watch(editorStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate scale to fit the pattern in the view
        final viewWidth = constraints.maxWidth;
        final viewHeight = constraints.maxHeight;
        final patternWidth = widget.result.widthMm;
        final patternHeight = widget.result.heightMm;

        final scaleX = viewWidth / patternWidth;
        final scaleY = viewHeight / patternHeight;
        final baseScale = (scaleX < scaleY ? scaleX : scaleY) * 0.9;

        // Center offset
        final offsetX = (viewWidth - patternWidth * baseScale) / 2;
        final offsetY = (viewHeight - patternHeight * baseScale) / 2;

        _painter = EditorVectorPainter(
          result: editorState.result ?? widget.result,
          displayScale: baseScale * _currentScale,
          offset: Offset(offsetX, offsetY),
          selectedPathIds: editorState.selectedPathIds,
          layerVisibility: editorState.layerVisibility,
          showConfidenceHighlights: widget.showConfidenceHighlights,
        );

        return GestureDetector(
          onTapUp: (details) =>
              _handleTap(details, baseScale, Offset(offsetX, offsetY)),
          child: InteractiveViewer(
            transformationController: _transformController,
            constrained: false,
            boundaryMargin: const EdgeInsets.all(100),
            minScale: 0.25,
            maxScale: 4.0,
            child: Container(
              width: viewWidth,
              height: viewHeight,
              color: widget.backgroundColor,
              child: CustomPaint(
                painter: _painter,
                size: Size(viewWidth, viewHeight),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTap(TapUpDetails details, double baseScale, Offset baseOffset) {
    if (_painter == null) return;

    // Transform tap position to canvas coordinates
    final matrix = _transformController.value.clone();
    matrix.invert();
    final transformedPoint =
        MatrixUtils.transformPoint(matrix, details.localPosition);

    // Adjust for view offset
    final canvasPoint = transformedPoint;

    // Hit test paths
    final hitPathId =
        _painter!.hitTestPath(canvasPoint, tolerance: 15.0 / _currentScale);

    if (hitPathId != null) {
      // Haptic feedback on selection
      HapticFeedback.selectionClick();

      final notifier = ref.read(editorStateProvider.notifier);
      notifier.togglePathSelection(hitPathId);
    } else {
      // Tapped empty space - clear selection
      ref.read(editorStateProvider.notifier).clearSelection();
    }

    widget.onPathTapped?.call(hitPathId);
  }

  /// Reset the view to fit the pattern
  void resetView() {
    _transformController.value = Matrix4.identity();
    _currentScale = 1.0;
  }
}

/// Layer toggle buttons widget
class LayerToggles extends ConsumerWidget {
  const LayerToggles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibility =
        ref.watch(editorStateProvider.select((s) => s.layerVisibility));
    final notifier = ref.read(editorStateProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _LayerToggle(
            icon: Icons.crop_square,
            label: 'Cutline',
            isActive: visibility.cutline,
            onTap: () => notifier.toggleLayer('cutline'),
          ),
          const SizedBox(width: 8),
          _LayerToggle(
            icon: Icons.edit,
            label: 'Markings',
            isActive: visibility.markings,
            onTap: () => notifier.toggleLayer('markings'),
          ),
          const SizedBox(width: 8),
          _LayerToggle(
            icon: Icons.text_fields,
            label: 'Labels',
            isActive: visibility.labels,
            onTap: () => notifier.toggleLayer('labels'),
          ),
          const SizedBox(width: 8),
          _LayerToggle(
            icon: Icons.grid_on,
            label: 'Grid',
            isActive: visibility.grid,
            onTap: () => notifier.toggleLayer('grid'),
          ),
        ],
      ),
    );
  }
}

class _LayerToggle extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _LayerToggle({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$label layer ${isActive ? 'visible' : 'hidden'}',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.4),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 9,
                  color: isActive
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
