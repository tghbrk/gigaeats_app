import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_profile_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../data/models/customer_profile.dart';

class CustomerAddressesScreen extends ConsumerStatefulWidget {
  const CustomerAddressesScreen({super.key});

  @override
  ConsumerState<CustomerAddressesScreen> createState() => _CustomerAddressesScreenState();
}

class _CustomerAddressesScreenState extends ConsumerState<CustomerAddressesScreen> {
  @override
  void initState() {
    super.initState();
    // Load customer profile when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerProfileProvider.notifier).loadProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(customerProfileProvider);
    final addresses = ref.watch(customerAddressesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Addresses'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: profileState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : profileState.error != null
              ? _buildErrorState(profileState.error!)
              : RefreshIndicator(
                  onRefresh: () => ref.read(customerProfileProvider.notifier).refresh(),
                  child: addresses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: addresses.length,
                          itemBuilder: (context, index) {
                            final address = addresses[index];
                            return _buildAddressCard(address);
                          },
                        ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddAddressDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildAddressCard(CustomerAddress address) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.label,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'Default',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        address.fullAddress,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[700],
                        ),
                      ),
                      if (address.deliveryInstructions?.isNotEmpty == true) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Instructions: ${address.deliveryInstructions}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => _handleAddressAction(value, address),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'set_default',
                        child: Row(
                          children: [
                            Icon(Icons.star),
                            SizedBox(width: 8),
                            Text('Set as Default'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 24),
            Text(
              'No addresses saved',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add your delivery addresses to make ordering easier',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            CustomButton(
              text: 'Add Address',
              onPressed: () => _showAddAddressDialog(),
              type: ButtonType.primary,
              icon: Icons.add_location,
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
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            CustomButton(
              text: 'Try Again',
              onPressed: () => ref.read(customerProfileProvider.notifier).refresh(),
              type: ButtonType.primary,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }

  void _handleAddressAction(String action, CustomerAddress address) {
    switch (action) {
      case 'edit':
        _showEditAddressDialog(address);
        break;
      case 'set_default':
        _setDefaultAddress(address);
        break;
      case 'delete':
        _showDeleteConfirmation(address);
        break;
    }
  }

  void _showAddAddressDialog() {
    debugPrint('🏠 [DEBUG] Opening add address dialog');
    _showAddressDialog();
  }



  void _showEditAddressDialog(CustomerAddress address) {
    _showAddressDialog(address: address);
  }

  void _showAddressDialog({CustomerAddress? address}) {
    final isEditing = address != null;
    debugPrint('🏠 [DEBUG] Showing address dialog - isEditing: $isEditing');

    showDialog(
      context: context,
      builder: (context) => AddressFormDialog(
        address: address,
        onSave: (newAddress) async {
          debugPrint('🏠 [DEBUG] Address form submitted - Label: ${newAddress.label}, Address: ${newAddress.addressLine1}');
          // Capture context before async operation
          final messenger = ScaffoldMessenger.of(context);

          if (isEditing) {
            debugPrint('🏠 [DEBUG] Updating existing address with ID: ${address.id}');
            final success = await ref.read(customerProfileProvider.notifier).updateAddress(newAddress);
            debugPrint('🏠 [DEBUG] Update address result: $success');
            if (success && mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Address updated successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } else {
            debugPrint('🏠 [DEBUG] Adding new address');
            final success = await ref.read(customerProfileProvider.notifier).addAddress(newAddress);
            debugPrint('🏠 [DEBUG] Add address result: $success');
            if (success && mounted) {
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Address added successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _setDefaultAddress(CustomerAddress address) async {
    final updatedAddress = address.copyWith(isDefault: true);
    final success = await ref.read(customerProfileProvider.notifier).updateAddress(updatedAddress);
    
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Default address updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _showDeleteConfirmation(CustomerAddress address) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Address'),
        content: Text('Are you sure you want to delete "${address.label}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (address.id != null) {
                // Capture messenger before async operation
                final messenger = ScaffoldMessenger.of(context);
                final success = await ref.read(customerProfileProvider.notifier).removeAddress(address.id!);
                if (success && mounted) {
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('Address deleted successfully'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Address form dialog widget
class AddressFormDialog extends StatefulWidget {
  final CustomerAddress? address;
  final Function(CustomerAddress) onSave;

  const AddressFormDialog({
    super.key,
    this.address,
    required this.onSave,
  });

  @override
  State<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends State<AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _instructionsController = TextEditingController();

  String _selectedState = 'Selangor';
  bool _isDefault = false;
  bool _isLoading = false;

  final List<String> _malaysianStates = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Malacca',
    'Negeri Sembilan', 'Pahang', 'Penang', 'Perak', 'Perlis', 'Putrajaya',
    'Sabah', 'Sarawak', 'Selangor', 'Terengganu',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.address != null) {
      _labelController.text = widget.address!.label;
      _addressLine1Controller.text = widget.address!.addressLine1;
      _addressLine2Controller.text = widget.address!.addressLine2 ?? '';
      _cityController.text = widget.address!.city;
      _postalCodeController.text = widget.address!.postalCode;
      _instructionsController.text = widget.address!.deliveryInstructions ?? '';
      _selectedState = widget.address!.state;
      _isDefault = widget.address!.isDefault;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth > 600 ? 500.0 : screenWidth * 0.9;

    return AlertDialog(
      title: Text(widget.address != null ? 'Edit Address' : 'Add Address'),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _labelController,
                  decoration: const InputDecoration(
                    labelText: 'Label (e.g., Home, Office)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true ? 'Please enter a label' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressLine1Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 1',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value?.trim().isEmpty == true ? 'Please enter address' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressLine2Controller,
                  decoration: const InputDecoration(
                    labelText: 'Address Line 2 (Optional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Flexible(
                      flex: 2,
                      child: TextFormField(
                        controller: _cityController,
                        decoration: const InputDecoration(
                          labelText: 'City',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) => value?.trim().isEmpty == true ? 'Please enter city' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      flex: 3,
                      child: DropdownButtonFormField<String>(
                        value: _selectedState,
                        decoration: const InputDecoration(
                          labelText: 'State',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                        ),
                        isExpanded: true,
                        items: _malaysianStates.map((state) => DropdownMenuItem(
                          value: state,
                          child: Text(
                            state,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )).toList(),
                        onChanged: (value) => setState(() => _selectedState = value!),
                        validator: (value) => value == null ? 'Please select state' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _postalCodeController,
                  decoration: const InputDecoration(
                    labelText: 'Postal Code',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) => value?.trim().isEmpty == true ? 'Please enter postal code' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _instructionsController,
                  decoration: const InputDecoration(
                    labelText: 'Delivery Instructions (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                CheckboxListTile(
                  title: const Text('Set as default address'),
                  value: _isDefault,
                  onChanged: (value) => setState(() => _isDefault = value ?? false),
                  contentPadding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: widget.address != null ? 'Update' : 'Add',
          onPressed: _isLoading ? null : _saveAddress,
          type: ButtonType.primary,
          isExpanded: false,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final address = CustomerAddress(
        id: widget.address?.id,
        label: _labelController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isNotEmpty 
            ? _addressLine2Controller.text.trim() 
            : null,
        city: _cityController.text.trim(),
        state: _selectedState,
        postalCode: _postalCodeController.text.trim(),
        deliveryInstructions: _instructionsController.text.trim().isNotEmpty 
            ? _instructionsController.text.trim() 
            : null,
        isDefault: _isDefault,
      );

      widget.onSave(address);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
