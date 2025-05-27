import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../../core/constants/app_constants.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final SharedPreferences _prefs;

  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    required SharedPreferences prefs,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _prefs = prefs;

  // Get current Firebase user
  firebase_auth.User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Get current user stream
  Stream<firebase_auth.User?> get authStateChanges =>
      _firebaseAuth.authStateChanges();

  // Check if user is authenticated
  bool get isAuthenticated => currentFirebaseUser != null;

  // Get stored user token
  String? get userToken => _prefs.getString(AppConstants.keyUserToken);

  // Get stored user role
  UserRole? get userRole {
    final roleString = _prefs.getString(AppConstants.keyUserRole);
    return roleString != null ? UserRole.fromString(roleString) : null;
  }

  // Get stored user ID
  String? get userId => _prefs.getString(AppConstants.keyUserId);

  // Register with email and password
  Future<AuthResult> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required UserRole role,
  }) async {
    try {
      // Create Firebase user
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        return AuthResult.failure('Failed to create user account');
      }

      // Update display name
      await credential.user!.updateDisplayName(fullName);

      // Send email verification
      await credential.user!.sendEmailVerification();

      // Store user data locally
      await _storeUserData(
        userId: credential.user!.uid,
        token: await credential.user!.getIdToken() ?? '',
        role: role,
      );

      // Create user profile in backend (this would be an API call)
      final user = User(
        id: credential.user!.uid,
        email: email,
        fullName: fullName,
        phoneNumber: phoneNumber,
        role: role,
        isVerified: false,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign in with email and password
  Future<AuthResult> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('AuthService: Attempting Firebase sign in for $email');

      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      debugPrint('AuthService: Firebase sign in successful, user: ${credential.user?.uid}');

      if (credential.user == null) {
        debugPrint('AuthService: No user in credential');
        return AuthResult.failure('Failed to sign in');
      }

      // Get user token
      final token = await credential.user!.getIdToken() ?? '';
      debugPrint('AuthService: Got user token');

      // Fetch user profile from backend (this would be an API call)
      // In production, user role should be determined by your backend API
      // For now, defaulting to sales agent - implement proper role assignment
      UserRole userRole = UserRole.salesAgent;

      debugPrint('AuthService: Determined user role: $userRole');

      final user = User(
        id: credential.user!.uid,
        email: email,
        fullName: credential.user!.displayName ?? 'User',
        phoneNumber: credential.user!.phoneNumber ?? '',
        role: userRole,
        isVerified: credential.user!.emailVerified,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('AuthService: Created user object: ${user.email}, role: ${user.role}');

      // Store user data locally
      await _storeUserData(
        userId: user.id,
        token: token,
        role: user.role,
      );

      debugPrint('AuthService: Stored user data locally');

      return AuthResult.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('AuthService: Firebase auth exception: ${e.code} - ${e.message}');
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      debugPrint('AuthService: Unexpected error: $e');
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
    await _clearUserData();
  }

  // Send password reset email
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
      return AuthResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Send email verification
  Future<AuthResult> sendEmailVerification() async {
    try {
      final user = currentFirebaseUser;
      if (user == null) {
        return AuthResult.failure('No user signed in');
      }

      await user.sendEmailVerification();
      return AuthResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Verify phone number
  Future<AuthResult> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(firebase_auth.AuthCredential credential) verificationCompleted,
  }) async {
    try {
      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: verificationCompleted,
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          // Handle verification failed
        },
        codeSent: (String verificationId, int? resendToken) {
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Handle timeout
        },
      );
      return AuthResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Store user data locally
  Future<void> _storeUserData({
    required String userId,
    required String token,
    required UserRole role,
  }) async {
    await _prefs.setString(AppConstants.keyUserId, userId);
    await _prefs.setString(AppConstants.keyUserToken, token);
    await _prefs.setString(AppConstants.keyUserRole, role.value);
  }

  // Clear user data
  Future<void> _clearUserData() async {
    await _prefs.remove(AppConstants.keyUserId);
    await _prefs.remove(AppConstants.keyUserToken);
    await _prefs.remove(AppConstants.keyUserRole);
  }

  // Get Firebase error message
  String _getFirebaseErrorMessage(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'The account already exists for that email.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Wrong password provided for that user.';
      case 'invalid-email':
        return 'The email address is not valid.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'too-many-requests':
        return 'Too many requests. Try again later.';
      case 'operation-not-allowed':
        return 'Signing in with Email and Password is not enabled.';
      default:
        return e.message ?? 'An authentication error occurred.';
    }
  }
}

// Auth result class
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User? user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.failure(String errorMessage) {
    return AuthResult._(isSuccess: false, errorMessage: errorMessage);
  }
}
