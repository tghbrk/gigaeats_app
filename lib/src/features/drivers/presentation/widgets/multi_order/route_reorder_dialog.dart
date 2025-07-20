import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/batch_operation_results.dart';
import '../../../data/models/route_optimization_models.dart';

/// Dialog for reordering route waypoints with drag-and-drop functionality
/// Allows drivers to manually adjust the optimized route sequence
class RouteReorderDialog extends ConsumerStatefulWidget {
  final List<BatchOrderWithDetails> orders;
  final OptimizedRoute? currentRoute;
  final Function(List<String> newOrderSequence)? onReorder;

  const RouteReorderDialog({
    super.key,
    required this.orders,
    this.currentRoute,
    this.onReorder,
  });

  @override
  ConsumerState<RouteReorderDialog> createState() => _RouteReorderDialogState();
}

class _RouteReorderDialogState extends ConsumerState<RouteReorderDialog> {
  late List<BatchOrderWithDetails> _reorderedOrders;
  bool _hasChanges = false;
  bool _isReoptimizing = false;

  @override
  void initState() {
    super.initState();
    _reorderedOrders = List.from(widget.orders);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.reorder,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Reorder Route Sequence',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            // Description
            Text(
              'Drag and drop to reorder the delivery sequence. The route will be recalculated automatically.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Current route info
            if (widget.currentRoute != null) ...[
              _buildCurrentRouteInfo(theme, widget.currentRoute!),
              const SizedBox(height: 16),
            ],
            
            // Reorderable list
            Expanded(
              child: _buildReorderableList(theme),
            ),
            
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: _hasChanges ? _resetOrder : null,
                  child: const Text('Reset'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: _hasChanges && !_isReoptimizing ? _applyChanges : null,
                  child: _isReoptimizing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Apply Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentRouteInfo(ThemeData theme, OptimizedRoute route) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Route',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildRouteMetric(theme, 'Distance', route.totalDistanceText),
              const SizedBox(width: 16),
              _buildRouteMetric(theme, 'Duration', route.totalDurationText),
              const SizedBox(width: 16),
              _buildRouteMetric(theme, 'Score', route.optimizationScoreText),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRouteMetric(ThemeData theme, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.outline,
          ),
        ),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReorderableList(ThemeData theme) {
    return ReorderableListView.builder(
      itemCount: _reorderedOrders.length,
      onReorder: _onReorder,
      itemBuilder: (context, index) {
        final orderWithDetails = _reorderedOrders[index];
        final order = orderWithDetails.order;
        
        return Card(
          key: ValueKey(order.id),
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: theme.colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              order.vendorName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Customer: ${order.customerName}'),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.restaurant,
                      size: 16,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Pickup',
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Delivery',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
            trailing: const Icon(Icons.drag_handle),
          ),
        );
      },
    );
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _reorderedOrders.removeAt(oldIndex);
      _reorderedOrders.insert(newIndex, item);
      _hasChanges = true;
    });
  }

  void _resetOrder() {
    setState(() {
      _reorderedOrders = List.from(widget.orders);
      _hasChanges = false;
    });
  }

  Future<void> _applyChanges() async {
    if (!_hasChanges || _isReoptimizing) return;

    setState(() {
      _isReoptimizing = true;
    });

    try {
      // Extract new order sequence
      final newOrderSequence = _reorderedOrders.map((o) => o.order.id).toList();
      
      // Notify parent widget
      if (widget.onReorder != null) {
        widget.onReorder!(newOrderSequence);
      }

      // Close dialog
      if (mounted) {
        Navigator.of(context).pop(newOrderSequence);
      }
    } catch (e) {
      debugPrint('❌ [ROUTE-REORDER] Error applying changes: $e');
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to reorder route: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isReoptimizing = false;
        });
      }
    }
  }
}
