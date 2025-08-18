import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/enhanced_vendor_order_history_providers.dart';
import '../../data/models/vendor_date_range_filter.dart';
import '../../data/models/vendor_grouped_order_history.dart';
import 'vendor_daily_order_group.dart';
import '../../../orders/data/models/order.dart';

/// Lazy loading list widget for vendor order history with performance optimizations
class VendorOrderHistoryLazyList extends ConsumerStatefulWidget {
  final VendorDateRangeFilter filter;
  final VendorOrderFilterStatus statusFilter;
  final Function(Order)? onOrderTap;
  final bool showPerformanceMonitor;

  const VendorOrderHistoryLazyList({
    super.key,
    required this.filter,
    this.statusFilter = VendorOrderFilterStatus.all,
    this.onOrderTap,
    this.showPerformanceMonitor = false,
  });

  @override
  ConsumerState<VendorOrderHistoryLazyList> createState() => _VendorOrderHistoryLazyListState();
}

class _VendorOrderHistoryLazyListState extends ConsumerState<VendorOrderHistoryLazyList> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final notifier = ref.read(paginatedVendorOrderHistoryProvider(widget.filter).notifier);
      await notifier.loadMore();
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMore = false;
        });
      }
    }
  }

  Future<void> _refresh() async {
    final notifier = ref.read(paginatedVendorOrderHistoryProvider(widget.filter).notifier);
    await notifier.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ordersAsync = ref.watch(paginatedVendorOrderHistoryProvider(widget.filter));
    final performanceMonitor = ref.watch(vendorOrderHistoryPerformanceProvider);

    return Column(
      children: [
        // Performance monitor (debug mode only)
        if (widget.showPerformanceMonitor && !const bool.fromEnvironment('dart.vm.product'))
          _buildPerformanceMonitor(theme, performanceMonitor),

        // Main content
        Expanded(
          child: ordersAsync.when(
            data: (orders) => _buildOrdersList(theme, orders),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => _buildErrorState(theme, error),
          ),
        ),
      ],
    );
  }

  Widget _buildPerformanceMonitor(ThemeData theme, VendorOrderHistoryPerformanceMonitor monitor) {
    final logs = monitor.getPerformanceLogs();
    
    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed,
                size: 16,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Performance Monitor',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: monitor.clearLogs,
                child: const Text('Clear'),
              ),
            ],
          ),
          if (logs.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...logs.take(3).map((log) => Text(
              log,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildOrdersList(ThemeData theme, List<Order> orders) {
    if (orders.isEmpty) {
      return _buildEmptyState(theme);
    }

    // Group orders by date
    final groupedHistory = VendorGroupedOrderHistory.fromOrders(orders);
    
    return RefreshIndicator(
      onRefresh: _refresh,
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Order groups
          ...groupedHistory.map((group) => _buildDailyGroup(group)),
          
          // Loading indicator
          if (_isLoadingMore)
            SliverToBoxAdapter(
              child: _buildLoadingIndicator(theme),
            ),
          
          // Load more button (if not loading and has more)
          if (!_isLoadingMore && _hasMore())
            SliverToBoxAdapter(
              child: _buildLoadMoreButton(theme),
            ),
          
          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 80),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGroup(VendorGroupedOrderHistory group) {
    return SliverToBoxAdapter(
      child: ExpandableVendorDailyOrderGroup(
        groupedHistory: group,
        statusFilter: widget.statusFilter,
        initiallyExpanded: group.isToday || group.isYesterday,
        onOrderTap: widget.onOrderTap,
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading more orders...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadMoreButton(ThemeData theme) {
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

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or check back later',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading orders',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _refresh,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  bool _hasMore() {
    final notifier = ref.read(paginatedVendorOrderHistoryProvider(widget.filter).notifier);
    return notifier.hasMore;
  }
}
