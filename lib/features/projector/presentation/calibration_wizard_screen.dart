import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/calibration_provider.dart';
import '../../../shared/widgets/scrubber_input.dart';
import 'widgets/test_square_painter.dart';

/// Calibration Wizard Screen
///
/// A 4-step wizard for calibrating projector scale accuracy.
/// This is session-only calibration for MVP (not persisted).
///
/// Steps:
/// 1. Welcome - Explain calibration
/// 2. Test Square - Project 100mm square
/// 3. Measure - User measures and enters value
/// 4. Adjust - Fine-tune with scrubber
class CalibrationWizardScreen extends ConsumerStatefulWidget {
  final String projectId;

  const CalibrationWizardScreen({
    super.key,
    required this.projectId,
  });

  @override
  ConsumerState<CalibrationWizardScreen> createState() =>
      _CalibrationWizardScreenState();
}

class _CalibrationWizardScreenState
    extends ConsumerState<CalibrationWizardScreen> {
  // Estimate display scale (pixels per mm) - this would be calibrated per device
  final double _displayScale = 3.78; // ~96 DPI approximation

  @override
  void initState() {
    super.initState();
    // Reset calibration state when entering wizard
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(calibrationProvider.notifier).reset();
    });
  }

  void _handleNext() {
    HapticFeedback.lightImpact();
    ref.read(calibrationProvider.notifier).nextStep();
  }

  void _handleBack() {
    final state = ref.read(calibrationProvider);
    if (state.step == CalibrationStep.welcome) {
      context.pop();
    } else {
      ref.read(calibrationProvider.notifier).previousStep();
    }
  }

  void _handleComplete() {
    HapticFeedback.mediumImpact();
    ref.read(calibrationProvider.notifier).nextStep();

    // Show success message and return to projector
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Calibration complete!'),
        backgroundColor: BlueprintColors.successState,
      ),
    );

    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(calibrationProvider);

    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      appBar: AppBar(
        title: Text('Calibration (${state.stepIndex + 1}/${CalibrationState.totalSteps})'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (state.stepIndex + 1) / CalibrationState.totalSteps,
              backgroundColor: BlueprintColors.surfaceOverlay,
              valueColor: AlwaysStoppedAnimation<Color>(
                BlueprintColors.accentAction,
              ),
            ),

            // Step content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: _buildStepContent(state),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent(CalibrationState state) {
    switch (state.step) {
      case CalibrationStep.welcome:
        return _WelcomeStep(onNext: _handleNext);
      case CalibrationStep.testSquare:
        return _TestSquareStep(
          displayScale: _displayScale,
          useMetric: state.useMetric,
          onUnitChanged: (useMetric) {
            ref.read(calibrationProvider.notifier).setUseMetric(useMetric);
          },
          onNext: _handleNext,
        );
      case CalibrationStep.measure:
        return _MeasureStep(
          useMetric: state.useMetric,
          expectedSize: state.expectedSizeInUnit,
          unitString: state.unitString,
          onMeasuredValueChanged: (value) {
            ref.read(calibrationProvider.notifier).setMeasuredValue(value);
          },
          measuredValue: state.measuredValue,
          onNext: _handleNext,
        );
      case CalibrationStep.adjust:
        return _AdjustStep(
          scaleAdjustment: state.scaleAdjustmentPercent,
          effectiveScale: state.effectiveScale,
          onAdjustmentChanged: (value) {
            ref.read(calibrationProvider.notifier).setScaleAdjustment(value);
          },
          onComplete: _handleComplete,
        );
    }
  }
}

/// Step 1: Welcome
class _WelcomeStep extends StatelessWidget {
  final VoidCallback onNext;

  const _WelcomeStep({required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: BlueprintColors.accentAction.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.square_foot,
              size: 64,
              color: BlueprintColors.accentAction,
            ),
          ),
          const SizedBox(height: 32),

