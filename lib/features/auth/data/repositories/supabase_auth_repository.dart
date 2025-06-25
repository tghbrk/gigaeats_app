import 'package:dartz/dartz.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;

import '../../../../core/errors/failures.dart';
import '../../../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../../../data/models/user.dart';
import '../../../../data/models/user_role.dart';
import '../datasources/supabase_auth_datasource.dart';

/// Supabase implementation of AuthRepository
class SupabaseAuthRepository implements AuthRepository {
  final SupabaseAuthDataSource _authDataSource;

  SupabaseAuthRepository({
    required SupabaseAuthDataSource authDataSource,
  }) : _authDataSource = authDataSource;

  @override
  Future<Either<Failure, UserEntity>> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _authDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      return Right(_mapUserToEntity(user));
    } catch (e) {
      return Left(AuthFailure(message: 'Sign in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
    String? phoneNumber,
    UserRoleEntity role = UserRoleEntity.customer,
  }) async {
    try {
      final user = await _authDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
        phoneNumber: phoneNumber,
      );

      return Right(_mapUserToEntity(user));
    } catch (e) {
      return Left(AuthFailure(message: 'Sign up failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> signOut() async {
    try {
      await _authDataSource.signOut();
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Sign out failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity?>> getCurrentUser() async {
    try {
      final currentUser = await _authDataSource.getCurrentUser();
      if (currentUser == null) {
        return const Right(null);
      }

      return Right(_mapUserToEntity(currentUser));
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to get current user: ${e.toString()}'));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges {
    return _authDataSource.authStateChanges.asyncMap((user) async {
      if (user == null) {
        return null;
      }

      try {
        return _mapUserToEntity(user);
      } catch (e) {
        return null;
      }
    });
  }

  @override
  Future<Either<Failure, void>> sendPasswordResetEmail(String email) async {
    try {
      await _authDataSource.sendPasswordResetEmail(email);
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to send password reset email: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> verifyEmail() async {
    try {
      // Supabase handles email verification automatically during signup
      // This method is kept for interface compatibility
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Email verification failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _authDataSource.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      return const Right(null);
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to update password: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAccount() async {
    try {
      // Note: Supabase doesn't have a direct delete user method in the client
      // This would typically be handled by a server-side function
      return Left(AuthFailure(message: 'Account deletion not implemented'));
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to delete account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> refreshToken() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      if (session?.accessToken != null) {
        return Right(session!.accessToken);
      } else {
        return Left(AuthFailure(message: 'No active session'));
      }
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to refresh token: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> isAuthenticated() async {
    try {
      final isAuth = await _authDataSource.isAuthenticated();
      return Right(isAuth);
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to check authentication status: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithGoogle() async {
    try {
      // Google sign-in with Supabase
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.google);
      
      // Wait for auth state change
      await Future.delayed(const Duration(seconds: 2));
      
      final currentUserResult = await getCurrentUser();
      return currentUserResult.fold(
        (failure) => Left(failure),
        (user) => user != null 
          ? Right(user) 
          : Left(AuthFailure(message: 'Google sign-in failed')),
      );
    } catch (e) {
      return Left(AuthFailure(message: 'Google sign-in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> signInWithApple() async {
    try {
      // Apple sign-in with Supabase
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.apple);
      
      // Wait for auth state change
      await Future.delayed(const Duration(seconds: 2));
      
      final currentUserResult = await getCurrentUser();
      return currentUserResult.fold(
        (failure) => Left(failure),
        (user) => user != null 
          ? Right(user) 
          : Left(AuthFailure(message: 'Apple sign-in failed')),
      );
    } catch (e) {
      return Left(AuthFailure(message: 'Apple sign-in failed: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> linkWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Supabase doesn't have direct account linking like Firebase
      // This would need to be implemented as a custom flow
      return Left(AuthFailure(message: 'Account linking not implemented'));
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to link account: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, void>> unlinkFromProvider(String providerId) async {
    try {
      // Supabase doesn't have direct provider unlinking
      return Left(AuthFailure(message: 'Provider unlinking not implemented'));
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to unlink provider: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getLinkedProviders() async {
    try {
      // Return empty list for now - would need custom implementation
      return const Right([]);
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to get linked providers: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? profileImageUrl,
  }) async {
    try {
      final currentUser = await _authDataSource.getCurrentUser();
      if (currentUser == null) {
        return Left(AuthFailure(message: 'No authenticated user'));
      }

      // Update Supabase auth user metadata
      final updates = <String, dynamic>{};
      if (fullName != null) updates['full_name'] = fullName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (profileImageUrl != null) updates['profile_image_url'] = profileImageUrl;

      if (updates.isNotEmpty) {
        await Supabase.instance.client.auth.updateUser(
          UserAttributes(data: updates),
        );

        // Update user profile in database
        await Supabase.instance.client.from('users').update({
          if (fullName != null) 'full_name': fullName,
          if (phoneNumber != null) 'phone_number': phoneNumber,
          if (profileImageUrl != null) 'profile_image_url': profileImageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('supabase_user_id', currentUser.id);
      }

      // Get updated user
      final updatedUserResult = await getCurrentUser();
      return updatedUserResult.fold(
        (failure) => Left(failure),
        (user) => user != null 
          ? Right(user) 
          : Left(AuthFailure(message: 'Failed to get updated user')),
      );
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to update profile: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, UserEntity>> updateUserRole({
    required String userId,
    required UserRoleEntity role,
  }) async {
    try {
      // Update user role in database (admin only operation)
      await Supabase.instance.client.from('users').update({
        'role': _mapRoleEntityToModel(role).value,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // Get updated user
      final response = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = User.fromJson(response);
      return Right(_mapUserToEntity(user));
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to update user role: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> validateSession() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      return Right(session != null && !session.isExpired);
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to validate session: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Set<String>>> getUserPermissions() async {
    try {
      // Get user role and return permissions based on role
      final currentUserResult = await getCurrentUser();
      return currentUserResult.fold(
        (failure) => Left(failure),
        (user) {
          if (user == null) {
            return const Right(<String>{});
          }
          
          // Return permissions based on user role
          final permissions = _getPermissionsForRole(user.role);
          return Right(permissions);
        },
      );
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to get user permissions: ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, bool>> hasPermission(String permission) async {
    try {
      final permissionsResult = await getUserPermissions();
      return permissionsResult.fold(
        (failure) => Left(failure),
        (permissions) => Right(permissions.contains(permission)),
      );
    } catch (e) {
      return Left(AuthFailure(message: 'Failed to check permission: ${e.toString()}'));
    }
  }

  /// Map User model to UserEntity
  UserEntity _mapUserToEntity(User user) {
    return UserEntity(
      id: user.id,
      email: user.email,
      fullName: user.fullName,
      phoneNumber: user.phoneNumber,
      role: _mapRoleModelToEntity(user.role),
      isVerified: user.isVerified,
      isActive: user.isActive,
      profileImageUrl: user.profileImageUrl,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
    );
  }

  /// Map UserRole model to UserRoleEntity
  UserRoleEntity _mapRoleModelToEntity(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return UserRoleEntity.admin;
      case UserRole.salesAgent:
        return UserRoleEntity.salesAgent;
      case UserRole.vendor:
        return UserRoleEntity.vendor;
      case UserRole.customer:
        return UserRoleEntity.customer;
      case UserRole.driver:
        return UserRoleEntity.customer; // TODO: Add driver entity when available
    }
  }

  /// Map UserRoleEntity to UserRole model
  UserRole _mapRoleEntityToModel(UserRoleEntity role) {
    switch (role) {
      case UserRoleEntity.admin:
        return UserRole.admin;
      case UserRoleEntity.salesAgent:
        return UserRole.salesAgent;
      case UserRoleEntity.vendor:
        return UserRole.vendor;
      case UserRoleEntity.customer:
        return UserRole.customer;
      // Note: Driver role maps to customer entity until driver entity is available
    }
  }

  /// Get permissions for a specific role
  Set<String> _getPermissionsForRole(UserRoleEntity role) {
    switch (role) {
      case UserRoleEntity.admin:
        return {
          'users.read',
          'users.write',
          'users.delete',
          'vendors.read',
          'vendors.write',
          'vendors.delete',
          'orders.read',
          'orders.write',
          'orders.delete',
          'analytics.read',
        };
      case UserRoleEntity.salesAgent:
        return {
          'vendors.read',
          'vendors.write',
          'customers.read',
          'customers.write',
          'orders.read',
          'orders.write',
        };
      case UserRoleEntity.vendor:
        return {
          'menu_items.read',
          'menu_items.write',
          'orders.read',
          'orders.write',
        };
      case UserRoleEntity.customer:
        return {
          'orders.read',
          'menu_items.read',
        };
    }
  }
}
