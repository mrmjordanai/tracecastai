import 'package:flutter/material.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// SummaryStepWidget - Dynamic personalized preview
/// Screen 12: Shows "Your Setup" summary based on user's onboarding answers
class SummaryStepWidget extends StatelessWidget {
  final OnboardingStepDefinition step;
  final Map<String, dynamic> answers;
  final VoidCallback onContinue;
  final VoidCallback? onBack;

  const SummaryStepWidget({
    super.key,
    required this.step,
    required this.answers,
    required this.onContinue,
    this.onBack,
  });

  String _formatProjectType(dynamic value) {
    switch (value?.toString()) {
      case 'sewing':
        return 'Sewing & Garments';
      case 'quilting':
        return 'Quilting';
      case 'stencil':
        return 'Stencils & Templates';
      case 'maker':
        return 'Maker Projects';
      default:
        return 'General';
    }
  }

  String _formatUnits(dynamic value) {
    switch (value?.toString()) {
      case 'mm':
        return 'Millimeters (mm)';
      case 'inches':
        return 'Inches (in)';
      default:
        return 'Inches (in)';
    }
  }

  String _formatProjector(dynamic value) {
    switch (value?.toString()) {
      case 'yes':
        return 'Ready to project';
      case 'planning':
        return 'Planning to get one';
      case 'no':
        return 'No projector';
      default:
        return 'Not specified';
    }
  }

  IconData _getProjectorIcon(dynamic value) {
    switch (value?.toString()) {
      case 'yes':
        return Icons.cast_connected;
      case 'planning':
        return Icons.cast;
      default:
        return Icons.cast_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final projectType = answers['project_type'];
    final units = answers['units'];
    final projectorStatus = answers['projector_status'];

    return SafeArea(
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (onBack != null)
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                const Spacer(),
              ],
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  step.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  "Here's what we've learned about you",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // Summary cards
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              children: [
                _SummaryCard(
                  icon: Icons.category,
                  label: 'Project Type',
                  value: _formatProjectType(projectType),
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  icon: Icons.straighten,
                  label: 'Measurement Units',
                  value: _formatUnits(units),
                ),
                const SizedBox(height: 12),
                _SummaryCard(
                  icon: _getProjectorIcon(projectorStatus),
                  label: 'Projector',
                  value: _formatProjector(projectorStatus),
                ),
              ],
            ),
          ),

          // Continue button
          Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BlueprintColors.primaryForeground,
                  foregroundColor: BlueprintColors.primaryBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Continue',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SummaryCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: BlueprintColors.primaryForeground.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                icon,
                color: BlueprintColors.primaryForeground,
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: BlueprintColors.secondaryForeground,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: BlueprintColors.primaryForeground,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
