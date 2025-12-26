import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Calibration step enum
enum CalibrationStep {
  welcome,    // Step 0: Introduction
  testSquare, // Step 1: Project test square
  measure,    // Step 2: User measures with ruler
  adjust,     // Step 3: Fine-tune adjustment
}

/// State for projector calibration wizard
/// Note: This is session-only storage for MVP (not persisted)
class CalibrationState {
  final CalibrationStep step;
  final bool useMetric;
  final double expectedSizeMm;
  final double measuredValue;
  final double scaleAdjustmentPercent;
  final String? projectorName;
  final bool isComplete;

  const CalibrationState({
    this.step = CalibrationStep.welcome,
    this.useMetric = true,
    this.expectedSizeMm = 100.0, // Default 100mm test square
    this.measuredValue = 100.0,
    this.scaleAdjustmentPercent = 0.0,
    this.projectorName,
    this.isComplete = false,
  });

  CalibrationState copyWith({
    CalibrationStep? step,
    bool? useMetric,
    double? expectedSizeMm,
    double? measuredValue,
    double? scaleAdjustmentPercent,
    String? projectorName,
    bool? isComplete,
  }) {
    return CalibrationState(
      step: step ?? this.step,
      useMetric: useMetric ?? this.useMetric,
      expectedSizeMm: expectedSizeMm ?? this.expectedSizeMm,
      measuredValue: measuredValue ?? this.measuredValue,
      scaleAdjustmentPercent: scaleAdjustmentPercent ?? this.scaleAdjustmentPercent,
      projectorName: projectorName ?? this.projectorName,
      isComplete: isComplete ?? this.isComplete,
    );
  }

  /// Get the effective scale multiplier based on adjustment
  /// 1.0 = no change, 1.05 = 5% larger, 0.95 = 5% smaller
  double get effectiveScale => 1.0 + (scaleAdjustmentPercent / 100);

  /// Expected size in the user's preferred unit
  double get expectedSizeInUnit {
    if (useMetric) {
      return expectedSizeMm;
    } else {
      return expectedSizeMm / 25.4; // Convert to inches
    }
  }

  /// Get the unit string
  String get unitString => useMetric ? 'mm' : 'in';

  /// Calculate the adjustment percentage based on measured vs expected
  double calculateAdjustment() {
    if (measuredValue <= 0 || expectedSizeMm <= 0) return 0.0;

    final expectedInUnit = expectedSizeInUnit;
    final difference = expectedInUnit - measuredValue;
    final percentDiff = (difference / expectedInUnit) * 100;

    // Clamp to ±10% for safety
    return percentDiff.clamp(-10.0, 10.0);
  }

  /// Get the step index (0-3)
  int get stepIndex => step.index;

  /// Total number of steps
  static const int totalSteps = 4;
}

/// Provider for calibration wizard state
class CalibrationNotifier extends StateNotifier<CalibrationState> {
  CalibrationNotifier() : super(const CalibrationState());

  /// Move to the next step
  void nextStep() {
    final currentIndex = state.step.index;
    if (currentIndex < CalibrationStep.values.length - 1) {
      final nextStep = CalibrationStep.values[currentIndex + 1];

      // Auto-calculate adjustment when moving to adjust step
      if (nextStep == CalibrationStep.adjust) {
        final adjustment = state.calculateAdjustment();
        state = state.copyWith(
          step: nextStep,
          scaleAdjustmentPercent: adjustment,
        );
      } else {
        state = state.copyWith(step: nextStep);
      }
    } else {
      // Complete calibration
      state = state.copyWith(isComplete: true);
    }
  }

  /// Move to the previous step
  void previousStep() {
    final currentIndex = state.step.index;
    if (currentIndex > 0) {
      state = state.copyWith(
        step: CalibrationStep.values[currentIndex - 1],
      );
    }
  }

  /// Go to a specific step
  void goToStep(CalibrationStep step) {
    state = state.copyWith(step: step);
  }

  /// Set the unit preference (metric or imperial)
  void setUseMetric(bool useMetric) {
    // Convert the measured value to the new unit
    double newMeasuredValue;
    if (useMetric && !state.useMetric) {
      // Converting from inches to mm
      newMeasuredValue = state.measuredValue * 25.4;
    } else if (!useMetric && state.useMetric) {
      // Converting from mm to inches
      newMeasuredValue = state.measuredValue / 25.4;
    } else {
      newMeasuredValue = state.measuredValue;
    }

    state = state.copyWith(
      useMetric: useMetric,
      measuredValue: newMeasuredValue,
    );
  }

  /// Set the measured value from user input
  void setMeasuredValue(double value) {
    state = state.copyWith(measuredValue: value);
  }

  /// Set the scale adjustment percentage
  void setScaleAdjustment(double percent) {
    state = state.copyWith(
      scaleAdjustmentPercent: percent.clamp(-10.0, 10.0),
    );
  }

  /// Set the projector name (for future profile saving)
  void setProjectorName(String name) {
    state = state.copyWith(projectorName: name);
  }

  /// Calculate and apply adjustment based on measurement
  void calculateAndApplyAdjustment() {
    final adjustment = state.calculateAdjustment();
    state = state.copyWith(scaleAdjustmentPercent: adjustment);
  }

  /// Reset to initial state
  void reset() {
    state = const CalibrationState();
  }

  /// Get calibration result for use in projector
  double getEffectiveScale() {
    return state.effectiveScale;
  }
}

/// Provider for calibration state
final calibrationProvider =
    StateNotifierProvider<CalibrationNotifier, CalibrationState>((ref) {
  return CalibrationNotifier();
});

/// Provider to check if calibration is complete
final isCalibrationCompleteProvider = Provider<bool>((ref) {
  return ref.watch(calibrationProvider).isComplete;
});

/// Provider to get the effective scale from calibration
final effectiveScaleProvider = Provider<double>((ref) {
  return ref.watch(calibrationProvider).effectiveScale;
});
