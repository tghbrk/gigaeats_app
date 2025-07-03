import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// TODO: Restore unused import - commented out for analyzer cleanup
// import 'package:go_router/go_router.dart';
// TODO: Restore when customer_profile_provider is implemented
// import '../providers/customer_profile_provider.dart';
// TODO: Restore when auth_provider is implemented
// import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../../../../shared/widgets/custom_button.dart';
// TODO: Restore missing URI import when customer_profile domain is implemented
// import '../../../user_management/domain/customer_profile.dart';

class CustomerProfileSetupScreen extends ConsumerStatefulWidget {
  const CustomerProfileSetupScreen({super.key});

  @override
  ConsumerState<CustomerProfileSetupScreen> createState() => _CustomerProfileSetupScreenState();
}

class _CustomerProfileSetupScreenState extends ConsumerState<CustomerProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();

  String _selectedState = 'Selangor';
  bool _halalOnly = false;
  bool _vegetarianOptions = false;
  bool _isLoading = false;

  final List<String> _malaysianStates = [
    'Johor',
    'Kedah',
    'Kelantan',
    'Kuala Lumpur',
    'Labuan',
    'Malacca',
    'Negeri Sembilan',
    'Pahang',
    'Penang',
    'Perak',
    'Perlis',
    'Putrajaya',
    'Sabah',
    'Sarawak',
    'Selangor',
    'Terengganu',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFromAuth();
  }

  void _initializeFromAuth() {
    // TODO: Restore when authStateProvider is implemented
    // final authState = ref.read(authStateProvider);
    // if (authState.user != null) {
    //   _fullNameController.text = authState.user!.fullName;
    //   _phoneController.text = authState.user!.phoneNumber ?? '';
    // }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Your Profile'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildWelcomeSection(),
              const SizedBox(height: 32),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildAddressSection(),
              const SizedBox(height: 24),
              _buildPreferencesSection(),
              const SizedBox(height: 32),
              _buildSubmitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeSection() {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.restaurant,
            size: 48,
            color: theme.colorScheme.onPrimary,
          ),
          const SizedBox(height: 16),
          Text(
            'Welcome to GigaEats!',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: theme.colorScheme.onPrimary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Let\'s set up your profile to personalize your food ordering experience.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Personal Information',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _fullNameController,
          decoration: const InputDecoration(
            labelText: 'Full Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your full name';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(),
            hintText: '+60123456789',
          ),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your phone number';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAddressSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Default Delivery Address',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressLine1Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 1',
            prefixIcon: Icon(Icons.location_on),
            border: OutlineInputBorder(),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _addressLine2Controller,
          decoration: const InputDecoration(
            labelText: 'Address Line 2 (Optional)',
            prefixIcon: Icon(Icons.location_on_outlined),
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(
                  labelText: 'City',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: DropdownButtonFormField<String>(
                value: _selectedState,
                decoration: const InputDecoration(
                  labelText: 'State',
                  border: OutlineInputBorder(),
                ),
                items: _malaysianStates.map((state) => DropdownMenuItem(
                  value: state,
                  child: Text(state),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value!;
                  });
                },
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
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter postal code';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPreferencesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Food Preferences',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        SwitchListTile(
          title: const Text('Halal Only'),
          subtitle: const Text('Show only halal-certified restaurants'),
          value: _halalOnly,
          onChanged: (value) {
            setState(() {
              _halalOnly = value;
            });
          },
        ),
        SwitchListTile(
          title: const Text('Vegetarian Options'),
          subtitle: const Text('Prefer restaurants with vegetarian options'),
          value: _vegetarianOptions,
          onChanged: (value) {
            setState(() {
              _vegetarianOptions = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return CustomButton(
      text: 'Complete Setup',
      onPressed: _isLoading ? null : _submitProfile,
      // TODO: Restore when ButtonType is implemented
      // type: ButtonType.primary,
      isLoading: _isLoading,
      icon: Icons.check,
    );
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // TODO: Restore when authStateProvider is implemented
      // final authState = ref.read(authStateProvider);
      // if (authState.user == null) {
      //   throw Exception('User not authenticated');
      // }

      // Create default address
      // TODO: Restore when CustomerAddress class is implemented
      // final defaultAddress = CustomerAddress(
      //   label: 'Home',
      //   addressLine1: _addressLine1Controller.text.trim(),
      //   addressLine2: _addressLine2Controller.text.trim().isNotEmpty
      //       ? _addressLine2Controller.text.trim()
      //       : null,
      //   city: _cityController.text.trim(),
      //   state: _selectedState,
      //   postalCode: _postalCodeController.text.trim(),
      //   isDefault: true,
      // );
      // TODO: Use defaultAddress when customer creation is restored
      // final defaultAddress = {
      //   'label': 'Home',
      //   'addressLine1': _addressLine1Controller.text.trim(),
      //   'addressLine2': _addressLine2Controller.text.trim().isNotEmpty
      //       ? _addressLine2Controller.text.trim()
      //       : null,
      //   'city': _cityController.text.trim(),
      //   'state': _selectedState,
      //   'postalCode': _postalCodeController.text.trim(),
      //   'isDefault': true,
      // };

      // TODO: Restore when CustomerPreferences class is implemented
      // Create preferences
      // final preferences = CustomerPreferences(
      //   halalOnly: _halalOnly,
      //   vegetarianOptions: _vegetarianOptions,
      // );
      // TODO: Use preferences when customer creation is restored
      // final preferences = {
      //   'halalOnly': _halalOnly,
      //   'vegetarianOptions': _vegetarianOptions,
      // };

      // TODO: Restore when CustomerProfile class is implemented
      // Create customer profile
      // final profile = CustomerProfile(
      //   id: '', // Will be generated by database
      //   userId: authState.user!.id,
      //   fullName: _fullNameController.text.trim(),
      //   phoneNumber: _phoneController.text.trim(),
      //   addresses: [defaultAddress],
      //   preferences: preferences,
      //   createdAt: DateTime.now(),
      //   updatedAt: DateTime.now(),
      // );
      // TODO: Use profile when customer creation is restored
      // final profile = {
      //   'id': '', // Will be generated by database
      //   // TODO: Restore when authState is implemented
      //   'userId': 'placeholder-user-id', // authState.user!.id,
      //   'fullName': _fullNameController.text.trim(),
      //   'phoneNumber': _phoneController.text.trim(),
      //   'addresses': [defaultAddress],
      //   'preferences': preferences,
      //   'createdAt': DateTime.now(),
      //   'updatedAt': DateTime.now(),
      // };

      // TODO: Restore when customerProfileProvider.notifier is implemented
      // final success = await ref.read(customerProfileProvider.notifier).createProfile(profile);
      // TODO: Restore unused variable - commented out for analyzer cleanup
      // final success = false; // Placeholder

      // TODO: Restore dead code - commented out for analyzer cleanup
      // if (success) {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Profile setup completed successfully!'),
      //         backgroundColor: Colors.green,
      //       ),
      //     );
      //     context.go('/customer/dashboard');
      //   }
      // } else {
      //   if (mounted) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(
      //         content: Text('Failed to create profile. Please try again.'),
      //         backgroundColor: Colors.red,
      //       ),
      //     );
      //   }
      // }

      // Placeholder implementation
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile setup not implemented yet'),
            backgroundColor: Colors.orange,
          ),
        );
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
