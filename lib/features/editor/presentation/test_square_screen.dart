import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/models/vectorize_result.dart';
import '../../../shared/widgets/scrubber_input.dart';

/// Test square screen for physical scale verification (Screen 21c/21d)
class TestSquareScreen extends ConsumerStatefulWidget {
  final String projectId;
  final String pieceId;
  final VectorizeResult result;

  const TestSquareScreen({
    super.key,
    required this.projectId,
    required this.pieceId,
    required this.result,
  });

  @override
  ConsumerState<TestSquareScreen> createState() => _TestSquareScreenState();
}

class _TestSquareScreenState extends ConsumerState<TestSquareScreen> {
  double _scaleFactor = 1.0;
  bool _useMetric = true;
  bool _showTestSquare = true;

  // 100mm for metric, 4 inches (101.6mm) for imperial
  double get _testSquareSizeMm => _useMetric ? 100.0 : 101.6;
  String get _testSquareLabel => _useMetric ? '100mm' : '4"';

  void _handlePass() {
    HapticFeedback.mediumImpact();

    // Scale is correct, proceed
    context.pop({'scaleFactor': _scaleFactor, 'verified': true});
  }

  void _handleFail() {
    HapticFeedback.lightImpact();

    // Show scale adjustment
    showModalBottomSheet(
      context: context,
      backgroundColor: BlueprintColors.surfaceOverlay,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _ScaleAdjustmentSheet(
        initialScale: _scaleFactor,
        onScaleChanged: (scale) {
          setState(() {
            _scaleFactor = scale;
          });
        },
        onDone: () {
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final adjustedResult = _applyScale(widget.result, _scaleFactor);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Verify Scale',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          // Toggle metric/imperial
          TextButton(
            onPressed: () {
              setState(() {
                _useMetric = !_useMetric;
              });
            },
            child: Text(
              _useMetric ? 'mm' : 'in',
              style: const TextStyle(
                color: BlueprintColors.accentAction,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Instructions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BlueprintColors.surfaceOverlay,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.straighten,
                    color: BlueprintColors.accentAction,
                    size: 32,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Measure the test square',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Project this onto your surface and measure with a ruler. It should be exactly $_testSquareLabel.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Test square display
          Expanded(
            child: Center(
              child: _showTestSquare
                  ? _TestSquareDisplay(
                      sizeMm: _testSquareSizeMm * _scaleFactor,
                      label: _testSquareLabel,
                    )
                  : CustomPaint(
                      painter: _MiniPreviewPainter(result: adjustedResult),
                      size: const Size(200, 200),
                    ),
            ),
          ),

          // Toggle button
          TextButton.icon(
            onPressed: () {
              setState(() {
                _showTestSquare = !_showTestSquare;
              });
            },
            icon: Icon(
              _showTestSquare ? Icons.preview : Icons.crop_square,
              size: 20,
            ),
            label:
                Text(_showTestSquare ? 'Preview pattern' : 'Show test square'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white70,
            ),
          ),

          const SizedBox(height: 16),

          // Scale indicator
          if (_scaleFactor != 1.0)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: BlueprintColors.accentAction.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.tune,
                    color: BlueprintColors.accentAction,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Scale adjusted: ${(_scaleFactor * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      color: BlueprintColors.accentAction,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          // Pass/Fail buttons
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Fail button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _handleFail,
                      icon: const Icon(Icons.close),
                      label: const Text('TOO BIG/SMALL'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: BlueprintColors.errorState,
                        side:
                            const BorderSide(color: BlueprintColors.errorState),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Pass button
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: _handlePass,
                      icon: const Icon(Icons.check),
                      label: const Text('LOOKS CORRECT'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BlueprintColors.successState,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  VectorizeResult _applyScale(VectorizeResult result, double scale) {
    if (scale == 1.0) return result;

    return VectorizeResult(
      pieceId: result.pieceId,
      sourceImageId: result.sourceImageId,
      scaleMmPerPx: result.scaleMmPerPx * scale,
      widthMm: result.widthMm * scale,
      heightMm: result.heightMm * scale,
      layers: result.layers, // Points are in mm, they scale with display
      qa: result.qa,
    );
  }
}

class _TestSquareDisplay extends StatelessWidget {
  final double sizeMm;
  final String label;

  const _TestSquareDisplay({
    required this.sizeMm,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    // Display at reasonable screen size (not actual mm)
    const displaySize = 200.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: displaySize,
          height: displaySize,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Actual size: ${sizeMm.toStringAsFixed(1)}mm',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.6),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _MiniPreviewPainter extends CustomPainter {
  final VectorizeResult result;

  _MiniPreviewPainter({required this.result});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / result.widthMm;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (final path in result.layers.cutline) {
      if (path.points.isEmpty) continue;

      final flutterPath = Path();
      flutterPath.moveTo(
        path.points.first.xMm * scale,
        path.points.first.yMm * scale,
      );

      for (int i = 1; i < path.points.length; i++) {
        flutterPath.lineTo(
          path.points[i].xMm * scale,
          path.points[i].yMm * scale,
        );
      }

      if (path.closed) flutterPath.close();
      canvas.drawPath(flutterPath, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ScaleAdjustmentSheet extends StatefulWidget {
  final double initialScale;
  final ValueChanged<double> onScaleChanged;
  final VoidCallback onDone;

  const _ScaleAdjustmentSheet({
    required this.initialScale,
    required this.onScaleChanged,
    required this.onDone,
  });

  @override
  State<_ScaleAdjustmentSheet> createState() => _ScaleAdjustmentSheetState();
}

class _ScaleAdjustmentSheetState extends State<_ScaleAdjustmentSheet> {
  late double _scale;

  @override
  void initState() {
    super.initState();
    _scale = widget.initialScale;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Adjust Scale',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'If the test square is too big, decrease the scale. If too small, increase it.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Scale display
          Center(
            child: Text(
              '${(_scale * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 48,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Scrubber
          ScrubberInput(
            value: _scale * 100,
            min: 80,
            max: 120,
            step: 0.5,
            suffix: '%',
            label: 'Scale',
            onChanged: (value) {
              setState(() {
                _scale = value / 100;
              });
              widget.onScaleChanged(_scale);
            },
          ),

          const SizedBox(height: 24),

          // Quick adjust buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _QuickAdjustButton(
                label: '-5%',
                onTap: () {
                  setState(() {
                    _scale = (_scale - 0.05).clamp(0.8, 1.2);
                  });
                  widget.onScaleChanged(_scale);
                },
              ),
              const SizedBox(width: 12),
              _QuickAdjustButton(
                label: '-1%',
                onTap: () {
                  setState(() {
                    _scale = (_scale - 0.01).clamp(0.8, 1.2);
                  });
                  widget.onScaleChanged(_scale);
                },
              ),
              const SizedBox(width: 12),
              _QuickAdjustButton(
                label: 'Reset',
                onTap: () {
                  setState(() {
                    _scale = 1.0;
                  });
                  widget.onScaleChanged(_scale);
                },
                isAccent: true,
              ),
              const SizedBox(width: 12),
              _QuickAdjustButton(
                label: '+1%',
                onTap: () {
                  setState(() {
                    _scale = (_scale + 0.01).clamp(0.8, 1.2);
                  });
                  widget.onScaleChanged(_scale);
                },
              ),
              const SizedBox(width: 12),
              _QuickAdjustButton(
                label: '+5%',
                onTap: () {
                  setState(() {
                    _scale = (_scale + 0.05).clamp(0.8, 1.2);
                  });
                  widget.onScaleChanged(_scale);
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Done button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: widget.onDone,
              style: ElevatedButton.styleFrom(
                backgroundColor: BlueprintColors.accentAction,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('APPLY & RETEST'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool isAccent;

  const _QuickAdjustButton({
    required this.label,
    required this.onTap,
    this.isAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isAccent
          ? BlueprintColors.accentAction.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Text(
            label,
            style: TextStyle(
              color: isAccent ? BlueprintColors.accentAction : Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
