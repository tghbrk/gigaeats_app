import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../data/models/customer_order_history_models.dart';
import '../../../../orders/data/models/order.dart';
import 'customer_order_card.dart';

/// Daily order group widget with date header and status-based organization
class CustomerDailyOrderGroup extends ConsumerWidget {
  final CustomerGroupedOrderHistory groupedHistory;
  final CustomerOrderFilterStatus statusFilter;
  final bool isCompact;
  final bool showSpendingTotal;

  const CustomerDailyOrderGroup({
    super.key,
    required this.groupedHistory,
    required this.statusFilter,
    this.isCompact = false,
    this.showSpendingTotal = true,
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
          // Date icon and text
          Expanded(
            child: Row(
              children: [
                Icon(
                  _getDateIcon(),
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  groupedHistory.displayDate,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  DateFormat('MMM dd, yyyy').format(groupedHistory.date),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          
          // Order count and spending
          _buildHeaderStats(theme),
        ],
      ),
    );
  }

  Widget _buildHeaderStats(ThemeData theme) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Order count chip
        _buildStatChip(
          theme,
          icon: Icons.receipt_long,
          label: _getOrderCountText(),
          color: theme.colorScheme.primary,
        ),
        
        if (showSpendingTotal && groupedHistory.totalSpent > 0) ...[
          const SizedBox(width: 8),
          // Spending chip
          _buildStatChip(
            theme,
            icon: Icons.attach_money,
            label: 'RM${groupedHistory.totalSpent.toStringAsFixed(0)}',
            color: theme.colorScheme.tertiary,
          ),
        ],
      ],
    );
  }

  Widget _buildStatChip(ThemeData theme, {
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(ThemeData theme) {
    final ordersToShow = _getOrdersToShow();
    
    if (ordersToShow.isEmpty) {
      return _buildEmptySection(theme);
    }

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
          child: CustomerOrderCard(
            order: order,
            showDate: false, // Date is shown in group header
          ),
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
            child: CustomerOrderCard(
              order: order,
              isCompact: true,
              showDate: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildEmptySection(ThemeData theme) {
    String message;
    switch (statusFilter) {
      case CustomerOrderFilterStatus.completed:
        message = 'No completed orders on this day';
        break;
      case CustomerOrderFilterStatus.cancelled:
        message = 'No cancelled orders on this day';
        break;
      case CustomerOrderFilterStatus.all:
        message = 'No orders on this day';
        break;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  List<Order> _getOrdersToShow() {
    switch (statusFilter) {
      case CustomerOrderFilterStatus.completed:
        return groupedHistory.completedOrders;
      case CustomerOrderFilterStatus.cancelled:
        return groupedHistory.cancelledOrders;
      case CustomerOrderFilterStatus.all:
        return groupedHistory.allOrders;
    }
  }

  String _getOrderCountText() {
    switch (statusFilter) {
      case CustomerOrderFilterStatus.completed:
        return '${groupedHistory.completedCount} completed';
      case CustomerOrderFilterStatus.cancelled:
        return '${groupedHistory.cancelledCount} cancelled';
      case CustomerOrderFilterStatus.all:
        return '${groupedHistory.totalOrders} orders';
    }
  }

  IconData _getDateIcon() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    
    if (groupedHistory.date == today) {
      return Icons.today;
    } else if (groupedHistory.date == yesterday) {
      return Icons.history;
    } else if (groupedHistory.date.isAfter(today.subtract(const Duration(days: 7)))) {
      return Icons.view_week;
    } else {
      return Icons.calendar_today;
    }
  }
}

/// Expandable daily order group for better organization
class ExpandableCustomerDailyOrderGroup extends ConsumerStatefulWidget {
  final CustomerGroupedOrderHistory groupedHistory;
  final CustomerOrderFilterStatus statusFilter;
  final bool initiallyExpanded;

  const ExpandableCustomerDailyOrderGroup({
    super.key,
    required this.groupedHistory,
    required this.statusFilter,
    this.initiallyExpanded = true,
  });

  @override
  ConsumerState<ExpandableCustomerDailyOrderGroup> createState() => _ExpandableCustomerDailyOrderGroupState();
}

class _ExpandableCustomerDailyOrderGroupState extends ConsumerState<ExpandableCustomerDailyOrderGroup>
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

  void _toggleExpanded() {
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
          InkWell(
            onTap: _toggleExpanded,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
              ),
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
                    child: CustomerDailyOrderGroup(
                      groupedHistory: widget.groupedHistory,
                      statusFilter: widget.statusFilter,
                      isCompact: true,
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
              child: CustomerDailyOrderGroup(
                groupedHistory: widget.groupedHistory,
                statusFilter: widget.statusFilter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
