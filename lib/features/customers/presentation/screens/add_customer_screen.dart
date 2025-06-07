import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/customer.dart';
import '../providers/customer_provider.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../core/utils/responsive_utils.dart';

class AddCustomerScreen extends ConsumerStatefulWidget {
  const AddCustomerScreen({super.key});

  @override
  ConsumerState<AddCustomerScreen> createState() => _AddCustomerScreenState();
}

class _AddCustomerScreenState extends ConsumerState<AddCustomerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _organizationNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();

  CustomerType _selectedType = CustomerType.corporate;
  bool _isLoading = false;

  @override
  void dispose() {
    _organizationNameController.dispose();
    _contactPersonController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Customer'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveCustomer,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ResponsiveContainer(
          child: SingleChildScrollView(
            padding: context.responsivePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Information Section
                _buildSectionHeader('Basic Information'),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _organizationNameController,
                  label: 'Organization Name',
                  hintText: 'Enter organization name',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                    if (value == null || value.isEmpty) {
                      return 'Contact person is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Customer Type Dropdown
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
                ),
                const SizedBox(height: 24),
                
                // Contact Information Section
                _buildSectionHeader('Contact Information'),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _emailController,
                  label: 'Email',
                  hintText: 'Enter email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                    if (value == null || value.isEmpty) {
                      return 'Phone number is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                
                // Address Information Section
                _buildSectionHeader('Address Information'),
                const SizedBox(height: 16),
                
                CustomTextField(
                  controller: _streetController,
                  label: 'Street Address',
                  hintText: 'Enter street address',
                  validator: (value) {
                    if (value == null || value.isEmpty) {
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
                          if (value == null || value.isEmpty) {
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
                          if (value == null || value.isEmpty) {
                            return 'Postcode is required';
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
                    if (value == null || value.isEmpty) {
                      return 'State is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                
                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _saveCustomer,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Add Customer'),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
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

  Future<void> _saveCustomer() async {
    debugPrint('🚀 AddCustomerScreen: _saveCustomer called');

    if (!_formKey.currentState!.validate()) {
      debugPrint('❌ AddCustomerScreen: Form validation failed');
      return;
    }

    debugPrint('✅ AddCustomerScreen: Form validation passed');
    setState(() {
      _isLoading = true;
    });

    try {
      final customer = Customer(
        id: '', // Will be generated by the backend
        salesAgentId: '', // Will be set by the repository
        type: _selectedType,
        organizationName: _organizationNameController.text.trim(),
        contactPersonName: _contactPersonController.text.trim(),
        email: _emailController.text.trim(),
        phoneNumber: _phoneController.text.trim(),
        address: CustomerAddress(
          street: _streetController.text.trim(),
          city: _cityController.text.trim(),
          state: _stateController.text.trim(),
          postcode: _postcodeController.text.trim(),
        ),
        preferences: const CustomerPreferences(),
        lastOrderDate: null, // New customers haven't placed orders yet
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      debugPrint('📋 AddCustomerScreen: Customer object created');
      debugPrint('   Organization: ${customer.organizationName}');
      debugPrint('   Contact: ${customer.contactPersonName}');
      debugPrint('   Email: ${customer.email}');
      debugPrint('   Phone: ${customer.phoneNumber}');
      debugPrint('   Type: ${customer.type}');

      debugPrint('🔄 AddCustomerScreen: Calling customerProvider.createCustomer');
      final result = await ref.read(customerProvider.notifier).createCustomer(customer);
      debugPrint('📤 AddCustomerScreen: createCustomer returned: $result');

      if (result != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer added successfully')),
        );
        context.pop();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to add customer'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
