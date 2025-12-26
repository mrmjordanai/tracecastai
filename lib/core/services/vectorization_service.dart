import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../models/vectorize_result.dart';

/// Service for uploading images and calling the vectorize Cloud Function
class VectorizationService {
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  VectorizationService({
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  })  : _functions =
            functions ?? FirebaseFunctions.instanceFor(region: 'us-east1'),
        _storage = storage ?? FirebaseStorage.instance;

  /// Uploads an image to Firebase Storage and triggers vectorization
  ///
  /// Returns the [VectorizeResult] containing extracted vector data
  /// Throws [VectorizeError] on failure
  Future<VectorizeResult> uploadAndVectorize({
    required File imageFile,
    required String projectId,
    required String userId,
    required String mode,
    double scaleMmPerPx = 0.25, // Default scale, will be refined by calibration
  }) async {
    // Generate unique image ID
    final imageId = _uuid.v4();

    try {
      // 1. Upload image to Firebase Storage
      debugPrint('Uploading image to Storage: $imageId');
      final storagePath = 'users/$userId/uploads/$imageId.jpg';
      final ref = _storage.ref(storagePath);

      await ref.putFile(
        imageFile,
        SettableMetadata(
          contentType: 'image/jpeg',
          customMetadata: {
            'projectId': projectId,
            'uploadedAt': DateTime.now().toIso8601String(),
          },
        ),
      );
      debugPrint('Image uploaded successfully');

      // 2. Call vectorize Cloud Function
      debugPrint('Calling vectorize function...');
      final callable = _functions.httpsCallable(
        'vectorize',
        options: HttpsCallableOptions(
          timeout: const Duration(seconds: 120),
        ),
      );

      final response = await callable.call<Map<String, dynamic>>({
        'project_id': projectId,
        'image_id': imageId,
        'mode': mode,
        'scale_mm_per_px': scaleMmPerPx,
        'targets': ['cutline', 'markings', 'labels'],
      });

      debugPrint('Vectorization complete');

      // 3. Parse response
      return VectorizeResult.fromJson(response.data);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('Functions error: ${e.code} - ${e.message}');
      throw _handleFunctionsError(e);
    } on FirebaseException catch (e) {
      debugPrint('Firebase error: ${e.code} - ${e.message}');
      throw VectorizeError(
        code: VectorizeErrorCode.storageError,
        message: e.message ?? 'Storage error',
        retryable: true,
      );
    } catch (e) {
      debugPrint('Unexpected error: $e');
      throw VectorizeError(
        code: VectorizeErrorCode.internalError,
        message: e.toString(),
        retryable: false,
      );
    }
  }

  VectorizeError _handleFunctionsError(FirebaseFunctionsException e) {
    final details = e.details as Map<String, dynamic>?;
    final code = details?['code'] as String?;

    // Map error codes to enum
    VectorizeErrorCode errorCode;
    bool retryable = false;

    switch (code) {
      case 'AI_UNAVAILABLE':
        errorCode = VectorizeErrorCode.aiUnavailable;
        retryable = true;
        break;
      case 'AI_TIMEOUT':
        errorCode = VectorizeErrorCode.aiTimeout;
        retryable = true;
        break;
      case 'NO_PATTERN_DETECTED':
        errorCode = VectorizeErrorCode.noPatternDetected;
        retryable = true;
        break;
      case 'LOW_CONFIDENCE':
        errorCode = VectorizeErrorCode.lowConfidence;
        retryable = true;
        break;
      case 'MALFORMED_AI_RESPONSE':
        errorCode = VectorizeErrorCode.malformedAiResponse;
        retryable = true;
        break;
      default:
        switch (e.code) {
          case 'unauthenticated':
            errorCode = VectorizeErrorCode.invalidRequest;
            break;
          case 'invalid-argument':
            errorCode = VectorizeErrorCode.invalidRequest;
            break;
          case 'not-found':
            errorCode = VectorizeErrorCode.storageError;
            break;
          default:
            errorCode = VectorizeErrorCode.internalError;
            retryable = true;
        }
    }

    return VectorizeError(
      code: errorCode,
      message: e.message ?? 'Unknown error',
      retryable: retryable,
    );
  }
}
