Of course. Based on your screenshots and the provided codebase, I've analyzed the issues and prepared a comprehensive plan to resolve them. Here is a detailed breakdown of the necessary changes.

### Plan of Action

This plan addresses the UI/UX inconsistencies and backend integration gaps identified in the screenshots. The implementation will be broken down by the affected user role or screen:

1.  **Vendor-Facing Fixes**: Correcting the order details screen, cleaning up the upcoming orders view, and refining the vendor dashboard UI.
2.  **Sales Agent Fixes**: Updating the sales agent dashboard and profile screen for a cleaner, more functional interface, and fixing the vendor details tab bar color.
3.  **Driver-Facing Fixes**: Implementing backend data for the driver profile's performance section and fixing the logic for displaying available orders.

I will now provide the complete code changes for each file that needs to be modified to implement these fixes.

---

### 1. Vendor-Facing Fixes

#### 1.1. Vendor Order Details Screen (`vendor_order_details_screen.dart`)

**Goal:**
-   Remove the incorrect "Mark as Delivered" action button for vendors.
-   Display accurate delivery/pickup information based on the order's delivery method.

**Rationale:**
As the error message in the screenshot correctly states, vendors should not be able to mark an order as delivered. That action is reserved for the driver or sales agent completing the delivery. Additionally, the delivery information section needs to be more descriptive to reflect whether it's a delivery or a pickup.

