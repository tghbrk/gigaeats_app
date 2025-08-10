import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/order.dart';
import '../../../../../presentation/providers/repository_providers.dart';
// TODO: Fix OrderStatus type conflicts
// import '../../../data/models/order_status.dart';

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  OrderStatus? _selectedStatus;
  String _selectedPeriod = 'Today';

  final List<String> _periods = ['Today', 'This Week', 'This Month', 'All Time'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔍 [ADMIN-ORDERS] build() called - Search: "$_searchQuery", Period: $_selectedPeriod');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
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
            icon: const Icon(Icons.refresh),
            onPressed: () {
              debugPrint('🔄 [ADMIN-ORDERS] Manual refresh triggered');
              ref.invalidate(platformOrdersProvider);
            },
            tooltip: 'Refresh Orders',
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter',
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
          // Search and Period Selection
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: 'Search orders...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      debugPrint('🔍 [ADMIN-ORDERS] Search query changed: "$value"');
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPeriod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _periods.map((period) => DropdownMenuItem(
                      value: period,
                      child: Text(period),
                    )).toList(),
                    onChanged: (value) {
                      debugPrint('🔍 [ADMIN-ORDERS] Period changed: "$value"');
                      setState(() {
                        _selectedPeriod = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          
          // Stats Summary
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(child: _buildStatCard('Total Orders', '3,456', Colors.blue)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Revenue', 'RM 125,450', Colors.green)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Pending', '23', Colors.orange)),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard('Cancelled', '12', Colors.red)),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOrdersTab(null), // All orders
                _buildOrdersTab(OrderStatus.pending),
                _buildActiveOrdersTab(),
                _buildOrdersTab(OrderStatus.delivered),
                _buildAnalyticsTab(),
              ],
            ),
          ),
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(OrderStatus? status) {
    debugPrint('🔍 [ADMIN-ORDERS] _buildOrdersTab called with status: $status');

    // Use real data from platformOrdersProvider instead of mock data
    final ordersAsync = ref.watch(platformOrdersProvider);

    return ordersAsync.when(
      data: (allOrders) {
        debugPrint('🔍 [ADMIN-ORDERS] Received ${allOrders.length} orders from database');

        // Apply filtering logic
        final filteredOrders = allOrders.where((order) {
          final matchesStatus = status == null || order.status == status;
          final matchesSearch = _searchQuery.isEmpty ||
              order.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              order.vendorName.toLowerCase().contains(_searchQuery.toLowerCase());
          return matchesStatus && matchesSearch;
        }).toList();

        debugPrint('🔍 [ADMIN-ORDERS] After filtering: ${filteredOrders.length} orders');
        debugPrint('🔍 [ADMIN-ORDERS] Filter - Status: $status, Search: "$_searchQuery"');

        // Log order statuses for debugging
        final statusCounts = <OrderStatus, int>{};
        for (final order in allOrders) {
          statusCounts[order.status] = (statusCounts[order.status] ?? 0) + 1;
        }
        debugPrint('🔍 [ADMIN-ORDERS] Order status breakdown: $statusCounts');

        if (filteredOrders.isEmpty) {
          return _buildEmptyOrdersState(status);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredOrders.length,
          itemBuilder: (context, index) {
            final order = filteredOrders[index];
            return _buildOrderCard(order);
          },
        );
      },
      loading: () {
        debugPrint('🔍 [ADMIN-ORDERS] Loading orders from database...');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading orders...'),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        debugPrint('❌ [ADMIN-ORDERS] Error loading orders: $error');
        debugPrint('❌ [ADMIN-ORDERS] Stack trace: $stackTrace');
        return _buildErrorState(error.toString());
      },
    );
  }

  Widget _buildActiveOrdersTab() {
    debugPrint('🔍 [ADMIN-ORDERS] _buildActiveOrdersTab called');

    // Use real data from platformOrdersProvider instead of mock data
    final ordersAsync = ref.watch(platformOrdersProvider);

    return ordersAsync.when(
      data: (allOrders) {
        debugPrint('🔍 [ADMIN-ORDERS] Active tab - Received ${allOrders.length} orders from database');

        final activeOrders = allOrders.where((order) =>
            order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.preparing ||
            order.status == OrderStatus.ready ||
            order.status == OrderStatus.outForDelivery
        ).toList();

        debugPrint('🔍 [ADMIN-ORDERS] Active tab - Found ${activeOrders.length} active orders');

        if (activeOrders.isEmpty) {
          return _buildEmptyOrdersState(null, isActiveTab: true);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeOrders.length,
          itemBuilder: (context, index) {
            final order = activeOrders[index];
            return _buildOrderCard(order);
          },
        );
      },
      loading: () {
        debugPrint('🔍 [ADMIN-ORDERS] Active tab - Loading orders...');
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading active orders...'),
            ],
          ),
        );
      },
      error: (error, stackTrace) {
        debugPrint('❌ [ADMIN-ORDERS] Active tab - Error loading orders: $error');
        return _buildErrorState(error.toString());
      },
    );
  }

  Widget _buildAnalyticsTab() {
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
          
          // Revenue Chart Placeholder
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Trend',
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
          
          // Top Vendors
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Top Performing Vendors',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildTopVendorRow('Nasi Lemak Express', 'RM 12,450', '234 orders'),
                  _buildTopVendorRow('Teh Tarik Corner', 'RM 8,920', '189 orders'),
                  _buildTopVendorRow('Roti Canai House', 'RM 7,650', '156 orders'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    debugPrint('🔍 [ADMIN-ORDERS] Building order card for: ${order.orderNumber} (${order.status.displayName})');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(order.status).withValues(alpha: 0.1),
          child: Icon(
            _getStatusIcon(order.status),
            color: _getStatusColor(order.status),
          ),
        ),
        title: Text(order.orderNumber),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${order.customerName} • ${order.vendorName}'),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStatusColor(order.status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.displayName,
                    style: TextStyle(
                      fontSize: 10,
                      color: _getStatusColor(order.status),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'RM ${order.totalAmount.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleOrderAction(value, order),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'view', child: Text('View Details')),
            const PopupMenuItem(value: 'track', child: Text('Track Order')),
            if (order.status.isPending)
              const PopupMenuItem(value: 'confirm', child: Text('Confirm')),
            if (order.status.isActive)
              const PopupMenuItem(value: 'cancel', child: Text('Cancel')),
            const PopupMenuItem(value: 'refund', child: Text('Process Refund')),
          ],
        ),
      ),
    );
  }

  Widget _buildTopVendorRow(String name, String revenue, String orders) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name)),
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

  Widget _buildEmptyOrdersState(OrderStatus? status, {bool isActiveTab = false}) {
    String title;
    String message;
    IconData icon;

    if (isActiveTab) {
      title = 'No Active Orders';
      message = 'There are no orders currently being processed.';
      icon = Icons.local_shipping_outlined;
    } else if (status == null) {
      title = 'No Orders Found';
      message = 'No orders match your current search criteria.';
      icon = Icons.receipt_long_outlined;
    } else {
      title = 'No ${status.displayName} Orders';
      message = 'There are no orders with ${status.displayName.toLowerCase()} status.';
      icon = _getStatusIcon(status);
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Refresh the orders
                ref.invalidate(platformOrdersProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Error Loading Orders',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.red[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Retry loading orders
                ref.invalidate(platformOrdersProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[600],
                foregroundColor: Colors.white,
              ),
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
        return Colors.teal;
      case OrderStatus.delivered:
        return Colors.green;
      case OrderStatus.cancelled:
        return Colors.red;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.pending_actions;
      case OrderStatus.confirmed:
        return Icons.check_circle;
      case OrderStatus.preparing:
        return Icons.restaurant;
      case OrderStatus.ready:
        return Icons.done_all;
      case OrderStatus.outForDelivery:
        return Icons.local_shipping;
      case OrderStatus.delivered:
        return Icons.check_circle_outline;
      case OrderStatus.cancelled:
        return Icons.cancel;
    }
  }

  void _showFilterDialog() {
    debugPrint('🔍 [ADMIN-ORDERS] Filter dialog opened');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Orders'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<OrderStatus?>(
              value: _selectedStatus,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                const DropdownMenuItem(value: null, child: Text('All Statuses')),
                ...OrderStatus.values.map((status) => DropdownMenuItem(
                  value: status,
                  child: Text(status.displayName),
                )),
              ],
              onChanged: (value) {
                debugPrint('🔍 [ADMIN-ORDERS] Filter status changed: $value');
                setState(() {
                  _selectedStatus = value;
                });
              },
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
              debugPrint('🔍 [ADMIN-ORDERS] Filter applied - Status: $_selectedStatus');
              Navigator.of(context).pop();
              setState(() {}); // Refresh the list
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _exportOrders() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting orders...')),
    );
  }

  void _handleOrderAction(String action, Order order) {
    debugPrint('🔍 [ADMIN-ORDERS] Order action triggered: $action for ${order.orderNumber}');

    String message;
    switch (action) {
      case 'view':
        message = 'View details for ${order.orderNumber}';
        break;
      case 'track':
        message = 'Track ${order.orderNumber}';
        break;
      case 'confirm':
        message = 'Confirmed ${order.orderNumber}';
        break;
      case 'cancel':
        message = 'Cancelled ${order.orderNumber}';
        break;
      case 'refund':
        message = 'Processing refund for ${order.orderNumber}';
        break;
      default:
        message = 'Unknown action';
    }

    debugPrint('🔍 [ADMIN-ORDERS] Action result: $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
