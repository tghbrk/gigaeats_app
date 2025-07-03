import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../customers/data/models/customer.dart';
import '../../../../customers/data/repositories/customer_repository.dart';
import '../../../../../core/services/auth_service.dart';

/// Provider for customer repository
final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository();
});

/// Provider for auth service
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider for current customer profile
final currentCustomerProfileProvider = FutureProvider<Customer?>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final customerRepository = ref.watch(customerRepositoryProvider);
  
  final user = authService.currentUser;
  if (user == null) return null;
  
  try {
    return await customerRepository.getCustomerByUserId(user.id);
  } catch (e) {
    // Return null if customer not found or error occurs
    return null;
  }
});

/// Provider for customer profile by ID
final customerProfileProvider = FutureProvider.family<Customer?, String>((ref, customerId) async {
  final customerRepository = ref.watch(customerRepositoryProvider);
  
  try {
    return await customerRepository.getCustomerById(customerId);
  } catch (e) {
    return null;
  }
});

/// Provider for customers by sales agent
final customersBySalesAgentProvider = FutureProvider.family<List<Customer>, String>((ref, salesAgentId) async {
  final customerRepository = ref.watch(customerRepositoryProvider);
  
  try {
    return await customerRepository.getCustomersBySalesAgent(salesAgentId: salesAgentId);
  } catch (e) {
    return [];
  }
});

/// Provider for customer statistics
final customerStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, customerId) async {
  final customerRepository = ref.watch(customerRepositoryProvider);
  
  try {
    return await customerRepository.getCustomerStats(customerId);
  } catch (e) {
    return {};
  }
});
