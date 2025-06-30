import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
// TODO: Restore unused import when Supabase functionality is implemented
// import 'package:supabase_flutter/supabase_flutter.dart';
// TODO: Restore when customer providers and widgets are implemented
// import '../../../../customers/presentation/providers/customer_cart_provider.dart';
// import '../../../../customers/presentation/providers/customer_profile_provider.dart';
// import '../../../../customers/presentation/providers/customer_order_provider.dart';
// import '../../../../customers/presentation/widgets/schedule_time_picker.dart';
import '../../../../orders/presentation/providers/customer/customer_cart_provider.dart';
import '../../../../orders/presentation/providers/customer/customer_order_provider.dart';
import '../../../../orders/data/models/customer_delivery_method.dart';
import '../../../../user_management/presentation/providers/customer_address_provider.dart' as address_provider;

import '../../../../../shared/widgets/custom_button.dart';

class CustomerCheckoutScreen extends ConsumerStatefulWidget {
  const CustomerCheckoutScreen({super.key});

  @override
  ConsumerState<CustomerCheckoutScreen> createState() => _CustomerCheckoutScreenState();
}

class _CustomerCheckoutScreenState extends ConsumerState<CustomerCheckoutScreen> {
  String _selectedPaymentMethod = 'card';
  bool _isProcessing = false;
  final TextEditingController _promoCodeController = TextEditingController();
  double _discount = 0.0;
  stripe.CardFieldInputDetails? _cardDetails;
  final TextEditingController _orderNotesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Auto-populate default address when checkout screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPopulateDefaultAddressIfNeeded();
    });
  }

  @override
  void dispose() {
    _promoCodeController.dispose();
    _orderNotesController.dispose();
    super.dispose();
  }

  /// Auto-populate delivery address from user's default address
  void _autoPopulateDefaultAddressIfNeeded() {
    final cartState = ref.read(customerCartProvider);

    // Only auto-populate if:
    // 1. Cart doesn't already have an address selected
    // 2. Delivery method requires an address (e.g., delivery, not pickup)
    if (cartState.selectedAddress != null || !cartState.deliveryMethod.requiresDriver) {
      return;
    }

    // Get the user's default address
    final defaultAddress = ref.read(address_provider.defaultCustomerAddressProvider);

    if (defaultAddress != null) {
      // Auto-populate with the default address
      ref.read(customerCartProvider.notifier).setDeliveryAddress(defaultAddress);

      // Show a subtle notification that the default address was used
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Using default address: ${defaultAddress.label}'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
            action: SnackBarAction(
              label: 'Change',
              textColor: Colors.white,
              onPressed: () => _changeDeliveryAddress(),
            ),
          ),
        );
      }
    } else {
      // No default address found, load addresses if not already loaded
      final addressesState = ref.read(address_provider.customerAddressesProvider);
      if (addressesState.addresses.isEmpty && !addressesState.isLoading) {
        ref.read(address_provider.customerAddressesProvider.notifier).loadAddresses();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(customerCartProvider);
    final theme = Theme.of(context);

    if (cartState.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text('Your cart is empty'),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDeliverySection(cartState, theme),
                  const SizedBox(height: 24),
                  _buildOrderSummary(cartState, theme),
                  const SizedBox(height: 24),
                  _buildPromoCodeSection(theme),
                  const SizedBox(height: 24),
                  _buildPaymentMethodSection(theme),
                  const SizedBox(height: 24),
                  _buildOrderNotes(theme),
                ],
              ),
            ),
          ),
          _buildCheckoutBottomBar(cartState, theme),
        ],
      ),
    );
  }

  Widget _buildDeliverySection(CustomerCartState cartState, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Delivery Details',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Delivery method
            Row(
              children: [
                Icon(Icons.delivery_dining, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cartState.deliveryMethod.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        cartState.deliveryMethod.description,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.pop(),
                  child: const Text('Change'),
                ),
              ],
            ),
            
            // Delivery address (if delivery method requires driver)
            if (cartState.deliveryMethod.requiresDriver) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.location_on, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Delivery Address',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          cartState.selectedAddress?.fullAddress ?? 'No address selected',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _changeDeliveryAddress(),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
            
            // Scheduled delivery time (if applicable)
            // TODO: Restore when CustomerDeliveryMethod is implemented
            // if (cartState.deliveryMethod == CustomerDeliveryMethod.scheduled) ...[
            // TODO: Restore when CustomerDeliveryMethod is implemented
            // if (false) ...[  // Placeholder - assume no scheduled delivery
            //   const SizedBox(height: 12),
            //   const Divider(),
            //   const SizedBox(height: 12),
            //   Row(
            //     children: [
            //       Icon(Icons.schedule, color: theme.colorScheme.primary),
            //       const SizedBox(width: 12),
            //       Expanded(
            //         child: Column(
            //           crossAxisAlignment: CrossAxisAlignment.start,
            //           children: [
            //             Text(
            //               'Scheduled Time',
            //               style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            //             ),
            //             Text(
            //               cartState.scheduledDeliveryTime != null
            //                   ? _formatScheduledTime(cartState.scheduledDeliveryTime!)
            //                   : 'Not set',
            //               style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            //             ),
            //           ],
            //         ),
            //       ),
            //       TextButton(
            //         onPressed: () => _showScheduleTimePicker(),
            //         child: const Text('Change'),
            //       ),
            //     ],
            //   ),
            // ],
          ],
        ),
      ),
    );
  }

  // TODO: Restore when CustomerCartState is implemented
  Widget _buildOrderSummary(dynamic cartState, ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Summary',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            
            // Order items
            ...cartState.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${item.quantity}x'),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.name,
                      style: theme.textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    'RM ${item.totalPrice.toStringAsFixed(2)}',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Price breakdown
            _buildPriceRow('Subtotal', cartState.subtotal, theme),
            _buildPriceRow('SST (6%)', cartState.sstAmount, theme),
            _buildPriceRow('Delivery Fee', cartState.deliveryFee, theme),
            if (_discount > 0)
              _buildPriceRow('Discount', -_discount, theme, isDiscount: true),
            
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            
            _buildPriceRow(
              'Total',
              cartState.totalAmount - _discount,
              theme,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, ThemeData theme, {bool isTotal = false, bool isDiscount = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
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
            '${isDiscount ? '-' : ''}RM ${amount.abs().toStringAsFixed(2)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal 
                  ? theme.colorScheme.primary 
                  : isDiscount 
                      ? Colors.green 
                      : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoCodeSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Promo Code',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoCodeController,
                    decoration: const InputDecoration(
                      hintText: 'Enter promo code',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                CustomButton(
                  text: 'Apply',
                  onPressed: _applyPromoCode,
                  type: ButtonType.secondary,
                  isExpanded: false,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Payment Method',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            RadioListTile<String>(
              title: const Text('Credit/Debit Card'),
              subtitle: const Text('Pay securely with your card'),
              value: 'card',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              contentPadding: EdgeInsets.zero,
            ),

            // Show card input field when card is selected
            if (_selectedPaymentMethod == 'card') ...[
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: stripe.CardField(
                  onCardChanged: (details) {
                    setState(() {
                      _cardDetails = details;
                    });
                  },
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Card number',
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                  enablePostalCode: false, // Disable postal code for Malaysian cards
                ),
              ),
            ],

            const SizedBox(height: 8),

            RadioListTile<String>(
              title: const Text('Cash on Delivery'),
              subtitle: const Text('Pay when your order arrives'),
              value: 'cash',
              groupValue: _selectedPaymentMethod,
              onChanged: (value) => setState(() => _selectedPaymentMethod = value!),
              contentPadding: EdgeInsets.zero,
            ),

            RadioListTile<String>(
              title: const Text('Digital Wallet'),
              subtitle: const Text('Coming soon'),
              value: 'wallet',
              groupValue: _selectedPaymentMethod,
              onChanged: null, // Disabled for now
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderNotes(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order Notes',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _orderNotesController,
              decoration: const InputDecoration(
                hintText: 'Any special instructions for your order?',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              onChanged: (value) {
                // TODO: Restore when customerCartProvider is implemented
                // ref.read(customerCartProvider.notifier).setSpecialInstructions(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  // TODO: Restore when CustomerCartState is implemented
  Widget _buildCheckoutBottomBar(dynamic cartState, ThemeData theme) {
    // TODO: Restore when orderCreationProvider is implemented
    // final orderState = ref.watch(orderCreationProvider);
    final orderState = null;
    final isLoading = _isProcessing || (orderState?.isLoading ?? false);
    final canCheckout = cartState.canCheckout && !isLoading;
    final totalAmount = cartState.totalAmount - _discount;

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
        child: CustomButton(
          text: isLoading
              ? 'Processing...'
              : 'Place Order - RM ${totalAmount.toStringAsFixed(2)}',
          onPressed: canCheckout ? _placeOrder : null,
          type: ButtonType.primary,
          isLoading: isLoading,
        ),
      ),
    );
  }

  // TODO: Restore unused method _showScheduleTimePicker when ScheduleTimePicker is implemented
  // void _showScheduleTimePicker() {
  //   showDialog(
  //     context: context,
  //     // TODO: Restore when ScheduleTimePicker is implemented
  //     // builder: (context) => ScheduleTimePicker(
  //     builder: (context) => AlertDialog( // Placeholder dialog
  //       title: const Text('Schedule Delivery'),
  //       content: const Text('Schedule delivery feature coming soon!'),
  //       actions: [
  //         TextButton(
  //           onPressed: () => Navigator.of(context).pop(),
  //           child: const Text('OK'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    // TODO: Implement actual promo code validation
    // For now, just simulate a discount
    if (code.toLowerCase() == 'welcome10') {
      setState(() {
        // TODO: Restore when customerCartProvider is implemented
        // _discount = ref.read(customerCartProvider).subtotal * 0.1; // 10% discount
        _discount = 10.0; // Placeholder discount
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Promo code applied! 10% discount'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _placeOrder() async {
    setState(() => _isProcessing = true);

    try {
      // Validate payment method
      if (_selectedPaymentMethod == 'card') {
        if (_cardDetails == null || !_cardDetails!.complete) {
          throw Exception('Please enter complete card details');
        }
      }

      // Create order and process payment
      final orderCreationNotifier = ref.read(orderCreationProvider.notifier);
      final success = await orderCreationNotifier.createOrderAndProcessPayment(
        paymentMethod: _selectedPaymentMethod == 'card' ? 'credit_card' : _selectedPaymentMethod,
        specialInstructions: _orderNotesController.text.trim().isNotEmpty
            ? _orderNotesController.text.trim()
            : null,
      );

      if (!success) {
        final error = ref.read(orderCreationProvider).error;
        throw Exception(error ?? 'Order creation failed');
      }

      // Order creation successful - handle post-order workflow
      if (success && mounted) {
        // Get the created order from state
        final createdOrder = ref.read(orderCreationProvider).order;
        final orderNumber = createdOrder?.orderNumber ?? 'Unknown';

        // Show success toast with order number
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order placed successfully! Order #$orderNumber'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'View Orders',
              textColor: Colors.white,
              onPressed: () => context.go('/customer/orders'),
            ),
          ),
        );

        // Invalidate customer orders provider to refresh the list
        ref.invalidate(currentCustomerOrdersProvider);

        // Add a brief delay to show the success message, then navigate
        await Future.delayed(const Duration(milliseconds: 1500));

        // Navigate to customer orders screen
        if (mounted) {
          context.go('/customer/orders');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error placing order: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  // TODO: Restore unused method _processStripePayment when Stripe integration is implemented
  // Future<void> _processStripePayment(String clientSecret) async {
  //   try {
  //     // Get the current authenticated user's email from Supabase auth
  //     final currentUser = Supabase.instance.client.auth.currentUser;
  //     final userEmail = currentUser?.email;

  //     final paymentMethod = stripe.PaymentMethodParams.card(
  //       paymentMethodData: stripe.PaymentMethodData(
  //         billingDetails: stripe.BillingDetails(
  //           email: userEmail, // Use actual email from auth user
  //         ),
  //       ),
  //     );

  //     final result = await stripe.Stripe.instance.confirmPayment(
  //       paymentIntentClientSecret: clientSecret,
  //       data: paymentMethod,
  //     );

  //     if (result.status == stripe.PaymentIntentsStatus.Succeeded) {
  //       // Payment successful - webhook will handle order status update
  //       return;
  //     } else if (result.status == stripe.PaymentIntentsStatus.Canceled) {
  //       throw Exception('Payment was cancelled');
  //     } else {
  //       throw Exception('Payment failed: ${result.status}');
  //     }
  //   } catch (e) {
  //     if (e is stripe.StripeException) {
  //       throw Exception('Payment failed: ${e.error.localizedMessage ?? e.error.message}');
  //     } else {
  //       rethrow;
  //     }
  //   }
  // }

  // TODO: Restore unused method _formatScheduledTime when schedule delivery is implemented
  // String _formatScheduledTime(DateTime dateTime) {
  //   final now = DateTime.now();
  //   final today = DateTime(now.year, now.month, now.day);
  //   final tomorrow = today.add(const Duration(days: 1));
  //   final scheduledDay = DateTime(dateTime.year, dateTime.month, dateTime.day);

  //   final timeString = TimeOfDay.fromDateTime(dateTime).format(context);

  //   if (scheduledDay == today) {
  //     return 'Today, $timeString';
  //   } else if (scheduledDay == tomorrow) {
  //     return 'Tomorrow, $timeString';
  //   } else {
  //     final months = [
  //       'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  //       'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  //     ];
  //     final dateString = '${dateTime.day} ${months[dateTime.month - 1]}';
  //     return '$dateString, $timeString';
  //   }
  // }

  Future<void> _changeDeliveryAddress() async {
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
              content: Text('Delivery address updated to ${selectedAddress.label}'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    }
  }
}
