import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Connectivity state
enum ConnectivityStatus {
  online,
  offline,
  checking,
}

/// Connectivity notifier - monitors network status
class ConnectivityNotifier extends StateNotifier<ConnectivityStatus> {
  final Connectivity _connectivity;
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  ConnectivityNotifier({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity(),
        super(ConnectivityStatus.checking) {
    _init();
  }

  Future<void> _init() async {
    // Check initial status
    await checkConnectivity();

    // Listen for changes
    _subscription = _connectivity.onConnectivityChanged.listen(_onConnectivityChanged);
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // If any result is not 'none', we're online
    final hasConnection = results.any((r) => r != ConnectivityResult.none);
    state = hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
  }

  /// Manually check connectivity
  Future<bool> checkConnectivity() async {
    state = ConnectivityStatus.checking;
    try {
      final results = await _connectivity.checkConnectivity();
      final hasConnection = results.any((r) => r != ConnectivityResult.none);
      state = hasConnection ? ConnectivityStatus.online : ConnectivityStatus.offline;
      return hasConnection;
    } catch (e) {
      state = ConnectivityStatus.offline;
      return false;
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Connectivity provider
final connectivityProvider =
    StateNotifierProvider<ConnectivityNotifier, ConnectivityStatus>((ref) {
  return ConnectivityNotifier();
});

/// Simple boolean provider for offline checks
final isOnlineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityProvider);
  return status == ConnectivityStatus.online;
});

/// Provider that returns true when offline
final isOfflineProvider = Provider<bool>((ref) {
  final status = ref.watch(connectivityProvider);
  return status == ConnectivityStatus.offline;
});
