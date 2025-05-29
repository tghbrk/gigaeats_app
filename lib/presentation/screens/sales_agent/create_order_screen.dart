import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/order.dart';
import '../../../data/models/customer.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/customer_selector.dart';

class CreateOrderScreen extends ConsumerStatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  ConsumerState<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends ConsumerState<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _notesController = TextEditingController();

  Customer? _selectedCustomer;
  DateTime? _selectedDeliveryDate;
  TimeOfDay? _selectedDeliveryTime;
  bool _isLoading = false;

  @override
  void dispose() {
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);

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
                    // Cart Summary Card
                    _buildCartSummaryCard(),

                    const SizedBox(height: 24),

                    // Customer Selection
                    CustomerSelector(
                      selectedCustomer: _selectedCustomer,
                      onCustomerSelected: (customer) {
                        setState(() {
                          _selectedCustomer = customer;
                          // Pre-fill delivery address if customer has default address
                          if (customer != null) {
                            _streetController.text = customer.address.street;
                            _cityController.text = customer.address.city;
                            _stateController.text = customer.address.state;
                            _postalCodeController.text = customer.address.postcode;
                          }
                        });
                      },
                    ),

                    const SizedBox(height: 24),

                    // Delivery Information
                    _buildSectionHeader('Delivery Information'),
                    const SizedBox(height: 16),
                    _buildDeliveryForm(),

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
            onPressed: () => context.pop(),
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



  Widget _buildDeliveryForm() {
    return Column(
      children: [
        // Delivery Date & Time
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _selectDeliveryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Delivery Date *',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDeliveryDate != null
                        ? '${_selectedDeliveryDate!.day}/${_selectedDeliveryDate!.month}/${_selectedDeliveryDate!.year}'
                        : 'Select date',
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _selectDeliveryTime,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Delivery Time',
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDeliveryTime != null
                        ? _selectedDeliveryTime!.format(context)
                        : 'Select time',
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Delivery Address
        CustomTextField(
          controller: _streetController,
          label: 'Street Address *',
          hintText: 'Enter street address',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Street address is required';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _cityController,
                label: 'City *',
                hintText: 'Kuala Lumpur',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'City is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _postalCodeController,
                label: 'Postal Code *',
                hintText: '50000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Postal code is required';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        CustomTextField(
          controller: _stateController,
          label: 'State *',
          hintText: 'Selangor',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'State is required';
            }
            return null;
          },
        ),
      ],
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCustomer == null) {
      _showErrorSnackBar('Please select a customer');
      return;
    }

    if (_selectedDeliveryDate == null) {
      _showErrorSnackBar('Please select a delivery date');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
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
      }

      final deliveryAddress = Address(
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: 'Malaysia',
      );

      final order = await ref.read(ordersProvider.notifier).createOrder(
        customerId: _selectedCustomer!.id,
        customerName: _selectedCustomer!.organizationName,
        deliveryDate: deliveryDateTime,
        deliveryAddress: deliveryAddress,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (order != null) {
        if (mounted) {
          _showSuccessSnackBar('Order created successfully!');
          context.pop(); // Go back to previous screen
        }
      } else {
        _showErrorSnackBar('Failed to create order. Please try again.');
      }
    } catch (e) {
      _showErrorSnackBar('Error: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showCartSummary(BuildContext context) {
    // TODO: Implement cart summary modal
    showModalBottomSheet(
      context: context,
      builder: (context) => const Center(
        child: Text('Cart Summary - Coming Soon'),
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
