import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';

import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/services/reference_detection_service.dart';
import 'reticle_painter.dart';

/// Technical Reticle Overlay for camera capture
///
/// Provides visual framing guides during pattern capture:
/// - Corner brackets (viewfinder style)
/// - Center crosshair (alignment aid)
/// - Level indicator (device orientation)
/// - Animated response to reference detection
class ReticleOverlay extends StatefulWidget {
  /// Whether a reference object has been detected
  final bool isReferenceDetected;

  /// Detection result with confidence
  final ReferenceDetectionResult? detectionResult;

  /// Callback when reference detection state changes
  final ValueChanged<bool>? onReferenceDetectionChanged;

  const ReticleOverlay({
    super.key,
    this.isReferenceDetected = false,
    this.detectionResult,
    this.onReferenceDetectionChanged,
  });

  @override
  State<ReticleOverlay> createState() => _ReticleOverlayState();
}

class _ReticleOverlayState extends State<ReticleOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late Animation<Color?> _colorAnimation;

  double _deviceTilt = 0.0;
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;

  @override
  void initState() {
    super.initState();

    // Pulse animation for detection feedback
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _colorAnimation = ColorTween(
      begin: BlueprintColors.primaryForeground,
      end: BlueprintColors.successState,
    ).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Start listening to accelerometer for level indicator
    _startAccelerometerListener();

    // Handle initial detection state
    if (widget.isReferenceDetected) {
      _onReferenceDetected();
    }
  }

  @override
  void didUpdateWidget(ReticleOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isReferenceDetected && !oldWidget.isReferenceDetected) {
      _onReferenceDetected();
    } else if (!widget.isReferenceDetected && oldWidget.isReferenceDetected) {
      _onReferenceLost();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _accelerometerSubscription?.cancel();
    super.dispose();
  }

  void _startAccelerometerListener() {
    try {
      _accelerometerSubscription = accelerometerEventStream().listen(
        (AccelerometerEvent event) {
          // Calculate tilt from accelerometer data
          // X-axis gives left/right tilt
          // Normalize to roughly -90 to 90 degrees
          final tilt = (event.x / 9.8 * 90).clamp(-90.0, 90.0);

          if (mounted && (tilt - _deviceTilt).abs() > 0.5) {
            setState(() {
              _deviceTilt = tilt;
            });
          }
        },
        onError: (error) {
          // Accelerometer not available, just use 0
          debugPrint('Accelerometer error: $error');
        },
      );
    } catch (e) {
      debugPrint('Failed to initialize accelerometer: $e');
    }
  }

  void _onReferenceDetected() {
    HapticFeedback.mediumImpact();
    _pulseController.forward();
    widget.onReferenceDetectionChanged?.call(true);
  }

  void _onReferenceLost() {
    _pulseController.reverse();
    widget.onReferenceDetectionChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          painter: ReticlePainter(
            tiltAngle: _deviceTilt,
            isLocked: widget.isReferenceDetected,
            color: _colorAnimation.value,
            pulseProgress: _pulseAnimation.value,
          ),
          size: Size.infinite,
        );
      },
    );
  }
}

/// Simplified reticle without level indicator (for constrained views)
class SimpleReticleOverlay extends StatelessWidget {
  final bool isActive;

  const SimpleReticleOverlay({
    super.key,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: ReticlePainter(
        tiltAngle: 0,
        isLocked: false,
        color: isActive
            ? BlueprintColors.primaryForeground
            : BlueprintColors.tertiaryForeground,
        pulseProgress: 0,
        levelIndicatorRadius: 0, // Hide level indicator
      ),
      size: Size.infinite,
    );
  }
}

/// Detection status badge shown when reference is detected
class DetectionStatusBadge extends StatelessWidget {
  final ReferenceDetectionResult? result;

  const DetectionStatusBadge({
    super.key,
    this.result,
  });

  @override
  Widget build(BuildContext context) {
    if (result == null || result!.type == ReferenceType.none) {
      return const SizedBox.shrink();
    }

    final isLocked = result!.isLocked;
    final confidence = result!.confidence;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isLocked
            ? BlueprintColors.successState.withValues(alpha: 0.9)
            : BlueprintColors.accentAction.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isLocked ? Icons.lock : Icons.search,
            size: 16,
            color: BlueprintColors.primaryForeground,
          ),
          const SizedBox(width: 8),
          Text(
            isLocked
                ? 'Reference Locked'
                : 'Detecting... ${(confidence * 100).toInt()}%',
            style: const TextStyle(
              color: BlueprintColors.primaryForeground,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Reference type indicator icons
class ReferenceTypeIndicator extends StatelessWidget {
  final ReferenceType type;

  const ReferenceTypeIndicator({
    super.key,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    String label;

    switch (type) {
      case ReferenceType.aruco:
        icon = Icons.qr_code_2;
        label = 'ArUco';
        break;
      case ReferenceType.grid:
        icon = Icons.grid_on;
        label = 'Grid';
        break;
      case ReferenceType.creditCard:
        icon = Icons.credit_card;
        label = 'Card';
        break;
      case ReferenceType.manual:
        icon = Icons.edit;
        label = 'Manual';
        break;
      case ReferenceType.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: BlueprintColors.primaryForeground,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: BlueprintColors.primaryForeground,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
