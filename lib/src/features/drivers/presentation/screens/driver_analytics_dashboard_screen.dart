import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../providers/batch_analytics_provider.dart';
import '../../data/models/batch_analytics_models.dart';

/// Driver analytics dashboard screen for Phase 4.2
/// Provides comprehensive performance insights and batch delivery reporting
class DriverAnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const DriverAnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<DriverAnalyticsDashboardScreen> createState() => _DriverAnalyticsDashboardScreenState();
}

class _DriverAnalyticsDashboardScreenState extends ConsumerState<DriverAnalyticsDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeAnalytics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeAnalytics() async {
    final analyticsNotifier = ref.read(batchAnalyticsProvider.notifier);
    await analyticsNotifier.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final analyticsState = ref.watch(batchAnalyticsProvider);

    // Check authentication and role
    if (authState.user == null || 
        (authState.user!.role != UserRole.driver && authState.user!.role != UserRole.admin)) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Analytics Dashboard'),
        ),
        body: const Center(
          child: Text('Access denied. Driver role required.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: analyticsState.isLoading ? null : _refreshAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Performance', icon: Icon(Icons.analytics)),
            Tab(text: 'Insights', icon: Icon(Icons.lightbulb_outline)),
            Tab(text: 'Reports', icon: Icon(Icons.assessment)),
          ],
        ),
      ),
      body: analyticsState.isLoading && !analyticsState.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPerformanceTab(theme, analyticsState),
                _buildInsightsTab(theme, analyticsState),
                _buildReportsTab(theme, analyticsState),
              ],
            ),
    );
  }

  Widget _buildPerformanceTab(ThemeData theme, BatchAnalyticsState analyticsState) {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Error display
            if (analyticsState.error != null) ...[
              _buildErrorCard(theme, analyticsState.error!),
              const SizedBox(height: 16),
            ],

            // Performance metrics overview
            _buildPerformanceOverview(theme, analyticsState.currentMetrics),
            const SizedBox(height: 24),

            // Performance charts
            _buildPerformanceCharts(theme, analyticsState.currentMetrics),
            const SizedBox(height: 24),

            // Recent activity
            _buildRecentActivity(theme, analyticsState.recentEvents),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightsTab(ThemeData theme, BatchAnalyticsState analyticsState) {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver performance insights
            _buildDriverInsights(theme, analyticsState.driverInsights),
            const SizedBox(height: 24),

            // Performance trends
            _buildPerformanceTrends(theme, analyticsState.driverInsights),
            const SizedBox(height: 24),

            // Recommendations
            _buildRecommendations(theme, analyticsState.driverInsights),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsTab(ThemeData theme, BatchAnalyticsState analyticsState) {
    return RefreshIndicator(
      onRefresh: _refreshAnalytics,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report summary
            _buildReportSummary(theme, analyticsState.recentReports),
            const SizedBox(height: 24),

            // Recent reports
            _buildRecentReports(theme, analyticsState.recentReports),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                error,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                color: theme.colorScheme.onErrorContainer,
              ),
              onPressed: () {
                ref.read(batchAnalyticsProvider.notifier).clearError();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceOverview(ThemeData theme, BatchPerformanceMetrics? metrics) {
    if (metrics == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No performance data available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete some deliveries to see your performance metrics',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Overview',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Total Batches',
                    metrics.totalBatches.toString(),
                    Icons.local_shipping,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Completion Rate',
                    '${(metrics.completionRate * 100).toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Avg Orders/Batch',
                    metrics.averageOrdersPerBatch.toStringAsFixed(1),
                    Icons.shopping_bag,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricCard(
                    theme,
                    'Efficiency Score',
                    '${(metrics.averageEfficiencyScore * 100).toStringAsFixed(0)}%',
                    Icons.speed,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard(
    ThemeData theme,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCharts(ThemeData theme, BatchPerformanceMetrics? metrics) {
    if (metrics == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true),
                  titlesData: FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateSampleSpots(),
                      isCurved: true,
                      color: theme.colorScheme.primary,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateSampleSpots() {
    // Generate sample data for demonstration
    return List.generate(7, (index) {
      return FlSpot(index.toDouble(), (index * 10 + 50).toDouble());
    });
  }

  Widget _buildDriverInsights(ThemeData theme, DriverPerformanceInsights? insights) {
    if (insights == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 48,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'No insights available',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Driver Performance Insights',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Overall Rating: ${insights.overallRating.toStringAsFixed(1)}/5.0',
              style: theme.textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Total Deliveries: ${insights.totalDeliveries}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'On-Time Rate: ${(insights.onTimeRate * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceTrends(ThemeData theme, DriverPerformanceInsights? insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Trends',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Trends will be displayed here based on historical data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations(ThemeData theme, DriverPerformanceInsights? insights) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommendations',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Personalized recommendations will appear here based on your performance data',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(ThemeData theme, List<AnalyticsEvent> events) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (events.isEmpty)
              Text(
                'No recent activity',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else
              ...events.take(5).map((event) => _buildActivityItem(theme, event)),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityItem(ThemeData theme, AnalyticsEvent event) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            _getEventIcon(event.eventType),
            size: 16,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _getEventDescription(event),
              style: theme.textTheme.bodySmall,
            ),
          ),
          Text(
            _formatEventTime(event.timestamp),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSummary(ThemeData theme, List<BatchDeliveryReport> reports) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Total Reports: ${reports.length}',
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentReports(ThemeData theme, List<BatchDeliveryReport> reports) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Reports',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (reports.isEmpty)
              Text(
                'No reports available',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              )
            else
              Text(
                'Reports will be displayed here',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getEventIcon(String eventType) {
    switch (eventType) {
      case 'batch_created':
        return Icons.add_circle_outline;
      case 'order_completed':
        return Icons.check_circle_outline;
      default:
        return Icons.event;
    }
  }

  String _getEventDescription(AnalyticsEvent event) {
    switch (event.eventType) {
      case 'batch_created':
        return 'Batch created with ${event.data['order_count']} orders';
      case 'order_completed':
        return 'Order completed successfully';
      default:
        return 'Analytics event: ${event.eventType}';
    }
  }

  String _formatEventTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Future<void> _refreshAnalytics() async {
    final analyticsNotifier = ref.read(batchAnalyticsProvider.notifier);
    await analyticsNotifier.refresh();
  }
}
