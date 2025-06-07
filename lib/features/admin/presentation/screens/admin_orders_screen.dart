import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../orders/data/models/order.dart';

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
    final orders = _getSampleOrders().where((order) {
      final matchesStatus = status == null || order.status == status;
      final matchesSearch = _searchQuery.isEmpty ||
          order.orderNumber.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.customerName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          order.vendorName.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesStatus && matchesSearch;
    }).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildActiveOrdersTab() {
    final activeOrders = _getSampleOrders().where((order) => 
        order.status == OrderStatus.confirmed ||
        order.status == OrderStatus.preparing ||
        order.status == OrderStatus.ready ||
        order.status == OrderStatus.outForDelivery
    ).toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeOrders.length,
      itemBuilder: (context, index) {
        final order = activeOrders[index];
        return _buildOrderCard(order);
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

  List<Order> _getSampleOrders() {
    final sampleAddress = Address(
      street: '123 Jalan Bukit Bintang',
      city: 'Kuala Lumpur',
      state: 'Selangor',
      postalCode: '50200',
      country: 'Malaysia',
    );

    final sampleItem = OrderItem(
      id: '1',
      menuItemId: '1',
      name: 'Nasi Lemak Special',
      description: 'Traditional Malaysian dish with coconut rice',
      quantity: 2,
      unitPrice: 12.50,
      totalPrice: 25.00,
      notes: 'Extra sambal',
    );

    return [
      Order(
        id: '1',
        orderNumber: 'ORD-001',
        status: OrderStatus.pending,
        items: [sampleItem],
        vendorId: '1',
        vendorName: 'Nasi Lemak Express',
        customerId: '1',
        customerName: 'ABC Company',
        salesAgentId: '1',
        salesAgentName: 'John Doe',
        deliveryDate: DateTime.now().add(const Duration(hours: 2)),
        deliveryAddress: sampleAddress,
        subtotal: 25.00,
        deliveryFee: 5.00,
        sstAmount: 1.80,
        totalAmount: 31.80,
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        updatedAt: DateTime.now(),
      ),
      Order(
        id: '2',
        orderNumber: 'ORD-002',
        status: OrderStatus.confirmed,
        items: [sampleItem],
        vendorId: '2',
        vendorName: 'Teh Tarik Corner',
        customerId: '2',
        customerName: 'XYZ Corporation',
        salesAgentId: '2',
        salesAgentName: 'Jane Smith',
        deliveryDate: DateTime.now().add(const Duration(hours: 1)),
        deliveryAddress: sampleAddress,
        subtotal: 45.00,
        deliveryFee: 8.00,
        sstAmount: 3.18,
        totalAmount: 56.18,
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        updatedAt: DateTime.now(),
      ),
      Order(
        id: '3',
        orderNumber: 'ORD-003',
        status: OrderStatus.delivered,
        items: [sampleItem],
        vendorId: '3',
        vendorName: 'Roti Canai House',
        customerId: '3',
        customerName: 'DEF Enterprise',
        salesAgentId: '1',
        salesAgentName: 'John Doe',
        deliveryDate: DateTime.now().subtract(const Duration(hours: 2)),
        deliveryAddress: sampleAddress,
        subtotal: 35.00,
        deliveryFee: 6.00,
        sstAmount: 2.46,
        totalAmount: 43.46,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        updatedAt: DateTime.now(),
      ),
      Order(
        id: '4',
        orderNumber: 'ORD-004',
        status: OrderStatus.cancelled,
        items: [sampleItem],
        vendorId: '1',
        vendorName: 'Nasi Lemak Express',
        customerId: '4',
        customerName: 'GHI Limited',
        salesAgentId: '2',
        salesAgentName: 'Jane Smith',
        deliveryDate: DateTime.now().add(const Duration(hours: 3)),
        deliveryAddress: sampleAddress,
        subtotal: 28.00,
        deliveryFee: 5.00,
        sstAmount: 1.98,
        totalAmount: 34.98,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        updatedAt: DateTime.now(),
      ),
    ];
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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
