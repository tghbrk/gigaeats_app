// Import models
import '../../features/customers/data/models/customer.dart';
import '../../features/user_management/domain/customer_profile.dart' as profile;

// Import core services
import '../../core/utils/logger.dart';

// Import base repository
import 'base_repository.dart';

/// Repository for customer management operations
class CustomerRepository extends BaseRepository {
  final AppLogger _logger = AppLogger();

  CustomerRepository() : super();

  /// Get customer by ID
  Future<Customer?> getCustomerById(String customerId) async {
    return executeQuery(() async {
      _logger.info('👤 [CUSTOMER-REPO] Getting customer: $customerId');

      final response = await client
          .from('customers')
          .select('''
            *,
            customer_addresses(*),
            customer_stats(*)
          ''')
          .eq('id', customerId)
          .maybeSingle();

      if (response == null) {
        _logger.warning('⚠️ [CUSTOMER-REPO] Customer not found: $customerId');
        return null;
      }

      final customer = Customer.fromJson(response);
      _logger.info('✅ [CUSTOMER-REPO] Retrieved customer: ${customer.name}');
      return customer;
    });
  }

  /// Get customer by user ID
  Future<Customer?> getCustomerByUserId(String userId) async {
    return executeQuery(() async {
      _logger.info('👤 [CUSTOMER-REPO] Getting customer by user ID: $userId');

      final response = await client
          .from('customers')
          .select('''
            *,
            customer_addresses(*),
            customer_stats(*)
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        _logger.warning('⚠️ [CUSTOMER-REPO] Customer not found for user: $userId');
        return null;
      }

      final customer = Customer.fromJson(response);
      _logger.info('✅ [CUSTOMER-REPO] Retrieved customer: ${customer.name}');
      return customer;
    });
  }

  /// Get all customers (for sales agents and admins)
  Future<List<Customer>> getAllCustomers({
    int? limit,
    int? offset,
    String? searchQuery,
    CustomerStatus? status,
    CustomerType? type,
  }) async {
    return executeQuery(() async {
      _logger.info('📋 [CUSTOMER-REPO] Getting all customers');

      dynamic queryBuilder = client
          .from('customers')
          .select('''
            *,
            customer_addresses(*),
            customer_stats(*)
          ''');

      // Apply filters
      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.name);
      }

      if (type != null) {
        queryBuilder = queryBuilder.eq('customer_type', type.name);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or('name.ilike.%$searchQuery%,email.ilike.%$searchQuery%,company_name.ilike.%$searchQuery%');
      }

      // Apply ordering first
      queryBuilder = queryBuilder.order('created_at', ascending: false);

      // Apply pagination
      if (offset != null) {
        queryBuilder = queryBuilder.range(offset, offset + (limit ?? 20) - 1);
      } else if (limit != null) {
        queryBuilder = queryBuilder.limit(limit);
      }

      final response = await queryBuilder;
      final customers = response.map((json) => Customer.fromJson(json)).toList();
      
      _logger.info('✅ [CUSTOMER-REPO] Retrieved ${customers.length} customers');
      return customers;
    });
  }

  /// Create new customer
  Future<String?> createCustomer(Map<String, dynamic> customerData) async {
    return executeQuery(() async {
      _logger.info('➕ [CUSTOMER-REPO] Creating new customer');

      final customerPayload = {
        'user_id': customerData['user_id'],
        'name': customerData['name'],
        'email': customerData['email'],
        'phone_number': customerData['phone_number'],
        'customer_type': customerData['customer_type'] ?? CustomerType.corporate.name,
        'status': CustomerStatus.active.name,
        'company_name': customerData['company_name'],
        'business_registration_number': customerData['business_registration_number'],
        'tax_id': customerData['tax_id'],
        'sales_agent_id': customerData['sales_agent_id'],
        'is_verified': false,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('customers')
          .insert(customerPayload)
          .select('id')
          .single();

      final customerId = response['id'] as String;

      // Create default address if provided
      if (customerData['address'] != null) {
        await _createCustomerAddress(customerId, customerData['address'], isDefault: true);
      }

      // Initialize customer stats
      await _initializeCustomerStats(customerId);

      _logger.info('✅ [CUSTOMER-REPO] Customer created successfully: $customerId');
      return customerId;
    });
  }

  /// Update customer
  Future<void> updateCustomer(String customerId, Map<String, dynamic> updates) async {
    return executeQuery(() async {
      _logger.info('🔄 [CUSTOMER-REPO] Updating customer: $customerId');

      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client
          .from('customers')
          .update(updateData)
          .eq('id', customerId);

      _logger.info('✅ [CUSTOMER-REPO] Customer updated successfully');
    });
  }

  /// Update customer status
  Future<void> updateCustomerStatus(String customerId, CustomerStatus newStatus) async {
    return executeQuery(() async {
      _logger.info('🔄 [CUSTOMER-REPO] Updating customer $customerId status to ${newStatus.name}');

      await client
          .from('customers')
          .update({
            'status': newStatus.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId);

      _logger.info('✅ [CUSTOMER-REPO] Customer status updated successfully');
    });
  }

  /// Add customer address
  ///
  /// @deprecated Use CustomerProfileRepository.addAddress() instead for customer app usage.
  /// This method is primarily for admin/sales agent operations.
  Future<String?> addCustomerAddress(String customerId, profile.CustomerAddress address) async {
    return executeQuery(() async {
      _logger.info('📍 [CUSTOMER-REPO] Adding address for customer: $customerId');

      final addressData = address.toJson();
      return await _createCustomerAddress(customerId, addressData);
    });
  }

  /// Update customer address
  ///
  /// @deprecated Use CustomerProfileRepository.updateAddress() instead for customer app usage.
  /// This method is primarily for admin/sales agent operations.
  Future<void> updateCustomerAddress(String addressId, Map<String, dynamic> updates) async {
    return executeQuery(() async {
      _logger.info('🔄 [CUSTOMER-REPO] Updating address: $addressId');

      final updateData = Map<String, dynamic>.from(updates);
      updateData['updated_at'] = DateTime.now().toIso8601String();

      await client
          .from('customer_addresses')
          .update(updateData)
          .eq('id', addressId);

      _logger.info('✅ [CUSTOMER-REPO] Address updated successfully');
    });
  }

  /// Delete customer address
  ///
  /// @deprecated Use CustomerProfileRepository.removeAddress() instead for customer app usage.
  /// This method is primarily for admin/sales agent operations.
  Future<void> deleteCustomerAddress(String addressId) async {
    return executeQuery(() async {
      _logger.info('🗑️ [CUSTOMER-REPO] Deleting address: $addressId');

      await client
          .from('customer_addresses')
          .delete()
          .eq('id', addressId);

      _logger.info('✅ [CUSTOMER-REPO] Address deleted successfully');
    });
  }

  /// Set default address
  Future<void> setDefaultAddress(String customerId, String addressId) async {
    return executeQuery(() async {
      _logger.info('🏠 [CUSTOMER-REPO] Setting default address for customer: $customerId');

      // Remove default from all addresses
      await client
          .from('customer_addresses')
          .update({'is_default': false})
          .eq('customer_profile_id', customerId);

      // Set new default
      await client
          .from('customer_addresses')
          .update({'is_default': true})
          .eq('id', addressId);

      _logger.info('✅ [CUSTOMER-REPO] Default address set successfully');
    });
  }

  /// Get customer addresses
  Future<List<profile.CustomerAddress>> getCustomerAddresses(String customerId) async {
    return executeQuery(() async {
      _logger.info('📍 [CUSTOMER-REPO] Getting addresses for customer: $customerId');

      final response = await client
          .from('customer_addresses')
          .select('*')
          .eq('customer_profile_id', customerId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      final addresses = response.map((json) {
        // Convert the database response to CustomerAddress format
        final addressData = Map<String, dynamic>.from(json);

        // Map database column names to CustomerAddress field names
        addressData['address_line_1'] = addressData['address_line_1'];
        addressData['address_line_2'] = addressData['address_line_2'];
        addressData['postal_code'] = addressData['postal_code'];
        addressData['delivery_instructions'] = addressData['delivery_instructions'];
        addressData['is_default'] = addressData['is_default'];

        return profile.CustomerAddress.fromJson(addressData);
      }).toList();

      _logger.info('✅ [CUSTOMER-REPO] Retrieved ${addresses.length} addresses');
      return addresses;
    });
  }

  /// Get customers by sales agent
  Future<List<Customer>> getCustomersBySalesAgent(String salesAgentId) async {
    return executeQuery(() async {
      _logger.info('👥 [CUSTOMER-REPO] Getting customers for sales agent: $salesAgentId');

      final response = await client
          .from('customers')
          .select('''
            *,
            customer_addresses(*),
            customer_stats(*)
          ''')
          .eq('sales_agent_id', salesAgentId)
          .order('created_at', ascending: false);

      final customers = response.map((json) => Customer.fromJson(json)).toList();
      _logger.info('✅ [CUSTOMER-REPO] Retrieved ${customers.length} customers for sales agent');
      return customers;
    });
  }

  /// Search customers
  Future<List<Customer>> searchCustomers(String query) async {
    return executeQuery(() async {
      _logger.info('🔍 [CUSTOMER-REPO] Searching customers: $query');

      final response = await client
          .from('customers')
          .select('''
            *,
            customer_addresses(*),
            customer_stats(*)
          ''')
          .or('name.ilike.%$query%,email.ilike.%$query%,company_name.ilike.%$query%,phone_number.ilike.%$query%')
          .order('name', ascending: true);

      final customers = response.map((json) => Customer.fromJson(json)).toList();
      _logger.info('✅ [CUSTOMER-REPO] Found ${customers.length} customers matching query');
      return customers;
    });
  }

  /// Get customer statistics
  Future<Map<String, dynamic>> getCustomerStatistics(String customerId) async {
    return executeQuery(() async {
      _logger.info('📊 [CUSTOMER-REPO] Getting statistics for customer: $customerId');

      final response = await client
          .rpc('get_customer_statistics', params: {'customer_id': customerId});

      _logger.info('✅ [CUSTOMER-REPO] Retrieved customer statistics');
      return response as Map<String, dynamic>;
    });
  }

  /// Create customer address
  Future<String?> _createCustomerAddress(String customerId, Map<String, dynamic> addressData, {bool isDefault = false}) async {
    final addressPayload = {
      'customer_profile_id': customerId,
      'label': addressData['label'] ?? 'Home',
      'address_line_1': addressData['address_line_1'] ?? addressData['addressLine1'],
      'address_line_2': addressData['address_line_2'] ?? addressData['addressLine2'],
      'city': addressData['city'],
      'state': addressData['state'],
      'postal_code': addressData['postal_code'] ?? addressData['postalCode'],
      'country': addressData['country'] ?? 'Malaysia',
      'latitude': addressData['latitude'],
      'longitude': addressData['longitude'],
      'is_default': addressData['is_default'] ?? addressData['isDefault'] ?? isDefault,
      'delivery_instructions': addressData['delivery_instructions'] ?? addressData['deliveryInstructions'],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await client
        .from('customer_addresses')
        .insert(addressPayload)
        .select('id')
        .single();

    final addressId = response['id'] as String;
    _logger.info('✅ [CUSTOMER-REPO] Address created successfully: $addressId');
    return addressId;
  }

  /// Initialize customer stats
  Future<void> _initializeCustomerStats(String customerId) async {
    final statsPayload = {
      'customer_id': customerId,
      'total_orders': 0,
      'total_spent': 0.0,
      'average_order_value': 0.0,
      'loyalty_points': 0,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await client.from('customer_stats').insert(statsPayload);
    _logger.info('✅ [CUSTOMER-REPO] Customer stats initialized');
  }

  /// Get customers with recent orders
  Future<List<Customer>> getCustomersWithRecentOrders({
    int daysSince = 30,
    int limit = 20,
  }) async {
    return executeQuery(() async {
      _logger.info('📋 [CUSTOMER-REPO] Getting customers with recent orders (last $daysSince days)');

      final cutoffDate = DateTime.now().subtract(Duration(days: daysSince));

      final response = await client
          .from('customers')
          .select('''
            *,
            customer_addresses(*),
            customer_stats(*)
          ''')
          .eq('is_active', true)
          .gte('last_order_date', cutoffDate.toIso8601String())
          .order('last_order_date', ascending: false)
          .limit(limit);

      final customers = response.map((json) => Customer.fromJson(json)).toList();
      _logger.info('✅ [CUSTOMER-REPO] Retrieved ${customers.length} customers with recent orders');
      return customers;
    });
  }
}
