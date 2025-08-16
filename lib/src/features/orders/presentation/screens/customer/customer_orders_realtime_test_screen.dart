import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/order.dart';
import '../../../../customers/presentation/providers/customer_order_provider.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';

/// Test screen to demonstrate real-time order status updates
/// This screen shows both the old FutureProvider and new StreamProvider side by side
class CustomerOrdersRealtimeTestScreen extends ConsumerWidget {
  const CustomerOrdersRealtimeTestScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final futureOrders = ref.watch(currentCustomerOrdersProvider);
    final streamOrders = ref.watch(currentCustomerOrdersRealtimeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Orders Test'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Orders Test',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This screen compares the old FutureProvider (manual refresh) with the new StreamProvider (real-time updates). '
                      'Change an order status in the admin/vendor interface to see real-time updates.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        GEButton.secondary(
                          text: 'Refresh Future',
                          onPressed: () => ref.invalidate(currentCustomerOrdersProvider),
                        ),
                        const SizedBox(width: 12),
                        GEButton.secondary(
                          text: 'Refresh Stream',
                          onPressed: () => ref.invalidate(currentCustomerOrdersRealtimeProvider),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Comparison view
            Expanded(
              child: Row(
                children: [
                  // Future Provider (Old)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FutureProvider (Manual)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildOrdersList(futureOrders, theme, isRealtime: false),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Stream Provider (New)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'StreamProvider (Real-time)',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            streamOrders.when(
                              data: (_) => Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              loading: () => const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                              error: (error, _) => const Icon(
                                Icons.error,
                                size: 16,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _buildOrdersList(streamOrders, theme, isRealtime: true),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersList(AsyncValue<List<Order>> ordersAsync, ThemeData theme, {required bool isRealtime}) {
    return ordersAsync.when(
      data: (orders) {
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'No orders',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Card(
              key: isRealtime ? ValueKey('realtime_${order.id}_${order.status.value}_${order.updatedAt.millisecondsSinceEpoch}') : ValueKey('future_${order.id}'),
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(
                  'Order #${order.orderNumber}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.vendorName),
                    const SizedBox(height: 4),
                    Text(
                      'Updated: ${_formatTime(order.updatedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Error: ${error.toString()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.red[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Colors.orange;
      case OrderStatus.confirmed:
        return Colors.blue;
      case OrderStatus.preparing:
        return Colors.purple;
      case OrderStatus.ready:
        return Colors.green;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    final second = date.second.toString().padLeft(2, '0');
    return '$hour:$minute:$second';
  }
}
