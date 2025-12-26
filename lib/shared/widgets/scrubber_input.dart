import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/blueprint_colors.dart';

/// ScrubberInput - A gesture-based slider with tap-to-type fallback
///
/// This is a critical accessibility component that allows users to:
/// 1. Drag left/right to adjust values (scrubbing)
/// 2. Tap to enter a precise value via keyboard
///
/// Used throughout TraceCast for scale input, zoom controls, and other
/// numeric adjustments where precision matters.
class ScrubberInput extends StatefulWidget {
  const ScrubberInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.min,
    required this.max,
    this.step = 1.0,
    this.label,
    this.suffix,
    this.decimalPlaces = 0,
    this.semanticLabel,
    this.enabled = true,
  });

  /// Current value
  final double value;

  /// Callback when value changes
  final ValueChanged<double> onChanged;

  /// Minimum allowed value
  final double min;

  /// Maximum allowed value
  final double max;

  /// Step increment for scrubbing (default: 1.0)
  final double step;

  /// Optional label displayed above the value
  final String? label;

  /// Optional suffix displayed after the value (e.g., "mm", "%")
  final String? suffix;

  /// Number of decimal places to display (default: 0)
  final int decimalPlaces;

  /// Semantic label for accessibility
  final String? semanticLabel;

  /// Whether the input is enabled
  final bool enabled;

  @override
  State<ScrubberInput> createState() => _ScrubberInputState();
}

class _ScrubberInputState extends State<ScrubberInput>
    with SingleTickerProviderStateMixin {
  bool _isEditing = false;
  late TextEditingController _textController;
  late FocusNode _focusNode;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  double _dragStartValue = 0;
  double _dragStartX = 0;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: _formatValue(widget.value));
    _focusNode = FocusNode();
    _focusNode.addListener(_onFocusChange);

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(ScrubberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isEditing && oldWidget.value != widget.value) {
      _textController.text = _formatValue(widget.value);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatValue(double value) {
    return value.toStringAsFixed(widget.decimalPlaces);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus && _isEditing) {
      _submitValue();
    }
  }

  void _startEditing() {
    if (!widget.enabled) return;

    setState(() {
      _isEditing = true;
      _textController.text = _formatValue(widget.value);
      _textController.selection = TextSelection(
        baseOffset: 0,
        extentOffset: _textController.text.length,
      );
    });
    _focusNode.requestFocus();
    HapticFeedback.lightImpact();
  }

  void _submitValue() {
    final text = _textController.text.trim();
    final parsed = double.tryParse(text);

    if (parsed != null) {
      final clamped = parsed.clamp(widget.min, widget.max);
      widget.onChanged(clamped);
    }

    setState(() {
      _isEditing = false;
      _textController.text = _formatValue(widget.value);
    });
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (!widget.enabled) return;

    _dragStartValue = widget.value;
    _dragStartX = details.localPosition.dx;
    _pulseController.forward();
    HapticFeedback.selectionClick();
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (!widget.enabled) return;

    final dx = details.localPosition.dx - _dragStartX;
    // Sensitivity: 2 pixels per step
    final steps = (dx / 2).round();
    final newValue =
        (_dragStartValue + steps * widget.step).clamp(widget.min, widget.max);

    if (newValue != widget.value) {
      widget.onChanged(newValue);
      HapticFeedback.selectionClick();
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    _pulseController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.semanticLabel ??
          '${widget.label ?? "Value"}: ${_formatValue(widget.value)}${widget.suffix ?? ""}. Swipe left or right to adjust, or double tap to enter a value.',
      value: _formatValue(widget.value),
      increasedValue: _formatValue(
          (widget.value + widget.step).clamp(widget.min, widget.max)),
      decreasedValue: _formatValue(
          (widget.value - widget.step).clamp(widget.min, widget.max)),
      onIncrease: widget.enabled
          ? () => widget.onChanged(
              (widget.value + widget.step).clamp(widget.min, widget.max))
          : null,
      onDecrease: widget.enabled
          ? () => widget.onChanged(
              (widget.value - widget.step).clamp(widget.min, widget.max))
          : null,
      child: Opacity(
        opacity: widget.enabled ? 1.0 : 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  widget.label!,
                  style: const TextStyle(
                    color: BlueprintColors.secondaryForeground,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            GestureDetector(
              onTap: _startEditing,
              onHorizontalDragStart: _onHorizontalDragStart,
              onHorizontalDragUpdate: _onHorizontalDragUpdate,
              onHorizontalDragEnd: _onHorizontalDragEnd,
              child: AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  );
                },
                child: Container(
                  constraints: const BoxConstraints(minWidth: 100),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: BlueprintColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isEditing
                          ? BlueprintColors.accentAction
                          : BlueprintColors.primaryForeground
                              .withValues(alpha: 0.3),
                      width: _isEditing ? 2 : 1,
                    ),
                  ),
                  child: _isEditing ? _buildTextField() : _buildDisplay(),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.swipe,
                  size: 12,
                  color: BlueprintColors.tertiaryForeground,
                ),
                const SizedBox(width: 4),
                Text(
                  'Drag to adjust • Tap to type',
                  style: TextStyle(
                    color: BlueprintColors.tertiaryForeground,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisplay() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _formatValue(widget.value),
          style: const TextStyle(
            color: BlueprintColors.primaryForeground,
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
        if (widget.suffix != null) ...[
          const SizedBox(width: 4),
          Text(
            widget.suffix!,
            style: const TextStyle(
              color: BlueprintColors.secondaryForeground,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField() {
    return IntrinsicWidth(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BlueprintColors.primaryForeground,
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                isDense: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[\d.]')),
              ],
              onSubmitted: (_) => _submitValue(),
            ),
          ),
          if (widget.suffix != null)
            Text(
              widget.suffix!,
              style: const TextStyle(
                color: BlueprintColors.secondaryForeground,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
        ],
      ),
    );
  }
}
