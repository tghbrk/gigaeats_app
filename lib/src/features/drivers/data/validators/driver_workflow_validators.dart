import 'dart:math' as dart_math;

import 'package:image_picker/image_picker.dart';

import '../../../drivers/data/models/driver_order.dart';
import '../../../orders/data/models/driver_order_state_machine.dart';

/// Comprehensive client-side validation utilities for driver workflow operations
class DriverWorkflowValidators {
  
  /// Validate order status transition with business rules
  static ValidationResult validateOrderStatusTransition({
    required DriverOrder order,
    required DriverOrderStatus targetStatus,
    Map<String, dynamic>? additionalData,
  }) {
    final errors = <String>[];

    // Basic state machine validation
    final stateValidation = DriverOrderStateMachine.validateTransition(
      order.status,
      targetStatus,
    );
    
    if (!stateValidation.isValid) {
      errors.add(stateValidation.errorMessage!);
    }

    // Business rule validations
    switch (targetStatus) {
      case DriverOrderStatus.onRouteToVendor:
        if (!_validateNavigationStart(order, isToVendor: true)) {
          errors.add('Cannot start navigation: Invalid vendor location');
        }
        break;

      case DriverOrderStatus.arrivedAtVendor:
        if (!_validateVendorArrival(order)) {
          errors.add('Cannot mark arrived: You must be near the restaurant location');
        }
        break;

      case DriverOrderStatus.pickedUp:
        final pickupValidation = _validatePickupConfirmation(order, additionalData);
        if (!pickupValidation.isValid) {
          errors.add(pickupValidation.errorMessage!);
        }
        break;

      case DriverOrderStatus.onRouteToCustomer:
        if (!_validateNavigationStart(order, isToVendor: false)) {
          errors.add('Cannot start delivery: Invalid customer location');
        }
        break;

      case DriverOrderStatus.arrivedAtCustomer:
        if (!_validateCustomerArrival(order)) {
          errors.add('Cannot mark arrived: You must be near the customer location');
        }
        break;

      case DriverOrderStatus.delivered:
        final deliveryValidation = _validateDeliveryConfirmation(order, additionalData);
        if (!deliveryValidation.isValid) {
          errors.add(deliveryValidation.errorMessage!);
        }
        break;

      default:
        break;
    }

    return errors.isEmpty 
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors.join('; '));
  }

  /// Validate pickup confirmation data
  static ValidationResult validatePickupConfirmationData({
    required Map<String, bool> verificationChecklist,
    String? notes,
  }) {
    final errors = <String>[];

    // Check that checklist is not empty
    if (verificationChecklist.isEmpty) {
      errors.add('Verification checklist cannot be empty');
    }

    // Check that at least 80% of items are verified
    final totalItems = verificationChecklist.length;
    final verifiedItems = verificationChecklist.values.where((verified) => verified).length;
    
    if (totalItems > 0 && (verifiedItems / totalItems) < 0.8) {
      errors.add('At least 80% of verification items must be completed ($verifiedItems/$totalItems completed)');
    }

    // Check for critical items that must be verified
    final criticalItems = [
      'Order number matches',
      'All items are present',
      'Items are properly packaged',
    ];

    for (final criticalItem in criticalItems) {
      if (verificationChecklist.containsKey(criticalItem) && 
          verificationChecklist[criticalItem] != true) {
        errors.add('Critical verification required: $criticalItem');
      }
    }

    // Validate notes length if provided
    if (notes != null && notes.length > 500) {
      errors.add('Notes cannot exceed 500 characters');
    }

    return errors.isEmpty 
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors.join('; '));
  }

  /// Validate delivery confirmation data
  static ValidationResult validateDeliveryConfirmationData({
    required String? photoUrl,
    required double? latitude,
    required double? longitude,
    double? accuracy,
    String? recipientName,
    String? notes,
  }) {
    final errors = <String>[];

    // Validate photo URL
    if (photoUrl == null || photoUrl.trim().isEmpty) {
      errors.add('Delivery photo is required');
    } else if (!_isValidImageUrl(photoUrl)) {
      errors.add('Invalid photo URL format');
    }

    // Validate GPS coordinates
    if (latitude == null || longitude == null) {
      errors.add('GPS location is required');
    } else {
      if (latitude == 0.0 && longitude == 0.0) {
        errors.add('Valid GPS coordinates are required');
      }

      if (latitude < -90 || latitude > 90) {
        errors.add('Invalid latitude value');
      }

      if (longitude < -180 || longitude > 180) {
        errors.add('Invalid longitude value');
      }
    }

    // Validate GPS accuracy
    if (accuracy != null && accuracy > 100) {
      errors.add('GPS accuracy is too low (${accuracy.toStringAsFixed(1)}m). Please try again in an area with better signal.');
    }

    // Validate recipient name if provided
    if (recipientName != null && recipientName.trim().isNotEmpty) {
      if (recipientName.length > 100) {
        errors.add('Recipient name cannot exceed 100 characters');
      }
      if (!_isValidName(recipientName)) {
        errors.add('Recipient name contains invalid characters');
      }
    }

    // Validate notes if provided
    if (notes != null && notes.length > 500) {
      errors.add('Notes cannot exceed 500 characters');
    }

    return errors.isEmpty 
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors.join('; '));
  }

  /// Validate photo file for upload
  static ValidationResult validatePhotoFile(XFile photo) {
    final errors = <String>[];

    // TODO: Implement file size validation (max 10MB)
    // Note: XFile doesn't provide direct size access, this would need platform-specific implementation

    // Check file extension
    final fileName = photo.name.toLowerCase();
    final validExtensions = ['.jpg', '.jpeg', '.png'];
    final hasValidExtension = validExtensions.any((ext) => fileName.endsWith(ext));
    
    if (!hasValidExtension) {
      errors.add('Photo must be in JPEG or PNG format');
    }

    // Check MIME type if available
    if (photo.mimeType != null) {
      final validMimeTypes = ['image/jpeg', 'image/jpg', 'image/png'];
      if (!validMimeTypes.contains(photo.mimeType!.toLowerCase())) {
        errors.add('Invalid image format');
      }
    }

    return errors.isEmpty 
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors.join('; '));
  }

  /// Validate driver location for specific operations
  static ValidationResult validateDriverLocation({
    required double driverLatitude,
    required double driverLongitude,
    required double targetLatitude,
    required double targetLongitude,
    required double maxDistanceMeters,
    required String operationType,
  }) {
    final distance = _calculateDistance(
      driverLatitude,
      driverLongitude,
      targetLatitude,
      targetLongitude,
    );

    if (distance > maxDistanceMeters) {
      return ValidationResult.invalid(
        'You must be within ${maxDistanceMeters.toInt()}m of the $operationType location. '
        'Current distance: ${distance.toInt()}m',
      );
    }

    return ValidationResult.valid();
  }

  /// Validate order timing constraints
  static ValidationResult validateOrderTiming(DriverOrder order) {
    final errors = <String>[];
    final now = DateTime.now();

    // Check if order is too old
    final orderAge = now.difference(order.createdAt);
    if (orderAge.inHours > 24) {
      errors.add('Order is too old to process (${orderAge.inHours} hours)');
    }

    // Check if order has reasonable delivery window
    if (order.requestedDeliveryTime != null) {
      final deliveryTime = order.requestedDeliveryTime!;
      if (deliveryTime.isBefore(now.subtract(const Duration(hours: 1)))) {
        errors.add('Requested delivery time has passed');
      }
    }

    return errors.isEmpty 
        ? ValidationResult.valid()
        : ValidationResult.invalid(errors.join('; '));
  }

  // Private helper methods

  static bool _validateNavigationStart(DriverOrder order, {required bool isToVendor}) {
    // TODO: Implement actual location validation
    // This would check if the target location has valid coordinates
    return true;
  }

  static bool _validateVendorArrival(DriverOrder order) {
    // TODO: Implement actual location validation
    // This would check if driver is within reasonable distance of vendor
    return true;
  }

  static bool _validateCustomerArrival(DriverOrder order) {
    // TODO: Implement actual location validation
    // This would check if driver is within reasonable distance of customer
    return true;
  }

  static ValidationResult _validatePickupConfirmation(DriverOrder order, Map<String, dynamic>? additionalData) {
    if (additionalData == null || additionalData['pickup_confirmation'] == null) {
      return ValidationResult.invalid('Pickup confirmation data is required');
    }

    final confirmationData = additionalData['pickup_confirmation'] as Map<String, dynamic>;
    
    // Validate verification checklist
    final checklist = confirmationData['verification_checklist'] as Map<String, bool>?;
    if (checklist == null || checklist.isEmpty) {
      return ValidationResult.invalid('Verification checklist is required');
    }

    return validatePickupConfirmationData(
      verificationChecklist: checklist,
      notes: confirmationData['notes'] as String?,
    );
  }

  static ValidationResult _validateDeliveryConfirmation(DriverOrder order, Map<String, dynamic>? additionalData) {
    if (additionalData == null || additionalData['delivery_confirmation'] == null) {
      return ValidationResult.invalid('Delivery confirmation data is required');
    }

    final confirmationData = additionalData['delivery_confirmation'] as Map<String, dynamic>;
    
    return validateDeliveryConfirmationData(
      photoUrl: confirmationData['photo_url'] as String?,
      latitude: confirmationData['latitude'] as double?,
      longitude: confirmationData['longitude'] as double?,
      accuracy: confirmationData['location_accuracy'] as double?,
      recipientName: confirmationData['recipient_name'] as String?,
      notes: confirmationData['notes'] as String?,
    );
  }

  static bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.isAbsolute && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  static bool _isValidName(String name) {
    // Allow letters, spaces, hyphens, and apostrophes
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    return nameRegex.hasMatch(name.trim());
  }

  /// Calculate distance between two points in meters using Haversine formula
  static double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371000; // Earth's radius in meters
    
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);
    
    final double a = 
        (dLat / 2).sin() * (dLat / 2).sin() +
        lat1.cos() * lat2.cos() *
        (dLon / 2).sin() * (dLon / 2).sin();
    
    final double c = 2 * a.sqrt().asin();
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (3.14159265359 / 180);
  }
}

/// Validation result for driver workflow operations
class ValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ValidationResult._(this.isValid, this.errorMessage);

  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) => ValidationResult._(false, message);
}

/// Extension for math operations
extension MathExtensions on double {
  double sin() => dart_math.sin(this);
  double cos() => dart_math.cos(this);
  double asin() => dart_math.asin(this);
  double sqrt() => dart_math.sqrt(this);
}
