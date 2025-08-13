import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../orders/data/models/order.dart';

/// Enhanced order card specifically designed for history view with detailed information
class EnhancedOrderHistoryCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;
  final bool showDetailedInfo;
  final bool showEarnings;

  const EnhancedOrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
    this.showDetailedInfo = true,
    this.showEarnings = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivered = order.status.value == 'delivered';
    final isCancelled = order.status.value == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row with order number and status
              _buildHeaderRow(theme, isDelivered, isCancelled),
              
              const SizedBox(height: 12),
              
              // Vendor and customer info
              _buildVendorCustomerInfo(theme),
              
              if (showDetailedInfo) ...[
                const SizedBox(height: 12),
                _buildOrderDetails(theme),
              ],
              
              const SizedBox(height: 12),
              
              // Footer with timing and earnings
              _buildFooterRow(theme, isDelivered, isCancelled),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderRow(ThemeData theme, bool isDelivered, bool isCancelled) {
    return Row(
      children: [
        // Order number
        Expanded(
          child: Text(
            order.orderNumber,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        
        // Status badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isDelivered 
                ? theme.colorScheme.primaryContainer
                : isCancelled 
                    ? theme.colorScheme.errorContainer
                    : theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isDelivered
                    ? Icons.check_circle
                    : isCancelled
                        ? Icons.cancel
                        : Icons.help_outline,
                size: 14,
                color: isDelivered
                    ? theme.colorScheme.onPrimaryContainer
                    : isCancelled
                        ? theme.colorScheme.onErrorContainer
                        : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                isDelivered
                    ? 'Delivered'
                    : isCancelled
                        ? 'Cancelled'
                        : order.status.displayName,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDelivered
                      ? theme.colorScheme.onPrimaryContainer
                      : isCancelled
                          ? theme.colorScheme.onErrorContainer
                          : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCustomerInfo(ThemeData theme) {
    return Column(
      children: [
        // Vendor info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.store,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.vendorName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 8),
        
        // Customer info
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(
                Icons.person,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                order.customerName,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildOrderDetails(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          // Items count and total
          Row(
            children: [
              Icon(
                Icons.shopping_bag_outlined,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                '${order.items.length} item${order.items.length == 1 ? '' : 's'}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              Text(
                'RM ${order.totalAmount.toStringAsFixed(2)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
          
          if (order.deliveryFee > 0) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Delivery fee',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                Text(
                  'RM ${order.deliveryFee.toStringAsFixed(2)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFooterRow(ThemeData theme, bool isDelivered, bool isCancelled) {
    final deliveryTime = order.actualDeliveryTime ?? order.createdAt;
    final timeText = _getTimeText(deliveryTime);
    
    return Row(
      children: [
        // Timing info
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                timeText,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        
        // Earnings (if enabled and delivered)
        if (showEarnings && isDelivered) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.payments,
                  size: 14,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  '+RM ${_calculateDriverEarnings().toStringAsFixed(2)}',
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
        
        // View details arrow
        Icon(
          Icons.chevron_right,
          size: 20,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }

  String _getTimeText(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final orderDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
    
    if (orderDate == today) {
      return DateFormat('HH:mm').format(dateTime);
    } else if (orderDate == today.subtract(const Duration(days: 1))) {
      return 'Yesterday ${DateFormat('HH:mm').format(dateTime)}';
    } else if (dateTime.year == now.year) {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    } else {
      return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
    }
  }

  double _calculateDriverEarnings() {
    // Simple calculation - in real app this would be more complex
    // Typically driver gets delivery fee + commission
    return order.deliveryFee + (order.commissionAmount ?? 0);
  }
}

/// Compact version of the order history card for dense layouts
class CompactOrderHistoryCard extends StatelessWidget {
  final Order order;
  final VoidCallback? onTap;

  const CompactOrderHistoryCard({
    super.key,
    required this.order,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDelivered = order.status.value == 'delivered';
    final isCancelled = order.status.value == 'cancelled';

    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Status indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isDelivered 
                      ? theme.colorScheme.primary
                      : isCancelled 
                          ? theme.colorScheme.error
                          : theme.colorScheme.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Order info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      order.vendorName,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              // Amount and time
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'RM ${order.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    DateFormat('HH:mm').format(order.actualDeliveryTime ?? order.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
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
}
