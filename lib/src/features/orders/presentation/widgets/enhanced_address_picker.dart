import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../../user_management/domain/customer_profile.dart';
import '../../../user_management/presentation/providers/customer_address_provider.dart';
import '../../../../core/services/location_service.dart';
import '../../../core/utils/logger.dart';
import '../../../../shared/widgets/loading_overlay.dart';

/// Enhanced address picker with GPS support and validation
class EnhancedAddressPicker extends ConsumerStatefulWidget {
  final CustomerAddress? selectedAddress;
  final ValueChanged<CustomerAddress?> onAddressChanged;
  final bool allowCurrentLocation;
  final bool allowAddNew;
  final bool showValidation;
  final String? vendorId;
  final double? maxDeliveryRadius;

  const EnhancedAddressPicker({
    super.key,
    this.selectedAddress,
    required this.onAddressChanged,
    this.allowCurrentLocation = true,
    this.allowAddNew = true,
    this.showValidation = true,
    this.vendorId,
    this.maxDeliveryRadius,
  });

  @override
  ConsumerState<EnhancedAddressPicker> createState() => _EnhancedAddressPickerState();
}

class _EnhancedAddressPickerState extends ConsumerState<EnhancedAddressPicker>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  
  bool _isLoadingLocation = false;
  bool _isValidatingAddress = false;
  String? _validationError;
  final AppLogger _logger = AppLogger();

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
    
    // Load addresses and start animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerAddressesProvider.notifier).loadAddresses();
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final addressesState = ref.watch(customerAddressesProvider);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(theme),
                  const SizedBox(height: 16),
                  if (widget.allowCurrentLocation) ...[
                    _buildCurrentLocationOption(theme),
                    const SizedBox(height: 12),
                  ],
                  _buildAddressList(theme, addressesState),
                  if (widget.allowAddNew) ...[
                    const SizedBox(height: 12),
                    _buildAddNewAddressOption(theme),
                  ],
                  if (widget.showValidation && _validationError != null) ...[
                    const SizedBox(height: 12),
                    _buildValidationError(theme),
                  ],
                ],
              ),
            ),
            if (_isLoadingLocation || _isValidatingAddress)
              SimpleLoadingOverlay(
                message: _isLoadingLocation
                    ? 'Getting your location...'
                    : 'Validating address...',
                backgroundColor: Colors.transparent,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.location_on,
            size: 20,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Delivery Address',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'Choose where you\'d like your order delivered',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentLocationOption(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoadingLocation ? null : _useCurrentLocation,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.my_location,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Use Current Location',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'We\'ll detect your location automatically',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isLoadingLocation)
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.primary,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList(ThemeData theme, CustomerAddressesState addressesState) {
    if (addressesState.isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (addressesState.addresses.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(
              Icons.location_off,
              size: 32,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              'No saved addresses',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Add an address to get started',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: addressesState.addresses.map((address) {
        final isSelected = widget.selectedAddress?.id == address.id;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _buildAddressOption(theme, address, isSelected),
        );
      }).toList(),
    );
  }

  Widget _buildAddressOption(ThemeData theme, CustomerAddress address, bool isSelected) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
            : theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectAddress(address),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                        ? theme.colorScheme.primary
                        : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getAddressIcon(address.label),
                    size: 20,
                    color: isSelected 
                        ? theme.colorScheme.onPrimary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            address.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (address.isDefault) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Default',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        address.fullAddress,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: address.id ?? '',
                  groupValue: widget.selectedAddress?.id ?? '',
                  onChanged: (value) => _selectAddress(address),
                  activeColor: theme.colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddNewAddressOption(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _addNewAddress,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_location,
                    size: 20,
                    color: theme.colorScheme.onPrimary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add New Address',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Create a new delivery address',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildValidationError(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            size: 16,
            color: theme.colorScheme.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _validationError!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAddressIcon(String? addressType) {
    switch (addressType?.toLowerCase()) {
      case 'home':
        return Icons.home;
      case 'work':
      case 'office':
        return Icons.business;
      case 'hotel':
        return Icons.hotel;
      default:
        return Icons.location_on;
    }
  }

  void _selectAddress(CustomerAddress address) {
    _logger.info('📍 [ADDRESS-PICKER] Selected address: ${address.label}');
    
    widget.onAddressChanged(address);
    
    if (widget.showValidation) {
      _validateAddress(address);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _validationError = null;
    });

    try {
      _logger.info('📍 [ADDRESS-PICKER] Getting current location');

      final locationData = await LocationService.getCurrentLocation(includeAddress: true);
      
      if (locationData == null) {
        throw Exception('Unable to get your current location');
      }

      // Create a temporary address from current location
      final currentLocationAddress = CustomerAddress(
        id: 'current_location',
        label: 'Current Location',
        addressLine1: locationData.address ?? 'Current Location',
        city: 'Current Location',
        state: 'Current Location',
        postalCode: '00000',
        country: 'Malaysia',
        latitude: locationData.latitude,
        longitude: locationData.longitude,
        isDefault: false,
      );

      widget.onAddressChanged(currentLocationAddress);
      
      if (widget.showValidation) {
        await _validateAddress(currentLocationAddress);
      }

      _logger.info('✅ [ADDRESS-PICKER] Current location set successfully');

    } catch (e) {
      _logger.error('❌ [ADDRESS-PICKER] Failed to get current location', e);
      
      setState(() {
        _validationError = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to get location: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }

  void _addNewAddress() {
    _logger.info('🏠 [ADDRESS-PICKER] Opening add address dialog');
    // TODO: Navigate to add address screen or show dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add address functionality coming soon')),
    );
  }

  Future<void> _validateAddress(CustomerAddress address) async {
    if (!widget.showValidation || widget.vendorId == null) return;

    setState(() {
      _isValidatingAddress = true;
      _validationError = null;
    });

    try {
      _logger.info('🔍 [ADDRESS-PICKER] Validating address for delivery');

      // Simulate address validation
      await Future.delayed(const Duration(seconds: 1));

      // Check if address has coordinates
      if (address.latitude == null || address.longitude == null) {
        throw Exception('Address location not available for delivery validation');
      }

      // Check delivery radius if specified
      if (widget.maxDeliveryRadius != null) {
        // Mock vendor location (in real implementation, get from vendor service)
        const vendorLat = 3.1390;
        const vendorLng = 101.6869;
        
        final distance = Geolocator.distanceBetween(
          vendorLat,
          vendorLng,
          address.latitude!,
          address.longitude!,
        ) / 1000; // Convert to kilometers

        if (distance > widget.maxDeliveryRadius!) {
          throw Exception('Address is outside delivery area (${distance.toStringAsFixed(1)}km away)');
        }
      }

      _logger.info('✅ [ADDRESS-PICKER] Address validation successful');

    } catch (e) {
      _logger.warning('⚠️ [ADDRESS-PICKER] Address validation failed: $e');
      
      setState(() {
        _validationError = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isValidatingAddress = false;
        });
      }
    }
  }
}
