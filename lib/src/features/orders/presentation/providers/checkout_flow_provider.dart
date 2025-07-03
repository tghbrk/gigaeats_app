import 'package:flutter_riverpod/flutter_riverpod.dart';


import '../../data/models/customer_delivery_method.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../marketplace_wallet/data/models/customer_payment_method.dart';
import '../../../core/utils/logger.dart';
import 'enhanced_cart_provider.dart';
import 'checkout_defaults_provider.dart';
import '../../../marketplace_wallet/presentation/providers/customer_wallet_provider.dart';
import '../../../marketplace_wallet/presentation/providers/customer_payment_methods_provider.dart';
import '../../data/services/schedule_delivery_validation_service.dart';

/// Result of scheduled time validation
class ScheduledTimeValidationResult {
  final bool isValid;
  final String? errorMessage;

  const ScheduledTimeValidationResult({
    required this.isValid,
    this.errorMessage,
  });
}

/// Checkout flow state
class CheckoutFlowState {
  final int currentStep;
  final int maxAccessibleStep;
  final bool isCartValid;
  final bool isDeliveryValid;
  final bool isPaymentValid;
  final bool isProcessing;
  final String? error;
  final Map<String, dynamic> stepData;
  final DateTime lastUpdated;

  const CheckoutFlowState({
    this.currentStep = 0,
    this.maxAccessibleStep = 0,
    this.isCartValid = false,
    this.isDeliveryValid = false,
    this.isPaymentValid = false,
    this.isProcessing = false,
    this.error,
    this.stepData = const {},
    required this.lastUpdated,
  });

  CheckoutFlowState copyWith({
    int? currentStep,
    int? maxAccessibleStep,
    bool? isCartValid,
    bool? isDeliveryValid,
    bool? isPaymentValid,
    bool? isProcessing,
    String? error,
    Map<String, dynamic>? stepData,
    DateTime? lastUpdated,
  }) {
    return CheckoutFlowState(
      currentStep: currentStep ?? this.currentStep,
      maxAccessibleStep: maxAccessibleStep ?? this.maxAccessibleStep,
      isCartValid: isCartValid ?? this.isCartValid,
      isDeliveryValid: isDeliveryValid ?? this.isDeliveryValid,
      isPaymentValid: isPaymentValid ?? this.isPaymentValid,
      isProcessing: isProcessing ?? this.isProcessing,
      error: error,
      stepData: stepData ?? this.stepData,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  /// Check if all steps are valid for checkout
  bool get canCompleteCheckout => isCartValid && isDeliveryValid && isPaymentValid;

  /// Get delivery method from step data
  CustomerDeliveryMethod? get selectedDeliveryMethod {
    final methodValue = stepData['deliveryMethod'] as String?;
    if (methodValue == null) return null;
    
    return CustomerDeliveryMethod.values.firstWhere(
      (method) => method.value == methodValue,
      orElse: () => CustomerDeliveryMethod.customerPickup,
    );
  }

  /// Get delivery address from step data
  CustomerAddress? get selectedDeliveryAddress {
    final addressData = stepData['deliveryAddress'] as Map<String, dynamic>?;
    if (addressData == null) return null;
    
    return CustomerAddress.fromJson(addressData);
  }

  /// Get payment method from step data
  String? get selectedPaymentMethod => stepData['paymentMethod'] as String?;

  /// Get special instructions from step data
  String? get specialInstructions => stepData['specialInstructions'] as String?;

  /// Get scheduled delivery time from step data
  DateTime? get scheduledDeliveryTime {
    final timeString = stepData['scheduledDeliveryTime'] as String?;
    if (timeString == null) return null;
    
    return DateTime.tryParse(timeString);
  }
}

/// Checkout flow state notifier
class CheckoutFlowNotifier extends StateNotifier<CheckoutFlowState> {
  final Ref _ref;
  final AppLogger _logger = AppLogger();

  CheckoutFlowNotifier(this._ref) : super(CheckoutFlowState(lastUpdated: DateTime.now()));

  /// Initialize checkout flow
  void initializeCheckout() {
    _logger.info('🛒 [CHECKOUT-FLOW] Initializing checkout flow');

    // Validate cart initially
    _validateCart();

    state = state.copyWith(
      currentStep: 0,
      maxAccessibleStep: 0,
    );

    // Auto-populate defaults asynchronously
    _autoPopulateDefaults();
  }

  /// Auto-populate default address and payment method
  Future<void> _autoPopulateDefaults() async {
    try {
      _logger.info('🔄 [CHECKOUT-FLOW] Auto-populating checkout defaults');

      // Fetch checkout defaults
      final defaults = _ref.read(checkoutDefaultsProvider);

      if (defaults.hasErrors) {
        _logger.warning('⚠️ [CHECKOUT-FLOW] Errors in defaults: address=${defaults.addressError}, payment=${defaults.paymentMethodError}');
      }

      // Auto-populate default address if available and delivery method requires it
      if (defaults.hasAddress && defaults.defaultAddress != null) {
        await _autoPopulateDefaultAddress(defaults.defaultAddress!);
      }

      // Auto-populate default payment method if available
      if (defaults.hasPaymentMethod && defaults.defaultPaymentMethod != null) {
        await _autoPopulateDefaultPaymentMethod(defaults.defaultPaymentMethod!);
      }

      _logger.info('✅ [CHECKOUT-FLOW] Auto-population completed');

    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FLOW] Error auto-populating defaults', e, stack);
      // Don't throw error - checkout should continue without defaults
    }
  }

  /// Auto-populate default address based on delivery method
  Future<void> _autoPopulateDefaultAddress(CustomerAddress defaultAddress) async {
    try {
      // Check if we already have an address set
      if (state.selectedDeliveryAddress != null) {
        _logger.debug('ℹ️ [CHECKOUT-FLOW] Address already set, skipping auto-population');
        return;
      }

      // Check if current delivery method requires an address
      final currentDeliveryMethod = state.selectedDeliveryMethod;
      if (currentDeliveryMethod != null && !currentDeliveryMethod.requiresDriver) {
        _logger.debug('ℹ️ [CHECKOUT-FLOW] Delivery method ${currentDeliveryMethod.value} does not require address');
        return;
      }

      // Set the default address
      setDeliveryAddress(defaultAddress);
      _logger.info('✅ [CHECKOUT-FLOW] Auto-populated default address: ${defaultAddress.label}');

    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FLOW] Error auto-populating default address', e, stack);
    }
  }

