import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/vectorize_result.dart';
import '../services/vectorization_service.dart';
import 'connectivity_provider.dart';

/// Hive box name for pending uploads
const String _pendingUploadsBoxName = 'pending_uploads';

/// Pending upload status
enum PendingUploadStatus {
  queued,
  uploading,
  processing,
  completed,
  failed,
}

/// Pending upload model
class PendingUpload {
  final String id;
  final String imagePath;
  final String projectId;
  final String mode;
  final DateTime createdAt;
  final PendingUploadStatus status;
  final int retryCount;
  final String? error;

  const PendingUpload({
    required this.id,
    required this.imagePath,
    required this.projectId,
    required this.mode,
    required this.createdAt,
    this.status = PendingUploadStatus.queued,
    this.retryCount = 0,
    this.error,
  });

  PendingUpload copyWith({
    String? id,
    String? imagePath,
    String? projectId,
    String? mode,
    DateTime? createdAt,
    PendingUploadStatus? status,
    int? retryCount,
    String? error,
  }) {
    return PendingUpload(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      projectId: projectId ?? this.projectId,
      mode: mode ?? this.mode,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      error: error,
    );
  }

  /// Convert to JSON for Hive storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'imagePath': imagePath,
        'projectId': projectId,
        'mode': mode,
        'createdAt': createdAt.toIso8601String(),
        'status': status.index,
        'retryCount': retryCount,
        'error': error,
      };

  /// Create from JSON for Hive storage
  factory PendingUpload.fromJson(Map<String, dynamic> json) => PendingUpload(
        id: json['id'] as String,
        imagePath: json['imagePath'] as String,
        projectId: json['projectId'] as String,
        mode: json['mode'] as String? ?? 'sewing',
        createdAt: DateTime.parse(json['createdAt'] as String),
        status: PendingUploadStatus.values[json['status'] as int],
        retryCount: json['retryCount'] as int? ?? 0,
        error: json['error'] as String?,
      );
}

/// Pending uploads state
class PendingUploadsState {
  final List<PendingUpload> uploads;
  final bool isProcessing;
  final bool isInitialized;

  const PendingUploadsState({
    this.uploads = const [],
    this.isProcessing = false,
    this.isInitialized = false,
  });

  int get pendingCount =>
      uploads.where((u) => u.status == PendingUploadStatus.queued).length;
  int get failedCount =>
      uploads.where((u) => u.status == PendingUploadStatus.failed).length;
  int get totalActiveCount => pendingCount + failedCount;

