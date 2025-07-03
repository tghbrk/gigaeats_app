import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../data/models/admin_notification.dart';
import '../../data/models/admin_activity_log.dart';
import '../../data/models/support_ticket.dart';
import '../../data/models/admin_dashboard_stats.dart';
import 'admin_providers.dart';

// ============================================================================
// REAL-TIME STATE
// ============================================================================

/// Real-time admin state for managing live updates
class AdminRealtimeState {
  final List<AdminNotification> liveNotifications;
  final List<AdminActivityLog> liveActivityLogs;
  final List<SupportTicket> liveTickets;
  final AdminDashboardStats? liveDashboardStats;
  final bool isConnected;
  final String? connectionError;
  final DateTime? lastUpdate;
  final Map<String, int> updateCounts;

  const AdminRealtimeState({
    this.liveNotifications = const [],
    this.liveActivityLogs = const [],
    this.liveTickets = const [],
    this.liveDashboardStats,
    this.isConnected = false,
    this.connectionError,
    this.lastUpdate,
    this.updateCounts = const {},
  });

  AdminRealtimeState copyWith({
    List<AdminNotification>? liveNotifications,
    List<AdminActivityLog>? liveActivityLogs,
    List<SupportTicket>? liveTickets,
    AdminDashboardStats? liveDashboardStats,
    bool? isConnected,
    String? connectionError,
    DateTime? lastUpdate,
    Map<String, int>? updateCounts,
  }) {
    return AdminRealtimeState(
      liveNotifications: liveNotifications ?? this.liveNotifications,
      liveActivityLogs: liveActivityLogs ?? this.liveActivityLogs,
      liveTickets: liveTickets ?? this.liveTickets,
      liveDashboardStats: liveDashboardStats ?? this.liveDashboardStats,
      isConnected: isConnected ?? this.isConnected,
      connectionError: connectionError,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      updateCounts: updateCounts ?? this.updateCounts,
    );
  }

  /// Get update count for a specific type
  int getUpdateCount(String type) => updateCounts[type] ?? 0;
}

/// Admin real-time notifier
class AdminRealtimeNotifier extends StateNotifier<AdminRealtimeState> {
  final Ref _ref;
  Timer? _dashboardRefreshTimer;

  AdminRealtimeNotifier(this._ref) : super(const AdminRealtimeState()) {
    _initializeRealtimeConnections();
    _startDashboardRefreshTimer();
  }

  @override
  void dispose() {
    // Cancel all timers to prevent memory leaks
    _dashboardRefreshTimer?.cancel();
    _dashboardRefreshTimer = null;

    // Note: ref.listen subscriptions are automatically disposed by Riverpod
    // when the provider is disposed, so no manual cleanup needed for streams

    super.dispose();
  }

  /// Initialize real-time connections
  void _initializeRealtimeConnections() {
    _setupNotificationsStream();
    _setupActivityLogsStream();
    _setupTicketsStream();
  }

  /// Setup notifications real-time stream
  void _setupNotificationsStream() {
    try {
      // Use ref.listen for proper Riverpod stream handling
      _ref.listen<AsyncValue<List<AdminNotification>>>(
        adminNotificationsStreamProvider,
        (previous, next) {
          next.when(
            data: (notifications) {
              _updateNotifications(notifications);
            },
            loading: () {
              debugPrint('🔔 AdminRealtimeNotifier: Notifications loading...');
            },
            error: (error, stack) {
              debugPrint('🔔 AdminRealtimeNotifier: Notifications error: $error');
              state = state.copyWith(
                connectionError: 'Failed to load notifications: $error',
                isConnected: false,
              );
            },
          );
        },
      );
    } catch (e) {
      debugPrint('🔔 AdminRealtimeNotifier: Error setting up notifications stream: $e');
    }
  }

  /// Setup activity logs real-time stream
  void _setupActivityLogsStream() {
    try {
      // Use ref.listen for proper Riverpod stream handling
      _ref.listen<AsyncValue<List<AdminActivityLog>>>(
        adminActivityLogsStreamProvider,
        (previous, next) {
          next.when(
            data: (activityLogs) {
              _updateActivityLogs(activityLogs);
            },
            loading: () {
              debugPrint('📝 AdminRealtimeNotifier: Activity logs loading...');
            },
            error: (error, stack) {
              debugPrint('📝 AdminRealtimeNotifier: Activity logs error: $error');
            },
          );
        },
      );
    } catch (e) {
      debugPrint('📝 AdminRealtimeNotifier: Error setting up activity logs stream: $e');
    }
  }

  /// Setup support tickets real-time stream
  void _setupTicketsStream() {
    try {
      // Use ref.listen for proper Riverpod stream handling
      _ref.listen<AsyncValue<List<SupportTicket>>>(
        supportTicketsStreamProvider(null),
        (previous, next) {
          next.when(
            data: (tickets) {
              _updateTickets(tickets);
            },
            loading: () {
              debugPrint('🎫 AdminRealtimeNotifier: Tickets loading...');
            },
            error: (error, stack) {
              debugPrint('🎫 AdminRealtimeNotifier: Tickets error: $error');
            },
          );
        },
      );
    } catch (e) {
      debugPrint('🎫 AdminRealtimeNotifier: Error setting up tickets stream: $e');
    }
  }