  /// Auto-populate default payment method
  Future<void> _autoPopulateDefaultPaymentMethod(CustomerPaymentMethod defaultPaymentMethod) async {
    try {
      // Check if we already have a payment method set
      if (state.selectedPaymentMethod != null && state.selectedPaymentMethod!.isNotEmpty) {
        _logger.debug('ℹ️ [CHECKOUT-FLOW] Payment method already set, skipping auto-population');
        return;
      }

      // Map CustomerPaymentMethod to checkout payment method string
      String paymentMethodValue;
      switch (defaultPaymentMethod.type) {
        case CustomerPaymentMethodType.card:
          paymentMethodValue = 'card';
          break;
        case CustomerPaymentMethodType.digitalWallet:
          paymentMethodValue = 'wallet';
          break;
        case CustomerPaymentMethodType.bankAccount:
          paymentMethodValue = 'fpx'; // FPX for bank accounts
          break;
      }

      // Set the default payment method
      setPaymentMethod(paymentMethodValue);
      _logger.info('✅ [CHECKOUT-FLOW] Auto-populated default payment method: ${defaultPaymentMethod.displayName}');

    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FLOW] Error auto-populating default payment method', e, stack);
    }
  }

  /// Set current step
  void setCurrentStep(int step) {
    _logger.info('🛒 [CHECKOUT-FLOW] Setting current step to: $step');
    
    final maxAccessible = step > state.maxAccessibleStep ? step : state.maxAccessibleStep;
    
    state = state.copyWith(
      currentStep: step,
      maxAccessibleStep: maxAccessible,
    );
  }

  /// Update step data
  void updateStepData(String key, dynamic value) {
    _logger.info('🛒 [CHECKOUT-FLOW] Updating step data: $key');
    
    final updatedStepData = Map<String, dynamic>.from(state.stepData);
    updatedStepData[key] = value;
    
    state = state.copyWith(stepData: updatedStepData);
    
    // Revalidate steps when data changes
    _validateAllSteps();
  }

  /// Set delivery method
  void setDeliveryMethod(CustomerDeliveryMethod method) {
    _logger.info('🚚 [CHECKOUT-FLOW] Setting delivery method: ${method.value}');
    updateStepData('deliveryMethod', method.value);

    // Auto-populate address if delivery method requires it and we don't have one
    _autoPopulateAddressForDeliveryMethod(method);
  }

  /// Auto-populate address when delivery method changes
  Future<void> _autoPopulateAddressForDeliveryMethod(CustomerDeliveryMethod method) async {
    try {
      // Only auto-populate if method requires an address and we don't have one
      if (!method.requiresDriver || state.selectedDeliveryAddress != null) {
        return;
      }

      _logger.debug('🔄 [CHECKOUT-FLOW] Auto-populating address for delivery method: ${method.value}');

      // Fetch default address
      final defaults = _ref.read(checkoutDefaultsProvider);

      if (defaults.hasAddress && defaults.defaultAddress != null) {
        setDeliveryAddress(defaults.defaultAddress!);
        _logger.info('✅ [CHECKOUT-FLOW] Auto-populated address for delivery method change');
      }

    } catch (e, stack) {
      _logger.error('❌ [CHECKOUT-FLOW] Error auto-populating address for delivery method', e, stack);
    }
  }

  /// Set delivery address
  void setDeliveryAddress(CustomerAddress? address) {
    _logger.info('📍 [CHECKOUT-FLOW] Setting delivery address');
    updateStepData('deliveryAddress', address?.toJson());
  }

  /// Set scheduled delivery time with validation
  void setScheduledDeliveryTime(DateTime? dateTime) {
    _logger.info('⏰ [CHECKOUT-FLOW] Setting scheduled delivery time: $dateTime');

    // Validate the scheduled time
    if (dateTime != null) {
      final validationResult = _validateScheduledTime(dateTime);
      if (!validationResult.isValid) {
        _logger.warning('⚠️ [CHECKOUT-FLOW] Invalid scheduled time: ${validationResult.errorMessage}');
        state = state.copyWith(error: validationResult.errorMessage);
        return;
      }
    }

    updateStepData('scheduledDeliveryTime', dateTime?.toIso8601String());

    // Clear any previous errors
    if (state.error?.contains('scheduled') == true) {
      state = state.copyWith(error: null);
    }

    // Re-validate delivery step
    _validateDelivery();
  }

  /// Validate scheduled delivery time using enhanced validation service
  ScheduledTimeValidationResult _validateScheduledTime(DateTime scheduledTime) {
    final validationService = _ref.read(scheduleDeliveryValidationServiceProvider);
    final result = validationService.validateScheduledTime(
      scheduledTime: scheduledTime,
      minimumAdvanceHours: 2,
      maxDaysAhead: 7,
      checkBusinessHours: true,
      checkVendorHours: false, // TODO: Enable when vendor integration is available
    );

    return ScheduledTimeValidationResult(
      isValid: result.isValid,
      errorMessage: result.primaryError,
    );
  }

  /// Clear scheduled delivery time
  void clearScheduledDeliveryTime() {
    _logger.info('🗑️ [CHECKOUT-FLOW] Clearing scheduled delivery time');
    updateStepData('scheduledDeliveryTime', null);
    _validateDelivery();
  }

  /// Check if scheduled delivery is required for current delivery method
  bool get isScheduledDeliveryRequired {
    return state.selectedDeliveryMethod == CustomerDeliveryMethod.scheduled;
  }

  /// Get formatted scheduled delivery time for display
  String? get formattedScheduledTime {
    final scheduledTime = state.scheduledDeliveryTime;
    if (scheduledTime == null) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final scheduledDay = DateTime(scheduledTime.year, scheduledTime.month, scheduledTime.day);

    final timeString = '${scheduledTime.hour.toString().padLeft(2, '0')}:${scheduledTime.minute.toString().padLeft(2, '0')}';

    if (scheduledDay == today) {
      return 'Today, $timeString';
    } else if (scheduledDay == tomorrow) {
      return 'Tomorrow, $timeString';
    } else {
      final months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ];
      final dateString = '${scheduledTime.day} ${months[scheduledTime.month - 1]}';
      return '$dateString, $timeString';
    }
  }

  /// Set payment method
  void setPaymentMethod(String method) {
    _logger.info('💳 [CHECKOUT-FLOW] Setting payment method: $method');
    updateStepData('paymentMethod', method);
  }

  /// Set special instructions
  void setSpecialInstructions(String? instructions) {
    _logger.info('📝 [CHECKOUT-FLOW] Setting special instructions');
    updateStepData('specialInstructions', instructions);
  }

  /// Start processing (for order placement)
  void startProcessing() {
    _logger.info('⏳ [CHECKOUT-FLOW] Starting order processing');
    state = state.copyWith(isProcessing: true, error: null);
  }

  /// Complete processing
  void completeProcessing() {
    _logger.info('✅ [CHECKOUT-FLOW] Order processing completed');
    state = state.copyWith(isProcessing: false);
  }

  /// Set error
  void setError(String error) {
    _logger.error('❌ [CHECKOUT-FLOW] Error occurred: $error');
    state = state.copyWith(isProcessing: false, error: error);
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Validate all steps
  void _validateAllSteps() {
    _validateCart();
    _validateDelivery();
    _validatePayment();
  }

  /// Validate cart step
  void _validateCart() {
    final cartState = _ref.read(enhancedCartProvider);
    
    final isValid = cartState.isNotEmpty && 
                   !cartState.hasMultipleVendors &&
                   cartState.items.every((item) => item.isAvailable);
    
    state = state.copyWith(isCartValid: isValid);
    
    _logger.debug('🛒 [CHECKOUT-FLOW] Cart validation: $isValid');
  }

  /// Validate delivery step
  void _validateDelivery() {
    final deliveryMethod = state.selectedDeliveryMethod;
    final deliveryAddress = state.selectedDeliveryAddress;
    
    bool isValid = deliveryMethod != null;
    
    // Check if delivery address is required
    if (deliveryMethod?.requiresDriver == true) {
      isValid = isValid && deliveryAddress != null;
    }
    
    // Check scheduled delivery time if required
    if (deliveryMethod == CustomerDeliveryMethod.scheduled) {
      final scheduledTime = state.scheduledDeliveryTime;
      if (scheduledTime == null) {
        isValid = false;
      } else {
        final validationResult = _validateScheduledTime(scheduledTime);
        isValid = isValid && validationResult.isValid;
      }
    }
    
    state = state.copyWith(isDeliveryValid: isValid);
    
    _logger.debug('🚚 [CHECKOUT-FLOW] Delivery validation: $isValid');
  }

  /// Validate payment step
  void _validatePayment() {
    final paymentMethod = state.selectedPaymentMethod;

    if (paymentMethod == null || paymentMethod.isEmpty) {
      state = state.copyWith(isPaymentValid: false);
      _logger.debug('💳 [CHECKOUT-FLOW] Payment validation: false (no method selected)');
      return;
    }

    // For wallet payments, validate wallet balance
    if (paymentMethod == 'wallet') {
      _validateWalletPayment();
    } else {
      // For other payment methods, basic validation
      state = state.copyWith(isPaymentValid: true);
      _logger.debug('💳 [CHECKOUT-FLOW] Payment validation: true (${paymentMethod})');
    }
  }

  /// Validate wallet payment specifically
  void _validateWalletPayment() {
    final cartState = _ref.read(enhancedCartProvider);
    final walletState = _ref.read(customerWalletProvider);

    if (walletState.isLoading) {
      // Still loading wallet, assume valid for now
      state = state.copyWith(isPaymentValid: true);
      _logger.debug('💳 [CHECKOUT-FLOW] Wallet validation: true (loading wallet)');
      return;
    }

    if (walletState.hasError) {
      // Error loading wallet
      state = state.copyWith(isPaymentValid: false);
      _logger.debug('💳 [CHECKOUT-FLOW] Wallet validation: false (error loading wallet)');
      return;
    }

    final wallet = walletState.wallet;
    if (wallet != null) {

        // Check if wallet has sufficient balance OR if split payment is possible
        final orderTotal = cartState.totalAmount;
        final walletBalance = wallet.availableBalance;

        if (walletBalance >= orderTotal) {
          // Full wallet payment possible
          state = state.copyWith(isPaymentValid: true);
          _logger.debug('💳 [CHECKOUT-FLOW] Wallet validation: true (full payment)');
        } else {
          // Check if user has saved payment methods for split payment
          final hasPaymentMethodsAsync = _ref.read(customerHasPaymentMethodsProvider.future);
          hasPaymentMethodsAsync.then((hasCards) {
            if (hasCards) {
              // Split payment possible
              state = state.copyWith(isPaymentValid: true);
              _logger.debug('💳 [CHECKOUT-FLOW] Wallet validation: true (split payment)');
            } else {
              // Insufficient balance and no fallback payment method
              state = state.copyWith(isPaymentValid: false);
              _logger.debug('💳 [CHECKOUT-FLOW] Wallet validation: false (insufficient balance, no cards)');
            }
          }).catchError((error) {
            // Error loading cards, assume no cards available
            state = state.copyWith(isPaymentValid: false);
            _logger.debug('💳 [CHECKOUT-FLOW] Wallet validation: false (error loading cards: $error)');
          });
        }
    } else {
      state = state.copyWith(isPaymentValid: false);
      _logger.debug('💳 [CHECKOUT-FLOW] Wallet validation: false (no wallet)');
    }
  }

  /// Reset checkout flow
  void reset() {
    _logger.info('🔄 [CHECKOUT-FLOW] Resetting checkout flow');

    state = CheckoutFlowState(lastUpdated: DateTime.now());
  }

  /// Manually trigger auto-population of defaults
  Future<void> autoPopulateDefaults() async {
    await _autoPopulateDefaults();
  }

  /// Check if auto-population is available
  bool canAutoPopulate() {
    try {
      final defaults = _ref.read(checkoutDefaultsProvider);
      return defaults.hasAnyDefaults && !defaults.hasErrors;
    } catch (e) {
      return false;
    }
  }

  /// Get checkout summary
  Map<String, dynamic> getCheckoutSummary() {
    final cartState = _ref.read(enhancedCartProvider);
    
    return {
      'cart': {
        'items': cartState.items.map((item) => item.toJson()).toList(),
        'subtotal': cartState.subtotal,
        'totalAmount': cartState.totalAmount,
        'itemCount': cartState.totalItems,
      },
      'delivery': {
        'method': state.selectedDeliveryMethod?.value,
        'address': state.selectedDeliveryAddress?.toJson(),
        'scheduledTime': state.scheduledDeliveryTime?.toIso8601String(),
        'fee': cartState.deliveryFee,
      },
      'payment': {
        'method': state.selectedPaymentMethod,
      },
      'order': {
        'specialInstructions': state.specialInstructions,
        'totalAmount': cartState.totalAmount,
        'sstAmount': cartState.sstAmount,
      },
    };
  }
}

