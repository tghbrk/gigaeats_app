import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/admin_repository.dart';
import '../../../user_management/domain/admin_user.dart';
import '../../data/models/admin_activity_log.dart';
import '../../data/models/admin_notification.dart';
import '../../data/models/support_ticket.dart';
import '../../data/models/system_setting.dart';
import '../../data/models/admin_dashboard_stats.dart';

// ============================================================================
// REPOSITORY PROVIDER
// ============================================================================

/// Admin repository provider
final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository();
});

// ============================================================================
// DASHBOARD PROVIDERS
// ============================================================================

/// Dashboard statistics provider
final adminDashboardStatsProvider = FutureProvider<AdminDashboardStats>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getDashboardStats();
});

/// Daily analytics provider
final dailyAnalyticsProvider = FutureProvider.family<List<DailyAnalytics>, int>((ref, days) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getDailyAnalytics(days: days);
});

/// User statistics provider
final userStatisticsProvider = FutureProvider<List<UserStatistics>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getUserStatistics();
});

/// Vendor performance provider
final vendorPerformanceProvider = FutureProvider.family<List<VendorPerformance>, Map<String, dynamic>>((ref, params) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getVendorPerformance(
    limit: params['limit'] ?? 50,
    offset: params['offset'] ?? 0,
  );
});

// ============================================================================
// USER MANAGEMENT PROVIDERS
// ============================================================================

/// Admin user management state
class AdminUserManagementState {
  final List<AdminUser> users;
  final bool isLoading;
  final String? errorMessage;
  final String? searchQuery;
  final String? selectedRole;
  final bool? isVerifiedFilter;
  final bool? isActiveFilter;
  final int currentPage;
  final bool hasMore;

  const AdminUserManagementState({
    this.users = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery,
    this.selectedRole,
    this.isVerifiedFilter,
    this.isActiveFilter,
    this.currentPage = 0,
    this.hasMore = true,
  });

