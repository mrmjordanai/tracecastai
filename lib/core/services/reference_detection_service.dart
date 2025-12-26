import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../platform_channels/reference_detection_channel.dart';

/// Reference type used for scale detection
enum ReferenceType {
  /// ArUco markers on reference sheet
  aruco,

  /// Grid pattern (cutting mat, graph paper)
  grid,

  /// Credit card sized reference
  creditCard,

  /// User-provided manual scale
  manual,

  /// No reference detected
  none,
}

/// Result from reference detection
class ReferenceDetectionResult {
  /// Type of reference detected
  final ReferenceType type;

  /// Detected corner points in image coordinates (top-left, top-right, bottom-right, bottom-left)
  final List<Offset>? cornerPoints;

  /// Calculated scale factor (mm per pixel)
  final double? scaleMmPerPx;

  /// Confidence score (0.0 - 1.0)
  final double confidence;

  /// Whether the reference is fully detected and locked
  final bool isLocked;

  /// Error message if detection failed
  final String? error;

  const ReferenceDetectionResult({
    required this.type,
    this.cornerPoints,
    this.scaleMmPerPx,
    this.confidence = 0.0,
    this.isLocked = false,
    this.error,
  });

  /// No reference detected
  static const ReferenceDetectionResult none = ReferenceDetectionResult(
    type: ReferenceType.none,
    confidence: 0.0,
  );

  ReferenceDetectionResult copyWith({
    ReferenceType? type,
    List<Offset>? cornerPoints,
    double? scaleMmPerPx,
    double? confidence,
    bool? isLocked,
    String? error,
  }) {
    return ReferenceDetectionResult(
      type: type ?? this.type,
      cornerPoints: cornerPoints ?? this.cornerPoints,
      scaleMmPerPx: scaleMmPerPx ?? this.scaleMmPerPx,
      confidence: confidence ?? this.confidence,
      isLocked: isLocked ?? this.isLocked,
      error: error,
    );
  }
}

/// Reference detection service
///
/// Detects ArUco markers, grid patterns, or credit card references
/// in camera frames to calculate scale factor.
///
/// Note: ArUco detection requires platform-specific implementation.
/// This service provides the Dart interface; native code handles detection.
class ReferenceDetectionService {
  /// Known reference dimensions (in mm)
  static const double arucoSheetWidthMm = 210.0; // A4 width
  static const double arucoSheetHeightMm = 297.0; // A4 height
  static const double creditCardWidthMm = 85.6;
  static const double creditCardHeightMm = 53.98;
  static const double gridSquareSizeMm = 25.4; // 1 inch grid

  /// Minimum confidence to consider detection valid
  static const double minConfidenceThreshold = 0.7;

  /// Detect reference in image bytes
  ///
  /// Returns [ReferenceDetectionResult] with detected reference info.
  /// If no reference is detected, returns [ReferenceDetectionResult.none].
  Future<ReferenceDetectionResult> detectReference({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    ReferenceType preferredType = ReferenceType.aruco,
  }) async {
    debugPrint(
        'ReferenceDetectionService: Detecting reference in ${imageWidth}x$imageHeight image');

    // Check if platform detection is available
    final isAvailable = await ReferenceDetectionChannel.isAvailable();
    if (!isAvailable) {
      debugPrint('ReferenceDetectionService: Platform detection not available');
      return ReferenceDetectionResult.none;
    }

    // Try detection based on preferred type
    ReferenceDetectionResult result;

    switch (preferredType) {
      case ReferenceType.aruco:
        result = await detectAruco(
          imageBytes: imageBytes,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        );
        if (result.confidence >= minConfidenceThreshold) return result;
        // Fall through to try other types
        result = await detectCreditCard(
          imageBytes: imageBytes,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        );
        if (result.confidence >= minConfidenceThreshold) return result;
        result = await detectGrid(
          imageBytes: imageBytes,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        );
        break;

      case ReferenceType.creditCard:
        result = await detectCreditCard(
          imageBytes: imageBytes,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        );
        break;

      case ReferenceType.grid:
        result = await detectGrid(
          imageBytes: imageBytes,
          imageWidth: imageWidth,
          imageHeight: imageHeight,
        );
        break;

      default:
        result = ReferenceDetectionResult.none;
    }

    return result.confidence >= minConfidenceThreshold
        ? result
        : ReferenceDetectionResult.none;
  }