  /// Start dashboard refresh timer
  void _startDashboardRefreshTimer() {
    _dashboardRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _refreshDashboardStats();
    });
  }

  /// Refresh dashboard statistics
  Future<void> _refreshDashboardStats() async {
    try {
      final dashboardStats = await _ref.read(adminDashboardStatsProvider.future);
      state = state.copyWith(
        liveDashboardStats: dashboardStats,
        lastUpdate: DateTime.now(),
        isConnected: true,
        connectionError: null,
      );
      
      _incrementUpdateCount('dashboard');
    } catch (e) {
      debugPrint('📊 AdminRealtimeNotifier: Error refreshing dashboard stats: $e');
      state = state.copyWith(
        connectionError: 'Failed to refresh dashboard: $e',
        isConnected: false,
      );
    }
  }

  /// Update notifications and track changes
  void _updateNotifications(List<AdminNotification> notifications) {
    final previousCount = state.liveNotifications.length;
    final newCount = notifications.length;
    
    state = state.copyWith(
      liveNotifications: notifications,
      lastUpdate: DateTime.now(),
      isConnected: true,
      connectionError: null,
    );

    if (newCount > previousCount) {
      _incrementUpdateCount('notifications');
      
      // Show new notification indicator
      final newNotifications = notifications.take(newCount - previousCount).toList();
      for (final notification in newNotifications) {
        _showNewNotificationIndicator(notification);
      }
    }
  }

  /// Update activity logs and track changes
  void _updateActivityLogs(List<AdminActivityLog> activityLogs) {
    final previousCount = state.liveActivityLogs.length;
    final newCount = activityLogs.length;
    
    state = state.copyWith(
      liveActivityLogs: activityLogs,
      lastUpdate: DateTime.now(),
    );

    if (newCount > previousCount) {
      _incrementUpdateCount('activity_logs');
    }
  }

  /// Update tickets and track changes
  void _updateTickets(List<SupportTicket> tickets) {
    final previousCount = state.liveTickets.length;
    final newCount = tickets.length;
    
    state = state.copyWith(
      liveTickets: tickets,
      lastUpdate: DateTime.now(),
    );

    if (newCount > previousCount) {
      _incrementUpdateCount('tickets');
      
      // Check for urgent tickets
      final urgentTickets = tickets.where((ticket) => 
        ticket.priority == TicketPriority.urgent && 
        ticket.status == TicketStatus.open
      ).toList();
      
      if (urgentTickets.isNotEmpty) {
        _showUrgentTicketAlert(urgentTickets.length);
      }
    }
  }

  /// Increment update count for a specific type
  void _incrementUpdateCount(String type) {
    final newUpdateCounts = Map<String, int>.from(state.updateCounts);
    newUpdateCounts[type] = (newUpdateCounts[type] ?? 0) + 1;
    state = state.copyWith(updateCounts: newUpdateCounts);
  }

  /// Show new notification indicator (could trigger UI notification)
  void _showNewNotificationIndicator(AdminNotification notification) {
    debugPrint('🔔 New admin notification: ${notification.title}');
    
    // Could trigger a local notification or UI indicator here
    if (notification.priority >= 3) {
      debugPrint('🚨 Critical notification received: ${notification.title}');
    }
  }

  /// Show urgent ticket alert
  void _showUrgentTicketAlert(int urgentCount) {
    debugPrint('🚨 $urgentCount urgent support tickets require attention');
    
    // Could trigger an alert dialog or notification here
  }

  /// Get unread notifications count
  int get unreadNotificationsCount {
    return state.liveNotifications.where((n) => !n.isRead).length;
  }

  /// Get critical notifications count
  int get criticalNotificationsCount {
    return state.liveNotifications.where((n) => n.priority >= 3 && !n.isRead).length;
  }

  /// Get urgent tickets count
  int get urgentTicketsCount {
    return state.liveTickets.where((t) => 
      t.priority == TicketPriority.urgent && 
      t.status == TicketStatus.open
    ).length;
  }

  /// Get recent activity (last 10 items)
  List<AdminActivityLog> get recentActivity {
    return state.liveActivityLogs.take(10).toList();
  }

  /// Force refresh all data
  Future<void> forceRefresh() async {
    state = state.copyWith(isConnected: false);

    // Reinitialize connections (ref.listen will automatically handle cleanup)
    _initializeRealtimeConnections();
    await _refreshDashboardStats();
  }

  /// Clear connection error
  void clearConnectionError() {
    state = state.copyWith(connectionError: null);
  }

  /// Reset update counts
  void resetUpdateCounts() {
    state = state.copyWith(updateCounts: {});
  }
}

/// Admin real-time provider
final adminRealtimeProvider = StateNotifierProvider<AdminRealtimeNotifier, AdminRealtimeState>((ref) {
  return AdminRealtimeNotifier(ref);
});

/// Unread notifications count provider
final adminUnreadNotificationsCountProvider = Provider<int>((ref) {
  ref.watch(adminRealtimeProvider);
  return ref.read(adminRealtimeProvider.notifier).unreadNotificationsCount;
});

/// Critical notifications count provider
final adminCriticalNotificationsCountProvider = Provider<int>((ref) {
  ref.watch(adminRealtimeProvider);
  return ref.read(adminRealtimeProvider.notifier).criticalNotificationsCount;
});

/// Urgent tickets count provider
final adminUrgentTicketsCountProvider = Provider<int>((ref) {
  ref.watch(adminRealtimeProvider);
  return ref.read(adminRealtimeProvider.notifier).urgentTicketsCount;
});

/// Recent activity provider
final adminRecentActivityProvider = Provider<List<AdminActivityLog>>((ref) {
  ref.watch(adminRealtimeProvider);
  return ref.read(adminRealtimeProvider.notifier).recentActivity;
});

/// Connection status provider
final adminConnectionStatusProvider = Provider<bool>((ref) {
  final realtimeState = ref.watch(adminRealtimeProvider);
  return realtimeState.isConnected;
});

/// Last update time provider
final adminLastUpdateProvider = Provider<DateTime?>((ref) {
  final realtimeState = ref.watch(adminRealtimeProvider);
  return realtimeState.lastUpdate;
});
