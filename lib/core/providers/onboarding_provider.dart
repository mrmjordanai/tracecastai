import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'service_providers.dart';

/// Onboarding step types
enum OnboardingStepType {
  intro,
  info,
  singleSelect,
  multiSelect,
  progress,
  summary,
  permission,
  account,
  paywall,
}

/// Single onboarding answer
class OnboardingAnswer {
  final String stepId;
  final dynamic value;
  final DateTime answeredAt;

  const OnboardingAnswer({
    required this.stepId,
    required this.value,
    required this.answeredAt,
  });
}

/// Onboarding session state
class OnboardingState {
  final bool isComplete;
  final int currentStepIndex;
  final List<OnboardingAnswer> answers;
  final bool isLoading;
  final String? error;

  const OnboardingState({
    this.isComplete = false,
    this.currentStepIndex = 0,
    this.answers = const [],
    this.isLoading = false,
    this.error,
  });

  /// Get answer for a specific step
  dynamic getAnswer(String stepId) {
    final answer = answers.where((a) => a.stepId == stepId).firstOrNull;
    return answer?.value;
  }

  OnboardingState copyWith({
    bool? isComplete,
    int? currentStepIndex,
    List<OnboardingAnswer>? answers,
    bool? isLoading,
    String? error,
  }) {
    return OnboardingState(
      isComplete: isComplete ?? this.isComplete,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      answers: answers ?? this.answers,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Onboarding step definition
class OnboardingStepDefinition {
  final String id;
  final OnboardingStepType type;
  final String title;
  final String? subtitle;
  final List<Map<String, dynamic>>? options;
  final bool isRequired;
  final bool canSkip;

  const OnboardingStepDefinition({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.options,
    this.isRequired = false,
    this.canSkip = false,
  });
}

/// Onboarding notifier - manages onboarding flow
class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final StorageService _storage;

  // Define all 16 onboarding steps per PRD
  static const List<OnboardingStepDefinition> steps = [
    OnboardingStepDefinition(
      id: 'welcome',
      type: OnboardingStepType.intro,
      title: 'Welcome to TraceCast',
    ),
    OnboardingStepDefinition(
      id: 'scale_promise',
      type: OnboardingStepType.info,
      title: 'True-to-Scale Patterns',
      subtitle: 'Your printed patterns, now digitized with perfect accuracy.',
    ),
    OnboardingStepDefinition(
      id: 'ai_demo',
      type: OnboardingStepType.info,
      title: 'AI-Powered Extraction',
      subtitle: 'Our AI sees the lines, not just the paper.',
    ),
    OnboardingStepDefinition(
      id: 'social_proof',
      type: OnboardingStepType.info,
      title: 'Trusted by Crafters',
    ),
    OnboardingStepDefinition(
      id: 'project_type',
      type: OnboardingStepType.singleSelect,
      title: 'What do you create?',
      isRequired: true,
      options: [
        {'id': 'sewing', 'label': 'Sewing & Garments', 'icon': 'content_cut'},
        {'id': 'quilting', 'label': 'Quilting', 'icon': 'grid_view'},
        {
          'id': 'stencil',
          'label': 'Stencils & Templates',
          'icon': 'format_shapes'
        },
        {'id': 'maker', 'label': 'Maker Projects', 'icon': 'build'},
      ],
    ),
    OnboardingStepDefinition(
      id: 'library_size',
      type: OnboardingStepType.singleSelect,
      title: 'How many patterns do you have?',
      options: [
        {'id': 'few', 'label': '1-10'},
        {'id': 'moderate', 'label': '11-50'},
        {'id': 'many', 'label': '50+'},
      ],
    ),
    OnboardingStepDefinition(
      id: 'pain_points',
      type: OnboardingStepType.multiSelect,
      title: 'What frustrates you about patterns?',
      options: [
        {'id': 'taping', 'label': 'Taping PDF pages together'},
        {'id': 'storage', 'label': 'Pattern storage'},
        {'id': 'accuracy', 'label': 'Getting accurate cuts'},
        {'id': 'organization', 'label': 'Finding the right pattern'},
        {'id': 'sizing', 'label': 'Scaling sizes'},
      ],
    ),
    OnboardingStepDefinition(
      id: 'projector_status',
      type: OnboardingStepType.singleSelect,
      title: 'Do you have a projector?',
      options: [
        {'id': 'yes', 'label': 'Yes, I project patterns'},
        {'id': 'planning', 'label': 'Planning to get one'},
        {'id': 'no', 'label': 'No projector'},
      ],
    ),
    OnboardingStepDefinition(
      id: 'grid_mat_status',
      type: OnboardingStepType.singleSelect,
      title: 'Do you have a cutting mat with grid?',
      options: [
        {'id': 'yes', 'label': 'Yes, with grid lines'},
        {'id': 'no_grid', 'label': 'Plain cutting mat'},
        {'id': 'none', 'label': 'No cutting mat'},
      ],
    ),
    OnboardingStepDefinition(
      id: 'units',
      type: OnboardingStepType.singleSelect,
      title: 'Preferred units?',
      isRequired: true,
      options: [
        {'id': 'mm', 'label': 'Millimeters (mm)'},
        {'id': 'inches', 'label': 'Inches (in)'},
      ],
    ),
    OnboardingStepDefinition(
      id: 'calculating',
      type: OnboardingStepType.progress,
      title: 'Personalizing your experience...',
    ),
    OnboardingStepDefinition(
      id: 'setup_preview',
      type: OnboardingStepType.summary,
      title: 'Your Setup',
    ),
    OnboardingStepDefinition(
      id: 'notification_permission',
      type: OnboardingStepType.permission,
      title: 'Stay Updated',
      subtitle: 'Get notified when your patterns are ready.',
      canSkip: true,
    ),
    OnboardingStepDefinition(
      id: 'account',
      type: OnboardingStepType.account,
      title: 'Create Your Account',
      subtitle: 'Save your patterns across devices.',
    ),
    OnboardingStepDefinition(
      id: 'paywall',
      type: OnboardingStepType.paywall,
      title: 'Start Your Free Trial',
    ),
    OnboardingStepDefinition(
      id: 'camera_permission',
      type: OnboardingStepType.permission,
      title: 'Ready to Scan',
      subtitle: 'Enable camera access to digitize your first pattern.',
      isRequired: true,
    ),
  ];

  OnboardingNotifier(this._storage) : super(const OnboardingState());

  /// Check if onboarding was already completed
  Future<void> checkOnboardingStatus() async {
    final completed = _storage.getBool('onboarding_complete');
    if (completed == true) {
      state = state.copyWith(isComplete: true);
    }
  }

  /// Get current step definition
  OnboardingStepDefinition get currentStep => steps[state.currentStepIndex];

  /// Answer current step and advance
  Future<void> answerStep(dynamic value) async {
    final answer = OnboardingAnswer(
      stepId: currentStep.id,
      value: value,
      answeredAt: DateTime.now(),
    );

    final newAnswers = [
      ...state.answers.where((a) => a.stepId != currentStep.id),
      answer
    ];

    state = state.copyWith(answers: newAnswers);
  }

  /// Go to next step
  void nextStep() {
    if (state.currentStepIndex < steps.length - 1) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex + 1);
    } else {
      completeOnboarding();
    }
  }

  /// Go to previous step
  void previousStep() {
    if (state.currentStepIndex > 0) {
      state = state.copyWith(currentStepIndex: state.currentStepIndex - 1);
    }
  }

  /// Skip current step (if allowed)
  void skipStep() {
    if (currentStep.canSkip) {
      nextStep();
    }
  }

  /// Complete onboarding
  Future<void> completeOnboarding() async {
    await _storage.setBool('onboarding_complete', true);
    state = state.copyWith(isComplete: true);
  }

  /// Reset onboarding (for testing)
  Future<void> resetOnboarding() async {
    await _storage.remove('onboarding_complete');
    state = const OnboardingState();
  }
}

/// Onboarding provider
final onboardingProvider =
    StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return OnboardingNotifier(storage);
});

/// Is onboarding complete provider
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  return ref.watch(onboardingProvider).isComplete;
});

/// Current onboarding step provider
final currentOnboardingStepProvider =
    Provider<OnboardingStepDefinition?>((ref) {
  final onboarding = ref.watch(onboardingProvider);
  if (onboarding.isComplete) return null;
  return OnboardingNotifier.steps[onboarding.currentStepIndex];
});
