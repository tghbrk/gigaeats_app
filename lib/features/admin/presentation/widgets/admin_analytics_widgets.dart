import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/admin_dashboard_stats.dart';
import '../providers/admin_providers_index.dart';
import 'admin_chart_widgets.dart';
import 'admin_export_widgets.dart';

/// Main analytics dashboard widget
class AnalyticsDashboard extends ConsumerStatefulWidget {
  const AnalyticsDashboard({super.key});

  @override
  ConsumerState<AnalyticsDashboard> createState() => _AnalyticsDashboardState();
}

class _AnalyticsDashboardState extends ConsumerState<AnalyticsDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load analytics data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminAnalyticsProvider.notifier).loadAnalyticsData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(adminAnalyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminAnalyticsProvider.notifier).loadAnalyticsData();
            },
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _showExportDialog(context),
            tooltip: 'Export Data',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.dashboard), text: 'Overview'),
            Tab(icon: Icon(Icons.trending_up), text: 'Revenue'),
            Tab(icon: Icon(Icons.people), text: 'Users'),
            Tab(icon: Icon(Icons.store), text: 'Vendors'),
          ],
        ),
      ),
      body: analyticsState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : analyticsState.errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading analytics data',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        analyticsState.errorMessage!,
                        style: Theme.of(context).textTheme.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () {
                          ref.read(adminAnalyticsProvider.notifier).loadAnalyticsData();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : TabBarView(
                  controller: _tabController,
                  children: const [
                    OverviewTab(),
                    RevenueTab(),
                    UsersTab(),
                    VendorsTab(),
                  ],
                ),
    );
  }

  void _showExportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ExportOptionsDialog(
        title: 'Analytics Data',
        availableFormats: const ['CSV', 'Excel'],
        onExport: (format, dateRange) async {
          try {
            final analyticsState = ref.read(adminAnalyticsProvider);

            // Show loading
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Exporting data...')),
              );
            }

            // Export based on current tab
            switch (_tabController.index) {
              case 0: // Overview
                if (analyticsState.dashboardStats != null) {
                  await AnalyticsExportService.exportDashboardStats(
                    stats: analyticsState.dashboardStats!,
                    format: format,
                    dateRange: dateRange,
                  );
                }
                break;
              case 1: // Revenue
                await AnalyticsExportService.exportDailyAnalytics(
                  analytics: analyticsState.dailyAnalytics,
                  format: format,
                  dateRange: dateRange,
                );
                break;
              case 2: // Users
                // Export user statistics
                break;
              case 3: // Vendors
                await AnalyticsExportService.exportVendorPerformance(
                  vendors: analyticsState.vendorPerformance,
                  format: format,
                );
                break;
            }

            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Data exported successfully!')),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Export failed: $e')),
              );
            }
          }
        },
      ),
    );
  }
}

/// Overview tab with key metrics and performance
class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(adminAnalyticsProvider);
    final quickStats = ref.watch(adminQuickStatsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick Stats Grid
          Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.8, // Increased from 1.5 to provide more height and prevent overflow
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: quickStats.length,
            itemBuilder: (context, index) {
              final stat = quickStats[index];
              return QuickStatCard(stat: stat);
            },
          ),
          
          const SizedBox(height: 32),
          
          // Performance Metrics
          const PerformanceMetricsWidget(),
          
          const SizedBox(height: 32),
          
          // System Health Status
          if (analyticsState.systemHealth != null) ...[
            Text(
              'System Health',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SystemHealthWidget(health: analyticsState.systemHealth!),
          ],
        ],
      ),
    );
  }
}

/// Revenue analytics tab
class RevenueTab extends ConsumerWidget {
  const RevenueTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Trends',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Revenue Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Revenue (Last 30 Days)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const RevenueChart(height: 300),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Orders Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Orders (Last 30 Days)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const OrdersChart(height: 300),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick stat card widget
class QuickStatCard extends StatelessWidget {
  final QuickStat stat;

