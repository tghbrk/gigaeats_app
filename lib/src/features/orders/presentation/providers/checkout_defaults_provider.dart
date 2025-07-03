import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../user_management/presentation/providers/customer_address_provider.dart';
import '../../../marketplace_wallet/presentation/providers/customer_payment_methods_provider.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../marketplace_wallet/data/models/customer_payment_method.dart';
import '../../../core/utils/logger.dart';

part 'checkout_defaults_provider.g.dart';

/// Model for checkout defaults
class CheckoutDefaults {
  final CustomerAddress? defaultAddress;
  final CustomerPaymentMethod? defaultPaymentMethod;
  final bool hasAddress;
  final bool hasPaymentMethod;
  final String? addressError;
  final String? paymentMethodError;

  const CheckoutDefaults({
    this.defaultAddress,
    this.defaultPaymentMethod,
    this.hasAddress = false,
    this.hasPaymentMethod = false,
    this.addressError,
    this.paymentMethodError,
  });

  CheckoutDefaults copyWith({
    CustomerAddress? defaultAddress,
    CustomerPaymentMethod? defaultPaymentMethod,
    bool? hasAddress,
    bool? hasPaymentMethod,
    String? addressError,
    String? paymentMethodError,
  }) {
    return CheckoutDefaults(
      defaultAddress: defaultAddress ?? this.defaultAddress,
      defaultPaymentMethod: defaultPaymentMethod ?? this.defaultPaymentMethod,
      hasAddress: hasAddress ?? this.hasAddress,
      hasPaymentMethod: hasPaymentMethod ?? this.hasPaymentMethod,
      addressError: addressError ?? this.addressError,
      paymentMethodError: paymentMethodError ?? this.paymentMethodError,
    );
  }

  /// Check if both defaults are available
  bool get hasAllDefaults => hasAddress && hasPaymentMethod;

  /// Check if any defaults are available
  bool get hasAnyDefaults => hasAddress || hasPaymentMethod;

  /// Check if there are any errors
  bool get hasErrors => addressError != null || paymentMethodError != null;

  @override
  String toString() {
    return 'CheckoutDefaults(hasAddress: $hasAddress, hasPaymentMethod: $hasPaymentMethod, hasErrors: $hasErrors)';
  }
}

/// Synchronous provider for payment method defaults state
/// This extracts the current state from the async provider without waiting
@riverpod
({CustomerPaymentMethod? method, bool hasMethod, String? error}) paymentMethodDefaults(Ref ref) {
  final logger = AppLogger();
  final paymentMethodsAsync = ref.watch(customerPaymentMethodsProvider);

  return paymentMethodsAsync.when(
    data: (methods) {
      logger.debug('📊 [PAYMENT-DEFAULTS] Payment methods data: ${methods.length} methods');

      if (methods.isNotEmpty) {
        try {
          final defaultMethod = methods.firstWhere(
            (method) => method.isDefault,
            orElse: () => methods.first,
          );
          logger.debug('✅ [PAYMENT-DEFAULTS] Default method found: ${defaultMethod.displayName}');
          return (method: defaultMethod, hasMethod: true, error: null);
        } catch (e) {
          logger.error('❌ [PAYMENT-DEFAULTS] Error selecting default method', e);
          return (method: null, hasMethod: false, error: 'Error selecting method: $e');
        }
      } else {
        logger.debug('ℹ️ [PAYMENT-DEFAULTS] No payment methods found');
        return (method: null, hasMethod: false, error: null);
      }
    },
    loading: () {
      logger.debug('🔄 [PAYMENT-DEFAULTS] Payment methods loading');
      return (method: null, hasMethod: false, error: null);
    },
    error: (error, stack) {
      logger.error('❌ [PAYMENT-DEFAULTS] Payment methods error', error, stack);
      return (method: null, hasMethod: false, error: 'Failed to load: $error');
    },
  );
}

