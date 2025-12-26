import 'package:cloud_firestore/cloud_firestore.dart';

/// Pattern mode enum for project categorization
enum PatternMode {
  sewing,
  quilting,
  stencil,
  maker,
  custom;

  static PatternMode fromString(String value) {
    return PatternMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => PatternMode.sewing,
    );
  }
}

/// Project model - represents a user's pattern project in Firestore
/// Path: /users/{userId}/projects/{projectId}
class ProjectModel {
  final String projectId;
  final String name;
  final PatternMode mode;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int pieceCount;
  final String? thumbnailUrl;
  final List<String> tags;
  final int sourceImageCount;

  const ProjectModel({
    required this.projectId,
    required this.name,
    required this.mode,
    required this.createdAt,
    required this.updatedAt,
    this.pieceCount = 0,
    this.thumbnailUrl,
    this.tags = const [],
    this.sourceImageCount = 0,
  });

  /// Create from Firestore document snapshot
  factory ProjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ProjectModel(
      projectId: doc.id,
      name: data['name'] ?? 'Untitled',
      mode: PatternMode.fromString(data['mode'] ?? 'sewing'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      pieceCount: data['pieceCount'] ?? 0,
      thumbnailUrl: data['thumbnailUrl'],
      tags: List<String>.from(data['tags'] ?? []),
      sourceImageCount: data['sourceImageCount'] ?? 0,
    );
  }

  /// Convert to Firestore map
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'mode': mode.name,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        'pieceCount': pieceCount,
        'thumbnailUrl': thumbnailUrl,
        'tags': tags,
        'sourceImageCount': sourceImageCount,
      };

  /// Create a copy with updated fields
  ProjectModel copyWith({
    String? projectId,
    String? name,
    PatternMode? mode,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? pieceCount,
    String? thumbnailUrl,
    List<String>? tags,
    int? sourceImageCount,
  }) {
    return ProjectModel(
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pieceCount: pieceCount ?? this.pieceCount,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      tags: tags ?? this.tags,
      sourceImageCount: sourceImageCount ?? this.sourceImageCount,
    );
  }

  /// Calculate average scale confidence from pieces (used for Scale Ring)
  /// Returns null if no pieces exist
  double? get averageScaleConfidence => null; // Computed from pieces

  @override
  String toString() =>
      'ProjectModel(id: $projectId, name: $name, mode: ${mode.name}, pieces: $pieceCount)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectModel &&
          runtimeType == other.runtimeType &&
          projectId == other.projectId;

  @override
  int get hashCode => projectId.hashCode;
}
