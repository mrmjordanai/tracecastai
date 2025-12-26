import 'package:flutter/material.dart';
import '../../app/theme/blueprint_colors.dart';
import '../../core/services/camera_service.dart';

/// CameraPermissionGate - Handles camera permission flow
///
/// Wraps child content and shows permission UI when camera access is needed.
/// Provides clear guidance for all permission states including:
/// - Initial request
/// - Denied (can retry)
/// - Permanently denied (open settings)
/// - Restricted (device policy)
class CameraPermissionGate extends StatefulWidget {
  const CameraPermissionGate({
    super.key,
    required this.onPermissionGranted,
    this.title = 'Camera Access Required',
    this.description =
        'TraceCast needs camera access to scan your patterns. Your photos are processed securely.',
  });

  /// Called when permission is granted
  final VoidCallback onPermissionGranted;

  /// Title shown in permission UI
  final String title;

  /// Description shown in permission UI
  final String description;

  @override
  State<CameraPermissionGate> createState() => _CameraPermissionGateState();
}

class _CameraPermissionGateState extends State<CameraPermissionGate> {
  final CameraService _cameraService = CameraService();
  CameraPermissionResult? _permissionStatus;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    setState(() => _isLoading = true);

    final status = await _cameraService.checkPermission();

    setState(() {
      _permissionStatus = status;
      _isLoading = false;
    });

    if (status == CameraPermissionResult.granted) {
      widget.onPermissionGranted();
    }
  }

  Future<void> _requestPermission() async {
    setState(() => _isLoading = true);

    final status = await _cameraService.requestPermission();

    setState(() {
      _permissionStatus = status;
      _isLoading = false;
    });

    if (status == CameraPermissionResult.granted) {
      widget.onPermissionGranted();
    }
  }

  Future<void> _openSettings() async {
    await _cameraService.openSettings();
    // Check again after returning from settings
    _checkPermission();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: BlueprintColors.primaryForeground,
        ),
      );
    }

    if (_permissionStatus == CameraPermissionResult.granted) {
      return const SizedBox.shrink();
    }

    return _buildPermissionUI();
  }

  Widget _buildPermissionUI() {
    final isPermanentlyDenied =
        _permissionStatus == CameraPermissionResult.permanentlyDenied;
    final isRestricted = _permissionStatus == CameraPermissionResult.restricted;

    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: BlueprintColors.surfaceOverlay,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPermanentlyDenied || isRestricted
                  ? Icons.camera_alt_outlined
                  : Icons.camera_alt,
              size: 40,
              color: BlueprintColors.primaryForeground,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            widget.title,
            style: const TextStyle(
              color: BlueprintColors.primaryForeground,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            widget.description,
            style: const TextStyle(
              color: BlueprintColors.secondaryForeground,
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          if (isRestricted) ...[
            _buildInfoCard(
              icon: Icons.info_outline,
              message:
                  'Camera access is restricted by your device policy. Contact your administrator.',
            ),
          ] else if (isPermanentlyDenied) ...[
            _buildInfoCard(
              icon: Icons.settings,
              message:
                  'Camera permission was denied. Please enable it in Settings to continue.',
            ),
            const SizedBox(height: 16),
            _buildPrimaryButton(
              label: 'Open Settings',
              icon: Icons.settings,
              onPressed: _openSettings,
            ),
          ] else ...[
            _buildPrimaryButton(
              label: 'Enable Camera',
              icon: Icons.camera_alt,
              onPressed: _requestPermission,
            ),
          ],
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Maybe Later',
              style: TextStyle(
                color: BlueprintColors.secondaryForeground,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String message}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BlueprintColors.surfaceOverlay,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: BlueprintColors.warningState,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: BlueprintColors.secondaryForeground,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: BlueprintColors.primaryForeground,
          foregroundColor: BlueprintColors.primaryBackground,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