**File:** `lib/features/orders/presentation/screens/vendor_order_details_screen.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/order.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../vendors/presentation/widgets/assign_driver_dialog.dart';
import '../utils/order_status_update_helper.dart';

class VendorOrderDetailsScreen extends ConsumerStatefulWidget {
  final String orderId;

  const VendorOrderDetailsScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<VendorOrderDetailsScreen> createState() => _VendorOrderDetailsScreenState();
}

class _VendorOrderDetailsScreenState extends ConsumerState<VendorOrderDetailsScreen> {
  Order? _order;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final orderRepository = ref.read(orderRepositoryProvider);
      final order = await orderRepository.getOrderById(widget.orderId);
      
      if (mounted) {
        setState(() {
          _order = order;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load order details: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order != null ? 'Order #${_order!.orderNumber}' : 'Order Details'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _loadOrderDetails,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading order details...')
          : _errorMessage != null
              ? CustomErrorWidget(
                  message: _errorMessage!,
                  onRetry: _loadOrderDetails,
                )
              : _order == null
                  ? _buildOrderNotFound()
                  : RefreshIndicator(
                      onRefresh: _loadOrderDetails,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Order Status Header
                            _buildStatusHeader(_order!),

                            const SizedBox(height: 24),

                            // Customer Information
                            _buildCustomerInfo(_order!),

                            const SizedBox(height: 24),

                            // Order Items
                            _buildOrderItems(_order!),

                            const SizedBox(height: 24),

                            // Order Summary
                            _buildOrderSummary(_order!),

                            const SizedBox(height: 24),

                            // Delivery Information
                            _buildDeliveryInfo(_order!),

                            const SizedBox(height: 24),

                            // Vendor Actions
                            _buildVendorActions(_order!),

                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
    );
  }

  Widget _buildOrderNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Order Not Found',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'The order you are looking for could not be found.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusHeader(Order order) {
    final theme = Theme.of(context);
    final statusColor = _getStatusColor(order.status);

    return Card(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              statusColor.withOpacity(0.1),
              statusColor.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            Icon(
              _getStatusIcon(order.status),
              size: 60,
              color: statusColor,
            ),
            const SizedBox(height: 12),
            Text(
              order.status.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getVendorStatusDescription(order.status),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Order Date: ${_formatMalaysianDateTime(order.createdAt)}',
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerInfo(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customer Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildDetailRow('Customer Name', order.customerName),
            if (order.contactPhone != null)
              _buildDetailRow('Contact Phone', order.contactPhone!),
            _buildDetailRow('Order Number', '#${order.orderNumber}'),
            _buildDetailRow('Order Date', _formatMalaysianDateTime(order.createdAt)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItems(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Items (${order.items.length})',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            ...order.items.map((item) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.2),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        'RM ${item.totalPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Quantity: ${item.quantity}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Unit Price: RM ${item.unitPrice.toStringAsFixed(2)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                  // Add customizations display
                  if (item.customizations != null && item.customizations!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Customizations: ${_formatCustomizations(item.customizations!)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  if (item.notes != null && item.notes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Note: ${item.notes}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(Order order) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildSummaryRow('Subtotal', 'RM ${order.subtotal.toStringAsFixed(2)}'),
            _buildSummaryRow('Delivery Fee', 'RM ${order.deliveryFee.toStringAsFixed(2)}'),
            _buildSummaryRow('SST (6%)', 'RM ${order.sstAmount.toStringAsFixed(2)}'),
            const Divider(height: 24),
            _buildSummaryRow(
              'Total Amount',
              'RM ${order.totalAmount.toStringAsFixed(2)}',
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliveryInfo(Order order) {
    final theme = Theme.of(context);
    final isPickup = order.isPickupOrder;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Information',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            _buildDetailRow('Delivery Type', order.deliveryMethod.displayName),
            _buildDetailRow('Delivery Date', _formatMalaysianDate(order.deliveryDate)),

            if (!isPickup) ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.location_on,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Address',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.deliveryAddress.fullAddress,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.store,
                    color: theme.colorScheme.primary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pickup Location',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.vendorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],

            if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty)
              _buildSpecialInstructionsSection(order, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorActions(Order order) {
    final theme = Theme.of(context);
    final availableActions = OrderStatusUpdateHelper.getAvailableActions(order, 'vendor');

    if (availableActions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...availableActions.map((action) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _updateOrderStatus(order, action.status),
                  icon: Icon(action.icon),
                  label: Text(action.label),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: action.color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w600,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialInstructionsSection(Order order, ThemeData theme) {
    return Column(
      children: [
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.note,
              color: theme.colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Special Instructions',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    order.specialInstructions!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _updateOrderStatus(Order order, OrderStatus newStatus) async {
    final success = await OrderStatusUpdateHelper.updateOrderStatus(
      context,
      ref,
      order: order,
      newStatus: newStatus,
      onSuccess: () => _loadOrderDetails(),
    );

    if (!success && mounted) {
      // The helper already shows the dialog, so we just log it here
      debugPrint('Failed to update order status for order ${order.orderNumber}');
    }
  }

  Color _getStatusColor(OrderStatus status) {
    return OrderStatusUpdateHelper.getAvailableActions(const Order(id: '', orderNumber: '', status: OrderStatus.pending, items: [], vendorId: '', vendorName: '', customerId: '', customerName: '', deliveryDate: DateTime.now(), deliveryAddress: Address(street: '', city: '', state: '', postalCode: '', country: ''), subtotal: 0, deliveryFee: 0, sstAmount: 0, totalAmount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()), 'admin')
        .firstWhere((action) => action.status == status, orElse: () => const OrderStatusAction(status: OrderStatus.pending, label: '', icon: Icons.help, color: Colors.grey))
        .color;
  }

  IconData _getStatusIcon(OrderStatus status) {
    return OrderStatusUpdateHelper.getAvailableActions(const Order(id: '', orderNumber: '', status: OrderStatus.pending, items: [], vendorId: '', vendorName: '', customerId: '', customerName: '', deliveryDate: DateTime.now(), deliveryAddress: Address(street: '', city: '', state: '', postalCode: '', country: ''), subtotal: 0, deliveryFee: 0, sstAmount: 0, totalAmount: 0, createdAt: DateTime.now(), updatedAt: DateTime.now()), 'admin')
        .firstWhere((action) => action.status == status, orElse: () => const OrderStatusAction(status: OrderStatus.pending, label: '', icon: Icons.help, color: Colors.grey))
        .icon;
  }

  String _getVendorStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'New order waiting for your confirmation';
      case OrderStatus.confirmed:
        return 'Order confirmed - ready to start preparation';
      case OrderStatus.preparing:
        return 'Order is being prepared in your kitchen';
      case OrderStatus.ready:
        return 'Order is ready for pickup or delivery';
      case OrderStatus.outForDelivery:
        return 'Order is out for delivery';
      case OrderStatus.delivered:
        return 'Order has been successfully delivered';
      case OrderStatus.cancelled:
        return 'This order has been cancelled';
    }
  }

  String _formatMalaysianDateTime(DateTime dateTime) {
    final malaysianTime = dateTime.toLocal();
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    return formatter.format(malaysianTime);
  }

  String _formatMalaysianDate(DateTime dateTime) {
    final malaysianTime = dateTime.toLocal();
    final formatter = DateFormat('dd/MM/yyyy');
    return formatter.format(malaysianTime);
  }

  String _formatCustomizations(Map<String, dynamic> customizations) {
    final parts = <String>[];
    customizations.forEach((key, value) {
      if (value is Map && value.containsKey('name')) {
        parts.add(value['name']);
      } else if (value is List) {
        for (var option in value) {
          if (option is Map && option.containsKey('name')) {
            parts.add(option['name']);
          }
        }
      }
    });
    return parts.join(', ');
  }
}

```

