import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/project_model.dart';
import '../models/piece_model.dart';

/// Provider for the ProjectService instance
final projectServiceProvider = Provider<ProjectService>((ref) {
  return ProjectService(FirebaseFirestore.instance);
});

/// Service for Firestore CRUD operations on projects and pieces
class ProjectService {
  final FirebaseFirestore _firestore;

  ProjectService(this._firestore);

  /// Get reference to user's projects collection
  CollectionReference<Map<String, dynamic>> _projectsCollection(
          String userId) =>
      _firestore.collection('users').doc(userId).collection('projects');

  /// Get reference to project's pieces collection
  CollectionReference<Map<String, dynamic>> _piecesCollection(
    String userId,
    String projectId,
  ) =>
      _projectsCollection(userId).doc(projectId).collection('pieces');

  // ========================
  // PROJECT OPERATIONS
  // ========================

  /// Watch all projects for a user (real-time stream)
  Stream<List<ProjectModel>> watchProjects(String userId) {
    return _projectsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  /// Get a single project by ID
  Future<ProjectModel?> getProject(String userId, String projectId) async {
    final doc = await _projectsCollection(userId).doc(projectId).get();
    if (!doc.exists) return null;
    return ProjectModel.fromFirestore(doc);
  }

  /// Create a new project
  Future<ProjectModel> createProject({
    required String userId,
    required String name,
    required PatternMode mode,
    List<String> tags = const [],
  }) async {
    final docRef = _projectsCollection(userId).doc();
    final now = DateTime.now();

    final project = ProjectModel(
      projectId: docRef.id,
      name: name,
      mode: mode,
      createdAt: now,
      updatedAt: now,
      pieceCount: 0,
      tags: tags,
      sourceImageCount: 0,
    );

    await docRef.set(project.toFirestore());
    return project;
  }

  /// Update an existing project
  Future<void> updateProject({
    required String userId,
    required String projectId,
    String? name,
    PatternMode? mode,
    String? thumbnailUrl,
    List<String>? tags,
    int? pieceCount,
    int? sourceImageCount,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (mode != null) updates['mode'] = mode.name;
    if (thumbnailUrl != null) updates['thumbnailUrl'] = thumbnailUrl;
    if (tags != null) updates['tags'] = tags;
    if (pieceCount != null) updates['pieceCount'] = pieceCount;
    if (sourceImageCount != null) {
      updates['sourceImageCount'] = sourceImageCount;
    }

    await _projectsCollection(userId).doc(projectId).update(updates);
  }

  /// Delete a project and all its pieces
  Future<void> deleteProject(String userId, String projectId) async {
    // First delete all pieces in the project
    final piecesSnapshot = await _piecesCollection(userId, projectId).get();
    final batch = _firestore.batch();

    for (final doc in piecesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Then delete the project itself
    batch.delete(_projectsCollection(userId).doc(projectId));

    await batch.commit();
  }

  /// Duplicate a project (creates a copy with " (Copy)" suffix)
  Future<ProjectModel> duplicateProject(
    String userId,
    String projectId,
  ) async {
    final original = await getProject(userId, projectId);
    if (original == null) {
      throw Exception('Project not found: $projectId');
    }

    // Create new project with copied data
    final newProject = await createProject(
      userId: userId,
      name: '${original.name} (Copy)',
      mode: original.mode,
      tags: original.tags,
    );

    // Copy all pieces to new project
    final piecesSnapshot = await _piecesCollection(userId, projectId).get();
    for (final pieceDoc in piecesSnapshot.docs) {
      final piece = PieceModel.fromFirestore(pieceDoc);
      await createPiece(
        userId: userId,
        projectId: newProject.projectId,
        piece: piece.copyWith(
          pieceId: '', // Will be assigned new ID
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    // Update piece count on new project
    await updateProject(
      userId: userId,
      projectId: newProject.projectId,
      pieceCount: piecesSnapshot.docs.length,
    );

    return newProject.copyWith(pieceCount: piecesSnapshot.docs.length);
  }

  // ========================
  // PIECE OPERATIONS
  // ========================

  /// Watch all pieces for a project (real-time stream)
  Stream<List<PieceModel>> watchPieces(String userId, String projectId) {
    return _piecesCollection(userId, projectId)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => PieceModel.fromFirestore(doc)).toList());
  }

  /// Get a single piece by ID
  Future<PieceModel?> getPiece(
    String userId,
    String projectId,
    String pieceId,
  ) async {
    final doc = await _piecesCollection(userId, projectId).doc(pieceId).get();
    if (!doc.exists) return null;
    return PieceModel.fromFirestore(doc);
  }

  /// Create a new piece
  Future<PieceModel> createPiece({
    required String userId,
    required String projectId,
    required PieceModel piece,
  }) async {
    final docRef = _piecesCollection(userId, projectId).doc();
    final now = DateTime.now();

    final newPiece = piece.copyWith(
      pieceId: docRef.id,
      createdAt: now,
      updatedAt: now,
    );

    await docRef.set(newPiece.toFirestore());

    // Increment piece count on project
    await _projectsCollection(userId).doc(projectId).update({
      'pieceCount': FieldValue.increment(1),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return newPiece;
  }

  /// Update an existing piece
  Future<void> updatePiece({
    required String userId,
    required String projectId,
    required String pieceId,
    String? name,
    double? scaleMmPerPx,
    double? scaleConfidence,
    ScaleMethod? scaleMethod,
    PieceLayers? layers,
    PieceQA? qa,
    EditHistory? editHistory,
    PieceStatus? status,
    String? errorMessage,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) updates['name'] = name;
    if (scaleMmPerPx != null) updates['scaleMmPerPx'] = scaleMmPerPx;
    if (scaleConfidence != null) updates['scaleConfidence'] = scaleConfidence;
    if (scaleMethod != null) updates['scaleMethod'] = scaleMethod.name;
    if (layers != null) updates['layers'] = layers.toMap();
    if (qa != null) updates['qa'] = qa.toMap();
    if (editHistory != null) updates['editHistory'] = editHistory.toMap();
    if (status != null) updates['status'] = status.name;
    if (errorMessage != null) updates['errorMessage'] = errorMessage;

    await _piecesCollection(userId, projectId).doc(pieceId).update(updates);

    // Update project timestamp too
    await _projectsCollection(userId).doc(projectId).update({
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a piece
  Future<void> deletePiece(
    String userId,
    String projectId,
    String pieceId,
  ) async {
    await _piecesCollection(userId, projectId).doc(pieceId).delete();

    // Decrement piece count on project
    await _projectsCollection(userId).doc(projectId).update({
      'pieceCount': FieldValue.increment(-1),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ========================
  // UTILITY OPERATIONS
  // ========================

  /// Get recent projects (last N projects by update time)
  Future<List<ProjectModel>> getRecentProjects(
    String userId, {
    int limit = 5,
  }) async {
    final snapshot = await _projectsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => ProjectModel.fromFirestore(doc)).toList();
  }

  /// Search projects by name or tags
  Future<List<ProjectModel>> searchProjects(
    String userId,
    String query,
  ) async {
    // Firestore doesn't support full-text search, so we fetch all and filter
    // For production, consider using Algolia or ElasticSearch
    final snapshot = await _projectsCollection(userId)
        .orderBy('updatedAt', descending: true)
        .get();

    final lowerQuery = query.toLowerCase();
    return snapshot.docs
        .map((doc) => ProjectModel.fromFirestore(doc))
        .where((project) =>
            project.name.toLowerCase().contains(lowerQuery) ||
            project.tags.any((tag) => tag.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  /// Filter projects by mode
  Stream<List<ProjectModel>> watchProjectsByMode(
    String userId,
    PatternMode mode,
  ) {
    return _projectsCollection(userId)
        .where('mode', isEqualTo: mode.name)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProjectModel.fromFirestore(doc))
            .toList());
  }

  /// Calculate average scale confidence across all pieces in a project
  Future<double> getProjectScaleConfidence(
    String userId,
    String projectId,
  ) async {
    final piecesSnapshot = await _piecesCollection(userId, projectId)
        .where('status', isEqualTo: 'complete')
        .get();

    if (piecesSnapshot.docs.isEmpty) return 0.0;

    double totalConfidence = 0.0;
    for (final doc in piecesSnapshot.docs) {
      final piece = PieceModel.fromFirestore(doc);
      totalConfidence += piece.scaleConfidence;
    }

    return totalConfidence / piecesSnapshot.docs.length;
  }
}
