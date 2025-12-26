import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/vectorization_provider.dart';
import 'widgets/vector_painter.dart';

/// Projector display screen - renders vectors on pure black background
class ProjectorScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectorScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<ProjectorScreen> createState() => _ProjectorScreenState();
}

class _ProjectorScreenState extends ConsumerState<ProjectorScreen> {
  final TransformationController _transformController =
      TransformationController();
  bool _showControls = true;

  @override
  void initState() {
    super.initState();
    // Hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    final vectorState = ref.watch(vectorizationProvider);
    final result = vectorState.result;

    return Scaffold(
      // Pure black background for projector
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _toggleControls,
        child: Stack(
          children: [
            // Vector display with pan/zoom
            if (result != null)
              InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.1,
                maxScale: 10.0,
                constrained: false,
                child: SizedBox(
                  width: result.widthMm * 3, // Scale factor for display
                  height: result.heightMm * 3,
                  child: CustomPaint(
                    painter: VectorPainter(
                      result: result,
                      displayScale: 3.0, // mm to pixels
                    ),
                    size: Size(result.widthMm * 3, result.heightMm * 3),
                  ),
                ),
              )
            else
              const Center(
                child: Text(
                  'No pattern loaded',
                  style: TextStyle(color: Colors.white54),
                ),
              ),

            // Controls overlay (fades in/out)
            AnimatedOpacity(
              opacity: _showControls ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 200),
              child: IgnorePointer(
                ignoring: !_showControls,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.15, 0.85, 1.0],
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top bar
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.close,
                                    color: Colors.white),
                                onPressed: () => context.pop(),
                              ),
                              if (result != null)
                                Text(
                                  '${result.widthMm.toStringAsFixed(0)} × ${result.heightMm.toStringAsFixed(0)} mm',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              IconButton(
                                icon: const Icon(Icons.fit_screen,
                                    color: Colors.white),
                                onPressed: _resetZoom,
                              ),
                            ],
                          ),
                        ),

                        // Bottom bar with controls
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _ControlButton(
                                icon: Icons.zoom_in,
                                label: 'Zoom In',
                                onTap: () {
                                  final scaleMatrix = Matrix4.diagonal3Values(1.2, 1.2, 1.0);
                                  _transformController.value = _transformController.value.multiplied(scaleMatrix);
                                },
                              ),
                              const SizedBox(width: 24),
                              _ControlButton(
                                icon: Icons.zoom_out,
                                label: 'Zoom Out',
                                onTap: () {
                                  final scaleMatrix = Matrix4.diagonal3Values(0.8, 0.8, 1.0);
                                  _transformController.value = _transformController.value.multiplied(scaleMatrix);
                                },
                              ),
                              const SizedBox(width: 24),
                              _ControlButton(
                                icon: Icons.cast,
                                label: 'Cast',
                                onTap: () {
                                  // TODO: Implement casting
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Casting will be available in Phase 2'),
                                      backgroundColor:
                                          BlueprintColors.surfaceOverlay,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ControlButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(height: 8),
            ExcludeSemantics(
              child: Text(
                label,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
