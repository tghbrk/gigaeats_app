import 'package:dartz/dartz.dart';

import '../../../../../core/errors/failures.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../domain/entities/user_entity.dart';
import '../../../../../domain/usecases/base_usecase.dart';
import '../../repositories/auth_repository.dart';

/// Use case for user login
class LoginUseCase implements UseCase<UserEntity, LoginParams> {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(LoginParams params) async {
    // Validate input
    final validationResult = _validateInput(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    // Perform login
    return await repository.signInWithEmailAndPassword(
      email: params.email,
      password: params.password,
    );
  }

  /// Validate login input
  ValidationFailure? _validateInput(LoginParams params) {
    // Validate email
    if (!InputValidator.isValidEmail(params.email)) {
      return const ValidationFailure(
        message: 'Please enter a valid email address',
        code: 'invalid_email',
      );
    }

    // Validate password
    if (params.password.isEmpty) {
      return const ValidationFailure(
        message: 'Password cannot be empty',
        code: 'empty_password',
      );
    }

    if (params.password.length < 6) {
      return const ValidationFailure(
        message: 'Password must be at least 6 characters long',
        code: 'password_too_short',
      );
    }

    // Check for potential security issues
    if (InputValidator.containsSqlInjection(params.email) ||
        InputValidator.containsSqlInjection(params.password)) {
      return const ValidationFailure(
        message: 'Invalid characters detected in input',
        code: 'invalid_characters',
      );
    }

    return null;
  }
}

/// Parameters for login use case
class LoginParams {
  final String email;
  final String password;

  const LoginParams({
    required this.email,
    required this.password,
  });

  @override
  String toString() => 'LoginParams(email: $email)';
}

/// Use case for Google login
class GoogleLoginUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  GoogleLoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.signInWithGoogle();
  }
}

/// Use case for Apple login
class AppleLoginUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  AppleLoginUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) async {
    return await repository.signInWithApple();
  }
}

/// Use case for logout
class LogoutUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  LogoutUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.signOut();
  }
}

/// Use case for checking authentication status
class CheckAuthStatusUseCase implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  CheckAuthStatusUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity?>> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}

/// Use case for password reset
class SendPasswordResetUseCase implements UseCase<void, SendPasswordResetParams> {
  final AuthRepository repository;

  SendPasswordResetUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(SendPasswordResetParams params) async {
    // Validate email
    if (!InputValidator.isValidEmail(params.email)) {
      return const Left(ValidationFailure(
        message: 'Please enter a valid email address',
        code: 'invalid_email',
      ));
    }

    return await repository.sendPasswordResetEmail(params.email);
  }
}

/// Parameters for password reset use case
class SendPasswordResetParams {
  final String email;

  const SendPasswordResetParams({required this.email});

  @override
  String toString() => 'SendPasswordResetParams(email: $email)';
}

/// Use case for email verification
class VerifyEmailUseCase implements UseCase<void, NoParams> {
  final AuthRepository repository;

  VerifyEmailUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(NoParams params) async {
    return await repository.verifyEmail();
  }
}

/// Use case for updating password
class UpdatePasswordUseCase implements UseCase<void, UpdatePasswordParams> {
  final AuthRepository repository;

  UpdatePasswordUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdatePasswordParams params) async {
    // Validate passwords
    final validationResult = _validatePasswords(params);
    if (validationResult != null) {
      return Left(validationResult);
    }

    return await repository.updatePassword(
      currentPassword: params.currentPassword,
      newPassword: params.newPassword,
    );
  }

  /// Validate password update input
  ValidationFailure? _validatePasswords(UpdatePasswordParams params) {
    // Check current password
    if (params.currentPassword.isEmpty) {
      return const ValidationFailure(
        message: 'Current password cannot be empty',
        code: 'empty_current_password',
      );
    }

    // Check new password
    if (params.newPassword.isEmpty) {
      return const ValidationFailure(
        message: 'New password cannot be empty',
        code: 'empty_new_password',
      );
    }

    // Check password strength
    if (!InputValidator.isStrongPassword(params.newPassword)) {
      return const ValidationFailure(
        message: 'New password must be at least 8 characters long and contain uppercase, lowercase, number, and special character',
        code: 'weak_password',
      );
    }

    // Check if passwords are different
    if (params.currentPassword == params.newPassword) {
      return const ValidationFailure(
        message: 'New password must be different from current password',
        code: 'same_password',
      );
    }

    return null;
  }
}

/// Parameters for password update use case
class UpdatePasswordParams {
  final String currentPassword;
  final String newPassword;

  const UpdatePasswordParams({
    required this.currentPassword,
    required this.newPassword,
  });

  @override
  String toString() => 'UpdatePasswordParams(currentPassword: [HIDDEN], newPassword: [HIDDEN])';
}

/// Use case for validating session
class ValidateSessionUseCase implements UseCase<bool, NoParams> {
  final AuthRepository repository;

  ValidateSessionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(NoParams params) async {
    return await repository.validateSession();
  }
}

/// Use case for checking permissions
class CheckPermissionUseCase implements UseCase<bool, CheckPermissionParams> {
  final AuthRepository repository;

  CheckPermissionUseCase(this.repository);

  @override
  Future<Either<Failure, bool>> call(CheckPermissionParams params) async {
    return await repository.hasPermission(params.permission);
  }
}

/// Parameters for permission check use case
class CheckPermissionParams {
  final String permission;

  const CheckPermissionParams({required this.permission});

  @override
  String toString() => 'CheckPermissionParams(permission: $permission)';
}
