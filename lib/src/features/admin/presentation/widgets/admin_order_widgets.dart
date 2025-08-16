import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/admin_order_provider.dart';
import '../../../../core/utils/responsive_utils.dart';

// ============================================================================
// ADMIN ORDERS TAB
// ============================================================================

/// Main admin orders tab widget
class AdminOrdersTab extends ConsumerStatefulWidget {
  const AdminOrdersTab({super.key});

  @override
  ConsumerState<AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends ConsumerState<AdminOrdersTab>
    with TickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    
    // Load orders when tab is first opened
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adminOrderProvider.notifier).loadOrders(refresh: true);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          onTap: (index) => _onTabChanged(index),
          tabs: const [
            Tab(text: 'All Orders', icon: Icon(Icons.receipt_long)),
            Tab(text: 'Pending', icon: Icon(Icons.pending_actions)),
            Tab(text: 'Active', icon: Icon(Icons.local_shipping)),
            Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(adminOrderProvider.notifier).loadOrders(refresh: true);
            },
            tooltip: 'Refresh',
          ),
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _exportOrders,
            tooltip: 'Export',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          const AdminOrderSearchAndFilterBar(),
          
          // Order Statistics
          const AdminOrderStatsBar(),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(null), // All orders
                _buildOrdersTab('pending'),
                _buildActiveOrdersTab(),
                _buildOrdersTab('delivered'),
                const AdminOrderAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onTabChanged(int index) {
    // Update filter based on selected tab
    switch (index) {
      case 0: // All orders
        ref.read(adminOrderProvider.notifier).updateStatusFilter(null);
        break;
      case 1: // Pending
        ref.read(adminOrderProvider.notifier).updateStatusFilter('pending');
        break;
      case 2: // Active (confirmed, preparing, ready, out_for_delivery)
        // This will be handled in _buildActiveOrdersTab
        break;
      case 3: // Completed
        ref.read(adminOrderProvider.notifier).updateStatusFilter('delivered');
        break;
      case 4: // Analytics
        // No filter needed for analytics
        break;
    }
  }

  Widget _buildOrdersTab(String? status) {
    final orderState = ref.watch(adminOrderProvider);
    
    if (orderState.isLoading && orderState.orders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (orderState.orders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminOrderProvider.notifier).loadOrders(refresh: true);
      },
      child: ResponsiveContainer(
        child: context.isDesktop
            ? _buildDesktopOrdersList(orderState.orders)
            : _buildMobileOrdersList(orderState.orders),
      ),
    );
  }

  Widget _buildActiveOrdersTab() {
    final orderState = ref.watch(adminOrderProvider);
    
    // Filter for active orders
    final activeOrders = orderState.orders.where((order) {
      final status = order['status'] as String?;
      return status == 'confirmed' || 
             status == 'preparing' || 
             status == 'ready' || 
             status == 'out_for_delivery';
    }).toList();

    if (orderState.isLoading && activeOrders.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (activeOrders.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.read(adminOrderProvider.notifier).loadOrders(refresh: true);
      },
      child: ResponsiveContainer(
        child: context.isDesktop
            ? _buildDesktopOrdersList(activeOrders)
            : _buildMobileOrdersList(activeOrders),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No orders found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileOrdersList(List<Map<String, dynamic>> orders) {
    return ListView.builder(
      padding: context.responsivePadding,
      itemCount: orders.length + 1, // +1 for load more indicator
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return _buildLoadMoreIndicator();
        }
        
        final order = orders[index];
        return AdminOrderCard(order: order);
      },
    );
  }

  Widget _buildDesktopOrdersList(List<Map<String, dynamic>> orders) {
    return GridView.builder(
      padding: context.responsivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: orders.length + 1, // +1 for load more indicator
      itemBuilder: (context, index) {
        if (index == orders.length) {
          return _buildLoadMoreIndicator();
        }
        
        final order = orders[index];
        return AdminOrderCard(order: order);
      },
    );
  }

  Widget _buildLoadMoreIndicator() {
    final orderState = ref.watch(adminOrderProvider);
    
    if (!orderState.hasMore) {
      return const SizedBox.shrink();
    }
    
    if (orderState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: () {
            ref.read(adminOrderProvider.notifier).loadMoreOrders();
          },
          child: const Text('Load More'),
        ),
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => const AdminOrderFilterDialog(),
    );
  }

  void _exportOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting orders...')),
    );
  }
}

// ============================================================================
// SEARCH AND FILTER BAR
// ============================================================================

