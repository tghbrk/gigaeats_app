import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer.dart';
import 'base_repository.dart';

class CustomerRepository extends BaseRepository {
  CustomerRepository({
    SupabaseClient? client,
  }) : super(client: client);

  /// Get customers for the current sales agent
  Future<List<Customer>> getCustomers({
    String? searchQuery,
    CustomerType? type,
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) throw Exception('Sales agent not found');

      var query = client
          .from('customers')
          .select('*')
          .eq('sales_agent_id', salesAgentId);

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('organization_name.ilike.%$searchQuery%,contact_person_name.ilike.%$searchQuery%,email.ilike.%$searchQuery%');
      }

      // Apply type filter
      if (type != null) {
        query = query.eq('customer_type', type.name);
      }

      // Apply active filter
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('CustomerRepository: Raw response: $response');

      return response.map((json) {
        try {
          debugPrint('CustomerRepository: Processing customer JSON: $json');
          return Customer.fromJson(json);
        } catch (e, stackTrace) {
          debugPrint('CustomerRepository: Error parsing customer JSON: $e');
          debugPrint('CustomerRepository: Stack trace: $stackTrace');
          debugPrint('CustomerRepository: Problematic JSON: $json');

          // Try to identify the specific field causing the issue
          json.forEach((key, value) {
            debugPrint('CustomerRepository: Field $key: $value (${value.runtimeType})');
          });

          rethrow;
        }
      }).toList();
    });
  }

  /// Get customers stream for real-time updates
  Stream<List<Customer>> getCustomersStream({
    String? searchQuery,
  }) {
    return executeStreamQuery(() async* {
      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) throw Exception('Sales agent not found');

      dynamic streamBuilder = client
          .from('customers')
          .stream(primaryKey: ['id'])
          .eq('sales_agent_id', salesAgentId);

      if (searchQuery != null && searchQuery.isNotEmpty) {
        streamBuilder = streamBuilder.ilike('organization_name', '%$searchQuery%');
      }

      yield* streamBuilder
          .map((data) => data.map((json) => Customer.fromJson(json)).toList());
    });
  }

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    return executeQuery(() async {
      final response = await client
          .from('customers')
          .select('*')
          .eq('id', customerId)
          .maybeSingle();

      return response != null ? Customer.fromJson(response) : null;
    });
  }

  /// Create new customer
  Future<Customer> createCustomer(Customer customer) async {
    return executeQuery(() async {
      debugPrint('CustomerRepository: Starting customer creation process');

      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) {
        debugPrint('CustomerRepository: Sales agent not found - cannot create customer');
        throw Exception('Sales agent not found');
      }

      debugPrint('CustomerRepository: Found sales agent ID: $salesAgentId');

      final customerData = customer.toJson();
      customerData['sales_agent_id'] = salesAgentId;

      // Remove fields that should be auto-generated
      customerData.remove('id');
      customerData.remove('created_at');
      customerData.remove('updated_at');

      debugPrint('CustomerRepository: Customer data to insert: $customerData');

      final authenticatedClient = await getAuthenticatedClient();
      debugPrint('CustomerRepository: Got authenticated client, inserting customer...');

      final response = await authenticatedClient
          .from('customers')
          .insert(customerData)
          .select()
          .single();

      debugPrint('CustomerRepository: Customer created successfully: $response');
      return Customer.fromJson(response);
    });
  }

  /// Update customer
  Future<Customer> updateCustomer(Customer customer) async {
    return executeQuery(() async {
      debugPrint('🔧 CustomerRepository: updateCustomer called for ${customer.organizationName} (${customer.id})');

      final customerData = customer.toJson();
      customerData['updated_at'] = DateTime.now().toIso8601String();

      debugPrint('🔧 CustomerRepository: Update data: $customerData');

      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .from('customers')
          .update(customerData)
          .eq('id', customer.id)
          .select()
          .single();

      debugPrint('🔧 CustomerRepository: Update operation response: $response');
      return Customer.fromJson(response);
    });
  }

  /// Delete customer (soft delete by setting inactive)
  Future<void> deleteCustomer(String customerId) async {
    return executeQuery(() async {
      debugPrint('🔧 CustomerRepository: deleteCustomer called for ID: $customerId');

      final updateData = {
        'is_active': false,
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('🔧 CustomerRepository: Update data: $updateData');

      final response = await client
          .from('customers')
          .update(updateData)
          .eq('id', customerId)
          .select(); // Add select to get the updated record

      debugPrint('🔧 CustomerRepository: Delete operation response: $response');
    });
  }

  /// Search customers
  Future<List<Customer>> searchCustomers(String query, {int limit = 20}) async {
    return executeQuery(() async {
      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) throw Exception('Sales agent not found');

      final response = await client
          .from('customers')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .or(
            'organization_name.ilike.%$query%,'
            'contact_person_name.ilike.%$query%,'
            'email.ilike.%$query%,'
            'phone_number.ilike.%$query%'
          )
          .order('organization_name')
          .limit(limit);

      return response.map((json) => Customer.fromJson(json)).toList();
    });
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics() async {
    return executeQuery(() async {
      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) throw Exception('Sales agent not found');

      final response = await client.rpc('get_customer_statistics', params: {
        'sales_agent_id': salesAgentId,
      });

      return response as Map<String, dynamic>;
    });
  }

  /// Get top customers by spending
  Future<List<Customer>> getTopCustomers({int limit = 10}) async {
    return executeQuery(() async {
      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) throw Exception('Sales agent not found');

      final response = await client
          .from('customers')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .eq('is_active', true)
          .order('total_spent', ascending: false)
          .limit(limit);

      return response.map((json) => Customer.fromJson(json)).toList();
    });
  }

  /// Get customers with recent orders
  Future<List<Customer>> getCustomersWithRecentOrders({
    int daysSince = 30,
    int limit = 20,
  }) async {
    return executeQuery(() async {
      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) throw Exception('Sales agent not found');

      final cutoffDate = DateTime.now().subtract(Duration(days: daysSince));

      final response = await client
          .from('customers')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .eq('is_active', true)
          .gte('last_order_date', cutoffDate.toIso8601String())
          .order('last_order_date', ascending: false)
          .limit(limit);

      return response.map((json) => Customer.fromJson(json)).toList();
    });
  }

  /// Update customer spending and order count (called after order completion)
  Future<void> updateCustomerOrderStats(
    String customerId,
    double orderAmount,
  ) async {
    return executeQuery(() async {
      await client.rpc('update_customer_order_stats', params: {
        'customer_id': customerId,
        'order_amount': orderAmount,
      });
    });
  }

  /// Add note to customer
  Future<void> addCustomerNote(String customerId, String note) async {
    return executeQuery(() async {
      final customer = await getCustomerById(customerId);
      if (customer == null) throw Exception('Customer not found');

      final existingNotes = customer.notes ?? '';
      final timestamp = DateTime.now().toIso8601String();
      final newNote = '$timestamp: $note';
      final updatedNotes = existingNotes.isEmpty 
          ? newNote 
          : '$existingNotes\n$newNote';

      await client
          .from('customers')
          .update({
            'notes': updatedNotes,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);
    });
  }

  /// Add tag to customer
  Future<void> addCustomerTag(String customerId, String tag) async {
    return executeQuery(() async {
      final customer = await getCustomerById(customerId);
      if (customer == null) throw Exception('Customer not found');

      final tags = List<String>.from(customer.tags);
      if (!tags.contains(tag)) {
        tags.add(tag);

        await client
            .from('customers')
            .update({
              'tags': tags,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', customerId);
      }
    });
  }

  /// Remove tag from customer
  Future<void> removeCustomerTag(String customerId, String tag) async {
    return executeQuery(() async {
      final customer = await getCustomerById(customerId);
      if (customer == null) throw Exception('Customer not found');

      final tags = List<String>.from(customer.tags);
      tags.remove(tag);

      await client
          .from('customers')
          .update({
            'tags': tags,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);
    });
  }

  /// Get customers by tags
  Future<List<Customer>> getCustomersByTags(List<String> tags) async {
    return executeQuery(() async {
      final salesAgentId = await _getCurrentSalesAgentId();
      if (salesAgentId == null) throw Exception('Sales agent not found');

      final response = await client
          .from('customers')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .overlaps('tags', tags)
          .order('organization_name');

      return response.map((json) => Customer.fromJson(json)).toList();
    });
  }

  /// Helper method to get current sales agent ID
  Future<String?> _getCurrentSalesAgentId() async {
    if (currentUserUid == null) return null;

    try {
      final authenticatedClient = await getAuthenticatedClient();

      debugPrint('CustomerRepository: Looking for sales agent with Supabase UID: $currentUserUid');

      // First try to get user with sales_agent role
      var response = await authenticatedClient
          .from('users')
          .select('id, role')
          .eq('supabase_user_id', currentUserUid!)
          .eq('role', 'sales_agent')
          .limit(1);

      if (response.isNotEmpty) {
        debugPrint('CustomerRepository: Found sales agent: ${response.first}');
        return response.first['id'];
      }

      // If no sales agent found, try to get any user with this Supabase UID
      response = await authenticatedClient
          .from('users')
          .select('id, role')
          .eq('supabase_user_id', currentUserUid!)
          .limit(1);

      if (response.isNotEmpty) {
        debugPrint('CustomerRepository: Found user with role ${response.first['role']}: ${response.first}');
        // For testing purposes, allow any user to act as sales agent
        return response.first['id'];
      }

      debugPrint('CustomerRepository: No user found with Firebase UID: $currentUserUid');
      return null;
    } catch (e) {
      debugPrint('CustomerRepository: Error getting sales agent ID: $e');
      return null;
    }
  }
}
