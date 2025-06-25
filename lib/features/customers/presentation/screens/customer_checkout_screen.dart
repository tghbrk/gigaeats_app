import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/customer_cart_provider.dart';
import '../providers/customer_profile_provider.dart';
import '../providers/customer_order_provider.dart';
import '../widgets/schedule_time_picker.dart';
import '../../../../shared/widgets/custom_button.dart';

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
  void dispose() {
    _promoCodeController.dispose();
    _orderNotesController.dispose();
    super.dispose();
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
            
            // Delivery address (if not pickup)
            if (cartState.deliveryMethod != CustomerDeliveryMethod.pickup) ...[
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
                    onPressed: () => context.push('/customer/addresses/select'),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
            
            // Scheduled delivery time (if applicable)
            if (cartState.deliveryMethod == CustomerDeliveryMethod.scheduled) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, color: theme.colorScheme.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Scheduled Time',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          cartState.scheduledDeliveryTime != null
                              ? _formatScheduledTime(cartState.scheduledDeliveryTime!)
                              : 'Not set',
                          style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showScheduleTimePicker(),
                    child: const Text('Change'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(CustomerCartState cartState, ThemeData theme) {
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
                ref.read(customerCartProvider.notifier).setSpecialInstructions(value);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckoutBottomBar(CustomerCartState cartState, ThemeData theme) {
    final orderState = ref.watch(orderCreationProvider);
    final isLoading = _isProcessing || orderState.isLoading;
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

  void _applyPromoCode() {
    final code = _promoCodeController.text.trim();
    if (code.isEmpty) return;

    // TODO: Implement actual promo code validation
    // For now, just simulate a discount
    if (code.toLowerCase() == 'welcome10') {
      setState(() {
        _discount = ref.read(customerCartProvider).subtotal * 0.1; // 10% discount
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

  void _placeOrder() async {
    setState(() => _isProcessing = true);

    try {
      // Validate payment method
      if (_selectedPaymentMethod == 'card') {
        if (_cardDetails == null || !_cardDetails!.complete) {
          throw Exception('Please enter complete card details');
        }
      }

      // Get customer profile
      final customerProfile = ref.read(currentCustomerProfileProvider);
      if (customerProfile == null) {
        throw Exception('Customer profile not found. Please complete your profile first.');
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
        throw Exception(error ?? 'Failed to create order');
      }

      final orderState = ref.read(orderCreationProvider);

      if (_selectedPaymentMethod == 'card' && orderState.paymentClientSecret != null) {
        // Process Stripe payment
        await _processStripePayment(orderState.paymentClientSecret!);
      }

      if (mounted) {
        // Clear cart
        ref.read(customerCartProvider.notifier).clearCart();

        // Clear order creation state
        ref.read(orderCreationProvider.notifier).clearOrder();

        // Invalidate customer orders provider to refresh the list
        ref.invalidate(currentCustomerOrdersProvider);
        ref.invalidate(currentCustomerRecentOrdersProvider);

        // Show success and navigate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order placed successfully!'),
            backgroundColor: Colors.green,
          ),
        );

        // Navigate to order confirmation or orders screen
        context.go('/customer/orders');
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

  /// Process Stripe payment confirmation
  Future<void> _processStripePayment(String clientSecret) async {
    try {
      // Get the current authenticated user's email from Supabase auth
      final currentUser = Supabase.instance.client.auth.currentUser;
      final userEmail = currentUser?.email;

      final paymentMethod = stripe.PaymentMethodParams.card(
        paymentMethodData: stripe.PaymentMethodData(
          billingDetails: stripe.BillingDetails(
            email: userEmail, // Use actual email from auth user
          ),
        ),
      );

      final result = await stripe.Stripe.instance.confirmPayment(
        paymentIntentClientSecret: clientSecret,
        data: paymentMethod,
      );

      if (result.status == stripe.PaymentIntentsStatus.Succeeded) {
        // Payment successful - webhook will handle order status update
        return;
      } else if (result.status == stripe.PaymentIntentsStatus.Canceled) {
        throw Exception('Payment was cancelled');
      } else {
        throw Exception('Payment failed: ${result.status}');
      }
    } catch (e) {
      if (e is stripe.StripeException) {
        throw Exception('Payment failed: ${e.error.localizedMessage ?? e.error.message}');
      } else {
        rethrow;
      }
    }
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
}
