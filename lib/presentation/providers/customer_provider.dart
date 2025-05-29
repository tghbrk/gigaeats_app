import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';

import '../../data/models/customer.dart';
import '../../data/services/customer_service.dart';

// Customer Service Provider
final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService();
});

// Customer State
class CustomerState {
  final List<Customer> customers;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;

  CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 0,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
    );
  }
}

// Customer Notifier
class CustomerNotifier extends StateNotifier<CustomerState> {
  final CustomerService _customerService;
  // final Ref _ref; // TODO: Use for cross-provider communication

  CustomerNotifier(this._customerService, Ref ref) : super(CustomerState());

  Future<void> loadCustomers({
    String? searchQuery,
    CustomerType? type,
    String? salesAgentId,
    bool? isActive,
    bool refresh = false,
  }) async {
    if (refresh) {
      state = CustomerState(isLoading: true);
    } else if (state.isLoading || !state.hasMore) {
      return;
    } else {
      state = state.copyWith(isLoading: true);
    }

    try {
      final customers = await _customerService.getCustomers(
        searchQuery: searchQuery,
        type: type,
        salesAgentId: salesAgentId,
        isActive: isActive,
        limit: 20,
        offset: refresh ? 0 : state.customers.length,
      );

      if (refresh) {
        state = state.copyWith(
          customers: customers,
          isLoading: false,
          hasMore: customers.length >= 20,
          currentPage: 1,
          errorMessage: null,
        );
      } else {
        state = state.copyWith(
          customers: [...state.customers, ...customers],
          isLoading: false,
          hasMore: customers.length >= 20,
          currentPage: state.currentPage + 1,
          errorMessage: null,
        );
      }
    } catch (e) {
      debugPrint('Error loading customers: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load customers: ${e.toString()}',
      );
    }
  }

  Future<Customer?> createCustomer({
    required String salesAgentId,
    required CustomerType type,
    required String organizationName,
    required String contactPersonName,
    required String email,
    required String phoneNumber,
    String? alternatePhoneNumber,
    required CustomerAddress address,
    CustomerBusinessInfo? businessInfo,
    CustomerPreferences? preferences,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final customer = await _customerService.createCustomer(
        salesAgentId: salesAgentId,
        type: type,
        organizationName: organizationName,
        contactPersonName: contactPersonName,
        email: email,
        phoneNumber: phoneNumber,
        alternatePhoneNumber: alternatePhoneNumber,
        address: address,
        businessInfo: businessInfo,
        preferences: preferences,
        notes: notes,
        tags: tags,
      );

      // Add to the beginning of the list
      state = state.copyWith(
        customers: [customer, ...state.customers],
      );

      return customer;
    } catch (e) {
      debugPrint('Error creating customer: $e');
      state = state.copyWith(
        errorMessage: 'Failed to create customer: ${e.toString()}',
      );
      return null;
    }
  }

  Future<Customer?> updateCustomer({
    required String customerId,
    String? organizationName,
    String? contactPersonName,
    String? email,
    String? phoneNumber,
    String? alternatePhoneNumber,
    CustomerAddress? address,
    CustomerBusinessInfo? businessInfo,
    CustomerPreferences? preferences,
    bool? isActive,
    bool? isVerified,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final updatedCustomer = await _customerService.updateCustomer(
        customerId: customerId,
        organizationName: organizationName,
        contactPersonName: contactPersonName,
        email: email,
        phoneNumber: phoneNumber,
        alternatePhoneNumber: alternatePhoneNumber,
        address: address,
        businessInfo: businessInfo,
        preferences: preferences,
        isActive: isActive,
        isVerified: isVerified,
        notes: notes,
        tags: tags,
      );

      if (updatedCustomer != null) {
        final updatedCustomers = state.customers.map((customer) {
          return customer.id == customerId ? updatedCustomer : customer;
        }).toList();

        state = state.copyWith(customers: updatedCustomers);
      }

      return updatedCustomer;
    } catch (e) {
      debugPrint('Error updating customer: $e');
      state = state.copyWith(
        errorMessage: 'Failed to update customer: ${e.toString()}',
      );
      return null;
    }
  }

  Future<bool> deleteCustomer(String customerId) async {
    try {
      final success = await _customerService.deleteCustomer(customerId);

      if (success) {
        final updatedCustomers = state.customers.where((customer) => customer.id != customerId).toList();
        state = state.copyWith(customers: updatedCustomers);
      }

      return success;
    } catch (e) {
      debugPrint('Error deleting customer: $e');
      state = state.copyWith(
        errorMessage: 'Failed to delete customer: ${e.toString()}',
      );
      return false;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }
}

// Providers
final customersProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  final customerService = ref.read(customerServiceProvider);
  return CustomerNotifier(customerService, ref);
});

// Individual customer provider
final customerProvider = FutureProvider.family<Customer?, String>((ref, customerId) async {
  final customerService = ref.read(customerServiceProvider);
  return await customerService.getCustomerById(customerId);
});

// Recent customers provider
final recentCustomersProvider = FutureProvider.family<List<Customer>, String?>((ref, salesAgentId) async {
  final customerService = ref.read(customerServiceProvider);
  return await customerService.getRecentCustomers(salesAgentId: salesAgentId);
});

// Customer search provider
final customerSearchProvider = FutureProvider.family<List<Customer>, Map<String, String?>>((ref, params) async {
  final customerService = ref.read(customerServiceProvider);
  return await customerService.searchCustomers(
    query: params['query'] ?? '',
    salesAgentId: params['salesAgentId'],
  );
});

// Customer stats provider
final customerStatsProvider = FutureProvider.family<Map<String, dynamic>, String?>((ref, salesAgentId) async {
  final customerService = ref.read(customerServiceProvider);
  return await customerService.getCustomerStats(salesAgentId: salesAgentId);
});
