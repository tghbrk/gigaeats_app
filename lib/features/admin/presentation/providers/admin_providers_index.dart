// ============================================================================
// GIGAEATS ADMIN PROVIDERS INDEX
// ============================================================================
// 
// This file exports all admin-related Riverpod providers for easy importing
// throughout the admin interface. It provides a centralized access point
// for all admin functionality providers.
//
// Usage:
// import 'package:gigaeats_app/features/admin/presentation/providers/admin_providers_index.dart';
//
// ============================================================================

// Core admin providers
export 'admin_providers.dart';

// Admin operations providers
export 'admin_operations_provider.dart';

// Admin analytics providers
export 'admin_analytics_provider.dart';

// Admin real-time providers
export 'admin_realtime_provider.dart';

// Admin notification settings providers (existing)
export 'admin_notification_settings_provider.dart';

// ============================================================================
// PROVIDER CATEGORIES SUMMARY
// ============================================================================

/// CORE ADMIN PROVIDERS (admin_providers.dart):
/// 
/// Repository:
/// - adminRepositoryProvider
/// 
/// Dashboard:
/// - adminDashboardStatsProvider
/// - dailyAnalyticsProvider
/// - userStatisticsProvider
/// - vendorPerformanceProvider
/// 
/// User Management:
/// - adminUserManagementProvider (StateNotifier)
/// - adminUserByIdProvider
/// 
/// Activity Logs:
/// - adminActivityLogsProvider
/// - adminActivityLogsStreamProvider
/// 
/// Notifications:
/// - adminNotificationsProvider
/// - adminNotificationsStreamProvider
/// - unreadAdminNotificationsCountProvider
/// - criticalAdminNotificationsProvider
/// 
/// Support Tickets:
/// - supportTicketsProvider
/// - supportTicketsStreamProvider
/// - supportTicketByIdProvider
/// - ticketStatisticsProvider
/// 
/// System Settings:
/// - systemSettingsProvider
/// - systemSettingByKeyProvider
/// - publicSystemSettingsProvider

/// ADMIN OPERATIONS PROVIDERS (admin_operations_provider.dart):
/// 
/// Operations State:
/// - adminOperationsProvider (StateNotifier)
/// 
/// Features:
/// - Create/manage notifications
/// - Support ticket operations
/// - System settings management
/// - Bulk operations
/// - Operation loading states

/// ADMIN ANALYTICS PROVIDERS (admin_analytics_provider.dart):
/// 
/// Analytics State:
/// - adminAnalyticsProvider (StateNotifier)
/// 
/// Chart Data:
/// - adminQuickStatsProvider
/// - adminRevenueChartProvider
/// - adminOrderChartProvider
/// - adminUserStatsChartProvider
/// 
/// Features:
/// - Performance metrics calculation
/// - System health monitoring
/// - Recent activity generation
/// - Chart data transformation

/// ADMIN REAL-TIME PROVIDERS (admin_realtime_provider.dart):
/// 
/// Real-time State:
/// - adminRealtimeProvider (StateNotifier)
/// 
/// Live Data:
/// - adminUnreadNotificationsCountProvider
/// - adminCriticalNotificationsCountProvider
/// - adminUrgentTicketsCountProvider
/// - adminRecentActivityProvider
/// - adminConnectionStatusProvider
/// - adminLastUpdateProvider
/// 
/// Features:
/// - Real-time notifications
/// - Live activity logs
/// - Support ticket updates
/// - Dashboard auto-refresh
/// - Connection monitoring

/// ADMIN NOTIFICATION SETTINGS PROVIDERS (admin_notification_settings_provider.dart):
/// 
/// Settings State:
/// - adminNotificationSettingsProvider (StateNotifier)
/// 
/// Categories:
/// - adminNotificationCategoriesProvider
/// 
/// Features:
/// - Notification preferences management
/// - Category-based settings
/// - Preference persistence

// ============================================================================
// USAGE EXAMPLES
// ============================================================================

/// Example 1: Dashboard Statistics
/// ```dart
/// class AdminDashboard extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final dashboardStatsAsync = ref.watch(adminDashboardStatsProvider);
///     final quickStats = ref.watch(adminQuickStatsProvider);
///     
///     return dashboardStatsAsync.when(
///       data: (stats) => DashboardContent(stats: stats, quickStats: quickStats),
///       loading: () => const CircularProgressIndicator(),
///       error: (error, stack) => ErrorWidget(error),
///     );
///   }
/// }
/// ```

