import 'package:cloud_firestore/cloud_firestore.dart';

/// Scale detection method for piece calibration
enum ScaleMethod {
  aruco,
  grid,
  card,
  manual;

  static ScaleMethod fromString(String value) {
    return ScaleMethod.values.firstWhere(
      (method) => method.name == value,
      orElse: () => ScaleMethod.manual,
    );
  }
}

/// Processing status for pieces
enum PieceStatus {
  pending,
  processing,
  complete,
  failed;

  static PieceStatus fromString(String value) {
    return PieceStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => PieceStatus.pending,
    );
  }
}

/// Path type for vector paths
enum PathType {
  cutline,
  dart,
  notch,
  grainline,
  foldLine,
  seamLine;

  static PathType fromString(String value) {
    // Handle snake_case from Firestore
    switch (value) {
      case 'fold_line':
        return PathType.foldLine;
      case 'seam_line':
        return PathType.seamLine;
      default:
        return PathType.values.firstWhere(
          (type) => type.name == value,
          orElse: () => PathType.cutline,
        );
    }
  }

  String toFirestoreString() {
    switch (this) {
      case PathType.foldLine:
        return 'fold_line';
      case PathType.seamLine:
        return 'seam_line';
      default:
        return name;
    }
  }
}

/// Point in millimeters (avoids Flutter's Point class conflict)
class PointMm {
  final double x;
  final double y;

  const PointMm(this.x, this.y);

  Map<String, dynamic> toMap() => {'x_mm': x, 'y_mm': y};

  factory PointMm.fromMap(Map<String, dynamic> map) => PointMm(
        (map['x_mm'] ?? 0).toDouble(),
        (map['y_mm'] ?? 0).toDouble(),
      );

  @override
  String toString() => 'PointMm($x, $y)';
}

/// Size in millimeters (avoids Flutter's Size class conflict)
class SizeMm {
  final double width;
  final double height;

  const SizeMm(this.width, this.height);

  Map<String, dynamic> toMap() => {'width_mm': width, 'height_mm': height};

  factory SizeMm.fromMap(Map<String, dynamic> map) => SizeMm(
        (map['width_mm'] ?? 0).toDouble(),
        (map['height_mm'] ?? 0).toDouble(),
      );

  @override
  String toString() => 'SizeMm($width x $height)';
}

/// Vector path model for cutlines, markings, etc.
class PathModel {
  final String pathId;
  final PathType pathType;
  final bool closed;
  final List<PointMm> points;
  final double strokeHintMm;
  final double confidence;

  const PathModel({
    required this.pathId,
    required this.pathType,
    required this.closed,
    required this.points,
    required this.strokeHintMm,
    required this.confidence,
  });