#### 1.2. Vendor Upcoming Orders Screen (`vendor_orders_screen.dart`)

**Goal:**
-   Remove test orders from the "Upcoming" tab to only show real, actionable orders.

**Rationale:**
The screenshot shows test orders cluttering the UI, which can confuse vendors. Filtering these out at the data source level ensures a clean and professional interface.

**File:** `lib/features/orders/data/repositories/order_repository.dart`

```dart
// ... inside class OrderRepository ...

  /// Get orders stream for real-time updates
  Stream<List<Order>> getOrdersStream({
    OrderStatus? status,
    String? vendorId,
    String? customerId,
  }) {
    // ... (existing code) ...

    return executeStreamQuery(() async* {
      // ... (existing code) ...

      // Apply role-based filtering
      switch (currentUser['role']) {
        // ... (existing code) ...
      }

      // ADD THIS: Filter out test orders
      initialQuery = initialQuery.not('order_number', 'ilike', 'TEST-%');
      initialQuery = initialQuery.not('order_number', 'ilike', 'FINAL-TEST-%');

      // Apply additional filters
      if (status != null) {
        initialQuery = initialQuery.eq('status', status.value);
      }
      // ... (rest of the method) ...
    });
  }
// ...
```

#### 1.3. Vendor Dashboard Screen (`vendor_dashboard.dart`)

**Goal:**
-   Remove non-functional "Settings" and "Developer Tools" icons.
-   Enable the notification icon to navigate to the notifications screen.

**Rationale:**
The dashboard's app bar should only contain relevant and functional actions for the vendor. The notification icon should be a primary way for vendors to access important updates.

**File:** `lib/features/vendors/presentation/screens/vendor_dashboard.dart`

```dart
// ... inside _VendorDashboardTab class ...
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Dashboard'),
        actions: [
          Consumer(
            builder: (context, ref, child) {
              final notificationsAsync = ref.watch(vendorNotificationsProvider(true)); // unread only

              return notificationsAsync.when(
                data: (notifications) {
                  final unreadCount = notifications.length;
                  return IconButton(
                    icon: unreadCount > 0
                      ? Badge(
                          label: Text(unreadCount > 99 ? '99+' : unreadCount.toString()),
                          child: const Icon(Icons.notifications_outlined),
                        )
                      : const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      // NAVIGATE to the notifications screen
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const NotificationsScreen(),
                        ),
                      );
                    },
                    tooltip: 'Notifications',
                  );
                },
                loading: () => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                error: (_, __) => IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                     Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // REMOVED developer tools and settings icons
        ],
      ),
      // ... rest of the build method
    );
  }
// ...
```

### 2. Sales Agent Fixes

#### 2.1. Sales Agent Profile Screen (`sales_agent_profile_screen.dart`)

**Goal:**
-   Add a "Sign Out" button to the profile screen.

**Rationale:**
Users need a clear and accessible way to sign out of their account, and the profile screen is the conventional location for this action.

**File:** `lib/features/sales_agent/presentation/screens/sales_agent_profile_screen.dart`

```dart
// ... inside _buildSettingsSection ...
  Widget _buildSettingsSection(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... existing settings ListTiles
            
            const Divider(), // ADDED divider
            
            // ADDED Logout button
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              subtitle: const Text('Sign out of your account'),
              onTap: () => _showSignOutDialog(context),
            ),
          ],
        ),
      ),
    );
  }

  // ADDED this method
  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              await AuthUtils.logout(context, ref);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
// ...
```

#### 2.2. Sales Agent Dashboard Screen (`sales_agent_dashboard.dart`)

**Goal:**
-   Remove non-functional "Settings" and test icons.
-   Enable the notification icon functionality.

**Rationale:**
Similar to the vendor dashboard, this cleans up the UI and makes the notification system functional for sales agents.

**File:** `lib/features/sales_agent/presentation/screens/sales_agent_dashboard.dart`

```dart
// ... inside _DashboardTab class ...
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              // NAVIGATE to notifications screen
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
            tooltip: 'Notifications',
          ),
          // REMOVED test and settings icons
        ],
      ),
      // ... rest of build method
    );
  }
// ...
```

#### 2.3. Vendor Details Screen (`vendor_details_screen.dart`)

**Goal:**
-   Fix the tab text color to ensure it's visible against the background.

**Rationale:**
The text color for the tabs was the same as the app bar background, making it unreadable. This fix ensures proper contrast and usability.

**File:** `lib/features/sales_agent/presentation/screens/vendor_details_screen.dart`

