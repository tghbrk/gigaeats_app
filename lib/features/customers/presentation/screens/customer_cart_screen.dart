import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_cart_provider.dart';
import '../providers/customer_profile_provider.dart';
import '../widgets/schedule_time_picker.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../features/sales_agent/presentation/providers/cart_provider.dart';

class CustomerCartScreen extends ConsumerStatefulWidget {
  const CustomerCartScreen({super.key});

  @override
  ConsumerState<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends ConsumerState<CustomerCartScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-populate address when cart screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPopulateAddressIfNeeded();
    });
  }

  void _autoPopulateAddressIfNeeded() {
    final cart = ref.read(customerCartProvider);
    final profile = ref.read(currentCustomerProfileProvider);

    if (shouldAutoPopulateAddress(cart, profile)) {
      if (profile != null) {
        ref.read(customerCartProvider.notifier).autoPopulateAddress(profile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(customerCartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cart'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          if (cartState.items.isNotEmpty)
            TextButton(
              onPressed: () => _showClearCartDialog(),
              child: Text(
                'Clear',
                style: TextStyle(color: theme.colorScheme.onPrimary),
              ),
            ),
        ],
      ),
      body: cartState.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildCartItems(cartState.items),
                        const SizedBox(height: 24),
                        _buildDeliverySection(cartState),
                        const SizedBox(height: 24),
                        _buildOrderSummary(cartState),
                      ],
                    ),
                  ),
                ),
                _buildCheckoutSection(cartState),
              ],
            ),
      bottomNavigationBar: _buildBottomNavigation(context),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Your cart is empty',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add items from restaurants to get started',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Browse Restaurants',
              onPressed: () => context.push('/customer/restaurants'),
              type: ButtonType.primary,
              icon: Icons.restaurant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCartItems(List<CartItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Order Items',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        ...items.map((item) => _buildCartItemCard(item)),
      ],
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item image placeholder
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.fastfood,
                    color: Colors.grey[400],
                  ),
                ),
                
                const SizedBox(width: 12),
                
                // Item details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.vendorName,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      if (item.customizations?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        _buildCustomizations(item.customizations!),
                      ],
                      if (item.notes?.isNotEmpty == true) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Note: ${item.notes}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Price and quantity controls
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RM ${item.totalPrice.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildQuantityControls(item),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizations(Map<String, dynamic> customizations) {
    final theme = Theme.of(context);
    final customizationText = _formatCustomizations(customizations);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        customizationText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.grey[700],
        ),
      ),
    );
  }

  String _formatCustomizations(Map<String, dynamic> customizations) {
    final parts = <String>[];

    customizations.forEach((customizationId, selectedValue) {
      if (selectedValue is String && selectedValue.isNotEmpty) {
        // Single selection - we need to find the option name
        // For now, we'll just show the ID, but in a real implementation
        // you'd look up the option name from the product's customizations
        parts.add(selectedValue);
      } else if (selectedValue is List && selectedValue.isNotEmpty) {
        // Multiple selections
        for (final optionId in selectedValue) {
          if (optionId is String && optionId.isNotEmpty) {
            parts.add(optionId);
          }
        }
      }
    });

    return parts.isNotEmpty ? parts.join(', ') : 'No customizations';
  }

  Widget _buildQuantityControls(CartItem item) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: item.quantity > 1
              ? () => ref.read(customerCartProvider.notifier).updateItemQuantity(item.id, item.quantity - 1)
              : () => ref.read(customerCartProvider.notifier).removeItem(item.id),
          icon: Icon(
            item.quantity > 1 ? Icons.remove : Icons.delete,
            size: 20,
          ),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey[300]!),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            '${item.quantity}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        IconButton(
          onPressed: () => ref.read(customerCartProvider.notifier).updateItemQuantity(item.id, item.quantity + 1),
          icon: const Icon(Icons.add, size: 20),
          constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          padding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildDeliverySection(CustomerCartState cartState) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Delivery Details',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        // Delivery method selection
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Delivery Method',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...CustomerDeliveryMethod.values.map((method) => RadioListTile<CustomerDeliveryMethod>(
                  title: Text(method.displayName),
                  subtitle: Text(method.description),
                  value: method,
                  groupValue: cartState.deliveryMethod,
                  onChanged: (value) {
                    if (value != null) {
                      ref.read(customerCartProvider.notifier).setDeliveryMethod(value);
                    }
                  },
                  contentPadding: EdgeInsets.zero,
                )),
              ],
            ),
          ),
        ),
        
        // Address selection (if delivery)
        if (cartState.deliveryMethod != CustomerDeliveryMethod.pickup) ...[
          const SizedBox(height: 16),
          Card(
            child: InkWell(
              onTap: () => context.push('/customer/addresses/select'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      color: theme.colorScheme.primary,
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
                            cartState.selectedAddress?.fullAddress ?? 'Select delivery address',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: cartState.selectedAddress != null 
                                  ? Colors.grey[700] 
                                  : theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],

        // Schedule time selection (if scheduled delivery)
        if (cartState.deliveryMethod == CustomerDeliveryMethod.scheduled) ...[
          const SizedBox(height: 16),
          Card(
            elevation: cartState.scheduledDeliveryTime == null ? 4 : 1,
            color: cartState.scheduledDeliveryTime == null
                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.1)
                : null,
            child: InkWell(
              onTap: () => _showScheduleTimePicker(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: cartState.scheduledDeliveryTime == null
                              ? theme.colorScheme.error
                              : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scheduled Time',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                cartState.scheduledDeliveryTime != null
                                    ? _formatScheduledTime(cartState.scheduledDeliveryTime!)
                                    : 'Tap to select delivery time',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: cartState.scheduledDeliveryTime != null
                                      ? Colors.grey[700]
                                      : theme.colorScheme.error,
                                  fontWeight: cartState.scheduledDeliveryTime == null
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: cartState.scheduledDeliveryTime == null
                              ? theme.colorScheme.error
                              : Colors.grey[400],
                        ),
                      ],
                    ),
                    if (cartState.scheduledDeliveryTime == null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: theme.colorScheme.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please select a delivery time to continue',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildOrderSummary(CustomerCartState cartState) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildSummaryRow('Subtotal', cartState.subtotal),
            _buildSummaryRow('SST (6%)', cartState.sstAmount),
            _buildSummaryRow('Delivery Fee', cartState.deliveryFee),
            const Divider(),
            _buildSummaryRow(
              'Total',
              cartState.totalAmount,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isTotal = false}) {
    final theme = Theme.of(context);
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            'RM ${amount.toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? theme.colorScheme.primary : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(CustomerCartState cartState) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show validation message if checkout is disabled
            if (!cartState.canCheckout && !cartState.isEmpty) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _getCheckoutValidationMessage(cartState),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            CustomButton(
              text: 'Proceed to Checkout (RM ${cartState.totalAmount.toStringAsFixed(2)})',
              onPressed: cartState.canCheckout
                  ? () => context.push('/customer/checkout')
                  : null,
              type: ButtonType.primary,
              isLoading: cartState.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Are you sure you want to remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(customerCartProvider.notifier).clearCart();
              Navigator.pop(context);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: 2, // Cart is selected
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/customer/dashboard');
            break;
          case 1:
            context.push('/customer/restaurants');
            break;
          case 2:
            // Already on cart
            break;
          case 3:
            context.push('/customer/orders');
            break;
          case 4:
            context.push('/customer/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Restaurants',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  void _showScheduleTimePicker() {
    showDialog(
      context: context,
      builder: (context) => ScheduleTimePicker(
        initialDateTime: ref.read(customerCartProvider).scheduledDeliveryTime,
        vendor: null, // TODO: Get current vendor from cart
        onDateTimeSelected: (dateTime) {
          ref.read(customerCartProvider.notifier).setScheduledDeliveryTime(dateTime);
        },
      ),
    );
  }

  String _formatScheduledTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

    final timeString = TimeOfDay.fromDateTime(dateTime).format(context);

    if (scheduledDay == today) {
      return 'Today, $timeString';
    } else if (scheduledDay == tomorrow) {
      return 'Tomorrow, $timeString';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final dateString = '${dateTime.day} ${months[dateTime.month - 1]}';
      return '$dateString, $timeString';
    }
  }

  String _getCheckoutValidationMessage(CustomerCartState cartState) {
    if (cartState.isEmpty) {
      return 'Your cart is empty';
    }

    if (cartState.deliveryMethod != CustomerDeliveryMethod.pickup && cartState.selectedAddress == null) {
      return 'Please select a delivery address';
    }

    if (cartState.deliveryMethod == CustomerDeliveryMethod.scheduled && cartState.scheduledDeliveryTime == null) {
      return 'Please select a scheduled delivery time';
    }

    return 'Please complete all required fields';
  }
}
