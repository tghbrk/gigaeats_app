import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user_management/domain/customer_profile.dart';
import '../../../../core/services/location_service.dart';
import '../../../core/utils/logger.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// Enhanced address form with GPS support and validation
class EnhancedAddressForm extends ConsumerStatefulWidget {
  final CustomerAddress? initialAddress;
  final ValueChanged<CustomerAddress> onAddressSaved;
  final VoidCallback? onCancel;
  final bool showGPSButton;
  final bool validateOnSave;

  const EnhancedAddressForm({
    super.key,
    this.initialAddress,
    required this.onAddressSaved,
    this.onCancel,
    this.showGPSButton = true,
    this.validateOnSave = true,
  });

  @override
  ConsumerState<EnhancedAddressForm> createState() => _EnhancedAddressFormState();
}

class _EnhancedAddressFormState extends ConsumerState<EnhancedAddressForm>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  // Form controllers
  final _labelController = TextEditingController();
  final _addressLine1Controller = TextEditingController();
  final _addressLine2Controller = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _postalCodeController = TextEditingController();
  final _instructionsController = TextEditingController();
  
  String _selectedAddressType = 'home';
  bool _isDefault = false;
  bool _isLoadingLocation = false;
  bool _isSaving = false;
  double? _latitude;
  double? _longitude;
  String? _locationError;
  
  final AppLogger _logger = AppLogger();

  // Malaysian states
  final List<String> _malaysianStates = [
    'Johor', 'Kedah', 'Kelantan', 'Kuala Lumpur', 'Labuan', 'Malacca',
    'Negeri Sembilan', 'Pahang', 'Penang', 'Perak', 'Perlis', 'Putrajaya',
    'Sabah', 'Sarawak', 'Selangor', 'Terengganu'
  ];

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    
    _initializeForm();
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _labelController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _initializeForm() {
    if (widget.initialAddress != null) {
      final address = widget.initialAddress!;
      _labelController.text = address.label;
      _addressLine1Controller.text = address.addressLine1;
      _addressLine2Controller.text = address.addressLine2 ?? '';
      _cityController.text = address.city;
      _stateController.text = address.state;
      _postalCodeController.text = address.postalCode;
      _instructionsController.text = address.deliveryInstructions ?? '';
      _selectedAddressType = 'home'; // Default since addressType doesn't exist in customer_profile version
      _isDefault = address.isDefault;
      _latitude = address.latitude;
      _longitude = address.longitude;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Stack(
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildHeader(theme),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildAddressTypeSection(theme),
                          const SizedBox(height: 16),
                          _buildBasicInfoSection(theme),
                          const SizedBox(height: 16),
                          _buildLocationSection(theme),
                          const SizedBox(height: 16),
                          _buildAdditionalInfoSection(theme),
                          const SizedBox(height: 16),
                          _buildOptionsSection(theme),
                          const SizedBox(height: 24),
                          _buildActionButtons(theme),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoadingLocation || _isSaving)
              LoadingOverlay(
                isLoading: _isLoadingLocation || _isSaving,
                message: _isLoadingLocation
                    ? 'Getting your location...'
                    : 'Saving address...',
                child: const SizedBox.shrink(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add_location,
              size: 20,
              color: theme.colorScheme.onPrimaryContainer,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.initialAddress != null ? 'Edit Address' : 'Add New Address',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (widget.onCancel != null)
            IconButton(
              onPressed: widget.onCancel,
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
  }

  Widget _buildAddressTypeSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Type',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildTypeChip(theme, 'home', 'Home', Icons.home),
            _buildTypeChip(theme, 'work', 'Work', Icons.business),
            _buildTypeChip(theme, 'hotel', 'Hotel', Icons.hotel),
            _buildTypeChip(theme, 'other', 'Other', Icons.location_on),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeChip(ThemeData theme, String value, String label, IconData icon) {
    final isSelected = _selectedAddressType == value;
    
    return FilterChip(
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedAddressType = value;
        });
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected 
            ? theme.colorScheme.onPrimaryContainer
            : theme.colorScheme.onSurfaceVariant,
      ),
      label: Text(label),
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      selectedColor: theme.colorScheme.primaryContainer,
      checkmarkColor: theme.colorScheme.onPrimaryContainer,
    );
  }

  Widget _buildBasicInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Address Details',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _labelController,
          label: 'Address Label',
          hintText: 'e.g., Home, Office, Mom\'s House',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter an address label';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _addressLine1Controller,
          label: 'Address Line 1 *',
          hintText: 'Street address, building name',
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter your address';
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _addressLine2Controller,
          label: 'Address Line 2',
          hintText: 'Unit number, floor (optional)',
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              flex: 2,
              child: CustomTextField(
                controller: _cityController,
                label: 'City *',
                hintText: 'City',
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter city';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CustomTextField(
                controller: _postalCodeController,
                label: 'Postal Code *',
                hintText: '50000',
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  if (value.length != 5) {
                    return 'Invalid';
                  }
                  return null;
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _stateController.text.isNotEmpty ? _stateController.text : null,
          decoration: const InputDecoration(
            labelText: 'State *',
            border: OutlineInputBorder(),
          ),
          items: _malaysianStates.map((state) {
            return DropdownMenuItem(
              value: state,
              child: Text(state),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _stateController.text = value;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a state';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildLocationSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Location',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            if (widget.showGPSButton)
              TextButton.icon(
                onPressed: _isLoadingLocation ? null : _getCurrentLocation,
                icon: Icon(
                  Icons.my_location,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                label: Text(
                  'Use GPS',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _latitude != null && _longitude != null
                ? theme.colorScheme.tertiaryContainer.withValues(alpha: 0.3)
                : theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: _latitude != null && _longitude != null
                  ? theme.colorScheme.tertiary.withValues(alpha: 0.3)
                  : theme.colorScheme.outline.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                _latitude != null && _longitude != null
                    ? Icons.location_on
                    : Icons.location_off,
                size: 16,
                color: _latitude != null && _longitude != null
                    ? theme.colorScheme.tertiary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _latitude != null && _longitude != null
                      ? 'Location: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}'
                      : 'No location set (GPS recommended for accurate delivery)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _latitude != null && _longitude != null
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_locationError != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 14,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _locationError!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAdditionalInfoSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Additional Information',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _instructionsController,
          label: 'Delivery Instructions',
          hintText: 'e.g., Ring the bell, Leave at door, Call when arrived',
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildOptionsSection(ThemeData theme) {
    return Column(
      children: [
        CheckboxListTile(
          value: _isDefault,
          onChanged: (value) {
            setState(() {
              _isDefault = value ?? false;
            });
          },
          title: Text(
            'Set as default address',
            style: theme.textTheme.bodyMedium,
          ),
          subtitle: Text(
            'This address will be selected automatically for future orders',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          controlAffinity: ListTileControlAffinity.leading,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        if (widget.onCancel != null)
          Expanded(
            child: CustomButton(
              text: 'Cancel',
              onPressed: widget.onCancel,
              variant: ButtonVariant.outlined,
            ),
          ),
        if (widget.onCancel != null) const SizedBox(width: 12),
        Expanded(
          child: CustomButton(
            text: widget.initialAddress != null ? 'Update Address' : 'Save Address',
            onPressed: _isSaving ? null : _saveAddress,
            variant: ButtonVariant.primary,
            isLoading: _isSaving,
          ),
        ),
      ],
    );
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });

    try {
      _logger.info('📍 [ADDRESS-FORM] Getting current location');

      final locationData = await LocationService.getCurrentLocation(includeAddress: true);
      
      if (locationData == null) {
        throw Exception('Unable to get your current location');
      }

      setState(() {
        _latitude = locationData.latitude;
        _longitude = locationData.longitude;
      });

      // Try to auto-fill address fields if we got address data
      if (locationData.address != null) {
        // This is a simplified implementation
        // In a real app, you'd parse the address more intelligently
        final addressParts = locationData.address!.split(', ');
        if (addressParts.isNotEmpty) {
          _addressLine1Controller.text = addressParts.first;
        }
      }

      _logger.info('✅ [ADDRESS-FORM] Location obtained successfully');

    } catch (e) {
      _logger.error('❌ [ADDRESS-FORM] Failed to get location', e);
      
      setState(() {
        _locationError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      _logger.info('💾 [ADDRESS-FORM] Saving address');

      final address = CustomerAddress(
        id: widget.initialAddress?.id,
        label: _labelController.text.trim(),
        addressLine1: _addressLine1Controller.text.trim(),
        addressLine2: _addressLine2Controller.text.trim().isNotEmpty
            ? _addressLine2Controller.text.trim()
            : null,
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        postalCode: _postalCodeController.text.trim(),
        country: 'Malaysia',
        deliveryInstructions: _instructionsController.text.trim().isNotEmpty
            ? _instructionsController.text.trim()
            : null,
        latitude: _latitude,
        longitude: _longitude,
        isDefault: _isDefault,
      );

      widget.onAddressSaved(address);

      _logger.info('✅ [ADDRESS-FORM] Address saved successfully');

    } catch (e) {
      _logger.error('❌ [ADDRESS-FORM] Failed to save address', e);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save address: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}