  const QuickStatCard({
    super.key,
    required this.stat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = _getStatColor(stat.color);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12), // Reduced padding from 16 to 12
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Added to prevent overflow
          children: [
            Row(
              children: [
                Icon(
                  _getStatIcon(stat.icon),
                  color: color,
                  size: 20, // Reduced icon size from 24 to 20
                ),
                const Spacer(),
                if (stat.trend != 'stable')
                  Icon(
                    stat.trend == 'up' ? Icons.trending_up : Icons.trending_down,
                    color: stat.trend == 'up' ? Colors.green : Colors.red,
                    size: 16, // Reduced trend icon size from 20 to 16
                  ),
              ],
            ),
            const SizedBox(height: 6), // Reduced spacing from 8 to 6
            Flexible( // Wrapped in Flexible to prevent overflow
              child: Text(
                stat.value,
                style: theme.textTheme.titleLarge?.copyWith( // Changed from headlineSmall to titleLarge
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 2), // Reduced spacing from 4 to 2
            Flexible( // Wrapped in Flexible to prevent overflow
              child: Text(
                stat.title,
                style: theme.textTheme.bodySmall?.copyWith( // Changed from bodyMedium to bodySmall
                  color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (stat.subtitle.isNotEmpty) ...[
              const SizedBox(height: 2), // Reduced spacing from 4 to 2
              Flexible( // Wrapped in Flexible to prevent overflow
                child: Text(
                  stat.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                    fontSize: 10, // Made subtitle even smaller
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatColor(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'green':
        return Colors.green;
      case 'orange':
        return Colors.orange;
      case 'purple':
        return Colors.purple;
      case 'red':
        return Colors.red;
      case 'teal':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  IconData _getStatIcon(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'people':
        return Icons.people;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'attach_money':
        return Icons.attach_money;
      case 'store':
        return Icons.store;
      case 'trending_up':
        return Icons.trending_up;
      case 'trending_down':
        return Icons.trending_down;
      default:
        return Icons.analytics;
    }
  }
}

/// System health status widget
class SystemHealthWidget extends StatelessWidget {
  final SystemHealthStatus health;

  const SystemHealthWidget({
    super.key,
    required this.health,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isHealthy = health.status == 'healthy';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isHealthy ? Icons.check_circle : Icons.warning,
                  color: isHealthy ? Colors.green : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  isHealthy ? 'System Healthy' : 'System Issues Detected',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isHealthy ? Colors.green : Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Health metrics
            _buildHealthMetric('CPU Usage', '${health.cpuUsage.toStringAsFixed(1)}%', theme),
            _buildHealthMetric('Memory Usage', '${health.memoryUsage.toStringAsFixed(1)}%', theme),
            _buildHealthMetric('Disk Usage', '${health.diskUsage.toStringAsFixed(1)}%', theme),
            _buildHealthMetric('Response Time', '${health.responseTime.toStringAsFixed(1)}ms', theme),
            _buildHealthMetric('Active Connections', health.activeConnections.toString(), theme),

            if (health.alerts.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Alerts:',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ...health.alerts.map((alert) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 16, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert)),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthMetric(String name, String status, ThemeData theme) {
    final isHealthy = status.toLowerCase() == 'healthy' || status.toLowerCase() == 'online';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isHealthy ? Colors.green : Colors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(name)),
          Text(
            status,
            style: TextStyle(
              color: isHealthy ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Users analytics tab
class UsersTab extends ConsumerWidget {
  const UsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // User Distribution Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'User Distribution by Role',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const UserStatsChart(height: 300),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // User Statistics Table
          const UserStatisticsTable(),
        ],
      ),
    );
  }
}

/// Vendors analytics tab
class VendorsTab extends ConsumerWidget {
  const VendorsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Vendor Performance',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          // Vendor Performance Chart
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top 10 Vendors by Revenue (Last 30 Days)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const VendorPerformanceChart(height: 300),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Vendor Performance Table
          const VendorPerformanceTable(),
        ],
      ),
    );
  }
}

/// User statistics table widget
class UserStatisticsTable extends ConsumerWidget {
  const UserStatisticsTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userStatsAsync = ref.watch(userStatisticsProvider);
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'User Statistics by Role',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            userStatsAsync.when(
              data: (stats) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 20, // Reduced column spacing
                  columns: const [
                    DataColumn(label: Text('Role')),
                    DataColumn(label: Text('Total')),
                    DataColumn(label: Text('Verified')),
                    DataColumn(label: Text('New')),
                    DataColumn(label: Text('Active')),
                  ],
                  rows: stats.map((stat) => DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 80,
                          child: Text(
                            stat.role.toUpperCase(),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 50,
                          child: Text(
                            stat.totalUsers.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 50,
                          child: Text(
                            stat.verifiedUsers.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 40,
                          child: Text(
                            stat.newThisWeek.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 50,
                          child: Text(
                            stat.activeThisWeek.toString(),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  )).toList(),
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading user statistics: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Vendor performance table widget
class VendorPerformanceTable extends ConsumerWidget {
  const VendorPerformanceTable({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vendorPerformanceAsync = ref.watch(vendorPerformanceProvider({'limit': 20, 'offset': 0}));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendor Performance Details',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            vendorPerformanceAsync.when(
              data: (vendors) => SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Business Name')),
                    DataColumn(label: Text('Rating')),
                    DataColumn(label: Text('Total Orders')),
                    DataColumn(label: Text('30-Day Orders')),
                    DataColumn(label: Text('30-Day Revenue')),
                    DataColumn(label: Text('Avg Order Value')),
                    DataColumn(label: Text('Cancelled Orders')),
                  ],
                  rows: vendors.map((vendor) => DataRow(
                    cells: [
                      DataCell(
                        SizedBox(
                          width: 120,
                          child: Text(
                            vendor.businessName,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      DataCell(Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(vendor.rating.toStringAsFixed(1)),
                        ],
                      )),
                      DataCell(Text(vendor.totalOrders.toString())),
                      DataCell(Text(vendor.ordersLast30Days.toString())),
                      DataCell(Text('RM ${vendor.revenueLast30Days.toStringAsFixed(2)}')),
                      DataCell(Text('RM ${vendor.avgOrderValue.toStringAsFixed(2)}')),
                      DataCell(Text(vendor.cancelledOrdersLast30Days.toString())),
                    ],
                  )).toList(),
                ),
              ),
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text('Error loading vendor performance: $error'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
