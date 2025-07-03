import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/customer_payment_method.dart';
import '../../data/repositories/customer_payment_method_repository.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

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
    debugPrint('🔄 [PAYMENT-METHODS-PROVIDER] Building payment methods provider');

    try {
      // Check authentication status first
      final authState = ref.watch(authStateProvider);
      debugPrint('🔐 [PAYMENT-METHODS-PROVIDER] Auth status: ${authState.status}');

      if (authState.status != AuthStatus.authenticated || authState.user == null) {
        debugPrint('❌ [PAYMENT-METHODS-PROVIDER] User not authenticated, returning empty list');
        throw Exception('User not authenticated. Please sign in to view payment methods.');
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [PAYMENT-METHODS-PROVIDER] No current Supabase user session');
        throw Exception('No active user session. Please sign in again.');
      }

      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] User authenticated: ${currentUser.id}');

      final repository = ref.watch(customerPaymentMethodRepositoryProvider);
      debugPrint('🔍 [PAYMENT-METHODS-PROVIDER] Fetching payment methods from repository');

      final methods = await repository.getPaymentMethods();

      debugPrint('📊 [PAYMENT-METHODS-PROVIDER] Fetched ${methods.length} payment methods');
      for (int i = 0; i < methods.length; i++) {
        final method = methods[i];
        debugPrint('  📋 [PAYMENT-METHODS-PROVIDER] Method $i: ${method.displayName} (default: ${method.isDefault}, active: ${method.isActive}, type: ${method.type})');
      }

      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] Successfully built payment methods provider');
      return methods;
    } catch (e, stack) {
      debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Error building payment methods provider: $e');
      debugPrint('📍 [PAYMENT-METHODS-PROVIDER] Stack trace: $stack');
      rethrow;
    }
  }

  /// Refresh payment methods
  Future<void> refresh() async {
    debugPrint('🔄 [PAYMENT-METHODS-PROVIDER] Refreshing payment methods');

    state = const AsyncValue.loading();
    debugPrint('🔄 [PAYMENT-METHODS-PROVIDER] Set state to loading');

    state = await AsyncValue.guard(() async {
      debugPrint('🔍 [PAYMENT-METHODS-PROVIDER] Fetching fresh payment methods');

      // Check authentication status first
      final authState = ref.read(authStateProvider);
      debugPrint('🔐 [PAYMENT-METHODS-PROVIDER] Auth status during refresh: ${authState.status}');

      if (authState.status != AuthStatus.authenticated || authState.user == null) {
        debugPrint('❌ [PAYMENT-METHODS-PROVIDER] User not authenticated during refresh');
        throw Exception('User not authenticated. Please sign in to refresh payment methods.');
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [PAYMENT-METHODS-PROVIDER] No current Supabase user session during refresh');
        throw Exception('No active user session. Please sign in again.');
      }

      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] User authenticated during refresh: ${currentUser.id}');

      final repository = ref.read(customerPaymentMethodRepositoryProvider);
      final methods = await repository.getPaymentMethods();

      debugPrint('📊 [PAYMENT-METHODS-PROVIDER] Refreshed ${methods.length} payment methods');
      return methods;
    });

    state.when(
      data: (methods) => debugPrint('✅ [PAYMENT-METHODS-PROVIDER] Refresh completed successfully with ${methods.length} methods'),
      loading: () => debugPrint('🔄 [PAYMENT-METHODS-PROVIDER] Still loading after refresh'),
      error: (error, stack) => debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Refresh failed: $error'),
    );
  }

  /// Add a new payment method
  Future<void> addPaymentMethod({
    required String stripePaymentMethodId,
    String? nickname,
  }) async {
    try {
      // Check authentication status first
      final authState = ref.read(authStateProvider);
      debugPrint('🔐 [PAYMENT-METHODS-PROVIDER] Auth status during add: ${authState.status}');

      if (authState.status != AuthStatus.authenticated || authState.user == null) {
        debugPrint('❌ [PAYMENT-METHODS-PROVIDER] User not authenticated during add');
        throw Exception('User not authenticated. Please sign in to add payment methods.');
      }

      final currentUser = Supabase.instance.client.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [PAYMENT-METHODS-PROVIDER] No current Supabase user session during add');
        throw Exception('No active user session. Please sign in again.');
      }

      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] User authenticated during add: ${currentUser.id}');

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
  debugPrint('🔄 [PAYMENT-METHODS-PROVIDER] Fetching default payment method');

  try {
    final repository = ref.watch(customerPaymentMethodRepositoryProvider);
    final defaultMethod = await repository.getDefaultPaymentMethod();

    if (defaultMethod != null) {
      debugPrint('✅ [PAYMENT-METHODS-PROVIDER] Default payment method found: ${defaultMethod.displayName} (ID: ${defaultMethod.id})');
    } else {
      debugPrint('ℹ️ [PAYMENT-METHODS-PROVIDER] No default payment method found');
    }

    return defaultMethod;
  } catch (e, stack) {
    debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Error fetching default payment method: $e');
    debugPrint('📍 [PAYMENT-METHODS-PROVIDER] Stack trace: $stack');
    rethrow;
  }
}

/// Provider for checking if user has payment methods
@riverpod
Future<bool> customerHasPaymentMethods(
  Ref ref,
) async {
  debugPrint('🔄 [PAYMENT-METHODS-PROVIDER] Checking if user has payment methods');

  try {
    final repository = ref.watch(customerPaymentMethodRepositoryProvider);
    final hasPaymentMethods = await repository.hasPaymentMethods();

    debugPrint('📊 [PAYMENT-METHODS-PROVIDER] User has payment methods: $hasPaymentMethods');
    return hasPaymentMethods;
  } catch (e, stack) {
    debugPrint('❌ [PAYMENT-METHODS-PROVIDER] Error checking if user has payment methods: $e');
    debugPrint('📍 [PAYMENT-METHODS-PROVIDER] Stack trace: $stack');
    return false;
  }
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
