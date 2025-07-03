import 'package:dartz/dartz.dart';

import '../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Abstract repository for user operations
abstract class UserRepository {
  /// Get user by ID
  Future<Either<Failure, UserEntity>> getUserById(String userId);

  /// Get user by email
  Future<Either<Failure, UserEntity>> getUserByEmail(String email);

  /// Get all users (admin only)
  Future<Either<Failure, List<UserEntity>>> getAllUsers({
    int? limit,
    int? offset,
    UserRoleEntity? role,
    bool? isActive,
  });

  /// Create new user
  Future<Either<Failure, UserEntity>> createUser(UserEntity user);

  /// Update user
  Future<Either<Failure, UserEntity>> updateUser(UserEntity user);

  /// Delete user
  Future<Either<Failure, void>> deleteUser(String userId);

  /// Get user profile
  Future<Either<Failure, UserProfileEntity>> getUserProfile(String userId);

  /// Update user profile
  Future<Either<Failure, UserProfileEntity>> updateUserProfile(UserProfileEntity profile);

  /// Search users
  Future<Either<Failure, List<UserEntity>>> searchUsers({
    required String query,
    UserRoleEntity? role,
    int? limit,
    int? offset,
  });

  /// Get users by role
  Future<Either<Failure, List<UserEntity>>> getUsersByRole(
    UserRoleEntity role, {
    int? limit,
    int? offset,
    bool? isActive,
  });

  /// Update user status
  Future<Either<Failure, UserEntity>> updateUserStatus({
    required String userId,
    required bool isActive,
  });

  /// Update user role
  Future<Either<Failure, UserEntity>> updateUserRole({
    required String userId,
    required UserRoleEntity role,
  });

  /// Verify user email
  Future<Either<Failure, UserEntity>> verifyUserEmail(String userId);

  /// Update user last login
  Future<Either<Failure, void>> updateLastLogin(String userId);

  /// Get user statistics
  Future<Either<Failure, UserStatsEntity>> getUserStats(String userId);

  /// Get platform statistics (admin only)
  Future<Either<Failure, PlatformStatsEntity>> getPlatformStats();

  /// Upload user profile image
  Future<Either<Failure, String>> uploadProfileImage({
    required String userId,
    required String imagePath,
  });

  /// Delete user profile image
  Future<Either<Failure, void>> deleteProfileImage(String userId);

  /// Get user preferences
  Future<Either<Failure, Map<String, dynamic>>> getUserPreferences(String userId);

  /// Update user preferences
  Future<Either<Failure, void>> updateUserPreferences({
    required String userId,
    required Map<String, dynamic> preferences,
  });

  /// Block user (admin only)
  Future<Either<Failure, void>> blockUser(String userId);

  /// Unblock user (admin only)
  Future<Either<Failure, void>> unblockUser(String userId);

  /// Get blocked users (admin only)
  Future<Either<Failure, List<UserEntity>>> getBlockedUsers({
    int? limit,
    int? offset,
  });

  /// Check if user exists
  Future<Either<Failure, bool>> userExists(String email);

  /// Validate user data
  Future<Either<Failure, bool>> validateUserData(UserEntity user);
}

/// User statistics entity
class UserStatsEntity {
  final String userId;
  final int totalOrders;
  final double totalSpent;
  final int favoriteVendors;
  final DateTime lastOrderDate;
  final int loyaltyPoints;
  final UserRoleEntity role;
  final DateTime memberSince;

  const UserStatsEntity({
    required this.userId,
    required this.totalOrders,
    required this.totalSpent,
    required this.favoriteVendors,
    required this.lastOrderDate,
    required this.loyaltyPoints,
    required this.role,
    required this.memberSince,
  });

  @override
  String toString() {
    return 'UserStatsEntity(userId: $userId, totalOrders: $totalOrders, totalSpent: $totalSpent)';
  }
}

/// Platform statistics entity
class PlatformStatsEntity {
  final int totalUsers;
  final int totalCustomers;
  final int totalVendors;
  final int totalSalesAgents;
  final int totalAdmins;
  final int activeUsers;
  final int newUsersToday;
  final int newUsersThisWeek;
  final int newUsersThisMonth;
  final Map<String, int> usersByRole;
  final Map<String, int> usersByStatus;
  final DateTime lastUpdated;

  const PlatformStatsEntity({
    required this.totalUsers,
    required this.totalCustomers,
    required this.totalVendors,
    required this.totalSalesAgents,
    required this.totalAdmins,
    required this.activeUsers,
    required this.newUsersToday,
    required this.newUsersThisWeek,
    required this.newUsersThisMonth,
    required this.usersByRole,
    required this.usersByStatus,
    required this.lastUpdated,
  });

  @override
  String toString() {
    return 'PlatformStatsEntity(totalUsers: $totalUsers, activeUsers: $activeUsers)';
  }
}

/// User query parameters
class UserQueryParams {
  final int? limit;
  final int? offset;
  final UserRoleEntity? role;
  final bool? isActive;
  final bool? isVerified;
  final String? searchQuery;
  final DateTime? createdAfter;
  final DateTime? createdBefore;
  final String? sortBy;
  final bool? sortAscending;

  const UserQueryParams({
    this.limit,
    this.offset,
    this.role,
    this.isActive,
    this.isVerified,
    this.searchQuery,
    this.createdAfter,
    this.createdBefore,
    this.sortBy,
    this.sortAscending,
  });

  Map<String, dynamic> toMap() {
    return {
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (role != null) 'role': role!.value,
      if (isActive != null) 'is_active': isActive,
      if (isVerified != null) 'is_verified': isVerified,
      if (searchQuery != null) 'search': searchQuery,
      if (createdAfter != null) 'created_after': createdAfter!.toIso8601String(),
      if (createdBefore != null) 'created_before': createdBefore!.toIso8601String(),
      if (sortBy != null) 'sort_by': sortBy,
      if (sortAscending != null) 'sort_ascending': sortAscending,
    };
  }
}