```dart
// ... inside _buildVendorDetails ...
        // Tab Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            TabBar(
              controller: _tabController,
              // ADDED these properties for proper color
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.7),
              indicatorColor: theme.colorScheme.primary,
              // END ADDED properties
              tabs: const [
                Tab(text: 'Menu'),
                Tab(text: 'Info'),
              ],
            ),
          ),
        ),
// ...
```

### 3. Driver-Facing Fixes

#### 3.1. Driver Orders Screen (`driver_orders_screen.dart`)

**Goal:**
-   Correctly load "ready" orders in the "Available" tab.
-   Prevent available orders from showing if the driver already has an active delivery.

**Rationale:**
The "Available" tab was not functioning as intended. It should only show new, unassigned jobs to drivers who are free to accept them.

**File:** `lib/features/drivers/data/repositories/driver_order_repository.dart`
*This change ensures the query fetches the correct orders.*
```dart
// ... inside class DriverOrderRepository ...

  /// Get available orders for driver assignment
  Future<List<DriverOrder>> getAvailableOrders() async {
    return executeQuery(() async {
      debugPrint('DriverOrderRepository: Getting available orders');
      
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            order_number,
            vendor_name,
            vendor_address,
            customer_name,
            delivery_address,
            customer_phone,
            total_amount,
            delivery_fee,
            status,
            estimated_delivery_time,
            special_instructions,
            created_at
          ''')
          .eq('status', 'ready') // CORRECTED: Was missing this filter
          .is_('assigned_driver_id', null) // CORRECTED: Use is_ for null check
          .order('created_at', ascending: true);

      debugPrint('DriverOrderRepository: Found ${response.length} available orders');
      
      return response.map((order) => DriverOrder.fromJson({
        ...order,
        'status': 'available',
      })).toList();
    });
  }
// ...
```

**File:** `lib/features/drivers/presentation/screens/driver_orders_screen.dart`
*This change implements the business logic in the UI.*
```dart
// ... inside _DriverOrdersScreenState ...
  Widget _buildAvailableOrdersTab() {
    final activeOrders = ref.watch(activeDriverOrdersProvider);
    final availableOrdersAsync = ref.watch(availableOrdersProvider);

    // ADDED: Logic to check for active orders first
    if (activeOrders.isNotEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.delivery_dining, size: 64, color: Colors.blue),
              SizedBox(height: 16),
              Text(
                'You have an active delivery.',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Please complete your current delivery to see new available orders.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }
    // END ADDED

    return availableOrdersAsync.when(
      data: (orders) => _buildOrdersList(orders, isAvailable: true),
      loading: () => const LoadingWidget(),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load available orders: $error',
        onRetry: () => ref.invalidate(availableOrdersProvider),
      ),
    );
  }
// ...
```

#### 3.2. Driver Profile Screen (`driver_profile_screen.dart`)

**Goal:**
-   Replace mock performance stats with real data from the backend.

**Rationale:**
The performance section was static. This change integrates it with the `driverPerformanceSummaryProvider` to show live, accurate metrics to the driver.

**File:** `lib/features/drivers/presentation/screens/driver_profile_screen.dart`

```dart
// ... inside _DriverProfileScreenState ...
  Widget _buildPerformanceSection(ThemeData theme) {
    // ADDED: Consumer to watch the provider
    return Consumer(
      builder: (context, ref, child) {
        final performanceAsync = ref.watch(driverPerformanceSummaryProvider);

        return _buildSection(
          theme,
          title: 'Performance Stats',
          children: [
            performanceAsync.when(
              data: (summary) {
                if (summary == null) {
                  return const Text('No performance data available.');
                }
                return Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        title: 'Total Deliveries',
                        value: (summary['total_deliveries'] ?? 0).toString(),
                        icon: Icons.local_shipping,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        theme,
                        title: 'Rating',
                        value: (summary['average_rating'] ?? 0.0).toStringAsFixed(1),
                        icon: Icons.star,
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => const Text('Could not load stats.'),
            ),
          ],
        );
      },
    );
  }
//...
```

**File:** `lib/features/drivers/presentation/providers/driver_earnings_provider.dart`
*A new provider is needed to supply the data.*
```dart
// ... inside file ...

/// Provider for driver performance summary
final driverPerformanceSummaryProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final earningsService = ref.read(driverEarningsServiceProvider);
  final driverId = await ref.watch(currentDriverIdProvider.future);

  if (driverId == null) {
    return null;
  }
  // This reuses the existing earnings summary logic which is sufficient for this card
  return await earningsService.getDriverEarningsSummary(driverId);
});
// ...
```

---

### Conclusion

Executing this plan will resolve all the identified issues from the screenshots. The application will be more robust, user-friendly, and aligned with the intended business logic for all user roles. The changes involve both UI refinements and crucial backend integration fixes, leading to a more professional and functional product.