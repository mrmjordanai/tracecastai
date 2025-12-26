import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Secure storage service for sensitive data and preferences
///
/// Uses flutter_secure_storage for sensitive data (tokens, keys)
/// and SharedPreferences for non-sensitive preferences.
class StorageService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  SharedPreferences? _prefs;

  /// Initialize SharedPreferences
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Secure storage methods (for sensitive data)

  /// Store sensitive string securely
  Future<void> setSecureString(String key, String value) async {
    await _secureStorage.write(key: key, value: value);
  }

  /// Get sensitive string from secure storage
  Future<String?> getSecureString(String key) async {
    return await _secureStorage.read(key: key);
  }

  /// Delete sensitive string from secure storage
  Future<void> deleteSecureString(String key) async {
    await _secureStorage.delete(key: key);
  }

  /// Clear all secure storage
  Future<void> clearSecureStorage() async {
    await _secureStorage.deleteAll();
  }

  // SharedPreferences methods (for non-sensitive data)

  /// Store string in preferences
  Future<bool> setString(String key, String value) async {
    return await _prefs?.setString(key, value) ?? false;
  }

  /// Get string from preferences
  String? getString(String key) {
    return _prefs?.getString(key);
  }

  /// Store int in preferences
  Future<bool> setInt(String key, int value) async {
    return await _prefs?.setInt(key, value) ?? false;
  }

  /// Get int from preferences
  int? getInt(String key) {
    return _prefs?.getInt(key);
  }

  /// Store bool in preferences
  Future<bool> setBool(String key, bool value) async {
    return await _prefs?.setBool(key, value) ?? false;
  }

  /// Get bool from preferences
  bool? getBool(String key) {
    return _prefs?.getBool(key);
  }

  /// Store double in preferences
  Future<bool> setDouble(String key, double value) async {
    return await _prefs?.setDouble(key, value) ?? false;
  }

  /// Get double from preferences
  double? getDouble(String key) {
    return _prefs?.getDouble(key);
  }

  /// Remove key from preferences
  Future<bool> remove(String key) async {
    return await _prefs?.remove(key) ?? false;
  }

  /// Clear all preferences
  Future<bool> clearPreferences() async {
    return await _prefs?.clear() ?? false;
  }

  // Convenience methods for common operations

  /// Check if user has completed onboarding
  bool get hasCompletedOnboarding => getBool('onboarding_completed') ?? false;

  /// Set onboarding completed
  Future<void> setOnboardingCompleted(bool value) async {
    await setBool('onboarding_completed', value);
  }

  /// Get user's preferred units
  String get preferredUnits => getString('preferred_units') ?? 'in';

  /// Set user's preferred units
  Future<void> setPreferredUnits(String units) async {
    await setString('preferred_units', units);
  }

  /// Get default line width in mm
  double get defaultLineWidth => getDouble('default_line_width') ?? 1.2;

  /// Set default line width in mm
  Future<void> setDefaultLineWidth(double width) async {
    await setDouble('default_line_width', width);
  }

  /// Get haptic feedback preference
  bool get hapticFeedbackEnabled => getBool('haptic_feedback') ?? true;

  /// Set haptic feedback preference
  Future<void> setHapticFeedbackEnabled(bool enabled) async {
    await setBool('haptic_feedback', enabled);
  }
}
