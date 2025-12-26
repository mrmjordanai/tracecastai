import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/reference_detection_service.dart';
import '../../../core/services/reference_sheet_service.dart';
import '../../../platform_channels/reference_detection_channel.dart';

/// Debug screen for testing reference detection and calibration features.
///
/// Provides tools to:
/// - Check platform channel availability
/// - Test reference detection
/// - Print reference sheets
/// - View latency metrics
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  bool _isCheckingChannels = false;
  bool _isPlatformChannelAvailable = false;
  String _platformChannelStatus = 'Not checked';

  bool _isTestingDetection = false;
  String _detectionResult = 'No test run';

  bool _isPrintingSheet = false;

  final _referenceSheetService = ReferenceSheetService();

  @override
  void initState() {
    super.initState();
    _checkPlatformChannels();
  }

  Future<void> _checkPlatformChannels() async {
    setState(() {
      _isCheckingChannels = true;
      _platformChannelStatus = 'Checking...';
    });

    try {
      // Test the platform channel by calling the static method
      final isAvailable = await ReferenceDetectionChannel.isAvailable();

      setState(() {
        _isPlatformChannelAvailable = isAvailable;
        _platformChannelStatus = isAvailable
            ? '✅ Available (${Platform.isIOS ? "iOS" : "Android"})'
            : '❌ Not available';
      });
    } on PlatformException catch (e) {
      setState(() {
        _isPlatformChannelAvailable = false;
        _platformChannelStatus = '❌ Error: ${e.message}';
      });
    } catch (e) {
      setState(() {
        _isPlatformChannelAvailable = false;
        _platformChannelStatus = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isCheckingChannels = false;
      });
    }
  }

  Future<void> _testDetection() async {
    setState(() {
      _isTestingDetection = true;
      _detectionResult = 'Running detection test...';
    });

    try {
      final service = ReferenceDetectionService();

      // Create a simple test with mock data
      final stopwatch = Stopwatch()..start();

      // Test manual scale creation (doesn't require camera)
      final manualResult = service.createManualScale(
        knownDimensionMm: 100,
        measuredPixels: 400,
      );

      stopwatch.stop();

      final scale = manualResult.scaleMmPerPx ?? 0.0;

      setState(() {
        _detectionResult = '''
✅ Detection service operational

Manual Scale Test:
- Scale: ${scale.toStringAsFixed(4)} mm/px
- Type: ${manualResult.type.name}
- Confidence: ${(manualResult.confidence * 100).toStringAsFixed(1)}%

Platform Channel: $_platformChannelStatus
Latency: ${stopwatch.elapsedMilliseconds}ms
''';
      });
    } catch (e) {
      setState(() {
        _detectionResult = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isTestingDetection = false;
      });
    }
  }

  Future<void> _printReferenceSheet() async {
    setState(() {
      _isPrintingSheet = true;
    });

    try {
      await _referenceSheetService.printReferenceSheet();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reference sheet sent to printer')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPrintingSheet = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _checkPlatformChannels,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Platform Channel Status
          _buildSection(
            title: 'Platform Channel Status',
            icon:
                _isPlatformChannelAvailable ? Icons.check_circle : Icons.error,
            iconColor: _isPlatformChannelAvailable ? Colors.green : Colors.red,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _platformChannelStatus,
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Platform: ${Platform.operatingSystem}',
                  style: theme.textTheme.bodySmall,
                ),
                if (_isCheckingChannels)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: LinearProgressIndicator(),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Detection Test
          _buildSection(
            title: 'Reference Detection',
            icon: Icons.qr_code_scanner,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _detectionResult,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFamily: 'monospace',
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isTestingDetection ? null : _testDetection,
                  icon: _isTestingDetection
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.play_arrow),
                  label: Text(_isTestingDetection ? 'Testing...' : 'Run Test'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Reference Sheet Printing
          _buildSection(
            title: 'Reference Sheet',
            icon: Icons.print,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Generate and print a reference sheet with calibration markers.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'The sheet contains:\n'
                  '• 4 corner markers (85.6mm square)\n'
                  '• Ruler marks at 10mm intervals\n'
                  '• Usage instructions',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _isPrintingSheet ? null : _printReferenceSheet,
                  icon: _isPrintingSheet
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.print),
                  label: Text(_isPrintingSheet ? 'Printing...' : 'Print Sheet'),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Detection Types Info
          _buildSection(
            title: 'Supported Detection Types',
            icon: Icons.info_outline,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetectionType(
                  'ArUco Markers',
                  'Highest accuracy (±0.5%)',
                  Icons.qr_code,
                ),
                const Divider(),
                _buildDetectionType(
                  'Grid / Cutting Mat',
                  'Good accuracy (±1%)',
                  Icons.grid_on,
                ),
                const Divider(),
                _buildDetectionType(
                  'Credit Card',
                  'Moderate accuracy (±2%)',
                  Icons.credit_card,
                ),
                const Divider(),
                _buildDetectionType(
                  'Manual Input',
                  'User-defined scale',
                  Icons.edit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget child,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor ?? theme.colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const Divider(),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildDetectionType(String name, String accuracy, IconData icon) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: theme.textTheme.bodyMedium),
                Text(
                  accuracy,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
