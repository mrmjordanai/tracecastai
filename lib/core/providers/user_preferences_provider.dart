import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/storage_service.dart';
import 'service_providers.dart';

/// User preferences for app settings
class UserPreferences {
  final String measurementUnit; // 'mm', 'inches'
  final String defaultPatternMode; // 'sewing', 'quilting', 'stencil', 'maker'
  final bool hasGridMat;
  final bool hasProjector;
  final bool showOnboardingTips;
  final bool enableHaptics;
  final double projectorScaleAdjustment;
  final String? lastUsedProjectorId;

  const UserPreferences({
    this.measurementUnit = 'mm',
    this.defaultPatternMode = 'sewing',
    this.hasGridMat = false,
    this.hasProjector = false,
    this.showOnboardingTips = true,
    this.enableHaptics = true,
    this.projectorScaleAdjustment = 1.0,
    this.lastUsedProjectorId,
  });

  UserPreferences copyWith({
    String? measurementUnit,
    String? defaultPatternMode,
    bool? hasGridMat,
    bool? hasProjector,
    bool? showOnboardingTips,
    bool? enableHaptics,
    double? projectorScaleAdjustment,
    String? lastUsedProjectorId,
  }) {
    return UserPreferences(
      measurementUnit: measurementUnit ?? this.measurementUnit,
      defaultPatternMode: defaultPatternMode ?? this.defaultPatternMode,
      hasGridMat: hasGridMat ?? this.hasGridMat,
      hasProjector: hasProjector ?? this.hasProjector,
      showOnboardingTips: showOnboardingTips ?? this.showOnboardingTips,
      enableHaptics: enableHaptics ?? this.enableHaptics,
      projectorScaleAdjustment:
          projectorScaleAdjustment ?? this.projectorScaleAdjustment,
      lastUsedProjectorId: lastUsedProjectorId ?? this.lastUsedProjectorId,
    );
  }
}

/// User preferences notifier
class UserPreferencesNotifier extends StateNotifier<UserPreferences> {
  final StorageService _storage;

  UserPreferencesNotifier(this._storage) : super(const UserPreferences());

  /// Load preferences from storage
  Future<void> load() async {
    try {
      final unit = _storage.getString('measurementUnit');
      final mode = _storage.getString('defaultPatternMode');
      final hasGrid = _storage.getBool('hasGridMat');
      final hasProj = _storage.getBool('hasProjector');
      final tips = _storage.getBool('showOnboardingTips');
      final haptics = _storage.getBool('enableHaptics');
      final scale = _storage.getDouble('projectorScaleAdjustment');
      final projId = _storage.getString('lastUsedProjectorId');

      state = UserPreferences(
        measurementUnit: unit ?? 'mm',
        defaultPatternMode: mode ?? 'sewing',
        hasGridMat: hasGrid ?? false,
        hasProjector: hasProj ?? false,
        showOnboardingTips: tips ?? true,
        enableHaptics: haptics ?? true,
        projectorScaleAdjustment: scale ?? 1.0,
        lastUsedProjectorId: projId,
      );
    } catch (e) {
      // Use defaults on error
    }
  }

  /// Update measurement unit
  Future<void> setMeasurementUnit(String unit) async {
    await _storage.setString('measurementUnit', unit);
    state = state.copyWith(measurementUnit: unit);
  }

  /// Update default pattern mode
  Future<void> setDefaultPatternMode(String mode) async {
    await _storage.setString('defaultPatternMode', mode);
    state = state.copyWith(defaultPatternMode: mode);
  }

  /// Update grid mat status
  Future<void> setHasGridMat(bool hasGrid) async {
    await _storage.setBool('hasGridMat', hasGrid);
    state = state.copyWith(hasGridMat: hasGrid);
  }

  /// Update projector status
  Future<void> setHasProjector(bool hasProjector) async {
    await _storage.setBool('hasProjector', hasProjector);
    state = state.copyWith(hasProjector: hasProjector);
  }

  /// Toggle onboarding tips
  Future<void> setShowOnboardingTips(bool show) async {
    await _storage.setBool('showOnboardingTips', show);
    state = state.copyWith(showOnboardingTips: show);
  }

  /// Toggle haptic feedback
  Future<void> setEnableHaptics(bool enable) async {
    await _storage.setBool('enableHaptics', enable);
    state = state.copyWith(enableHaptics: enable);
  }

  /// Set projector scale adjustment
  Future<void> setProjectorScaleAdjustment(double scale) async {
    await _storage.setDouble('projectorScaleAdjustment', scale);
    state = state.copyWith(projectorScaleAdjustment: scale);
  }

  /// Set last used projector
  Future<void> setLastUsedProjectorId(String? id) async {
    if (id != null) {
      await _storage.setString('lastUsedProjectorId', id);
    }
    state = state.copyWith(lastUsedProjectorId: id);
  }
}

/// User preferences provider
final userPreferencesProvider =
    StateNotifierProvider<UserPreferencesNotifier, UserPreferences>((ref) {
  final storage = ref.watch(storageServiceProvider);
  return UserPreferencesNotifier(storage);
});

/// Measurement unit convenience provider
final measurementUnitProvider = Provider<String>((ref) {
  return ref.watch(userPreferencesProvider).measurementUnit;
});

/// Has projector convenience provider
final hasProjectorProvider = Provider<bool>((ref) {
  return ref.watch(userPreferencesProvider).hasProjector;
});
