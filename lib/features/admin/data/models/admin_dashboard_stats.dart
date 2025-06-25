import 'package:freezed_annotation/freezed_annotation.dart';

part 'admin_dashboard_stats.freezed.dart';
part 'admin_dashboard_stats.g.dart';

/// Admin dashboard statistics model
@freezed
class AdminDashboardStats with _$AdminDashboardStats {
  const factory AdminDashboardStats({
    @Default(0) int totalUsers,
    @Default(0) int totalOrders,
    @Default(0.0) double totalRevenue,
    @Default(0) int activeVendors,
    @Default(0) int pendingOrders,
    @Default(0) int todayOrders,
    @Default(0.0) double todayRevenue,
    @Default(0) int newUsersToday,
    @Default(0) int pendingVendors,
    @Default(0) int pendingTickets,
    @Default(0) int criticalNotifications,
    required DateTime lastUpdated,

    // Additional metrics
    @Default(0) int totalCustomers,
    @Default(0) int totalDrivers,
    @Default(0) int activeSalesAgents,
    @Default(0) int completedOrdersToday,
    @Default(0) int cancelledOrdersToday,
    @Default(0.0) double averageOrderValue,
    @Default(0.0) double conversionRate,
    @Default(0) int newCustomersToday,
    @Default(0) int activeDriversToday,
    @Default(0.0) double customerSatisfactionScore,
    @Default(0) int totalRefunds,
    @Default(0.0) double refundAmount,
    @Default(0) int systemErrors,
    @Default(0) int apiErrors,
  }) = _AdminDashboardStats;

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
    try {
      return AdminDashboardStats(
        totalUsers: json['total_users'] ?? json['totalUsers'] ?? 0,
        totalOrders: json['total_orders'] ?? json['totalOrders'] ?? 0,
        totalRevenue: (json['total_revenue'] ?? json['totalRevenue'] ?? 0).toDouble(),
        activeVendors: json['active_vendors'] ?? json['activeVendors'] ?? 0,
        pendingOrders: json['pending_orders'] ?? json['pendingOrders'] ?? 0,
        todayOrders: json['today_orders'] ?? json['todayOrders'] ?? 0,
        todayRevenue: (json['today_revenue'] ?? json['todayRevenue'] ?? 0).toDouble(),
        newUsersToday: json['new_users_today'] ?? json['newUsersToday'] ?? 0,
        pendingVendors: json['pending_vendors'] ?? json['pendingVendors'] ?? 0,
        pendingTickets: json['pending_tickets'] ?? json['pendingTickets'] ?? 0,
        criticalNotifications: json['critical_notifications'] ?? json['criticalNotifications'] ?? 0,
        lastUpdated: json['last_updated'] is String
            ? DateTime.parse(json['last_updated'])
            : json['last_updated'] ?? json['lastUpdated'] ?? DateTime.now(),
        totalCustomers: json['total_customers'] ?? json['totalCustomers'] ?? 0,
        totalDrivers: json['total_drivers'] ?? json['totalDrivers'] ?? 0,
        activeSalesAgents: json['active_sales_agents'] ?? json['activeSalesAgents'] ?? 0,
        completedOrdersToday: json['completed_orders_today'] ?? json['completedOrdersToday'] ?? 0,
        cancelledOrdersToday: json['cancelled_orders_today'] ?? json['cancelledOrdersToday'] ?? 0,
        averageOrderValue: (json['average_order_value'] ?? json['averageOrderValue'] ?? 0).toDouble(),
        conversionRate: (json['conversion_rate'] ?? json['conversionRate'] ?? 0).toDouble(),
        newCustomersToday: json['new_customers_today'] ?? json['newCustomersToday'] ?? 0,
        activeDriversToday: json['active_drivers_today'] ?? json['activeDriversToday'] ?? 0,
        customerSatisfactionScore: (json['customer_satisfaction_score'] ?? json['customerSatisfactionScore'] ?? 0).toDouble(),
        totalRefunds: json['total_refunds'] ?? json['totalRefunds'] ?? 0,
        refundAmount: (json['refund_amount'] ?? json['refundAmount'] ?? 0).toDouble(),
        systemErrors: json['system_errors'] ?? json['systemErrors'] ?? 0,
        apiErrors: json['api_errors'] ?? json['apiErrors'] ?? 0,
      );
    } catch (e) {
      throw FormatException('Failed to parse AdminDashboardStats from JSON: $e');
    }
  }
}

/// Quick stats for dashboard cards
@freezed
class QuickStat with _$QuickStat {
  const factory QuickStat({
    required String title,
    required String value,
    required String subtitle,
    required String icon,
    required String color,
    String? trend,
    double? trendValue,
    String? actionUrl,
  }) = _QuickStat;

  factory QuickStat.fromJson(Map<String, dynamic> json) =>
      _$QuickStatFromJson(json);
}

/// Chart data point
@freezed
class ChartDataPoint with _$ChartDataPoint {
  const factory ChartDataPoint({
    required String label,
    required double value,
    String? color,
    Map<String, dynamic>? metadata,
  }) = _ChartDataPoint;

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) =>
      _$ChartDataPointFromJson(json);
}

/// Time series data for charts
@freezed
class TimeSeriesData with _$TimeSeriesData {
  const factory TimeSeriesData({
    required DateTime timestamp,
    required double value,
    String? label,
    String? category,
  }) = _TimeSeriesData;

