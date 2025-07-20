import 'dart:math' as dart_math;
import 'package:flutter/foundation.dart';

import '../models/driver_order.dart';
import '../../../../core/utils/driver_workflow_logger.dart';

/// Service for handling mandatory confirmation steps in the driver workflow
/// Enforces pickup confirmation and delivery photo proof requirements
class MandatoryConfirmationService {
  
  /// Validate pickup confirmation requirements (Step 4: pickedUp)
  static ValidationResult validatePickupConfirmation({
    required DriverOrder order,
    required Map<String, dynamic> confirmationData,
  }) {
    final errors = <String>[];
    
    DriverWorkflowLogger.logValidation(
      validationType: 'Pickup Confirmation',
      isValid: true,
      orderId: order.id,
      context: 'MANDATORY_SERVICE',
      reason: 'Starting pickup validation',
    );

    // 1. Verify location proximity (if GPS data available)
    if (confirmationData.containsKey('driver_location')) {
      final locationValidation = _validateLocationProximity(
        driverLocation: confirmationData['driver_location'],
        targetLocation: confirmationData['vendor_location'],
        threshold: 100, // 100 meters
        locationType: 'vendor',
      );
      if (!locationValidation.isValid) {
        errors.add(locationValidation.error!);
      }
    }

    // 2. Validate verification checklist
    final checklist = confirmationData['verification_checklist'] as Map<String, dynamic>?;
    if (checklist == null || checklist.isEmpty) {
      errors.add('Pickup verification checklist is required');
    } else {
      final checklistValidation = _validatePickupChecklist(checklist);
      if (!checklistValidation.isValid) {
        errors.add(checklistValidation.error!);
      }
    }

    // 3. Validate order number confirmation
    final confirmedOrderNumber = confirmationData['confirmed_order_number'] as String?;
    if (confirmedOrderNumber == null || confirmedOrderNumber.isEmpty) {
      errors.add('Order number confirmation is required');
    } else if (confirmedOrderNumber != order.orderNumber) {
      errors.add('Confirmed order number does not match the actual order number');
    }

    // 4. Validate restaurant staff confirmation (optional but recommended)
    final staffConfirmation = confirmationData['staff_confirmation'] as bool?;
    if (staffConfirmation != true) {
      DriverWorkflowLogger.logValidation(
        validationType: 'Staff Confirmation',
        isValid: false,
        orderId: order.id,
        context: 'MANDATORY_SERVICE',
        reason: 'Staff confirmation not provided (recommended)',
      );
    }

    // 5. Validate pickup timestamp
    final pickupTimestamp = confirmationData['pickup_timestamp'] as String?;
    if (pickupTimestamp == null) {
      errors.add('Pickup timestamp is required');
    } else {
      final timestampValidation = _validateTimestamp(pickupTimestamp);
      if (!timestampValidation.isValid) {
        errors.add(timestampValidation.error!);
      }
    }

    final isValid = errors.isEmpty;
    DriverWorkflowLogger.logValidation(
      validationType: 'Pickup Confirmation',
      isValid: isValid,
      orderId: order.id,
      context: 'MANDATORY_SERVICE',
      reason: isValid ? 'All pickup requirements met' : 'Validation errors: ${errors.join(', ')}',
    );

    return isValid 
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors.join('; '));
  }

  /// Validate delivery confirmation requirements (Step 7: delivered)
  static ValidationResult validateDeliveryConfirmation({
    required DriverOrder order,
    required Map<String, dynamic> confirmationData,
  }) {
    final errors = <String>[];
    
    DriverWorkflowLogger.logValidation(
      validationType: 'Delivery Confirmation',
      isValid: true,
      orderId: order.id,
      context: 'MANDATORY_SERVICE',
      reason: 'Starting delivery validation',
    );

    // 1. Verify location proximity (if GPS data available)
    if (confirmationData.containsKey('driver_location')) {
      final locationValidation = _validateLocationProximity(
        driverLocation: confirmationData['driver_location'],
        targetLocation: confirmationData['customer_location'],
        threshold: 50, // 50 meters for delivery
        locationType: 'customer',
      );
      if (!locationValidation.isValid) {
        errors.add(locationValidation.error!);
      }
    }

    // 2. Validate photo proof (MANDATORY)
    final photoUrl = confirmationData['delivery_photo_url'] as String?;
    if (photoUrl == null || photoUrl.isEmpty) {
      errors.add('Delivery photo proof is mandatory');
    } else {
      final photoValidation = _validateDeliveryPhoto(photoUrl);
      if (!photoValidation.isValid) {
        errors.add(photoValidation.error!);
      }
    }

    // 3. Validate recipient information
    final recipientName = confirmationData['recipient_name'] as String?;
    if (recipientName == null || recipientName.trim().isEmpty) {
      errors.add('Recipient name is required');
    }

    // 4. Validate delivery notes (optional but recommended)
    final deliveryNotes = confirmationData['delivery_notes'] as String?;
    if (deliveryNotes != null && deliveryNotes.length > 500) {
      errors.add('Delivery notes cannot exceed 500 characters');
    }

    // 5. Validate customer signature (if required)
    final requiresSignature = confirmationData['requires_signature'] as bool? ?? false;
    if (requiresSignature) {
      final signatureUrl = confirmationData['signature_url'] as String?;
      if (signatureUrl == null || signatureUrl.isEmpty) {
        errors.add('Customer signature is required for this delivery');
      }
    }

    // 6. Validate delivery timestamp
    final deliveryTimestamp = confirmationData['delivery_timestamp'] as String?;
    if (deliveryTimestamp == null) {
      errors.add('Delivery timestamp is required');
    } else {
      final timestampValidation = _validateTimestamp(deliveryTimestamp);
      if (!timestampValidation.isValid) {
        errors.add(timestampValidation.error!);
      }
    }

    // 7. Validate delivery address confirmation
    final confirmedAddress = confirmationData['confirmed_delivery_address'] as String?;
    if (confirmedAddress != null && confirmedAddress != order.deliveryAddress) {
      DriverWorkflowLogger.logValidation(
        validationType: 'Address Confirmation',
        isValid: false,
        orderId: order.id,
        context: 'MANDATORY_SERVICE',
        reason: 'Delivery address mismatch detected',
      );
    }

    final isValid = errors.isEmpty;
    DriverWorkflowLogger.logValidation(
      validationType: 'Delivery Confirmation',
      isValid: isValid,
      orderId: order.id,
      context: 'MANDATORY_SERVICE',
      reason: isValid ? 'All delivery requirements met' : 'Validation errors: ${errors.join(', ')}',
    );

    return isValid 
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors.join('; '));
  }

  /// Validate location proximity
  static ValidationResult _validateLocationProximity({
    required Map<String, dynamic> driverLocation,
    required Map<String, dynamic>? targetLocation,
    required double threshold,
    required String locationType,
  }) {
    if (targetLocation == null) {
      return ValidationResult.invalid('Target $locationType location not available');
    }

    try {
      final driverLat = driverLocation['latitude'] as double;
      final driverLng = driverLocation['longitude'] as double;
      final targetLat = targetLocation['latitude'] as double;
      final targetLng = targetLocation['longitude'] as double;

      final distance = _calculateDistance(driverLat, driverLng, targetLat, targetLng);
      
      if (distance > threshold) {
        return ValidationResult.invalid(
          'You must be within ${threshold}m of the $locationType location. Current distance: ${distance.toStringAsFixed(0)}m'
        );
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Invalid location data provided');
    }
  }

  /// Validate pickup verification checklist
  static ValidationResult _validatePickupChecklist(Map<String, dynamic> checklist) {
    final requiredItems = [
      'order_number_verified',
      'all_items_present',
      'items_properly_packaged',
    ];

    final missingItems = <String>[];
    for (final item in requiredItems) {
      if (checklist[item] != true) {
        missingItems.add(item.replaceAll('_', ' '));
      }
    }

    if (missingItems.isNotEmpty) {
      return ValidationResult.invalid(
        'Required verification items not confirmed: ${missingItems.join(', ')}'
      );
    }

    return ValidationResult.valid();
  }

  /// Validate delivery photo
  static ValidationResult _validateDeliveryPhoto(String photoUrl) {
    // Basic URL validation
    if (!photoUrl.startsWith('http')) {
      return ValidationResult.invalid('Invalid photo URL format');
    }

    // Check for common image extensions
    final validExtensions = ['.jpg', '.jpeg', '.png', '.webp'];
    final hasValidExtension = validExtensions.any((ext) => 
        photoUrl.toLowerCase().contains(ext));
    
    if (!hasValidExtension) {
      return ValidationResult.invalid('Photo must be a valid image file');
    }

    return ValidationResult.valid();
  }

  /// Validate timestamp
  static ValidationResult _validateTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      
      // Check if timestamp is not in the future
      if (dateTime.isAfter(now)) {
        return ValidationResult.invalid('Timestamp cannot be in the future');
      }

      // Check if timestamp is not too old (e.g., more than 24 hours ago)
      final age = now.difference(dateTime);
      if (age.inHours > 24) {
        return ValidationResult.invalid('Timestamp is too old (more than 24 hours)');
      }

      return ValidationResult.valid();
    } catch (e) {
      return ValidationResult.invalid('Invalid timestamp format');
    }
  }

  /// Calculate distance between two coordinates (Haversine formula)
  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() *
        (dLng / 2).sin() * (dLng / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  /// Convert degrees to radians
  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? error;

  ValidationResult._(this.isValid, this.error);

  factory ValidationResult.valid() => ValidationResult._(true, null);
  factory ValidationResult.invalid(String error) => ValidationResult._(false, error);
}

/// Extension methods for math operations
extension MathExtensions on double {
  double sin() => dart_math.sin(this);
  double cos() => dart_math.cos(this);
  double asin() => dart_math.asin(this);
  double sqrt() => dart_math.sqrt(this);
}
