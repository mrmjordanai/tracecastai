/// Application-wide constants
class AppConstants {
  AppConstants._();

  /// App name
  static const String appName = 'TraceCast';

  /// App version (should match pubspec.yaml)
  static const String appVersion = '1.0.0';

  /// Minimum iOS version
  static const String minIOSVersion = '14.0';

  /// Minimum Android API level
  static const int minAndroidAPI = 24;

  /// Maximum image dimension before downsampling
  static const int maxImageDimension = 2048;

  /// JPEG quality for image processing
  static const int jpegQuality = 85;

  /// Minimum image dimension to accept
  static const int minImageDimension = 800;

  /// API timeout in seconds
  static const int apiTimeoutSeconds = 30;

  /// Maximum retry attempts
  static const int maxRetryAttempts = 3;

  /// Offline queue retry delays in milliseconds
  static const List<int> retryDelaysMs = [1000, 2000, 4000];

  /// Legal URLs
  static const String termsUrl = 'https://tracecast.app/terms';
  static const String privacyUrl = 'https://tracecast.app/privacy';
  static const String supportUrl = 'https://tracecast.app/support';
}

/// Pattern modes supported by the app
enum PatternMode {
  sewing('sewing', 'Sewing'),
  quilting('quilting', 'Quilting'),
  stencil('stencil', 'Stencil'),
  maker('maker', 'Maker'),
  custom('custom', 'Custom');

  const PatternMode(this.value, this.label);
  final String value;
  final String label;
}

/// Processing status for pieces
enum ProcessingStatus {
  pending('pending'),
  processing('processing'),
  complete('complete'),
  failed('failed');

  const ProcessingStatus(this.value);
  final String value;
}
