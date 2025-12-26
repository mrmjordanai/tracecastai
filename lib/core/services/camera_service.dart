import 'dart:async';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// CameraService - Handles camera initialization and permission management
///
/// Provides a unified interface for:
/// - Camera permission requests
/// - Camera initialization and disposal
/// - Device camera enumeration
/// - Capture operations
class CameraService {
  static List<CameraDescription>? _availableCameras;
  CameraController? _controller;

  /// Get the current camera controller
  CameraController? get controller => _controller;

  /// Check if camera is initialized and ready
  bool get isReady => _controller?.value.isInitialized ?? false;

  /// Get available cameras (cached after first call)
  Future<List<CameraDescription>> getAvailableCameras() async {
    if (_availableCameras != null) return _availableCameras!;

    try {
      _availableCameras = await availableCameras();
      return _availableCameras!;
    } catch (e) {
      debugPrint('Error getting cameras: $e');
      return [];
    }
  }

  /// Request camera permission
  Future<CameraPermissionResult> requestPermission() async {
    final status = await Permission.camera.request();

    return switch (status) {
      PermissionStatus.granted => CameraPermissionResult.granted,
      PermissionStatus.denied => CameraPermissionResult.denied,
      PermissionStatus.permanentlyDenied =>
        CameraPermissionResult.permanentlyDenied,
      PermissionStatus.restricted => CameraPermissionResult.restricted,
      PermissionStatus.limited => CameraPermissionResult.limited,
      PermissionStatus.provisional => CameraPermissionResult.granted,
    };
  }

  /// Check current camera permission status
  Future<CameraPermissionResult> checkPermission() async {
    final status = await Permission.camera.status;

    return switch (status) {
      PermissionStatus.granted => CameraPermissionResult.granted,
      PermissionStatus.denied => CameraPermissionResult.denied,
      PermissionStatus.permanentlyDenied =>
        CameraPermissionResult.permanentlyDenied,
      PermissionStatus.restricted => CameraPermissionResult.restricted,
      PermissionStatus.limited => CameraPermissionResult.limited,
      PermissionStatus.provisional => CameraPermissionResult.granted,
    };
  }

  /// Open app settings (for when permission is permanently denied)
  Future<bool> openSettings() async {
    return await openAppSettings();
  }

  /// Initialize camera with specified description and resolution
  Future<CameraInitResult> initializeCamera({
    CameraDescription? camera,
    ResolutionPreset resolution = ResolutionPreset.high,
    bool enableAudio = false,
  }) async {
    try {
      // Dispose existing controller if any
      await dispose();

      // Get cameras if not specified
      final cameras = await getAvailableCameras();
      if (cameras.isEmpty) {
        return CameraInitResult.noCamerasAvailable;
      }

      // Use specified camera or default to back camera
      final selectedCamera = camera ??
          cameras.firstWhere(
            (c) => c.lensDirection == CameraLensDirection.back,
            orElse: () => cameras.first,
          );

      _controller = CameraController(
        selectedCamera,
        resolution,
        enableAudio: enableAudio,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      await _controller!.initialize();

      // Lock focus and exposure for better quality
      if (_controller!.value.isInitialized) {
        await _controller!.setFocusMode(FocusMode.auto);
        await _controller!.setExposureMode(ExposureMode.auto);
      }

      return CameraInitResult.success;
    } on CameraException catch (e) {
      debugPrint('Camera init error: ${e.code} - ${e.description}');
      return _mapCameraException(e);
    } catch (e) {
      debugPrint('Camera init error: $e');
      return CameraInitResult.unknown;
    }
  }

  CameraInitResult _mapCameraException(CameraException e) {
    return switch (e.code) {
      'CameraAccessDenied' => CameraInitResult.permissionDenied,
      'CameraAccessDeniedWithoutPrompt' =>
        CameraInitResult.permissionPermanentlyDenied,
      'CameraAccessRestricted' => CameraInitResult.permissionRestricted,
      'AudioAccessDenied' => CameraInitResult.audioPermissionDenied,
      'AudioAccessDeniedWithoutPrompt' =>
        CameraInitResult.audioPermissionDenied,
      'AudioAccessRestricted' => CameraInitResult.audioPermissionDenied,
      _ => CameraInitResult.unknown,
    };
  }

  /// Take a photo and return the file path
  Future<String?> takePicture() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      debugPrint('Camera not initialized');
      return null;
    }

    if (_controller!.value.isTakingPicture) {
      debugPrint('Already taking a picture');
      return null;
    }

    try {
      final file = await _controller!.takePicture();
      return file.path;
    } on CameraException catch (e) {
      debugPrint('Take picture error: ${e.code} - ${e.description}');
      return null;
    }
  }

  /// Set focus point (normalized coordinates 0-1)
  Future<void> setFocusPoint(double x, double y) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setFocusPoint(Offset(x, y));
    } catch (e) {
      debugPrint('Set focus point error: $e');
    }
  }

  /// Set exposure point (normalized coordinates 0-1)
  Future<void> setExposurePoint(double x, double y) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      await _controller!.setExposurePoint(Offset(x, y));
    } catch (e) {
      debugPrint('Set exposure point error: $e');
    }
  }

  /// Toggle flash mode
  Future<FlashMode> toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return FlashMode.off;
    }

    final modes = [FlashMode.off, FlashMode.auto, FlashMode.always];
    final currentIndex = modes.indexOf(_controller!.value.flashMode);
    final nextMode = modes[(currentIndex + 1) % modes.length];

    try {
      await _controller!.setFlashMode(nextMode);
      return nextMode;
    } catch (e) {
      debugPrint('Toggle flash error: $e');
      return _controller!.value.flashMode;
    }
  }

  /// Set zoom level (1.0 = no zoom)
  Future<void> setZoom(double zoom) async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final maxZoom = await _controller!.getMaxZoomLevel();
      final minZoom = await _controller!.getMinZoomLevel();
      final clampedZoom = zoom.clamp(minZoom, maxZoom);
      await _controller!.setZoomLevel(clampedZoom);
    } catch (e) {
      debugPrint('Set zoom error: $e');
    }
  }

  /// Dispose camera resources
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }
}

/// Camera permission result states
enum CameraPermissionResult {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  limited,
}

/// Camera initialization result states
enum CameraInitResult {
  success,
  noCamerasAvailable,
  permissionDenied,
  permissionPermanentlyDenied,
  permissionRestricted,
  audioPermissionDenied,
  unknown,
}
