import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/vendor_grouped_order_history.dart';
import '../../data/models/vendor_date_range_filter.dart';
import '../../../orders/data/models/order.dart';

/// Daily order group widget with date header and status-based organization
class VendorDailyOrderGroup extends ConsumerWidget {
  final VendorGroupedOrderHistory groupedHistory;
  final VendorOrderFilterStatus statusFilter;
  final bool isCompact;
  final bool showRevenueTotal;
  final Function(Order)? onOrderTap;

  const VendorDailyOrderGroup({
    super.key,
    required this.groupedHistory,
    required this.statusFilter,
    this.isCompact = false,
    this.showRevenueTotal = true,
    this.onOrderTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date header
          _buildDateHeader(theme),
          
          const SizedBox(height: 12),
          
          // Orders based on status filter
          _buildOrdersList(theme),
        ],
      ),
    );
  }

  Widget _buildDateHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Date and day info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  groupedHistory.displayDate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (!groupedHistory.isToday && !groupedHistory.isYesterday) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('EEEE, MMM dd, yyyy').format(groupedHistory.date),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // Order statistics
          _buildOrderStats(theme),
        ],
      ),
    );
  }

  Widget _buildOrderStats(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Order count
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long,
              size: 16,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 4),
            Text(
              '${groupedHistory.totalOrders} orders',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        
        // Revenue (if enabled and has delivered orders)
        if (showRevenueTotal && groupedHistory.deliveredOrders > 0) ...[
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.monetization_on,
                size: 14,
                color: Colors.green,
              ),
              const SizedBox(width: 4),
              Text(
                'RM${groupedHistory.totalRevenue.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
        
        // Status breakdown (if not compact)
        if (!isCompact && groupedHistory.totalOrders > 1) ...[
          const SizedBox(height: 4),
          _buildStatusBreakdown(theme),
        ],
      ],
    );
  }

  Widget _buildStatusBreakdown(ThemeData theme) {
    final statusCounts = <String, int>{
      if (groupedHistory.activeOrders > 0) 'Active': groupedHistory.activeOrders,
      if (groupedHistory.deliveredOrders > 0) 'Delivered': groupedHistory.deliveredOrders,
      if (groupedHistory.cancelledOrders > 0) 'Cancelled': groupedHistory.cancelledOrders,
    };

    if (statusCounts.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      children: statusCounts.entries.map((entry) {
        Color statusColor;
        switch (entry.key) {
          case 'Active':
            statusColor = Colors.blue;
            break;
          case 'Delivered':
            statusColor = Colors.green;
            break;
          case 'Cancelled':
            statusColor = Colors.red;
            break;
          default:
            statusColor = theme.colorScheme.onSurface;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '${entry.value} ${entry.key}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildOrdersList(ThemeData theme) {
    final ordersToShow = _getOrdersToShow();

    debugPrint('🏪 VendorDailyOrderGroup._buildOrdersList: ${groupedHistory.displayDate} for status: ${statusFilter.displayName}');
    debugPrint('🏪 VendorDailyOrderGroup._buildOrdersList: Group has ${groupedHistory.totalOrders} total orders');
    debugPrint('🏪 VendorDailyOrderGroup._buildOrdersList: _getOrdersToShow() returned ${ordersToShow.length} orders');

    // Debug: Log the status of each order to show
    for (int i = 0; i < ordersToShow.length; i++) {
      final order = ordersToShow[i];
      debugPrint('🏪 VendorDailyOrderGroup._buildOrdersList: Order $i - ID: ${order.id}, Status: ${order.status.value}, Amount: RM${order.totalAmount}');
    }

    if (ordersToShow.isEmpty) {
      debugPrint('🏪 VendorDailyOrderGroup._buildOrdersList: No orders to show, returning empty section');
      return _buildEmptySection(theme);
    }

    debugPrint('🏪 VendorDailyOrderGroup._buildOrdersList: Building ${ordersToShow.length} order cards');

    if (isCompact) {
      return _buildCompactOrdersList(theme, ordersToShow);
    } else {
      return _buildFullOrdersList(theme, ordersToShow);
    }
  }

  Widget _buildFullOrdersList(ThemeData theme, List<Order> orders) {
    return Column(
      children: orders.map((order) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildOrderCard(order, theme),
        );
      }).toList(),
    );
  }

  Widget _buildCompactOrdersList(ThemeData theme, List<Order> orders) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: orders.take(3).map((order) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildOrderCard(order, theme, isCompact: true),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOrderCard(Order order, ThemeData theme, {bool isCompact = false}) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => onOrderTap?.call(order),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Order #${order.orderNumber}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getStatusColor(order.status).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      order.status.displayName,
                      style: TextStyle(
                        color: _getStatusColor(order.status),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (!isCompact) ...[
                const SizedBox(height: 8),
                
                // Customer and amount
                Row(
                  children: [
                    Icon(
                      Icons.person,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                    Text(
                      'RM ${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 4),
                
                // Items count and time
                Row(
                  children: [
                    Text(
                      '${order.items.length} item(s)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      DateFormat('HH:mm').format(order.createdAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        order.customerName,
                        style: theme.textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      'RM ${order.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptySection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              Icons.receipt_long,
              size: 32,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
            Text(
              'No orders for ${statusFilter.displayName.toLowerCase()}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Order> _getOrdersToShow() {
    switch (statusFilter) {
      case VendorOrderFilterStatus.all:
        return groupedHistory.orders;
      case VendorOrderFilterStatus.active:
        return groupedHistory.orders.where((order) => 
          ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(order.status.value)
        ).toList();
      case VendorOrderFilterStatus.completed:
        return groupedHistory.orders.where((order) => order.status.value == 'delivered').toList();
      case VendorOrderFilterStatus.cancelled:
        return groupedHistory.orders.where((order) => order.status.value == 'cancelled').toList();
      case VendorOrderFilterStatus.preparing:
        return groupedHistory.orders.where((order) => order.status.value == 'preparing').toList();
      case VendorOrderFilterStatus.ready:
        return groupedHistory.orders.where((order) => order.status.value == 'ready').toList();
      case VendorOrderFilterStatus.delivered:
        return groupedHistory.orders.where((order) => order.status.value == 'delivered').toList();
    }
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
        return Colors.teal;
      case OrderStatus.outForDelivery:
        return Colors.indigo;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }
}

/// Expandable daily order group for better organization
class ExpandableVendorDailyOrderGroup extends ConsumerStatefulWidget {
  final VendorGroupedOrderHistory groupedHistory;
  final VendorOrderFilterStatus statusFilter;
  final bool initiallyExpanded;
  final Function(Order)? onOrderTap;

  const ExpandableVendorDailyOrderGroup({
    super.key,
    required this.groupedHistory,
    required this.statusFilter,
    this.initiallyExpanded = true,
    this.onOrderTap,
  });

  @override
  ConsumerState<ExpandableVendorDailyOrderGroup> createState() => _ExpandableVendorDailyOrderGroupState();
}

class _ExpandableVendorDailyOrderGroupState extends ConsumerState<ExpandableVendorDailyOrderGroup>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initiallyExpanded;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );

    if (_isExpanded) {
      _animationController.value = 1.0;
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Expandable header
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _toggleExpansion,
              borderRadius: BorderRadius.circular(12),
              child: Row(
                children: [
                  // Expand/collapse icon
                  AnimatedRotation(
                    turns: _isExpanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 300),
                    child: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Date and stats (same as regular group)
                  Expanded(
                    child: VendorDailyOrderGroup(
                      groupedHistory: widget.groupedHistory,
                      statusFilter: widget.statusFilter,
                      isCompact: true,
                      onOrderTap: widget.onOrderTap,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          SizeTransition(
            sizeFactor: _expandAnimation,
            child: Container(
              padding: const EdgeInsets.only(top: 12),
              child: VendorDailyOrderGroup(
                groupedHistory: widget.groupedHistory,
                statusFilter: widget.statusFilter,
                onOrderTap: widget.onOrderTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
