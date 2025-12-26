import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/library/presentation/home_screen.dart';
import '../features/capture/presentation/scan_screen.dart';
import '../features/capture/presentation/capture_screen.dart';
import '../features/verification/presentation/analysis_screen.dart';
import '../features/verification/presentation/vectorization_error_screen.dart';
import '../features/verification/presentation/network_error_screen.dart';
import '../features/verification/presentation/low_confidence_screen.dart';
import '../features/verification/presentation/no_reference_screen.dart';
import '../features/verification/presentation/manual_scale_screen.dart';
import '../features/projector/presentation/projector_screen.dart';
import '../features/projector/presentation/calibration_wizard_screen.dart';
import '../features/library/presentation/settings_screen.dart';
import '../features/library/presentation/project_detail_screen.dart';
import '../features/library/presentation/search_screen.dart';
import '../features/library/presentation/all_projects_screen.dart';
import '../features/debug/presentation/debug_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/editor/presentation/editor_screen.dart';
import '../features/editor/presentation/verification_screen.dart';
import '../features/editor/presentation/test_square_screen.dart';
import '../core/providers/onboarding_provider.dart';
import '../core/models/vectorize_result.dart';
import '../shared/widgets/app_shell.dart';

/// GoRouter configuration provider
final routerProvider = Provider<GoRouter>((ref) {
  // Watch onboarding state for redirect
  final isOnboardingComplete = ref.watch(isOnboardingCompleteProvider);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // If onboarding not complete and not already on onboarding, redirect
      final isOnboardingRoute = state.matchedLocation.startsWith('/onboarding');
      if (!isOnboardingComplete && !isOnboardingRoute) {
        return '/onboarding';
      }
      // If onboarding complete and on onboarding route, redirect to home
      if (isOnboardingComplete && isOnboardingRoute) {
        return '/';
      }
      return null;
    },
    routes: [
      // Shell route for tab navigation
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/scan',
            name: 'scan',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ScanScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),

      // =====================
      // ONBOARDING FLOW
      // =====================
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // =====================
      // CAPTURE FLOW
      // =====================
      GoRoute(
        path: '/capture/:mode',
        name: 'capture',
        builder: (context, state) {
          final mode = state.pathParameters['mode'] ?? 'sewing';
          return CaptureScreen(mode: mode);
        },
      ),
      GoRoute(
        path: '/analysis/:projectId',
        name: 'analysis',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          final imagePath = extra?['imagePath'] as String? ?? '';
          final mode = extra?['mode'] as String? ?? 'sewing';
          return AnalysisScreen(
            projectId: projectId,
            imagePath: imagePath,
            mode: mode,
          );
        },
      ),

      // =====================
      // VERIFICATION FLOW
      // =====================
      GoRoute(
        path: '/review',
        name: 'review',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'Review & Calibrate'),
        routes: [
          GoRoute(
            path: 'manual-scale',
            name: 'review-manual-scale',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              return ManualScaleScreen(
                imagePath: extra?['imagePath'] as String? ?? '',
                projectId: extra?['projectId'] as String?,
                mode: extra?['mode'] as String? ?? 'sewing',
              );
            },
          ),
        ],
      ),
      GoRoute(
        path: '/verify',
        name: 'verify',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final result = extra?['result'] as VectorizeResult?;
          if (result == null) {
            return const _PlaceholderScreen(name: 'Missing Result');
          }
          return VerificationScreen(
            projectId: extra?['projectId'] as String? ?? '',
            pieceId: extra?['pieceId'] as String? ?? '',
            result: result,
            imagePath: extra?['imagePath'] as String?,
          );
        },
        routes: [
          GoRoute(
            path: 'test-square',
            name: 'verify-test-square',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final result = extra?['result'] as VectorizeResult?;
              if (result == null) {
                return const _PlaceholderScreen(name: 'Missing Result');
              }
              return TestSquareScreen(
                projectId: extra?['projectId'] as String? ?? '',
                pieceId: extra?['pieceId'] as String? ?? '',
                result: result,
              );
            },
          ),
          GoRoute(
            path: 'editor',
            name: 'verify-editor',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>?;
              final result = extra?['result'] as VectorizeResult?;
              return EditorScreen(
                projectId: extra?['projectId'] as String? ?? '',
                pieceId: extra?['pieceId'] as String? ?? '',
                initialResult: result,
                imagePath: extra?['imagePath'] as String?,
              );
            },
          ),
        ],
      ),

      // =====================
      // EDITOR FLOW
      // =====================
      GoRoute(
        path: '/editor/:projectId',
        name: 'editor',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          final extra = state.extra as Map<String, dynamic>?;
          return EditorScreen(
            projectId: projectId,
            pieceId: extra?['pieceId'] as String? ?? '',
            initialResult: extra?['result'] as VectorizeResult?,
            imagePath: extra?['imagePath'] as String?,
          );
        },
      ),

      // =====================
      // ERROR SCREENS
      // =====================
      GoRoute(
        path: '/error/vectorization',
        name: 'error-vectorization',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return VectorizationErrorScreen(
            errorCode: extra?['errorCode'] as String?,
            errorMessage: extra?['errorMessage'] as String?,
            imagePath: extra?['imagePath'] as String?,
            mode: extra?['mode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/error/network',
        name: 'error-network',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NetworkErrorScreen(
            imagePath: extra?['imagePath'] as String?,
            mode: extra?['mode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/error/low-confidence',
        name: 'error-low-confidence',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return LowConfidenceScreen(
            confidenceScore: extra?['confidenceScore'] as double? ?? 0.5,
            projectId: extra?['projectId'] as String?,
            imagePath: extra?['imagePath'] as String?,
            mode: extra?['mode'] as String?,
          );
        },
      ),
      GoRoute(
        path: '/error/no-reference',
        name: 'error-no-reference',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return NoReferenceScreen(
            imagePath: extra?['imagePath'] as String?,
            mode: extra?['mode'] as String?,
            projectId: extra?['projectId'] as String?,
          );
        },
      ),

      // =====================
      // PROJECTOR FLOW
      // =====================
      GoRoute(
        path: '/projector/:projectId',
        name: 'projector',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return ProjectorScreen(projectId: projectId);
        },
        routes: [
          GoRoute(
            path: 'calibrate',
            name: 'projector-calibrate',
            builder: (context, state) {
              final projectId = state.pathParameters['projectId'] ?? '';
              return CalibrationWizardScreen(projectId: projectId);
            },
          ),
          GoRoute(
            path: 'remote',
            name: 'projector-remote',
            builder: (context, state) =>
                const _PlaceholderScreen(name: 'Remote Control'),
          ),
        ],
      ),
      GoRoute(
        path: '/cast',
        name: 'cast',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'Cast Picker'),
      ),

      // =====================
      // LIBRARY & EXPORT
      // =====================
      GoRoute(
        path: '/search',
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const AllProjectsScreen(),
      ),
      GoRoute(
        path: '/export',
        name: 'export',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'Export / Share'),
        routes: [
          GoRoute(
            path: 'pdf',
            name: 'export-pdf',
            builder: (context, state) =>
                const _PlaceholderScreen(name: 'Export to PDF'),
          ),
          GoRoute(
            path: 'svg',
            name: 'export-svg',
            builder: (context, state) =>
                const _PlaceholderScreen(name: 'Export to SVG'),
          ),
        ],
      ),
      GoRoute(
        path: '/project/:projectId',
        name: 'project',
        builder: (context, state) {
          final projectId = state.pathParameters['projectId'] ?? '';
          return ProjectDetailScreen(projectId: projectId);
        },
      ),

      // =====================
      // SETTINGS & SUPPORT
      // =====================
      GoRoute(
        path: '/subscription',
        name: 'subscription',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'Subscription'),
        routes: [
          GoRoute(
            path: 'manage',
            name: 'subscription-manage',
            builder: (context, state) =>
                const _PlaceholderScreen(name: 'Manage Subscription'),
          ),
        ],
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const _PlaceholderScreen(name: 'Profile'),
      ),
      GoRoute(
        path: '/privacy',
        name: 'privacy',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'Privacy & Data'),
      ),
      GoRoute(
        path: '/about',
        name: 'about',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'About TraceCast'),
      ),

      // =====================
      // DEBUG
      // =====================
      GoRoute(
        path: '/debug',
        name: 'debug',
        builder: (context, state) => const DebugScreen(),
      ),

      GoRoute(
        path: '/help',
        name: 'help',
        builder: (context, state) =>
            const _PlaceholderScreen(name: 'Help & Support'),
        routes: [
          GoRoute(
            path: 'faq',
            name: 'help-faq',
            builder: (context, state) => const _PlaceholderScreen(name: 'FAQ'),
          ),
          GoRoute(
            path: 'contact',
            name: 'help-contact',
            builder: (context, state) =>
                const _PlaceholderScreen(name: 'Contact Support'),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _PlaceholderScreen(
      name: 'Error: ${state.error}',
    ),
  );
});

/// Temporary placeholder screen for routes not yet implemented
class _PlaceholderScreen extends StatelessWidget {
  const _PlaceholderScreen({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.construction,
              size: 64,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Coming soon...',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
