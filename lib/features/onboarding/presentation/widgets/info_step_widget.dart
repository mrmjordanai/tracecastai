import 'package:flutter/material.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// InfoStepWidget - Reusable widget for value proposition screens
///
/// Used for screens 2-4 (scale_promise, ai_demo, social_proof).
/// Displays title, subtitle, hero illustration area, and Continue button.
class InfoStepWidget extends StatelessWidget {
  const InfoStepWidget({
    super.key,
    required this.step,
    required this.onContinue,
  });

  final OnboardingStepDefinition step;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 1),

            // Hero illustration area
            _buildHeroIllustration(),

            const SizedBox(height: 48),

            // Title
            Text(
              step.title,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: BlueprintColors.primaryForeground,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),

            if (step.subtitle != null) ...[
              const SizedBox(height: 16),
              Text(
                step.subtitle!,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: BlueprintColors.secondaryForeground,
                    ),
                textAlign: TextAlign.center,
              ),
            ],

            const Spacer(flex: 2),

            // Continue button
            SizedBox(
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
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroIllustration() {
    // Icon based on step id
    IconData icon;
    switch (step.id) {
      case 'scale_promise':
        icon = Icons.straighten;
        break;
      case 'ai_demo':
        icon = Icons.auto_awesome;
        break;
      case 'social_proof':
        icon = Icons.people;
        break;
      default:
        icon = Icons.info_outline;
    }

    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(32),
      ),
      child: Center(
        child: Icon(
          icon,
          size: 80,
          color: BlueprintColors.primaryForeground,
        ),
      ),
    );
  }
}