  AdminUserManagementState copyWith({
    List<AdminUser>? users,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedRole,
    bool? isVerifiedFilter,
    bool? isActiveFilter,
    int? currentPage,
    bool? hasMore,
  }) {
    return AdminUserManagementState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedRole: selectedRole ?? this.selectedRole,
      isVerifiedFilter: isVerifiedFilter ?? this.isVerifiedFilter,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
      currentPage: currentPage ?? this.currentPage,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

/// Admin user management notifier
class AdminUserManagementNotifier extends StateNotifier<AdminUserManagementState> {
  final AdminRepository _repository;

  AdminUserManagementNotifier(this._repository) : super(const AdminUserManagementState()) {
    loadUsers();
  }

  /// Load users with current filters
  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(currentPage: 0, hasMore: true);
    }

    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final users = await _repository.getUsers(
        searchQuery: state.searchQuery,
        role: state.selectedRole,
        isVerified: state.isVerifiedFilter,
        isActive: state.isActiveFilter,
        limit: 50,
        offset: state.currentPage * 50,
      );

      if (refresh || state.currentPage == 0) {
        state = state.copyWith(
          users: users,
          isLoading: false,
          hasMore: users.length == 50,
        );
      } else {
        state = state.copyWith(
          users: [...state.users, ...users],
          isLoading: false,
          hasMore: users.length == 50,
        );
      }
    } catch (e) {
      debugPrint('🔍 AdminUserManagementNotifier: Error loading users: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load more users (pagination)
  Future<void> loadMoreUsers() async {
    if (!state.hasMore || state.isLoading) return;

    state = state.copyWith(currentPage: state.currentPage + 1);
    await loadUsers();
  }

  /// Search users
  Future<void> searchUsers(String query) async {
    state = state.copyWith(searchQuery: query.isEmpty ? null : query);
    await loadUsers(refresh: true);
  }

  /// Filter by role
  Future<void> filterByRole(String? role) async {
    state = state.copyWith(selectedRole: role);
    await loadUsers(refresh: true);
  }

  /// Filter by verification status
  Future<void> filterByVerification(bool? isVerified) async {
    state = state.copyWith(isVerifiedFilter: isVerified);
    await loadUsers(refresh: true);
  }

  /// Filter by active status
  Future<void> filterByActiveStatus(bool? isActive) async {
    state = state.copyWith(isActiveFilter: isActive);
    await loadUsers(refresh: true);
  }

  /// Update user status
  Future<void> updateUserStatus(String userId, bool isActive, {String? reason}) async {
    try {
      await _repository.updateUserStatus(userId, isActive, reason: reason);
      
      // Update local state
      final updatedUsers = state.users.map((user) {
        return user.id == userId ? user.copyWith(isActive: isActive) : user;
      }).toList();
      
      state = state.copyWith(users: updatedUsers);
      
      // Refresh to get latest data
      await loadUsers(refresh: true);
    } catch (e) {
      debugPrint('🔍 AdminUserManagementNotifier: Error updating user status: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Update user role
  Future<void> updateUserRole(String userId, String newRole, {String? reason}) async {
    try {
      await _repository.updateUserRole(userId, newRole, reason: reason);
      
      // Refresh to get latest data
      await loadUsers(refresh: true);
    } catch (e) {
      debugPrint('🔍 AdminUserManagementNotifier: Error updating user role: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Create new user
  Future<void> createUser(Map<String, dynamic> userData) async {
    try {
      await _repository.createUser(userData);

      // Refresh to get latest data including the new user
      await loadUsers(refresh: true);
    } catch (e) {
      debugPrint('🔍 AdminUserManagementNotifier: Error creating user: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> updates) async {
    try {
      await _repository.updateUser(userId, updates);

      // Refresh to get latest data
      await loadUsers(refresh: true);
    } catch (e) {
      debugPrint('🔍 AdminUserManagementNotifier: Error updating user: $e');
      state = state.copyWith(errorMessage: e.toString());
      rethrow;
    }
  }

  /// Delete user
  Future<void> deleteUser(String userId, {String? reason}) async {
    try {
      await _repository.deleteUser(userId, reason: reason);

      // Remove from local state
      final updatedUsers = state.users.where((user) => user.id != userId).toList();
      state = state.copyWith(users: updatedUsers);
    } catch (e) {
      debugPrint('🔍 AdminUserManagementNotifier: Error deleting user: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

/// Admin user management provider
final adminUserManagementProvider = StateNotifierProvider<AdminUserManagementNotifier, AdminUserManagementState>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return AdminUserManagementNotifier(repository);
});

/// Individual user provider
final adminUserByIdProvider = FutureProvider.family<AdminUser?, String>((ref, userId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getUserById(userId);
});

// ============================================================================
// ACTIVITY LOG PROVIDERS
// ============================================================================

/// Activity logs provider with filtering
final adminActivityLogsProvider = FutureProvider.family<List<AdminActivityLog>, ActivityLogFilter?>((ref, filter) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getActivityLogs(filter: filter);
});

/// Activity logs stream provider
final adminActivityLogsStreamProvider = StreamProvider<List<AdminActivityLog>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.streamActivityLogs(limit: 100);
});

// ============================================================================
// NOTIFICATION PROVIDERS
// ============================================================================

/// Admin notifications provider with filtering
final adminNotificationsProvider = FutureProvider.family<List<AdminNotification>, NotificationFilter?>((ref, filter) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getNotifications(filter: filter);
});

/// Admin notifications stream provider
final adminNotificationsStreamProvider = StreamProvider<List<AdminNotification>>((ref) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.streamNotifications();
});

/// Unread notifications count provider
final unreadAdminNotificationsCountProvider = Provider<int>((ref) {
  final notificationsAsync = ref.watch(adminNotificationsStreamProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => !n.isRead).length,
    loading: () => 0,
    error: (_, _) => 0,
  );
});

/// Critical notifications provider
final criticalAdminNotificationsProvider = Provider<List<AdminNotification>>((ref) {
  final notificationsAsync = ref.watch(adminNotificationsStreamProvider);
  return notificationsAsync.when(
    data: (notifications) => notifications.where((n) => n.priority >= 3 && !n.isRead).toList(),
    loading: () => [],
    error: (_, _) => [],
  );
});

// ============================================================================
// SUPPORT TICKET PROVIDERS
// ============================================================================

/// Support tickets provider with filtering
final supportTicketsProvider = FutureProvider.family<List<SupportTicket>, TicketFilter?>((ref, filter) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSupportTickets(filter: filter);
});

/// Support tickets stream provider
final supportTicketsStreamProvider = StreamProvider.family<List<SupportTicket>, Map<String, dynamic>?>((ref, params) {
  final repository = ref.watch(adminRepositoryProvider);
  return repository.streamSupportTickets(
    status: params?['status'],
    assignedAdminId: params?['assignedAdminId'],
  );
});

/// Individual support ticket provider
final supportTicketByIdProvider = FutureProvider.family<SupportTicket?, String>((ref, ticketId) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSupportTicketById(ticketId);
});

/// Ticket statistics provider
final ticketStatisticsProvider = FutureProvider<TicketStatistics>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getTicketStatistics();
});

// ============================================================================
// SYSTEM SETTINGS PROVIDERS
// ============================================================================

/// System settings provider with filtering
final systemSettingsProvider = FutureProvider.family<List<SystemSetting>, SettingsFilter?>((ref, filter) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSystemSettings(filter: filter);
});

/// Individual system setting provider
final systemSettingByKeyProvider = FutureProvider.family<SystemSetting?, String>((ref, settingKey) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSystemSetting(settingKey);
});

/// Public system settings provider (for non-admin users)
final publicSystemSettingsProvider = FutureProvider<List<SystemSetting>>((ref) async {
  final repository = ref.watch(adminRepositoryProvider);
  return await repository.getSystemSettings(
    filter: const SettingsFilter(isPublic: true),
  );
});
