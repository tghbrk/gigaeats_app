import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/sales_agent_profile.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../../../../shared/widgets/loading_widget.dart';

class SalesAgentEditProfileScreen extends ConsumerStatefulWidget {
  final SalesAgentProfile profile;

  const SalesAgentEditProfileScreen({
    super.key,
    required this.profile,
  });

  @override
  ConsumerState<SalesAgentEditProfileScreen> createState() => _SalesAgentEditProfileScreenState();
}

class _SalesAgentEditProfileScreenState extends ConsumerState<SalesAgentEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late TextEditingController _fullNameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _companyNameController;
  late TextEditingController _businessRegistrationController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessTypeController;

  // Form state
  List<String> _selectedRegions = [];
  final List<String> _availableRegions = [
    'Kuala Lumpur',
    'Selangor',
    'Penang',
    'Johor',
    'Perak',
    'Kedah',
    'Kelantan',
    'Terengganu',
    'Pahang',
    'Negeri Sembilan',
    'Melaka',
    'Perlis',
    'Sabah',
    'Sarawak',
    'Putrajaya',
    'Labuan',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _fullNameController = TextEditingController(text: widget.profile.fullName);
    _phoneNumberController = TextEditingController(text: widget.profile.phoneNumber ?? '');
    _companyNameController = TextEditingController(text: widget.profile.companyName ?? '');
    _businessRegistrationController = TextEditingController(text: widget.profile.businessRegistrationNumber ?? '');
    _businessAddressController = TextEditingController(text: widget.profile.businessAddress ?? '');
    _businessTypeController = TextEditingController(text: widget.profile.businessType ?? '');
    
    _selectedRegions = List.from(widget.profile.assignedRegions);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _companyNameController.dispose();
    _businessRegistrationController.dispose();
    _businessAddressController.dispose();
    _businessTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(12.0),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : ElevatedButton(
                    onPressed: _saveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save'),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Updating profile...')
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Personal Information Section
                    _buildSectionHeader('Personal Information'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        labelText: 'Full Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Full name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _phoneNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        hintText: '+60123456789',
                      ),
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          // Basic phone validation for Malaysian numbers
                          if (!RegExp(r'^\+?60\d{8,10}$').hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
                            return 'Please enter a valid Malaysian phone number';
                          }
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 24),

                    // Employment Details Section
                    _buildSectionHeader('Employment Details'),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(
                        labelText: 'Company Name',
                        border: OutlineInputBorder(),
                        hintText: 'Your company or agency name',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessRegistrationController,
                      decoration: const InputDecoration(
                        labelText: 'Business Registration Number',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., SSM123456789',
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Business Address',
                        border: OutlineInputBorder(),
                        hintText: 'Your business address',
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Business Type',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Sales Agency, Food Distribution',
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Assigned Regions Section
                    _buildSectionHeader('Assigned Regions'),
                    const SizedBox(height: 16),
                    _buildRegionsSelector(),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
      floatingActionButton: _isLoading
          ? null
          : FloatingActionButton.extended(
              onPressed: _saveProfile,
              icon: const Icon(Icons.save),
              label: const Text('Save Profile'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
            ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildRegionsSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select regions you are assigned to:',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableRegions.map((region) {
            final isSelected = _selectedRegions.contains(region);
            return FilterChip(
              label: Text(region),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedRegions.add(region);
                  } else {
                    _selectedRegions.remove(region);
                  }
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final salesAgentRepository = ref.read(salesAgentRepositoryProvider);

      // Create updated profile
      final updatedProfile = widget.profile.copyWith(
        fullName: _fullNameController.text.trim(),
        phoneNumber: _phoneNumberController.text.trim().isEmpty 
            ? null 
            : _phoneNumberController.text.trim(),
        companyName: _companyNameController.text.trim().isEmpty 
            ? null 
            : _companyNameController.text.trim(),
        businessRegistrationNumber: _businessRegistrationController.text.trim().isEmpty 
            ? null 
            : _businessRegistrationController.text.trim(),
        businessAddress: _businessAddressController.text.trim().isEmpty 
            ? null 
            : _businessAddressController.text.trim(),
        businessType: _businessTypeController.text.trim().isEmpty 
            ? null 
            : _businessTypeController.text.trim(),
        assignedRegions: _selectedRegions,
      );

      await salesAgentRepository.updateSalesAgentProfile(updatedProfile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update profile: $e'),
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
