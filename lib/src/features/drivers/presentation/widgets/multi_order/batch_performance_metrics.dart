import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery_batch.dart';
import '../../../data/models/batch_operation_results.dart';

/// Batch performance metrics widget for Phase 3 multi-order management
/// Displays comprehensive performance analytics and KPIs for delivery batches
class BatchPerformanceMetrics extends ConsumerWidget {
  final DeliveryBatch? batch;
  final BatchSummary? batchSummary;

  const BatchPerformanceMetrics({
    super.key,
    this.batch,
    this.batchSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (batch == null) {
      return _buildEmptyState(theme);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildPerformanceGrid(theme),
            const SizedBox(height: 16),
            _buildEfficiencyMetrics(theme),
            const SizedBox(height: 16),
            _buildTimeMetrics(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.analytics_outlined,
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No Performance Data',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Performance metrics will appear when you have an active batch',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.analytics,
          color: theme.colorScheme.primary,
          size: 24,
        ),
        const SizedBox(width: 8),
        Text(
          'Performance Metrics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _getPerformanceColor(theme).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getPerformanceColor(theme).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            _getPerformanceRating(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getPerformanceColor(theme),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceGrid(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Optimization Score',
                  '${batch!.optimizationScore?.toStringAsFixed(0) ?? '0'}%',
                  Icons.star,
                  _getOptimizationColor(theme),
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Completion Rate',
                  '${_calculateCompletionRate().toStringAsFixed(0)}%',
                  Icons.check_circle,
                  _getCompletionColor(theme),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Distance Efficiency',
                  '${_calculateDistanceEfficiency().toStringAsFixed(1)} km/order',
                  Icons.straighten,
                  theme.colorScheme.primary,
                ),
              ),
              Expanded(
                child: _buildMetricItem(
                  theme,
                  'Time Efficiency',
                  '${_calculateTimeEfficiency().toStringAsFixed(0)} min/order',
                  Icons.schedule,
                  theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildEfficiencyMetrics(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Efficiency Analysis',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        _buildEfficiencyBar(
          theme,
          'Route Optimization',
          batch!.optimizationScore ?? 0.0,
          100.0,
          _getOptimizationColor(theme),
        ),
        const SizedBox(height: 8),
        _buildEfficiencyBar(
          theme,
          'Order Completion',
          _calculateCompletionRate(),
          100.0,
          _getCompletionColor(theme),
        ),
        const SizedBox(height: 8),
        _buildEfficiencyBar(
          theme,
          'Time Utilization',
          _calculateTimeUtilization(),
          100.0,
          Colors.blue,
        ),
      ],
    );
  }

  Widget _buildEfficiencyBar(
    ThemeData theme,
    String label,
    double value,
    double maxValue,
    Color color,
  ) {
    final percentage = (value / maxValue).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '${value.toStringAsFixed(0)}%',
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ],
    );
  }

  Widget _buildTimeMetrics(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Analysis',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12.0),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              _buildTimeMetricRow(
                theme,
                'Estimated Duration',
                '${batch!.estimatedDurationMinutes ?? 0} min',
                Icons.schedule,
              ),
              const SizedBox(height: 8),
              _buildTimeMetricRow(
                theme,
                'Actual Duration',
                '${_calculateActualDuration()} min',
                Icons.timer,
              ),
              const SizedBox(height: 8),
              _buildTimeMetricRow(
                theme,
                'Time Variance',
                _calculateTimeVariance(),
                Icons.trending_up,
              ),
              const SizedBox(height: 8),
              _buildTimeMetricRow(
                theme,
                'Avg per Order',
                '${_calculateTimeEfficiency().toStringAsFixed(0)} min',
                Icons.access_time,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTimeMetricRow(
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
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
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

  // Performance calculation methods
  double _calculateCompletionRate() {
    if (batchSummary == null || batchSummary!.totalOrders == 0) return 0.0;
    return (batchSummary!.completedDeliveries / batchSummary!.totalOrders) * 100;
  }

  double _calculateDistanceEfficiency() {
    if (batchSummary == null || batchSummary!.totalOrders == 0) return 0.0;
    return (batch!.totalDistanceKm ?? 0.0) / batchSummary!.totalOrders;
  }

  double _calculateTimeEfficiency() {
    if (batchSummary == null || batchSummary!.totalOrders == 0) return 0.0;
    return (batch!.estimatedDurationMinutes ?? 0.0) / batchSummary!.totalOrders;
  }

  double _calculateTimeUtilization() {
    final estimated = batch!.estimatedDurationMinutes ?? 0.0;
    final actual = _calculateActualDuration();
    if (estimated == 0.0) return 0.0;
    return (actual / estimated) * 100;
  }

  double _calculateActualDuration() {
    if (batch!.actualCompletionTime == null) {
      // If not completed, calculate duration from start to now
      final now = DateTime.now();
      final start = batch!.actualStartTime ?? batch!.createdAt;
      return now.difference(start).inMinutes.toDouble();
    } else {
      // If completed, calculate actual duration
      final start = batch!.actualStartTime ?? batch!.createdAt;
      return batch!.actualCompletionTime!.difference(start).inMinutes.toDouble();
    }
  }

  String _calculateTimeVariance() {
    final estimated = batch!.estimatedDurationMinutes ?? 0.0;
    final actual = _calculateActualDuration();
    final variance = actual - estimated;
    
    if (variance > 0) {
      return '+${variance.toStringAsFixed(0)} min';
    } else if (variance < 0) {
      return '${variance.toStringAsFixed(0)} min';
    } else {
      return 'On time';
    }
  }

  String _getPerformanceRating() {
    final optimizationScore = batch!.optimizationScore ?? 0.0;
    final completionRate = _calculateCompletionRate();
    final averageScore = (optimizationScore + completionRate) / 2;

    if (averageScore >= 90) return 'Excellent';
    if (averageScore >= 80) return 'Good';
    if (averageScore >= 70) return 'Average';
    if (averageScore >= 60) return 'Below Average';
    return 'Poor';
  }

  Color _getPerformanceColor(ThemeData theme) {
    final optimizationScore = batch!.optimizationScore ?? 0.0;
    final completionRate = _calculateCompletionRate();
    final averageScore = (optimizationScore + completionRate) / 2;

    if (averageScore >= 90) return Colors.green;
    if (averageScore >= 80) return Colors.blue;
    if (averageScore >= 70) return Colors.orange;
    if (averageScore >= 60) return Colors.red[300]!;
    return theme.colorScheme.error;
  }

  Color _getOptimizationColor(ThemeData theme) {
    final score = batch!.optimizationScore ?? 0.0;
    if (score >= 90) return Colors.green;
    if (score >= 80) return Colors.blue;
    if (score >= 70) return Colors.orange;
    return theme.colorScheme.error;
  }

  Color _getCompletionColor(ThemeData theme) {
    final rate = _calculateCompletionRate();
    if (rate >= 90) return Colors.green;
    if (rate >= 80) return Colors.blue;
    if (rate >= 70) return Colors.orange;
    return theme.colorScheme.error;
  }
}
