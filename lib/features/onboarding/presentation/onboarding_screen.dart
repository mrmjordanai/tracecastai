import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/onboarding_provider.dart';
import '../../../core/providers/subscription_provider.dart';
import 'widgets/intro_step_widget.dart';
import 'widgets/info_step_widget.dart';
import 'widgets/single_select_step_widget.dart';
import 'widgets/multi_select_step_widget.dart';
import 'widgets/progress_step_widget.dart';
import 'widgets/summary_step_widget.dart';
import 'widgets/permission_step_widget.dart';
import 'widgets/account_step_widget.dart';
import 'widgets/paywall_step_widget.dart';

/// OnboardingScreen - Main orchestrator for the 16-step onboarding flow
/// Uses PageView with programmatic navigation (no swipe)
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToStep(int index) {
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _handleNext() {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);

    if (state.currentStepIndex < OnboardingNotifier.steps.length - 1) {
      notifier.nextStep();
      _goToStep(state.currentStepIndex + 1);
    } else {
      _completeOnboarding();
    }
  }

  void _handleBack() {
    final notifier = ref.read(onboardingProvider.notifier);
    final state = ref.read(onboardingProvider);

    if (state.currentStepIndex > 0) {
      notifier.previousStep();
      _goToStep(state.currentStepIndex - 1);
    }
  }

  void _handleSkip() {
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.skipStep();
    final state = ref.read(onboardingProvider);
    _goToStep(state.currentStepIndex);
  }

  Future<void> _completeOnboarding() async {
    final notifier = ref.read(onboardingProvider.notifier);
    await notifier.completeOnboarding();

    if (mounted) {
      context.go('/');
    }
  }

  Map<String, dynamic> _getAnswersMap() {
    final state = ref.read(onboardingProvider);
    final answers = <String, dynamic>{};
    for (final answer in state.answers) {
      answers[answer.stepId] = answer.value;
    }
    return answers;
  }

  @override
  Widget build(BuildContext context) {
    // Watch provider to rebuild on state changes
    ref.watch(onboardingProvider);
    final steps = OnboardingNotifier.steps;

    return Scaffold(
      backgroundColor: BlueprintColors.primaryBackground,
      body: PageView.builder(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: steps.length,
        itemBuilder: (context, index) {
          final step = steps[index];
          return _buildStepWidget(step, index);
        },
      ),
    );
  }

  Widget _buildStepWidget(OnboardingStepDefinition step, int index) {
    final state = ref.watch(onboardingProvider);
    final currentValue = state.getAnswer(step.id);

    switch (step.type) {
      case OnboardingStepType.intro:
        return IntroStepWidget(
          step: step,
          onContinue: _handleNext,
          onSignIn: () {
            // Navigate to sign-in flow
            _goToStep(
                OnboardingNotifier.steps.indexWhere((s) => s.id == 'account'));
          },
        );

      case OnboardingStepType.info:
        return InfoStepWidget(
          step: step,
          onContinue: _handleNext,
        );

      case OnboardingStepType.singleSelect:
        return SingleSelectStepWidget(
          step: step,
          currentValue: currentValue,
          onSelect: (value) {
            ref.read(onboardingProvider.notifier).answerStep(value);
          },
          onContinue: _handleNext,
          onBack: index > 0 ? _handleBack : null,
          autoAdvance: true,
        );

      case OnboardingStepType.multiSelect:
        return MultiSelectStepWidget(
          step: step,
          currentValues: currentValue as List<dynamic>? ?? [],
          onSelect: (values) {
            ref.read(onboardingProvider.notifier).answerStep(values);
          },
          onContinue: _handleNext,
          onBack: index > 0 ? _handleBack : null,
        );

      case OnboardingStepType.progress:
        return ProgressStepWidget(
          step: step,
          answers: _getAnswersMap(),
          onComplete: _handleNext,
        );

      case OnboardingStepType.summary:
        return SummaryStepWidget(
          step: step,
          answers: _getAnswersMap(),
          onContinue: _handleNext,
          onBack: _handleBack,
        );

      case OnboardingStepType.permission:
        return PermissionStepWidget(
          step: step,
          permissionType: step.id == 'camera_permission'
              ? Permission.camera
              : Permission.notification,
          onPermissionResult: (granted) {
            ref.read(onboardingProvider.notifier).answerStep(granted);
            _handleNext();
          },
          onSkip: step.canSkip ? _handleSkip : null,
          onBack: index > 0 ? _handleBack : null,
        );

      case OnboardingStepType.account:
        return AccountStepWidget(
          step: step,
          onSignIn: (provider) async {
            final authNotifier = ref.read(authProvider.notifier);
            bool success = false;

            switch (provider) {
              case 'apple':
                success = await authNotifier.signInWithApple();
                break;
              case 'google':
                success = await authNotifier.signInWithGoogle();
                break;
              case 'email':
                // Email flow would need a separate UI for email/password input
                // For now, navigate to next step to implement later
                success = true;
                break;
            }

            if (success) {
              _handleNext();
            }
            return success;
          },
          onBack: index > 0 ? _handleBack : null,
        );

      case OnboardingStepType.paywall:
        return PaywallStepWidget(
          step: step,
          answers: _getAnswersMap(),
          onPurchase: (planId) async {
            final notifier = ref.read(subscriptionProvider.notifier);
            final tier = planId.contains('annual')
                ? SubscriptionTier.annual
                : SubscriptionTier.monthly;
            final success = await notifier.purchase(tier);
            if (success) {
              _handleNext();
            }
            return success;
          },
          onRestore: () async {
            final notifier = ref.read(subscriptionProvider.notifier);
            final success = await notifier.restorePurchases();
            if (success) {
              _handleNext();
            }
            return success;
          },
          onBack: null, // Hard paywall - no back button
        );
    }
  }
}
