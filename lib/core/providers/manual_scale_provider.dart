import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for manual scale input
class ManualScaleState {
  final Offset? startPoint;
  final Offset? endPoint;
  final double knownDimensionMm;
  final bool isDrawing;
  final Size? imageSize;

  const ManualScaleState({
    this.startPoint,
    this.endPoint,
    this.knownDimensionMm = 100.0,
    this.isDrawing = false,
    this.imageSize,
  });

  ManualScaleState copyWith({
    Offset? startPoint,
    Offset? endPoint,
    double? knownDimensionMm,
    bool? isDrawing,
    Size? imageSize,
  }) {
    return ManualScaleState(
      startPoint: startPoint ?? this.startPoint,
      endPoint: endPoint ?? this.endPoint,
      knownDimensionMm: knownDimensionMm ?? this.knownDimensionMm,
      isDrawing: isDrawing ?? this.isDrawing,
      imageSize: imageSize ?? this.imageSize,
    );
  }

  /// Calculate the pixel distance between start and end points
  double get pixelDistance {
    if (startPoint == null || endPoint == null) return 0.0;
    final dx = endPoint!.dx - startPoint!.dx;
    final dy = endPoint!.dy - startPoint!.dy;
    return sqrt(dx * dx + dy * dy);
  }

  /// Calculate the scale factor (mm per pixel)
  double get scaleMmPerPx {
    if (pixelDistance == 0) return 0.0;
    return knownDimensionMm / pixelDistance;
  }

  /// Check if a valid line has been drawn
  bool get hasValidLine {
    return startPoint != null && endPoint != null && pixelDistance > 10;
  }

  /// Clear the drawn line
  ManualScaleState clearLine() {
    return ManualScaleState(
      startPoint: null,
      endPoint: null,
      knownDimensionMm: knownDimensionMm,
      isDrawing: false,
      imageSize: imageSize,
    );
  }
}

/// Provider for manual scale input state
class ManualScaleNotifier extends StateNotifier<ManualScaleState> {
  ManualScaleNotifier() : super(const ManualScaleState());

  /// Start drawing a new line
  void startDrawing(Offset point) {
    state = state.copyWith(
      startPoint: point,
      endPoint: point,
      isDrawing: true,
    );
  }

  /// Update the end point while drawing
  void updateEndPoint(Offset point) {
    if (state.isDrawing) {
      state = state.copyWith(endPoint: point);
    }
  }

  /// Finish drawing the line
  void finishDrawing() {
    state = state.copyWith(isDrawing: false);
  }

  /// Set the known dimension in mm
  void setKnownDimension(double value) {
    state = state.copyWith(knownDimensionMm: value);
  }

  /// Set the image size for coordinate calculations
  void setImageSize(Size size) {
    state = state.copyWith(imageSize: size);
  }

  /// Clear the drawn line and reset state
  void clearLine() {
    state = state.clearLine();
  }

  /// Reset all state
  void reset() {
    state = const ManualScaleState();
  }

  /// Move the start point (for fine-tuning)
  void moveStartPoint(Offset delta) {
    if (state.startPoint != null) {
      state = state.copyWith(
        startPoint: state.startPoint! + delta,
      );
    }
  }

  /// Move the end point (for fine-tuning)
  void moveEndPoint(Offset delta) {
    if (state.endPoint != null) {
      state = state.copyWith(
        endPoint: state.endPoint! + delta,
      );
    }
  }
}

/// Provider for manual scale state
final manualScaleProvider =
    StateNotifierProvider<ManualScaleNotifier, ManualScaleState>((ref) {
  return ManualScaleNotifier();
});
