import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Remote config service for feature flags and A/B testing
///
/// Provides access to Firebase Remote Config values.
class RemoteConfigService {
  late final FirebaseRemoteConfig _remoteConfig;
  bool _initialized = false;

  /// Default values for remote config
  /// Model IDs verified at https://openrouter.ai/models (Dec 2024)
  static const Map<String, dynamic> _defaults = {
    // AI Vectorization settings
    'ai_primary_model': 'google/gemini-2.0-flash-001',
    'ai_fallback_model_1': 'google/gemini-1.5-flash',
    'ai_fallback_model_2': 'anthropic/claude-sonnet-4',
    'ai_fallback_model_3': 'openai/gpt-4o',
    'ai_timeout_ms': 30000,
    'ai_max_retries': 3,

    // Feature flags
    'enable_contrast_normalization': false,
    'show_beta_features': false,
    'enable_multi_piece_detection': false,

    // UI settings
    'show_confidence_badges': true,
    'min_confidence_warning': 0.6,

    // Rate limiting
    'max_scans_per_month_free': 5,
    'max_scans_per_month_pro': 9999,
  };

  /// Initialize remote config
  Future<void> initialize() async {
    _remoteConfig = FirebaseRemoteConfig.instance;
    await _remoteConfig.setDefaults(_defaults.map((k, v) => MapEntry(k, v)));
    await _remoteConfig.setConfigSettings(RemoteConfigSettings(
      fetchTimeout: const Duration(minutes: 1),
      minimumFetchInterval: const Duration(hours: 1),
    ));
    await _remoteConfig.fetchAndActivate();
    _initialized = true;
  }

  /// Get string value
  String getString(String key) {
    if (_initialized) {
      return _remoteConfig.getString(key);
    }
    return _defaults[key]?.toString() ?? '';
  }

  /// Get int value
  int getInt(String key) {
    if (_initialized) {
      return _remoteConfig.getInt(key);
    }
    return _defaults[key] as int? ?? 0;
  }

  /// Get bool value
  bool getBool(String key) {
    if (_initialized) {
      return _remoteConfig.getBool(key);
    }
    return _defaults[key] as bool? ?? false;
  }

  /// Get double value
  double getDouble(String key) {
    if (_initialized) {
      return _remoteConfig.getDouble(key);
    }
    return (_defaults[key] as num?)?.toDouble() ?? 0.0;
  }

  // Convenience getters for common settings

  /// Primary AI model for vectorization
  String get aiPrimaryModel => getString('ai_primary_model');

  /// First fallback AI model
  String get aiFallbackModel1 => getString('ai_fallback_model_1');

  /// Second fallback AI model
  String get aiFallbackModel2 => getString('ai_fallback_model_2');

  /// Third fallback AI model
  String get aiFallbackModel3 => getString('ai_fallback_model_3');

  /// AI request timeout in milliseconds
  int get aiTimeoutMs => getInt('ai_timeout_ms');

  /// Maximum retry attempts
  int get aiMaxRetries => getInt('ai_max_retries');

  /// Whether to enable contrast normalization
  bool get enableContrastNormalization => getBool('enable_contrast_normalization');

  /// Whether to show beta features
  bool get showBetaFeatures => getBool('show_beta_features');

  /// Whether to enable multi-piece detection
  bool get enableMultiPieceDetection => getBool('enable_multi_piece_detection');

  /// Whether to show confidence badges
  bool get showConfidenceBadges => getBool('show_confidence_badges');

  /// Minimum confidence before showing warning
  double get minConfidenceWarning => getDouble('min_confidence_warning');

  /// Max scans per month for free users
  int get maxScansPerMonthFree => getInt('max_scans_per_month_free');

  /// Max scans per month for pro users
  int get maxScansPerMonthPro => getInt('max_scans_per_month_pro');
}
