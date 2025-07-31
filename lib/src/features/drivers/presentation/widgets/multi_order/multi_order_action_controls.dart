import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/delivery_batch.dart';
import '../../../data/models/batch_operation_results.dart';

/// Multi-order action controls for Phase 3 batch management
/// Provides comprehensive controls for managing orders within a batch
class MultiOrderActionControls extends ConsumerWidget {
  final DeliveryBatch? batch;
  final List<BatchOrderWithDetails> batchOrders;
  final VoidCallback? onAddOrder;
  final void Function(String orderId)? onRemoveOrder;
  final VoidCallback? onReorderBatch;

  const MultiOrderActionControls({
    super.key,
    this.batch,
    this.batchOrders = const [],
    this.onAddOrder,
    this.onRemoveOrder,
    this.onReorderBatch,
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
            _buildActionButtons(theme),
            const SizedBox(height: 16),
            _buildBatchStats(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.settings,
          color: theme.colorScheme.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          'Batch Controls',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        if (batch != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${batchOrders.length}/3 orders',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    final canAddOrder = batch != null && batchOrders.length < 3;
    final canReorder = batch != null && batchOrders.length > 1;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canAddOrder ? onAddOrder : null,
                icon: const Icon(Icons.add),
                label: const Text('Add Order'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canReorder ? onReorderBatch : null,
                icon: const Icon(Icons.reorder),
                label: const Text('Reorder'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) => OutlinedButton.icon(
                  onPressed: batch != null ? () => _showBatchSettings(context) : null,
                  icon: const Icon(Icons.tune),
                  label: const Text('Settings'),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) => OutlinedButton.icon(
                  onPressed: batch != null ? () => _showBatchAnalytics(context) : null,
                  icon: const Icon(Icons.analytics),
                  label: const Text('Analytics'),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatchStats(ThemeData theme) {
    if (batch == null || batchOrders.isEmpty) {
      return _buildEmptyStats(theme);
    }

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Batch Statistics',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Total Value',
                  'RM ${_calculateTotalValue().toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Avg Distance',
                  '${_calculateAverageDistance().toStringAsFixed(1)} km',
                  Icons.straighten,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Est. Time',
                  '${batch!.estimatedDurationMinutes ?? 0} min',
                  Icons.schedule,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  theme,
                  'Efficiency',
                  '${batch!.optimizationScore?.toStringAsFixed(0) ?? '0'}%',
                  Icons.trending_up,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStats(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            'Add orders to see batch statistics',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(ThemeData theme, String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: theme.textTheme.labelMedium?.copyWith(
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
        ),
      ],
    );
  }

  double _calculateTotalValue() {
    return batchOrders.fold(0.0, (sum, batchOrder) {
      return sum + batchOrder.order.totalAmount;
    });
  }

  double _calculateAverageDistance() {
    if (batchOrders.isEmpty) return 0.0;
    
    // This would need actual distance calculation between orders
    // For now, return a placeholder based on batch total distance
    return (batch?.totalDistanceKm ?? 0.0) / batchOrders.length;
  }

  void _showBatchSettings(BuildContext context) {
    debugPrint('🚛 [MULTI-ORDER-CONTROLS] Showing batch settings');
    
    showDialog(
      context: context,
      builder: (context) => _BatchSettingsDialog(
        batch: batch!,
        onSettingsChanged: (settings) {
          debugPrint('🚛 [MULTI-ORDER-CONTROLS] Batch settings changed: $settings');
          // TODO: Apply batch settings
        },
      ),
    );
  }

  void _showBatchAnalytics(BuildContext context) {
    debugPrint('🚛 [MULTI-ORDER-CONTROLS] Showing batch analytics');
    
    showDialog(
      context: context,
      builder: (context) => _BatchAnalyticsDialog(
        batch: batch!,
        batchOrders: batchOrders,
      ),
    );
  }
}

/// Batch settings dialog
class _BatchSettingsDialog extends StatefulWidget {
  final DeliveryBatch batch;
  final Function(Map<String, dynamic>) onSettingsChanged;

  const _BatchSettingsDialog({
    required this.batch,
    required this.onSettingsChanged,
  });

  @override
  State<_BatchSettingsDialog> createState() => _BatchSettingsDialogState();
}

class _BatchSettingsDialogState extends State<_BatchSettingsDialog> {
  late double _maxDeviationKm;
  late bool _enableRealTimeOptimization;
  late bool _allowOrderResequencing;

  @override
  void initState() {
    super.initState();
    _maxDeviationKm = widget.batch.maxDeviationKm;
    _enableRealTimeOptimization = widget.batch.metadata?['real_time_optimization_enabled'] ?? false;
    _allowOrderResequencing = widget.batch.metadata?['allow_order_resequencing'] ?? true;
  }

  @override
  Widget build(BuildContext context) {

    return AlertDialog(
      title: const Text('Batch Settings'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Max Route Deviation'),
            subtitle: Text('${_maxDeviationKm.toStringAsFixed(1)} km'),
            trailing: SizedBox(
              width: 100,
              child: Slider(
                value: _maxDeviationKm,
                min: 1.0,
                max: 10.0,
                divisions: 18,
                onChanged: (value) {
                  setState(() {
                    _maxDeviationKm = value;
                  });
                },
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Real-time Optimization'),
            subtitle: const Text('Automatically adjust route based on conditions'),
            value: _enableRealTimeOptimization,
            onChanged: (value) {
              setState(() {
                _enableRealTimeOptimization = value;
              });
            },
          ),
          SwitchListTile(
            title: const Text('Allow Order Resequencing'),
            subtitle: const Text('Permit automatic reordering of deliveries'),
            value: _allowOrderResequencing,
            onChanged: (value) {
              setState(() {
                _allowOrderResequencing = value;
              });
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            widget.onSettingsChanged({
              'max_deviation_km': _maxDeviationKm,
              'real_time_optimization_enabled': _enableRealTimeOptimization,
              'allow_order_resequencing': _allowOrderResequencing,
            });
            Navigator.of(context).pop();
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

/// Batch analytics dialog
class _BatchAnalyticsDialog extends StatelessWidget {
  final DeliveryBatch batch;
  final List<BatchOrderWithDetails> batchOrders;

  const _BatchAnalyticsDialog({
    required this.batch,
    required this.batchOrders,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Batch Analytics'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAnalyticsGrid(theme),
            const SizedBox(height: 16),
            _buildOrderBreakdown(theme),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildAnalyticsGrid(ThemeData theme) {
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
                child: _buildAnalyticsItem(
                  theme,
                  'Total Distance',
                  '${batch.totalDistanceKm?.toStringAsFixed(1) ?? '0.0'} km',
                  Icons.straighten,
                ),
              ),
              Expanded(
                child: _buildAnalyticsItem(
                  theme,
                  'Est. Duration',
                  '${batch.estimatedDurationMinutes ?? 0} min',
                  Icons.schedule,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalyticsItem(
                  theme,
                  'Optimization Score',
                  '${batch.optimizationScore?.toStringAsFixed(0) ?? '0'}%',
                  Icons.star,
                ),
              ),
              Expanded(
                child: _buildAnalyticsItem(
                  theme,
                  'Total Value',
                  'RM ${_calculateTotalValue().toStringAsFixed(2)}',
                  Icons.attach_money,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsItem(ThemeData theme, String label, String value, IconData icon) {
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildOrderBreakdown(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Breakdown',
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        ...batchOrders.asMap().entries.map((entry) {
          final index = entry.key;
          final batchOrder = entry.value;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            title: Text(
              batchOrder.order.vendorName,
              style: theme.textTheme.bodySmall,
            ),
            subtitle: Text(
              'RM ${batchOrder.order.totalAmount.toStringAsFixed(2)}',
              style: theme.textTheme.labelSmall,
            ),
            trailing: Text(
              batchOrder.batchOrder.pickupStatus.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          );
        }),
      ],
    );
  }

  double _calculateTotalValue() {
    return batchOrders.fold(0.0, (sum, batchOrder) {
      return sum + batchOrder.order.totalAmount;
    });
  }
}
