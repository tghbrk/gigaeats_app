import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/optimized_order_history_providers.dart';
import '../providers/enhanced_driver_order_history_providers.dart';
import '../../data/services/lazy_loading_service.dart';
import '../../data/models/grouped_order_history.dart';
import '../../../orders/data/models/order.dart';
import 'enhanced_order_history_card.dart';

/// Optimized lazy loading list widget for driver order history
class OptimizedLazyLoadingList extends ConsumerStatefulWidget {
  final DateRangeFilter filter;
  final Widget Function(BuildContext, GroupedOrderHistory, bool)? groupHeaderBuilder;
  final Widget Function(BuildContext, Order)? itemBuilder;
  final Widget? emptyStateWidget;
  final Widget? loadingWidget;
  final Widget Function(BuildContext, String)? errorWidget;
  final bool enablePrefetch;
  final int prefetchThreshold;
  final ScrollController? scrollController;

  const OptimizedLazyLoadingList({
    super.key,
    required this.filter,
    this.groupHeaderBuilder,
    this.itemBuilder,
    this.emptyStateWidget,
    this.loadingWidget,
    this.errorWidget,
    this.enablePrefetch = true,
    this.prefetchThreshold = 5,
    this.scrollController,
  });

  @override
  ConsumerState<OptimizedLazyLoadingList> createState() => _OptimizedLazyLoadingListState();
}

class _OptimizedLazyLoadingListState extends ConsumerState<OptimizedLazyLoadingList> {
  late ScrollController _scrollController;
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController = widget.scrollController ?? ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    if (widget.scrollController == null) {
      _scrollController.dispose();
    } else {
      _scrollController.removeListener(_onScroll);
    }
    super.dispose();
  }

  void _onScroll() {
    if (!widget.enablePrefetch) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final threshold = maxScroll * 0.8; // Load more when 80% scrolled

    if (currentScroll >= threshold && !_isLoadingMore) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;
    
    setState(() {
      _isLoadingMore = true;
    });

    try {
      final notifier = ref.read(optimizedDriverOrderHistoryProvider(widget.filter).notifier);
      await notifier.loadMore();
    } catch (e) {
      debugPrint('🚗 OptimizedLazyLoadingList: Error loading more: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final orderHistoryAsync = ref.watch(optimizedDriverOrderHistoryProvider(widget.filter));
    final groupedHistoryAsync = ref.watch(optimizedGroupedOrderHistoryProvider(widget.filter));

    return RefreshIndicator(
      onRefresh: () async {
        final notifier = ref.read(optimizedDriverOrderHistoryProvider(widget.filter).notifier);
        await notifier.refresh();
      },
      child: orderHistoryAsync.when(
        data: (result) {
          if (result.items.isEmpty) {
            return widget.emptyStateWidget ?? _buildDefaultEmptyState();
          }

          return groupedHistoryAsync.when(
            data: (groupedHistory) => _buildGroupedList(groupedHistory, result),
            loading: () => widget.loadingWidget ?? _buildDefaultLoadingState(),
            error: (error, _) => widget.errorWidget?.call(context, error.toString()) ?? 
                                  _buildDefaultErrorState(error.toString()),
          );
        },
        loading: () => widget.loadingWidget ?? _buildDefaultLoadingState(),
        error: (error, _) => widget.errorWidget?.call(context, error.toString()) ?? 
                            _buildDefaultErrorState(error.toString()),
      ),
    );
  }

  Widget _buildGroupedList(List<GroupedOrderHistory> groupedHistory, LazyLoadingResult result) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Performance indicator (debug only)
        if (!const bool.fromEnvironment('dart.vm.product'))
          SliverToBoxAdapter(
            child: _buildPerformanceIndicator(result),
          ),

        // Grouped orders
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final group = groupedHistory[index];
              return _buildGroupSection(group, index == 0);
            },
            childCount: groupedHistory.length,
          ),
        ),

        // Load more indicator
        if (result.hasMore || _isLoadingMore)
          SliverToBoxAdapter(
            child: _buildLoadMoreIndicator(result),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildGroupSection(GroupedOrderHistory group, bool isFirst) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: isFirst ? 8 : 16,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group header
          widget.groupHeaderBuilder?.call(context, group, isFirst) ?? 
          _buildDefaultGroupHeader(group),
          
          const SizedBox(height: 12),
          
          // Orders in this group
          ...group.orders.asMap().entries.map((entry) {
            final index = entry.key;
            final order = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: index < group.orders.length - 1 ? 8 : 0),
              child: widget.itemBuilder?.call(context, order) ?? 
                     _buildDefaultOrderItem(order),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildDefaultGroupHeader(GroupedOrderHistory group) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: group.isToday 
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: group.isToday 
            ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3))
            : null,
      ),
      child: Row(
        children: [
          // Date icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: group.isToday 
                  ? theme.colorScheme.primary
                  : theme.colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              group.isToday 
                  ? Icons.today
                  : group.isYesterday 
                      ? Icons.history_toggle_off
                      : Icons.calendar_today,
              size: 16,
              color: group.isToday 
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 12),
          
          // Date and count
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  group.displayDate,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: group.isToday 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${group.totalOrders} order${group.totalOrders == 1 ? '' : 's'}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'RM ${group.totalEarnings.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
              if (group.cancelledOrders > 0)
                Text(
                  '${group.cancelledOrders} cancelled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultOrderItem(Order order) {
    return EnhancedOrderHistoryCard(
      order: order,
      onTap: () => _showOrderDetails(order),
      showDetailedInfo: true,
      showEarnings: true,
    );
  }

  Widget _buildPerformanceIndicator(LazyLoadingResult result) {
    final theme = Theme.of(context);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            Icons.speed,
            size: 16,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Text(
            'Loaded: ${result.totalLoaded} | Page: ${result.currentPage} | Cache: ${result.fromCache ? 'HIT' : 'MISS'}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreIndicator(LazyLoadingResult result) {
    final theme = Theme.of(context);
    
    if (_isLoadingMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    if (result.hasMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: _loadMore,
            icon: const Icon(Icons.expand_more),
            label: const Text('Load More Orders'),
          ),
        ),
      );
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          'All orders loaded',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultEmptyState() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.history_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Order History',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your completed orders will appear here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDefaultLoadingState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }

  Widget _buildDefaultErrorState(String error) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                final notifier = ref.read(optimizedDriverOrderHistoryProvider(widget.filter).notifier);
                notifier.refresh();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _showOrderDetails(Order order) {
    debugPrint('🚗 Showing order details: ${order.id}');
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order ${order.orderNumber}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vendor: ${order.vendorName}'),
            Text('Customer: ${order.customerName}'),
            Text('Status: ${order.status.displayName}'),
            Text('Total: RM ${order.totalAmount.toStringAsFixed(2)}'),
            Text('Items: ${order.items.length}'),
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
}
