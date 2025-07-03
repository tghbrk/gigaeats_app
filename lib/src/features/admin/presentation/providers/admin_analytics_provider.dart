import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/admin_dashboard_stats.dart';
import '../../../user_management/domain/admin_user.dart';
import 'admin_providers.dart';

// ============================================================================
// ANALYTICS STATE
// ============================================================================

/// Analytics state for managing analytics data
class AdminAnalyticsState {
  final AdminDashboardStats? dashboardStats;
  final List<DailyAnalytics> dailyAnalytics;
  final List<UserStatistics> userStatistics;
  final List<VendorPerformance> vendorPerformance;
  final PerformanceMetrics? performanceMetrics;
  final SystemHealthStatus? systemHealth;
  final List<RecentActivity> recentActivity;
  final bool isLoading;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const AdminAnalyticsState({
    this.dashboardStats,
    this.dailyAnalytics = const [],
    this.userStatistics = const [],
    this.vendorPerformance = const [],
    this.performanceMetrics,
    this.systemHealth,
    this.recentActivity = const [],
    this.isLoading = false,
    this.errorMessage,
    this.lastUpdated,
  });

  AdminAnalyticsState copyWith({
    AdminDashboardStats? dashboardStats,
    List<DailyAnalytics>? dailyAnalytics,
    List<UserStatistics>? userStatistics,
    List<VendorPerformance>? vendorPerformance,
    PerformanceMetrics? performanceMetrics,
    SystemHealthStatus? systemHealth,
    List<RecentActivity>? recentActivity,
    bool? isLoading,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return AdminAnalyticsState(
      dashboardStats: dashboardStats ?? this.dashboardStats,
      dailyAnalytics: dailyAnalytics ?? this.dailyAnalytics,
      userStatistics: userStatistics ?? this.userStatistics,
      vendorPerformance: vendorPerformance ?? this.vendorPerformance,
      performanceMetrics: performanceMetrics ?? this.performanceMetrics,
      systemHealth: systemHealth ?? this.systemHealth,
      recentActivity: recentActivity ?? this.recentActivity,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Admin analytics notifier
class AdminAnalyticsNotifier extends StateNotifier<AdminAnalyticsState> {
  final Ref _ref;

  AdminAnalyticsNotifier(this._ref) : super(const AdminAnalyticsState()) {
    loadAnalyticsData();
  }

  /// Load all analytics data
  Future<void> loadAnalyticsData({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Load dashboard stats
      final dashboardStatsAsync = _ref.read(adminDashboardStatsProvider.future);
      
      // Load daily analytics (last 30 days)
      final dailyAnalyticsAsync = _ref.read(dailyAnalyticsProvider(30).future);
      
      // Load user statistics
      final userStatsAsync = _ref.read(userStatisticsProvider.future);
      
      // Load vendor performance
      final vendorPerformanceAsync = _ref.read(vendorPerformanceProvider({'limit': 20, 'offset': 0}).future);

      // Wait for all data
      final results = await Future.wait([
        dashboardStatsAsync,
        dailyAnalyticsAsync,
        userStatsAsync,
        vendorPerformanceAsync,
      ]);

      final dashboardStats = results[0] as AdminDashboardStats;
      final dailyAnalytics = results[1] as List<DailyAnalytics>;
      final userStatistics = results[2] as List<UserStatistics>;
      final vendorPerformance = results[3] as List<VendorPerformance>;

      // Calculate performance metrics
      final performanceMetrics = _calculatePerformanceMetrics(
        dashboardStats,
        dailyAnalytics,
        userStatistics,
      );

      // Generate system health status
      final systemHealth = _generateSystemHealthStatus(dashboardStats);

      // Generate recent activity
      final recentActivity = _generateRecentActivity(dashboardStats);

      state = state.copyWith(
        dashboardStats: dashboardStats,
        dailyAnalytics: dailyAnalytics,
        userStatistics: userStatistics,
        vendorPerformance: vendorPerformance,
        performanceMetrics: performanceMetrics,
        systemHealth: systemHealth,
        recentActivity: recentActivity,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('🔍 AdminAnalyticsNotifier: Error loading analytics data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Calculate performance metrics from available data
  PerformanceMetrics _calculatePerformanceMetrics(
    AdminDashboardStats dashboardStats,
    List<DailyAnalytics> dailyAnalytics,
    List<UserStatistics> userStatistics,
  ) {
    // Calculate order fulfillment rate
    final totalOrders = dashboardStats.totalOrders;
    final completedOrders = dailyAnalytics.fold<int>(
      0, (sum, day) => sum + day.completedOrders
    );
    final orderFulfillmentRate = totalOrders > 0 ? (completedOrders / totalOrders) * 100 : 0.0;

    // Calculate customer retention rate (simplified)
    final totalCustomers = dashboardStats.totalCustomers;
    final newCustomersToday = dashboardStats.newCustomersToday;
    final customerRetentionRate = totalCustomers > 0 && newCustomersToday > 0 
        ? ((totalCustomers - newCustomersToday) / totalCustomers) * 100 
        : 95.0; // Default assumption

    // Calculate revenue growth rate (last 7 days vs previous 7 days)
    final last7Days = dailyAnalytics.take(7).fold<double>(
      0.0, (sum, day) => sum + day.dailyRevenue
    );
    final previous7Days = dailyAnalytics.skip(7).take(7).fold<double>(
      0.0, (sum, day) => sum + day.dailyRevenue
    );
    final revenueGrowthRate = previous7Days > 0 
        ? ((last7Days - previous7Days) / previous7Days) * 100 
        : 0.0;

    // Calculate user growth rate
    final totalUsers = userStatistics.fold<int>(0, (sum, stat) => sum + stat.totalUsers);
    final newUsersThisWeek = userStatistics.fold<int>(0, (sum, stat) => sum + stat.newThisWeek);
    final userGrowthRate = totalUsers > 0 && newUsersThisWeek > 0
        ? (newUsersThisWeek / totalUsers) * 100
        : 0.0;

    return PerformanceMetrics(
      orderFulfillmentRate: orderFulfillmentRate,
      customerRetentionRate: customerRetentionRate,
      vendorSatisfactionScore: 4.2, // Mock data - would come from surveys
      averageDeliveryTime: 35.5, // Mock data - would come from order tracking
      systemUptime: 99.8, // Mock data - would come from monitoring
      paymentSuccessRate: 98.5, // Mock data - would come from payment logs
      totalTransactions: totalOrders,
      revenueGrowthRate: revenueGrowthRate,
      userGrowthRate: userGrowthRate,
      churnRate: 2.1, // Mock data - would be calculated from user activity
    );
  }

  /// Generate system health status
  SystemHealthStatus _generateSystemHealthStatus(AdminDashboardStats dashboardStats) {
    final alerts = <String>[];
    
    // Check for critical notifications
    if (dashboardStats.criticalNotifications > 0) {
      alerts.add('${dashboardStats.criticalNotifications} critical notifications pending');
    }
    
    // Check for pending tickets
    if (dashboardStats.pendingTickets > 10) {
      alerts.add('High number of pending support tickets (${dashboardStats.pendingTickets})');
    }
    
    // Check for pending vendors
    if (dashboardStats.pendingVendors > 5) {
      alerts.add('${dashboardStats.pendingVendors} vendors awaiting approval');
    }

    // Determine overall status
    String status = 'healthy';
    if (alerts.isNotEmpty) {
      status = alerts.length > 2 ? 'critical' : 'warning';
    }

    return SystemHealthStatus(
      status: status,
      uptime: 99800, // Mock uptime in seconds
      cpuUsage: 45.2, // Mock CPU usage
      memoryUsage: 67.8, // Mock memory usage
      diskUsage: 23.4, // Mock disk usage
      activeConnections: dashboardStats.totalUsers,
      responseTime: 120.5, // Mock response time in ms
      errorRate: 0, // Mock error rate
      alerts: alerts,
      lastChecked: DateTime.now(),
    );
  }

  /// Generate recent activity items
  List<RecentActivity> _generateRecentActivity(AdminDashboardStats dashboardStats) {
    final activities = <RecentActivity>[];
    final now = DateTime.now();

    // Add activities based on dashboard stats
    if (dashboardStats.newUsersToday > 0) {
      activities.add(RecentActivity(
        id: 'new_users_today',
        title: 'New User Registrations',
        description: '${dashboardStats.newUsersToday} new users registered today',
        type: 'user_registration',
        icon: 'person_add',
        timestamp: now.subtract(const Duration(hours: 2)),
      ));
    }

    if (dashboardStats.todayOrders > 0) {
      activities.add(RecentActivity(
        id: 'today_orders',
        title: 'Orders Processed',
        description: '${dashboardStats.todayOrders} orders processed today',
        type: 'order_processing',
        icon: 'shopping_cart',
        timestamp: now.subtract(const Duration(hours: 1)),
      ));
    }

    if (dashboardStats.pendingVendors > 0) {
      activities.add(RecentActivity(
        id: 'pending_vendors',
        title: 'Vendor Applications',
        description: '${dashboardStats.pendingVendors} vendor applications pending review',
        type: 'vendor_application',
        icon: 'store',
        timestamp: now.subtract(const Duration(hours: 3)),
      ));
    }

    return activities;
  }

  /// Get quick stats for dashboard cards
  List<QuickStat> getQuickStats() {
    if (state.dashboardStats == null) return [];

    final stats = state.dashboardStats!;
    
    return [
      QuickStat(
        title: 'Total Users',
        value: stats.totalUsers.toString(),
        subtitle: '+${stats.newUsersToday} today',
        icon: 'people',
        color: 'blue',
        trend: stats.newUsersToday > 0 ? 'up' : 'stable',
        trendValue: stats.newUsersToday.toDouble(),
      ),
      QuickStat(
        title: 'Total Orders',
        value: stats.totalOrders.toString(),
        subtitle: '${stats.todayOrders} today',
        icon: 'shopping_cart',
        color: 'green',
        trend: stats.todayOrders > 0 ? 'up' : 'stable',
        trendValue: stats.todayOrders.toDouble(),
      ),
      QuickStat(
        title: 'Total Revenue',
        value: 'RM ${stats.totalRevenue.toStringAsFixed(2)}',
        subtitle: 'RM ${stats.todayRevenue.toStringAsFixed(2)} today',
        icon: 'attach_money',
        color: 'orange',
        trend: stats.todayRevenue > 0 ? 'up' : 'stable',
        trendValue: stats.todayRevenue,
      ),
      QuickStat(
        title: 'Active Vendors',
        value: stats.activeVendors.toString(),
        subtitle: '${stats.pendingVendors} pending',
        icon: 'store',
        color: 'purple',
        trend: stats.pendingVendors > 0 ? 'warning' : 'stable',
        trendValue: stats.pendingVendors.toDouble(),
      ),
    ];
  }

  /// Get chart data for revenue trends
  List<TimeSeriesData> getRevenueChartData() {
    return state.dailyAnalytics.map((analytics) => TimeSeriesData(
      timestamp: analytics.date,
      value: analytics.dailyRevenue,
      label: 'Revenue',
      category: 'daily',
    )).toList();
  }

  /// Get chart data for order trends
  List<TimeSeriesData> getOrderChartData() {
    return state.dailyAnalytics.map((analytics) => TimeSeriesData(
      timestamp: analytics.date,
      value: analytics.completedOrders.toDouble(),
      label: 'Orders',
      category: 'daily',
    )).toList();
  }

  /// Get chart data for user statistics
  List<ChartDataPoint> getUserStatsChartData() {
    return state.userStatistics.map((stat) => ChartDataPoint(
      label: stat.role,
      value: stat.totalUsers.toDouble(),
      color: _getRoleColor(stat.role),
    )).toList();
  }

  /// Get role-specific color for charts
  String _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'customer': return '#4CAF50';
      case 'vendor': return '#FF9800';
      case 'driver': return '#2196F3';
      case 'sales_agent': return '#9C27B0';
      case 'admin': return '#F44336';
      default: return '#757575';
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh analytics data
  Future<void> refresh() async {
    await loadAnalyticsData(refresh: true);
  }
}

/// Admin analytics provider
final adminAnalyticsProvider = StateNotifierProvider<AdminAnalyticsNotifier, AdminAnalyticsState>((ref) {
  return AdminAnalyticsNotifier(ref);
});

/// Quick stats provider
final adminQuickStatsProvider = Provider<List<QuickStat>>((ref) {
  ref.watch(adminAnalyticsProvider);
  return ref.read(adminAnalyticsProvider.notifier).getQuickStats();
});

/// Revenue chart data provider
final adminRevenueChartProvider = Provider<List<TimeSeriesData>>((ref) {
  ref.watch(adminAnalyticsProvider);
  return ref.read(adminAnalyticsProvider.notifier).getRevenueChartData();
});

/// Order chart data provider
final adminOrderChartProvider = Provider<List<TimeSeriesData>>((ref) {
  ref.watch(adminAnalyticsProvider);
  return ref.read(adminAnalyticsProvider.notifier).getOrderChartData();
});

/// User stats chart data provider
final adminUserStatsChartProvider = Provider<List<ChartDataPoint>>((ref) {
  ref.watch(adminAnalyticsProvider);
  return ref.read(adminAnalyticsProvider.notifier).getUserStatsChartData();
});
