import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../services/analytics_service.dart';
import '../services/remote_config_service.dart';
import '../services/storage_service.dart';
import '../services/api_client.dart';
import '../services/camera_service.dart';

/// Core service providers for dependency injection
///
/// These providers expose singleton instances of core services
/// that can be accessed throughout the app.

/// Analytics service provider
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService();
});

/// Remote config service provider
final remoteConfigServiceProvider = Provider<RemoteConfigService>((ref) {
  return RemoteConfigService();
});

/// Storage service provider (SharedPreferences + SecureStorage)
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// API client provider (Dio with interceptors)
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

/// Camera service provider
final cameraServiceProvider = Provider<CameraService>((ref) {
  return CameraService();
});

/// Firebase Auth provider
final firebaseAuthProvider = Provider<FirebaseAuth>((ref) {
  return FirebaseAuth.instance;
});

/// Firestore provider
final firestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

/// Firebase Storage provider
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) {
  return FirebaseStorage.instance;
});
