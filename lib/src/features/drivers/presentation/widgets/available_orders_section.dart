import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../orders/data/models/order.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/driver_dashboard_providers.dart';
import 'driver_order_details_dialog.dart';

/// Section displaying available orders that drivers can accept
class AvailableOrdersSection extends ConsumerWidget {
  const AvailableOrdersSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final availableOrdersAsync = ref.watch(availableOrdersProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Orders',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              availableOrdersAsync.when(
                data: (orders) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${orders.length}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Orders List
          availableOrdersAsync.when(
            data: (orders) => orders.isEmpty
                ? _buildEmptyState(theme)
                : _buildOrdersList(context, theme, orders, ref),
            loading: () => _buildLoadingState(theme),
            error: (error, stack) => _buildErrorState(theme, error.toString()),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(BuildContext context, ThemeData theme, List<Order> orders, WidgetRef ref) {
    return Column(
      children: orders.map((order) => _buildOrderCard(context, theme, order, ref)).toList(),
    );
  }

  Widget _buildOrderCard(BuildContext context, ThemeData theme, Order order, WidgetRef ref) {
    final estimatedEarnings = _calculateEstimatedEarnings(order);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => _showOrderDetails(context, order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.orderNumber}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        order.vendorName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Est. RM${estimatedEarnings.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Customer and Delivery Info
            Row(
              children: [
                Icon(
                  Icons.person,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.customerName,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 8),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.location_on,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    order.deliveryAddress.fullAddress,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Order Details
            Row(
              children: [
                _buildInfoChip(
                  theme,
                  icon: Icons.schedule,
                  label: DateFormat('HH:mm').format(order.createdAt),
                ),
                const SizedBox(width: 8),
                _buildInfoChip(
                  theme,
                  icon: Icons.shopping_bag,
                  label: '${_getTotalItemsCount(order)} items',
                ),
                const Spacer(),
                _buildAcceptButton(theme, order, ref),
              ],
            ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(ThemeData theme, {required IconData icon, required String label}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAcceptButton(ThemeData theme, Order order, WidgetRef ref) {
    return ElevatedButton.icon(
      onPressed: () => _acceptOrder(order, ref),
      icon: const Icon(Icons.check, size: 16),
      label: const Text('Accept'),
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Available Orders',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'New orders will appear here when they\'re ready for pickup',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: List.generate(3, (index) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        height: 120,
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      )),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            size: 48,
            color: theme.colorScheme.onErrorContainer,
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to Load Orders',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _calculateEstimatedEarnings(Order order) {
    // Calculate estimated earnings (delivery fee + 10% commission)
    return order.deliveryFee + (order.totalAmount * 0.1);
  }

  Future<void> _acceptOrder(Order order, WidgetRef ref) async {
    try {
      debugPrint('🚗 [ACCEPT] Starting order acceptance for ${order.orderNumber} (ID: ${order.id.substring(0, 8)}...)');
      debugPrint('🚗 [ACCEPT] Current order status: ${order.status.value}');

      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;

      if (userId == null) {
        debugPrint('❌ [ACCEPT] User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🚗 [ACCEPT] Driver ID: $userId');
      final supabase = Supabase.instance.client;

      debugPrint('🚗 [ACCEPT] Updating order status from ${order.status.value} to assigned');

      // Assign the order to this driver using enhanced workflow
      final updateResult = await supabase
          .from('orders')
          .update({
            'assigned_driver_id': userId,
            'status': 'assigned', // Enhanced workflow: ready → assigned
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', order.id)
          .select(); // Add select to get updated data back

      debugPrint('🚗 [ACCEPT] Database update result: ${updateResult.length} rows affected');
      if (updateResult.isNotEmpty) {
        debugPrint('🚗 [ACCEPT] Updated order data: ${updateResult.first}');
      }

      // CRITICAL FIX: Update driver's current_delivery_status to match the order workflow
      debugPrint('🚗 [ACCEPT] Updating driver delivery status to assigned for proper workflow progression');
      await supabase
          .from('drivers')
          .update({
            'status': 'on_delivery',
            'current_delivery_status': 'assigned', // Reset to start of workflow
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);

      debugPrint('✅ [ACCEPT] Driver delivery status updated to assigned');

      debugPrint('🚗 [ACCEPT] Invalidating providers to refresh data');
      // Refresh data
      ref.invalidate(availableOrdersProvider);
      ref.invalidate(currentDriverOrderProvider);

      debugPrint('✅ [ACCEPT] Order ${order.orderNumber} accepted by driver $userId');
      
    } catch (e) {
      debugPrint('Error accepting order: $e');
      // Handle error - could show a snackbar or dialog
    }
  }

  void _showOrderDetails(BuildContext context, Order order) {
    debugPrint('🚗 Showing order details for: ${order.id}');
    showDialog(
      context: context,
      builder: (context) => DriverOrderDetailsDialog(order: order),
    );
  }

  int _getTotalItemsCount(Order order) {
    return order.items.fold<int>(0, (sum, item) => sum + item.quantity);
  }
}
