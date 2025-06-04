import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../widgets/custom_text_field.dart';

import '../../../core/utils/responsive_utils.dart';

class EditCustomerScreen extends ConsumerStatefulWidget {
  final String customerId;

  const EditCustomerScreen({
    super.key,
    required this.customerId,
  });

  @override
  ConsumerState<EditCustomerScreen> createState() => _EditCustomerScreenState();
}

class _EditCustomerScreenState extends ConsumerState<EditCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _notesController = TextEditingController();

  CustomerType _selectedType = CustomerType.corporate;
  bool _isActive = true;
  bool _isLoading = false;
  Customer? _originalCustomer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _organizationNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _alternatePhoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _populateFields(Customer customer) {
    debugPrint('🔧 EditCustomerScreen: _populateFields() called for ${customer.organizationName}');
    _originalCustomer = customer;
    _organizationNameController.text = customer.organizationName;
    _contactPersonController.text = customer.contactPersonName;
    _emailController.text = customer.email;
    _phoneController.text = customer.phoneNumber;
    _alternatePhoneController.text = customer.alternatePhoneNumber ?? '';
    _streetController.text = customer.address.street;
    _cityController.text = customer.address.city;
    _stateController.text = customer.address.state;
    _postcodeController.text = customer.address.postcode;
    _notesController.text = customer.notes ?? '';
    _selectedType = customer.type;
    _isActive = customer.isActive;
    debugPrint('🔧 EditCustomerScreen: Fields populated, _originalCustomer set');
  }

  @override
  Widget build(BuildContext context) {
    // Ensure we get fresh customer data when opening the edit screen (only once)
    if (_originalCustomer == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        debugPrint('🔧 EditCustomerScreen: Invalidating cache to ensure fresh data');
        ref.invalidate(customerByIdProvider(widget.customerId));
      });
    }

    final customerAsync = ref.watch(customerByIdProvider(widget.customerId));
    debugPrint('🔧 EditCustomerScreen: build() called, _isLoading: $_isLoading');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Customer'),
        actions: [
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: () {
                debugPrint('🔧 EditCustomerScreen: Save button pressed');
                _saveCustomer();
              },
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: customerAsync.when(
        data: (customer) {
          if (customer == null) {
            return _buildNotFound();
          }
          
          // Populate fields when customer data is loaded
          if (_originalCustomer == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _populateFields(customer);
            });
          }

          return _buildForm();
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _buildErrorState(error.toString()),
      ),
    );
  }

  Widget _buildForm() {
    return ResponsiveContainer(
      child: SingleChildScrollView(
        padding: context.responsivePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customer Type Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Type',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<CustomerType>(
                        value: _selectedType,
                        decoration: const InputDecoration(
                          labelText: 'Customer Type',
                          border: OutlineInputBorder(),
                        ),
                        items: CustomerType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedType = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Please select a customer type';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Basic Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Basic Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _organizationNameController,
                        label: 'Organization Name',
                        hintText: 'Enter organization name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Organization name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _contactPersonController,
                        label: 'Contact Person',
                        hintText: 'Enter contact person name',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Contact person is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Contact Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _emailController,
                        label: 'Email',
                        hintText: 'Enter email address',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hintText: 'Enter phone number (e.g., +60123456789)',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          final cleanValue = value.replaceAll(' ', '').replaceAll('-', '');
                          debugPrint('🔧 Phone validation: Input="$value", Clean="$cleanValue"');

                          // Allow multiple formats:
                          // +60123456789 (12-13 digits with +60)
                          // 0123456789 (10-11 digits starting with 0)
                          // 123456789 (9-10 digits without prefix)
                          bool isValid = RegExp(r'^\+60\d{9,10}$').hasMatch(cleanValue) ||
                                        RegExp(r'^0\d{9,10}$').hasMatch(cleanValue) ||
                                        RegExp(r'^\d{8,11}$').hasMatch(cleanValue);

                          debugPrint('🔧 Phone validation: isValid=$isValid');
                          if (!isValid) {
                            return 'Please enter a valid Malaysian phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _alternatePhoneController,
                        label: 'Alternate Phone (Optional)',
                        hintText: 'Enter alternate phone number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (value != null && value.trim().isNotEmpty) {
                            final cleanValue = value.replaceAll(' ', '').replaceAll('-', '');
                            debugPrint('🔧 Alt Phone validation: Input="$value", Clean="$cleanValue"');

                            // Allow multiple formats (same as main phone)
                            bool isValid = RegExp(r'^\+60\d{9,10}$').hasMatch(cleanValue) ||
                                          RegExp(r'^0\d{9,10}$').hasMatch(cleanValue) ||
                                          RegExp(r'^\d{8,11}$').hasMatch(cleanValue);

                            debugPrint('🔧 Alt Phone validation: isValid=$isValid');
                            if (!isValid) {
                              return 'Please enter a valid Malaysian phone number';
                            }
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Address Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Address Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _streetController,
                        label: 'Street Address',
                        hintText: 'Enter street address',
                        maxLines: 2,
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
                              label: 'City',
                              hintText: 'Enter city',
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
                              controller: _postcodeController,
                              label: 'Postcode',
                              hintText: 'Enter postcode',
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Postcode is required';
                                }
                                if (!RegExp(r'^\d{5}$').hasMatch(value)) {
                                  return 'Invalid postcode';
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
                        label: 'State',
                        hintText: 'Enter state',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'State is required';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Additional Information
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Additional Information',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        title: const Text('Active Customer'),
                        subtitle: const Text('Enable to allow orders from this customer'),
                        value: _isActive,
                        onChanged: (value) {
                          setState(() {
                            _isActive = value;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _notesController,
                        label: 'Notes (Optional)',
                        hintText: 'Enter any additional notes',
                        maxLines: 3,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Customer not found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.pop(),
            child: const Text('Go Back'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading customer',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ref.invalidate(customerByIdProvider(widget.customerId));
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveCustomer() async {
    debugPrint('🔧 EditCustomerScreen: _saveCustomer() called');

    if (_formKey.currentState == null) {
      debugPrint('🔧 EditCustomerScreen: Form key is null');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      debugPrint('🔧 EditCustomerScreen: Form validation failed');
      return;
    }

    if (_originalCustomer == null) {
      debugPrint('🔧 EditCustomerScreen: Original customer is null');
      return;
    }

    debugPrint('🔧 EditCustomerScreen: Starting save process...');
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('🔧 EditCustomerScreen: Creating updated customer object...');
      final updatedCustomer = _originalCustomer!.copyWith(
        type: _selectedType,
        organizationName: _organizationNameController.text.trim(),
        contactPersonName: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        alternatePhoneNumber: _alternatePhoneController.text.trim().isNotEmpty
            ? _alternatePhoneController.text.trim()
            : null,
        address: CustomerAddress(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postcode: _postcodeController.text.trim(),
          country: _originalCustomer!.address.country,
          buildingName: _originalCustomer!.address.buildingName,
          floor: _originalCustomer!.address.floor,
          unit: _originalCustomer!.address.unit,
          deliveryInstructions: _originalCustomer!.address.deliveryInstructions,
          latitude: _originalCustomer!.address.latitude,
          longitude: _originalCustomer!.address.longitude,
        ),
        isActive: _isActive,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        updatedAt: DateTime.now(),
      );

      debugPrint('🔧 EditCustomerScreen: Updated customer: ${updatedCustomer.organizationName}');
      debugPrint('🔧 EditCustomerScreen: Calling provider updateCustomer...');

      final result = await ref.read(customerProvider.notifier).updateCustomer(updatedCustomer);

      debugPrint('🔧 EditCustomerScreen: Provider returned result: $result');

      if (mounted) {
        if (result != null) {
          debugPrint('🔧 EditCustomerScreen: Update successful, showing success message');

          // Additional cache invalidation to ensure all screens get fresh data
          debugPrint('🔧 EditCustomerScreen: Invalidating customerByIdProvider cache');
          ref.invalidate(customerByIdProvider(widget.customerId));

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Customer updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          context.pop(); // Go back to customer details
        } else {
          debugPrint('🔧 EditCustomerScreen: Update failed, showing error message');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to update customer. Please try again.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🔧 EditCustomerScreen: Exception caught: $e');
      debugPrint('🔧 EditCustomerScreen: Exception type: ${e.runtimeType}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      debugPrint('🔧 EditCustomerScreen: Save process completed, setting loading to false');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
