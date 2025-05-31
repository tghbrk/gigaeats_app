import '../models/customer.dart';
import 'mock_data.dart';

class CustomerService {
  // In a real app, this would make API calls
  // TODO: Replace with actual API integration

  Future<List<Customer>> getCustomers({
    String? searchQuery,
    CustomerType? type,
    String? salesAgentId,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    var customers = MockData.sampleCustomers;

    // Apply filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      customers = customers.where((customer) {
        final query = searchQuery.toLowerCase();
        return customer.organizationName.toLowerCase().contains(query) ||
            customer.contactPersonName.toLowerCase().contains(query) ||
            customer.email.toLowerCase().contains(query) ||
            customer.phoneNumber.contains(query);
      }).toList();
    }

    if (type != null) {
      customers = customers.where((customer) => customer.type == type).toList();
    }

    if (salesAgentId != null) {
      customers = customers.where((customer) => customer.salesAgentId == salesAgentId).toList();
    }

    if (isActive != null) {
      customers = customers.where((customer) => customer.isActive == isActive).toList();
    }

    // Apply pagination
    final startIndex = offset;
    final endIndex = (offset + limit).clamp(0, customers.length);
    
    if (startIndex >= customers.length) {
      return [];
    }

    return customers.sublist(startIndex, endIndex);
  }

  Future<Customer?> getCustomerById(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 200));

    // TODO: Replace with actual API call
    try {
      return MockData.sampleCustomers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  Future<Customer> createCustomer({
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
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Replace with actual API call
    final now = DateTime.now();
    final customer = Customer(
      id: 'cust_${DateTime.now().millisecondsSinceEpoch}',
      salesAgentId: salesAgentId,
      type: type,
      organizationName: organizationName,
      contactPersonName: contactPersonName,
      email: email,
      phoneNumber: phoneNumber,
      alternatePhoneNumber: alternatePhoneNumber,
      address: address,
      businessInfo: businessInfo,
      preferences: preferences ?? const CustomerPreferences(),
      lastOrderDate: now,
      notes: notes,
      tags: tags ?? [],
      createdAt: now,
      updatedAt: now,
    );

    // In a real app, this would be saved to the database
    MockData.sampleCustomers.add(customer);

    return customer;
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
    await Future.delayed(const Duration(milliseconds: 600));

    // TODO: Replace with actual API call
    final customerIndex = MockData.sampleCustomers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) return null;

    final existingCustomer = MockData.sampleCustomers[customerIndex];
    final updatedCustomer = existingCustomer.copyWith(
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
      updatedAt: DateTime.now(),
    );

    MockData.sampleCustomers[customerIndex] = updatedCustomer;
    return updatedCustomer;
  }

  Future<bool> deleteCustomer(String customerId) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // TODO: Replace with actual API call
    final customerIndex = MockData.sampleCustomers.indexWhere((c) => c.id == customerId);
    if (customerIndex == -1) return false;

    MockData.sampleCustomers.removeAt(customerIndex);
    return true;
  }

  Future<List<Customer>> getRecentCustomers({
    String? salesAgentId,
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: Replace with actual API call
    var customers = MockData.sampleCustomers;

    // For demo purposes, show all customers regardless of sales agent ID
    // In production, this would filter by actual sales agent assignments
    // For now, we'll show all customers to ensure the checkout flow works

    // Uncomment the lines below for production filtering:
    // if (salesAgentId != null) {
    //   customers = customers.where((customer) => customer.salesAgentId == salesAgentId).toList();
    // }

    // Sort by last order date (most recent first)
    customers.sort((a, b) => b.lastOrderDate.compareTo(a.lastOrderDate));

    return customers.take(limit).toList();
  }

  Future<List<Customer>> searchCustomers({
    required String query,
    String? salesAgentId,
    int limit = 20,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // TODO: Replace with actual API call
    var customers = MockData.sampleCustomers;

    // For demo purposes, show all customers regardless of sales agent ID
    // In production, this would filter by actual sales agent assignments

    // Uncomment the lines below for production filtering:
    // if (salesAgentId != null) {
    //   customers = customers.where((customer) => customer.salesAgentId == salesAgentId).toList();
    // }

    if (query.isNotEmpty) {
      final searchQuery = query.toLowerCase();
      customers = customers.where((customer) {
        return customer.organizationName.toLowerCase().contains(searchQuery) ||
            customer.contactPersonName.toLowerCase().contains(searchQuery) ||
            customer.email.toLowerCase().contains(searchQuery) ||
            customer.phoneNumber.contains(searchQuery);
      }).toList();
    }

    return customers.take(limit).toList();
  }

  Future<Map<String, dynamic>> getCustomerStats({
    String? salesAgentId,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: Replace with actual API call
    var customers = MockData.sampleCustomers;

    if (salesAgentId != null) {
      customers = customers.where((customer) => customer.salesAgentId == salesAgentId).toList();
    }

    final totalCustomers = customers.length;
    final activeCustomers = customers.where((c) => c.isActive).length;
    final totalSpent = customers.fold(0.0, (sum, c) => sum + c.totalSpent);
    final totalOrders = customers.fold(0, (sum, c) => sum + c.totalOrders);

    return {
      'totalCustomers': totalCustomers,
      'activeCustomers': activeCustomers,
      'totalSpent': totalSpent,
      'totalOrders': totalOrders,
      'averageOrderValue': totalOrders > 0 ? totalSpent / totalOrders : 0.0,
    };
  }
}
