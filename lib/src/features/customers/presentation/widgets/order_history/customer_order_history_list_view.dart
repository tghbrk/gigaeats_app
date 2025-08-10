import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/customer_order_history_models.dart';
import 'customer_daily_order_group.dart';

/// List view for customer order history with daily grouping and lazy loading
class CustomerOrderHistoryListView extends ConsumerStatefulWidget {
  final List<CustomerGroupedOrderHistory> groupedHistory;
  final CustomerOrderFilterStatus statusFilter;
  final bool isLoading;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;
  final Future<void> Function()? onRefresh;
  final ScrollController? scrollController;

  const CustomerOrderHistoryListView({
    super.key,
    required this.groupedHistory,
    required this.statusFilter,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
    this.onRefresh,
    this.scrollController,
  });

  @override
  ConsumerState<CustomerOrderHistoryListView> createState() => _CustomerOrderHistoryListViewState();
}

class _CustomerOrderHistoryListViewState extends ConsumerState<CustomerOrderHistoryListView> {
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
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !widget.hasMore || widget.isLoading) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      await widget.onLoadMore?.call();
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
    final theme = Theme.of(context);

    debugPrint('🛒 CustomerOrderHistoryListView: Building with ${widget.groupedHistory.length} groups for status: ${widget.statusFilter.displayName}');
    debugPrint('🛒 CustomerOrderHistoryListView: isLoading: ${widget.isLoading}');

    // Debug: Log details about each group
    for (int i = 0; i < widget.groupedHistory.length; i++) {
      final group = widget.groupedHistory[i];
      debugPrint('🛒 CustomerOrderHistoryListView: Group $i - ${group.displayDate}: ${group.totalOrders} total (${group.activeCount} active, ${group.completedCount} completed, ${group.cancelledCount} cancelled)');
    }

    if (widget.groupedHistory.isEmpty && !widget.isLoading) {
      debugPrint('🛒 CustomerOrderHistoryListView: No groups found and not loading, showing empty state');
      return _buildEmptyState(theme);
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh ?? () async {},
      child: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // Order groups
          ...widget.groupedHistory.map((group) => _buildDailyGroup(group)),
          
          // Loading indicator
          if (widget.isLoading || _isLoadingMore)
            SliverToBoxAdapter(
              child: _buildLoadingIndicator(theme),
            ),
          
          // Load more button
          if (widget.hasMore && !widget.isLoading && !_isLoadingMore)
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

  Widget _buildDailyGroup(CustomerGroupedOrderHistory group) {
    debugPrint('🛒 CustomerOrderHistoryListView: Building daily group for ${group.displayDate} with ${group.totalOrders} orders');
    return SliverToBoxAdapter(
      child: CustomerDailyOrderGroup(
        groupedHistory: group,
        statusFilter: widget.statusFilter,
      ),
    );
  }

  Widget _buildLoadingIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            'Loading more orders...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
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
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    String message;
    IconData icon;
    
    switch (widget.statusFilter) {
      case CustomerOrderFilterStatus.active:
        message = 'No active orders found for the selected period';
        icon = Icons.schedule_outlined;
        break;
      case CustomerOrderFilterStatus.completed:
        message = 'No completed orders found for the selected period';
        icon = Icons.check_circle_outline;
        break;
      case CustomerOrderFilterStatus.cancelled:
        message = 'No cancelled orders found for the selected period';
        icon = Icons.cancel_outlined;
        break;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliver list view variant for better performance with large datasets
class CustomerOrderHistorySliverListView extends ConsumerWidget {
  final List<CustomerGroupedOrderHistory> groupedHistory;
  final CustomerOrderFilterStatus statusFilter;
  final bool isLoading;
  final bool hasMore;
  final Future<void> Function()? onLoadMore;

  const CustomerOrderHistorySliverListView({
    super.key,
    required this.groupedHistory,
    required this.statusFilter,
    this.isLoading = false,
    this.hasMore = false,
    this.onLoadMore,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groupedHistory.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < groupedHistory.length) {
            return CustomerDailyOrderGroup(
              groupedHistory: groupedHistory[index],
              statusFilter: statusFilter,
            );
          } else if (index == groupedHistory.length && (isLoading || hasMore)) {
            return _buildLoadingOrLoadMore(context);
          }
          return null;
        },
        childCount: groupedHistory.length + (isLoading || hasMore ? 1 : 0),
      ),
    );
  }

  Widget _buildLoadingOrLoadMore(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isLoading) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Loading more orders...',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    
    if (hasMore) {
      return Container(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: OutlinedButton.icon(
            onPressed: onLoadMore,
            icon: const Icon(Icons.expand_more),
            label: const Text('Load More Orders'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }
}

/// Grid view variant for tablet/desktop layouts
class CustomerOrderHistoryGridView extends ConsumerWidget {
  final List<CustomerGroupedOrderHistory> groupedHistory;
  final CustomerOrderFilterStatus statusFilter;
  final int crossAxisCount;

  const CustomerOrderHistoryGridView({
    super.key,
    required this.groupedHistory,
    required this.statusFilter,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (groupedHistory.isEmpty) {
      return const SliverToBoxAdapter(
        child: SizedBox.shrink(),
      );
    }

    return SliverGrid(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 1.2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          if (index < groupedHistory.length) {
            return CustomerDailyOrderGroup(
              groupedHistory: groupedHistory[index],
              statusFilter: statusFilter,
              isCompact: true,
            );
          }
          return null;
        },
        childCount: groupedHistory.length,
      ),
    );
  }
}