  PendingUploadsState copyWith({
    List<PendingUpload>? uploads,
    bool? isProcessing,
    bool? isInitialized,
  }) {
    return PendingUploadsState(
      uploads: uploads ?? this.uploads,
      isProcessing: isProcessing ?? this.isProcessing,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

/// Pending uploads notifier - manages offline queue with Hive persistence
class PendingUploadsNotifier extends StateNotifier<PendingUploadsState> {
  Box<Map>? _box;

  PendingUploadsNotifier() : super(const PendingUploadsState()) {
    _init();
  }

  Future<void> _init() async {
    try {
      _box = await Hive.openBox<Map>(_pendingUploadsBoxName);
      await _loadFromHive();
      state = state.copyWith(isInitialized: true);
    } catch (e) {
      debugPrint('Failed to initialize Hive for pending uploads: $e');
      state = state.copyWith(isInitialized: true);
    }
  }

  Future<void> _loadFromHive() async {
    if (_box == null) return;

    final uploads = <PendingUpload>[];
    for (final key in _box!.keys) {
      final data = _box!.get(key);
      if (data != null) {
        try {
          uploads.add(PendingUpload.fromJson(Map<String, dynamic>.from(data)));
        } catch (e) {
          debugPrint('Failed to parse pending upload: $e');
        }
      }
    }

    // Sort by creation date
    uploads.sort((a, b) => a.createdAt.compareTo(b.createdAt));

    state = state.copyWith(uploads: uploads);
  }

  Future<void> _saveToHive(PendingUpload upload) async {
    if (_box == null) return;
    await _box!.put(upload.id, upload.toJson());
  }

  Future<void> _deleteFromHive(String id) async {
    if (_box == null) return;
    await _box!.delete(id);
  }

  /// Queue a new upload
  Future<void> queueUpload({
    required String imagePath,
    required String projectId,
    required String mode,
  }) async {
    final upload = PendingUpload(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      projectId: projectId,
      mode: mode,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(
      uploads: [...state.uploads, upload],
    );

    await _saveToHive(upload);
  }

  /// Process all queued uploads (called when connectivity is restored)
  Future<void> processQueue({required bool isOnline}) async {
    if (state.isProcessing || !isOnline) return;

    state = state.copyWith(isProcessing: true);

    final queued = state.uploads
        .where((u) => u.status == PendingUploadStatus.queued)
        .toList();

    for (final upload in queued) {
      await _processUpload(upload);
    }

    state = state.copyWith(isProcessing: false);
  }

  Future<void> _processUpload(PendingUpload upload) async {
    // Update status to uploading
    await _updateUpload(upload.copyWith(status: PendingUploadStatus.uploading));

    try {
      // Verify image file exists
      final imageFile = File(upload.imagePath);
      if (!await imageFile.exists()) {
        throw Exception('Image file not found: ${upload.imagePath}');
      }

      // Update status to processing
      await _updateUpload(
          upload.copyWith(status: PendingUploadStatus.processing));

      // Call VectorizationService
      final vectorizationService = VectorizationService();
      await vectorizationService.uploadAndVectorize(
        imageFile: imageFile,
        projectId: upload.projectId,
        userId: 'anonymous', // TODO: Wire up with auth provider
        mode: upload.mode,
      );

      // Success - mark completed
      await _updateUpload(
          upload.copyWith(status: PendingUploadStatus.completed));
    } on VectorizeError catch (e) {
      // Handle vectorization-specific errors
      await _updateUpload(upload.copyWith(
        status: PendingUploadStatus.failed,
        retryCount: upload.retryCount + 1,
        error: '${e.code.name}: ${e.message}',
      ));
    } catch (e) {
      // Handle generic errors
      await _updateUpload(upload.copyWith(
        status: PendingUploadStatus.failed,
        retryCount: upload.retryCount + 1,
        error: e.toString(),
      ));
    }
  }

  Future<void> _updateUpload(PendingUpload updated) async {
    state = state.copyWith(
      uploads:
          state.uploads.map((u) => u.id == updated.id ? updated : u).toList(),
    );
    await _saveToHive(updated);
  }

  /// Retry a failed upload
  Future<void> retryUpload(String uploadId, {required bool isOnline}) async {
    final upload = state.uploads.firstWhere((u) => u.id == uploadId);
    await _updateUpload(upload.copyWith(
      status: PendingUploadStatus.queued,
      error: null,
    ));
    processQueue(isOnline: isOnline);
  }

  /// Retry all failed uploads
  Future<void> retryFailed({required bool isOnline}) async {
    final failed =
        state.uploads.where((u) => u.status == PendingUploadStatus.failed);
    for (final upload in failed) {
      await _updateUpload(upload.copyWith(
        status: PendingUploadStatus.queued,
        error: null,
      ));
    }
    processQueue(isOnline: isOnline);
  }

  /// Remove completed uploads
  Future<void> clearCompleted() async {
    final completed = state.uploads
        .where((u) => u.status == PendingUploadStatus.completed)
        .toList();

    for (final upload in completed) {
      await _deleteFromHive(upload.id);
    }

    state = state.copyWith(
      uploads: state.uploads
          .where((u) => u.status != PendingUploadStatus.completed)
          .toList(),
    );
  }

  /// Remove a specific upload
  Future<void> removeUpload(String id) async {
    await _deleteFromHive(id);
    state = state.copyWith(
      uploads: state.uploads.where((u) => u.id != id).toList(),
    );
  }
}

/// Pending uploads provider
final pendingUploadsProvider =
    StateNotifierProvider<PendingUploadsNotifier, PendingUploadsState>((ref) {
  final notifier = PendingUploadsNotifier();

  // Listen to connectivity changes and process queue when online
  ref.listen<ConnectivityStatus>(connectivityProvider, (previous, next) {
    if (next == ConnectivityStatus.online &&
        previous == ConnectivityStatus.offline) {
      notifier.processQueue(isOnline: true);
    }
  });

  return notifier;
});

/// Pending count badge provider
final pendingUploadCountProvider = Provider<int>((ref) {
  return ref.watch(pendingUploadsProvider).totalActiveCount;
});
