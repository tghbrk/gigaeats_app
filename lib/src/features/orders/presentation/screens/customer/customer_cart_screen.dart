import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Import CartItem from the cart provider
import '../../providers/cart_provider.dart' show CartItem;
import '../../providers/customer/customer_cart_provider.dart';
import '../../../data/models/customer_delivery_method.dart';
import '../../../../user_management/presentation/providers/customer_address_provider.dart' as address_provider;

import '../../widgets/customer/schedule_time_picker.dart';
import '../../widgets/customer/scheduled_delivery_display.dart';
import '../../../../shared/widgets/custom_button.dart';

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
      _initializeAddressesAndAutoPopulate();
    });
  }

  Future<void> _initializeAddressesAndAutoPopulate() async {
    try {
      debugPrint('🔄 [CART-SCREEN] Starting address initialization for cold start');

      // First, ensure addresses are loaded
      final addressesState = ref.read(address_provider.customerAddressesProvider);
      debugPrint('🔍 [CART-SCREEN] Current address state: ${addressesState.addresses.length} addresses, loading: ${addressesState.isLoading}');

      if (addressesState.addresses.isEmpty && !addressesState.isLoading) {
        debugPrint('🔄 [CART-SCREEN] Loading addresses before auto-population');
        await ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();

        // Wait for the loading to complete
        await Future.delayed(const Duration(milliseconds: 500));

        // Check the state again after loading
        final updatedState = ref.read(address_provider.customerAddressesProvider);
        debugPrint('🔍 [CART-SCREEN] After loading: ${updatedState.addresses.length} addresses');
      }

      // Now try auto-population with the loaded addresses
      _autoPopulateAddressIfNeeded();
    } catch (e) {
      debugPrint('❌ [CART-SCREEN] Error initializing addresses: $e');
    }
  }

  void _autoPopulateAddressIfNeeded() {
    debugPrint('🔄 [CART-SCREEN] ===== AUTO-POPULATE ADDRESS START =====');

    final cart = ref.read(customerCartProvider);
    debugPrint('🔍 [CART-SCREEN] Current cart state before auto-populate:');
    debugPrint('🔍 [CART-SCREEN] - Has address: ${cart.selectedAddress != null}');
    debugPrint('🔍 [CART-SCREEN] - Current address: ${cart.selectedAddress?.label ?? 'null'}');
    debugPrint('🔍 [CART-SCREEN] - Delivery method: ${cart.deliveryMethod.name}');
    debugPrint('🔍 [CART-SCREEN] - Requires driver: ${cart.deliveryMethod.requiresDriver}');
    debugPrint('🔍 [CART-SCREEN] - Cart items count: ${cart.items.length}');

    // If cart already has an address, don't auto-populate
    if (cart.selectedAddress != null) {
      debugPrint('✅ [CART-SCREEN] Cart already has address: ${cart.selectedAddress!.label}');
      debugPrint('🔄 [CART-SCREEN] ===== AUTO-POPULATE ADDRESS END (ALREADY HAS ADDRESS) =====');
      return;
    }

    // If delivery method doesn't require driver, no address needed
    if (!cart.deliveryMethod.requiresDriver) {
      debugPrint('ℹ️ [CART-SCREEN] Delivery method does not require address');
      debugPrint('🔄 [CART-SCREEN] ===== AUTO-POPULATE ADDRESS END (NO ADDRESS REQUIRED) =====');
      return;
    }

    // Load addresses and auto-select default
    final addressesState = ref.read(address_provider.customerAddressesProvider);
    debugPrint('🔍 [CART-SCREEN] Address provider state:');
    debugPrint('🔍 [CART-SCREEN] - Addresses count: ${addressesState.addresses.length}');
    debugPrint('🔍 [CART-SCREEN] - Is loading: ${addressesState.isLoading}');
    debugPrint('🔍 [CART-SCREEN] - Has error: ${addressesState.error != null}');
    debugPrint('🔍 [CART-SCREEN] - Error: ${addressesState.error ?? 'none'}');

    if (addressesState.addresses.isNotEmpty) {
      // Log all available addresses with full details
      debugPrint('🔍 [CART-SCREEN] Available addresses:');
      for (int i = 0; i < addressesState.addresses.length; i++) {
        final addr = addressesState.addresses[i];
        debugPrint('🔍 [CART-SCREEN] Address $i:');
        debugPrint('🔍 [CART-SCREEN]   - ID: ${addr.id}');
        debugPrint('🔍 [CART-SCREEN]   - Label: ${addr.label}');
        debugPrint('🔍 [CART-SCREEN]   - Address Line 1: ${addr.addressLine1}');
        debugPrint('🔍 [CART-SCREEN]   - City: ${addr.city}');
        debugPrint('🔍 [CART-SCREEN]   - Is Default: ${addr.isDefault}');
      }

      final defaultAddress = addressesState.addresses
          .where((addr) => addr.isDefault)
          .firstOrNull;

      if (defaultAddress != null) {
        debugPrint('✅ [CART-SCREEN] Found default address: ${defaultAddress.label}');
        debugPrint('🔍 [CART-SCREEN] Default address details:');
        debugPrint('🔍 [CART-SCREEN]   - ID: ${defaultAddress.id}');
        debugPrint('🔍 [CART-SCREEN]   - Label: ${defaultAddress.label}');
        debugPrint('🔍 [CART-SCREEN]   - Address Line 1: ${defaultAddress.addressLine1}');
        debugPrint('🔍 [CART-SCREEN]   - City: ${defaultAddress.city}');

        // Get cart state before setting address
        final cartBefore = ref.read(customerCartProvider);
        debugPrint('🔍 [CART-SCREEN] Cart state BEFORE setting address: ${cartBefore.selectedAddress?.label ?? 'null'}');

        try {
          // Use the default address directly (already unified type)
          ref.read(customerCartProvider.notifier).setDeliveryAddress(defaultAddress);
          debugPrint('✅ [CART-SCREEN] Called setDeliveryAddress with default address');

          // Check cart state after setting address
          final cartAfter = ref.read(customerCartProvider);
          debugPrint('🔍 [CART-SCREEN] Cart state AFTER setting address: ${cartAfter.selectedAddress?.label ?? 'null'}');

          if (cartAfter.selectedAddress != null) {
            debugPrint('✅ [CART-SCREEN] Successfully set default address in cart: ${cartAfter.selectedAddress!.label}');
          } else {
            debugPrint('❌ [CART-SCREEN] Failed to set address - cart still has no address');
          }
        } catch (e, stack) {
          debugPrint('❌ [CART-SCREEN] Error setting default address: $e');
          debugPrint('❌ [CART-SCREEN] Stack trace: $stack');
        }
      } else {
        debugPrint('⚠️ [CART-SCREEN] No default address found, using first address');
        final firstAddress = addressesState.addresses.first;
        debugPrint('🔍 [CART-SCREEN] First address details:');
        debugPrint('🔍 [CART-SCREEN]   - ID: ${firstAddress.id}');
        debugPrint('🔍 [CART-SCREEN]   - Label: ${firstAddress.label}');
        debugPrint('🔍 [CART-SCREEN]   - Address Line 1: ${firstAddress.addressLine1}');
        debugPrint('🔍 [CART-SCREEN]   - City: ${firstAddress.city}');

        try {
          // Use first address as fallback
          ref.read(customerCartProvider.notifier).setDeliveryAddress(firstAddress);
          debugPrint('✅ [CART-SCREEN] Called setDeliveryAddress with first address');

          // Check cart state after setting address
          final cartAfter = ref.read(customerCartProvider);
          debugPrint('🔍 [CART-SCREEN] Cart state AFTER setting first address: ${cartAfter.selectedAddress?.label ?? 'null'}');

          if (cartAfter.selectedAddress != null) {
            debugPrint('✅ [CART-SCREEN] Successfully set first address as fallback: ${cartAfter.selectedAddress!.label}');
          } else {
            debugPrint('❌ [CART-SCREEN] Failed to set first address - cart still has no address');
          }
        } catch (e, stack) {
          debugPrint('❌ [CART-SCREEN] Error setting first address: $e');
          debugPrint('❌ [CART-SCREEN] Stack trace: $stack');
        }
      }
    } else {
      debugPrint('❌ [CART-SCREEN] No addresses available for auto-population');
    }

    debugPrint('🔄 [CART-SCREEN] ===== AUTO-POPULATE ADDRESS END =====');
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(customerCartProvider);
    final theme = Theme.of(context);

    // Listen for delivery method changes and trigger auto-population
    ref.listen<CustomerCartState>(customerCartProvider, (previous, current) {
      // Check if delivery method changed
      if (previous != null &&
          previous.deliveryMethod != current.deliveryMethod) {

        debugPrint('🔄 [CART-SCREEN] Delivery method changed from ${previous.deliveryMethod.name} to ${current.deliveryMethod.name}');

        // If the new method requires driver and we don't have an address, auto-populate
        if (current.deliveryMethod.requiresDriver && current.selectedAddress == null) {
          debugPrint('🔄 [CART-SCREEN] New delivery method requires address, triggering auto-population');

          // Trigger auto-population after a short delay to ensure state is settled
          Future.delayed(const Duration(milliseconds: 100), () {
            _autoPopulateAddressIfNeeded();
          });
        }
        // If the new method doesn't require driver, clear the address
        else if (!current.deliveryMethod.requiresDriver && current.selectedAddress != null) {
          debugPrint('🔄 [CART-SCREEN] New delivery method does not require address, clearing address');
          ref.read(customerCartProvider.notifier).clearDeliveryAddress();
        }
      }
    });

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
              variant: ButtonVariant.primary,
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
                // Show only customer-relevant delivery methods
                ...[
                  CustomerDeliveryMethod.customerPickup,
                  CustomerDeliveryMethod.delivery,
                  CustomerDeliveryMethod.scheduled,
                ].map((method) => RadioListTile<CustomerDeliveryMethod>(
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
        
        // Address selection (if delivery method requires driver)
        if (cartState.deliveryMethod.requiresDriver) ...[
          const SizedBox(height: 16),
          Card(
            child: InkWell(
              onTap: () => _selectDeliveryAddress(),
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
                          if (cartState.selectedAddress?.deliveryInstructions?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info_outline,
                                    size: 14,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: Text(
                                      cartState.selectedAddress!.deliveryInstructions!,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                        fontStyle: FontStyle.italic,
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
          ScheduledDeliveryDisplay(
            scheduledTime: cartState.scheduledDeliveryTime,
            onTap: () => _showScheduleTimePicker(),
            onEdit: () => _showScheduleTimePicker(),
            onClear: () => _clearScheduledTime(),
            showEditButton: cartState.scheduledDeliveryTime != null,
            showClearButton: cartState.scheduledDeliveryTime != null,
            showValidationStatus: true,
            isRequired: true,
            title: 'Scheduled Delivery Time',
            emptyStateText: 'Tap to select your preferred delivery time',
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
    final validationErrors = ref.watch(customerCartValidationProvider);
    final canCheckout = validationErrors.isEmpty;

    // Debug logging for checkout validation
    debugPrint('🔍 [CHECKOUT-SECTION] Validation errors: $validationErrors');
    debugPrint('🔍 [CHECKOUT-SECTION] Can checkout: $canCheckout');
    debugPrint('🔍 [CHECKOUT-SECTION] Cart subtotal: ${cartState.subtotal}');
    debugPrint('🔍 [CHECKOUT-SECTION] Cart total: ${cartState.totalAmount}');

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
            if (validationErrors.isNotEmpty) ...[
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
                        validationErrors.isNotEmpty ? validationErrors.first : '',
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
              onPressed: canCheckout
                  ? () => context.push('/customer/checkout')
                  : null,
              variant: ButtonVariant.primary,
              isLoading: cartState.isLoading,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDeliveryAddress() async {
    final selectedAddressId = await context.push<String>('/customer/addresses/select');

    if (selectedAddressId != null) {
      // Get the selected address from the address provider
      final addressesState = ref.read(address_provider.customerAddressesProvider);
      final selectedAddress = addressesState.addresses
          .where((addr) => addr.id == selectedAddressId)
          .firstOrNull;

      if (selectedAddress != null) {
        // Use the selected address directly (already unified type)
        ref.read(customerCartProvider.notifier).setDeliveryAddress(selectedAddress);

        // Show confirmation
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Delivery address set to ${selectedAddress.label}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    }
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
      barrierDismissible: false, // Prevent dismissing without action
      builder: (context) => ScheduleTimePicker(
        initialDateTime: ref.read(customerCartProvider).scheduledDeliveryTime,
        onDateTimeSelected: (dateTime) {
          if (dateTime != null) {
            ref.read(customerCartProvider.notifier).setScheduledDeliveryTime(dateTime);
            debugPrint('🕒 [CART-SCREEN] Scheduled delivery time set: $dateTime');
          }
        },
        onCancel: () {
          debugPrint('🚫 [CART-SCREEN] Schedule delivery cancelled');
        },
        title: 'Schedule Your Delivery',
        subtitle: 'Choose when you\'d like your order to be delivered',
        showBusinessHours: true,
        minimumAdvanceHours: 2,
        maxDaysAhead: 7,
      ),
    );
  }

  void _clearScheduledTime() {
    ref.read(customerCartProvider.notifier).setScheduledDeliveryTime(null);
    debugPrint('🗑️ [CART-SCREEN] Scheduled delivery time cleared');

    // Show confirmation
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Scheduled delivery time cleared'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }




}
