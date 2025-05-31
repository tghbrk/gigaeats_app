import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract repository for authentication operations
abstract class AuthRepository {
  /// Sign in with email and password
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Sign up with email and password
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRoleEntity role = UserRoleEntity.customer,
  });

  /// Sign out current user
  Future<Either<Failure, void>> signOut();

  /// Get current authenticated user
  Future<Either<Failure, UserEntity?>> getCurrentUser();

  /// Stream of authentication state changes
  Stream<UserEntity?> get authStateChanges;

  /// Send password reset email
  Future<Either<Failure, void>> sendPasswordResetEmail(String email);

  /// Verify email address
  Future<Either<Failure, void>> verifyEmail();

  /// Update password
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Delete user account
  Future<Either<Failure, void>> deleteAccount();

  /// Refresh authentication token
  Future<Either<Failure, String>> refreshToken();

  /// Check if user is authenticated
  Future<Either<Failure, bool>> isAuthenticated();

  /// Sign in with Google
  Future<Either<Failure, UserEntity>> signInWithGoogle();

  /// Sign in with Apple
  Future<Either<Failure, UserEntity>> signInWithApple();

  /// Link account with email and password
  Future<Either<Failure, UserEntity>> linkWithEmailAndPassword({
    required String email,
    required String password,
  });

  /// Unlink account from provider
  Future<Either<Failure, void>> unlinkFromProvider(String providerId);

  /// Get linked providers
  Future<Either<Failure, List<String>>> getLinkedProviders();

  /// Update user profile
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  });

  /// Update user role (admin only)
  Future<Either<Failure, UserEntity>> updateUserRole({
    required String userId,
    required UserRoleEntity role,
  });

  /// Validate current session
  Future<Either<Failure, bool>> validateSession();

  /// Get user permissions
  Future<Either<Failure, Set<String>>> getUserPermissions();

  /// Check if user has specific permission
  Future<Either<Failure, bool>> hasPermission(String permission);
}

/// Authentication result wrapper
class AuthResult {
  final UserEntity? user;
  final String? error;
  final bool isSuccess;

  const AuthResult._({
    this.user,
    this.error,
    required this.isSuccess,
  });

  /// Create successful authentication result
  factory AuthResult.success(UserEntity user) {
    return AuthResult._(
      user: user,
      isSuccess: true,
    );
  }

  /// Create failed authentication result
  factory AuthResult.failure(String error) {
    return AuthResult._(
      error: error,
      isSuccess: false,
    );
  }

  @override
  String toString() {
    if (isSuccess) {
      return 'AuthResult.success(user: ${user?.email})';
    } else {
      return 'AuthResult.failure(error: $error)';
    }
  }
}

/// Authentication state
enum AuthState {
  initial,
  loading,
  authenticated,
  unauthenticated,
  error,
}

/// Authentication event
abstract class AuthEvent {
  const AuthEvent();
}

class SignInRequested extends AuthEvent {
  final String email;
  final String password;

  const SignInRequested({
    required this.email,
    required this.password,
  });
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String fullName;
  final String? phoneNumber;
  final UserRoleEntity role;

  const SignUpRequested({
    required this.email,
    required this.password,
    required this.fullName,
    this.phoneNumber,
    this.role = UserRoleEntity.customer,
  });
}

class SignOutRequested extends AuthEvent {
  const SignOutRequested();
}

class AuthStateCheckRequested extends AuthEvent {
  const AuthStateCheckRequested();
}

class GoogleSignInRequested extends AuthEvent {
  const GoogleSignInRequested();
}

class AppleSignInRequested extends AuthEvent {
  const AppleSignInRequested();
}

class PasswordResetRequested extends AuthEvent {
  final String email;

  const PasswordResetRequested({required this.email});
}

class EmailVerificationRequested extends AuthEvent {
  const EmailVerificationRequested();
}

class PasswordUpdateRequested extends AuthEvent {
  final String currentPassword;
  final String newPassword;

  const PasswordUpdateRequested({
    required this.currentPassword,
    required this.newPassword,
  });
}

class ProfileUpdateRequested extends AuthEvent {
  final String? fullName;
  final String? phoneNumber;
  final String? profileImageUrl;

  const ProfileUpdateRequested({
    this.fullName,
    this.phoneNumber,
    this.profileImageUrl,
  });
}

class AccountDeletionRequested extends AuthEvent {
  const AccountDeletionRequested();
}
