import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';

/// Service for validating delivery addresses
class AddressValidationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  /// Validate address for delivery
  Future<AddressValidationResult> validateAddress({
    required CustomerAddress address,
    required String vendorId,
    double? maxDeliveryRadius,
  }) async {
    try {
      _logger.info('🔍 [ADDRESS-VALIDATION] Validating address for vendor: $vendorId');

      final validationResults = <ValidationCheck>[];

      // Check 1: Basic address completeness
      final completenessCheck = _validateAddressCompleteness(address);
      validationResults.add(completenessCheck);

      // Check 2: GPS coordinates availability
      final coordinatesCheck = _validateCoordinates(address);
      validationResults.add(coordinatesCheck);

      // Check 3: Delivery area coverage
      if (address.latitude != null && address.longitude != null) {
        final coverageCheck = await _validateDeliveryArea(
          address,
          vendorId,
          maxDeliveryRadius,
        );
        validationResults.add(coverageCheck);
      }

      // Check 4: Address format validation
      final formatCheck = _validateAddressFormat(address);
      validationResults.add(formatCheck);

      // Check 5: Postal code validation
      final postalCodeCheck = _validatePostalCode(address);
      validationResults.add(postalCodeCheck);

      // Determine overall result
      final hasErrors = validationResults.any((check) => !check.isValid && check.severity == ValidationSeverity.error);
      final hasWarnings = validationResults.any((check) => !check.isValid && check.severity == ValidationSeverity.warning);

      final overallStatus = hasErrors 
          ? ValidationStatus.invalid
          : hasWarnings 
              ? ValidationStatus.warning
              : ValidationStatus.valid;

      final result = AddressValidationResult(
        status: overallStatus,
        checks: validationResults,
        isDeliverable: !hasErrors,
        estimatedDeliveryTime: _calculateEstimatedDeliveryTime(address, vendorId),
        deliveryFeeMultiplier: _calculateDeliveryFeeMultiplier(address, vendorId),
      );

      _logger.info('✅ [ADDRESS-VALIDATION] Validation completed: ${result.status}');
      return result;

    } catch (e) {
      _logger.error('❌ [ADDRESS-VALIDATION] Validation failed', e);
      
      return AddressValidationResult(
        status: ValidationStatus.error,
        checks: [
          ValidationCheck(
            type: ValidationType.system,
            isValid: false,
            severity: ValidationSeverity.error,
            message: 'Validation service error: ${e.toString()}',
          ),
        ],
        isDeliverable: false,
      );
    }
  }

  /// Validate multiple addresses in batch
  Future<Map<String, AddressValidationResult>> validateAddressBatch({
    required List<CustomerAddress> addresses,
    required String vendorId,
    double? maxDeliveryRadius,
  }) async {
    final results = <String, AddressValidationResult>{};

    for (final address in addresses) {
      if (address.id != null) {
        final result = await validateAddress(
          address: address,
          vendorId: vendorId,
          maxDeliveryRadius: maxDeliveryRadius,
        );
        results[address.id!] = result;
      }
    }

    return results;
  }

  /// Get delivery area boundaries for a vendor
  Future<DeliveryAreaInfo> getDeliveryAreaInfo(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendor_delivery_areas')
          .select('*')
          .eq('vendor_id', vendorId)
          .single();

      return DeliveryAreaInfo.fromJson(response);
    } catch (e) {
      _logger.warning('Failed to get delivery area info: $e');
      
      // Return default delivery area
      return DeliveryAreaInfo(
        vendorId: vendorId,
        maxRadius: 10.0,
        centerLatitude: 3.1390,
        centerLongitude: 101.6869,
        isActive: true,
      );
    }
  }

  ValidationCheck _validateAddressCompleteness(CustomerAddress address) {
    final missingFields = <String>[];

    if (address.addressLine1.trim().isEmpty) missingFields.add('Street address');
    if (address.city.trim().isEmpty) missingFields.add('City');
    if (address.state.trim().isEmpty) missingFields.add('State');
    if (address.postalCode.trim().isEmpty) missingFields.add('Postal code');

    if (missingFields.isEmpty) {
      return ValidationCheck(
        type: ValidationType.completeness,
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'Address is complete',
      );
    } else {
      return ValidationCheck(
        type: ValidationType.completeness,
        isValid: false,
        severity: ValidationSeverity.error,
        message: 'Missing required fields: ${missingFields.join(', ')}',
      );
    }
  }

  ValidationCheck _validateCoordinates(CustomerAddress address) {
    if (address.latitude != null && address.longitude != null) {
      // Validate coordinate ranges for Malaysia
      final lat = address.latitude!;
      final lng = address.longitude!;
      
      if (lat >= 0.8 && lat <= 7.5 && lng >= 99.0 && lng <= 119.5) {
        return ValidationCheck(
          type: ValidationType.coordinates,
          isValid: true,
          severity: ValidationSeverity.info,
          message: 'GPS coordinates available',
        );
      } else {
        return ValidationCheck(
          type: ValidationType.coordinates,
          isValid: false,
          severity: ValidationSeverity.error,
          message: 'GPS coordinates are outside Malaysia',
        );
      }
    } else {
      return ValidationCheck(
        type: ValidationType.coordinates,
        isValid: false,
        severity: ValidationSeverity.warning,
        message: 'GPS coordinates not available - delivery may be less accurate',
      );
    }
  }

  Future<ValidationCheck> _validateDeliveryArea(
    CustomerAddress address,
    String vendorId,
    double? maxDeliveryRadius,
  ) async {
    try {
      // Get vendor location (in real implementation, fetch from database)
      const vendorLat = 3.1390; // Mock vendor location
      const vendorLng = 101.6869;

      final distance = Geolocator.distanceBetween(
        vendorLat,
        vendorLng,
        address.latitude!,
        address.longitude!,
      ) / 1000; // Convert to kilometers

      final maxRadius = maxDeliveryRadius ?? 15.0; // Default 15km

      if (distance <= maxRadius) {
        return ValidationCheck(
          type: ValidationType.deliveryArea,
          isValid: true,
          severity: ValidationSeverity.info,
          message: 'Address is within delivery area (${distance.toStringAsFixed(1)}km)',
          metadata: {'distance': distance, 'maxRadius': maxRadius},
        );
      } else {
        return ValidationCheck(
          type: ValidationType.deliveryArea,
          isValid: false,
          severity: ValidationSeverity.error,
          message: 'Address is outside delivery area (${distance.toStringAsFixed(1)}km away, max ${maxRadius.toStringAsFixed(1)}km)',
          metadata: {'distance': distance, 'maxRadius': maxRadius},
        );
      }
    } catch (e) {
      return ValidationCheck(
        type: ValidationType.deliveryArea,
        isValid: false,
        severity: ValidationSeverity.warning,
        message: 'Unable to verify delivery area coverage',
      );
    }
  }

  ValidationCheck _validateAddressFormat(CustomerAddress address) {
    final issues = <String>[];

    // Check for common formatting issues
    if (address.addressLine1.length < 5) {
      issues.add('Street address seems too short');
    }

    if (address.city.length < 2) {
      issues.add('City name seems too short');
    }

    if (address.addressLine1.contains(RegExp(r'[^\w\s\-\.,#/]'))) {
      issues.add('Street address contains unusual characters');
    }

    if (issues.isEmpty) {
      return ValidationCheck(
        type: ValidationType.format,
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'Address format is valid',
      );
    } else {
      return ValidationCheck(
        type: ValidationType.format,
        isValid: false,
        severity: ValidationSeverity.warning,
        message: 'Format issues: ${issues.join(', ')}',
      );
    }
  }

  ValidationCheck _validatePostalCode(CustomerAddress address) {
    final postalCode = address.postalCode.trim();

    // Malaysian postal code validation (5 digits)
    if (RegExp(r'^\d{5}$').hasMatch(postalCode)) {
      return ValidationCheck(
        type: ValidationType.postalCode,
        isValid: true,
        severity: ValidationSeverity.info,
        message: 'Postal code format is valid',
      );
    } else {
      return ValidationCheck(
        type: ValidationType.postalCode,
        isValid: false,
        severity: ValidationSeverity.error,
        message: 'Invalid postal code format (should be 5 digits)',
      );
    }
  }

  int _calculateEstimatedDeliveryTime(CustomerAddress address, String vendorId) {
    // Base delivery time in minutes
    int baseTime = 30;

    // Add time based on distance if coordinates available
    if (address.latitude != null && address.longitude != null) {
      const vendorLat = 3.1390;
      const vendorLng = 101.6869;

      final distance = Geolocator.distanceBetween(
        vendorLat,
        vendorLng,
        address.latitude!,
        address.longitude!,
      ) / 1000;

      // Add 2 minutes per kilometer
      baseTime += (distance * 2).round();
    }

    return baseTime.clamp(15, 120); // Min 15 minutes, max 2 hours
  }

  double _calculateDeliveryFeeMultiplier(CustomerAddress address, String vendorId) {
    // Base multiplier
    double multiplier = 1.0;

    // Increase fee based on distance if coordinates available
    if (address.latitude != null && address.longitude != null) {
      const vendorLat = 3.1390;
      const vendorLng = 101.6869;

      final distance = Geolocator.distanceBetween(
        vendorLat,
        vendorLng,
        address.latitude!,
        address.longitude!,
      ) / 1000;

      // Increase fee by 10% for every 5km beyond 5km
      if (distance > 5.0) {
        multiplier += ((distance - 5.0) / 5.0) * 0.1;
      }
    }

    return multiplier.clamp(1.0, 2.0); // Max 2x multiplier
  }
}

