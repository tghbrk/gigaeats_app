import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/customer.dart';
import '../../data/repositories/customer_repository.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// Customer state for managing customer data
class CustomerState {
  final List<Customer> customers;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final CustomerType? selectedType;
  final bool? isActiveFilter;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedType,
    this.isActiveFilter,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    CustomerType? selectedType,
    bool? isActiveFilter,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedType: selectedType ?? this.selectedType,
      isActiveFilter: isActiveFilter ?? this.isActiveFilter,
    );
  }
}

/// Customer notifier for managing customer operations
class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerRepository _repository;
  final Ref _ref;

  CustomerNotifier(this._repository, this._ref) : super(const CustomerState());

  /// Load customers with optional filters
  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      final customers = await _repository.getCustomers(
        searchQuery: state.searchQuery.isNotEmpty ? state.searchQuery : null,
        type: state.selectedType,
        isActive: state.isActiveFilter ?? true, // Default to showing only active customers
      );

      state = state.copyWith(
        customers: customers,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      debugPrint('CustomerNotifier: Error loading customers: $e');
      debugPrint('CustomerNotifier: Stack trace: $stackTrace');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load customers: ${e.toString()}',
      );
    }
  }

  /// Search customers
  Future<void> searchCustomers(String query) async {
    state = state.copyWith(searchQuery: query);
    await loadCustomers();
  }

  /// Filter by customer type
  Future<void> filterByType(CustomerType? type) async {
    state = state.copyWith(selectedType: type);
    await loadCustomers();
  }

  /// Filter by active status
  Future<void> filterByActiveStatus(bool? isActive) async {
    state = state.copyWith(isActiveFilter: isActive);
    await loadCustomers();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    state = state.copyWith(
      searchQuery: '',
      selectedType: null,
      isActiveFilter: null,
    );
    await loadCustomers();
  }

  /// Create new customer
  Future<Customer?> createCustomer(Customer customer) async {
    try {
      debugPrint('CustomerNotifier: Starting customer creation...');
      debugPrint('CustomerNotifier: Customer data: ${customer.toJson()}');

      final newCustomer = await _repository.createCustomer(customer);
      debugPrint('CustomerNotifier: Customer created successfully: ${newCustomer.toJson()}');

      await loadCustomers(); // Refresh the list
      return newCustomer;
    } catch (e) {
      debugPrint('CustomerNotifier: Error creating customer: $e');
      debugPrint('CustomerNotifier: Error type: ${e.runtimeType}');
      debugPrint('CustomerNotifier: Stack trace: ${StackTrace.current}');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Update customer
  Future<Customer?> updateCustomer(Customer customer) async {
    try {
      debugPrint('🔧 CustomerNotifier: updateCustomer called for ${customer.organizationName} (${customer.id})');
      final updatedCustomer = await _repository.updateCustomer(customer);
      debugPrint('🔧 CustomerNotifier: Customer updated successfully, refreshing list...');
      await loadCustomers(); // Refresh the list
      debugPrint('🔧 CustomerNotifier: Customer list refreshed');

      // Invalidate the individual customer cache to ensure fresh data
      debugPrint('🔧 CustomerNotifier: Invalidating customerByIdProvider cache for ${customer.id}');
      _ref.invalidate(customerByIdProvider(customer.id));
      debugPrint('🔧 CustomerNotifier: Cache invalidated');

      return updatedCustomer;
    } catch (e) {
      debugPrint('CustomerNotifier: Error updating customer: $e');
      debugPrint('CustomerNotifier: Error type: ${e.runtimeType}');
      debugPrint('CustomerNotifier: Stack trace: ${StackTrace.current}');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Delete customer (soft delete)
  Future<bool> deleteCustomer(String customerId) async {
    try {
      debugPrint('🔧 CustomerNotifier: deleteCustomer called for ID: $customerId');
      await _repository.deleteCustomer(customerId);
      debugPrint('🔧 CustomerNotifier: Customer deleted successfully, refreshing list...');
      await loadCustomers(); // Refresh the list
      debugPrint('🔧 CustomerNotifier: Customer list refreshed');
      return true;
    } catch (e) {
      debugPrint('CustomerNotifier: Error deleting customer: $e');
      debugPrint('CustomerNotifier: Error type: ${e.runtimeType}');
      debugPrint('CustomerNotifier: Stack trace: ${StackTrace.current}');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Add note to customer
  Future<bool> addNote(String customerId, String note) async {
    try {
      await _repository.addCustomerNote(customerId, note);
      await loadCustomers(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('CustomerNotifier: Error adding note: $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Add tag to customer
  Future<bool> addTag(String customerId, String tag) async {
    try {
      await _repository.addCustomerTag(customerId, tag);
      await loadCustomers(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('CustomerNotifier: Error adding tag: $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Remove tag from customer
  Future<bool> removeTag(String customerId, String tag) async {
    try {
      await _repository.removeCustomerTag(customerId, tag);
      await loadCustomers(); // Refresh the list
      return true;
    } catch (e) {
      debugPrint('CustomerNotifier: Error removing tag: $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }
}

/// Customer provider
final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  final repository = ref.watch(customerRepositoryProvider);
  return CustomerNotifier(repository, ref);
});

/// Web-specific customer provider for platform-aware data fetching
final webCustomersProvider = FutureProvider.family<List<Customer>, Map<String, dynamic>>((ref, params) async {
  debugPrint('🌐 webCustomersProvider: Called with params: $params');

  final repository = ref.watch(customerRepositoryProvider);
  debugPrint('🌐 webCustomersProvider: Repository obtained');

  final result = await repository.getCustomers(
    searchQuery: params['searchQuery'] as String?,
    type: params['type'] as CustomerType?,
    isActive: params['isActive'] as bool?,
    limit: params['limit'] as int? ?? 50,
    offset: params['offset'] as int? ?? 0,
  );

  debugPrint('🌐 webCustomersProvider: Repository returned ${result.length} customers');
  return result;
});

/// Simple web customers provider without parameters for basic usage
final simpleWebCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomers(isActive: true); // Default to showing only active customers
});

/// Customer by ID provider
final customerByIdProvider = FutureProvider.family<Customer?, String>((ref, customerId) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomerById(customerId);
});

/// Top customers provider
final topCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getTopCustomers();
});

/// Customer statistics provider
final customerStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomerStatistics();
});

/// Recent customers provider
final recentCustomersProvider = FutureProvider<List<Customer>>((ref) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.getCustomersWithRecentOrders();
});

/// Search customers provider
final searchCustomersProvider = FutureProvider.family<List<Customer>, String>((ref, query) async {
  final repository = ref.watch(customerRepositoryProvider);
  return repository.searchCustomers(query);
});