/// Provider for fetching checkout defaults (address and payment method)
/// Fixed to properly handle async payment method data while maintaining synchronous interface
@riverpod
CheckoutDefaults checkoutDefaults(Ref ref) {
  final logger = AppLogger();
  logger.info('🔄 [CHECKOUT-DEFAULTS] Fetching checkout defaults');

  try {
    // Get the default address synchronously by watching the provider
    final defaultAddress = ref.watch(defaultCustomerAddressProvider);

    // Get the payment method defaults using the new synchronous provider
    final paymentDefaults = ref.watch(paymentMethodDefaultsProvider);

    final defaults = CheckoutDefaults(
      defaultAddress: defaultAddress,
      defaultPaymentMethod: paymentDefaults.method,
      hasAddress: defaultAddress != null,
      hasPaymentMethod: paymentDefaults.hasMethod,
      addressError: null,
      paymentMethodError: paymentDefaults.error,
    );

    // Enhanced logging for address state
    if (defaultAddress != null) {
      logger.debug('✅ [CHECKOUT-DEFAULTS] Default address found: ${defaultAddress.label} (ID: ${defaultAddress.id})');
    } else {
      logger.debug('ℹ️ [CHECKOUT-DEFAULTS] No default address found');
    }

    // Enhanced logging for payment method state
    if (paymentDefaults.hasMethod && paymentDefaults.method != null) {
      logger.debug('✅ [CHECKOUT-DEFAULTS] Default payment method found: ${paymentDefaults.method!.displayName} (ID: ${paymentDefaults.method!.id})');
    } else {
      logger.debug('ℹ️ [CHECKOUT-DEFAULTS] No default payment method found');
      if (paymentDefaults.error != null) {
        logger.debug('❌ [CHECKOUT-DEFAULTS] Payment method error: ${paymentDefaults.error}');
      }
    }

    // Enhanced logging for final state
    logger.info('✅ [CHECKOUT-DEFAULTS] Defaults fetched - hasAddress: ${defaults.hasAddress}, hasPaymentMethod: ${defaults.hasPaymentMethod}');
    logger.debug('🔍 [CHECKOUT-DEFAULTS] Final defaults: $defaults');

    return defaults;

  } catch (e, stack) {
    logger.error('❌ [CHECKOUT-DEFAULTS] Error fetching defaults', e, stack);

    // Return empty defaults with error
    return CheckoutDefaults(
      addressError: 'Failed to load address: $e',
      paymentMethodError: 'Failed to load payment method: $e',
    );
  }
}







/// Provider for checking if user has any saved addresses
@riverpod
Future<bool> customerHasAddresses(Ref ref) async {
  try {
    final addressesState = ref.read(customerAddressesProvider);
    return addressesState.addresses.isNotEmpty;
  } catch (e) {
    return false;
  }
}

/// Provider for checking if user has any saved payment methods
@riverpod
Future<bool> customerHasSavedPaymentMethods(Ref ref) async {
  try {
    return await ref.read(customerHasPaymentMethodsProvider.future);
  } catch (e) {
    return false;
  }
}

/// Provider for getting checkout readiness status
@riverpod
Future<CheckoutReadiness> checkoutReadiness(Ref ref) async {
  final logger = AppLogger();
  
  try {
    logger.debug('🔍 [CHECKOUT-READINESS] Checking checkout readiness');
    
    final results = await Future.wait([
      ref.read(customerHasAddressesProvider.future),
      ref.read(customerHasSavedPaymentMethodsProvider.future),
    ]);

    final hasAddresses = results[0];
    final hasPaymentMethods = results[1];

    final readiness = CheckoutReadiness(
      hasAddresses: hasAddresses,
      hasPaymentMethods: hasPaymentMethods,
    );

    logger.debug('✅ [CHECKOUT-READINESS] Readiness: $readiness');
    return readiness;

  } catch (e, stack) {
    logger.error('❌ [CHECKOUT-READINESS] Error checking readiness', e, stack);
    return const CheckoutReadiness();
  }
}

/// Model for checkout readiness
class CheckoutReadiness {
  final bool hasAddresses;
  final bool hasPaymentMethods;

  const CheckoutReadiness({
    this.hasAddresses = false,
    this.hasPaymentMethods = false,
  });

  /// Check if user is ready for checkout
  bool get isReady => hasAddresses && hasPaymentMethods;

  /// Get missing requirements
  List<String> get missingRequirements {
    final missing = <String>[];
    if (!hasAddresses) missing.add('delivery address');
    if (!hasPaymentMethods) missing.add('payment method');
    return missing;
  }

  @override
  String toString() {
    return 'CheckoutReadiness(hasAddresses: $hasAddresses, hasPaymentMethods: $hasPaymentMethods, isReady: $isReady)';
  }
}
