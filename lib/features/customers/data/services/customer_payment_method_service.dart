import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_payment_method.dart';

/// Service for managing customer payment methods with Stripe integration
class CustomerPaymentMethodService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all payment methods for the current user
  Future<List<CustomerPaymentMethod>> getPaymentMethods() async {
    try {
      debugPrint('🔍 [PAYMENT-METHODS] Fetching payment methods');

      final response = await _supabase.functions.invoke(
        'customer-payment-methods',
        body: {
          'action': 'list',
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to fetch payment methods');
      }

      final List<dynamic> data = response.data['data'] ?? [];
      final paymentMethods = data
          .map((json) => CustomerPaymentMethod.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [PAYMENT-METHODS] Found ${paymentMethods.length} payment methods');
      return paymentMethods;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error fetching payment methods: $e');
      throw Exception('Failed to fetch payment methods: $e');
    }
  }

  /// Add a new payment method
  Future<CustomerPaymentMethod> addPaymentMethod({
    required String stripePaymentMethodId,
    String? nickname,
  }) async {
    try {
      debugPrint('🔍 [PAYMENT-METHODS] Adding payment method: $stripePaymentMethodId');

      final response = await _supabase.functions.invoke(
        'customer-payment-methods',
        body: {
          'action': 'add',
          'stripe_payment_method_id': stripePaymentMethodId,
          'nickname': nickname,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to add payment method');
      }

      final paymentMethod = CustomerPaymentMethod.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [PAYMENT-METHODS] Added payment method: ${paymentMethod.id}');
      return paymentMethod;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error adding payment method: $e');
      throw Exception('Failed to add payment method: $e');
    }
  }

  /// Update a payment method
  Future<CustomerPaymentMethod> updatePaymentMethod({
    required String paymentMethodId,
    String? nickname,
  }) async {
    try {
      debugPrint('🔍 [PAYMENT-METHODS] Updating payment method: $paymentMethodId');

      final response = await _supabase.functions.invoke(
        'customer-payment-methods',
        body: {
          'action': 'update',
          'payment_method_id': paymentMethodId,
          'nickname': nickname,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to update payment method');
      }

      final paymentMethod = CustomerPaymentMethod.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [PAYMENT-METHODS] Updated payment method: ${paymentMethod.id}');
      return paymentMethod;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error updating payment method: $e');
      throw Exception('Failed to update payment method: $e');
    }
  }

  /// Delete a payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      debugPrint('🔍 [PAYMENT-METHODS] Deleting payment method: $paymentMethodId');

      final response = await _supabase.functions.invoke(
        'customer-payment-methods',
        body: {
          'action': 'delete',
          'payment_method_id': paymentMethodId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to delete payment method');
      }

      debugPrint('✅ [PAYMENT-METHODS] Deleted payment method: $paymentMethodId');
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error deleting payment method: $e');
      throw Exception('Failed to delete payment method: $e');
    }
  }

  /// Set a payment method as default
  Future<CustomerPaymentMethod> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      debugPrint('🔍 [PAYMENT-METHODS] Setting default payment method: $paymentMethodId');

      final response = await _supabase.functions.invoke(
        'customer-payment-methods',
        body: {
          'action': 'set_default',
          'payment_method_id': paymentMethodId,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to set default payment method');
      }

      final paymentMethod = CustomerPaymentMethod.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [PAYMENT-METHODS] Set default payment method: ${paymentMethod.id}');
      return paymentMethod;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error setting default payment method: $e');
      throw Exception('Failed to set default payment method: $e');
    }
  }

  /// Get the default payment method for the current user
  Future<CustomerPaymentMethod?> getDefaultPaymentMethod() async {
    try {
      final paymentMethods = await getPaymentMethods();
      return paymentMethods.where((pm) => pm.isDefault).firstOrNull;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error getting default payment method: $e');
      return null;
    }
  }

  /// Check if user has any saved payment methods
  Future<bool> hasPaymentMethods() async {
    try {
      final paymentMethods = await getPaymentMethods();
      return paymentMethods.isNotEmpty;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error checking payment methods: $e');
      return false;
    }
  }

  /// Get payment method by ID
  Future<CustomerPaymentMethod?> getPaymentMethodById(String paymentMethodId) async {
    try {
      final paymentMethods = await getPaymentMethods();
      return paymentMethods.where((pm) => pm.id == paymentMethodId).firstOrNull;
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS] Error getting payment method by ID: $e');
      return null;
    }
  }

  /// Validate payment method (check if not expired for cards)
  bool isPaymentMethodValid(CustomerPaymentMethod paymentMethod) {
    // Check if payment method is active
    if (!paymentMethod.isActive) {
      return false;
    }

    // Check if card is expired
    if (paymentMethod.type == CustomerPaymentMethodType.card && paymentMethod.isExpired) {
      return false;
    }

    return true;
  }

  /// Get user-friendly error message
  String getErrorMessage(String error) {
    if (error.contains('payment_method_not_found')) {
      return 'Payment method not found. Please try again.';
    } else if (error.contains('stripe_error')) {
      return 'Payment service error. Please try again later.';
    } else if (error.contains('unauthorized')) {
      return 'You are not authorized to perform this action.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.contains('expired')) {
      return 'This payment method has expired. Please add a new one.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Format card display name
  String formatCardDisplayName(CustomerPaymentMethod paymentMethod) {
    if (paymentMethod.type != CustomerPaymentMethodType.card) {
      return paymentMethod.displayName;
    }

    final brand = paymentMethod.cardBrand?.name.toUpperCase() ?? 'CARD';
    final last4 = paymentMethod.cardLast4 ?? '****';
    final expiry = paymentMethod.formattedExpiry ?? '';
    
    return '$brand •••• $last4${expiry.isNotEmpty ? ' ($expiry)' : ''}';
  }

  /// Check if payment method can be deleted (not the only payment method)
  Future<bool> canDeletePaymentMethod(String paymentMethodId) async {
    try {
      final paymentMethods = await getPaymentMethods();
      return paymentMethods.length > 1;
    } catch (e) {
      return false;
    }
  }
}
