import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// IntroStepWidget - Welcome splash screen with animation
/// Screen 1: Full-screen with Blueprint background, logo animation, Get Started button
class IntroStepWidget extends StatefulWidget {
  final OnboardingStepDefinition step;
  final VoidCallback onContinue;
  final VoidCallback? onSignIn;

  const IntroStepWidget({
    super.key,
    required this.step,
    required this.onContinue,
    this.onSignIn,
  });

  @override
  State<IntroStepWidget> createState() => _IntroStepWidgetState();
}

class _IntroStepWidgetState extends State<IntroStepWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Logo with animation
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Opacity(
                    opacity: _fadeAnimation.value,
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  // Logo icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: BlueprintColors.primaryForeground,
                      borderRadius: BorderRadius.circular(32),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.grid_on,
                        size: 64,
                        color: BlueprintColors.primaryBackground,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // App name
                  Text(
                    'TraceCast',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                          color: BlueprintColors.primaryForeground,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Digitize. Project. Create.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: BlueprintColors.secondaryForeground,
                        ),
                  ),
                ],
              ),
            ),

            const Spacer(flex: 3),

            // Get Started button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  widget.onContinue();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: BlueprintColors.primaryForeground,
                  foregroundColor: BlueprintColors.primaryBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'Get Started',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Sign in link
            if (widget.onSignIn != null)
              TextButton(
                onPressed: widget.onSignIn,
                child: Text(
                  'Already have an account? Sign in',
                  style: TextStyle(
                    color: BlueprintColors.secondaryForeground,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
