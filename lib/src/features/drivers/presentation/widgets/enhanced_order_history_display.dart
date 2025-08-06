import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/data/models/order.dart';
import '../../data/models/grouped_order_history.dart';
import '../providers/enhanced_driver_order_history_providers.dart';

import 'enhanced_order_grouping_components.dart';
import 'enhanced_lazy_loading_components.dart';
import 'lazy_loading_performance_monitor.dart';

/// Enhanced order history display with advanced grouping and lazy loading
/// 
/// This widget provides a comprehensive order history display with collapsible
/// date groups, intelligent lazy loading, performance monitoring, and enhanced
/// empty states with contextual messaging.
class EnhancedOrderHistoryDisplay extends ConsumerStatefulWidget {
  final DateRangeFilter filter;
  final Widget Function(BuildContext, Order)? itemBuilder;
  final bool showStatisticsSummary;
  final bool enableCollapsibleGroups;
  final bool showPerformanceMonitor;
  final EdgeInsetsGeometry? padding;

  const EnhancedOrderHistoryDisplay({
    super.key,
    required this.filter,
    this.itemBuilder,
    this.showStatisticsSummary = true,
    this.enableCollapsibleGroups = true,
    this.showPerformanceMonitor = false,
    this.padding,
  });

  @override
  ConsumerState<EnhancedOrderHistoryDisplay> createState() => _EnhancedOrderHistoryDisplayState();
}

class _EnhancedOrderHistoryDisplayState extends ConsumerState<EnhancedOrderHistoryDisplay> {
  // final Map<String, bool> _groupExpansionStates = {}; // TODO: Implement group expansion

  @override
  Widget build(BuildContext context) {
    // final theme = Theme.of(context); // TODO: Use for theming
    final quickFilter = ref.watch(selectedQuickFilterProvider);
    
    return Column(
      children: [
        // Performance monitor (debug mode only)
        if (widget.showPerformanceMonitor && !const bool.fromEnvironment('dart.vm.product'))
          const LazyLoadingPerformanceMonitor(
            showDetailedMetrics: true,
            showRecommendations: true,
          ),

        // Main content
        Expanded(
          child: EnhancedInfiniteScrollList(
            filter: widget.filter,
            itemBuilder: (context, order, index) => _buildOrderItem(context, order),
            emptyBuilder: (context) => EnhancedOrderHistoryEmptyState(
              filter: widget.filter,
              quickFilter: quickFilter,
              onClearFilters: _clearFilters,
              onRefresh: _refreshData,
            ),
            errorBuilder: (context, error) => _buildErrorState(context, error),
            padding: widget.padding,
            enablePrefetch: true,
            showPerformanceIndicator: widget.showPerformanceMonitor,
          ),
        ),
      ],
    );
  }

  Widget _buildOrderItem(BuildContext context, Order order) {
    if (widget.itemBuilder != null) {
      return widget.itemBuilder!(context, order);
    }
    
    return _buildDefaultOrderItem(context, order);
  }