/// Search and filter bar for orders
class AdminOrderSearchAndFilterBar extends ConsumerWidget {
  const AdminOrderSearchAndFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search orders...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest,
              ),
              onChanged: (value) {
                ref.read(adminOrderProvider.notifier).updateSearchQuery(value);
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: DropdownButtonFormField<String>(
              initialValue: 'Today',
              decoration: InputDecoration(
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              items: const [
                DropdownMenuItem(value: 'Today', child: Text('Today')),
                DropdownMenuItem(value: 'This Week', child: Text('This Week')),
                DropdownMenuItem(value: 'This Month', child: Text('This Month')),
                DropdownMenuItem(value: 'All Time', child: Text('All Time')),
              ],
              onChanged: (value) {
                _updateDateFilter(ref, value!);
              },
            ),
          ),
        ],
      ),
    );
  }

  void _updateDateFilter(WidgetRef ref, String period) {
    DateTime? startDate;
    DateTime? endDate = DateTime.now();

    switch (period) {
      case 'Today':
        startDate = DateTime(endDate.year, endDate.month, endDate.day);
        break;
      case 'This Week':
        startDate = endDate.subtract(Duration(days: endDate.weekday - 1));
        startDate = DateTime(startDate.year, startDate.month, startDate.day);
        break;
      case 'This Month':
        startDate = DateTime(endDate.year, endDate.month, 1);
        break;
      case 'All Time':
        startDate = null;
        endDate = null;
        break;
    }

    ref.read(adminOrderProvider.notifier).updateDateRangeFilter(startDate, endDate);
  }
}

// ============================================================================
// ORDER STATISTICS BAR
// ============================================================================

/// Statistics bar showing order metrics
class AdminOrderStatsBar extends ConsumerWidget {
  const AdminOrderStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderState = ref.watch(adminOrderProvider);

    // Calculate stats from current order list
    final totalOrders = orderState.orders.length;
    final pendingOrders = orderState.orders.where((o) => o['status'] == 'pending').length;
    final deliveredOrders = orderState.orders.where((o) => o['status'] == 'delivered').length;
    final totalRevenue = orderState.orders.fold<double>(0, (sum, o) => sum + (o['total_amount'] as num? ?? 0).toDouble());

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(child: _buildStatCard('Total', totalOrders.toString(), Colors.blue)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Pending', pendingOrders.toString(), Colors.orange)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Delivered', deliveredOrders.toString(), Colors.green)),
          const SizedBox(width: 12),
          Expanded(child: _buildStatCard('Revenue', 'RM ${totalRevenue.toStringAsFixed(0)}', Colors.purple)),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// ORDER CARD
// ============================================================================

/// Individual order card for admin management
class AdminOrderCard extends ConsumerWidget {
  final Map<String, dynamic> order;

