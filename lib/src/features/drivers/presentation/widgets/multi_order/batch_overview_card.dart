import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery_batch.dart';
import '../../providers/multi_order_batch_provider.dart';

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
            _buildActionButtons(context, ref, theme, batch!),
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

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ThemeData theme, DeliveryBatch batch) {
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
            onPressed: batch.status == BatchStatus.active
                ? () => _handlePauseBatch(ref, batch)
                : () => _handleStartBatch(ref, batch),
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
    debugPrint('🚛 [BATCH-OVERVIEW] Showing batch menu for: ${batch.id}');

    showModalBottomSheet(
      context: context,
      builder: (context) => _BatchMenuBottomSheet(batch: batch),
    );
  }

  void _handleViewDetails(BuildContext context, DeliveryBatch batch) {
    debugPrint('🚛 [BATCH-OVERVIEW] Viewing details for batch: ${batch.id}');

    // Show batch details in a dialog for now
    // TODO: Create dedicated batch details screen route
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Batch Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batch ID: ${batch.id}'),
            Text('Status: ${batch.status.name}'),
            Text('Max Orders: ${batch.maxOrders}'),
            Text('Created: ${batch.createdAt.toString()}'),
            if (batch.actualStartTime != null)
              Text('Started: ${batch.actualStartTime.toString()}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _handleStartBatch(WidgetRef ref, DeliveryBatch batch) {
    debugPrint('🚛 [BATCH-OVERVIEW] Starting batch: ${batch.id}');

    // Use the provider to start the batch
    ref.read(multiOrderBatchProvider.notifier).startBatch();
  }

  void _handlePauseBatch(WidgetRef ref, DeliveryBatch batch) {
    debugPrint('🚛 [BATCH-OVERVIEW] Pausing batch: ${batch.id}');

    // Use the provider to pause the batch
    ref.read(multiOrderBatchProvider.notifier).pauseBatch();
  }
}

/// Batch menu bottom sheet for additional batch actions
class _BatchMenuBottomSheet extends ConsumerWidget {
  final DeliveryBatch batch;

  const _BatchMenuBottomSheet({required this.batch});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Batch Actions',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          _buildMenuOption(
            context,
            icon: Icons.info_outline,
            title: 'View Details',
            subtitle: 'See batch information',
            onTap: () {
              Navigator.pop(context);
              // TODO: Navigate to batch details
            },
          ),
          _buildMenuOption(
            context,
            icon: Icons.route,
            title: 'Optimize Route',
            subtitle: 'Recalculate optimal route',
            onTap: () {
              Navigator.pop(context);
              _handleOptimizeRoute(ref);
            },
          ),
          if (batch.status == BatchStatus.active || batch.status == BatchStatus.paused)
            _buildMenuOption(
              context,
              icon: Icons.cancel_outlined,
              title: 'Cancel Batch',
              subtitle: 'Cancel this batch',
              onTap: () {
                Navigator.pop(context);
                _showCancelConfirmation(context, ref);
              },
              isDestructive: true,
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final color = isDestructive ? theme.colorScheme.error : theme.colorScheme.onSurface;

    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.outline,
        ),
      ),
      onTap: onTap,
    );
  }

  void _handleOptimizeRoute(WidgetRef ref) {
    debugPrint('🚛 [BATCH-MENU] Optimizing route for batch: ${batch.id}');
    // TODO: Implement route optimization - method not available in provider yet
    ScaffoldMessenger.of(ref.context).showSnackBar(
      const SnackBar(content: Text('Route optimization coming soon')),
    );
  }

  void _showCancelConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Batch'),
        content: const Text(
          'Are you sure you want to cancel this batch? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Batch'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              _handleCancelBatch(ref);
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Cancel Batch'),
          ),
        ],
      ),
    );
  }

  void _handleCancelBatch(WidgetRef ref) {
    debugPrint('🚛 [BATCH-MENU] Cancelling batch: ${batch.id}');
    ref.read(multiOrderBatchProvider.notifier).cancelBatch('User requested cancellation');
  }
}
