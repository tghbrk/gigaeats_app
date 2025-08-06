import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/data/models/order.dart';
import '../../data/models/grouped_order_history.dart';
import 'enhanced_order_history_card.dart';
import 'date_filter/date_filter_components.dart';

/// Enhanced tab widget for displaying order history with date filtering and daily organization
class EnhancedHistoryOrdersTab extends ConsumerStatefulWidget {
  const EnhancedHistoryOrdersTab({super.key});

  @override
  ConsumerState<EnhancedHistoryOrdersTab> createState() => _EnhancedHistoryOrdersTabState();
}

class _EnhancedHistoryOrdersTabState extends ConsumerState<EnhancedHistoryOrdersTab>
    with DateFilterMixin {
  final ScrollController _scrollController = ScrollController();
  bool _showScrollToTop = false;

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
    final showScrollToTop = _scrollController.offset > 200;
    if (showScrollToTop != _showScrollToTop) {
      setState(() {
        _showScrollToTop = showScrollToTop;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] ===== BUILD METHOD CALLED =====');
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] Timestamp: ${DateTime.now()}');
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] Context: ${context.runtimeType}');
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] Widget mounted: $mounted');
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] Widget hash: $hashCode');

    final combinedFilter = ref.watch(combinedDateFilterProvider);
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] Combined filter: $combinedFilter');
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] About to watch groupedOrderHistoryProvider...');

    final groupedHistoryAsync = ref.watch(groupedOrderHistoryProvider(combinedFilter));
    debugPrint('🔍 [ENHANCED-HISTORY-TAB] Grouped history async state: ${groupedHistoryAsync.runtimeType}');

    return Scaffold(
      body: Column(
        children: [
          // Date filter bar
          CompactDateFilterBar(
            showOrderCount: true,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
          
          // Quick filter chips (optional)
          if (hasActiveFilter())
            SizedBox(
              height: 48,
              child: QuickFilterChips(
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
          
          // Main content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                debugPrint('🚗 EnhancedHistoryOrdersTab: Refreshing history orders');
                ref.invalidate(groupedOrderHistoryProvider(combinedFilter));
                ref.invalidate(orderCountByDateProvider(combinedFilter));
              },
              child: groupedHistoryAsync.when(
                data: (groupedHistory) {
                  debugPrint('🚗 EnhancedHistoryOrdersTab: Received ${groupedHistory.length} date groups');
                  return groupedHistory.isEmpty
                      ? _buildEmptyState(theme, combinedFilter)
                      : _buildGroupedOrdersList(theme, groupedHistory);
                },
                loading: () {
                  debugPrint('🚗 EnhancedHistoryOrdersTab: Loading state');
                  return _buildLoadingState(theme);
                },
                error: (error, stack) {
                  debugPrint('🚗 EnhancedHistoryOrdersTab: Error state: $error');
                  return _buildErrorState(theme, error.toString());
                },
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              onPressed: () {
                _scrollController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                );
              },
              tooltip: 'Scroll to top',
              child: const Icon(Icons.keyboard_arrow_up),
            )
          : null,
    );
  }

  Widget _buildGroupedOrdersList(ThemeData theme, List<GroupedOrderHistory> groupedHistory) {
    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Summary section (if there are orders)
        if (groupedHistory.isNotEmpty)
          SliverToBoxAdapter(
            child: _buildSummarySection(theme, groupedHistory),
          ),
        
        // Grouped orders
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final group = groupedHistory[index];
              return _buildDateGroup(theme, group, index == 0);
            },
            childCount: groupedHistory.length,
          ),
        ),
        
        // Load more section (for pagination)
        SliverToBoxAdapter(
          child: _buildLoadMoreSection(theme),
        ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Widget _buildSummarySection(ThemeData theme, List<GroupedOrderHistory> groupedHistory) {
    final summary = GroupedOrderHistory.getSummary(groupedHistory);
    
    return Container(
      margin: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.analytics_outlined,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Summary',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (summary.dateRange != null)
                    Text(
                      GroupedOrderHistory.getDateRangeDisplay(
                        summary.dateRange!.start,
                        summary.dateRange!.end,
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryItem(
                      theme,
                      'Total Orders',
                      '${summary.totalOrders}',
                      Icons.receipt_long,
                    ),
                  ),
                  Expanded(
                    child: _buildSummaryItem(
                      theme,
                      'Delivered',
                      '${summary.deliveredOrders}',
                      Icons.check_circle,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  if (summary.cancelledOrders > 0)
                    Expanded(
                      child: _buildSummaryItem(
                        theme,
                        'Cancelled',
                        '${summary.cancelledOrders}',
                        Icons.cancel,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  Expanded(
                    child: _buildSummaryItem(
                      theme,
                      'Earnings',
                      'RM ${summary.totalEarnings.toStringAsFixed(2)}',
                      Icons.payments,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryItem(
    ThemeData theme,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    final itemColor = color ?? theme.colorScheme.onSurfaceVariant;
    
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: itemColor,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: itemColor,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDateGroup(ThemeData theme, GroupedOrderHistory group, bool isFirst) {
    return Container(
      margin: EdgeInsets.only(
        left: 16,
        right: 16,
        top: isFirst ? 0 : 16,
        bottom: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced date header with order count and statistics
          _buildEnhancedDateHeader(theme, group),
          const SizedBox(height: 12),
          
          // Orders for this date
          ...group.orders.asMap().entries.map((entry) {
            final index = entry.key;
            final order = entry.value;
            
            return Container(
              margin: EdgeInsets.only(bottom: index < group.orders.length - 1 ? 8 : 0),
              child: EnhancedOrderHistoryCard(
                key: ValueKey('enhanced_history_order_${order.id}'),
                order: order,
                onTap: () => _viewOrderDetails(context, order),
                showDetailedInfo: true,
                showEarnings: true,
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEnhancedDateHeader(ThemeData theme, GroupedOrderHistory group) {
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

  Widget _buildLoadMoreSection(ThemeData theme) {
    final combinedFilter = ref.watch(combinedDateFilterProvider);
    final hasMoreAsync = ref.watch(hasMoreOrdersProvider(combinedFilter));
    
    return hasMoreAsync.when(
      data: (hasMore) {
        if (!hasMore) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.all(16),
          child: Center(
            child: OutlinedButton.icon(
              onPressed: () => _loadMoreOrders(),
              icon: const Icon(Icons.expand_more),
              label: const Text('Load More Orders'),
            ),
          ),
        );
      },
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      ),
      error: (_, stackTrace) => const SizedBox.shrink(),
    );
  }

  void _loadMoreOrders() {
    final currentFilter = ref.read(dateFilterProvider);
    final newOffset = currentFilter.offset + currentFilter.limit;

    debugPrint('🚗 EnhancedHistoryOrdersTab: Loading more orders, offset: $newOffset');
    ref.read(dateFilterProvider.notifier).setOffset(newOffset);
  }

  Widget _buildEmptyState(ThemeData theme, DateRangeFilter filter) {
    // Determine empty state based on filter
    final hasFilter = filter.startDate != null ||
                     filter.endDate != null ||
                     ref.read(selectedQuickFilterProvider) != QuickDateFilter.all;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              hasFilter ? Icons.search_off : Icons.history_outlined,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              hasFilter ? 'No Orders Found' : 'No Order History',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              hasFilter
                  ? 'No orders found for the selected date range.\nTry adjusting your filter or selecting a different time period.'
                  : 'Your completed and cancelled orders will appear here.\nStart delivering to build your history!',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (hasFilter) ...[
              FilledButton.icon(
                onPressed: () => resetFilters(),
                icon: const Icon(Icons.clear_all),
                label: const Text('Clear Filters'),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => showFilterOptions(context),
                icon: const Icon(Icons.tune),
                label: const Text('Adjust Filters'),
              ),
            ] else ...[
              OutlinedButton.icon(
                onPressed: () => showFilterOptions(context),
                icon: const Icon(Icons.filter_list),
                label: const Text('Filter Orders'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        if (index == 0) {
          // Loading summary card
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 80,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: List.generate(4, (i) => Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: i < 3 ? 8 : 0),
                        child: Column(
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              width: double.infinity,
                              height: 14,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Container(
                              width: double.infinity,
                              height: 12,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )),
                  ),
                ],
              ),
            ),
          );
        }

        return _buildLoadingDateGroup(theme, index == 1);
      },
    );
  }

  Widget _buildLoadingDateGroup(ThemeData theme, bool isFirst) {
    return Container(
      margin: EdgeInsets.only(
        bottom: 16,
        top: isFirst ? 0 : 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Loading date header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 100,
                        height: 16,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        width: 80,
                        height: 12,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 60,
                      height: 16,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Loading order cards
          ...List.generate(2, (i) => Container(
            margin: EdgeInsets.only(bottom: i == 0 ? 8 : 0),
            child: _buildLoadingOrderCard(theme),
          )),
        ],
      ),
    );
  }

  Widget _buildLoadingOrderCard(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                Container(
                  width: 70,
                  height: 20,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 200,
              height: 14,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => resetFilters(),
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Reset Filters'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: () {
                    final combinedFilter = ref.read(combinedDateFilterProvider);
                    ref.invalidate(groupedOrderHistoryProvider(combinedFilter));
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try Again'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewOrderDetails(BuildContext context, Order order) {
    debugPrint('🚗 Viewing enhanced history order details: ${order.id}');

    // For now, show a simple dialog with order details
    // TODO: Replace with proper DriverOrderDetailsDialog when available
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
