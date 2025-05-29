import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/user_role.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/auth_sync_service.dart';
import '../../core/config/firebase_config.dart';

class AuthService {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final SharedPreferences _prefs;
  final AuthSyncService _authSync;

  AuthService({
    firebase_auth.FirebaseAuth? firebaseAuth,
    required SharedPreferences prefs,
    AuthSyncService? authSync,
  })  : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
        _prefs = prefs,
        _authSync = authSync ?? AuthSyncService();

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

      // Set user role using Cloud Function
      await _setUserRoleWithCloudFunction(credential.user!.uid, role);

      // Sync user to Supabase
      await _authSync.syncUserToSupabase(credential.user!);

      // Store user data locally
      await _storeUserData(
        userId: credential.user!.uid,
        token: await credential.user!.getIdToken() ?? '',
        role: role,
      );

      // Get user from Supabase (now that it's synced)
      final user = await _authSync.getCurrentUser();

      if (user == null) {
        // Fallback to creating user object locally
        final fallbackUser = User(
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
        return AuthResult.success(fallbackUser);
      }

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

      // Sync user to Supabase and get user profile
      await _authSync.syncUserToSupabase(credential.user!);
      final user = await _authSync.getCurrentUser();

      if (user != null) {
        debugPrint('AuthService: Got user from Supabase: ${user.email}, role: ${user.role}');

        // Store user data locally
        await _storeUserData(
          userId: user.id,
          token: token,
          role: user.role,
        );

        debugPrint('AuthService: Stored user data locally');
        return AuthResult.success(user);
      } else {
        // Fallback to creating user object locally if Supabase sync fails
        debugPrint('AuthService: Fallback to local user creation');

        final fallbackUser = User(
          id: credential.user!.uid,
          email: email,
          fullName: credential.user!.displayName ?? 'User',
          phoneNumber: credential.user!.phoneNumber ?? '',
          role: UserRole.salesAgent, // Default role
          isVerified: credential.user!.emailVerified,
          isActive: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        // Store user data locally
        await _storeUserData(
          userId: fallbackUser.id,
          token: token,
          role: fallbackUser.role,
        );

        return AuthResult.success(fallbackUser);
      }
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
    await _authSync.clearSupabaseSession();
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

  // Verify phone number (Malaysian numbers)
  Future<AuthResult> verifyPhoneNumber({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(firebase_auth.AuthCredential credential) verificationCompleted,
    required Function(String error) verificationFailed,
  }) async {
    try {
      // Validate Malaysian phone number format
      final validationResult = _validateMalaysianPhoneNumber(phoneNumber);
      if (!validationResult.isValid) {
        return AuthResult.failure(validationResult.errorMessage!);
      }

      final formattedNumber = validationResult.formattedNumber!;
      debugPrint('AuthService: Verifying phone number: $formattedNumber');

      await _firebaseAuth.verifyPhoneNumber(
        phoneNumber: formattedNumber,
        timeout: FirebaseConfig.phoneVerificationTimeout,
        verificationCompleted: (firebase_auth.PhoneAuthCredential credential) async {
          debugPrint('AuthService: Phone verification completed automatically');
          verificationCompleted(credential);
        },
        verificationFailed: (firebase_auth.FirebaseAuthException e) {
          debugPrint('AuthService: Phone verification failed: ${e.message}');
          verificationFailed(_getFirebaseErrorMessage(e));
        },
        codeSent: (String verificationId, int? resendToken) {
          debugPrint('AuthService: Verification code sent. ID: $verificationId');
          codeSent(verificationId);
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          debugPrint('AuthService: Code auto-retrieval timeout for ID: $verificationId');
        },
      );
      return AuthResult.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Verify SMS code and link to account
  Future<AuthResult> verifySmsCode({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      debugPrint('AuthService: Verifying SMS code');

      final credential = firebase_auth.PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );

      final currentUser = _firebaseAuth.currentUser;
      if (currentUser != null) {
        // Link phone number to existing account
        await currentUser.linkWithCredential(credential);
        debugPrint('AuthService: Phone number linked to existing account');

        // Sync updated user to Supabase
        await _authSync.syncUserToSupabase(currentUser);

        return AuthResult.success(null);
      } else {
        // Sign in with phone credential (for phone-only auth)
        final userCredential = await _firebaseAuth.signInWithCredential(credential);
        if (userCredential.user != null) {
          await _authSync.syncUserToSupabase(userCredential.user!);
          return AuthResult.success(null);
        } else {
          return AuthResult.failure('Failed to verify phone number');
        }
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      return AuthResult.failure(_getFirebaseErrorMessage(e));
    } catch (e) {
      return AuthResult.failure('An unexpected error occurred: ${e.toString()}');
    }
  }

  // Validate Malaysian phone number
  PhoneValidationResult _validateMalaysianPhoneNumber(String phoneNumber) {
    // Remove all non-digit characters
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Malaysian phone number patterns:
    // Mobile: 01X-XXXXXXX (10-11 digits total)
    // Landline: 0X-XXXXXXX (9-10 digits total)

    if (digitsOnly.isEmpty) {
      return PhoneValidationResult.invalid('Phone number cannot be empty');
    }

    // Check if it starts with Malaysia country code
    if (digitsOnly.startsWith('60')) {
      // Remove country code and validate
      final localNumber = digitsOnly.substring(2);
      return _validateLocalMalaysianNumber(localNumber, '+60');
    }

    // Check if it starts with 0 (local format)
    if (digitsOnly.startsWith('0')) {
      return _validateLocalMalaysianNumber(digitsOnly, '+60');
    }

    // If no country code, assume Malaysian and add +60
    if (digitsOnly.length >= 9 && digitsOnly.length <= 11) {
      return _validateLocalMalaysianNumber('0$digitsOnly', '+60');
    }

    return PhoneValidationResult.invalid(
      'Invalid Malaysian phone number format. Please use format: 01X-XXXXXXX or +601X-XXXXXXX'
    );
  }

  PhoneValidationResult _validateLocalMalaysianNumber(String localNumber, String countryCode) {
    final digitsOnly = localNumber.replaceAll(RegExp(r'[^\d]'), '');

    // Mobile numbers: 01X-XXXXXXX (10-11 digits with leading 0)
    if (digitsOnly.startsWith('01')) {
      if (digitsOnly.length >= 10 && digitsOnly.length <= 11) {
        // Valid mobile number
        final formatted = '$countryCode${digitsOnly.substring(1)}'; // Remove leading 0 and add country code
        return PhoneValidationResult.valid(formatted);
      }
    }

    // Landline numbers: 0X-XXXXXXX (9-10 digits with leading 0, X != 1)
    if (digitsOnly.startsWith('0') && !digitsOnly.startsWith('01')) {
      if (digitsOnly.length >= 9 && digitsOnly.length <= 10) {
        // Valid landline number
        final formatted = '$countryCode${digitsOnly.substring(1)}'; // Remove leading 0 and add country code
        return PhoneValidationResult.valid(formatted);
      }
    }

    return PhoneValidationResult.invalid(
      'Invalid Malaysian phone number. Mobile: 01X-XXXXXXX, Landline: 0X-XXXXXXX'
    );
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

  // Set user role using Supabase (temporary workaround for Spark plan)
  Future<void> _setUserRoleWithCloudFunction(String uid, UserRole role) async {
    try {
      // For now, we'll set the role directly in Supabase
      // This is a temporary workaround until we upgrade to Blaze plan
      await _authSync.setUserRole(uid, role);
      debugPrint('AuthService: User role set successfully in Supabase: ${role.value}');
    } catch (e) {
      debugPrint('AuthService: Error setting user role in Supabase: $e');
      // Don't throw here as this is not critical for the auth flow
      // The role can be set later by an admin if needed
    }
  }

  // Update user role (for existing users) - Supabase workaround
  Future<AuthResult> updateUserRole(String uid, UserRole role) async {
    try {
      // Use Supabase directly for role updates (temporary workaround)
      await _authSync.updateUserRole(uid, role);

      // Update local storage
      await _prefs.setString(AppConstants.keyUserRole, role.value);

      return AuthResult.success(null);
    } catch (e) {
      debugPrint('AuthService: Error updating user role: $e');
      return AuthResult.failure('Failed to update user role: ${e.toString()}');
    }
  }

  // Set user verification status (admin only) - Supabase workaround
  Future<AuthResult> setUserVerification(String uid, bool verified) async {
    try {
      // Use Supabase directly for verification updates (temporary workaround)
      await _authSync.setUserVerification(uid, verified);
      return AuthResult.success(null);
    } catch (e) {
      debugPrint('AuthService: Error setting user verification: $e');
      return AuthResult.failure('Failed to update verification: ${e.toString()}');
    }
  }

  // Get user role from Supabase (temporary workaround for claims)
  Future<UserRole?> getUserRole([String? uid]) async {
    try {
      final targetUid = uid ?? currentFirebaseUser?.uid;
      if (targetUid == null) return null;

      return await _authSync.getUserRole(targetUid);
    } catch (e) {
      debugPrint('AuthService: Error getting user role: $e');
      return null;
    }
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

// Phone validation result class
class PhoneValidationResult {
  final bool isValid;
  final String? formattedNumber;
  final String? errorMessage;

  PhoneValidationResult._({
    required this.isValid,
    this.formattedNumber,
    this.errorMessage,
  });

  factory PhoneValidationResult.valid(String formattedNumber) {
    return PhoneValidationResult._(
      isValid: true,
      formattedNumber: formattedNumber,
    );
  }

  factory PhoneValidationResult.invalid(String errorMessage) {
    return PhoneValidationResult._(
      isValid: false,
      errorMessage: errorMessage,
    );
  }
}
