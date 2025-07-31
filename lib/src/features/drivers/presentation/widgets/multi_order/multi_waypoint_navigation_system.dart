import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/enhanced_navigation_provider.dart';
import '../../providers/multi_order_batch_provider.dart';

/// Multi-waypoint navigation system widget with Phase 2 enhancements
/// Provides comprehensive multi-order delivery navigation with waypoint management,
/// route optimization, and batch delivery coordination
class MultiWaypointNavigationSystem extends ConsumerStatefulWidget {
  final bool showWaypointList;
  final bool showRouteOptimization;
  final bool showBatchProgress;
  final Function(String orderId)? onWaypointSelected;
  final Function(List<String> orderIds)? onRouteReordered;
  final VoidCallback? onOptimizeRoute;

  const MultiWaypointNavigationSystem({
    super.key,
    this.showWaypointList = true,
    this.showRouteOptimization = true,
    this.showBatchProgress = true,
    this.onWaypointSelected,
    this.onRouteReordered,
    this.onOptimizeRoute,
  });

  @override
  ConsumerState<MultiWaypointNavigationSystem> createState() => _MultiWaypointNavigationSystemState();
}

class _MultiWaypointNavigationSystemState extends ConsumerState<MultiWaypointNavigationSystem>
    with TickerProviderStateMixin {
  late AnimationController _expandController;
  late Animation<double> _expandAnimation;
  
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    
    debugPrint('🗺️ [MULTI-WAYPOINT] Initializing multi-waypoint navigation system (Phase 2)');
    
    _expandController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _expandAnimation = CurvedAnimation(
      parent: _expandController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _expandController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final navState = ref.watch(enhancedNavigationProvider);
    final batchState = ref.watch(multiOrderBatchProvider);

    if (!navState.isNavigating || !batchState.hasActiveBatch) {
      return const SizedBox.shrink();
    }

    debugPrint('🗺️ [MULTI-WAYPOINT] Building multi-waypoint navigation system - Batch orders: ${batchState.batchOrders.length}');

    return Positioned(
      bottom: MediaQuery.of(context).padding.bottom + 20,
      left: 16,
      right: 16,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with batch progress
              _buildHeader(theme, navState, batchState),
              
              // Expandable waypoint list
              AnimatedBuilder(
                animation: _expandAnimation,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.topCenter,
                      heightFactor: _expandAnimation.value,
                      child: child,
                    ),
                  );
                },
                child: _buildWaypointList(theme, batchState),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build header with batch progress and controls
  Widget _buildHeader(
    ThemeData theme,
    EnhancedNavigationState navState,
    MultiOrderBatchState batchState,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.route,
                  color: theme.colorScheme.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Order Delivery',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    Text(
                      '${batchState.completedDeliveries + 1} of ${batchState.totalOrders} orders',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Expand/collapse button
              IconButton(
                icon: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: const Icon(Icons.expand_more),
                ),
                onPressed: _toggleExpanded,
                tooltip: _isExpanded ? 'Collapse' : 'Expand',
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress bar
          _buildProgressBar(theme, batchState),
          
          const SizedBox(height: 12),
          
          // Current destination info
          _buildCurrentDestinationInfo(theme, navState, batchState),
        ],
      ),
    );
  }

  /// Build progress bar
  Widget _buildProgressBar(ThemeData theme, MultiOrderBatchState batchState) {
    final progress = batchState.totalOrders > 0
        ? (batchState.completedDeliveries + 1) / batchState.totalOrders
        : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Delivery Progress',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '${(progress * 100).round()}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: progress,
          backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.2),
          valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
        ),
      ],
    );
  }

  /// Build current destination info
  Widget _buildCurrentDestinationInfo(
    ThemeData theme,
    EnhancedNavigationState navState,
    MultiOrderBatchState batchState,
  ) {
    // Get current order from batch orders (first non-completed order)
    final currentOrder = batchState.batchOrders.isNotEmpty
        ? batchState.batchOrders.firstWhere(
            (order) => !order.isDeliveryCompleted,
            orElse: () => batchState.batchOrders.first,
          ).order
        : null;
    if (currentOrder == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              color: theme.colorScheme.onPrimary,
              size: 16,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Current Destination',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  currentOrder.deliveryAddress.fullAddress,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (navState.estimatedArrival != null) ...[
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'ETA',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
                Text(
                  _formatETA(navState.estimatedArrival!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Build waypoint list
  Widget _buildWaypointList(ThemeData theme, MultiOrderBatchState batchState) {
    if (!widget.showWaypointList) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Delivery Sequence',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const Spacer(),
              if (widget.showRouteOptimization)
                TextButton.icon(
                  onPressed: widget.onOptimizeRoute,
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  label: const Text('Optimize'),
                  style: TextButton.styleFrom(
                    foregroundColor: theme.colorScheme.secondary,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Waypoint items
          ...batchState.batchOrders.asMap().entries.map((entry) {
            final index = entry.key;
            final order = entry.value;
            final isCompleted = index < batchState.completedDeliveries;
            final isCurrent = index == batchState.completedDeliveries;
            
            return _buildWaypointItem(
              theme,
              order,
              index + 1,
              isCompleted,
              isCurrent,
            );
          }),
        ],
      ),
    );
  }

  /// Build individual waypoint item
  Widget _buildWaypointItem(
    ThemeData theme,
    dynamic order, // Using dynamic since we don't have the exact Order type imported
    int sequenceNumber,
    bool isCompleted,
    bool isCurrent,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => widget.onWaypointSelected?.call(order.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrent
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
                : isCompleted
                    ? theme.colorScheme.surfaceContainerHighest
                    : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent
                  ? theme.colorScheme.primary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              // Sequence indicator
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green
                      : isCurrent
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(
                          Icons.check,
                          color: Colors.white,
                          size: 16,
                        )
                      : Text(
                          '$sequenceNumber',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isCurrent
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.outline,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),

              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrent
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.deliveryAddress?.fullAddress ?? 'Unknown Address',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.outline,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),

              // Status indicator
              if (isCompleted)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Delivered',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Active',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  /// Toggle expanded state
  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });

    if (_isExpanded) {
      _expandController.forward();
    } else {
      _expandController.reverse();
    }

    debugPrint('🗺️ [MULTI-WAYPOINT] Toggled expanded state: $_isExpanded');
  }

  /// Format ETA time
  String _formatETA(DateTime eta) {
    final now = DateTime.now();
    final difference = eta.difference(now);

    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }
}
