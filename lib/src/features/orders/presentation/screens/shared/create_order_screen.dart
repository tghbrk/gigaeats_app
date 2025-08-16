import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/order.dart';
import '../../../../customers/data/models/customer.dart';
import '../../../data/models/delivery_method.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
// TODO: Restore when cartProvider is implemented
// import '../../../../sales_agent/presentation/providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../widgets/customer_selector.dart';
import '../../../widgets/delivery_method_selector.dart';
import '../../../widgets/delivery_information_section.dart';
import '../../../../payments/presentation/screens/payment_screen.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _customerNameController = TextEditingController();
  final _customerEmailController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDeliveryDate;
  TimeOfDay? _selectedDeliveryTime;
  bool _isLoading = false;
  Customer? _selectedCustomer;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Restore when cartProvider is implemented
    // final cartState = ref.watch(cartProvider);
    final cartState = null;
    final authState = ref.watch(authStateProvider);

    // Check authentication status
    if (authState.status == AuthStatus.unauthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Order')),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline, size: 64, color: Colors.grey),
              SizedBox(height: 16),
              Text(
                'Authentication Required',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'Please log in to create orders',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (authState.status == AuthStatus.loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Order')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Order'),
        actions: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () => _showCartSummary(context),
          ),
        ],
      ),
      body: cartState.isEmpty
          ? _buildEmptyCart()
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Authentication Status Card
                    if (authState.user != null) _buildUserInfoCard(authState.user!),

                    const SizedBox(height: 16),

                    // Cart Summary Card
                    _buildCartSummaryCard(),

                    const SizedBox(height: 24),

                    // Customer Information
                    CustomerSelector(
                      selectedCustomer: _selectedCustomer,
                      onCustomerSelected: (customer) {
                        setState(() {
                          _selectedCustomer = customer;
                          if (customer != null) {
                            // Auto-fill customer information
                            _customerNameController.text = customer.organizationName;
                            _customerEmailController.text = customer.email;
                            _customerPhoneController.text = customer.phoneNumber;

                            // Address auto-population is handled by DeliveryInformationSection widget
                          }
                        });
                      },
                      // Manual entry parameters temporarily removed for quick launch
                    ),

                    const SizedBox(height: 24),

                    // Delivery Method Selection
                    DeliveryMethodSelector(
                      selectedMethod: cartState.selectedDeliveryMethod ?? DeliveryMethod.ownFleet,
                      onMethodSelected: (method) {
                        if (method != null) {
                          // TODO: Restore when cartProvider is implemented
                          // ref.read(cartProvider.notifier).updateDeliveryMethod(method);
                          // Address auto-population is handled by DeliveryInformationSection widget
                        }
                      },
                      // subtotal parameter temporarily removed for quick launch
                    ),

                    const SizedBox(height: 24),

                    // Delivery Information
                    DeliveryInformationSection(
                      deliveryMethod: cartState.selectedDeliveryMethod,
                      selectedCustomer: _selectedCustomer,
                      deliveryInfo: const {},
                      onDeliveryInfoChanged: (info) {
                        // Handle delivery info changes
                      },
                    ),

                    const SizedBox(height: 24),

                    // Delivery Date & Time Selection
                    _buildSectionHeader('Delivery Date & Time'),
                    const SizedBox(height: 16),
                    _buildDateTimeSelection(),

                    const SizedBox(height: 24),

                    // Additional Notes
                    _buildSectionHeader('Additional Notes'),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _notesController,
                      label: 'Order Notes (Optional)',
                      hintText: 'Any special instructions or requirements...',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 32),

                    // Create Order Button
                    SizedBox(
                      width: double.infinity,
                      child: GEButton.primary(
                        text: 'Create Order',
                        onPressed: _isLoading ? null : _createOrder,
                        isLoading: _isLoading,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildUserInfoCard(dynamic user) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.person,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Agent: ${user.fullName}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    user.email,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Authenticated',
                style: TextStyle(
                  color: Colors.green[700],
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add items to your cart before creating an order',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          GEButton.primary(
            text: 'Browse Vendors',
            onPressed: () {
              // Navigate directly to the vendors screen
              context.push('/sales-agent/vendors');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummaryCard() {
    // TODO: Restore when cartProvider is implemented
    // final cartState = ref.watch(cartProvider);
    final cartState = null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: () => _showCartSummary(context),
                  child: const Text('View Details'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Items (${cartState.totalItems})'),
                Text('RM ${cartState.subtotal.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('SST (6%)'),
                Text('RM ${cartState.sstAmount.toStringAsFixed(2)}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Delivery Fee'),
                Text('RM ${cartState.deliveryFee.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'RM ${cartState.totalAmount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildDateTimeSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Date *',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDeliveryDate != null
                                      ? _formatDate(_selectedDeliveryDate!)
                                      : 'Select delivery date',
                                  style: TextStyle(
                                    color: _selectedDeliveryDate != null
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_selectedDeliveryDate != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDeliveryDate = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Time Selection (Optional)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery Time (Optional)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Theme.of(context).primaryColor,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _selectedDeliveryTime != null
                                      ? _formatTime(_selectedDeliveryTime!)
                                      : 'Select delivery time (defaults to 12:00 PM)',
                                  style: TextStyle(
                                    color: _selectedDeliveryTime != null
                                        ? Colors.black87
                                        : Colors.grey.shade600,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              if (_selectedDeliveryTime != null)
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedDeliveryTime = null;
                                    });
                                  },
                                  child: Icon(
                                    Icons.clear,
                                    color: Colors.grey.shade600,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // Validation Error Display
            if (_selectedDeliveryDate == null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Please select a delivery date',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDeliveryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 1),
      helpText: 'Select Delivery Date',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null && picked != _selectedDeliveryDate) {
      setState(() {
        _selectedDeliveryDate = picked;
      });
    }
  }

  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedDeliveryTime ?? const TimeOfDay(hour: 12, minute: 0),
      helpText: 'Select Delivery Time',
      cancelText: 'Cancel',
      confirmText: 'Select',
    );

    if (picked != null && picked != _selectedDeliveryTime) {
      setState(() {
        _selectedDeliveryTime = picked;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final selectedDate = DateTime(date.year, date.month, date.day);

    if (selectedDate == today) {
      return 'Today, ${_formatDateString(date)}';
    } else if (selectedDate == tomorrow) {
      return 'Tomorrow, ${_formatDateString(date)}';
    } else {
      return _formatDateString(date);
    }
  }

  String _formatDateString(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    final displayHour = hour == 0 ? 12 : hour;
    return '$displayHour:$minute $period';
  }

  Future<void> _createOrder() async {
    // Validate form
    if (!_formKey.currentState!.validate()) {
      _showErrorSnackBar('Please fill in all required fields correctly');
      return;
    }

    // Validate delivery date
    if (_selectedDeliveryDate == null) {
      _showErrorSnackBar('Please select a delivery date');
      return;
    }

    // Check if delivery date is in the future
    final now = DateTime.now();
    final selectedDate = _selectedDeliveryDate!;
    if (selectedDate.isBefore(DateTime(now.year, now.month, now.day))) {
      _showErrorSnackBar('Delivery date must be today or in the future');
      return;
    }

    // Check authentication
    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      _showErrorSnackBar('Authentication required. Please log in and try again.');
      return;
    }

    // Check cart
    // TODO: Restore when cartProvider is implemented
    // final cartState = ref.read(cartProvider);
    final cartState = null;
    if (cartState.isEmpty) {
      _showErrorSnackBar('Your cart is empty. Please add items before creating an order.');
      return;
    }

    // Validate customer selection for delivery methods
    final deliveryMethod = cartState.selectedDeliveryMethod ?? DeliveryMethod.ownFleet;
    if (!deliveryMethod.isPickup && _selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer for delivery orders.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('CreateOrderScreen: Starting order creation process');

      // Combine date and time
      DateTime deliveryDateTime = _selectedDeliveryDate!;
      if (_selectedDeliveryTime != null) {
        deliveryDateTime = DateTime(
          _selectedDeliveryDate!.year,
          _selectedDeliveryDate!.month,
          _selectedDeliveryDate!.day,
          _selectedDeliveryTime!.hour,
          _selectedDeliveryTime!.minute,
        );
      } else {
        // Default to 12:00 PM if no time selected
        deliveryDateTime = DateTime(
          _selectedDeliveryDate!.year,
          _selectedDeliveryDate!.month,
          _selectedDeliveryDate!.day,
          12,
          0,
        );
      }

      // Get delivery method with fallback
      final deliveryMethod = cartState.selectedDeliveryMethod ?? DeliveryMethod.ownFleet;

      // Create delivery address using customer data for delivery methods
      final deliveryAddress = deliveryMethod.isPickup
          ? const Address(
              street: 'Pickup Location',
              city: 'N/A',
              state: 'N/A',
              postalCode: '00000',
              country: 'Malaysia',
            )
          : _selectedCustomer != null
              ? Address(
                  street: _selectedCustomer!.address.street,
                  city: _selectedCustomer!.address.city,
                  state: _selectedCustomer!.address.state,
                  postalCode: _selectedCustomer!.address.postcode,
                  country: _selectedCustomer!.address.country,
                )
              : const Address(
                  street: 'Address Not Available',
                  city: 'N/A',
                  state: 'N/A',
                  postalCode: '00000',
                  country: 'Malaysia',
                );

      // Combine order notes and delivery instructions
      final combinedNotes = <String>[];
      if (_notesController.text.trim().isNotEmpty) {
        combinedNotes.add('Order Notes: ${_notesController.text.trim()}');
      }

      // Add customer delivery instructions if available
      if (!deliveryMethod.isPickup &&
          _selectedCustomer != null &&
          _selectedCustomer!.address.deliveryInstructions != null &&
          _selectedCustomer!.address.deliveryInstructions!.isNotEmpty) {
        combinedNotes.add('Delivery Instructions: ${_selectedCustomer!.address.deliveryInstructions}');
      }

      combinedNotes.add('Delivery Method: ${deliveryMethod.displayName}');

      debugPrint('CreateOrderScreen: Creating order with delivery date: $deliveryDateTime');
      debugPrint('CreateOrderScreen: Customer: ${_customerNameController.text.trim()}');
      debugPrint('CreateOrderScreen: Phone: ${_customerPhoneController.text.trim()}');
      debugPrint('CreateOrderScreen: Delivery Method: ${deliveryMethod.displayName}');

      final order = await ref.read(ordersProvider.notifier).createOrder(
        customerId: _selectedCustomer?.id, // Use selected customer ID if available
        customerName: _customerNameController.text.trim(),
        deliveryDate: deliveryDateTime,
        deliveryAddress: deliveryAddress,
        notes: combinedNotes.isNotEmpty ? combinedNotes.join('\n\n') : null,
        contactPhone: _customerPhoneController.text.trim().isNotEmpty
            ? _customerPhoneController.text.trim()
            : null,
      );

      // If we reach here, the order was created successfully
      if (mounted) {
        debugPrint('CreateOrderScreen: Order created successfully: ${order?.id}');

        // Navigate directly to payment screen without showing success message
        if (order != null) {
          // Navigate to payment screen with the created order
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PaymentScreen(order: order),
            ),
          ).then((paymentResult) {
            // Handle payment completion
            if (paymentResult == true) {
              // Payment successful - clear cart and navigate back
              // TODO: Restore when cartProvider is implemented
              // ref.read(cartProvider.notifier).clearCart();
              _showSuccessSnackBar('Order #${order.orderNumber} completed successfully!');
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  context.pop();
                }
              });
            } else {
              // Payment failed or cancelled - keep cart and stay on order screen
              _showErrorSnackBar('Payment was not completed. Order #${order.orderNumber} is saved but requires payment.');
            }
          });
        }
      }
    } catch (e) {
      debugPrint('CreateOrderScreen: Error creating order: $e');

      // Extract the error message from the exception
      String errorMessage = e.toString();

      // Remove "Exception: " prefix if present
      if (errorMessage.startsWith('Exception: ')) {
        errorMessage = errorMessage.substring(11);
      }

      // If it's still a generic message, provide fallback
      if (errorMessage.isEmpty || errorMessage == 'Failed to create order') {
        errorMessage = 'Failed to create order. Please try again later.';
      }

      _showErrorSnackBar(errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Address auto-population is now handled by the DeliveryInformationSection widget
  // No manual controller population needed since we use customer data directly

  void _showCartSummary(BuildContext context) {
    // TODO: Restore when cartProvider is implemented
    // final cartState = ref.read(cartProvider);
    final cartState = null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cart Summary',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Cart items
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: cartState.items.length,
                  itemBuilder: (context, index) {
                    final item = cartState.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: item.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  item.imageUrl!,
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    width: 50,
                                    height: 50,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.fastfood),
                                  ),
                                ),
                              )
                            : Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.fastfood),
                              ),
                        title: Text(
                          item.name,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Qty: ${item.quantity}'),
                            Text('RM ${item.unitPrice.toStringAsFixed(2)} each'),
                            if (item.notes != null && item.notes!.isNotEmpty)
                              Text(
                                'Note: ${item.notes}',
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 12,
                                ),
                              ),
                          ],
                        ),
                        trailing: Text(
                          'RM ${item.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // Summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal'),
                        Text('RM ${cartState.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('SST (6%)'),
                        Text('RM ${cartState.sstAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Delivery Fee'),
                        Text('RM ${cartState.deliveryFee.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'RM ${cartState.totalAmount.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