  factory TimeSeriesData.fromJson(Map<String, dynamic> json) {
    return TimeSeriesData(
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : json['timestamp'] ?? DateTime.now(),
      value: (json['value'] ?? 0).toDouble(),
      label: json['label'],
      category: json['category'],
    );
  }
}

/// System health status
@freezed
class SystemHealthStatus with _$SystemHealthStatus {
  const factory SystemHealthStatus({
    @Default('healthy') String status,
    @Default(0) int uptime,
    @Default(0.0) double cpuUsage,
    @Default(0.0) double memoryUsage,
    @Default(0.0) double diskUsage,
    @Default(0) int activeConnections,
    @Default(0.0) double responseTime,
    @Default(0) int errorRate,
    @Default([]) List<String> alerts,
    required DateTime lastChecked,
  }) = _SystemHealthStatus;

  factory SystemHealthStatus.fromJson(Map<String, dynamic> json) {
    return SystemHealthStatus(
      status: json['status'] ?? 'healthy',
      uptime: json['uptime'] ?? 0,
      cpuUsage: (json['cpu_usage'] ?? json['cpuUsage'] ?? 0).toDouble(),
      memoryUsage: (json['memory_usage'] ?? json['memoryUsage'] ?? 0).toDouble(),
      diskUsage: (json['disk_usage'] ?? json['diskUsage'] ?? 0).toDouble(),
      activeConnections: json['active_connections'] ?? json['activeConnections'] ?? 0,
      responseTime: (json['response_time'] ?? json['responseTime'] ?? 0).toDouble(),
      errorRate: json['error_rate'] ?? json['errorRate'] ?? 0,
      alerts: json['alerts'] is List
          ? List<String>.from(json['alerts'])
          : <String>[],
      lastChecked: json['last_checked'] is String
          ? DateTime.parse(json['last_checked'])
          : json['last_checked'] ?? json['lastChecked'] ?? DateTime.now(),
    );
  }
}

/// Recent activity item
@freezed
class RecentActivity with _$RecentActivity {
  const factory RecentActivity({
    required String id,
    required String title,
    required String description,
    required String type,
    required String icon,
    required DateTime timestamp,
    String? userId,
    String? userName,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) = _RecentActivity;

  factory RecentActivity.fromJson(Map<String, dynamic> json) {
    return RecentActivity(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      type: json['type'] as String,
      icon: json['icon'] as String,
      timestamp: json['timestamp'] is String
          ? DateTime.parse(json['timestamp'])
          : json['timestamp'] ?? DateTime.now(),
      userId: json['user_id'] ?? json['userId'],
      userName: json['user_name'] ?? json['userName'],
      actionUrl: json['action_url'] ?? json['actionUrl'],
      metadata: json['metadata'],
    );
  }
}

/// Performance metrics
@freezed
class PerformanceMetrics with _$PerformanceMetrics {
  const factory PerformanceMetrics({
    @Default(0.0) double orderFulfillmentRate,
    @Default(0.0) double customerRetentionRate,
    @Default(0.0) double vendorSatisfactionScore,
    @Default(0.0) double averageDeliveryTime,
    @Default(0.0) double systemUptime,
    @Default(0.0) double paymentSuccessRate,
    @Default(0) int totalTransactions,
    @Default(0.0) double revenueGrowthRate,
    @Default(0.0) double userGrowthRate,
    @Default(0.0) double churnRate,
  }) = _PerformanceMetrics;

  factory PerformanceMetrics.fromJson(Map<String, dynamic> json) {
    return PerformanceMetrics(
      orderFulfillmentRate: (json['order_fulfillment_rate'] ?? json['orderFulfillmentRate'] ?? 0).toDouble(),
      customerRetentionRate: (json['customer_retention_rate'] ?? json['customerRetentionRate'] ?? 0).toDouble(),
      vendorSatisfactionScore: (json['vendor_satisfaction_score'] ?? json['vendorSatisfactionScore'] ?? 0).toDouble(),
      averageDeliveryTime: (json['average_delivery_time'] ?? json['averageDeliveryTime'] ?? 0).toDouble(),
      systemUptime: (json['system_uptime'] ?? json['systemUptime'] ?? 0).toDouble(),
      paymentSuccessRate: (json['payment_success_rate'] ?? json['paymentSuccessRate'] ?? 0).toDouble(),
      totalTransactions: json['total_transactions'] ?? json['totalTransactions'] ?? 0,
      revenueGrowthRate: (json['revenue_growth_rate'] ?? json['revenueGrowthRate'] ?? 0).toDouble(),
      userGrowthRate: (json['user_growth_rate'] ?? json['userGrowthRate'] ?? 0).toDouble(),
      churnRate: (json['churn_rate'] ?? json['churnRate'] ?? 0).toDouble(),
    );
  }
}

/// Dashboard configuration
@freezed
class DashboardConfig with _$DashboardConfig {
  const factory DashboardConfig({
    @Default(true) bool showQuickStats,
    @Default(true) bool showCharts,
    @Default(true) bool showRecentActivity,
    @Default(true) bool showSystemHealth,
    @Default(true) bool showNotifications,
    @Default(30) int refreshIntervalSeconds,
    @Default(['orders', 'revenue', 'users', 'vendors']) List<String> enabledWidgets,
    @Default('light') String theme,
    @Default('en') String language,
  }) = _DashboardConfig;

  factory DashboardConfig.fromJson(Map<String, dynamic> json) =>
      _$DashboardConfigFromJson(json);
}
