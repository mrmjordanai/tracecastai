import 'package:flutter/foundation.dart';

/// Result from the vectorize Cloud Function
@immutable
class VectorizeResult {
  final String pieceId;
  final String sourceImageId;
  final double scaleMmPerPx;
  final double widthMm;
  final double heightMm;
  final VectorLayers layers;
  final QualityAssurance qa;

  const VectorizeResult({
    required this.pieceId,
    required this.sourceImageId,
    required this.scaleMmPerPx,
    required this.widthMm,
    required this.heightMm,
    required this.layers,
    required this.qa,
  });

  factory VectorizeResult.fromJson(Map<String, dynamic> json) {
    return VectorizeResult(
      pieceId: json['piece_id'] as String,
      sourceImageId: json['source_image_id'] as String,
      scaleMmPerPx: (json['scale_mm_per_px'] as num).toDouble(),
      widthMm: (json['width_mm'] as num).toDouble(),
      heightMm: (json['height_mm'] as num).toDouble(),
      layers: VectorLayers.fromJson(json['layers'] as Map<String, dynamic>),
      qa: QualityAssurance.fromJson(json['qa'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() => {
        'piece_id': pieceId,
        'source_image_id': sourceImageId,
        'scale_mm_per_px': scaleMmPerPx,
        'width_mm': widthMm,
        'height_mm': heightMm,
        'layers': layers.toJson(),
        'qa': qa.toJson(),
      };
}

/// Container for all vector layers
@immutable
class VectorLayers {
  final List<VectorPath> cutline;
  final List<VectorPath> markings;
  final List<TextBox> labels;

  const VectorLayers({
    required this.cutline,
    required this.markings,
    required this.labels,
  });

  factory VectorLayers.fromJson(Map<String, dynamic> json) {
    return VectorLayers(
      cutline: (json['cutline'] as List<dynamic>)
          .map((e) => VectorPath.fromJson(e as Map<String, dynamic>))
          .toList(),
      markings: (json['markings'] as List<dynamic>)
          .map((e) => VectorPath.fromJson(e as Map<String, dynamic>))
          .toList(),
      labels: (json['labels'] as List<dynamic>)
          .map((e) => TextBox.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'cutline': cutline.map((e) => e.toJson()).toList(),
        'markings': markings.map((e) => e.toJson()).toList(),
        'labels': labels.map((e) => e.toJson()).toList(),
      };
}

/// A vector path (cutline, dart, notch, grainline, etc.)
@immutable
class VectorPath {
  final String pathId;
  final String pathType;
  final bool closed;
  final List<VectorPoint> points;
  final double strokeHintMm;
  final double confidence;

  const VectorPath({
    required this.pathId,
    required this.pathType,
    required this.closed,
    required this.points,
    required this.strokeHintMm,
    required this.confidence,
  });

  factory VectorPath.fromJson(Map<String, dynamic> json) {
    return VectorPath(
      pathId: json['path_id'] as String,
      pathType: json['path_type'] as String,
      closed: json['closed'] as bool,
      points: (json['points'] as List<dynamic>)
          .map((e) => VectorPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      strokeHintMm: (json['stroke_hint_mm'] as num).toDouble(),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'path_id': pathId,
        'path_type': pathType,
        'closed': closed,
        'points': points.map((e) => e.toJson()).toList(),
        'stroke_hint_mm': strokeHintMm,
        'confidence': confidence,
      };
}

/// A point in mm coordinates
@immutable
class VectorPoint {
  final double xMm;
  final double yMm;

  const VectorPoint({
    required this.xMm,
    required this.yMm,
  });

  factory VectorPoint.fromJson(Map<String, dynamic> json) {
    return VectorPoint(
      xMm: (json['x_mm'] as num).toDouble(),
      yMm: (json['y_mm'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'x_mm': xMm,
        'y_mm': yMm,
      };
}

/// A text label with bounding box
@immutable
class TextBox {
  final String labelId;
  final String text;
  final VectorPoint position;
  final SizeMm size;
  final double confidence;

  const TextBox({
    required this.labelId,
    required this.text,
    required this.position,
    required this.size,
    required this.confidence,
  });

  factory TextBox.fromJson(Map<String, dynamic> json) {
    final sizeJson = json['size'] as Map<String, dynamic>;
    return TextBox(
      labelId: json['label_id'] as String,
      text: json['text'] as String,
      position: VectorPoint.fromJson(json['position'] as Map<String, dynamic>),
      size: SizeMm(
        (sizeJson['width_mm'] as num).toDouble(),
        (sizeJson['height_mm'] as num).toDouble(),
      ),
      confidence: (json['confidence'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label_id': labelId,
        'text': text,
        'position': position.toJson(),
        'size': {
          'width_mm': size.widthMm,
          'height_mm': size.heightMm,
        },
        'confidence': confidence,
      };
}

/// Size in millimeters (distinct from Flutter's Size class)
@immutable
class SizeMm {
  final double widthMm;
  final double heightMm;

  const SizeMm(this.widthMm, this.heightMm);
}

/// Quality assurance metadata
@immutable
class QualityAssurance {
  final double confidence;
  final List<String> warnings;

  const QualityAssurance({
    required this.confidence,
    required this.warnings,
  });

  factory QualityAssurance.fromJson(Map<String, dynamic> json) {
    return QualityAssurance(
      confidence: (json['confidence'] as num).toDouble(),
      warnings:
          (json['warnings'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'confidence': confidence,
        'warnings': warnings,
      };
}

/// Error codes from vectorization
enum VectorizeErrorCode {
  imageTooSmall,
  imageCorrupt,
  invalidRequest,
  noPatternDetected,
  lowConfidence,
  malformedAiResponse,
  aiUnavailable,
  aiTimeout,
  aiRateLimited,
  storageError,
  internalError,
}

/// Vectorization error
class VectorizeError implements Exception {
  final VectorizeErrorCode code;
  final String message;
  final bool retryable;

  const VectorizeError({
    required this.code,
    required this.message,
    this.retryable = false,
  });

  @override
  String toString() => 'VectorizeError($code): $message';
}
