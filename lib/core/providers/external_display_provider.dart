import 'package:flutter_riverpod/flutter_riverpod.dart';

/// External display connection state
enum ExternalDisplayState {
  disconnected,
  connecting,
  connected,
  error,
}

/// External display type
enum ExternalDisplayType {
  none,
  airplay, // iOS: AirPlay to Apple TV / Mac
  chromecast, // Android: Chromecast
  hdmi, // Wired HDMI/USB-C
}

/// External display info
class ExternalDisplayInfo {
  final ExternalDisplayType type;
  final String? deviceName;
  final int? width;
  final int? height;

  const ExternalDisplayInfo({
    required this.type,
    this.deviceName,
    this.width,
    this.height,
  });
}

/// External display state container
class ExternalDisplayStateData {
  final ExternalDisplayState state;
  final ExternalDisplayInfo? displayInfo;
  final String? error;

  const ExternalDisplayStateData({
    this.state = ExternalDisplayState.disconnected,
    this.displayInfo,
    this.error,
  });

  bool get isConnected => state == ExternalDisplayState.connected;

  ExternalDisplayStateData copyWith({
    ExternalDisplayState? state,
    ExternalDisplayInfo? displayInfo,
    String? error,
  }) {
    return ExternalDisplayStateData(
      state: state ?? this.state,
      displayInfo: displayInfo ?? this.displayInfo,
      error: error,
    );
  }
}

/// External display notifier - manages projector/TV connections
class ExternalDisplayNotifier extends StateNotifier<ExternalDisplayStateData> {
  ExternalDisplayNotifier() : super(const ExternalDisplayStateData());

  /// Scan for available external displays
  Future<List<ExternalDisplayInfo>> scanForDisplays() async {
    // TODO: Implement platform channel for AirPlay (iOS) and Chromecast (Android)
    // For now, return empty list - actual implementation requires native code
    await Future.delayed(const Duration(seconds: 1));
    return [];
  }

  /// Connect to an external display
  Future<bool> connect(ExternalDisplayInfo display) async {
    state = state.copyWith(
      state: ExternalDisplayState.connecting,
      error: null,
    );

    try {
      // TODO: Implement platform channel for connection
      await Future.delayed(const Duration(seconds: 2));

      state = state.copyWith(
        state: ExternalDisplayState.connected,
        displayInfo: display,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        state: ExternalDisplayState.error,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Disconnect from external display
  Future<void> disconnect() async {
    // TODO: Implement platform channel for disconnection
    state = const ExternalDisplayStateData();
  }

  /// Send content to external display
  Future<void> sendToDisplay(List<dynamic> vectors, double scale) async {
    if (!state.isConnected) return;

    // TODO: Implement platform channel for rendering vectors
    // This will send vector data to the native side for display
  }
}

/// External display provider
final externalDisplayProvider =
    StateNotifierProvider<ExternalDisplayNotifier, ExternalDisplayStateData>(
        (ref) {
  return ExternalDisplayNotifier();
});

/// Is projector connected convenience provider
final isProjectorConnectedProvider = Provider<bool>((ref) {
  return ref.watch(externalDisplayProvider).isConnected;
});
