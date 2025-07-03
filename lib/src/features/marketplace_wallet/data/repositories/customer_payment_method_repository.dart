import 'package:flutter/foundation.dart';
import '../models/customer_payment_method.dart';
import '../services/customer_payment_method_service.dart';

/// Repository for customer payment method data management
class CustomerPaymentMethodRepository {
  final CustomerPaymentMethodService _service;

  CustomerPaymentMethodRepository({
    CustomerPaymentMethodService? service,
  }) : _service = service ?? CustomerPaymentMethodService();

  /// Get all payment methods for the current user
  Future<List<CustomerPaymentMethod>> getPaymentMethods() async {
    debugPrint('🔄 [PAYMENT-METHODS-REPO] Fetching payment methods from service');

    try {
      final methods = await _service.getPaymentMethods();
      debugPrint('📊 [PAYMENT-METHODS-REPO] Fetched ${methods.length} payment methods from service');

      for (int i = 0; i < methods.length; i++) {
        final method = methods[i];
        debugPrint('  📋 [PAYMENT-METHODS-REPO] Method $i: ${method.displayName} (default: ${method.isDefault}, active: ${method.isActive})');
      }

      return methods;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getPaymentMethods: $e');
      rethrow;
    }
  }

  /// Add a new payment method
  Future<CustomerPaymentMethod> addPaymentMethod({
    required String stripePaymentMethodId,
    String? nickname,
  }) async {
    try {
      return await _service.addPaymentMethod(
        stripePaymentMethodId: stripePaymentMethodId,
        nickname: nickname,
      );
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in addPaymentMethod: $e');
      rethrow;
    }
  }

  /// Update a payment method
  Future<CustomerPaymentMethod> updatePaymentMethod({
    required String paymentMethodId,
    String? nickname,
  }) async {
    try {
      return await _service.updatePaymentMethod(
        paymentMethodId: paymentMethodId,
        nickname: nickname,
      );
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in updatePaymentMethod: $e');
      rethrow;
    }
  }

  /// Delete a payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      await _service.deletePaymentMethod(paymentMethodId);
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in deletePaymentMethod: $e');
      rethrow;
    }
  }

  /// Set a payment method as default
  Future<CustomerPaymentMethod> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      return await _service.setDefaultPaymentMethod(paymentMethodId);
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in setDefaultPaymentMethod: $e');
      rethrow;
    }
  }

  /// Get the default payment method for the current user
  Future<CustomerPaymentMethod?> getDefaultPaymentMethod() async {
    debugPrint('🔄 [PAYMENT-METHODS-REPO] Fetching default payment method from service');

    try {
      final defaultMethod = await _service.getDefaultPaymentMethod();

      if (defaultMethod != null) {
        debugPrint('✅ [PAYMENT-METHODS-REPO] Default payment method found: ${defaultMethod.displayName} (ID: ${defaultMethod.id})');
      } else {
        debugPrint('ℹ️ [PAYMENT-METHODS-REPO] No default payment method found in service');
      }

      return defaultMethod;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getDefaultPaymentMethod: $e');
      return null;
    }
  }

  /// Check if user has any saved payment methods
  Future<bool> hasPaymentMethods() async {
    debugPrint('🔄 [PAYMENT-METHODS-REPO] Checking if user has payment methods');

    try {
      final hasPaymentMethods = await _service.hasPaymentMethods();
      debugPrint('📊 [PAYMENT-METHODS-REPO] User has payment methods: $hasPaymentMethods');
      return hasPaymentMethods;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in hasPaymentMethods: $e');
      return false;
    }
  }

  /// Get payment method by ID
  Future<CustomerPaymentMethod?> getPaymentMethodById(String paymentMethodId) async {
    try {
      return await _service.getPaymentMethodById(paymentMethodId);
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getPaymentMethodById: $e');
      return null;
    }
  }

  /// Validate payment method
  bool isPaymentMethodValid(CustomerPaymentMethod paymentMethod) {
    return _service.isPaymentMethodValid(paymentMethod);
  }

  /// Get user-friendly error message
  String getErrorMessage(String error) {
    return _service.getErrorMessage(error);
  }

  /// Format card display name
  String formatCardDisplayName(CustomerPaymentMethod paymentMethod) {
    return _service.formatCardDisplayName(paymentMethod);
  }

  /// Check if payment method can be deleted
  Future<bool> canDeletePaymentMethod(String paymentMethodId) async {
    try {
      return await _service.canDeletePaymentMethod(paymentMethodId);
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in canDeletePaymentMethod: $e');
      return false;
    }
  }

  /// Get active payment methods only
  Future<List<CustomerPaymentMethod>> getActivePaymentMethods() async {
    try {
      final allMethods = await getPaymentMethods();
      return allMethods.where((method) => method.isActive).toList();
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getActivePaymentMethods: $e');
      rethrow;
    }
  }

  /// Get valid payment methods (active and not expired)
  Future<List<CustomerPaymentMethod>> getValidPaymentMethods() async {
    try {
      final allMethods = await getPaymentMethods();
      return allMethods.where((method) => isPaymentMethodValid(method)).toList();
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getValidPaymentMethods: $e');
      rethrow;
    }
  }

  /// Get payment methods by type
  Future<List<CustomerPaymentMethod>> getPaymentMethodsByType(
    CustomerPaymentMethodType type,
  ) async {
    try {
      final allMethods = await getPaymentMethods();
      return allMethods.where((method) => method.type == type).toList();
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getPaymentMethodsByType: $e');
      rethrow;
    }
  }

  /// Get card payment methods only
  Future<List<CustomerPaymentMethod>> getCardPaymentMethods() async {
    return getPaymentMethodsByType(CustomerPaymentMethodType.card);
  }

  /// Get bank account payment methods only
  Future<List<CustomerPaymentMethod>> getBankAccountPaymentMethods() async {
    return getPaymentMethodsByType(CustomerPaymentMethodType.bankAccount);
  }

  /// Get digital wallet payment methods only
  Future<List<CustomerPaymentMethod>> getDigitalWalletPaymentMethods() async {
    return getPaymentMethodsByType(CustomerPaymentMethodType.digitalWallet);
  }

  /// Check if user has a default payment method
  Future<bool> hasDefaultPaymentMethod() async {
    try {
      final defaultMethod = await getDefaultPaymentMethod();
      return defaultMethod != null;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in hasDefaultPaymentMethod: $e');
      return false;
    }
  }

  /// Get payment methods count
  Future<int> getPaymentMethodsCount() async {
    try {
      final methods = await getPaymentMethods();
      return methods.length;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getPaymentMethodsCount: $e');
      return 0;
    }
  }

  /// Get expired payment methods
  Future<List<CustomerPaymentMethod>> getExpiredPaymentMethods() async {
    try {
      final allMethods = await getPaymentMethods();
      return allMethods.where((method) => 
        method.type == CustomerPaymentMethodType.card && method.isExpired
      ).toList();
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-REPO] Error in getExpiredPaymentMethods: $e');
      rethrow;
    }
  }
}