  Widget _buildDefaultOrderItem(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(order.status.value).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColor(order.status.value),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Order details
          Text(
            'RM ${order.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          
          const SizedBox(height: 4),
          
          Text(
            _formatOrderTime(order),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load order history',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatOrderTime(Order order) {
    final dateTime = order.actualDeliveryTime ?? order.createdAt;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  void _clearFilters() {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
    ref.read(dateFilterProvider.notifier).reset();
  }

  void _refreshData() {
    ref.invalidate(enhancedDriverOrderHistoryProvider(widget.filter));
  }
}

/// Enhanced grouped order history display with collapsible sections
class EnhancedGroupedOrderHistoryDisplay extends ConsumerStatefulWidget {
  final DateRangeFilter filter;
  final Widget Function(BuildContext, Order)? itemBuilder;
  final bool showStatisticsSummary;
  final bool enableCollapsibleGroups;
  final bool initiallyExpandedGroups;
  final EdgeInsetsGeometry? padding;

  const EnhancedGroupedOrderHistoryDisplay({
    super.key,
    required this.filter,
    this.itemBuilder,
    this.showStatisticsSummary = true,
    this.enableCollapsibleGroups = true,
    this.initiallyExpandedGroups = true,
    this.padding,
  });

  @override
  ConsumerState<EnhancedGroupedOrderHistoryDisplay> createState() => _EnhancedGroupedOrderHistoryDisplayState();
}

class _EnhancedGroupedOrderHistoryDisplayState extends ConsumerState<EnhancedGroupedOrderHistoryDisplay> {
  final Map<String, bool> _groupExpansionStates = {};

  @override
  Widget build(BuildContext context) {
    final groupedHistoryAsync = ref.watch(groupedOrderHistoryProvider(widget.filter));
    final quickFilter = ref.watch(selectedQuickFilterProvider);

    return groupedHistoryAsync.when(
      data: (groups) {
        if (groups.isEmpty) {
          return EnhancedOrderHistoryEmptyState(
            filter: widget.filter,
            quickFilter: quickFilter,
            onClearFilters: _clearFilters,
            onRefresh: _refreshData,
          );
        }

        return CustomScrollView(
          slivers: [
            // Statistics summary
            if (widget.showStatisticsSummary)
              SliverToBoxAdapter(
                child: EnhancedOrderStatisticsSummary(
                  groups: groups,
                  showDetailedStats: true,
                  showTrends: false,
                  padding: widget.padding,
                ),
              ),

            // Grouped orders
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final group = groups[index];
                  return _buildGroupSection(group);
                },
                childCount: groups.length,
              ),
            ),

            // Bottom padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 80),
            ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => _buildErrorState(context, error.toString()),
    );
  }

  Widget _buildGroupSection(GroupedOrderHistory group) {
    if (!widget.enableCollapsibleGroups) {
      return _buildSimpleGroup(group);
    }

    final isExpanded = _groupExpansionStates[group.dateKey] ?? widget.initiallyExpandedGroups;

    return EnhancedCollapsibleOrderGroup(
      group: group,
      itemBuilder: (context, order) => widget.itemBuilder?.call(context, order) ?? 
                                      _buildDefaultOrderItem(context, order),
      initiallyExpanded: isExpanded,
      showEarningsSummary: true,
      showOrderCount: true,
      showDateDetails: true,
      onExpansionChanged: () {
        setState(() {
          _groupExpansionStates[group.dateKey] = !isExpanded;
        });
      },
    );
  }

  Widget _buildSimpleGroup(GroupedOrderHistory group) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          _buildSimpleGroupHeader(group),
          const SizedBox(height: 12),
          
          // Orders
          ...group.orders.map((order) => 
            widget.itemBuilder?.call(context, order) ?? 
            _buildDefaultOrderItem(context, order)
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleGroupHeader(GroupedOrderHistory group) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            group.displayDate,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Text(
            '${group.totalOrders} orders',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultOrderItem(BuildContext context, Order order) {
    return _buildOrderItemCard(context, order);
  }

  Widget _buildOrderItemCard(BuildContext context, Order order) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Order header
          Row(
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColorForOrder(order.status.value).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  order.status.displayName,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: _getStatusColorForOrder(order.status.value),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Order details
          Text(
            'RM ${order.totalAmount.toStringAsFixed(2)}',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _formatOrderTimeForGroup(order),
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColorForOrder(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      case 'preparing':
        return Colors.orange;
      case 'ready':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatOrderTimeForGroup(Order order) {
    final dateTime = order.actualDeliveryTime ?? order.createdAt;
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes} minutes ago';
      }
      return '${difference.inHours} hours ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load order history',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _clearFilters() {
    ref.read(selectedQuickFilterProvider.notifier).setFilter(QuickDateFilter.all);
    ref.read(dateFilterProvider.notifier).reset();
  }

  void _refreshData() {
    ref.invalidate(groupedOrderHistoryProvider(widget.filter));
  }
}
