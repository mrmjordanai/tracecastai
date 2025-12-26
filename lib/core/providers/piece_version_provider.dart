import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/vectorize_result.dart';

/// A saved version of a piece
@immutable
class PieceVersion {
  final String versionId;
  final String pieceId;
  final DateTime createdAt;
  final VectorizeResult vectorData;
  final bool isOriginal;

  const PieceVersion({
    required this.versionId,
    required this.pieceId,
    required this.createdAt,
    required this.vectorData,
    this.isOriginal = false,
  });

  Map<String, dynamic> toJson() => {
        'version_id': versionId,
        'piece_id': pieceId,
        'created_at': createdAt.toIso8601String(),
        'vector_data': vectorData.toJson(),
        'is_original': isOriginal,
      };

  factory PieceVersion.fromJson(Map<String, dynamic> json) {
    return PieceVersion(
      versionId: json['version_id'] as String,
      pieceId: json['piece_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      vectorData:
          VectorizeResult.fromJson(json['vector_data'] as Map<String, dynamic>),
      isOriginal: json['is_original'] as bool? ?? false,
    );
  }
}

/// State for piece version control
@immutable
class PieceVersionState {
  final String? pieceId;
  final List<PieceVersion> versions;
  final int currentVersionIndex;
  final bool isLoading;
  final String? error;
  final DateTime? lastSaveTime;

  const PieceVersionState({
    this.pieceId,
    this.versions = const [],
    this.currentVersionIndex = 0,
    this.isLoading = false,
    this.error,
    this.lastSaveTime,
  });

  /// Maximum number of versions to keep per piece
  static const int maxVersions = 10;

  /// Auto-save after this many changes
  static const int autoSaveChangeThreshold = 5;

  /// Auto-save after this many seconds of idle
  static const int autoSaveIdleSeconds = 30;

  PieceVersion? get currentVersion =>
      versions.isNotEmpty ? versions[currentVersionIndex] : null;

  PieceVersion? get originalVersion => versions.isEmpty
      ? null
      : versions.firstWhere(
          (v) => v.isOriginal,
          orElse: () => versions.first,
        );

  bool get canRevertToPrevious =>
      versions.length > 1 && currentVersionIndex < versions.length - 1;

  bool get canRestoreNext => currentVersionIndex > 0;

  PieceVersionState copyWith({
    String? pieceId,
    List<PieceVersion>? versions,
    int? currentVersionIndex,
    bool? isLoading,
    String? error,
    DateTime? lastSaveTime,
  }) {
    return PieceVersionState(
      pieceId: pieceId ?? this.pieceId,
      versions: versions ?? this.versions,
      currentVersionIndex: currentVersionIndex ?? this.currentVersionIndex,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastSaveTime: lastSaveTime ?? this.lastSaveTime,
    );
  }
}

/// Notifier for piece version control
class PieceVersionNotifier extends StateNotifier<PieceVersionState> {
  final FirebaseFirestore _firestore;
  Timer? _autoSaveTimer;

  PieceVersionNotifier({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance,
        super(const PieceVersionState());

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    super.dispose();
  }

  /// Load versions for a piece
  Future<void> loadVersions(
      String userId, String projectId, String pieceId) async {
    state = state.copyWith(isLoading: true, pieceId: pieceId);

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('pieces')
          .doc(pieceId)
          .collection('versions')
          .orderBy('created_at', descending: true)
          .limit(PieceVersionState.maxVersions)
          .get();

      final versions = snapshot.docs
          .map((doc) => PieceVersion.fromJson(doc.data()))
          .toList();

      state = state.copyWith(
        versions: versions,
        currentVersionIndex: 0,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load versions: $e',
      );
    }
  }

  /// Save a new version
  Future<void> saveVersion(
    String userId,
    String projectId,
    VectorizeResult vectorData, {
    bool isOriginal = false,
  }) async {
    if (state.pieceId == null) return;

    final versionId = DateTime.now().millisecondsSinceEpoch.toString();
    final version = PieceVersion(
      versionId: versionId,
      pieceId: state.pieceId!,
      createdAt: DateTime.now(),
      vectorData: vectorData,
      isOriginal: isOriginal,
    );

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('projects')
          .doc(projectId)
          .collection('pieces')
          .doc(state.pieceId)
          .collection('versions')
          .doc(versionId)
          .set(version.toJson());

      // Add to local state
      var newVersions = [version, ...state.versions];

      // Trim old versions (keep original if present)
      if (newVersions.length > PieceVersionState.maxVersions) {
        // Find non-original versions to remove
        final toRemove = newVersions
            .skip(PieceVersionState.maxVersions - 1)
            .where((v) => !v.isOriginal)
            .take(newVersions.length - PieceVersionState.maxVersions)
            .toList();

        for (final v in toRemove) {
          newVersions.remove(v);
          // Delete from Firestore
          await _firestore
              .collection('users')
              .doc(userId)
              .collection('projects')
              .doc(projectId)
              .collection('pieces')
              .doc(state.pieceId)
              .collection('versions')
              .doc(v.versionId)
              .delete();
        }
      }

      state = state.copyWith(
        versions: newVersions,
        currentVersionIndex: 0,
        lastSaveTime: DateTime.now(),
      );
    } catch (e) {
      state = state.copyWith(error: 'Failed to save version: $e');
    }
  }

  /// Reset to original version
  void resetToOriginal() {
    final original = state.originalVersion;
    if (original == null) return;

    final index = state.versions.indexOf(original);
    if (index >= 0) {
      state = state.copyWith(currentVersionIndex: index);
    }
  }

  /// Navigate to previous version
  void goToPreviousVersion() {
    if (!state.canRevertToPrevious) return;
    state = state.copyWith(
      currentVersionIndex: state.currentVersionIndex + 1,
    );
  }

  /// Navigate to next version
  void goToNextVersion() {
    if (!state.canRestoreNext) return;
    state = state.copyWith(
      currentVersionIndex: state.currentVersionIndex - 1,
    );
  }

  /// Start auto-save timer
  void startAutoSaveTimer(VoidCallback onSave) {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = Timer(
      const Duration(seconds: PieceVersionState.autoSaveIdleSeconds),
      onSave,
    );
  }

  /// Cancel auto-save timer
  void cancelAutoSaveTimer() {
    _autoSaveTimer?.cancel();
    _autoSaveTimer = null;
  }

  /// Clear state
  void clear() {
    _autoSaveTimer?.cancel();
    state = const PieceVersionState();
  }
}

/// Provider for piece version control
final pieceVersionProvider =
    StateNotifierProvider<PieceVersionNotifier, PieceVersionState>((ref) {
  return PieceVersionNotifier();
});