/// Example 2: User Management
/// ```dart
/// class UserManagementScreen extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final userManagementState = ref.watch(adminUserManagementProvider);
///     final notifier = ref.read(adminUserManagementProvider.notifier);
///     
///     return Column(
///       children: [
///         SearchBar(onSearch: notifier.searchUsers),
///         UserList(users: userManagementState.users),
///         if (userManagementState.hasMore)
///           LoadMoreButton(onPressed: notifier.loadMoreUsers),
///       ],
///     );
///   }
/// }
/// ```

/// Example 3: Real-time Notifications
/// ```dart
/// class NotificationBadge extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final unreadCount = ref.watch(adminUnreadNotificationsCountProvider);
///     final criticalCount = ref.watch(adminCriticalNotificationsCountProvider);
///     
///     return Badge(
///       count: unreadCount,
///       color: criticalCount > 0 ? Colors.red : Colors.blue,
///       child: const Icon(Icons.notifications),
///     );
///   }
/// }
/// ```

/// Example 4: Operations with Loading States
/// ```dart
/// class UserActionButton extends ConsumerWidget {
///   final String userId;
///   final bool currentStatus;
///   
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final operationsState = ref.watch(adminOperationsProvider);
///     final isLoading = operationsState.isOperationLoading('update_user_status');
///     
///     return ElevatedButton(
///       onPressed: isLoading ? null : () {
///         ref.read(adminUserManagementProvider.notifier)
///           .updateUserStatus(userId, !currentStatus);
///       },
///       child: isLoading 
///         ? const CircularProgressIndicator()
///         : Text(currentStatus ? 'Deactivate' : 'Activate'),
///     );
///   }
/// }
/// ```

/// Example 5: Analytics Charts
/// ```dart
/// class RevenueChart extends ConsumerWidget {
///   @override
///   Widget build(BuildContext context, WidgetRef ref) {
///     final revenueData = ref.watch(adminRevenueChartProvider);
///     final orderData = ref.watch(adminOrderChartProvider);
///     
///     return LineChart(
///       data: revenueData,
///       secondaryData: orderData,
///       title: 'Revenue & Orders Trend',
///     );
///   }
/// }
/// ```

// ============================================================================
// PROVIDER DEPENDENCIES
// ============================================================================

/// Provider Dependency Graph:
/// 
/// adminRepositoryProvider (base)
/// ├── adminDashboardStatsProvider
/// ├── adminUserManagementProvider
/// ├── adminNotificationsStreamProvider
/// ├── supportTicketsStreamProvider
/// └── systemSettingsProvider
/// 
/// adminAnalyticsProvider
/// ├── depends on: adminDashboardStatsProvider
/// ├── depends on: dailyAnalyticsProvider
/// ├── depends on: userStatisticsProvider
/// └── provides: chart data providers
/// 
/// adminRealtimeProvider
/// ├── depends on: adminNotificationsStreamProvider
/// ├── depends on: adminActivityLogsStreamProvider
/// ├── depends on: supportTicketsStreamProvider
/// └── provides: real-time count providers
/// 
/// adminOperationsProvider
/// ├── depends on: adminRepositoryProvider
/// └── triggers: refresh of other providers

// ============================================================================
// BEST PRACTICES
// ============================================================================

/// 1. Provider Usage:
/// - Use FutureProvider for one-time data fetching
/// - Use StreamProvider for real-time data
/// - Use StateNotifierProvider for complex state management
/// - Use Provider for computed values and transformations
/// 
/// 2. Error Handling:
/// - Always handle AsyncValue states (data, loading, error)
/// - Use try-catch in StateNotifier methods
/// - Provide meaningful error messages to users
/// 
/// 3. Performance:
/// - Use family providers for parameterized data
/// - Implement proper pagination for large datasets
/// - Use select() to prevent unnecessary rebuilds
/// - Cache expensive computations
/// 
/// 4. Real-time Updates:
/// - Use Supabase streams for live data
/// - Implement connection monitoring
/// - Handle stream errors gracefully
/// - Provide offline fallbacks
/// 
/// 5. State Management:
/// - Keep state immutable with copyWith()
/// - Use proper loading states for operations
/// - Clear errors after handling
/// - Implement optimistic updates where appropriate
