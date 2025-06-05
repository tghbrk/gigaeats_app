import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/order.dart';
import '../../../data/models/customer.dart';
import '../../../data/models/delivery_method.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/customer_selector.dart';
import '../../widgets/delivery_method_selector.dart';
import '../../widgets/delivery_information_section.dart';

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
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();
  final _deliveryInstructionsController = TextEditingController();

  DateTime? _selectedDeliveryDate;
  TimeOfDay? _selectedDeliveryTime;
  bool _isLoading = false;
  Customer? _selectedCustomer;

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerEmailController.dispose();
    _customerPhoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    _deliveryInstructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
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

                            // Auto-populate address fields for delivery methods
                            _autoPopulateAddressIfNeeded();
                          }
                        });
                      },
                      manualCustomerName: _customerNameController.text,
                      manualCustomerPhone: _customerPhoneController.text,
                      manualCustomerEmail: _customerEmailController.text,
                      onManualEntryChanged: (name, phone, email) {
                        _customerNameController.text = name;
                        _customerPhoneController.text = phone;
                        _customerEmailController.text = email;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Delivery Method Selection
                    DeliveryMethodSelector(
                      selectedMethod: cartState.selectedDeliveryMethod ?? DeliveryMethod.ownFleet,
                      onMethodSelected: (method) {
                        ref.read(cartProvider.notifier).updateDeliveryMethod(method);
                        // Auto-populate address when delivery method changes
                        _autoPopulateAddressIfNeeded();
                      },
                      subtotal: cartState.subtotal,
                    ),

                    const SizedBox(height: 24),

                    // Delivery Information
                    DeliveryInformationSection(
                      selectedDeliveryMethod: cartState.selectedDeliveryMethod ?? DeliveryMethod.ownFleet,
                      selectedDeliveryDate: _selectedDeliveryDate,
                      selectedDeliveryTime: _selectedDeliveryTime,
                      streetController: _streetController,
                      cityController: _cityController,
                      stateController: _stateController,
                      postalCodeController: _postalCodeController,
                      deliveryInstructionsController: _deliveryInstructionsController,
                      onSelectDate: _selectDeliveryDate,
                      onSelectTime: _selectDeliveryTime,
                    ),

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
                      child: CustomButton(
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
          CustomButton(
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
    final cartState = ref.watch(cartProvider);

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

  Future<void> _selectDeliveryDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );

    if (date != null) {
      setState(() {
        _selectedDeliveryDate = date;
      });
    }
  }

  Future<void> _selectDeliveryTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 12, minute: 0),
    );

    if (time != null) {
      setState(() {
        _selectedDeliveryTime = time;
      });
    }
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
    final cartState = ref.read(cartProvider);
    if (cartState.isEmpty) {
      _showErrorSnackBar('Your cart is empty. Please add items before creating an order.');
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

      // Create delivery address (use placeholder for pickup methods)
      final deliveryAddress = deliveryMethod.isPickup
          ? const Address(
              street: 'Pickup Location',
              city: 'N/A',
              state: 'N/A',
              postalCode: '00000',
              country: 'Malaysia',
            )
          : Address(
              street: _streetController.text.trim(),
              city: _cityController.text.trim(),
              state: _stateController.text.trim(),
              postalCode: _postalCodeController.text.trim(),
              country: 'Malaysia',
            );

      // Combine order notes and delivery instructions
      final combinedNotes = <String>[];
      if (_notesController.text.trim().isNotEmpty) {
        combinedNotes.add('Order Notes: ${_notesController.text.trim()}');
      }
      if (_deliveryInstructionsController.text.trim().isNotEmpty) {
        final instructionType = deliveryMethod.isPickup ? 'Pickup' : 'Delivery';
        combinedNotes.add('$instructionType Instructions: ${_deliveryInstructionsController.text.trim()}');
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

        // Clear the cart after successful order creation
        ref.read(cartProvider.notifier).clearCart();

        _showSuccessSnackBar('Order #${order?.orderNumber ?? 'N/A'} created successfully!');

        // Navigate back with a delay to show the success message
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            context.pop();
          }
        });
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

  void _autoPopulateAddressIfNeeded() {
    // Only auto-populate if customer is selected and delivery method requires address
    if (_selectedCustomer == null) return;

    final cartState = ref.read(cartProvider);
    final deliveryMethod = cartState.selectedDeliveryMethod ?? DeliveryMethod.ownFleet;

    // Only auto-populate for Lalamove and Own Delivery Fleet
    if (deliveryMethod == DeliveryMethod.lalamove || deliveryMethod == DeliveryMethod.ownFleet) {
      final address = _selectedCustomer!.address;

      setState(() {
        _streetController.text = address.street;
        _cityController.text = address.city;
        _stateController.text = address.state;
        _postalCodeController.text = address.postcode;

        // Also populate delivery instructions if available
        if (address.deliveryInstructions != null && address.deliveryInstructions!.isNotEmpty) {
          _deliveryInstructionsController.text = address.deliveryInstructions!;
        }
      });

      debugPrint('CreateOrderScreen: Auto-populated address for ${deliveryMethod.displayName}');
    }
  }

  void _showCartSummary(BuildContext context) {
    final cartState = ref.read(cartProvider);

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
