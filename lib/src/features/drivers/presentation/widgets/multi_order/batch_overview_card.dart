import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery_batch.dart';

/// Batch overview card displaying key metrics and status information
/// Follows Material Design 3 patterns with comprehensive batch visualization
class BatchOverviewCard extends ConsumerWidget {
  final DeliveryBatch? batch;
  final bool isLoading;
  final String? error;

  const BatchOverviewCard({
    super.key,
    this.batch,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    if (error != null) {
      return _buildErrorCard(theme, error!);
    }

    if (isLoading) {
      return _buildLoadingCard(theme);
    }

    if (batch == null) {
      return _buildEmptyCard(theme);
    }

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, theme, batch!),
            const SizedBox(height: 16),
            _buildMetricsRow(theme, batch!),
            const SizedBox(height: 16),
            _buildProgressSection(theme, batch!),
            const SizedBox(height: 16),
            _buildActionButtons(theme, batch!),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, DeliveryBatch batch) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            color: _getStatusColor(batch.status).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Icon(
            _getStatusIcon(batch.status),
            color: _getStatusColor(batch.status),
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Batch #${batch.id.substring(0, 8)}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 4.0,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(batch.status),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      batch.status.displayName,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${batch.maxOrders} max orders',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () => _showBatchMenu(context, batch),
          tooltip: 'Batch Options',
        ),
      ],
    );
  }

  Widget _buildMetricsRow(ThemeData theme, DeliveryBatch batch) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            theme,
            icon: Icons.route,
            label: 'Distance',
            value: batch.totalDistanceKm != null
                ? '${batch.totalDistanceKm!.toStringAsFixed(1)}km'
                : 'N/A',
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme,
            icon: Icons.access_time,
            label: 'Est. Time',
            value: batch.estimatedDurationMinutes != null
                ? '${batch.estimatedDurationMinutes}min'
                : 'N/A',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildMetricCard(
            theme,
            icon: Icons.trending_up,
            label: 'Efficiency',
            value: batch.optimizationScore != null
                ? '${batch.optimizationScore!.toStringAsFixed(0)}%'
                : 'N/A',
            color: Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: color,
            size: 20,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(ThemeData theme, DeliveryBatch batch) {
    // For now, show basic progress based on batch status
    final progressPercentage = _getProgressPercentage(batch);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${progressPercentage.toStringAsFixed(0)}%',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progressPercentage / 100,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(progressPercentage),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _buildProgressItem(
              theme,
              icon: Icons.check_circle,
              label: 'Completed',
              count: batch.status == BatchStatus.completed ? batch.maxOrders : 0,
              color: Colors.green,
            ),
            const SizedBox(width: 16),
            _buildProgressItem(
              theme,
              icon: Icons.pending,
              label: 'Pending',
              count: batch.status == BatchStatus.planned ? batch.maxOrders : 0,
              color: Colors.orange,
            ),
            const SizedBox(width: 16),
            _buildProgressItem(
              theme,
              icon: Icons.local_shipping,
              label: 'In Progress',
              count: batch.status == BatchStatus.active ? batch.maxOrders : 0,
              color: Colors.blue,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProgressItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required int count,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: color,
        ),
        const SizedBox(width: 4),
        Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, DeliveryBatch batch) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleViewDetails(batch),
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: batch.status == BatchStatus.active
                ? () => _handlePauseBatch(batch)
                : () => _handleStartBatch(batch),
            icon: Icon(
              batch.status == BatchStatus.active
                  ? Icons.pause
                  : Icons.play_arrow,
            ),
            label: Text(
              batch.status == BatchStatus.active ? 'Pause' : 'Start',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading batch information...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorCard(ThemeData theme, String error) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading batch',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCard(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(
              Icons.inbox_outlined,
              color: theme.colorScheme.outline,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No Active Batch',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create a new batch to start multi-order delivery',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return Colors.blue;
      case BatchStatus.active:
        return Colors.green;
      case BatchStatus.paused:
        return Colors.orange;
      case BatchStatus.completed:
        return Colors.purple;
      case BatchStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return Icons.schedule;
      case BatchStatus.active:
        return Icons.local_shipping;
      case BatchStatus.paused:
        return Icons.pause_circle;
      case BatchStatus.completed:
        return Icons.check_circle;
      case BatchStatus.cancelled:
        return Icons.cancel;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 25) return Colors.red;
    if (percentage < 50) return Colors.orange;
    if (percentage < 75) return Colors.blue;
    return Colors.green;
  }

  double _getProgressPercentage(DeliveryBatch batch) {
    switch (batch.status) {
      case BatchStatus.planned:
        return 0.0;
      case BatchStatus.active:
        return 50.0; // Assume 50% when active
      case BatchStatus.paused:
        return 25.0; // Assume 25% when paused
      case BatchStatus.completed:
        return 100.0;
      case BatchStatus.cancelled:
        return 0.0;
    }
  }

  void _showBatchMenu(BuildContext context, DeliveryBatch batch) {
    // TODO: Implement batch menu
  }

  void _handleViewDetails(DeliveryBatch batch) {
    // TODO: Navigate to batch details screen
  }

  void _handleStartBatch(DeliveryBatch batch) {
    // TODO: Start batch
  }

  void _handlePauseBatch(DeliveryBatch batch) {
    // TODO: Pause batch
  }
}
