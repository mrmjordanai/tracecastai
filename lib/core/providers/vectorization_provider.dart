import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/vectorize_result.dart';
import '../services/vectorization_service.dart';

/// Vectorization state
class VectorizationState {
  final bool isProcessing;
  final String? statusMessage;
  final VectorizeResult? result;
  final String? error;
  final String? errorCode;
  final bool retryable;

  const VectorizationState({
    this.isProcessing = false,
    this.statusMessage,
    this.result,
    this.error,
    this.errorCode,
    this.retryable = false,
  });

  VectorizationState copyWith({
    bool? isProcessing,
    String? statusMessage,
    VectorizeResult? result,
    String? error,
    String? errorCode,
    bool? retryable,
  }) {
    return VectorizationState(
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: statusMessage ?? this.statusMessage,
      result: result ?? this.result,
      error: error,
      errorCode: errorCode,
      retryable: retryable ?? this.retryable,
    );
  }
}

/// Vectorization notifier - manages AI pattern extraction
class VectorizationNotifier extends StateNotifier<VectorizationState> {
  final VectorizationService _service;
  final FirebaseAuth _auth;

  VectorizationNotifier({
    VectorizationService? service,
    FirebaseAuth? auth,
  })  : _service = service ?? VectorizationService(),
        _auth = auth ?? FirebaseAuth.instance,
        super(const VectorizationState());

  /// Start vectorization process
  Future<VectorizeResult?> startVectorization({
    required String imagePath,
    required String projectId,
    required String mode,
    double scaleMmPerPx = 0.25,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      state = state.copyWith(
        isProcessing: false,
        error: 'Not logged in',
        errorCode: 'UNAUTHENTICATED',
      );
      return null;
    }

    state = state.copyWith(
      isProcessing: true,
      statusMessage: 'Uploading image...',
      error: null,
      errorCode: null,
    );

    try {
      final result = await _service.uploadAndVectorize(
        imageFile: File(imagePath),
        projectId: projectId,
        userId: user.uid,
        mode: mode,
        scaleMmPerPx: scaleMmPerPx,
      );

      state = state.copyWith(
        isProcessing: false,
        statusMessage: null,
        result: result,
      );

      return result;
    } on VectorizeError catch (e) {
      state = state.copyWith(
        isProcessing: false,
        statusMessage: null,
        error: e.message,
        errorCode: e.code.name,
        retryable: e.retryable,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isProcessing: false,
        statusMessage: null,
        error: e.toString(),
        errorCode: 'UNKNOWN',
        retryable: true,
      );
      rethrow;
    }
  }

  /// Set a result directly (for testing or loading from cache)
  void setResult(VectorizeResult result) {
    state = state.copyWith(
      isProcessing: false,
      result: result,
      error: null,
    );
  }

  /// Clear current result
  void clear() {
    state = const VectorizationState();
  }
}

/// Vectorization provider
final vectorizationProvider =
    StateNotifierProvider<VectorizationNotifier, VectorizationState>((ref) {
  return VectorizationNotifier();
});

/// Vectorization result convenience provider
final vectorResultProvider = Provider<VectorizeResult?>((ref) {
  return ref.watch(vectorizationProvider).result;
});

/// Scale confidence provider
final scaleConfidenceProvider = Provider<double?>((ref) {
  final result = ref.watch(vectorResultProvider);
  return result?.qa.confidence;
});
