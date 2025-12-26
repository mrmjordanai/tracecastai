import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Platform channel for native ArUco and reference marker detection
///
/// This class provides the Flutter interface for calling native detection code
/// on iOS (Vision framework) and Android (ML Kit or OpenCV).
class ReferenceDetectionChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.jordansco.tracecast/reference_detection',
  );

  /// Check if native reference detection is available on this platform
  static Future<bool> isAvailable() async {
    try {
      final result = await _channel.invokeMethod<bool>('isAvailable');
      return result ?? false;
    } on PlatformException catch (e) {
      debugPrint('Reference detection availability check failed: ${e.message}');
      return false;
    } catch (e) {
      debugPrint('Unexpected error checking availability: $e');
      return false;
    }
  }

  /// Detect ArUco markers in an image
  ///
  /// [imageBytes] - The raw image bytes (JPEG or PNG)
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  ///
  /// Returns a map with:
  /// - 'detected': bool - Whether any markers were detected
  /// - 'markerIds': `List<int>` - IDs of detected markers
  /// - 'corners': `List<List<double>>` - Corner coordinates for each marker
  ///   Each corner set is [topLeftX, topLeftY, topRightX, topRightY,
  ///   bottomRightX, bottomRightY, bottomLeftX, bottomLeftY]
  /// - 'confidence': double - Detection confidence (0.0-1.0)
  /// - 'error': String? - Error message if detection failed
  static Future<Map<String, dynamic>> detectAruco({
    required Uint8List imageBytes,
    required int width,
    required int height,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'detectAruco',
        {
          'imageBytes': imageBytes,
          'width': width,
          'height': height,
        },
      );

      if (result == null) {
        return {
          'detected': false,
          'error': 'No result from native code',
        };
      }

      return _parseDetectionResult(result);
    } on PlatformException catch (e) {
      debugPrint('ArUco detection failed: ${e.message}');
      return {
        'detected': false,
        'error': e.message,
      };
    } catch (e) {
      debugPrint('Unexpected error during ArUco detection: $e');
      return {
        'detected': false,
        'error': e.toString(),
      };
    }
  }

  /// Detect grid lines (cutting mat) in an image
  ///
  /// [imageBytes] - The raw image bytes
  /// [width] - Image width in pixels
  /// [height] - Image height in pixels
  /// [gridSpacingMm] - Expected grid spacing in millimeters (default: 25.4 = 1 inch)
  ///
  /// Returns a map with:
  /// - 'detected': bool - Whether a grid pattern was detected
  /// - 'horizontalLines': `List<List<double>>` - Detected horizontal line endpoints
  /// - 'verticalLines': `List<List<double>>` - Detected vertical line endpoints
  /// - 'gridSpacingPx': double - Detected grid spacing in pixels
  /// - 'confidence': double - Detection confidence
  static Future<Map<String, dynamic>> detectGrid({
    required Uint8List imageBytes,
    required int width,
    required int height,
    double gridSpacingMm = 25.4,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'detectGrid',
        {
          'imageBytes': imageBytes,
          'width': width,
          'height': height,
          'gridSpacingMm': gridSpacingMm,
        },
      );

      if (result == null) {
        return {
          'detected': false,
          'error': 'No result from native code',
        };
      }

      return _parseDetectionResult(result);
    } on PlatformException catch (e) {
      debugPrint('Grid detection failed: ${e.message}');
      return {
        'detected': false,
        'error': e.message,
      };
    }
  }

  /// Detect a credit card (or similar rectangular reference) in an image
  ///
  /// Standard credit card dimensions: 85.6mm x 53.98mm
  ///
  /// Returns a map with:
  /// - 'detected': bool - Whether a card was detected
  /// - 'corners': `List<double>` - Four corner coordinates [x,y] pairs
  /// - 'aspectRatio': double - Detected aspect ratio (should be ~1.585)
  /// - 'confidence': double - Detection confidence
  static Future<Map<String, dynamic>> detectCreditCard({
    required Uint8List imageBytes,
    required int width,
    required int height,
  }) async {
    try {
      final result = await _channel.invokeMethod<Map<Object?, Object?>>(
        'detectCreditCard',
        {
          'imageBytes': imageBytes,
          'width': width,
          'height': height,
        },
      );

      if (result == null) {
        return {
          'detected': false,
          'error': 'No result from native code',
        };
      }

      return _parseDetectionResult(result);
    } on PlatformException catch (e) {
      debugPrint('Credit card detection failed: ${e.message}');
      return {
        'detected': false,
        'error': e.message,
      };
    }
  }

  /// Parse the result map from native code
  static Map<String, dynamic> _parseDetectionResult(Map<Object?, Object?> raw) {
    final result = <String, dynamic>{};

    raw.forEach((key, value) {
      if (key is String) {
        if (value is List) {
          // Convert nested lists
          result[key] = _convertList(value);
        } else {
          result[key] = value;
        }
      }
    });

    return result;
  }

  /// Recursively convert `List<Object?>` to proper Dart types
  static dynamic _convertList(List<Object?> list) {
    return list.map((item) {
      if (item is List) {
        return _convertList(item);
      } else if (item is Map) {
        return _parseDetectionResult(item as Map<Object?, Object?>);
      } else {
        return item;
      }
    }).toList();
  }
}

/// Result class for parsed detection data
class DetectionChannelResult {
  final bool detected;
  final List<int> markerIds;
  final List<List<double>> corners;
  final double confidence;
  final String? error;

  const DetectionChannelResult({
    required this.detected,
    this.markerIds = const [],
    this.corners = const [],
    this.confidence = 0.0,
    this.error,
  });

  factory DetectionChannelResult.fromMap(Map<String, dynamic> map) {
    return DetectionChannelResult(
      detected: map['detected'] as bool? ?? false,
      markerIds: (map['markerIds'] as List<dynamic>?)
              ?.map((e) => e as int)
              .toList() ??
          [],
      corners: (map['corners'] as List<dynamic>?)
              ?.map((e) => (e as List<dynamic>)
                  .map((c) => (c as num).toDouble())
                  .toList())
              .toList() ??
          [],
      confidence: (map['confidence'] as num?)?.toDouble() ?? 0.0,
      error: map['error'] as String?,
    );
  }
}