/// Address validation result
class AddressValidationResult {
  final ValidationStatus status;
  final List<ValidationCheck> checks;
  final bool isDeliverable;
  final int? estimatedDeliveryTime;
  final double? deliveryFeeMultiplier;

  const AddressValidationResult({
    required this.status,
    required this.checks,
    required this.isDeliverable,
    this.estimatedDeliveryTime,
    this.deliveryFeeMultiplier,
  });

  List<ValidationCheck> get errors => checks.where((c) => !c.isValid && c.severity == ValidationSeverity.error).toList();
  List<ValidationCheck> get warnings => checks.where((c) => !c.isValid && c.severity == ValidationSeverity.warning).toList();
  List<ValidationCheck> get infos => checks.where((c) => c.isValid && c.severity == ValidationSeverity.info).toList();
}

/// Individual validation check
class ValidationCheck {
  final ValidationType type;
  final bool isValid;
  final ValidationSeverity severity;
  final String message;
  final Map<String, dynamic>? metadata;

  const ValidationCheck({
    required this.type,
    required this.isValid,
    required this.severity,
    required this.message,
    this.metadata,
  });
}

/// Delivery area information
class DeliveryAreaInfo {
  final String vendorId;
  final double maxRadius;
  final double centerLatitude;
  final double centerLongitude;
  final bool isActive;
  final List<String>? excludedPostalCodes;

  const DeliveryAreaInfo({
    required this.vendorId,
    required this.maxRadius,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.isActive,
    this.excludedPostalCodes,
  });

  factory DeliveryAreaInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryAreaInfo(
      vendorId: json['vendor_id'],
      maxRadius: (json['max_radius'] ?? 10.0).toDouble(),
      centerLatitude: (json['center_latitude'] ?? 3.1390).toDouble(),
      centerLongitude: (json['center_longitude'] ?? 101.6869).toDouble(),
      isActive: json['is_active'] ?? true,
      excludedPostalCodes: json['excluded_postal_codes']?.cast<String>(),
    );
  }
}

/// Validation enums
enum ValidationStatus { valid, warning, invalid, error }
enum ValidationType { completeness, coordinates, deliveryArea, format, postalCode, system }
enum ValidationSeverity { info, warning, error }
