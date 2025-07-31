import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/enhanced_driver_order_history_providers.dart';
import '../../data/models/grouped_order_history.dart';

/// Widget displaying comprehensive statistics for order history
class OrderHistoryStatistics extends ConsumerWidget {
  final EdgeInsetsGeometry? padding;
  final bool showDetailedStats;

  const OrderHistoryStatistics({
    super.key,
    this.padding,
    this.showDetailedStats = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final combinedFilter = ref.watch(combinedDateFilterProvider);
    final summaryAsync = ref.watch(orderHistorySummaryProvider(combinedFilter));

    return Container(
      padding: padding ?? const EdgeInsets.all(16),
      child: summaryAsync.when(
        data: (summary) => _buildStatistics(theme, summary),
        loading: () => _buildLoadingState(theme),
        error: (_, _) => _buildErrorState(theme),
      ),
    );
  }

  Widget _buildStatistics(ThemeData theme, OrderHistorySummary summary) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.analytics_outlined,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Performance Statistics',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Main stats grid
        _buildMainStatsGrid(theme, summary),
        
        if (showDetailedStats) ...[
          const SizedBox(height: 16),
          _buildDetailedStats(theme, summary),
        ],
      ],
    );
  }

  Widget _buildMainStatsGrid(ThemeData theme, OrderHistorySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // First row: Total Orders, Delivered, Cancelled
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Total Orders',
                    '${summary.totalOrders}',
                    Icons.receipt_long,
                    theme.colorScheme.primary,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Delivered',
                    '${summary.deliveredOrders}',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                if (summary.cancelledOrders > 0)
                  Expanded(
                    child: _buildStatItem(
                      theme,
                      'Cancelled',
                      '${summary.cancelledOrders}',
                      Icons.cancel,
                      theme.colorScheme.error,
                    ),
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Second row: Earnings and Success Rate
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Total Earnings',
                    'RM ${summary.totalEarnings.toStringAsFixed(2)}',
                    Icons.payments,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Success Rate',
                    '${(summary.deliverySuccessRate * 100).toStringAsFixed(1)}%',
                    Icons.trending_up,
                    summary.deliverySuccessRate >= 0.9 
                        ? Colors.green 
                        : summary.deliverySuccessRate >= 0.8 
                            ? Colors.orange 
                            : theme.colorScheme.error,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    theme,
                    'Avg per Order',
                    'RM ${summary.averageEarningsPerOrder.toStringAsFixed(2)}',
                    Icons.trending_flat,
                    theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(ThemeData theme, OrderHistorySummary summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Detailed Breakdown',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Performance indicators
            _buildPerformanceIndicator(
              theme,
              'Delivery Success Rate',
              summary.deliverySuccessRate,
              summary.deliverySuccessRate >= 0.9 
                  ? Colors.green 
                  : summary.deliverySuccessRate >= 0.8 
                      ? Colors.orange 
                      : theme.colorScheme.error,
            ),
            
            const SizedBox(height: 12),
            
            // Date range info
            if (summary.dateRange != null) ...[
              _buildInfoRow(
                theme,
                'Date Range',
                GroupedOrderHistory.getDateRangeDisplay(
                  summary.dateRange!.start,
                  summary.dateRange!.end,
                ),
                Icons.date_range,
              ),
              
              const SizedBox(height: 8),
              
              _buildInfoRow(
                theme,
                'Period Duration',
                '${summary.dateRange!.duration.inDays + 1} days',
                Icons.schedule,
              ),
            ],
            
            const SizedBox(height: 8),
            
            // Orders per day average
            if (summary.dateRange != null && summary.dateRange!.duration.inDays > 0)
              _buildInfoRow(
                theme,
                'Orders per Day',
                (summary.totalOrders / (summary.dateRange!.duration.inDays + 1)).toStringAsFixed(1),
                Icons.today,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildPerformanceIndicator(
    ThemeData theme,
    String label,
    double value,
    Color color,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${(value * 100).toStringAsFixed(1)}%',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: value,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 150,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: List.generate(3, (i) => Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                  child: Column(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
              )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Unable to load statistics',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
