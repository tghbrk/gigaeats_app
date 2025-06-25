import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/customer_payment_method.dart';
import '../../data/repositories/customer_payment_method_repository.dart';

part 'customer_payment_methods_provider.g.dart';

/// Repository provider for customer payment methods
@riverpod
CustomerPaymentMethodRepository customerPaymentMethodRepository(
  Ref ref,
) {
  return CustomerPaymentMethodRepository();
}

/// Provider for customer payment methods list
@riverpod
class CustomerPaymentMethods extends _$CustomerPaymentMethods {
  @override
  Future<List<CustomerPaymentMethod>> build() async {
    final repository = ref.watch(customerPaymentMethodRepositoryProvider);
    return repository.getPaymentMethods();
  }

  /// Refresh payment methods
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(customerPaymentMethodRepositoryProvider);
      return repository.getPaymentMethods();
    });
  }

  /// Add a new payment method
  Future<void> addPaymentMethod({
    required String stripePaymentMethodId,
    String? nickname,
  }) async {
    try {
      final repository = ref.read(customerPaymentMethodRepositoryProvider);
      
      debugPrint('🔍 [PAYMENT-METHODS-PROVIDER] Adding payment method');
      
      final newPaymentMethod = await repository.addPaymentMethod(
        stripePaymentMethodId: stripePaymentMethodId,
        nickname: nickname,
      );

      // Update state optimistically
      state = state.whenData((methods) => [newPaymentMethod, ...methods]);
      
      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] Payment method added successfully');
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Error adding payment method: $e');
      rethrow;
    }
  }

  /// Update a payment method
  Future<void> updatePaymentMethod({
    required String paymentMethodId,
    String? nickname,
  }) async {
    try {
      final repository = ref.read(customerPaymentMethodRepositoryProvider);
      
      debugPrint('🔍 [PAYMENT-METHODS-PROVIDER] Updating payment method: $paymentMethodId');
      
      final updatedPaymentMethod = await repository.updatePaymentMethod(
        paymentMethodId: paymentMethodId,
        nickname: nickname,
      );

      // Update state optimistically
      state = state.whenData((methods) => methods.map((method) {
        return method.id == paymentMethodId ? updatedPaymentMethod : method;
      }).toList());
      
      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] Payment method updated successfully');
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Error updating payment method: $e');
      rethrow;
    }
  }

  /// Delete a payment method
  Future<void> deletePaymentMethod(String paymentMethodId) async {
    try {
      final repository = ref.read(customerPaymentMethodRepositoryProvider);
      
      debugPrint('🔍 [PAYMENT-METHODS-PROVIDER] Deleting payment method: $paymentMethodId');
      
      await repository.deletePaymentMethod(paymentMethodId);

      // Update state optimistically
      state = state.whenData((methods) => 
        methods.where((method) => method.id != paymentMethodId).toList()
      );
      
      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] Payment method deleted successfully');
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Error deleting payment method: $e');
      rethrow;
    }
  }

  /// Set a payment method as default
  Future<void> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final repository = ref.read(customerPaymentMethodRepositoryProvider);
      
      debugPrint('🔍 [PAYMENT-METHODS-PROVIDER] Setting default payment method: $paymentMethodId');
      
      final updatedPaymentMethod = await repository.setDefaultPaymentMethod(paymentMethodId);

      // Update state optimistically
      state = state.whenData((methods) => methods.map((method) {
        if (method.id == paymentMethodId) {
          return updatedPaymentMethod;
        } else {
          return method.copyWith(isDefault: false);
        }
      }).toList());
      
      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] Default payment method set successfully');
    } catch (e) {
      debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Error setting default payment method: $e');
      rethrow;
    }
  }
}

/// Provider for default payment method
@riverpod
Future<CustomerPaymentMethod?> customerDefaultPaymentMethod(
  Ref ref,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.getDefaultPaymentMethod();
}

/// Provider for checking if user has payment methods
@riverpod
Future<bool> customerHasPaymentMethods(
  Ref ref,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.hasPaymentMethods();
}

/// Provider for active payment methods only
@riverpod
Future<List<CustomerPaymentMethod>> customerActivePaymentMethods(
  Ref ref,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.getActivePaymentMethods();
}

/// Provider for valid payment methods (active and not expired)
@riverpod
Future<List<CustomerPaymentMethod>> customerValidPaymentMethods(
  Ref ref,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.getValidPaymentMethods();
}

/// Provider for card payment methods only
@riverpod
Future<List<CustomerPaymentMethod>> customerCardPaymentMethods(
  Ref ref,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.getCardPaymentMethods();
}

/// Provider for payment methods count
@riverpod
Future<int> customerPaymentMethodsCount(
  Ref ref,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.getPaymentMethodsCount();
}

/// Provider for expired payment methods
@riverpod
Future<List<CustomerPaymentMethod>> customerExpiredPaymentMethods(
  Ref ref,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.getExpiredPaymentMethods();
}

/// Provider for specific payment method by ID
@riverpod
Future<CustomerPaymentMethod?> customerPaymentMethodById(
  Ref ref,
  String paymentMethodId,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.getPaymentMethodById(paymentMethodId);
}

/// Provider for checking if payment method can be deleted
@riverpod
Future<bool> canDeleteCustomerPaymentMethod(
  Ref ref,
  String paymentMethodId,
) async {
  final repository = ref.watch(customerPaymentMethodRepositoryProvider);
  return repository.canDeletePaymentMethod(paymentMethodId);
}
