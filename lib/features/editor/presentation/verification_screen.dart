import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/models/vectorize_result.dart';
import '../../../core/providers/editor_state_provider.dart';
import 'widgets/confidence_badge.dart';
import 'widgets/editor_vector_painter.dart';

/// Verification screen showing AI extraction results with confidence indicators (Screen 22)
class VerificationScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String pieceId;
  final VectorizeResult result;
  final String? imagePath;

  const VerificationScreen({
    super.key,
    required this.projectId,
    required this.pieceId,
    required this.result,
    this.imagePath,
  });

  @override
  ConsumerState<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends ConsumerState<VerificationScreen> {
  double _overlayOpacity = 0.5;
  bool _showVectors = true;

  @override
  void initState() {
    super.initState();
    // Pre-initialize editor state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(editorStateProvider.notifier).initialize(widget.result);
    });
  }

  int get _highConfidenceCount {
    int count = 0;
    for (final p in widget.result.layers.cutline) {
      if (p.confidence >= 0.8) count++;
    }
    for (final p in widget.result.layers.markings) {
      if (p.confidence >= 0.8) count++;
    }
    for (final l in widget.result.layers.labels) {
      if (l.confidence >= 0.8) count++;
    }
    return count;
  }

  int get _mediumConfidenceCount {
    int count = 0;
    for (final p in widget.result.layers.cutline) {
      if (p.confidence >= 0.5 && p.confidence < 0.8) count++;
    }
    for (final p in widget.result.layers.markings) {
      if (p.confidence >= 0.5 && p.confidence < 0.8) count++;
    }
    for (final l in widget.result.layers.labels) {
      if (l.confidence >= 0.5 && l.confidence < 0.8) count++;
    }
    return count;
  }

  int get _lowConfidenceCount {
    int count = 0;
    for (final p in widget.result.layers.cutline) {
      if (p.confidence < 0.5) count++;
    }
    for (final p in widget.result.layers.markings) {
      if (p.confidence < 0.5) count++;
    }
    for (final l in widget.result.layers.labels) {
      if (l.confidence < 0.5) count++;
    }
    return count;
  }

  bool get _needsReview =>
      _lowConfidenceCount > 0 || _mediumConfidenceCount > 2;

  void _navigateToEditor() {
    HapticFeedback.mediumImpact();
    context.push('/verify/editor', extra: {
      'projectId': widget.projectId,
      'pieceId': widget.pieceId,
      'result': widget.result,
      'imagePath': widget.imagePath,
    });
  }

  void _navigateToTestSquare() {
    HapticFeedback.mediumImpact();
    context.push('/verify/test-square', extra: {
      'projectId': widget.projectId,
      'pieceId': widget.pieceId,
      'result': widget.result,
    });
  }

  void _proceedToProject() {
    HapticFeedback.mediumImpact();
    context.go('/projector/${widget.projectId}', extra: {
      'result': widget.result,
      'pieceId': widget.pieceId,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      appBar: AppBar(
        backgroundColor: BlueprintColors.surfaceOverlay,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: const Text('Verify Extraction'),
        actions: [
          IconButton(
            icon: Icon(_showVectors ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                _showVectors = !_showVectors;
              });
            },
            tooltip: _showVectors ? 'Hide vectors' : 'Show vectors',
          ),
        ],
      ),
      body: Column(
        children: [
          // Preview area
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background image
                if (widget.imagePath != null)
                  Image.file(
                    File(widget.imagePath!),
                    fit: BoxFit.contain,
                  ),

                // Vector overlay
                if (_showVectors)
                  Opacity(
                    opacity: _overlayOpacity,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final scaleX =
                            constraints.maxWidth / widget.result.widthMm;
                        final scaleY =
                            constraints.maxHeight / widget.result.heightMm;
                        final scale = (scaleX < scaleY ? scaleX : scaleY) * 0.9;
                        final offsetX = (constraints.maxWidth -
                                widget.result.widthMm * scale) /
                            2;
                        final offsetY = (constraints.maxHeight -
                                widget.result.heightMm * scale) /
                            2;

                        return CustomPaint(
                          painter: EditorVectorPainter(
                            result: widget.result,
                            displayScale: scale,
                            offset: Offset(offsetX, offsetY),
                            showConfidenceHighlights: true,
                          ),
                          size:
                              Size(constraints.maxWidth, constraints.maxHeight),
                        );
                      },
                    ),
                  ),

                // Opacity slider
                Positioned(
                  right: 16,
                  top: 16,
                  bottom: 16,
                  child: Column(
                    children: [
                      const Icon(Icons.opacity,
                          color: Colors.white70, size: 20),
                      Expanded(
                        child: RotatedBox(
                          quarterTurns: 3,
                          child: Slider(
                            value: _overlayOpacity,
                            onChanged: (v) =>
                                setState(() => _overlayOpacity = v),
                            activeColor: BlueprintColors.accentAction,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Quality summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BlueprintColors.surfaceOverlay,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Quality badges
                  QualitySummary(
                    overallConfidence: widget.result.qa.confidence,
                    highConfidenceCount: _highConfidenceCount,
                    mediumConfidenceCount: _mediumConfidenceCount,
                    lowConfidenceCount: _lowConfidenceCount,
                  ),

                  const SizedBox(height: 16),

                  // Review message
                  if (_needsReview)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            BlueprintColors.accentAction.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: BlueprintColors.accentAction
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.warning_amber_rounded,
                            color: BlueprintColors.accentAction,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Some areas may need manual adjustment. Tap "Edit" to fix.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 16),

                  // Action buttons
                  Row(
                    children: [
                      // Edit button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToEditor,
                          icon: const Icon(Icons.edit),
                          label: const Text('EDIT'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Test square button
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _navigateToTestSquare,
                          icon: const Icon(Icons.straighten),
                          label: const Text('TEST'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Project button
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: _proceedToProject,
                          icon: const Icon(Icons.cast),
                          label: const Text('PROJECT →'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: BlueprintColors.successState,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
