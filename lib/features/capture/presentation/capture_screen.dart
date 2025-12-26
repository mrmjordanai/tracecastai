import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../app/theme/blueprint_colors.dart';
import '../../../core/services/reference_detection_service.dart';
import 'widgets/reticle_overlay.dart';

/// Camera capture screen for taking pattern photos
class CaptureScreen extends ConsumerStatefulWidget {
  final String mode; // sewing, quilting, stencil, maker

  const CaptureScreen({
    super.key,
    required this.mode,
  });

  @override
  ConsumerState<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends ConsumerState<CaptureScreen> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isCapturing = false;
  String? _error;
  bool _isReferenceDetected = false;
  ReferenceDetectionResult? _detectionResult;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        setState(() {
          _error = 'No cameras available';
        });
        return;
      }

      // Use the first back camera
      final backCamera = _cameras!.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => _cameras!.first,
      );

      _controller = CameraController(
        backCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Camera error: $e';
      });
    }
  }

  Future<void> _capturePhoto() async {
    if (_controller == null || !_isInitialized || _isCapturing) return;

    setState(() {
      _isCapturing = true;
    });

    try {
      // Capture the photo
      final XFile photo = await _controller!.takePicture();

      // Save to temp directory with unique name
      final tempDir = await getTemporaryDirectory();
      final fileName = '${const Uuid().v4()}.jpg';
      final savedPath = '${tempDir.path}/$fileName';

      // Copy file to temp location
      await File(photo.path).copy(savedPath);

      if (mounted) {
        // Navigate to analysis screen
        // The projectId would typically come from creating a new project
        // For now, we'll use a temporary ID
        final projectId = const Uuid().v4();
        context.push(
          '/analysis/$projectId',
          extra: {
            'imagePath': savedPath,
            'mode': widget.mode,
          },
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to capture: $e'),
            backgroundColor: BlueprintColors.errorState,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCapturing = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera preview
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: CameraPreview(_controller!),
            ),
          // Technical reticle overlay (shown on top of camera)
          if (_isInitialized && _controller != null)
            Positioned.fill(
              child: IgnorePointer(
                child: ReticleOverlay(
                  isReferenceDetected: _isReferenceDetected,
                  detectionResult: _detectionResult,
                  onReferenceDetectionChanged: (detected) {
                    setState(() {
                      _isReferenceDetected = detected;
                    });
                  },
                ),
              ),
            ),
          // Error state
          if (_error != null)
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white54,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Colors.white54),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          // Loading indicator (when camera is initializing)
          if (!_isInitialized && _error == null)
            const Center(
              child: CircularProgressIndicator(
                color: BlueprintColors.primaryForeground,
              ),
            ),

          // Top bar with close button
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        widget.mode.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48), // Balance the close button
                  ],
                ),
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Hint text
                    const Text(
                      'Position pattern within view and tap to capture',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    // Capture button - using MagicButton style
                    Semantics(
                      button: true,
                      enabled: !_isCapturing,
                      label: _isCapturing
                          ? 'Capturing photo, please wait'
                          : 'Capture photo',
                      hint: 'Double tap to take a photo of the pattern',
                      child: GestureDetector(
                        onTap: _isCapturing ? null : _capturePhoto,
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isCapturing ? Colors.white54 : Colors.white,
                            border: Border.all(
                              color: Colors.white,
                              width: 4,
                            ),
                          ),
                          child: _isCapturing
                              ? const Padding(
                                  padding: EdgeInsets.all(20),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.black54,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
