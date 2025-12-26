import 'package:firebase_analytics/firebase_analytics.dart';

/// Analytics service wrapper for Firebase Analytics
///
/// Provides typed event logging and screen tracking.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  /// Log a custom event
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }

  /// Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }

  /// Set user ID for analytics
  Future<void> setUserId(String? userId) async {
    await _analytics.setUserId(id: userId);
  }

  /// Set user property
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    await _analytics.setUserProperty(name: name, value: value);
  }

  // Onboarding events
  Future<void> logOnboardingStepView(int stepIndex, String stepName) async {
    await logEvent(
      name: 'onboarding_step_view',
      parameters: {
        'step_index': stepIndex,
        'step_name': stepName,
      },
    );
  }

  Future<void> logOnboardingStepAction({
    required String stepId,
    required String action,
    dynamic value,
  }) async {
    await logEvent(
      name: 'onboarding_step_action',
      parameters: {
        'step_id': stepId,
        'action': action,
        if (value != null) 'value': value.toString(),
      },
    );
  }

  Future<void> logOnboardingComplete() async {
    await logEvent(name: 'onboarding_complete');
  }

  Future<void> logPaywallPlanSelect(String planId) async {
    await logEvent(
      name: 'paywall_plan_select',
      parameters: {'plan_id': planId},
    );
  }

  // Capture events
  Future<void> logCaptureStart(String mode) async {
    await logEvent(
      name: 'capture_start',
      parameters: {'mode': mode},
    );
  }

  Future<void> logCaptureComplete({
    required String mode,
    required int durationMs,
    required double confidence,
  }) async {
    await logEvent(
      name: 'capture_complete',
      parameters: {
        'mode': mode,
        'duration_ms': durationMs,
        'confidence': confidence,
      },
    );
  }

  // Vectorization events
  Future<void> logVectorizationStart() async {
    await logEvent(name: 'vectorization_start');
  }

  Future<void> logVectorizationComplete({
    required int durationMs,
    required double confidence,
    required String model,
  }) async {
    await logEvent(
      name: 'vectorization_complete',
      parameters: {
        'duration_ms': durationMs,
        'confidence': confidence,
        'model': model,
      },
    );
  }

  Future<void> logVectorizationFail({
    required String errorCode,
    required String model,
    required int retryCount,
  }) async {
    await logEvent(
      name: 'vectorization_fail',
      parameters: {
        'error_code': errorCode,
        'model': model,
        'retry_count': retryCount,
      },
    );
  }

  // Auth events
  Future<void> logAuthStart(String provider) async {
    await logEvent(
      name: 'auth_start',
      parameters: {'provider': provider},
    );
  }

  Future<void> logAuthSuccess(String provider) async {
    await logEvent(
      name: 'auth_success',
      parameters: {'provider': provider},
    );
  }

  Future<void> logAuthFail({
    required String provider,
    required String error,
  }) async {
    await logEvent(
      name: 'auth_fail',
      parameters: {
        'provider': provider,
        'error': error,
      },
    );
  }

  // Subscription events
  Future<void> logPaywallView({String source = 'onboarding'}) async {
    await logEvent(
      name: 'paywall_view',
      parameters: {'source': source},
    );
  }

  Future<void> logPurchaseStart(String productId) async {
    await logEvent(
      name: 'purchase_start',
      parameters: {'product_id': productId},
    );
  }

  Future<void> logPurchaseSuccess(String productId) async {
    await logEvent(
      name: 'purchase_success',
      parameters: {'product_id': productId},
    );
  }

  Future<void> logPurchaseFail({
    required String productId,
    required String error,
  }) async {
    await logEvent(
      name: 'purchase_fail',
      parameters: {
        'product_id': productId,
        'error': error,
      },
    );
  }

  // Projector events
  Future<void> logProjectorConnect(String connectionType) async {
    await logEvent(
      name: 'projector_connect',
      parameters: {'connection_type': connectionType},
    );
  }

  Future<void> logCalibrationComplete({
    required int attempts,
    required double adjustmentPercent,
  }) async {
    await logEvent(
      name: 'calibration_complete',
      parameters: {
        'attempts': attempts,
        'adjustment_percent': adjustmentPercent,
      },
    );
  }
}
