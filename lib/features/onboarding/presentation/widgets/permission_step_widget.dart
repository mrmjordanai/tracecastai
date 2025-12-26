import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../app/theme/blueprint_colors.dart';
import '../../../../core/providers/onboarding_provider.dart';

/// PermissionStepWidget - Request OS permissions
/// Screens 13, 16: Notifications and Camera permission requests
class PermissionStepWidget extends StatefulWidget {
  final OnboardingStepDefinition step;
  final Permission permissionType;
  final void Function(bool granted) onPermissionResult;
  final VoidCallback? onSkip;
  final VoidCallback? onBack;

  const PermissionStepWidget({
    super.key,
    required this.step,
    required this.permissionType,
    required this.onPermissionResult,
    this.onSkip,
    this.onBack,
  });

  @override
  State<PermissionStepWidget> createState() => _PermissionStepWidgetState();
}

class _PermissionStepWidgetState extends State<PermissionStepWidget> {
  bool _isRequesting = false;

  IconData get _icon {
    if (widget.permissionType == Permission.camera) {
      return Icons.camera_alt;
    } else if (widget.permissionType == Permission.notification) {
      return Icons.notifications;
    }
    return Icons.security;
  }

  String get _rationale {
    if (widget.permissionType == Permission.camera) {
      return 'TraceCast uses your camera to capture and digitize patterns. This is required to scan patterns.';
    } else if (widget.permissionType == Permission.notification) {
      return 'Get notified when your patterns are ready, and receive tips for better results.';
    }
    return 'This permission helps TraceCast work better for you.';
  }

  String get _buttonLabel {
    if (widget.permissionType == Permission.camera) {
      return 'Enable Camera';
    } else if (widget.permissionType == Permission.notification) {
      return 'Enable Notifications';
    }
    return 'Enable Permission';
  }

  @override
  void initState() {
    super.initState();
    _checkCurrentStatus();
  }

  Future<void> _checkCurrentStatus() async {
    final status = await widget.permissionType.status;

    // If already granted, auto-advance
    if (status.isGranted) {
      widget.onPermissionResult(true);
    }
  }

  Future<void> _requestPermission() async {
    setState(() {
      _isRequesting = true;
    });

    final status = await widget.permissionType.request();

    setState(() {
      _isRequesting = false;
    });

    if (status.isGranted) {
      widget.onPermissionResult(true);
    } else if (status.isPermanentlyDenied) {
      // Show settings dialog
      if (mounted) {
        _showSettingsDialog();
      }
    } else {
      widget.onPermissionResult(false);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Permission Required'),
        content: Text(
          'Please enable ${widget.permissionType == Permission.camera ? 'camera' : 'notification'} access in Settings to continue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              openAppSettings();
            },
            child: const Text('Open Settings'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          // Header with back button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (widget.onBack != null)
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                const Spacer(),
              ],
            ),
          ),

          const Spacer(flex: 1),

          // Icon
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: BlueprintColors.surfaceOverlay,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Center(
              child: Icon(
                _icon,
                size: 56,
                color: BlueprintColors.primaryForeground,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                Text(
                  widget.step.title,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (widget.step.subtitle != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    widget.step.subtitle!,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white.withValues(alpha: 0.7),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Rationale
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BlueprintColors.surfaceOverlay,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: BlueprintColors.secondaryForeground,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _rationale,
                      style: TextStyle(
                        color: BlueprintColors.secondaryForeground,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Spacer(flex: 2),

          // Request button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isRequesting ? null : _requestPermission,
                style: ElevatedButton.styleFrom(
                  backgroundColor: BlueprintColors.primaryForeground,
                  foregroundColor: BlueprintColors.primaryBackground,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isRequesting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            BlueprintColors.primaryBackground,
                          ),
                        ),
                      )
                    : Text(
                        _buttonLabel,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ),

          // Skip button (if allowed)
          if (widget.onSkip != null) ...[
            const SizedBox(height: 16),
            TextButton(
              onPressed: widget.onSkip,
              child: Text(
                'Maybe later',
                style: TextStyle(
                  color: BlueprintColors.secondaryForeground,
                  fontSize: 16,
                ),
              ),
            ),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
