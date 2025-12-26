import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../../../app/theme/blueprint_colors.dart';

/// CameraPreview - Live camera viewfinder widget
///
/// Displays the camera feed with proper aspect ratio handling.
/// Used in the capture flow for pattern scanning.
class CameraPreview extends StatelessWidget {
  const CameraPreview({
    super.key,
    required this.controller,
    this.overlay,
    this.borderRadius = 16.0,
    this.showGrid = false,
  });

  /// The camera controller (must be initialized)
  final CameraController controller;

  /// Optional overlay widget (e.g., scan frame, focus indicator)
  final Widget? overlay;

  /// Corner radius for the preview (default: 16)
  final double borderRadius;

  /// Whether to show alignment grid lines
  final bool showGrid;

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container(
        decoration: BoxDecoration(
          color: BlueprintColors.surfaceOverlay,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: const Center(
          child: CircularProgressIndicator(
            color: BlueprintColors.primaryForeground,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            CameraPreview._buildPreview(controller),
            if (showGrid) const _AlignmentGrid(),
            if (overlay != null) overlay!,
          ],
        ),
      ),
    );
  }

  static Widget _buildPreview(CameraController controller) {
    return CameraPreviewWidget(controller: controller);
  }
}

/// Internal widget that renders the actual camera preview
class CameraPreviewWidget extends StatelessWidget {
  const CameraPreviewWidget({super.key, required this.controller});

  final CameraController controller;

  @override
  Widget build(BuildContext context) {
    return controller.buildPreview();
  }
}

/// Alignment grid overlay for the camera preview
class _AlignmentGrid extends StatelessWidget {
  const _AlignmentGrid();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      size: Size.infinite,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = BlueprintColors.primaryForeground.withValues(alpha: 0.3)
      ..strokeWidth = 0.5;

    // Vertical lines (rule of thirds)
    final third = size.width / 3;
    canvas.drawLine(
      Offset(third, 0),
      Offset(third, size.height),
      paint,
    );
    canvas.drawLine(
      Offset(third * 2, 0),
      Offset(third * 2, size.height),
      paint,
    );

    // Horizontal lines (rule of thirds)
    final thirdH = size.height / 3;
    canvas.drawLine(
      Offset(0, thirdH),
      Offset(size.width, thirdH),
      paint,
    );
    canvas.drawLine(
      Offset(0, thirdH * 2),
      Offset(size.width, thirdH * 2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Scan frame overlay with corner brackets
class ScanFrameOverlay extends StatelessWidget {
  const ScanFrameOverlay({
    super.key,
    this.frameColor = BlueprintColors.primaryForeground,
    this.cornerLength = 24,
    this.cornerWidth = 3,
    this.padding = 32,
  });

  final Color frameColor;
  final double cornerLength;
  final double cornerWidth;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
      child: CustomPaint(
        painter: _ScanFramePainter(
          color: frameColor,
          cornerLength: cornerLength,
          cornerWidth: cornerWidth,
        ),
        size: Size.infinite,
      ),
    );
  }
}

class _ScanFramePainter extends CustomPainter {
  _ScanFramePainter({
    required this.color,
    required this.cornerLength,
    required this.cornerWidth,
  });

  final Color color;
  final double cornerLength;
  final double cornerWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = cornerWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Top-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, cornerLength)
        ..lineTo(0, 0)
        ..lineTo(cornerLength, 0),
      paint,
    );

    // Top-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, 0)
        ..lineTo(size.width, 0)
        ..lineTo(size.width, cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height - cornerLength)
        ..lineTo(0, size.height)
        ..lineTo(cornerLength, size.height),
      paint,
    );

    // Bottom-right corner
    canvas.drawPath(
      Path()
        ..moveTo(size.width - cornerLength, size.height)
        ..lineTo(size.width, size.height)
        ..lineTo(size.width, size.height - cornerLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
