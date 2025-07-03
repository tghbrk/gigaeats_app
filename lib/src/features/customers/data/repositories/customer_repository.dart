import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer.dart';

/// Repository for customer-related operations
class CustomerRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all customers
  Future<List<Customer>> getCustomers({
    String? salesAgentId,
    CustomerStatus? status,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('customers')
          .select('*');

      if (salesAgentId != null) {
        query = query.eq('sales_agent_id', salesAgentId);
      }

      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('*')
          .eq('id', customerId)
          .maybeSingle();

      if (response == null) return null;
      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch customer: $e');
    }
  }

  /// Get customer by user ID
  Future<Customer?> getCustomerByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('customers')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch customer by user ID: $e');
    }
  }

  /// Create customer
  Future<Customer> createCustomer(Customer customer) async {
    try {
      final response = await _supabase
          .from('customers')
          .insert(customer.toJson())
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create customer: $e');
    }
  }

  /// Update customer
  Future<Customer> updateCustomer(Customer customer) async {
    try {
      final response = await _supabase
          .from('customers')
          .update(customer.toJson())
          .eq('id', customer.id)
          .select()
          .single();

      return Customer.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update customer: $e');
    }
  }

  /// Delete customer
  Future<void> deleteCustomer(String customerId) async {
    try {
      await _supabase
          .from('customers')
          .delete()
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to delete customer: $e');
    }
  }

  /// Search customers
  Future<List<Customer>> searchCustomers({
    required String query,
    String? salesAgentId,
    int limit = 20,
  }) async {
    try {
      var searchQuery = _supabase
          .from('customers')
          .select('*')
          .or('full_name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%');

      if (salesAgentId != null) {
        searchQuery = searchQuery.eq('sales_agent_id', salesAgentId);
      }

      final response = await searchQuery
          .order('full_name')
          .limit(limit);

      return response.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }

  /// Update customer status
  Future<void> updateCustomerStatus(String customerId, CustomerStatus status) async {
    try {
      await _supabase
          .from('customers')
          .update({'status': status.name})
          .eq('id', customerId);
    } catch (e) {
      throw Exception('Failed to update customer status: $e');
    }
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStats(String customerId) async {
    try {
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('customer_id', customerId);

      final totalOrders = ordersResponse.length;
      final totalSpent = ordersResponse
          .where((order) => order['status'] == 'delivered')
          .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      final lastOrderDate = ordersResponse.isNotEmpty
          ? DateTime.parse(ordersResponse.first['created_at'])
          : null;

      return {
        'total_orders': totalOrders,
        'total_spent': totalSpent,
        'last_order_date': lastOrderDate?.toIso8601String(),
        'active_orders': ordersResponse.where((order) => 
          ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(order['status'])
        ).length,
      };
    } catch (e) {
      throw Exception('Failed to fetch customer stats: $e');
    }
  }

  /// Get customers by sales agent with pagination
  Future<List<Customer>> getCustomersBySalesAgent({
    required String salesAgentId,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final offset = page * limit;
      final response = await _supabase
          .from('customers')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((json) => Customer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customers by sales agent: $e');
    }
  }

  /// Get customers stream for real-time updates
  Stream<List<Customer>> getCustomersStream({
    String? salesAgentId,
    CustomerStatus? status,
    String? searchQuery,
    int limit = 50,
  }) {
    // Build the stream with filters
    var stream = _supabase
        .from('customers')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .limit(limit);

    return stream.map((data) {
      var customers = data.map((json) => Customer.fromJson(json)).toList();

      // Apply filters in memory since stream doesn't support dynamic filtering
      if (salesAgentId != null) {
        customers = customers.where((customer) => customer.salesAgentId == salesAgentId).toList();
      }

      if (status != null) {
        customers = customers.where((customer) => customer.status == status).toList();
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        customers = customers.where((customer) =>
          customer.name.toLowerCase().contains(query) ||
          customer.email.toLowerCase().contains(query) ||
          customer.phoneNumber.toLowerCase().contains(query) ||
          (customer.companyName?.toLowerCase().contains(query) ?? false)
        ).toList();
      }

      return customers;
    });
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics({
    String? salesAgentId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('customers')
          .select('id, created_at, status');

      if (salesAgentId != null) {
        query = query.eq('sales_agent_id', salesAgentId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query;

      final totalCustomers = response.length;
      final activeCustomers = response.where((customer) =>
        customer['status'] == 'active'
      ).length;

      final inactiveCustomers = response.where((customer) =>
        customer['status'] == 'inactive'
      ).length;

      final pendingCustomers = response.where((customer) =>
        customer['status'] == 'pending'
      ).length;

      // Calculate new customers this month
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final newThisMonth = response.where((customer) {
        final createdAt = DateTime.parse(customer['created_at']);
        return createdAt.isAfter(thisMonthStart);
      }).length;

      return {
        'total_customers': totalCustomers,
        'active_customers': activeCustomers,
        'inactive_customers': inactiveCustomers,
        'pending_customers': pendingCustomers,
        'new_this_month': newThisMonth,
        'growth_rate': totalCustomers > 0 ? (newThisMonth / totalCustomers * 100) : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to fetch customer statistics: $e');
    }
  }

  /// Get top customers by total spent (returns Customer objects)
  Future<List<Customer>> getTopCustomers({
    String? salesAgentId,
    int limit = 10,
    String orderBy = 'total_spent', // 'total_spent', 'total_orders', 'last_order'
  }) async {
    try {
      // Get customers with their order statistics
      var customersQuery = _supabase
          .from('customers')
          .select('*');

      if (salesAgentId != null) {
        customersQuery = customersQuery.eq('sales_agent_id', salesAgentId);
      }

      final customers = await customersQuery;

      // Convert to Customer objects and sort by the specified criteria
      final customerObjects = customers.map((json) => Customer.fromJson(json)).toList();

      // Sort by the specified criteria (using stats property from customers/data/models Customer)
      customerObjects.sort((a, b) {
        switch (orderBy) {
          case 'total_orders':
            return b.stats.totalOrders.compareTo(a.stats.totalOrders);
          case 'last_order':
            final aDate = a.stats.lastOrderDate ?? DateTime(1970);
            final bDate = b.stats.lastOrderDate ?? DateTime(1970);
            return bDate.compareTo(aDate);
          case 'total_spent':
          default:
            return b.stats.totalSpent.compareTo(a.stats.totalSpent);
        }
      });

      return customerObjects.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch top customers: $e');
    }
  }

  /// Get top customers with detailed statistics (returns Map objects)
  Future<List<Map<String, dynamic>>> getTopCustomersWithStats({
    String? salesAgentId,
    int limit = 10,
    String orderBy = 'total_spent', // 'total_spent', 'total_orders', 'last_order'
  }) async {
    try {
      // Get customers with their order statistics
      var customersQuery = _supabase
          .from('customers')
          .select('id, full_name, email, phone_number, created_at');

      if (salesAgentId != null) {
        customersQuery = customersQuery.eq('sales_agent_id', salesAgentId);
      }

      final customers = await customersQuery;

      // Get order statistics for each customer
      final customerStats = <Map<String, dynamic>>[];

      for (final customer in customers) {
        final customerId = customer['id'];

        final ordersResponse = await _supabase
            .from('orders')
            .select('total_amount, status, created_at')
            .eq('customer_id', customerId);

        final totalOrders = ordersResponse.length;
        final totalSpent = ordersResponse
            .where((order) => order['status'] == 'delivered')
            .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

        final lastOrderDate = ordersResponse.isNotEmpty
            ? DateTime.parse(ordersResponse
                .map((order) => order['created_at'])
                .reduce((a, b) => DateTime.parse(a).isAfter(DateTime.parse(b)) ? a : b))
            : null;

        customerStats.add({
          'id': customer['id'],
          'full_name': customer['full_name'],
          'email': customer['email'],
          'phone_number': customer['phone_number'],
          'created_at': customer['created_at'],
          'total_orders': totalOrders,
          'total_spent': totalSpent,
          'last_order_date': lastOrderDate?.toIso8601String(),
        });
      }

      // Sort by the specified criteria
      customerStats.sort((a, b) {
        switch (orderBy) {
          case 'total_orders':
            return (b['total_orders'] as int).compareTo(a['total_orders'] as int);
          case 'last_order':
            final aDate = a['last_order_date'] != null ? DateTime.parse(a['last_order_date']) : DateTime(1970);
            final bDate = b['last_order_date'] != null ? DateTime.parse(b['last_order_date']) : DateTime(1970);
            return bDate.compareTo(aDate);
          case 'total_spent':
          default:
            return (b['total_spent'] as double).compareTo(a['total_spent'] as double);
        }
      });

      return customerStats.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch top customers: $e');
    }
  }
}
