import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery_batch.dart';
import '../../../data/models/route_optimization_models.dart';

/// Batch progress indicator showing overall delivery progress
/// Displays visual progress with waypoint tracking and ETA information
class BatchProgressIndicator extends ConsumerWidget {
  final DeliveryBatch batch;
  final RouteProgress? routeProgress;

  const BatchProgressIndicator({
    super.key,
    required this.batch,
    this.routeProgress,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: 16),
            _buildProgressBar(theme),
            const SizedBox(height: 16),
            _buildProgressDetails(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    final progressPercentage = _getProgressPercentage();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Batch Progress',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Batch ${batch.batchNumber} - ${batch.status.displayName}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: _getProgressColor(progressPercentage).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _getProgressColor(progressPercentage).withValues(alpha: 0.3),
            ),
          ),
          child: Text(
            '${progressPercentage.toStringAsFixed(0)}%',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: _getProgressColor(progressPercentage),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildProgressBar(ThemeData theme) {
    final progressPercentage = _getProgressPercentage();

    return Column(
      children: [
        // Main progress bar
        LinearProgressIndicator(
          value: progressPercentage / 100,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(
            _getProgressColor(progressPercentage),
          ),
          minHeight: 8,
        ),

        const SizedBox(height: 8),

        // Waypoint indicators
        if (routeProgress != null)
          _buildWaypointIndicators(theme),
      ],
    );
  }

  Widget _buildWaypointIndicators(ThemeData theme) {
    final totalWaypoints = batch.maxOrders * 2; // Pickup + delivery for each order
    final completedWaypoints = routeProgress?.completedWaypoints.length ?? 0;

    return Row(
      children: List.generate(
        totalWaypoints.clamp(0, 10), // Limit to 10 indicators for UI
        (index) {
          final isCompleted = index < completedWaypoints;
          final isCurrent = index == completedWaypoints;

          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 1),
              height: 4,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.green
                    : isCurrent
                        ? Colors.blue
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProgressDetails(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildProgressItem(
            theme,
            icon: Icons.check_circle,
            label: 'Completed',
            value: batch.status == BatchStatus.completed ? '${batch.maxOrders}' : '0',
            color: Colors.green,
          ),
        ),
        Expanded(
          child: _buildProgressItem(
            theme,
            icon: Icons.local_shipping,
            label: 'In Progress',
            value: batch.status == BatchStatus.active ? '${batch.maxOrders}' : '0',
            color: Colors.blue,
          ),
        ),
        Expanded(
          child: _buildProgressItem(
            theme,
            icon: Icons.pending,
            label: 'Pending',
            value: batch.status == BatchStatus.planned ? '${batch.maxOrders}' : '0',
            color: Colors.orange,
          ),
        ),
        Expanded(
          child: _buildProgressItem(
            theme,
            icon: Icons.access_time,
            label: 'ETA',
            value: _getEstimatedTimeRemaining(),
            color: Colors.purple,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressItem(
    ThemeData theme, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
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
            color: theme.colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Color _getProgressColor(double percentage) {
    if (percentage < 25) return Colors.red;
    if (percentage < 50) return Colors.orange;
    if (percentage < 75) return Colors.blue;
    return Colors.green;
  }

  double _getProgressPercentage() {
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

  String _getEstimatedTimeRemaining() {
    if (batch.estimatedDurationMinutes != null) {
      final totalMinutes = batch.estimatedDurationMinutes!;
      final progressPercentage = _getProgressPercentage();
      final remainingMinutes = (totalMinutes * (100 - progressPercentage) / 100).round();

      if (remainingMinutes < 60) {
        return '${remainingMinutes}m';
      } else {
        final hours = remainingMinutes ~/ 60;
        final minutes = remainingMinutes % 60;
        return '${hours}h ${minutes}m';
      }
    }

    return 'N/A';
  }
}
