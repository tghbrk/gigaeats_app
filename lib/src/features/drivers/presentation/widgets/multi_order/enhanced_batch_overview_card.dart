import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery_batch.dart';
import '../../../data/models/batch_operation_results.dart';

/// Enhanced batch overview card for Phase 3 multi-order management
/// Provides comprehensive batch visualization with real-time metrics and advanced controls
class EnhancedBatchOverviewCard extends ConsumerWidget {
  final DeliveryBatch? batch;
  final BatchSummary? batchSummary;
  final bool isLoading;
  final String? error;

  const EnhancedBatchOverviewCard({
    super.key,
    this.batch,
    this.batchSummary,
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
            _buildHeader(theme, batch!),
            const SizedBox(height: 16),
            _buildStatusIndicator(theme, batch!),
            const SizedBox(height: 16),
            _buildMetricsGrid(theme, batch!, batchSummary),
            const SizedBox(height: 16),
            _buildProgressSection(theme, batch!, batchSummary),
            const SizedBox(height: 16),
            _buildActionButtons(context, theme, batch!),
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
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              'Error Loading Batch',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
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
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
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
              size: 48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No Active Batch',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Create a new batch to start managing multiple orders',
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

  Widget _buildHeader(ThemeData theme, DeliveryBatch batch) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            batch.batchNumber,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        Icon(
          Icons.access_time,
          size: 16,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
        const SizedBox(width: 4),
        Text(
          _formatDateTime(batch.createdAt),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(ThemeData theme, DeliveryBatch batch) {
    final statusColor = _getStatusColor(theme, batch.status);
    final statusIcon = _getStatusIcon(batch.status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          const SizedBox(width: 8),
          Text(
            batch.status.displayName,
            style: theme.textTheme.labelMedium?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsGrid(ThemeData theme, DeliveryBatch batch, BatchSummary? summary) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricItem(
            theme,
            'Orders',
            '${summary?.totalOrders ?? 0}',
            Icons.shopping_bag,
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            theme,
            'Distance',
            '${batch.totalDistanceKm?.toStringAsFixed(1) ?? '0.0'} km',
            Icons.straighten,
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            theme,
            'Duration',
            '${batch.estimatedDurationMinutes ?? 0} min',
            Icons.schedule,
          ),
        ),
        Expanded(
          child: _buildMetricItem(
            theme,
            'Score',
            '${batch.optimizationScore?.toStringAsFixed(0) ?? '0'}%',
            Icons.star,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricItem(ThemeData theme, String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressSection(ThemeData theme, DeliveryBatch batch, BatchSummary? summary) {
    if (summary == null) return const SizedBox.shrink();

    final progress = summary.overallProgress / 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '${summary.overallProgress.toStringAsFixed(0)}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.surfaceContainerHighest,
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pickups: ${summary.completedPickups}/${summary.totalOrders}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
            Text(
              'Deliveries: ${summary.completedDeliveries}/${summary.totalOrders}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, ThemeData theme, DeliveryBatch batch) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _handleViewDetails(context, batch),
            icon: const Icon(Icons.visibility),
            label: const Text('View Details'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FilledButton.icon(
            onPressed: () => _handleBatchAction(context, batch),
            icon: Icon(_getBatchActionIcon(batch.status)),
            label: Text(_getBatchActionLabel(batch.status)),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(ThemeData theme, BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return theme.colorScheme.primary;
      case BatchStatus.active:
        return Colors.green;
      case BatchStatus.paused:
        return Colors.orange;
      case BatchStatus.completed:
        return Colors.blue;
      case BatchStatus.cancelled:
        return theme.colorScheme.error;
    }
  }

  IconData _getStatusIcon(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return Icons.schedule;
      case BatchStatus.active:
        return Icons.play_arrow;
      case BatchStatus.paused:
        return Icons.pause;
      case BatchStatus.completed:
        return Icons.check_circle;
      case BatchStatus.cancelled:
        return Icons.cancel;
    }
  }

  IconData _getBatchActionIcon(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return Icons.play_arrow;
      case BatchStatus.active:
        return Icons.pause;
      case BatchStatus.paused:
        return Icons.play_arrow;
      default:
        return Icons.info;
    }
  }

  String _getBatchActionLabel(BatchStatus status) {
    switch (status) {
      case BatchStatus.planned:
        return 'Start';
      case BatchStatus.active:
        return 'Pause';
      case BatchStatus.paused:
        return 'Resume';
      default:
        return 'View';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  void _handleViewDetails(BuildContext context, DeliveryBatch batch) {
    debugPrint('🚛 [ENHANCED-BATCH-OVERVIEW] Viewing batch details: ${batch.id}');
    // TODO: Navigate to batch details screen
  }

  void _handleBatchAction(BuildContext context, DeliveryBatch batch) {
    debugPrint('🚛 [ENHANCED-BATCH-OVERVIEW] Batch action for status: ${batch.status}');
    // TODO: Implement batch actions
  }
}
