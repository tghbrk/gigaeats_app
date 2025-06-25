import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../../data/models/user_role.dart';

part 'admin_user.freezed.dart';
part 'admin_user.g.dart';

/// Enhanced admin user model for user management
@freezed
class AdminUser with _$AdminUser {
  const factory AdminUser({
    required String id,
    required String email,
    required String fullName,
    String? phoneNumber,
    required UserRole role,
    String? profileImageUrl,
    @Default(false) bool isVerified,
    @Default(true) bool isActive,
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? lastSignInAt,
    DateTime? emailConfirmedAt,
    DateTime? phoneConfirmedAt,
    @Default({}) Map<String, dynamic> metadata,

    // Extended admin-specific fields
    @Default(0) int totalOrders,
    @Default(0.0) double totalEarnings,
    @Default(0) int totalCustomers,
    String? assignedRegion,
    @Default([]) List<String> permissions,
    @Default('active') String status,
    DateTime? lastActivityAt,
  }) = _AdminUser;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    try {
      // Handle nested user_profiles data if present
      if (json.containsKey('user_profiles') && json['user_profiles'] is Map) {
        final profile = json['user_profiles'] as Map<String, dynamic>;
        json = {
          ...json,
          ...profile,
        };
      }

      // Create AdminUser directly using constructor
      return AdminUser(
        id: json['id'] as String,
        email: json['email'] as String,
        fullName: json['full_name'] ?? json['fullName'] as String,
        phoneNumber: json['phone_number'] ?? json['phoneNumber'] as String?,
        role: _roleFromJson(json['role']),
        profileImageUrl: json['profile_image_url'] ?? json['profileImageUrl'] as String?,
        isVerified: json['is_verified'] ?? json['isVerified'] ?? false,
        isActive: json['is_active'] ?? json['isActive'] ?? true,
        createdAt: json['created_at'] is String
            ? DateTime.parse(json['created_at'])
            : json['created_at'] ?? json['createdAt'] ?? DateTime.now(),
        updatedAt: json['updated_at'] is String
            ? DateTime.parse(json['updated_at'])
            : json['updated_at'] ?? json['updatedAt'] ?? DateTime.now(),
        lastSignInAt: json['last_sign_in_at'] is String
            ? DateTime.parse(json['last_sign_in_at'])
            : json['last_sign_in_at'] ?? json['lastSignInAt'],
        emailConfirmedAt: json['email_confirmed_at'] is String
            ? DateTime.parse(json['email_confirmed_at'])
            : json['email_confirmed_at'] ?? json['emailConfirmedAt'],
        phoneConfirmedAt: json['phone_confirmed_at'] is String
            ? DateTime.parse(json['phone_confirmed_at'])
            : json['phone_confirmed_at'] ?? json['phoneConfirmedAt'],
        metadata: json['metadata'] ?? <String, dynamic>{},
        totalOrders: json['total_orders'] ?? json['totalOrders'] ?? 0,
        totalEarnings: (json['total_earnings'] ?? json['totalEarnings'] ?? 0).toDouble(),
        totalCustomers: json['total_customers'] ?? json['totalCustomers'] ?? 0,
        assignedRegion: json['assigned_region'] ?? json['assignedRegion'],
        permissions: json['permissions'] is List
            ? List<String>.from(json['permissions'])
            : <String>[],
        status: json['status'] ?? 'active',
        lastActivityAt: json['last_activity_at'] is String
            ? DateTime.parse(json['last_activity_at'])
            : json['last_activity_at'] ?? json['lastActivityAt'],
      );
    } catch (e) {
      throw FormatException('Failed to parse AdminUser from JSON: $e');
    }
  }
}

// Helper functions for role serialization
UserRole _roleFromJson(dynamic value) {
  if (value is String) {
    return UserRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => UserRole.customer,
    );
  }
  return UserRole.customer;
}



/// User statistics for admin dashboard
@freezed
class UserStatistics with _$UserStatistics {
  const factory UserStatistics({
    required String role,
    @Default(0) int totalUsers,
    @Default(0) int verifiedUsers,
    @Default(0) int newThisWeek,
    @Default(0) int activeThisWeek,
    @Default(0) int activeUsers,
  }) = _UserStatistics;

  factory UserStatistics.fromJson(Map<String, dynamic> json) =>
      _$UserStatisticsFromJson(json);
}

/// Daily analytics for admin dashboard
@freezed
class DailyAnalytics with _$DailyAnalytics {
  const factory DailyAnalytics({
    required DateTime date,
    @Default(0) int completedOrders,
    @Default(0) int cancelledOrders,
    @Default(0.0) double dailyRevenue,
    @Default(0) int uniqueCustomers,
    @Default(0) int activeVendors,
    @Default(0.0) double avgOrderValue,
  }) = _DailyAnalytics;

  factory DailyAnalytics.fromJson(Map<String, dynamic> json) {
    try {
      return DailyAnalytics(
        date: json['date'] is String
            ? DateTime.parse(json['date'])
            : json['date'] ?? DateTime.now(),
        completedOrders: json['completed_orders'] ?? json['completedOrders'] ?? 0,
        cancelledOrders: json['cancelled_orders'] ?? json['cancelledOrders'] ?? 0,
        dailyRevenue: (json['daily_revenue'] ?? json['dailyRevenue'] ?? 0).toDouble(),
        uniqueCustomers: json['unique_customers'] ?? json['uniqueCustomers'] ?? 0,
        activeVendors: json['active_vendors'] ?? json['activeVendors'] ?? 0,
        avgOrderValue: (json['avg_order_value'] ?? json['avgOrderValue'] ?? 0).toDouble(),
      );
    } catch (e) {
      throw FormatException('Failed to parse DailyAnalytics from JSON: $e');
    }
  }
}

/// Vendor performance for admin monitoring
@freezed
class VendorPerformance with _$VendorPerformance {
  const factory VendorPerformance({
    required String id,
    required String businessName,
    @Default(0.0) double rating,
    @Default(0) int totalOrders,
    @Default(0) int ordersLast30Days,
    @Default(0.0) double revenueLast30Days,
    @Default(0.0) double avgOrderValue,
    @Default(0) int cancelledOrdersLast30Days,
  }) = _VendorPerformance;

  factory VendorPerformance.fromJson(Map<String, dynamic> json) {
    try {
      return VendorPerformance(
        id: json['id'] as String,
        businessName: json['business_name'] ?? json['businessName'] as String,
        rating: (json['rating'] ?? 0).toDouble(),
        totalOrders: json['total_orders'] ?? json['totalOrders'] ?? 0,
        ordersLast30Days: json['orders_last_30_days'] ?? json['ordersLast30Days'] ?? 0,
        revenueLast30Days: (json['revenue_last_30_days'] ?? json['revenueLast30Days'] ?? 0).toDouble(),
        avgOrderValue: (json['avg_order_value'] ?? json['avgOrderValue'] ?? 0).toDouble(),
        cancelledOrdersLast30Days: json['cancelled_orders_last_30_days'] ?? json['cancelledOrdersLast30Days'] ?? 0,
      );
    } catch (e) {
      throw FormatException('Failed to parse VendorPerformance from JSON: $e');
    }
  }
}