          // Title
          Text(
            'Projector Calibration',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: BlueprintColors.primaryForeground,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            'Ensure your patterns project at the exact size they should be on your cutting surface.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: BlueprintColors.secondaryForeground,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Instructions
          _InstructionItem(
            icon: Icons.straighten,
            text: 'Grab a physical ruler or measuring tape',
          ),
          const SizedBox(height: 12),
          _InstructionItem(
            icon: Icons.settings_overscan,
            text: 'Point your projector at a flat surface',
          ),
          const SizedBox(height: 12),
          _InstructionItem(
            icon: Icons.visibility,
            text: 'Make sure you can see the projected image clearly',
          ),

          const Spacer(),

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: BlueprintColors.accentAction,
                foregroundColor: BlueprintColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Start Calibration',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 2: Test Square
class _TestSquareStep extends StatelessWidget {
  final double displayScale;
  final bool useMetric;
  final ValueChanged<bool> onUnitChanged;
  final VoidCallback onNext;

  const _TestSquareStep({
    required this.displayScale,
    required this.useMetric,
    required this.onUnitChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Test square display
        Expanded(
          child: TestSquareDisplay(
            sizeMm: 100.0,
            displayScale: displayScale,
            useMetric: useMetric,
          ),
        ),

        // Controls
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: BlueprintColors.surfaceElevated,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(24),
            ),
          ),
          child: Column(
            children: [
              Text(
                'A test square is now being projected',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BlueprintColors.primaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Unit selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _UnitButton(
                    label: 'Metric (mm)',
                    isSelected: useMetric,
                    onTap: () => onUnitChanged(true),
                  ),
                  const SizedBox(width: 12),
                  _UnitButton(
                    label: 'Imperial (in)',
                    isSelected: !useMetric,
                    onTap: () => onUnitChanged(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Next button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BlueprintColors.accentAction,
                    foregroundColor: BlueprintColors.primaryForeground,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'I Can See the Square',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Step 3: Measure
class _MeasureStep extends StatelessWidget {
  final bool useMetric;
  final double expectedSize;
  final String unitString;
  final double measuredValue;
  final ValueChanged<double> onMeasuredValueChanged;
  final VoidCallback onNext;

  const _MeasureStep({
    required this.useMetric,
    required this.expectedSize,
    required this.unitString,
    required this.measuredValue,
    required this.onMeasuredValueChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final min = useMetric ? 80.0 : 3.0;
    final max = useMetric ? 120.0 : 5.0;
    final step = useMetric ? 0.5 : 0.05;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BlueprintColors.surfaceElevated,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.straighten,
              size: 40,
              color: BlueprintColors.accentAction,
            ),
          ),
          const SizedBox(height: 24),

          // Instructions
          Text(
            'Measure the projected square',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: BlueprintColors.primaryForeground,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            'Use your ruler to measure one side of the square. Enter the measurement below.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BlueprintColors.secondaryForeground,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Expected value display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BlueprintColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Expected:',
                  style: TextStyle(
                    color: BlueprintColors.secondaryForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${expectedSize.toStringAsFixed(useMetric ? 0 : 2)} $unitString',
                  style: const TextStyle(
                    color: BlueprintColors.primaryForeground,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Measured value input
          Text(
            'What did you measure?',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BlueprintColors.primaryForeground,
                ),
          ),
          const SizedBox(height: 16),

          ScrubberInput(
            value: measuredValue,
            onChanged: onMeasuredValueChanged,
            min: min,
            max: max,
            step: step,
            suffix: unitString,
            decimalPlaces: useMetric ? 1 : 2,
            semanticLabel: 'Measured value in $unitString',
          ),

          const Spacer(),

          // Next button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(
                backgroundColor: BlueprintColors.accentAction,
                foregroundColor: BlueprintColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Step 4: Adjust
class _AdjustStep extends StatelessWidget {
  final double scaleAdjustment;
  final double effectiveScale;
  final ValueChanged<double> onAdjustmentChanged;
  final VoidCallback onComplete;

  const _AdjustStep({
    required this.scaleAdjustment,
    required this.effectiveScale,
    required this.onAdjustmentChanged,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isAdjusted = scaleAdjustment.abs() > 0.1;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Spacer(),

          // Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: isAdjusted
                  ? BlueprintColors.accentAction.withValues(alpha: 0.2)
                  : BlueprintColors.successState.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isAdjusted ? Icons.tune : Icons.check_circle_outline,
              size: 40,
              color: isAdjusted
                  ? BlueprintColors.accentAction
                  : BlueprintColors.successState,
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            isAdjusted ? 'Scale Adjustment Needed' : 'Perfect Match!',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: BlueprintColors.primaryForeground,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),

          Text(
            isAdjusted
                ? 'Fine-tune the adjustment if needed.'
                : 'Your projector is calibrated correctly.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BlueprintColors.secondaryForeground,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),

          // Adjustment scrubber
          Text(
            'Scale Adjustment',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: BlueprintColors.primaryForeground,
                ),
          ),
          const SizedBox(height: 16),

          ScrubberInput(
            value: scaleAdjustment,
            onChanged: onAdjustmentChanged,
            min: -10.0,
            max: 10.0,
            step: 0.1,
            suffix: '%',
            decimalPlaces: 1,
            semanticLabel: 'Scale adjustment percentage',
          ),
          const SizedBox(height: 24),

          // Effective scale display
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: BlueprintColors.surfaceElevated,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Patterns will be scaled by:',
                  style: TextStyle(
                    color: BlueprintColors.secondaryForeground,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${(effectiveScale * 100).toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: scaleAdjustment.abs() > 0.1
                        ? BlueprintColors.accentAction
                        : BlueprintColors.successState,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // Complete button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onComplete,
              style: ElevatedButton.styleFrom(
                backgroundColor: BlueprintColors.accentAction,
                foregroundColor: BlueprintColors.primaryForeground,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Done',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Instruction item widget
class _InstructionItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InstructionItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: BlueprintColors.surfaceElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: BlueprintColors.accentAction,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: BlueprintColors.primaryForeground,
                ),
          ),
        ),
      ],
    );
  }
}

/// Unit selection button
class _UnitButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? BlueprintColors.accentAction
              : BlueprintColors.primaryBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? BlueprintColors.accentAction
                : BlueprintColors.primaryForeground.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: BlueprintColors.primaryForeground,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
