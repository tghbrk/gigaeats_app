import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/customer_profile.dart';
import '../providers/customer_address_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/utils/profile_validators.dart';
import '../../../../core/utils/logger.dart';

class AddressFormDialog extends ConsumerStatefulWidget {
  final CustomerAddress? address;
  final VoidCallback? onSuccess;

  const AddressFormDialog({
    super.key,
    this.address,
    this.onSuccess,
  });

  @override
  ConsumerState<AddressFormDialog> createState() => _AddressFormDialogState();
}

class _AddressFormDialogState extends ConsumerState<AddressFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _labelController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _instructionsController = TextEditingController();
  final AppLogger _logger = AppLogger();

  String _selectedState = 'Selangor';
  String _selectedAddressType = 'Home';
  bool _isDefault = false;
  bool _isLoading = false;

  // Malaysian states from ProfileValidators
  static const List<String> _malaysianStates = [
    'Johor', 'Kedah', 'Kelantan', 'Malacca', 'Negeri Sembilan',
    'Pahang', 'Penang', 'Perak', 'Perlis', 'Sabah', 'Sarawak',
    'Selangor', 'Terengganu', 'Kuala Lumpur', 'Labuan', 'Putrajaya'
  ];

  // Common address types
  static const List<String> _addressTypes = [
    'Home', 'Office', 'Work', 'Family', 'Friend', 'Other'
  ];

  bool get _isEditing => widget.address != null;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (_isEditing && widget.address != null) {
      final address = widget.address!;
      _labelController.text = address.label;
      _addressLine1Controller.text = address.addressLine1;
      _addressLine2Controller.text = address.addressLine2 ?? '';
      _cityController.text = address.city;
      _postalCodeController.text = address.postalCode;
      _instructionsController.text = address.deliveryInstructions ?? '';
      _selectedState = address.state;
      _isDefault = address.isDefault;

      // Set address type based on label
      if (_addressTypes.contains(address.label)) {
        _selectedAddressType = address.label;
      } else {
        _selectedAddressType = 'Other';
      }

      _logger.info('🏠 [ADDRESS-FORM] Initialized form for editing: ${address.label}');
    } else {
      _logger.info('🏠 [ADDRESS-FORM] Initialized form for new address');
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
    final theme = Theme.of(context);
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth = screenSize.width > 600 ? 500.0 : screenSize.width * 0.9;

    return AlertDialog(
      title: Text(
        _isEditing ? 'Edit Address' : 'Add New Address',
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      content: SizedBox(
        width: dialogWidth,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAddressTypeSelector(theme),
                const SizedBox(height: 16),
                _buildLabelField(theme),
                const SizedBox(height: 16),
                _buildAddressLine1Field(theme),
                const SizedBox(height: 16),
                _buildAddressLine2Field(theme),
                const SizedBox(height: 16),
                _buildCityStateRow(theme),
                const SizedBox(height: 16),
                _buildPostalCodeField(theme),
                const SizedBox(height: 16),
                _buildInstructionsField(theme),
                const SizedBox(height: 16),
                _buildAddressPreview(theme),
                const SizedBox(height: 16),
                _buildDefaultCheckbox(theme),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        CustomButton(
          text: _isEditing ? 'Update Address' : 'Add Address',
          onPressed: _isLoading ? null : _saveAddress,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildAddressTypeSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedAddressType,
            decoration: const InputDecoration(
              labelText: 'Address Type *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
            ),
            isExpanded: true,
            items: _addressTypes.map((type) => DropdownMenuItem(
              value: type,
              child: Text(type),
            )).toList(),
            onChanged: (value) {
              setState(() {
                _selectedAddressType = value!;
                // Auto-fill label if it's empty or matches previous type
                if (_labelController.text.isEmpty || _addressTypes.contains(_labelController.text)) {
                  _labelController.text = value;
                }
              });
            },
            validator: (value) => value == null ? 'Please select address type' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: _buildLabelField(theme),
        ),
      ],
    );
  }

  Widget _buildLabelField(ThemeData theme) {
    return TextFormField(
      controller: _labelController,
      decoration: InputDecoration(
        labelText: 'Custom Label',
        hintText: 'e.g., Mom\'s House, Main Office',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.edit),
        helperText: 'Optional: Customize the address name',
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) {
        // Label is optional since we have address type selector
        if (value != null && value.trim().length > 50) {
          return 'Label must be less than 50 characters';
        }
        return null;
      },
    );
  }

  Widget _buildAddressLine1Field(ThemeData theme) {
    return TextFormField(
      controller: _addressLine1Controller,
      decoration: const InputDecoration(
        labelText: 'Address Line 1 *',
        hintText: 'Street address, building name, unit number',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.home),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) => ProfileValidators.validateAddress(value),
    );
  }

  Widget _buildAddressLine2Field(ThemeData theme) {
    return TextFormField(
      controller: _addressLine2Controller,
      decoration: const InputDecoration(
        labelText: 'Address Line 2',
        hintText: 'Apartment, suite, floor (optional)',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.business),
      ),
      textCapitalization: TextCapitalization.words,
      validator: (value) => ProfileValidators.validateAddress(value, required: false),
    );
  }

  Widget _buildCityStateRow(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: TextFormField(
            controller: _cityController,
            decoration: const InputDecoration(
              labelText: 'City *',
              hintText: 'e.g., Kuala Lumpur',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.location_city),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (value) => ProfileValidators.validateCity(value),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: DropdownButtonFormField<String>(
            value: _selectedState,
            decoration: const InputDecoration(
              labelText: 'State *',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.map),
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
            validator: (value) => ProfileValidators.validateState(value),
          ),
        ),
      ],
    );
  }

  Widget _buildPostalCodeField(ThemeData theme) {
    return TextFormField(
      controller: _postalCodeController,
      decoration: const InputDecoration(
        labelText: 'Postal Code *',
        hintText: 'e.g., 50450',
        border: OutlineInputBorder(),
        prefixIcon: Icon(Icons.markunread_mailbox),
        helperText: '5-digit Malaysian postal code',
      ),
      keyboardType: TextInputType.number,
      maxLength: 5,
      validator: (value) => ProfileValidators.validateMalaysianPostcode(value),
      onChanged: (value) {
        // Auto-format postal code (remove non-digits)
        final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
        if (digitsOnly != value) {
          _postalCodeController.value = _postalCodeController.value.copyWith(
            text: digitsOnly,
            selection: TextSelection.collapsed(offset: digitsOnly.length),
          );
        }
      },
    );
  }

  Widget _buildInstructionsField(ThemeData theme) {
    return TextFormField(
      controller: _instructionsController,
      decoration: InputDecoration(
        labelText: 'Delivery Instructions',
        hintText: 'e.g., Ring doorbell twice, Leave at gate, Call upon arrival',
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.note),
        helperText: 'Help delivery drivers find you easily',
        counterText: '${_instructionsController.text.length}/500',
      ),
      maxLines: 3,
      maxLength: 500,
      textCapitalization: TextCapitalization.sentences,
      onChanged: (value) {
        // Trigger rebuild to update counter
        setState(() {});
      },
      validator: (value) {
        if (value != null && value.length > 500) {
          return 'Instructions must be less than 500 characters';
        }
        return null;
      },
    );
  }

  Widget _buildAddressPreview(ThemeData theme) {
    final addressLine1 = _addressLine1Controller.text.trim();
    final addressLine2 = _addressLine2Controller.text.trim();
    final city = _cityController.text.trim();
    final postalCode = _postalCodeController.text.trim();

    if (addressLine1.isEmpty && city.isEmpty && postalCode.isEmpty) {
      return const SizedBox.shrink();
    }

    final addressParts = <String>[];
    if (addressLine1.isNotEmpty) addressParts.add(addressLine1);
    if (addressLine2.isNotEmpty) addressParts.add(addressLine2);
    if (city.isNotEmpty) addressParts.add(city);
    if (postalCode.isNotEmpty) addressParts.add('$postalCode $_selectedState');
    addressParts.add('Malaysia');

    final fullAddress = addressParts.join(', ');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.preview,
                size: 16,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Address Preview',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fullAddress,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultCheckbox(ThemeData theme) {
    return CheckboxListTile(
      title: const Text('Set as default address'),
      subtitle: const Text('Use this address as your primary delivery location'),
      value: _isDefault,
      onChanged: (value) => setState(() => _isDefault = value ?? false),
      contentPadding: EdgeInsets.zero,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      _logger.info('🏠 [ADDRESS-FORM] Saving address: ${_labelController.text}');

      // Use custom label if provided, otherwise use selected address type
      final addressLabel = _labelController.text.trim().isNotEmpty
          ? _labelController.text.trim()
          : _selectedAddressType;

      final address = CustomerAddress(
        id: _isEditing ? widget.address!.id : null,
        label: addressLabel,
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isNotEmpty
            ? _addressLine2Controller.text.trim()
            : null,
        city: _cityController.text.trim(),
        state: _selectedState,
        postalCode: _postalCodeController.text.trim(),
        country: 'Malaysia',
        deliveryInstructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        isDefault: _isDefault,
      );

      bool success;
      if (_isEditing) {
        success = await ref.read(customerAddressesProvider.notifier)
            .updateAddress(widget.address!.id!, address);
      } else {
        success = await ref.read(customerAddressesProvider.notifier)
            .addAddress(address);
      }

      if (success && mounted) {
        _logger.info('✅ [ADDRESS-FORM] Address saved successfully');
        
        Navigator.of(context).pop();
        
        // Call success callback if provided
        widget.onSuccess?.call();
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditing 
                  ? 'Address updated successfully' 
                  : 'Address added successfully'
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      _logger.error('❌ [ADDRESS-FORM] Error saving address', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving address: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