  /// Detect ArUco markers in image
  ///
  /// Looks for ArUco markers (IDs 0-3) at the corners of the reference sheet.
  /// Returns corner points if all 4 markers are found.
  Future<ReferenceDetectionResult> detectAruco({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    debugPrint('ReferenceDetectionService: Detecting ArUco markers');

    try {
      final result = await ReferenceDetectionChannel.detectAruco(
        imageBytes: imageBytes,
        width: imageWidth,
        height: imageHeight,
      );

      final detected = result['detected'] as bool? ?? false;
      if (!detected) {
        final error = result['error'] as String?;
        final message = result['message'] as String?;
        return ReferenceDetectionResult(
          type: ReferenceType.aruco,
          confidence: 0.0,
          error: error ?? message,
        );
      }

      // Parse corner points from result
      final cornersData = result['corners'] as List<dynamic>?;
      List<Offset>? cornerPoints;

      if (cornersData != null && cornersData.isNotEmpty) {
        // Each marker has 8 values (4 corners x 2 coordinates)
        // We want the outer corners of all detected markers
        final allCorners = <Offset>[];
        for (final markerCorners in cornersData) {
          if (markerCorners is List && markerCorners.length >= 8) {
            allCorners.add(Offset(
              (markerCorners[0] as num).toDouble(),
              (markerCorners[1] as num).toDouble(),
            ));
            allCorners.add(Offset(
              (markerCorners[2] as num).toDouble(),
              (markerCorners[3] as num).toDouble(),
            ));
            allCorners.add(Offset(
              (markerCorners[4] as num).toDouble(),
              (markerCorners[5] as num).toDouble(),
            ));
            allCorners.add(Offset(
              (markerCorners[6] as num).toDouble(),
              (markerCorners[7] as num).toDouble(),
            ));
          }
        }

        // If we have 4 markers (16 corners), extract the outer bounds
        if (allCorners.length >= 4) {
          cornerPoints = _extractOuterCorners(allCorners);
        }
      }

      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final scaleMmPerPx = cornerPoints != null
          ? calculateScale(corners: cornerPoints, type: ReferenceType.aruco)
          : null;

      return ReferenceDetectionResult(
        type: ReferenceType.aruco,
        cornerPoints: cornerPoints,
        scaleMmPerPx: scaleMmPerPx,
        confidence: confidence,
        isLocked: confidence >= minConfidenceThreshold,
      );
    } catch (e) {
      debugPrint('ReferenceDetectionService: ArUco detection error: $e');
      return ReferenceDetectionResult(
        type: ReferenceType.aruco,
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Extract 4 outer corners from a list of all detected corner points
  List<Offset> _extractOuterCorners(List<Offset> allCorners) {
    if (allCorners.length < 4) return allCorners;

    // Find bounding box corners
    double minX = double.infinity, minY = double.infinity;
    double maxX = double.negativeInfinity, maxY = double.negativeInfinity;

    for (final corner in allCorners) {
      if (corner.dx < minX) minX = corner.dx;
      if (corner.dy < minY) minY = corner.dy;
      if (corner.dx > maxX) maxX = corner.dx;
      if (corner.dy > maxY) maxY = corner.dy;
    }

    // Find closest corner to each bounding box corner
    Offset findClosest(double targetX, double targetY) {
      return allCorners.reduce((a, b) {
        final distA = (a.dx - targetX).abs() + (a.dy - targetY).abs();
        final distB = (b.dx - targetX).abs() + (b.dy - targetY).abs();
        return distA < distB ? a : b;
      });
    }

    return [
      findClosest(minX, minY), // Top-left
      findClosest(maxX, minY), // Top-right
      findClosest(maxX, maxY), // Bottom-right
      findClosest(minX, maxY), // Bottom-left
    ];
  }

  /// Detect grid pattern in image
  ///
  /// Looks for regular grid lines (cutting mat, graph paper).
  Future<ReferenceDetectionResult> detectGrid({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    debugPrint('ReferenceDetectionService: Detecting grid pattern');

    try {
      final result = await ReferenceDetectionChannel.detectGrid(
        imageBytes: imageBytes,
        width: imageWidth,
        height: imageHeight,
        gridSpacingMm: gridSquareSizeMm,
      );

      final detected = result['detected'] as bool? ?? false;
      if (!detected) {
        final error = result['error'] as String?;
        final message = result['message'] as String?;
        return ReferenceDetectionResult(
          type: ReferenceType.grid,
          confidence: 0.0,
          error: error ?? message,
        );
      }

      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final gridSpacingPx = (result['gridSpacingPx'] as num?)?.toDouble();

      // Calculate scale from grid spacing
      double? scaleMmPerPx;
      if (gridSpacingPx != null && gridSpacingPx > 0) {
        scaleMmPerPx = gridSquareSizeMm / gridSpacingPx;
      }

      return ReferenceDetectionResult(
        type: ReferenceType.grid,
        scaleMmPerPx: scaleMmPerPx,
        confidence: confidence,
        isLocked: confidence >= minConfidenceThreshold,
      );
    } catch (e) {
      debugPrint('ReferenceDetectionService: Grid detection error: $e');
      return ReferenceDetectionResult(
        type: ReferenceType.grid,
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Detect credit card in image
  ///
  /// Looks for rectangular object matching credit card aspect ratio.
  Future<ReferenceDetectionResult> detectCreditCard({
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
  }) async {
    debugPrint('ReferenceDetectionService: Detecting credit card');

    try {
      final result = await ReferenceDetectionChannel.detectCreditCard(
        imageBytes: imageBytes,
        width: imageWidth,
        height: imageHeight,
      );

      final detected = result['detected'] as bool? ?? false;
      if (!detected) {
        final error = result['error'] as String?;
        final message = result['message'] as String?;
        return ReferenceDetectionResult(
          type: ReferenceType.creditCard,
          confidence: 0.0,
          error: error ?? message,
        );
      }

      // Parse corner points from result
      final cornersData = result['corners'] as List<dynamic>?;
      List<Offset>? cornerPoints;

      if (cornersData != null && cornersData.length >= 8) {
        cornerPoints = [
          Offset(
            (cornersData[0] as num).toDouble(),
            (cornersData[1] as num).toDouble(),
          ),
          Offset(
            (cornersData[2] as num).toDouble(),
            (cornersData[3] as num).toDouble(),
          ),
          Offset(
            (cornersData[4] as num).toDouble(),
            (cornersData[5] as num).toDouble(),
          ),
          Offset(
            (cornersData[6] as num).toDouble(),
            (cornersData[7] as num).toDouble(),
          ),
        ];
      }

      final confidence = (result['confidence'] as num?)?.toDouble() ?? 0.0;
      final scaleMmPerPx = cornerPoints != null
          ? calculateScale(corners: cornerPoints, type: ReferenceType.creditCard)
          : null;

      return ReferenceDetectionResult(
        type: ReferenceType.creditCard,
        cornerPoints: cornerPoints,
        scaleMmPerPx: scaleMmPerPx,
        confidence: confidence,
        isLocked: confidence >= minConfidenceThreshold,
      );
    } catch (e) {
      debugPrint('ReferenceDetectionService: Credit card detection error: $e');
      return ReferenceDetectionResult(
        type: ReferenceType.creditCard,
        confidence: 0.0,
        error: e.toString(),
      );
    }
  }

  /// Calculate scale from detected corners
  ///
  /// Given 4 corner points and known reference dimensions,
  /// calculates the mm-per-pixel scale factor.
  double? calculateScale({
    required List<Offset> corners,
    required ReferenceType type,
  }) {
    if (corners.length != 4) return null;

    // Get reference dimensions based on type
    double refWidthMm;
    double refHeightMm;

    switch (type) {
      case ReferenceType.aruco:
        refWidthMm = arucoSheetWidthMm;
        refHeightMm = arucoSheetHeightMm;
        break;
      case ReferenceType.creditCard:
        refWidthMm = creditCardWidthMm;
        refHeightMm = creditCardHeightMm;
        break;
      case ReferenceType.grid:
        // For grid, we use the grid square size
        refWidthMm = gridSquareSizeMm;
        refHeightMm = gridSquareSizeMm;
        break;
      default:
        return null;
    }

    // Calculate pixel dimensions from corners
    final topEdgePx = (corners[1] - corners[0]).distance;
    final bottomEdgePx = (corners[2] - corners[3]).distance;
    final leftEdgePx = (corners[3] - corners[0]).distance;
    final rightEdgePx = (corners[2] - corners[1]).distance;

    // Average the edges
    final avgWidthPx = (topEdgePx + bottomEdgePx) / 2;
    final avgHeightPx = (leftEdgePx + rightEdgePx) / 2;

    // Calculate scale (mm per pixel)
    final scaleFromWidth = refWidthMm / avgWidthPx;
    final scaleFromHeight = refHeightMm / avgHeightPx;

    // Average the two scales
    return (scaleFromWidth + scaleFromHeight) / 2;
  }

  /// Create manual scale result from user input
  ///
  /// Used when user manually specifies a known dimension.
  ReferenceDetectionResult createManualScale({
    required double knownDimensionMm,
    required double measuredPixels,
  }) {
    final scaleMmPerPx = knownDimensionMm / measuredPixels;

    return ReferenceDetectionResult(
      type: ReferenceType.manual,
      scaleMmPerPx: scaleMmPerPx,
      confidence: 1.0, // User input is trusted
      isLocked: true,
    );
  }
}
