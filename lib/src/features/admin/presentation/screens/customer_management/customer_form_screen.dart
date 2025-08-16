import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../user_management/domain/customer.dart';
import '../../../../user_management/presentation/providers/customer_provider.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../shared/widgets/custom_text_field.dart';
import '../../../../../shared/widgets/loading_widget.dart';


class CustomerFormScreen extends ConsumerStatefulWidget {
  final String? customerId; // null for create, non-null for edit

  const CustomerFormScreen({
    super.key,
    this.customerId,
  });

  @override
  ConsumerState<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends ConsumerState<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Basic Information Controllers
  final _organizationNameController = TextEditingController();
  final _contactPersonController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _alternatePhoneController = TextEditingController();
  
  // Address Controllers
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postcodeController = TextEditingController();
  final _buildingNameController = TextEditingController();
  final _floorController = TextEditingController();
  final _deliveryInstructionsController = TextEditingController();
  
  // Business Info Controllers
  final _companyRegController = TextEditingController();
  final _taxIdController = TextEditingController();
  final _industryController = TextEditingController();
  final _employeeCountController = TextEditingController();
  final _websiteController = TextEditingController();
  
  // Notes and Tags
  final _notesController = TextEditingController();
  final _tagsController = TextEditingController();
  
  CustomerType _selectedType = CustomerType.corporate;
  bool _isActive = true;
  bool _isVerified = false;
  bool _halalOnly = false;
  bool _vegetarianOptions = false;
  bool _requiresInvoice = false;
  
  List<String> _selectedCuisines = [];
  List<String> _dietaryRestrictions = [];
  List<String> _businessHours = [];
  
  bool _isLoading = false;
  Customer? _existingCustomer;

