import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/customer.dart';

/// Customer provider for managing customer data
final customerProvider = StateNotifierProvider<CustomerNotifier, CustomerState>((ref) {
  return CustomerNotifier();
});

/// Customer state
class CustomerState {
  final List<Customer> customers;
  final bool isLoading;
  final String? errorMessage;

  const CustomerState({
    this.customers = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CustomerState copyWith({
    List<Customer>? customers,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CustomerState(
      customers: customers ?? this.customers,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Customer notifier
class CustomerNotifier extends StateNotifier<CustomerState> {
  CustomerNotifier() : super(const CustomerState());

  Future<void> loadCustomers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    
    try {
      // In a real app, this would fetch from repository
      await Future.delayed(const Duration(seconds: 1));
      
      final customers = <Customer>[
        // Mock customers
      ];
      
      state = state.copyWith(
        customers: customers,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void addCustomer(Customer customer) {
    state = state.copyWith(
      customers: [...state.customers, customer],
    );
  }

  void updateCustomer(Customer customer) {
    final updatedCustomers = state.customers.map((c) {
      return c.id == customer.id ? customer : c;
    }).toList();
    
    state = state.copyWith(customers: updatedCustomers);
  }

  void removeCustomer(String customerId) {
    final updatedCustomers = state.customers.where((c) => c.id != customerId).toList();
    state = state.copyWith(customers: updatedCustomers);
  }
}

/// Provider for getting a specific customer by ID
final customerByIdProvider = Provider.family<Customer?, String>((ref, customerId) {
  final customers = ref.watch(customerProvider).customers;
  try {
    return customers.firstWhere((customer) => customer.id == customerId);
  } catch (e) {
    return null;
  }
});

/// Provider for getting customers by sales agent
final customersBySalesAgentProvider = Provider.family<List<Customer>, String>((ref, salesAgentId) {
  final customers = ref.watch(customerProvider).customers;
  return customers.where((customer) => customer.salesAgentId == salesAgentId).toList();
});