  factory PathModel.fromMap(Map<String, dynamic> map) => PathModel(
        pathId: map['pathId'] ?? '',
        pathType: PathType.fromString(map['pathType'] ?? 'cutline'),
        closed: map['closed'] ?? false,
        points: (map['points'] as List? ?? [])
            .map((p) => PointMm.fromMap(p as Map<String, dynamic>))
            .toList(),
        strokeHintMm: (map['strokeHintMm'] ?? 0.5).toDouble(),
        confidence: (map['confidence'] ?? 1.0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'pathId': pathId,
        'pathType': pathType.toFirestoreString(),
        'closed': closed,
        'points': points.map((p) => p.toMap()).toList(),
        'strokeHintMm': strokeHintMm,
        'confidence': confidence,
      };

  PathModel copyWith({
    String? pathId,
    PathType? pathType,
    bool? closed,
    List<PointMm>? points,
    double? strokeHintMm,
    double? confidence,
  }) {
    return PathModel(
      pathId: pathId ?? this.pathId,
      pathType: pathType ?? this.pathType,
      closed: closed ?? this.closed,
      points: points ?? this.points,
      strokeHintMm: strokeHintMm ?? this.strokeHintMm,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// Text label model for pattern labels
class TextBoxModel {
  final String labelId;
  final String text;
  final PointMm position;
  final SizeMm size;
  final double confidence;

  const TextBoxModel({
    required this.labelId,
    required this.text,
    required this.position,
    required this.size,
    required this.confidence,
  });

  factory TextBoxModel.fromMap(Map<String, dynamic> map) => TextBoxModel(
        labelId: map['labelId'] ?? '',
        text: map['text'] ?? '',
        position: PointMm(
          (map['position']?['x_mm'] ?? 0).toDouble(),
          (map['position']?['y_mm'] ?? 0).toDouble(),
        ),
        size: SizeMm(
          (map['size']?['width_mm'] ?? 0).toDouble(),
          (map['size']?['height_mm'] ?? 0).toDouble(),
        ),
        confidence: (map['confidence'] ?? 1.0).toDouble(),
      );

  Map<String, dynamic> toMap() => {
        'labelId': labelId,
        'text': text,
        'position': position.toMap(),
        'size': size.toMap(),
        'confidence': confidence,
      };

  TextBoxModel copyWith({
    String? labelId,
    String? text,
    PointMm? position,
    SizeMm? size,
    double? confidence,
  }) {
    return TextBoxModel(
      labelId: labelId ?? this.labelId,
      text: text ?? this.text,
      position: position ?? this.position,
      size: size ?? this.size,
      confidence: confidence ?? this.confidence,
    );
  }
}

/// Layer grouping for piece vectors
class PieceLayers {
  final List<PathModel> cutline;
  final List<PathModel> markings;
  final List<TextBoxModel> labels;

  const PieceLayers({
    this.cutline = const [],
    this.markings = const [],
    this.labels = const [],
  });

  factory PieceLayers.fromMap(Map<String, dynamic> map) => PieceLayers(
        cutline: (map['cutline'] as List? ?? [])
            .map((p) => PathModel.fromMap(p as Map<String, dynamic>))
            .toList(),
        markings: (map['markings'] as List? ?? [])
            .map((p) => PathModel.fromMap(p as Map<String, dynamic>))
            .toList(),
        labels: (map['labels'] as List? ?? [])
            .map((l) => TextBoxModel.fromMap(l as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toMap() => {
        'cutline': cutline.map((p) => p.toMap()).toList(),
        'markings': markings.map((p) => p.toMap()).toList(),
        'labels': labels.map((l) => l.toMap()).toList(),
      };

  /// Get all paths (cutline + markings) combined
  List<PathModel> get allPaths => [...cutline, ...markings];

  /// Check if layers have any content
  bool get isEmpty => cutline.isEmpty && markings.isEmpty && labels.isEmpty;

  PieceLayers copyWith({
    List<PathModel>? cutline,
    List<PathModel>? markings,
    List<TextBoxModel>? labels,
  }) {
    return PieceLayers(
      cutline: cutline ?? this.cutline,
      markings: markings ?? this.markings,
      labels: labels ?? this.labels,
    );
  }
}

/// QA information from AI analysis
class PieceQA {
  final double confidence;
  final List<String> warnings;

  const PieceQA({
    this.confidence = 0,
    this.warnings = const [],
  });

  factory PieceQA.fromMap(Map<String, dynamic> map) => PieceQA(
        confidence: (map['confidence'] ?? 0).toDouble(),
        warnings: List<String>.from(map['warnings'] ?? []),
      );

  Map<String, dynamic> toMap() => {
        'confidence': confidence,
        'warnings': warnings,
      };

  /// Returns true if confidence is above 80% (good quality)
  bool get isHighConfidence => confidence >= 0.8;

  /// Returns true if confidence is below 50% (needs review)
  bool get isLowConfidence => confidence < 0.5;

  PieceQA copyWith({
    double? confidence,
    List<String>? warnings,
  }) {
    return PieceQA(
      confidence: confidence ?? this.confidence,
      warnings: warnings ?? this.warnings,
    );
  }
}

/// Edit history for tracking user modifications
class EditHistory {
  final List<PathModel> originalPaths;
  final bool hasEdits;

  const EditHistory({
    this.originalPaths = const [],
    this.hasEdits = false,
  });

  factory EditHistory.fromMap(Map<String, dynamic> map) => EditHistory(
        originalPaths: (map['originalPaths'] as List? ?? [])
            .map((p) => PathModel.fromMap(p as Map<String, dynamic>))
            .toList(),
        hasEdits: map['hasEdits'] ?? false,
      );

  Map<String, dynamic> toMap() => {
        'originalPaths': originalPaths.map((p) => p.toMap()).toList(),
        'hasEdits': hasEdits,
      };
}

/// Piece model - represents a single pattern piece in Firestore
/// Path: /users/{userId}/projects/{projectId}/pieces/{pieceId}
class PieceModel {
  final String pieceId;
  final String name;
  final String sourceImageId;
  final String sourceImageUrl;
  final double scaleMmPerPx;
  final double scaleConfidence;
  final ScaleMethod scaleMethod;
  final double widthMm;
  final double heightMm;
  final PieceLayers layers;
  final PieceQA qa;
  final EditHistory editHistory;
  final DateTime createdAt;
  final DateTime updatedAt;
  final PieceStatus status;
  final String? errorMessage;

  const PieceModel({
    required this.pieceId,
    required this.name,
    required this.sourceImageId,
    required this.sourceImageUrl,
    required this.scaleMmPerPx,
    required this.scaleConfidence,
    required this.scaleMethod,
    required this.widthMm,
    required this.heightMm,
    required this.layers,
    required this.qa,
    this.editHistory = const EditHistory(),
    required this.createdAt,
    required this.updatedAt,
    this.status = PieceStatus.pending,
    this.errorMessage,
  });

  /// Create from Firestore document snapshot
  factory PieceModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PieceModel(
      pieceId: doc.id,
      name: data['name'] ?? 'Untitled',
      sourceImageId: data['sourceImageId'] ?? '',
      sourceImageUrl: data['sourceImageUrl'] ?? '',
      scaleMmPerPx: (data['scaleMmPerPx'] ?? 0).toDouble(),
      scaleConfidence: (data['scaleConfidence'] ?? 0).toDouble(),
      scaleMethod: ScaleMethod.fromString(data['scaleMethod'] ?? 'manual'),
      widthMm: (data['widthMm'] ?? 0).toDouble(),
      heightMm: (data['heightMm'] ?? 0).toDouble(),
      layers: PieceLayers.fromMap(data['layers'] ?? {}),
      qa: PieceQA.fromMap(data['qa'] ?? {}),
      editHistory: EditHistory.fromMap(data['editHistory'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: PieceStatus.fromString(data['status'] ?? 'pending'),
      errorMessage: data['errorMessage'],
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'sourceImageId': sourceImageId,
        'sourceImageUrl': sourceImageUrl,
        'scaleMmPerPx': scaleMmPerPx,
        'scaleConfidence': scaleConfidence,
        'scaleMethod': scaleMethod.name,
        'widthMm': widthMm,
        'heightMm': heightMm,
        'layers': layers.toMap(),
        'qa': qa.toMap(),
        'editHistory': editHistory.toMap(),
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'status': status.name,
        'errorMessage': errorMessage,
      };

  /// Create a copy with updated fields
  PieceModel copyWith({
    String? pieceId,
    String? name,
    String? sourceImageId,
    String? sourceImageUrl,
    double? scaleMmPerPx,
    double? scaleConfidence,
    ScaleMethod? scaleMethod,
    double? widthMm,
    double? heightMm,
    PieceLayers? layers,
    PieceQA? qa,
    EditHistory? editHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    PieceStatus? status,
    String? errorMessage,
  }) {
    return PieceModel(
      pieceId: pieceId ?? this.pieceId,
      name: name ?? this.name,
      sourceImageId: sourceImageId ?? this.sourceImageId,
      sourceImageUrl: sourceImageUrl ?? this.sourceImageUrl,
      scaleMmPerPx: scaleMmPerPx ?? this.scaleMmPerPx,
      scaleConfidence: scaleConfidence ?? this.scaleConfidence,
      scaleMethod: scaleMethod ?? this.scaleMethod,
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      layers: layers ?? this.layers,
      qa: qa ?? this.qa,
      editHistory: editHistory ?? this.editHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  /// Check if piece is still processing
  bool get isProcessing => status == PieceStatus.processing;

  /// Check if piece has completed successfully
  bool get isComplete => status == PieceStatus.complete;

  /// Check if piece processing failed
  bool get isFailed => status == PieceStatus.failed;

  @override
  String toString() =>
      'PieceModel(id: $pieceId, name: $name, status: ${status.name}, confidence: ${qa.confidence})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieceModel &&
          runtimeType == other.runtimeType &&
          pieceId == other.pieceId;

  @override
  int get hashCode => pieceId.hashCode;
}
