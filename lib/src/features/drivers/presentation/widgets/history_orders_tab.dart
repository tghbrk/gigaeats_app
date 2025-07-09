import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../orders/data/models/order.dart';
import '../providers/driver_orders_management_providers.dart';
import 'driver_order_management_card.dart';
import 'driver_order_details_dialog.dart';

/// Tab widget for displaying order history (delivered and cancelled orders)
class HistoryOrdersTab extends ConsumerWidget {
  const HistoryOrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    debugPrint('🚗 HistoryOrdersTab: Building widget');
    final historyOrdersAsync = ref.watch(historyOrdersStreamProvider);

    return RefreshIndicator(
      onRefresh: () async {
        debugPrint('🚗 HistoryOrdersTab: Refreshing history orders');
        ref.invalidate(historyOrdersStreamProvider);
      },
      child: historyOrdersAsync.when(
        data: (orders) {
          debugPrint('🚗 HistoryOrdersTab: Received ${orders.length} orders');
          return orders.isEmpty
              ? _buildEmptyState(theme)
              : _buildOrdersList(orders);
        },
        loading: () {
          debugPrint('🚗 HistoryOrdersTab: Loading state');
          return _buildLoadingState(theme);
        },
        error: (error, stack) {
          debugPrint('🚗 HistoryOrdersTab: Error state: $error');
          return _buildErrorState(theme, error.toString());
        },
      ),
    );
  }

  Widget _buildOrdersList(List<Order> orders) {
    // Group orders by date for better organization
    final groupedOrders = _groupOrdersByDate(orders);
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: groupedOrders.length,
      itemBuilder: (context, index) {
        final entry = groupedOrders.entries.elementAt(index);
        final date = entry.key;
        final dayOrders = entry.value;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (index > 0) const SizedBox(height: 16),
            _buildDateHeader(date),
            const SizedBox(height: 8),
            ...dayOrders.map((order) => DriverOrderManagementCard(
              key: ValueKey('history_order_${order.id}'),
              order: order,
              type: OrderCardType.history,
              onTap: () => _viewOrderDetails(context, order),
            )),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        date,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.grey,
        ),
      ),
    );
  }

  Map<String, List<Order>> _groupOrdersByDate(List<Order> orders) {
    final grouped = <String, List<Order>>{};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    for (final order in orders) {
      final orderDate = DateTime(
        order.createdAt.year,
        order.createdAt.month,
        order.createdAt.day,
      );
      
      String dateKey;
      if (orderDate == today) {
        dateKey = 'Today';
      } else if (orderDate == yesterday) {
        dateKey = 'Yesterday';
      } else {
        dateKey = DateFormat('MMM dd, yyyy').format(orderDate);
      }
      
      grouped.putIfAbsent(dateKey, () => []).add(order);
    }
    
    return grouped;
  }

  Widget _buildEmptyState(ThemeData theme) {
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
              'Your completed and cancelled orders will appear here.\nStart delivering to build your history!',
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

  Widget _buildLoadingState(ThemeData theme) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 4,
      itemBuilder: (context, index) => _buildLoadingCard(theme),
    );
  }

  Widget _buildLoadingCard(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
            const SizedBox(height: 16),
            Container(
              width: 80,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
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
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                // Trigger refresh by invalidating the provider
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  void _viewOrderDetails(BuildContext context, Order order) {
    debugPrint('🚗 Viewing history order details: ${order.id}');

    showDialog(
      context: context,
      builder: (context) => DriverOrderDetailsDialog(order: order),
    );
  }
}