  const AdminOrderCard({
    super.key,
    required this.order,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final orderId = order['id'] as String;
    final orderNumber = order['order_number'] as String? ?? 'Unknown';
    final status = order['status'] as String? ?? 'pending';
    final totalAmount = (order['total_amount'] as num? ?? 0).toDouble();
    final customerName = order['customer']?['organization_name'] as String? ?? 'Unknown Customer';
    final vendorName = order['vendor']?['business_name'] as String? ?? 'Unknown Vendor';
    final createdAt = DateTime.tryParse(order['created_at'] as String? ?? '') ?? DateTime.now();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _viewOrderDetails(context, orderId),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Order Status Avatar
              CircleAvatar(
                radius: 25,
                backgroundColor: _getStatusColor(status).withValues(alpha: 0.1),
                child: Icon(
                  _getStatusIcon(status),
                  color: _getStatusColor(status),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),

              // Order Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            orderNumber,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        _buildStatusChip(status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$customerName • $vendorName',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'RM ${totalAmount.toStringAsFixed(2)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDateTime(createdAt),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              PopupMenuButton<String>(
                onSelected: (value) => _handleOrderAction(context, ref, value, order),
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'view', child: Text('View Details')),
                  const PopupMenuItem(value: 'track', child: Text('Track Order')),
                  if (_canConfirmOrder(status))
                    const PopupMenuItem(
                      value: 'confirm',
                      child: Row(
                        children: [
                          Icon(Icons.check, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Confirm'),
                        ],
                      ),
                    ),
                  if (_canCancelOrder(status))
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Row(
                        children: [
                          Icon(Icons.cancel, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Cancel'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'refund',
                    child: Row(
                      children: [
                        Icon(Icons.money_off, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('Process Refund'),
                      ],
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

  Widget _buildStatusChip(String status) {
    Color color = _getStatusColor(status);
    String label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'preparing':
        return Colors.purple;
      case 'ready':
        return Colors.green;
      case 'out_for_delivery':
        return Colors.teal;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.check_circle;
      case 'preparing':
        return Icons.restaurant;
      case 'ready':
        return Icons.done_all;
      case 'out_for_delivery':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'out_for_delivery':
        return 'Out for Delivery';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  bool _canConfirmOrder(String status) {
    return status == 'pending';
  }

  bool _canCancelOrder(String status) {
    return status == 'pending' || status == 'confirmed' || status == 'preparing';
  }

  void _viewOrderDetails(BuildContext context, String orderId) {
    context.push('/admin/orders/$orderId');
  }

  void _handleOrderAction(BuildContext context, WidgetRef ref, String action, Map<String, dynamic> order) {
    final orderId = order['id'] as String;
    final orderNumber = order['order_number'] as String;

    switch (action) {
      case 'view':
        _viewOrderDetails(context, orderId);
        break;
      case 'track':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Track $orderNumber - Coming Soon')),
        );
        break;
      case 'confirm':
        _confirmOrder(context, ref, orderId, orderNumber);
        break;
      case 'cancel':
        _cancelOrder(context, ref, orderId, orderNumber);
        break;
      case 'refund':
        _showRefundDialog(context, ref, orderId, orderNumber);
        break;
    }
  }

  void _confirmOrder(BuildContext context, WidgetRef ref, String orderId, String orderNumber) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Order $orderNumber'),
        content: const Text('Are you sure you want to confirm this order?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(adminOrderProvider.notifier).updateOrderStatus(
                  orderId,
                  'confirmed',
                  adminNotes: 'Confirmed by admin',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order $orderNumber confirmed')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error confirming order: $e')),
                  );
                }
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _cancelOrder(BuildContext context, WidgetRef ref, String orderId, String orderNumber) {
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cancel Order $orderNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Please provide a reason for cancellation:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Cancellation Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(adminOrderProvider.notifier).updateOrderStatus(
                  orderId,
                  'cancelled',
                  adminNotes: reasonController.text.isEmpty
                      ? 'Cancelled by admin'
                      : 'Cancelled by admin: ${reasonController.text}',
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Order $orderNumber cancelled')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling order: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order'),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(BuildContext context, WidgetRef ref, String orderId, String orderNumber) {
    final amountController = TextEditingController();
    final reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Process Refund for $orderNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Refund Amount (RM)',
                border: OutlineInputBorder(),
                prefixText: 'RM ',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Refund Reason',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a valid refund amount')),
                );
                return;
              }

              if (reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please provide a refund reason')),
                );
                return;
              }

              Navigator.of(context).pop();
              try {
                await ref.read(adminOrderProvider.notifier).processOrderRefund(
                  orderId,
                  amount,
                  reasonController.text,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Refund processed for $orderNumber')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error processing refund: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Process Refund'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// FILTER DIALOG
// ============================================================================

/// Filter dialog for orders
class AdminOrderFilterDialog extends ConsumerStatefulWidget {
  const AdminOrderFilterDialog({super.key});

  @override
  ConsumerState<AdminOrderFilterDialog> createState() => _AdminOrderFilterDialogState();
}

class _AdminOrderFilterDialogState extends ConsumerState<AdminOrderFilterDialog> {
  String? selectedStatus;
  String? selectedVendor;
  DateTimeRange? selectedDateRange;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Orders'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String?>(
            initialValue: selectedStatus,
            decoration: const InputDecoration(labelText: 'Status'),
            items: const [
              DropdownMenuItem(value: null, child: Text('All Statuses')),
              DropdownMenuItem(value: 'pending', child: Text('Pending')),
              DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
              DropdownMenuItem(value: 'preparing', child: Text('Preparing')),
              DropdownMenuItem(value: 'ready', child: Text('Ready')),
              DropdownMenuItem(value: 'out_for_delivery', child: Text('Out for Delivery')),
              DropdownMenuItem(value: 'delivered', child: Text('Delivered')),
              DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
            ],
            onChanged: (value) {
              setState(() {
                selectedStatus = value;
              });
            },
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedDateRange == null
                      ? 'Select Date Range'
                      : '${selectedDateRange!.start.day}/${selectedDateRange!.start.month} - ${selectedDateRange!.end.day}/${selectedDateRange!.end.month}',
                ),
              ),
              TextButton(
                onPressed: () async {
                  final range = await showDateRangePicker(
                    context: context,
                    firstDate: DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now(),
                  );
                  if (range != null) {
                    setState(() {
                      selectedDateRange = range;
                    });
                  }
                },
                child: const Text('Select'),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Apply filters
            if (selectedStatus != null) {
              ref.read(adminOrderProvider.notifier).updateStatusFilter(selectedStatus);
            }
            if (selectedDateRange != null) {
              ref.read(adminOrderProvider.notifier).updateDateRangeFilter(
                selectedDateRange!.start,
                selectedDateRange!.end,
              );
            }
            Navigator.of(context).pop();
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

// ============================================================================
// ANALYTICS TAB
// ============================================================================

/// Analytics tab for orders
class AdminOrderAnalyticsTab extends ConsumerWidget {
  const AdminOrderAnalyticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(adminOrderAnalyticsProvider({
      'startDate': DateTime.now().subtract(const Duration(days: 30)),
      'endDate': DateTime.now(),
      'limit': 30,
    }));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Analytics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          analyticsAsync.when(
            data: (analytics) => Column(
              children: [
                // Revenue Chart Placeholder
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Revenue Trend (Last 30 Days)',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Center(
                            child: Text('Revenue Chart\n(Chart implementation here)'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Analytics Summary
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...analytics.take(5).map((data) => _buildAnalyticsRow(
                          data['order_date'] as String,
                          'RM ${(data['total_revenue'] as num).toStringAsFixed(2)}',
                          '${data['total_orders']} orders',
                        )),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(
              child: Text('Error loading analytics: $error'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticsRow(String date, String revenue, String orders) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(date)),
          Text(
            revenue,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 16),
          Text(
            orders,
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
