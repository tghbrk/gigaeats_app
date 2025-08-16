import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/vendor_profile_provider.dart';
import 'vendor_image_upload.dart';

class VendorProfileForm extends ConsumerStatefulWidget {
  final bool isEditing;
  final VoidCallback? onSaved;

  const VendorProfileForm({
    super.key,
    this.isEditing = false,
    this.onSaved,
  });

  @override
  ConsumerState<VendorProfileForm> createState() => _VendorProfileFormState();
}

class _VendorProfileFormState extends ConsumerState<VendorProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _businessNameController = TextEditingController();
  final _registrationNumberController = TextEditingController();
  final _addressController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _halalCertNumberController = TextEditingController();
  final _minimumOrderController = TextEditingController();
  final _deliveryFeeController = TextEditingController();
  final _freeDeliveryThresholdController = TextEditingController();

  final List<String> _businessTypes = [
    'Restaurant',
    'Cafe',
    'Fast Food',
    'Food Truck',
    'Catering',
    'Bakery',
    'Grocery Store',
    'Other',
  ];

  final List<String> _availableCuisines = [
    'Malaysian',
    'Chinese',
    'Indian',
    'Western',
    'Japanese',
    'Korean',
    'Thai',
    'Italian',
    'Mexican',
    'Middle Eastern',
    'Vegetarian',
    'Halal',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.isEditing) {
        ref.read(vendorProfileFormProvider.notifier).loadCurrentVendorProfile();
      }
    });
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _addressController.dispose();
    _descriptionController.dispose();
    _halalCertNumberController.dispose();
    _minimumOrderController.dispose();
    _deliveryFeeController.dispose();
    _freeDeliveryThresholdController.dispose();
    super.dispose();
  }

  void _updateControllersFromState(VendorProfileFormState state) {
    _businessNameController.text = state.businessName;
    _registrationNumberController.text = state.businessRegistrationNumber;
    _addressController.text = state.businessAddress;
    _descriptionController.text = state.description ?? '';
    _halalCertNumberController.text = state.halalCertificationNumber ?? '';
    _minimumOrderController.text = state.minimumOrderAmount?.toString() ?? '';
    _deliveryFeeController.text = state.deliveryFee?.toString() ?? '';
    _freeDeliveryThresholdController.text = state.freeDeliveryThreshold?.toString() ?? '';
  }

  String? _getValidBusinessType(String businessType) {
    if (businessType.isEmpty) return null;

    // Try exact match first
    if (_businessTypes.contains(businessType)) {
      return businessType;
    }

    // Try case-insensitive match
    final lowerType = businessType.toLowerCase();
    for (final type in _businessTypes) {
      if (type.toLowerCase() == lowerType) {
        return type;
      }
    }

    // If no match found, return null to avoid dropdown error
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(vendorProfileFormProvider);
    final notifier = ref.read(vendorProfileFormProvider.notifier);

    // Update controllers when state changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateControllersFromState(state);
    });

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error/Success Messages
          if (state.errorMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.errorMessage!,
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
            ),

          if (state.successMessage != null)
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.successMessage!,
                      style: TextStyle(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

          // Cover Image Upload
          VendorImageUpload(
            title: 'Cover Image',
            imageUrl: state.coverImageUrl,
            onImageSelected: (imageFile) {
              notifier.uploadCoverImage(imageFile);
            },
            isLoading: state.isSaving,
          ),

          const SizedBox(height: 24),

          // Basic Information Section
          _buildSectionHeader('Basic Information'),
          const SizedBox(height: 16),

          // Business Name
          TextFormField(
            controller: _businessNameController,
            decoration: const InputDecoration(
              labelText: 'Business Name *',
              hintText: 'Enter your business name',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Business name is required';
              }
              return null;
            },
            onChanged: notifier.updateBusinessName,
          ),

          const SizedBox(height: 16),

          // Business Registration Number
          TextFormField(
            controller: _registrationNumberController,
            decoration: const InputDecoration(
              labelText: 'Business Registration Number *',
              hintText: 'Enter SSM registration number',
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Business registration number is required';
              }
              return null;
            },
            onChanged: notifier.updateBusinessRegistrationNumber,
          ),

          const SizedBox(height: 16),

          // Business Type
          DropdownButtonFormField<String>(
            initialValue: _getValidBusinessType(state.businessType),
            decoration: const InputDecoration(
              labelText: 'Business Type *',
              border: OutlineInputBorder(),
            ),
            items: _businessTypes.map((type) {
              return DropdownMenuItem(
                value: type,
                child: Text(type),
              );
            }).toList(),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Business type is required';
              }
              return null;
            },
            onChanged: (value) {
              if (value != null) {
                notifier.updateBusinessType(value);
              }
            },
          ),

          const SizedBox(height: 16),

          // Business Address
          TextFormField(
            controller: _addressController,
            decoration: const InputDecoration(
              labelText: 'Business Address *',
              hintText: 'Enter complete business address',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Business address is required';
              }
              return null;
            },
            onChanged: notifier.updateBusinessAddress,
          ),

          const SizedBox(height: 16),

          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Describe your business (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: notifier.updateDescription,
          ),

          const SizedBox(height: 24),

          // Cuisine Types Section
          _buildSectionHeader('Cuisine Types'),
          const SizedBox(height: 16),

          _buildCuisineTypesSelector(state, notifier),

          const SizedBox(height: 24),

          // Halal Certification Section
          _buildSectionHeader('Halal Certification'),
          const SizedBox(height: 16),

          CheckboxListTile(
            title: const Text('Halal Certified'),
            subtitle: const Text('Check if your business is halal certified'),
            value: state.isHalalCertified,
            onChanged: (value) {
              notifier.updateIsHalalCertified(value ?? false);
            },
            controlAffinity: ListTileControlAffinity.leading,
          ),

          if (state.isHalalCertified) ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _halalCertNumberController,
              decoration: const InputDecoration(
                labelText: 'Halal Certification Number',
                hintText: 'Enter halal certification number',
                border: OutlineInputBorder(),
              ),
              onChanged: notifier.updateHalalCertificationNumber,
            ),
          ],

          const SizedBox(height: 24),

          // Service Areas Section
          _buildSectionHeader('Service Areas'),
          const SizedBox(height: 16),

          _buildServiceAreasEditor(state, notifier),
        ],
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

  Widget _buildCuisineTypesSelector(VendorProfileFormState state, VendorProfileFormNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select cuisine types that best describe your food *',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCuisines.map((cuisine) {
            final isSelected = state.cuisineTypes.contains(cuisine);
            return FilterChip(
              label: Text(cuisine),
              selected: isSelected,
              onSelected: (selected) {
                final updatedCuisines = List<String>.from(state.cuisineTypes);
                if (selected) {
                  updatedCuisines.add(cuisine);
                } else {
                  updatedCuisines.remove(cuisine);
                }
                notifier.updateCuisineTypes(updatedCuisines);
              },
            );
          }).toList(),
        ),
        if (state.cuisineTypes.isEmpty)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Please select at least one cuisine type',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildServiceAreasEditor(VendorProfileFormState state, VendorProfileFormNotifier notifier) {
    final serviceAreaController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Areas where you provide delivery service',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),

        // Add new service area
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: serviceAreaController,
                decoration: const InputDecoration(
                  hintText: 'Enter area name (e.g., Kuala Lumpur)',
                  border: OutlineInputBorder(),
                ),
                onFieldSubmitted: (value) {
                  if (value.trim().isNotEmpty && !state.serviceAreas.contains(value.trim())) {
                    final updatedAreas = [...state.serviceAreas, value.trim()];
                    notifier.updateServiceAreas(updatedAreas);
                    serviceAreaController.clear();
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final value = serviceAreaController.text.trim();
                if (value.isNotEmpty && !state.serviceAreas.contains(value)) {
                  final updatedAreas = [...state.serviceAreas, value];
                  notifier.updateServiceAreas(updatedAreas);
                  serviceAreaController.clear();
                }
              },
              icon: const Icon(Icons.add),
              tooltip: 'Add service area',
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Display current service areas
        if (state.serviceAreas.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: state.serviceAreas.map((area) {
              return Chip(
                label: Text(area),
                deleteIcon: const Icon(Icons.close, size: 18),
                onDeleted: () {
                  final updatedAreas = state.serviceAreas.where((a) => a != area).toList();
                  notifier.updateServiceAreas(updatedAreas);
                },
              );
            }).toList(),
          ),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Colors.grey),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Add service areas to let customers know where you deliver',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
