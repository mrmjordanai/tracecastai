import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import 'service_providers.dart';

/// Authentication state
enum AuthStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Auth state class
class AuthState {
  final AuthStatus status;
  final User? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  AuthState copyWith({
    AuthStatus? status,
    User? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage,
    );
  }

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null;
}

/// Auth provider
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final firebaseAuth = ref.watch(firebaseAuthProvider);
  return AuthNotifier(firebaseAuth);
});

/// Auth notifier for managing authentication state
class AuthNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );

  AuthNotifier(this._auth) : super(const AuthState()) {
    // Listen to auth state changes
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  void _onAuthStateChanged(User? user) {
    if (user != null) {
      state = AuthState(
        status: AuthStatus.authenticated,
        user: user,
      );
    } else {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
      );
    }
  }

  /// Sign in with Apple
  Future<bool> signInWithApple() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      // Check if Apple Sign In is available
      final isAvailable = await SignInWithApple.isAvailable();
      if (!isAvailable) {
        state = state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Sign in with Apple is not available on this device.',
        );
        return false;
      }

      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final userCredential = await _auth.signInWithCredential(oauthCredential);

      // Update display name if available (Apple only provides name on first sign in)
      if (userCredential.user != null &&
          appleCredential.givenName != null &&
          userCredential.user!.displayName == null) {
        final displayName =
            '${appleCredential.givenName} ${appleCredential.familyName ?? ''}'.trim();
        await userCredential.user!.updateDisplayName(displayName);
      }

      return true;
    } on SignInWithAppleAuthorizationException catch (e) {
      // User cancelled
      if (e.code == AuthorizationErrorCode.canceled) {
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return false;
      }
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Apple sign in failed: ${e.message}',
      );
      return false;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getFirebaseAuthErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'An unexpected error occurred. Please try again.',
      );
      return false;
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled
        state = state.copyWith(status: AuthStatus.unauthenticated);
        return false;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getFirebaseAuthErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Google sign in failed. Please try again.',
      );
      return false;
    }
  }

  /// Sign in with email and password
  Future<bool> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getFirebaseAuthErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Sign in failed. Please try again.',
      );
      return false;
    }
  }

  /// Create account with email and password
  Future<bool> createAccountWithEmail(String email, String password) async {
    try {
      state = state.copyWith(status: AuthStatus.loading);

      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getFirebaseAuthErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: 'Account creation failed. Please try again.',
      );
      return false;
    }
  }

  /// Send password reset email
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(
        status: AuthStatus.error,
        errorMessage: _getFirebaseAuthErrorMessage(e.code),
      );
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(
      status: state.user != null
          ? AuthStatus.authenticated
          : AuthStatus.unauthenticated,
      errorMessage: null,
    );
  }

  /// Get user-friendly error message for Firebase Auth errors
  String _getFirebaseAuthErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Please check your connection.';
      case 'invalid-credential':
        return 'Invalid credentials. Please try again.';
      case 'account-exists-with-different-credential':
        return 'An account exists with a different sign-in method.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}

/// Convenience provider for current user
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// Convenience provider for checking if user is authenticated
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});
