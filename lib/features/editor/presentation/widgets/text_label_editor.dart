import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/models/vectorize_result.dart';
import '../../../../core/providers/editor_state_provider.dart';

/// Tool for editing OCR text labels
class TextLabelEditor extends ConsumerStatefulWidget {
  /// The vectorization result
  final VectorizeResult result;

  /// Display scale (mm to pixels)
  final double displayScale;

  /// Pan offset
  final Offset offset;

  /// Callback when a label is edited
  final ValueChanged<TextBox>? onLabelEdited;

  const TextLabelEditor({
    super.key,
    required this.result,
    required this.displayScale,
    required this.offset,
    this.onLabelEdited,
  });

  @override
  ConsumerState<TextLabelEditor> createState() => _TextLabelEditorState();
}

class _TextLabelEditorState extends ConsumerState<TextLabelEditor> {
  String? _selectedLabelId;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapUp: _onTapUp,
      child: CustomPaint(
        painter: _LabelHighlightPainter(
          labels: widget.result.layers.labels,
          selectedLabelId: _selectedLabelId,
          displayScale: widget.displayScale,
          offset: widget.offset,
        ),
        size: Size.infinite,
      ),
    );
  }

  void _onTapUp(TapUpDetails details) {
    final tappedLabel = _findLabelAtPosition(details.localPosition);

    if (tappedLabel != null) {
      HapticFeedback.selectionClick();
      setState(() {
        _selectedLabelId = tappedLabel.labelId;
      });
      _showEditDialog(tappedLabel);
    } else {
      setState(() {
        _selectedLabelId = null;
      });
    }
  }

  TextBox? _findLabelAtPosition(Offset screenPos) {
    const tolerance = 30.0;

    for (final label in widget.result.layers.labels) {
      final labelScreen = Offset(
        label.position.xMm * widget.displayScale + widget.offset.dx,
        label.position.yMm * widget.displayScale + widget.offset.dy,
      );

      final labelWidth = label.size.widthMm * widget.displayScale;
      final labelHeight = label.size.heightMm * widget.displayScale;

      final labelRect = Rect.fromLTWH(
        labelScreen.dx - tolerance,
        labelScreen.dy - tolerance,
        labelWidth + tolerance * 2,
        labelHeight + tolerance * 2,
      );

      if (labelRect.contains(screenPos)) {
        return label;
      }
    }

    return null;
  }

  void _showEditDialog(TextBox label) {
    final controller = TextEditingController(text: label.text);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: BlueprintColors.surfaceOverlay,
        title: const Text(
          'Edit Label',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current text:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: controller,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                hintText: 'Enter label text',
                hintStyle: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                ),
              ),
              onSubmitted: (value) {
                if (value.trim().isNotEmpty) {
                  _updateLabel(label, value.trim());
                }
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ConfidenceBadgeInline(confidence: label.confidence),
                const SizedBox(width: 8),
                Text(
                  'AI confidence',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _selectedLabelId = null;
              });
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                _updateLabel(label, controller.text.trim());
              }
              Navigator.pop(context);
              setState(() {
                _selectedLabelId = null;
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _updateLabel(TextBox label, String newText) {
    if (newText == label.text) return;

    HapticFeedback.mediumImpact();

    final command = UpdateLabelCommand(
      labelId: label.labelId,
      newText: newText,
      originalText: label.text,
    );

    ref.read(editorStateProvider.notifier).executeCommand(command);

    widget.onLabelEdited?.call(TextBox(
      labelId: label.labelId,
      text: newText,
      position: label.position,
      size: label.size,
      confidence: 1.0, // User-edited = 100% confidence
    ));
  }
}

class _LabelHighlightPainter extends CustomPainter {
  final List<TextBox> labels;
  final String? selectedLabelId;
  final double displayScale;
  final Offset offset;

  _LabelHighlightPainter({
    required this.labels,
    this.selectedLabelId,
    required this.displayScale,
    required this.offset,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final label in labels) {
      final position = Offset(
        label.position.xMm * displayScale + offset.dx,
        label.position.yMm * displayScale + offset.dy,
      );

      final isSelected = label.labelId == selectedLabelId;
      final labelWidth = label.size.widthMm * displayScale;
      final labelHeight = label.size.heightMm * displayScale;

      // Draw highlight box
      final boxPaint = Paint()
        ..color = isSelected
            ? BlueprintColors.accentAction.withValues(alpha: 0.3)
            : BlueprintColors.primaryBackground.withValues(alpha: 0.2)
        ..style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(
          position.dx - 4,
          position.dy - 4,
          labelWidth.clamp(40.0, 200.0) + 8,
          labelHeight.clamp(16.0, 40.0) + 8,
        ),
        const Radius.circular(4),
      );
      canvas.drawRRect(rect, boxPaint);

      // Draw border
      final borderPaint = Paint()
        ..color = isSelected
            ? BlueprintColors.accentAction
            : BlueprintColors.primaryBackground.withValues(alpha: 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2 : 1;
      canvas.drawRRect(rect, borderPaint);

      // Draw edit icon for selected label
      if (isSelected) {
        final iconPaint = Paint()..color = BlueprintColors.accentAction;
        canvas.drawCircle(
          Offset(rect.right - 8, rect.top + 8),
          8,
          iconPaint,
        );

        // Draw pencil icon (simplified)
        final pencilPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;
        canvas.drawLine(
          Offset(rect.right - 11, rect.top + 5),
          Offset(rect.right - 5, rect.top + 11),
          pencilPaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LabelHighlightPainter oldDelegate) {
    return selectedLabelId != oldDelegate.selectedLabelId ||
        labels != oldDelegate.labels;
  }
}

/// Inline confidence badge for the edit dialog
class ConfidenceBadgeInline extends StatelessWidget {
  final double confidence;

  const ConfidenceBadgeInline({
    super.key,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    if (confidence >= 0.8) {
      color = BlueprintColors.successState;
      icon = Icons.check_circle;
    } else if (confidence >= 0.5) {
      color = BlueprintColors.accentAction;
      icon = Icons.warning_amber_rounded;
    } else {
      color = BlueprintColors.errorState;
      icon = Icons.cancel;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(
          '${(confidence * 100).round()}%',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
