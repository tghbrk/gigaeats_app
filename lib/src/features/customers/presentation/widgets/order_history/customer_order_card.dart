import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../orders/data/models/order.dart';
import '../../../../orders/data/models/delivery_method.dart';

/// Enhanced customer order card with Material Design 3 styling
class CustomerOrderCard extends ConsumerWidget {
  final Order order;
  final bool isCompact;
  final bool showDate;
  final bool showActions;
  final VoidCallback? onTap;

  const CustomerOrderCard({
    super.key,
    required this.order,
    this.isCompact = false,
    this.showDate = true,
    this.showActions = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap ?? () => _showOrderDetails(context),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: isCompact ? _buildCompactContent(theme, context) : _buildFullContent(theme, context),
        ),
      ),
    );
  }

  Widget _buildFullContent(ThemeData theme, BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header row
        _buildHeader(theme),
        
        const SizedBox(height: 12),
        
        // Vendor and order info
        _buildOrderInfo(theme),
        
        const SizedBox(height: 12),
        
        // Order items preview
        _buildOrderItemsPreview(theme),
        
        const SizedBox(height: 12),
        
        // Footer with total and actions
        _buildFooter(theme, context),
      ],
    );
  }

  Widget _buildCompactContent(ThemeData theme, BuildContext context) {
    return Row(
      children: [
        // Order info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _buildStatusChip(theme, isCompact: true),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                order.vendorName,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'RM${order.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Quick action
        IconButton(
          onPressed: () => _showOrderDetails(context),
          icon: const Icon(Icons.arrow_forward_ios, size: 16),
          tooltip: 'View details',
        ),
      ],
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order #${order.orderNumber}',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showDate) ...[
                const SizedBox(height: 2),
                Text(
                  _formatOrderDate(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        _buildStatusChip(theme),
      ],
    );
  }

  Widget _buildOrderInfo(ThemeData theme) {
    return Row(
      children: [
        // Vendor icon and info
        Expanded(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.vendorName,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${order.items.length} item${order.items.length != 1 ? 's' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Delivery method indicator
        _buildDeliveryMethodChip(theme),
      ],
    );
  }

  Widget _buildOrderItemsPreview(ThemeData theme) {
    final displayItems = order.items.take(2).toList();
    final remainingCount = order.items.length - displayItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Text(
                '${item.quantity}x',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.name,
                  style: theme.textTheme.bodySmall,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                'RM${(item.unitPrice * item.quantity).toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )),
        
        if (remainingCount > 0)
          Text(
            '+$remainingCount more item${remainingCount != 1 ? 's' : ''}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.primary,
              fontStyle: FontStyle.italic,
            ),
          ),
      ],
    );
  }

  Widget _buildFooter(ThemeData theme, BuildContext context) {
    return Row(
      children: [
        // Total amount
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                'RM${order.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        
        // Action buttons
        if (showActions) _buildActionButtons(theme, context),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // View details button
        OutlinedButton.icon(
          onPressed: () => _showOrderDetails(context),
          icon: const Icon(Icons.visibility, size: 16),
          label: const Text('Details'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            visualDensity: VisualDensity.compact,
          ),
        ),
        
        const SizedBox(width: 8),
        
        // Status-specific actions
        if (order.status == OrderStatus.delivered) ...[
          FilledButton.icon(
            onPressed: () => _reorderItems(context),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reorder'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ] else if (order.status == OrderStatus.cancelled) ...[
          OutlinedButton.icon(
            onPressed: () => _reorderItems(context),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Reorder'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              visualDensity: VisualDensity.compact,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildStatusChip(ThemeData theme, {bool isCompact = false}) {
    final statusColor = _getStatusColor(order.status);
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.3),
        ),
      ),
      child: Text(
        order.status.displayName,
        style: theme.textTheme.labelSmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w600,
          fontSize: isCompact ? 10 : null,
        ),
      ),
    );
  }

  Widget _buildDeliveryMethodChip(ThemeData theme) {
    IconData icon;
    String label;
    
    switch (order.deliveryMethod) {
      case DeliveryMethod.customerPickup:
        icon = Icons.directions_walk;
        label = 'Pickup';
        break;
      case DeliveryMethod.salesAgentPickup:
        icon = Icons.person;
        label = 'Agent';
        break;
      case DeliveryMethod.ownFleet:
        icon = Icons.delivery_dining;
        label = 'Delivery';
        break;
      case DeliveryMethod.thirdParty:
        icon = Icons.local_shipping;
        label = 'Third Party';
        break;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ],
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
        return Colors.green.shade700;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  String _formatOrderDate() {
    final now = DateTime.now();
    final orderDate = order.createdAt;
    final difference = now.difference(orderDate);

    if (difference.inDays == 0) {
      return 'Today, ${DateFormat('HH:mm').format(orderDate)}';
    } else if (difference.inDays == 1) {
      return 'Yesterday, ${DateFormat('HH:mm').format(orderDate)}';
    } else if (difference.inDays < 7) {
      return DateFormat('EEEE, HH:mm').format(orderDate);
    } else {
      return DateFormat('MMM dd, HH:mm').format(orderDate);
    }
  }

  void _showOrderDetails(BuildContext context) {
    context.push('/customer/order/${order.id}');
  }

  void _reorderItems(BuildContext context) {
    // TODO: Implement reorder functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reorder functionality coming soon!'),
      ),
    );
  }
}
