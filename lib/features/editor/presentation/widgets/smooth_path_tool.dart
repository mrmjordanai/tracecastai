import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// Smooth path tool using Catmull-Rom to Bezier conversion
class SmoothPathTool extends ConsumerWidget {
  /// Smoothing factor (0.0 = no smoothing, 1.0 = maximum smoothing)
  final double smoothingFactor;

  const SmoothPathTool({
    super.key,
    this.smoothingFactor = 0.5,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editorState = ref.watch(editorStateProvider);
    final selectedPaths = editorState.selectedPathIds;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_fix_high,
            color: BlueprintColors.accentAction,
            size: 48,
          ),
          const SizedBox(height: 16),
          Text(
            selectedPaths.isEmpty
                ? 'Select a path to smooth'
                : 'Smooth ${selectedPaths.length} path${selectedPaths.length > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Smoothing reduces sharp corners and makes curves more natural.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: selectedPaths.isEmpty
                ? null
                : () => _smoothSelectedPaths(context, ref),
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('APPLY SMOOTHING'),
            style: ElevatedButton.styleFrom(
              backgroundColor: BlueprintColors.accentAction,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _smoothSelectedPaths(BuildContext context, WidgetRef ref) {
    final editorState = ref.read(editorStateProvider);
    final result = editorState.result;
    if (result == null) return;

    HapticFeedback.mediumImpact();

    // Smooth each selected path
    for (final pathId in editorState.selectedPathIds) {
      // Find the path
      VectorPath? targetPath;
      for (final p in result.layers.cutline) {
        if (p.pathId == pathId) {
          targetPath = p;
          break;
        }
      }
      targetPath ??= result.layers.markings.firstWhere(
        (p) => p.pathId == pathId,
        orElse: () => throw StateError('Path not found'),
      );

      if (targetPath.points.length < 3) continue;

      // Apply smoothing
      final smoothedPoints = _smoothPoints(targetPath.points, smoothingFactor);

      // Create command
      final command = ModifyPathCommand(
        pathId: pathId,
        newPoints: smoothedPoints,
        originalPoints: targetPath.points,
      );

      ref.read(editorStateProvider.notifier).executeCommand(command);
    }
  }

  /// Smooth points using Catmull-Rom spline interpolation
  List<VectorPoint> _smoothPoints(List<VectorPoint> points, double tension) {
    if (points.length < 3) return points;

    final smoothed = <VectorPoint>[];
    smoothed.add(points.first); // Keep first point

    // Number of interpolation points between each original point
    const segments = 3;

    for (int i = 0; i < points.length - 1; i++) {
      final p0 = i > 0 ? points[i - 1] : points[i];
      final p1 = points[i];
      final p2 = points[i + 1];
      final p3 = i < points.length - 2 ? points[i + 2] : points[i + 1];

      for (int j = 1; j <= segments; j++) {
        final t = j / segments.toDouble();
        final point = _catmullRom(p0, p1, p2, p3, t, tension);
        smoothed.add(point);
      }
    }

    smoothed.add(points.last); // Keep last point
    return smoothed;
  }

  /// Catmull-Rom spline interpolation
  VectorPoint _catmullRom(
    VectorPoint p0,
    VectorPoint p1,
    VectorPoint p2,
    VectorPoint p3,
    double t,
    double tension,
  ) {
    final t2 = t * t;
    final t3 = t2 * t;

    final alpha = 1.0 - tension;

    final x = alpha *
        ((2 * p1.xMm) +
            (-p0.xMm + p2.xMm) * t +
            (2 * p0.xMm - 5 * p1.xMm + 4 * p2.xMm - p3.xMm) * t2 +
            (-p0.xMm + 3 * p1.xMm - 3 * p2.xMm + p3.xMm) * t3) /
        2;

    final y = alpha *
        ((2 * p1.yMm) +
            (-p0.yMm + p2.yMm) * t +
            (2 * p0.yMm - 5 * p1.yMm + 4 * p2.yMm - p3.yMm) * t2 +
            (-p0.yMm + 3 * p1.yMm - 3 * p2.yMm + p3.yMm) * t3) /
        2;

    return VectorPoint(xMm: x, yMm: y);
  }
}

/// Quick smooth button for the toolbar
class SmoothPathButton extends ConsumerWidget {
  const SmoothPathButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasSelection = ref.watch(editorStateProvider.select(
      (s) => s.selectedPathIds.isNotEmpty,
    ));

    return Semantics(
      label: 'Smooth selected paths',
      button: true,
      enabled: hasSelection,
      child: Tooltip(
        message: hasSelection ? 'Smooth path' : 'Select a path first',
        child: InkWell(
          onTap: hasSelection ? () => _showSmoothDialog(context) : null,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: hasSelection
                  ? BlueprintColors.accentAction.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.auto_fix_high,
              color:
                  hasSelection ? BlueprintColors.accentAction : Colors.white38,
            ),
          ),
        ),
      ),
    );
  }

  void _showSmoothDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: const SmoothPathTool(),
      ),
    );
  }
}