/// Checkout flow provider
final checkoutFlowProvider = StateNotifierProvider<CheckoutFlowNotifier, CheckoutFlowState>((ref) {
  return CheckoutFlowNotifier(ref);
});

/// Convenience providers
final currentCheckoutStepProvider = Provider<int>((ref) {
  return ref.watch(checkoutFlowProvider).currentStep;
});

final isCheckoutProcessingProvider = Provider<bool>((ref) {
  return ref.watch(checkoutFlowProvider).isProcessing;
});

final checkoutErrorProvider = Provider<String?>((ref) {
  return ref.watch(checkoutFlowProvider).error;
});

final canCompleteCheckoutProvider = Provider<bool>((ref) {
  return ref.watch(checkoutFlowProvider).canCompleteCheckout;
});

final selectedDeliveryMethodProvider = Provider<CustomerDeliveryMethod?>((ref) {
  return ref.watch(checkoutFlowProvider).selectedDeliveryMethod;
});

final selectedDeliveryAddressProvider = Provider<CustomerAddress?>((ref) {
  return ref.watch(checkoutFlowProvider).selectedDeliveryAddress;
});

final selectedPaymentMethodProvider = Provider<String?>((ref) {
  return ref.watch(checkoutFlowProvider).selectedPaymentMethod;
});

final scheduledDeliveryTimeProvider = Provider<DateTime?>((ref) {
  return ref.watch(checkoutFlowProvider).scheduledDeliveryTime;
});

final formattedScheduledTimeProvider = Provider<String?>((ref) {
  return ref.read(checkoutFlowProvider.notifier).formattedScheduledTime;
});

final isScheduledDeliveryRequiredProvider = Provider<bool>((ref) {
  return ref.read(checkoutFlowProvider.notifier).isScheduledDeliveryRequired;
});

final checkoutSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  return ref.read(checkoutFlowProvider.notifier).getCheckoutSummary();
});

/// Provider for checking if auto-population is available
final canAutoPopulateCheckoutProvider = FutureProvider<bool>((ref) async {
  return ref.read(checkoutFlowProvider.notifier).canAutoPopulate();
});

/// Provider for triggering manual auto-population
final autoPopulateCheckoutProvider = Provider<Future<void> Function()>((ref) {
  return () => ref.read(checkoutFlowProvider.notifier).autoPopulateDefaults();
});
