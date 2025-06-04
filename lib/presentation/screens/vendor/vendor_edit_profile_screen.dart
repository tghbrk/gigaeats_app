import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/vendor.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/loading_widget.dart';

class VendorEditProfileScreen extends ConsumerStatefulWidget {
  final Vendor vendor;

  const VendorEditProfileScreen({
    super.key,
    required this.vendor,
  });

  @override
  ConsumerState<VendorEditProfileScreen> createState() => _VendorEditProfileScreenState();
}

class _VendorEditProfileScreenState extends ConsumerState<VendorEditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Form controllers
  late TextEditingController _businessNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _businessRegistrationController;
  late TextEditingController _businessAddressController;
  late TextEditingController _businessTypeController;
  late TextEditingController _halalCertNumberController;
  late TextEditingController _minimumOrderController;
  late TextEditingController _deliveryFeeController;
  late TextEditingController _freeDeliveryThresholdController;

  // Form state
  bool _isHalalCertified = false;
  bool _isActive = true;
  List<String> _selectedCuisineTypes = [];

  // Operating hours
  Map<String, DaySchedule> _operatingHours = {
    'monday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
    'tuesday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
    'wednesday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
    'thursday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
    'friday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
    'saturday': const DaySchedule(isOpen: true, openTime: '09:00', closeTime: '18:00'),
    'sunday': const DaySchedule(isOpen: false),
  };

  // Available cuisine types
  final List<String> _availableCuisineTypes = [
    'Malaysian',
    'Chinese',
    'Indian',
    'Western',
    'Japanese',
    'Korean',
    'Thai',
    'Vietnamese',
    'Italian',
    'Mexican',
    'Middle Eastern',
    'Fusion',
  ];

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _businessNameController = TextEditingController(text: widget.vendor.businessName);
    _descriptionController = TextEditingController(text: widget.vendor.description ?? '');
    _businessRegistrationController = TextEditingController(text: widget.vendor.businessRegistrationNumber);
    _businessAddressController = TextEditingController(text: widget.vendor.businessAddress);
    _businessTypeController = TextEditingController(text: widget.vendor.businessType);
    _halalCertNumberController = TextEditingController(text: widget.vendor.halalCertificationNumber ?? '');
    _minimumOrderController = TextEditingController(text: widget.vendor.minimumOrderAmount?.toString() ?? '');
    _deliveryFeeController = TextEditingController(text: widget.vendor.deliveryFee?.toString() ?? '');
    _freeDeliveryThresholdController = TextEditingController(text: widget.vendor.freeDeliveryThreshold?.toString() ?? '');

    _isHalalCertified = widget.vendor.isHalalCertified;
    _isActive = widget.vendor.isActive;
    _selectedCuisineTypes = List.from(widget.vendor.cuisineTypes);

    // Initialize operating hours from vendor data
    _operatingHours = Map.from(widget.vendor.businessInfo.operatingHours.schedule);
    debugPrint('🕐 Operating hours loaded from vendor: $_operatingHours');
    debugPrint('🕐 Raw business hours from vendor: ${widget.vendor.businessHours}');
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _descriptionController.dispose();
    _businessRegistrationController.dispose();
    _businessAddressController.dispose();
    _businessTypeController.dispose();
    _halalCertNumberController.dispose();
    _minimumOrderController.dispose();
    _deliveryFeeController.dispose();
    _freeDeliveryThresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    // Business Information Section
                    _buildSectionHeader('Business Information'),
                    const SizedBox(height: 16),
                    
                    TextFormField(
                      controller: _businessNameController,
                      decoration: const InputDecoration(
                        labelText: 'Business Name *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                        hintText: 'Tell customers about your business...',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessRegistrationController,
                      decoration: const InputDecoration(
                        labelText: 'Business Registration Number *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., 123456-A',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business registration number is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessAddressController,
                      decoration: const InputDecoration(
                        labelText: 'Business Address *',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business address is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _businessTypeController,
                      decoration: const InputDecoration(
                        labelText: 'Business Type *',
                        border: OutlineInputBorder(),
                        hintText: 'e.g., Restaurant, Cafe, Food Truck',
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Business type is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Cuisine Types Section
                    _buildSectionHeader('Cuisine Types'),
                    const SizedBox(height: 16),
                    _buildCuisineTypeSelector(),
                    const SizedBox(height: 24),

                    // Halal Certification Section
                    _buildSectionHeader('Halal Certification'),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Halal Certified'),
                      subtitle: const Text('Is your business halal certified?'),
                      value: _isHalalCertified,
                      onChanged: (value) {
                        setState(() {
                          _isHalalCertified = value;
                        });
                      },
                    ),

                    if (_isHalalCertified) ...[
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _halalCertNumberController,
                        decoration: const InputDecoration(
                          labelText: 'Halal Certification Number',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Operating Hours Section
                    _buildSectionHeader('Operating Hours'),
                    const SizedBox(height: 16),
                    _buildOperatingHoursEditor(),
                    const SizedBox(height: 24),

                    // Order Settings Section
                    _buildSectionHeader('Order Settings'),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _minimumOrderController,
                      decoration: const InputDecoration(
                        labelText: 'Minimum Order Amount (RM)',
                        border: OutlineInputBorder(),
                        prefixText: 'RM ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = double.tryParse(value);
                          if (amount == null || amount < 0) {
                            return 'Please enter a valid amount';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _deliveryFeeController,
                      decoration: const InputDecoration(
                        labelText: 'Delivery Fee (RM)',
                        border: OutlineInputBorder(),
                        prefixText: 'RM ',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = double.tryParse(value);
                          if (amount == null || amount < 0) {
                            return 'Please enter a valid amount';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _freeDeliveryThresholdController,
                      decoration: const InputDecoration(
                        labelText: 'Free Delivery Threshold (RM)',
                        border: OutlineInputBorder(),
                        prefixText: 'RM ',
                        hintText: 'Minimum order for free delivery',
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value != null && value.isNotEmpty) {
                          final amount = double.tryParse(value);
                          if (amount == null || amount < 0) {
                            return 'Please enter a valid amount';
                          }
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Status Section
                    _buildSectionHeader('Status'),
                    const SizedBox(height: 16),
                    
                    SwitchListTile(
                      title: const Text('Active'),
                      subtitle: const Text('Accept new orders'),
                      value: _isActive,
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),

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

  Widget _buildCuisineTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select cuisine types that best describe your food:',
          style: TextStyle(color: Colors.grey),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _availableCuisineTypes.map((cuisine) {
            final isSelected = _selectedCuisineTypes.contains(cuisine);
            return FilterChip(
              label: Text(cuisine),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    _selectedCuisineTypes.add(cuisine);
                  } else {
                    _selectedCuisineTypes.remove(cuisine);
                  }
                });
              },
            );
          }).toList(),
        ),
        if (_selectedCuisineTypes.isEmpty)
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

  Widget _buildOperatingHoursEditor() {
    final dayNames = {
      'monday': 'Monday',
      'tuesday': 'Tuesday',
      'wednesday': 'Wednesday',
      'thursday': 'Thursday',
      'friday': 'Friday',
      'saturday': 'Saturday',
      'sunday': 'Sunday',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Set your business operating hours:',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            ...dayNames.entries.map((entry) {
              final dayKey = entry.key;
              final dayName = entry.value;
              final schedule = _operatingHours[dayKey] ?? const DaySchedule(isOpen: false);

              return _buildDayScheduleEditor(dayKey, dayName, schedule);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildDayScheduleEditor(String dayKey, String dayName, DaySchedule schedule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 100,
                child: Text(
                  dayName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Switch(
                value: schedule.safeIsOpen,
                onChanged: (isOpen) {
                  setState(() {
                    _operatingHours[dayKey] = DaySchedule(
                      isOpen: isOpen,
                      openTime: isOpen ? (schedule.openTime ?? '09:00') : null,
                      closeTime: isOpen ? (schedule.closeTime ?? '18:00') : null,
                    );
                  });
                },
              ),
              const SizedBox(width: 8),
              Text(
                schedule.safeIsOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  color: schedule.safeIsOpen ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (schedule.safeIsOpen) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const SizedBox(width: 100),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Open',
                    time: schedule.openTime ?? '09:00',
                    onTimeChanged: (time) {
                      setState(() {
                        _operatingHours[dayKey] = DaySchedule(
                          isOpen: true,
                          openTime: time,
                          closeTime: schedule.closeTime,
                        );
                      });
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildTimeSelector(
                    label: 'Close',
                    time: schedule.closeTime ?? '18:00',
                    onTimeChanged: (time) {
                      setState(() {
                        _operatingHours[dayKey] = DaySchedule(
                          isOpen: true,
                          openTime: schedule.openTime,
                          closeTime: time,
                        );
                      });
                    },
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeSelector({
    required String label,
    required String time,
    required Function(String) onTimeChanged,
  }) {
    return InkWell(
      onTap: () async {
        final TimeOfDay? picked = await showTimePicker(
          context: context,
          initialTime: TimeOfDay(
            hour: int.parse(time.split(':')[0]),
            minute: int.parse(time.split(':')[1]),
          ),
        );
        if (picked != null) {
          final formattedTime = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
          onTimeChanged(formattedTime);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('$label: $time'),
            const Icon(Icons.access_time, size: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedCuisineTypes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one cuisine type'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final vendorRepository = ref.read(vendorRepositoryProvider);

      // Convert operating hours to proper JSON format
      final businessHoursJson = <String, dynamic>{};
      for (final entry in _operatingHours.entries) {
        businessHoursJson[entry.key] = entry.value.toJson();
      }

      debugPrint('🕐 Operating hours being saved: $businessHoursJson');

      // Prepare update data
      final updateData = <String, dynamic>{
        'business_name': _businessNameController.text.trim(),
        'description': _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        'business_registration_number': _businessRegistrationController.text.trim(),
        'business_address': _businessAddressController.text.trim(),
        'business_type': _businessTypeController.text.trim(),
        'cuisine_types': _selectedCuisineTypes,
        'is_halal_certified': _isHalalCertified,
        'halal_certification_number': _isHalalCertified && _halalCertNumberController.text.trim().isNotEmpty
            ? _halalCertNumberController.text.trim()
            : null,
        'is_active': _isActive,
        'business_hours': businessHoursJson,
      };

      // Add optional numeric fields
      if (_minimumOrderController.text.trim().isNotEmpty) {
        updateData['minimum_order_amount'] = double.parse(_minimumOrderController.text.trim());
      }
      if (_deliveryFeeController.text.trim().isNotEmpty) {
        updateData['delivery_fee'] = double.parse(_deliveryFeeController.text.trim());
      }
      if (_freeDeliveryThresholdController.text.trim().isNotEmpty) {
        updateData['free_delivery_threshold'] = double.parse(_freeDeliveryThresholdController.text.trim());
      }

      await vendorRepository.updateVendorProfile(widget.vendor.id, updateData);

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
