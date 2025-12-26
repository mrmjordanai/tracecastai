import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:camera/camera.dart';
import '../services/camera_service.dart';
import 'service_providers.dart';

/// Capture state for the camera/scanning flow
class CaptureState {
  final CameraController? controller;
  final bool isInitializing;
  final bool isCameraReady;
  final bool isCapturing;
  final String? capturedImagePath;
  final String? error;
  final FlashMode flashMode;
  final double zoomLevel;
  final bool showGrid;

  const CaptureState({
    this.controller,
    this.isInitializing = false,
    this.isCameraReady = false,
    this.isCapturing = false,
    this.capturedImagePath,
    this.error,
    this.flashMode = FlashMode.off,
    this.zoomLevel = 1.0,
    this.showGrid = true,
  });

  CaptureState copyWith({
    CameraController? controller,
    bool? isInitializing,
    bool? isCameraReady,
    bool? isCapturing,
    String? capturedImagePath,
    String? error,
    FlashMode? flashMode,
    double? zoomLevel,
    bool? showGrid,
  }) {
    return CaptureState(
      controller: controller ?? this.controller,
      isInitializing: isInitializing ?? this.isInitializing,
      isCameraReady: isCameraReady ?? this.isCameraReady,
      isCapturing: isCapturing ?? this.isCapturing,
      capturedImagePath: capturedImagePath ?? this.capturedImagePath,
      error: error,
      flashMode: flashMode ?? this.flashMode,
      zoomLevel: zoomLevel ?? this.zoomLevel,
      showGrid: showGrid ?? this.showGrid,
    );
  }
}

/// Capture notifier - manages camera and capture state
class CaptureNotifier extends StateNotifier<CaptureState> {
  final CameraService _cameraService;

  CaptureNotifier(this._cameraService) : super(const CaptureState());

  /// Initialize camera
  Future<void> initializeCamera() async {
    state = state.copyWith(isInitializing: true, error: null);

    try {
      // Check permission first
      final permission = await _cameraService.requestPermission();
      if (permission != CameraPermissionResult.granted) {
        state = state.copyWith(
          isInitializing: false,
          error: 'Camera permission denied',
        );
        return;
      }

      // Initialize camera
      final result = await _cameraService.initializeCamera(
        resolution: ResolutionPreset.high,
      );

      if (result == CameraInitResult.success) {
        state = state.copyWith(
          controller: _cameraService.controller,
          isInitializing: false,
          isCameraReady: true,
        );
      } else {
        state = state.copyWith(
          isInitializing: false,
          error: 'Failed to initialize camera: ${result.name}',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isInitializing: false,
        error: e.toString(),
      );
    }
  }

  /// Capture a photo
  Future<String?> capturePhoto() async {
    if (!state.isCameraReady) return null;

    state = state.copyWith(isCapturing: true, error: null);

    try {
      final path = await _cameraService.takePicture();
      state = state.copyWith(
        isCapturing: false,
        capturedImagePath: path,
      );
      return path;
    } catch (e) {
      state = state.copyWith(
        isCapturing: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Toggle flash mode
  Future<void> toggleFlash() async {
    final newMode = await _cameraService.toggleFlash();
    state = state.copyWith(flashMode: newMode);
  }

  /// Set zoom level
  Future<void> setZoom(double zoom) async {
    await _cameraService.setZoom(zoom);
    state = state.copyWith(zoomLevel: zoom);
  }

  /// Toggle alignment grid
  void toggleGrid() {
    state = state.copyWith(showGrid: !state.showGrid);
  }

  /// Clear captured image to retake
  void clearCapture() {
    state = state.copyWith(capturedImagePath: null);
  }

  /// Dispose camera resources
  Future<void> disposeCamera() async {
    await _cameraService.dispose();
    state = const CaptureState();
  }
}

/// Capture provider
final captureProvider =
    StateNotifierProvider<CaptureNotifier, CaptureState>((ref) {
  final cameraService = ref.watch(cameraServiceProvider);
  return CaptureNotifier(cameraService);
});

/// Camera ready convenience provider
final isCameraReadyProvider = Provider<bool>((ref) {
  return ref.watch(captureProvider).isCameraReady;
});

/// Captured image path provider
final capturedImagePathProvider = Provider<String?>((ref) {
  return ref.watch(captureProvider).capturedImagePath;
});
