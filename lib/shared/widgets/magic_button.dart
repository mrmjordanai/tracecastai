import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../app/theme/blueprint_colors.dart';

/// MagicButton - The signature floating action button for TraceCast
///
/// A white FAB with radial expand animation that serves as the primary
/// action trigger. Used in the bottom navigation for the Scan tab and
/// can be reused for other primary actions throughout the app.
///
/// Features:
/// - Radial expand animation on press
/// - Haptic feedback
/// - Accessibility support
/// - Loading and disabled states
class MagicButton extends StatefulWidget {
  const MagicButton({
    super.key,
    required this.onPressed,
    this.icon = Icons.add,
    this.size = 64,
    this.isLoading = false,
    this.enabled = true,
    this.semanticLabel = 'Magic button',
    this.heroTag,
  });

  /// Callback when button is pressed
  final VoidCallback? onPressed;

  /// Icon to display (default: add icon)
  final IconData icon;

  /// Size of the button (default: 64)
  final double size;

  /// Whether the button is in loading state
  final bool isLoading;

  /// Whether the button is enabled
  final bool enabled;

  /// Semantic label for accessibility
  final String semanticLabel;

  /// Hero tag for hero animations (optional)
  final Object? heroTag;

  @override
  State<MagicButton> createState() => _MagicButtonState();
}

class _MagicButtonState extends State<MagicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.enabled || widget.isLoading) return;
    _controller.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.enabled || widget.isLoading) return;
    _controller.reverse();
  }

  void _onTapCancel() {
    _controller.reverse();
  }

  void _onTap() {
    if (!widget.enabled || widget.isLoading) return;
    HapticFeedback.mediumImpact();
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final button = Semantics(
      button: true,
      enabled: widget.enabled && !widget.isLoading,
      label: widget.semanticLabel,
      child: GestureDetector(
        onTapDown: _onTapDown,
        onTapUp: _onTapUp,
        onTapCancel: _onTapCancel,
        onTap: _onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: widget.size,
                height: widget.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.enabled
                      ? BlueprintColors.primaryForeground
                      : BlueprintColors.primaryForeground
                          .withValues(alpha: 0.5),
                  boxShadow: [
                    // Base shadow
                    BoxShadow(
                      color: BlueprintColors.shadowColor,
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                    // Glow effect on press
                    BoxShadow(
                      color: BlueprintColors.accentAction
                          .withValues(alpha: 0.4 * _glowAnimation.value),
                      blurRadius: 20 * _glowAnimation.value,
                      spreadRadius: 4 * _glowAnimation.value,
                    ),
                  ],
                ),
                child: Center(
                  child: widget.isLoading
                      ? SizedBox(
                          width: widget.size * 0.4,
                          height: widget.size * 0.4,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              BlueprintColors.primaryBackground,
                            ),
                          ),
                        )
                      : Icon(
                          widget.icon,
                          size: widget.size * 0.5,
                          color: BlueprintColors.primaryBackground,
                        ),
                ),
              ),
            );
          },
        ),
      ),
    );

    if (widget.heroTag != null) {
      return Hero(
        tag: widget.heroTag!,
        child: button,
      );
    }

    return button;
  }
}

/// A variant of MagicButton specifically designed for the Scan tab
/// in the bottom navigation. It's slightly elevated above other tabs.
class ScanTabButton extends StatelessWidget {
  const ScanTabButton({
    super.key,
    required this.onPressed,
    this.isSelected = false,
  });

  final VoidCallback? onPressed;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: const Offset(0, -12),
      child: MagicButton(
        onPressed: onPressed,
        icon: Icons.center_focus_strong,
        size: 56,
        semanticLabel: 'Start scanning',
        heroTag: 'scan_button',
      ),
    );
  }
}
