import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/enhanced_cart_models.dart';
import '../models/customer_delivery_method.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import '../../../../core/utils/validators.dart';
import '../../presentation/providers/enhanced_payment_provider.dart';
import 'address_validation_service.dart';
import 'schedule_validation_service.dart';
import 'enhanced_payment_service.dart';

/// Comprehensive validation service for cart and ordering workflow
class ComprehensiveValidationService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AddressValidationService _addressValidationService = AddressValidationService();
  final ScheduleValidationService _scheduleValidationService = ScheduleValidationService();
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();
  final AppLogger _logger = AppLogger();

  /// Validate entire cart and checkout workflow
  Future<WorkflowValidationResult> validateCompleteWorkflow({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledDeliveryTime,
    required PaymentMethodType paymentMethod,
    dynamic paymentDetails,
    String? promoCode,
    String? specialInstructions,
  }) async {
    try {
      _logger.info('🔍 [COMPREHENSIVE-VALIDATION] Starting complete workflow validation');

      final validationResults = <ValidationResult>[];

      // Step 1: Cart validation
      final cartValidation = await validateCart(cartState);
      validationResults.add(cartValidation);

      // Step 2: Delivery method validation
      final deliveryValidation = await validateDeliveryMethod(
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        cartState: cartState,
      );
      validationResults.add(deliveryValidation);

      // Step 3: Schedule validation (if applicable)
      if (scheduledDeliveryTime != null) {
        final scheduleValidation = await validateSchedule(
          scheduledTime: scheduledDeliveryTime,
          vendorId: cartState.primaryVendorId,
        );
        validationResults.add(scheduleValidation);
      }

      // Step 4: Payment validation
      final paymentValidation = await validatePayment(
        paymentMethod: paymentMethod,
        amount: cartState.totalAmount,
        paymentDetails: paymentDetails,
      );
      validationResults.add(paymentValidation);

      // Step 5: Form data validation
      final formValidation = validateFormData(
        specialInstructions: specialInstructions,
        promoCode: promoCode,
      );
      validationResults.add(formValidation);

      // Step 6: Business rules validation
      final businessValidation = await validateBusinessRules(
        cartState: cartState,
        deliveryMethod: deliveryMethod,
        scheduledTime: scheduledDeliveryTime,
      );
      validationResults.add(businessValidation);

      // Compile overall result
      final hasErrors = validationResults.any((result) => !result.isValid);
      final allErrors = validationResults
          .where((result) => !result.isValid)
          .expand((result) => result.errors)
          .toList();
      final allWarnings = validationResults
          .expand((result) => result.warnings)
          .toList();

      final result = WorkflowValidationResult(
        isValid: !hasErrors,
        validationResults: validationResults,
        errors: allErrors,
        warnings: allWarnings,
        recommendations: _generateRecommendations(validationResults),
      );

      _logger.info('✅ [COMPREHENSIVE-VALIDATION] Workflow validation completed: ${result.isValid}');
      return result;

    } catch (e) {
      _logger.error('❌ [COMPREHENSIVE-VALIDATION] Validation failed', e);
      
      return WorkflowValidationResult(
        isValid: false,
        validationResults: [],
        errors: ['Validation service error: ${e.toString()}'],
        warnings: [],
        recommendations: [],
      );
    }
  }

  /// Validate cart contents and state
  Future<ValidationResult> validateCart(EnhancedCartState cartState) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check if cart is empty
    if (cartState.isEmpty) {
      errors.add('Cart is empty. Please add items before proceeding.');
      return ValidationResult(
        type: ValidationType.cart,
        isValid: false,
        errors: errors,
        warnings: warnings,
      );
    }

    // Check for multiple vendors
    if (cartState.hasMultipleVendors) {
      errors.add('Cart contains items from multiple vendors. Please order from one vendor at a time.');
    }

    // Validate individual cart items
    for (final item in cartState.items) {
      final itemValidation = _validateCartItem(item);
      if (itemValidation != null) {
        errors.add(itemValidation);
      }
    }

    // Check minimum order amount
    if (cartState.primaryVendorId != null) {
      final vendorMinOrder = await _getVendorMinimumOrder(cartState.primaryVendorId!);
      if (vendorMinOrder != null && cartState.subtotal < vendorMinOrder) {
        errors.add('Order amount (RM${cartState.subtotal.toStringAsFixed(2)}) is below minimum order amount (RM${vendorMinOrder.toStringAsFixed(2)})');
      }
    }

    // Check item availability
    final unavailableItems = await _checkItemAvailability(cartState.items);
    if (unavailableItems.isNotEmpty) {
      errors.add('Some items are no longer available: ${unavailableItems.join(', ')}');
    }

    // Warnings for large orders
    if (cartState.items.length > 10) {
      warnings.add('Large order detected. Preparation time may be longer than usual.');
    }

    if (cartState.totalAmount > 500) {
      warnings.add('High-value order. Please verify all details before placing.');
    }

    return ValidationResult(
      type: ValidationType.cart,
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate delivery method and address
  Future<ValidationResult> validateDeliveryMethod({
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    required EnhancedCartState cartState,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check if delivery method requires address
    if (deliveryMethod.requiresDriver && deliveryAddress == null) {
      errors.add('Delivery address is required for ${deliveryMethod.displayName}');
    }

    // Validate delivery address if provided
    if (deliveryAddress != null && cartState.primaryVendorId != null) {
      try {
        final addressValidation = await _addressValidationService.validateAddress(
          address: deliveryAddress,
          vendorId: cartState.primaryVendorId!,
        );

        if (!addressValidation.isDeliverable) {
          errors.addAll(addressValidation.checks
              .where((check) => !check.isValid)
              .map((check) => check.message));
        }

        // TODO: Restored proper ValidationSeverity comparison - use string comparison to avoid
        // type conflicts between different ValidationSeverity enums in different services
        warnings.addAll(addressValidation.checks
            .where((check) => check.severity.toString().contains('warning'))
            .map((check) => check.message));

      } catch (e) {
        warnings.add('Could not validate delivery address: ${e.toString()}');
      }
    }

    // Check delivery method availability
    if (!await _isDeliveryMethodAvailable(deliveryMethod, cartState)) {
      errors.add('${deliveryMethod.displayName} is not available for this order');
    }

    return ValidationResult(
      type: ValidationType.delivery,
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate scheduled delivery time
  Future<ValidationResult> validateSchedule({
    required DateTime scheduledTime,
    String? vendorId,
  }) async {
    try {
      final scheduleValidation = await _scheduleValidationService.validateSchedule(
        dateTime: scheduledTime,
        vendorId: vendorId,
      );

      return ValidationResult(
        type: ValidationType.schedule,
        isValid: scheduleValidation.isValid,
        errors: scheduleValidation.isValid ? [] : [scheduleValidation.message ?? 'Invalid schedule'],
        warnings: scheduleValidation.hasWarnings ? [scheduleValidation.message ?? 'Schedule warning'] : [],
      );

    } catch (e) {
      return ValidationResult(
        type: ValidationType.schedule,
        isValid: false,
        errors: ['Schedule validation failed: ${e.toString()}'],
        warnings: [],
      );
    }
  }

  /// Validate payment method and details
  Future<ValidationResult> validatePayment({
    required PaymentMethodType paymentMethod,
    required double amount,
    dynamic paymentDetails,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate payment amount
    if (amount <= 0) {
      errors.add('Invalid payment amount');
    }

    // Validate payment method specific requirements
    switch (paymentMethod) {
      case PaymentMethodType.card:
        if (paymentDetails == null) {
          errors.add('Card details are required for card payment');
        }
        break;

      case PaymentMethodType.wallet:
        try {
          final walletBalance = await _paymentService.getWalletBalance();
          if (walletBalance < amount) {
            errors.add('Insufficient wallet balance. Required: RM${amount.toStringAsFixed(2)}, Available: RM${walletBalance.toStringAsFixed(2)}');
          }
        } catch (e) {
          warnings.add('Could not verify wallet balance: ${e.toString()}');
        }
        break;

      case PaymentMethodType.cash:
        // Cash payment is always valid
        break;
    }

    // Check payment limits
    if (amount > 1000 && paymentMethod == PaymentMethodType.cash) {
      warnings.add('Large cash payment. Consider using card or wallet for security.');
    }

    return ValidationResult(
      type: ValidationType.payment,
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate form data
  ValidationResult validateFormData({
    String? specialInstructions,
    String? promoCode,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    // Validate special instructions
    if (specialInstructions != null && specialInstructions.isNotEmpty) {
      final instructionsValidation = InputValidator.validateAndSanitizeText(
        specialInstructions,
        maxLength: 500,
        allowEmpty: true,
      );
      if (instructionsValidation != null) {
        errors.add('Special instructions: $instructionsValidation');
      }
    }

    // Validate promo code format
    if (promoCode != null && promoCode.isNotEmpty) {
      if (promoCode.length < 3 || promoCode.length > 20) {
        errors.add('Promo code must be between 3 and 20 characters');
      }
      
      if (!RegExp(r'^[A-Z0-9]+$').hasMatch(promoCode.toUpperCase())) {
        errors.add('Promo code can only contain letters and numbers');
      }
    }

    return ValidationResult(
      type: ValidationType.form,
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Validate business rules
  Future<ValidationResult> validateBusinessRules({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    DateTime? scheduledTime,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];

    // Check business hours
    final now = DateTime.now();
    if (scheduledTime == null && (now.hour < 8 || now.hour >= 22)) {
      warnings.add('Ordering outside business hours. Delivery may be delayed.');
    }

    // Check vendor operational status
    if (cartState.primaryVendorId != null) {
      final isVendorOperational = await _checkVendorOperationalStatus(cartState.primaryVendorId!);
      if (!isVendorOperational) {
        errors.add('Restaurant is currently not accepting orders');
      }
    }

    // Check delivery capacity
    if (deliveryMethod.requiresDriver) {
      final hasCapacity = await _checkDeliveryCapacity(scheduledTime ?? now);
      if (!hasCapacity) {
        warnings.add('High delivery demand. Delivery may take longer than usual.');
      }
    }

    return ValidationResult(
      type: ValidationType.business,
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Helper methods
  String? _validateCartItem(EnhancedCartItem item) {
    if (item.quantity <= 0) {
      return 'Invalid quantity for ${item.name}';
    }

    if (item.basePrice <= 0) {
      return 'Invalid price for ${item.name}';
    }

    return null;
  }

  Future<double?> _getVendorMinimumOrder(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('minimum_order_amount')
          .eq('id', vendorId)
          .single();

      return (response['minimum_order_amount'] as num?)?.toDouble();
    } catch (e) {
      return null;
    }
  }

  Future<List<String>> _checkItemAvailability(List<EnhancedCartItem> items) async {
    final unavailableItems = <String>[];
    
    for (final item in items) {
      try {
        final response = await _supabase
            .from('menu_items')
            .select('is_available')
            .eq('id', item.menuItemId)
            .single();

        if (response['is_available'] != true) {
          unavailableItems.add(item.name);
        }
      } catch (e) {
        // If we can't check availability, assume it's available
        continue;
      }
    }

    return unavailableItems;
  }

  Future<bool> _isDeliveryMethodAvailable(CustomerDeliveryMethod method, EnhancedCartState cartState) async {
    // Mock implementation - in real app, check vendor delivery methods
    return true;
  }

  Future<bool> _checkVendorOperationalStatus(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('is_operational')
          .eq('id', vendorId)
          .single();

      return response['is_operational'] == true;
    } catch (e) {
      return true; // Assume operational if we can't check
    }
  }

  Future<bool> _checkDeliveryCapacity(DateTime time) async {
    // Mock implementation - in real app, check driver availability
    return true;
  }

  List<String> _generateRecommendations(List<ValidationResult> results) {
    final recommendations = <String>[];

    // Generate recommendations based on validation results
    for (final result in results) {
      if (result.warnings.isNotEmpty) {
        switch (result.type) {
          case ValidationType.cart:
            recommendations.add('Consider reviewing your order for optimal preparation time');
            break;
          case ValidationType.delivery:
            recommendations.add('Verify delivery address for accurate delivery');
            break;
          case ValidationType.payment:
            recommendations.add('Consider using secure payment methods for large orders');
            break;
          default:
            break;
        }
      }
    }

    return recommendations;
  }
}

/// Validation result for individual components
class ValidationResult {
  final ValidationType type;
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.type,
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// Complete workflow validation result
class WorkflowValidationResult {
  final bool isValid;
  final List<ValidationResult> validationResults;
  final List<String> errors;
  final List<String> warnings;
  final List<String> recommendations;

  const WorkflowValidationResult({
    required this.isValid,
    required this.validationResults,
    required this.errors,
    required this.warnings,
    required this.recommendations,
  });
}

/// Validation types
enum ValidationType {
  cart,
  delivery,
  schedule,
  payment,
  form,
  business,
}

/// Validation severity levels
enum ValidationSeverity {
  info,
  warning,
  error,
}