  @override
  void initState() {
    super.initState();
    if (widget.customerId != null) {
      _loadCustomer();
    }
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
    _buildingNameController.dispose();
    _floorController.dispose();
    _deliveryInstructionsController.dispose();
    _companyRegController.dispose();
    _taxIdController.dispose();
    _industryController.dispose();
    _employeeCountController.dispose();
    _websiteController.dispose();
    _notesController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomer() async {
    final customer = await ref.read(customerByIdProvider(widget.customerId!).future);
    if (customer != null) {
      setState(() {
        _existingCustomer = customer;
        _populateForm(customer);
      });
    }
  }

  void _populateForm(Customer customer) {
    _organizationNameController.text = customer.organizationName;
    _contactPersonController.text = customer.contactPersonName;
    _emailController.text = customer.email;
    _phoneController.text = customer.phoneNumber;
    _alternatePhoneController.text = customer.alternatePhoneNumber ?? '';
    
    // Address
    _streetController.text = customer.address.street;
    _cityController.text = customer.address.city;
    _stateController.text = customer.address.state;
    _postcodeController.text = customer.address.postcode;
    _buildingNameController.text = customer.address.buildingName ?? '';
    _floorController.text = customer.address.floor ?? '';
    _deliveryInstructionsController.text = customer.address.deliveryInstructions ?? '';
    
    // Business Info
    if (customer.businessInfo != null) {
      _companyRegController.text = customer.businessInfo!.companyRegistrationNumber ?? '';
      _taxIdController.text = customer.businessInfo!.taxId ?? '';
      _industryController.text = customer.businessInfo!.industry;
      _employeeCountController.text = customer.businessInfo!.employeeCount.toString();
      _websiteController.text = customer.businessInfo!.website ?? '';
      _businessHours = List.from(customer.businessInfo!.businessHours);
      _requiresInvoice = customer.businessInfo!.requiresInvoice;
    }
    
    // Other fields
    _selectedType = customer.type;
    _isActive = customer.isActive;
    _isVerified = customer.isVerified;
    _notesController.text = customer.notes ?? '';
    _tagsController.text = customer.tags.join(', ');
    
    // Preferences
    _selectedCuisines = List.from(customer.preferences.preferredCuisines);
    _dietaryRestrictions = List.from(customer.preferences.dietaryRestrictions);
    _halalOnly = customer.preferences.halalOnly;
    _vegetarianOptions = customer.preferences.vegetarianOptions;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.customerId != null;

    if (isEditing && _existingCustomer == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const LoadingWidget(message: 'Loading customer details...'),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Customer' : 'Add Customer'),
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
              onPressed: _saveCustomer,
              child: Text(
                isEditing ? 'Update' : 'Save',
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Basic Information
              _buildSectionHeader('Basic Information'),
              const SizedBox(height: 16),
              _buildBasicInfoForm(),
              
              const SizedBox(height: 24),
              
              // Address Information
              _buildSectionHeader('Address Information'),
              const SizedBox(height: 16),
              _buildAddressForm(),
              
              const SizedBox(height: 24),
              
              // Business Information
              _buildSectionHeader('Business Information'),
              const SizedBox(height: 16),
              _buildBusinessInfoForm(),
              
              const SizedBox(height: 24),
              
              // Preferences
              _buildSectionHeader('Preferences'),
              const SizedBox(height: 16),
              _buildPreferencesForm(),
              
              const SizedBox(height: 24),
              
              // Notes and Tags
              _buildSectionHeader('Notes & Tags'),
              const SizedBox(height: 16),
              _buildNotesAndTagsForm(),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveCustomer,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          isEditing ? 'Update Customer' : 'Create Customer',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 16),
            ],
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

  Widget _buildBasicInfoForm() {
    return Column(
      children: [
        // Customer Type
        DropdownButtonFormField<CustomerType>(
          initialValue: _selectedType,
          decoration: const InputDecoration(
            labelText: 'Customer Type *',
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
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _organizationNameController,
          label: 'Organization Name *',
          hintText: 'Enter company or organization name',
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
          label: 'Contact Person *',
          hintText: 'Enter contact person name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Contact person name is required';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _emailController,
          label: 'Email Address *',
          hintText: 'contact@company.com',
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Email address is required';
            }
            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
              return 'Please enter a valid email address';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _phoneController,
          label: 'Phone Number *',
          hintText: '+60123456789',
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Phone number is required';
            }
            return null;
          },
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _alternatePhoneController,
          label: 'Alternate Phone Number',
          hintText: '+60987654321',
          keyboardType: TextInputType.phone,
        ),
        
        const SizedBox(height: 16),
        
        // Status toggles
        Row(
          children: [
            Expanded(
              child: SwitchListTile(
                title: const Text('Active'),
                subtitle: const Text('Customer can place orders'),
                value: _isActive,
                onChanged: (value) {
                  setState(() {
                    _isActive = value;
                  });
                },
              ),
            ),
            Expanded(
              child: SwitchListTile(
                title: const Text('Verified'),
                subtitle: const Text('Customer is verified'),
                value: _isVerified,
                onChanged: (value) {
                  setState(() {
                    _isVerified = value;
                  });
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Column(
      children: [
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
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _postcodeController,
                label: 'Postcode *',
                hintText: '50000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Postcode is required';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _buildingNameController,
                label: 'Building Name',
                hintText: 'Menara ABC',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _floorController,
                label: 'Floor/Unit',
                hintText: 'Level 15, Unit A',
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _deliveryInstructionsController,
          label: 'Delivery Instructions',
          hintText: 'Special delivery instructions...',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildBusinessInfoForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _companyRegController,
          label: 'Company Registration Number',
          hintText: 'ROC123456789',
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _taxIdController,
          label: 'Tax ID',
          hintText: 'TAX987654321',
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _industryController,
          label: 'Industry',
          hintText: 'Information Technology',
        ),
        
        const SizedBox(height: 16),
        
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _employeeCountController,
                label: 'Employee Count',
                hintText: '150',
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CustomTextField(
                controller: _websiteController,
                label: 'Website',
                hintText: 'www.company.com',
                keyboardType: TextInputType.url,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        SwitchListTile(
          title: const Text('Requires Invoice'),
          subtitle: const Text('Customer requires formal invoicing'),
          value: _requiresInvoice,
          onChanged: (value) {
            setState(() {
              _requiresInvoice = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesForm() {
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Halal Only'),
          subtitle: const Text('Customer requires halal food only'),
          value: _halalOnly,
          onChanged: (value) {
            setState(() {
              _halalOnly = value;
            });
          },
        ),
        
        SwitchListTile(
          title: const Text('Vegetarian Options'),
          subtitle: const Text('Customer requires vegetarian options'),
          value: _vegetarianOptions,
          onChanged: (value) {
            setState(() {
              _vegetarianOptions = value;
            });
          },
        ),
        
        // TODO: Add cuisine preferences and dietary restrictions
        // This would require more complex UI components
      ],
    );
  }

  Widget _buildNotesAndTagsForm() {
    return Column(
      children: [
        CustomTextField(
          controller: _notesController,
          label: 'Notes',
          hintText: 'Additional notes about the customer...',
          maxLines: 4,
        ),
        
        const SizedBox(height: 16),
        
        CustomTextField(
          controller: _tagsController,
          label: 'Tags',
          hintText: 'VIP, Corporate, Regular (comma separated)',
        ),
      ],
    );
  }

  Future<void> _saveCustomer() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final authState = ref.read(authStateProvider);
      final salesAgentId = authState.user?.id ?? 'unknown';

      final address = CustomerAddress(
        street: _streetController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postcode: _postcodeController.text.trim(),
        buildingName: _buildingNameController.text.trim().isNotEmpty
            ? _buildingNameController.text.trim()
            : null,
        floor: _floorController.text.trim().isNotEmpty
            ? _floorController.text.trim()
            : null,
        deliveryInstructions: _deliveryInstructionsController.text.trim().isNotEmpty
            ? _deliveryInstructionsController.text.trim()
            : null,
      );

      final businessInfo = CustomerBusinessInfo(
        companyRegistrationNumber: _companyRegController.text.trim().isNotEmpty
            ? _companyRegController.text.trim()
            : null,
        taxId: _taxIdController.text.trim().isNotEmpty
            ? _taxIdController.text.trim()
            : null,
        industry: _industryController.text.trim().isNotEmpty
            ? _industryController.text.trim()
            : 'General',
        employeeCount: _employeeCountController.text.trim().isNotEmpty
            ? int.tryParse(_employeeCountController.text.trim()) ?? 1
            : 1,
        website: _websiteController.text.trim().isNotEmpty
            ? _websiteController.text.trim()
            : null,
        businessHours: _businessHours,
        requiresInvoice: _requiresInvoice,
      );

      final preferences = CustomerPreferences(
        preferredCuisines: _selectedCuisines,
        dietaryRestrictions: _dietaryRestrictions,
        halalOnly: _halalOnly,
        vegetarianOptions: _vegetarianOptions,
      );

      final tags = _tagsController.text.trim().isNotEmpty
          ? _tagsController.text.split(',').map((tag) => tag.trim()).toList()
          : <String>[];

      Customer? result;

      if (widget.customerId != null) {
        // Update existing customer
        final updatedCustomer = _existingCustomer!.copyWith(
          organizationName: _organizationNameController.text.trim(),
          contactPersonName: _contactPersonController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          alternatePhoneNumber: _alternatePhoneController.text.trim().isNotEmpty
              ? _alternatePhoneController.text.trim()
              : null,
          address: address,
          businessInfo: businessInfo,
          preferences: preferences,
          isActive: _isActive,
          isVerified: _isVerified,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          tags: tags,
          updatedAt: DateTime.now(),
        );
        result = await ref.read(customerProvider.notifier).updateCustomer(updatedCustomer);
      } else {
        // Create new customer
        final newCustomer = Customer(
          id: '', // Will be generated by the backend
          salesAgentId: salesAgentId,
          type: _selectedType,
          organizationName: _organizationNameController.text.trim(),
          contactPersonName: _contactPersonController.text.trim(),
          email: _emailController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          alternatePhoneNumber: _alternatePhoneController.text.trim().isNotEmpty
              ? _alternatePhoneController.text.trim()
              : null,
          address: address,
          businessInfo: businessInfo,
          preferences: preferences,
          isActive: _isActive,
          isVerified: _isVerified,
          notes: _notesController.text.trim().isNotEmpty
              ? _notesController.text.trim()
              : null,
          tags: tags,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        result = await ref.read(customerProvider.notifier).createCustomer(newCustomer);
      }

      if (result != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                widget.customerId != null
                    ? 'Customer updated successfully'
                    : 'Customer created successfully',
              ),
              backgroundColor: Colors.green,
            ),
          );
          context.pop();
        }
      } else {
        throw Exception('Failed to save customer');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
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
