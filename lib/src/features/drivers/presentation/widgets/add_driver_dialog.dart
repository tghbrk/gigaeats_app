import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user_management/domain/driver.dart';
import '../../data/repositories/driver_repository.dart';

/// Dialog for adding a new driver to the vendor's fleet
class AddDriverDialog extends ConsumerStatefulWidget {
  final VoidCallback? onDriverAdded;

  const AddDriverDialog({
    super.key,
    this.onDriverAdded,
  });

  @override
  ConsumerState<AddDriverDialog> createState() => _AddDriverDialogState();
}

class _AddDriverDialogState extends ConsumerState<AddDriverDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _plateNumberController = TextEditingController();
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();

  String _selectedVehicleType = 'motorcycle';
  bool _isLoading = false;

  final List<String> _vehicleTypes = [
    'motorcycle',
    'car',
    'bicycle',
    'van',
    'truck',
  ];

  final List<String> _vehicleColors = [
    'Red',
    'Blue',
    'Black',
    'White',
    'Silver',
    'Grey',
    'Green',
    'Yellow',
    'Orange',
    'Purple',
  ];

  @override
  void initState() {
    super.initState();
    // Pre-fill phone number with Malaysian country code
    _phoneController.text = '+60';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _plateNumberController.dispose();
    _brandController.dispose();
    _modelController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.person_add,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Add New Driver',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Driver Information Section
                      Text(
                        'Driver Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name Field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'Enter driver\'s full name',
                          prefixIcon: Icon(Icons.person),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                        textCapitalization: TextCapitalization.words,
                      ),
                      const SizedBox(height: 16),

                      // Phone Field
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone Number *',
                          hintText: '+60123456789',
                          prefixIcon: Icon(Icons.phone),
                          border: OutlineInputBorder(),
                          helperText: 'Malaysian format: +60xxxxxxxxx',
                        ),
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[+0-9]')),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          final phoneRegex = RegExp(r'^\+60[0-9]{8,10}$');
                          if (!phoneRegex.hasMatch(value.trim())) {
                            return 'Invalid Malaysian phone format';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Vehicle Information Section
                      Text(
                        'Vehicle Information',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Vehicle Type Dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedVehicleType,
                        decoration: const InputDecoration(
                          labelText: 'Vehicle Type *',
                          prefixIcon: Icon(Icons.directions_car),
                          border: OutlineInputBorder(),
                        ),
                        items: _vehicleTypes.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Row(
                              children: [
                                Icon(_getVehicleIcon(type), size: 20),
                                const SizedBox(width: 8),
                                Text(_capitalizeFirst(type)),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVehicleType = value!;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Plate Number Field
                      TextFormField(
                        controller: _plateNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Plate Number *',
                          hintText: 'ABC 1234',
                          prefixIcon: Icon(Icons.confirmation_number),
                          border: OutlineInputBorder(),
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Plate number is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Brand and Model Row
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandController,
                              decoration: const InputDecoration(
                                labelText: 'Brand',
                                hintText: 'Honda',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _modelController,
                              decoration: const InputDecoration(
                                labelText: 'Model',
                                hintText: 'Wave 125',
                                border: OutlineInputBorder(),
                              ),
                              textCapitalization: TextCapitalization.words,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Color and Year Row
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: null,
                              decoration: const InputDecoration(
                                labelText: 'Color',
                                border: OutlineInputBorder(),
                              ),
                              hint: const Text('Select color'),
                              items: _vehicleColors.map((color) {
                                return DropdownMenuItem(
                                  value: color,
                                  child: Text(color),
                                );
                              }).toList(),
                              onChanged: (value) {
                                _colorController.text = value ?? '';
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _yearController,
                              decoration: const InputDecoration(
                                labelText: 'Year',
                                hintText: '2023',
                                border: OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _addDriver,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Add Driver'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'van':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.local_shipping;
    }
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  Future<void> _addDriver() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id ?? '';

      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      // Get the vendor ID from the vendors table using the user ID
      final supabase = Supabase.instance.client;
      final vendorResponse = await supabase
          .from('vendors')
          .select('id')
          .eq('user_id', userId)
          .single();

      final vendorId = vendorResponse['id'] as String;

      final vehicleDetails = VehicleDetails(
        type: _selectedVehicleType,
        plateNumber: _plateNumberController.text.trim(),
        color: _colorController.text.trim().isNotEmpty ? _colorController.text.trim() : null,
        brand: _brandController.text.trim().isNotEmpty ? _brandController.text.trim() : null,
        model: _modelController.text.trim().isNotEmpty ? _modelController.text.trim() : null,
        year: _yearController.text.trim().isNotEmpty ? _yearController.text.trim() : null,
      );

      final driverRepository = DriverRepository();
      await driverRepository.createDriver(
        vendorId: vendorId,
        name: _nameController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        vehicleDetails: vehicleDetails,
      );

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_nameController.text.trim()} added to your fleet successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        widget.onDriverAdded?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add driver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
