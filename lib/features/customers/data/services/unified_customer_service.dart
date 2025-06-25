import '../models/unified_customer_models.dart';
import '../repositories/base_repository.dart';

class UnifiedCustomerService extends BaseRepository {

  // Create unified customer
  Future<UnifiedCustomerResult> createUnifiedCustomer({
    required String fullName,
    String? email,
    String? phoneNumber,
    String? salesAgentId,
    String customerType = 'individual',
    String? organizationName,
    String? contactPersonName,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? address,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final response = await supabase
          .from('unified_customers')
          .insert({
            'full_name': fullName,
            'email': email,
            'phone_number': phoneNumber,
            'sales_agent_id': salesAgentId,
            'customer_type': customerType,
            'organization_name': organizationName,
            'contact_person_name': contactPersonName,
            'business_info': businessInfo ?? {},
            'address': address,
            'preferences': preferences ?? {},
          })
          .select()
          .single();

      return UnifiedCustomerResult(
        success: true,
        customer: UnifiedCustomer.fromJson(response),
        message: 'Customer created successfully',
      );
    } catch (e) {
      return UnifiedCustomerResult(
        success: false,
        message: 'Failed to create customer: $e',
      );
    }
  }

  // Get unified customers for sales agent
  Future<List<UnifiedCustomer>> getUnifiedCustomers({
    String? salesAgentId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = supabase
          .from('unified_customers')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      // TODO: Fix Supabase API - .eq() method issue
      // if (salesAgentId != null) {
      //   query = query.eq('sales_agent_id', salesAgentId);
      // }

      final response = await query;
      return response.map((json) => UnifiedCustomer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customers: $e');
    }
  }

  // Get unified customer by ID
  Future<UnifiedCustomer?> getUnifiedCustomerById(String customerId) async {
    try {
      final response = await supabase
          .from('unified_customers')
          .select()
          .eq('id', customerId)
          .single();

      return UnifiedCustomer.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get unified customer by user ID
  Future<UnifiedCustomer?> getUnifiedCustomerByUserId(String userId) async {
    try {
      final response = await supabase
          .from('unified_customers')
          .select()
          .eq('user_id', userId)
          .single();

      return UnifiedCustomer.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Update unified customer
  Future<UnifiedCustomerResult> updateUnifiedCustomer({
    required String customerId,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? alternatePhoneNumber,
    String? organizationName,
    String? contactPersonName,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? address,
    Map<String, dynamic>? preferences,
    bool? isActive,
    bool? isVerified,
    String? notes,
    List<String>? tags,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (fullName != null) updateData['full_name'] = fullName;
      if (email != null) updateData['email'] = email;
      if (phoneNumber != null) updateData['phone_number'] = phoneNumber;
      if (alternatePhoneNumber != null) updateData['alternate_phone_number'] = alternatePhoneNumber;
      if (organizationName != null) updateData['organization_name'] = organizationName;
      if (contactPersonName != null) updateData['contact_person_name'] = contactPersonName;
      if (businessInfo != null) updateData['business_info'] = businessInfo;
      if (address != null) updateData['address'] = address;
      if (preferences != null) updateData['preferences'] = preferences;
      if (isActive != null) updateData['is_active'] = isActive;
      if (isVerified != null) updateData['is_verified'] = isVerified;
      if (notes != null) updateData['notes'] = notes;
      if (tags != null) updateData['tags'] = tags;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabase
          .from('unified_customers')
          .update(updateData)
          .eq('id', customerId)
          .select()
          .single();

      return UnifiedCustomerResult(
        success: true,
        customer: UnifiedCustomer.fromJson(response),
        message: 'Customer updated successfully',
      );
    } catch (e) {
      return UnifiedCustomerResult(
        success: false,
        message: 'Failed to update customer: $e',
      );
    }
  }

  // Link customer to auth user
  Future<UnifiedCustomerResult> linkCustomerToAuthUser({
    required String customerId,
    required String userId,
  }) async {
    try {
      final response = await supabase
          .from('unified_customers')
          .update({
            'user_id': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', customerId)
          .select()
          .single();

      return UnifiedCustomerResult(
        success: true,
        customer: UnifiedCustomer.fromJson(response),
        message: 'Customer linked to auth user successfully',
      );
    } catch (e) {
      return UnifiedCustomerResult(
        success: false,
        message: 'Failed to link customer to auth user: $e',
      );
    }
  }

  // Get customer addresses
  Future<List<UnifiedCustomerAddress>> getCustomerAddresses(String customerId) async {
    try {
      final response = await supabase
          .from('unified_customer_addresses')
          .select()
          .eq('customer_id', customerId)
          .eq('is_active', true)
          .order('is_default', ascending: false)
          .order('created_at', ascending: false);

      return response.map((json) => UnifiedCustomerAddress.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch customer addresses: $e');
    }
  }

  // Add customer address
  Future<UnifiedCustomerAddressResult> addCustomerAddress({
    required String customerId,
    required String label,
    required String addressLine1,
    String? addressLine2,
    required String city,
    required String state,
    required String postalCode,
    String country = 'Malaysia',
    String addressType = 'residential',
    bool isDefault = false,
    String? deliveryInstructions,
    String? landmark,
    double? latitude,
    double? longitude,
  }) async {
    try {
      // If this is set as default, unset other default addresses
      if (isDefault) {
        await supabase
            .from('unified_customer_addresses')
            .update({'is_default': false})
            .eq('customer_id', customerId);
      }

      final response = await supabase
          .from('unified_customer_addresses')
          .insert({
            'customer_id': customerId,
            'label': label,
            'address_line_1': addressLine1,
            'address_line_2': addressLine2,
            'city': city,
            'state': state,
            'postal_code': postalCode,
            'country': country,
            'address_type': addressType,
            'is_default': isDefault,
            'delivery_instructions': deliveryInstructions,
            'landmark': landmark,
            'latitude': latitude,
            'longitude': longitude,
          })
          .select()
          .single();

      return UnifiedCustomerAddressResult(
        success: true,
        address: UnifiedCustomerAddress.fromJson(response),
        message: 'Address added successfully',
      );
    } catch (e) {
      return UnifiedCustomerAddressResult(
        success: false,
        message: 'Failed to add address: $e',
      );
    }
  }

  // Update customer address
  Future<UnifiedCustomerAddressResult> updateCustomerAddress({
    required String addressId,
    String? label,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    String? country,
    String? addressType,
    bool? isDefault,
    String? deliveryInstructions,
    String? landmark,
    double? latitude,
    double? longitude,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (label != null) updateData['label'] = label;
      if (addressLine1 != null) updateData['address_line_1'] = addressLine1;
      if (addressLine2 != null) updateData['address_line_2'] = addressLine2;
      if (city != null) updateData['city'] = city;
      if (state != null) updateData['state'] = state;
      if (postalCode != null) updateData['postal_code'] = postalCode;
      if (country != null) updateData['country'] = country;
      if (addressType != null) updateData['address_type'] = addressType;
      if (isDefault != null) updateData['is_default'] = isDefault;
      if (deliveryInstructions != null) updateData['delivery_instructions'] = deliveryInstructions;
      if (landmark != null) updateData['landmark'] = landmark;
      if (latitude != null) updateData['latitude'] = latitude;
      if (longitude != null) updateData['longitude'] = longitude;
      if (isActive != null) updateData['is_active'] = isActive;

      updateData['updated_at'] = DateTime.now().toIso8601String();

      // If this is set as default, unset other default addresses
      if (isDefault == true) {
        // Get customer ID first
        final addressResponse = await supabase
            .from('unified_customer_addresses')
            .select('customer_id')
            .eq('id', addressId)
            .single();
        
        await supabase
            .from('unified_customer_addresses')
            .update({'is_default': false})
            .eq('customer_id', addressResponse['customer_id']);
      }

      final response = await supabase
          .from('unified_customer_addresses')
          .update(updateData)
          .eq('id', addressId)
          .select()
          .single();

      return UnifiedCustomerAddressResult(
        success: true,
        address: UnifiedCustomerAddress.fromJson(response),
        message: 'Address updated successfully',
      );
    } catch (e) {
      return UnifiedCustomerAddressResult(
        success: false,
        message: 'Failed to update address: $e',
      );
    }
  }

  // Delete customer address
  Future<bool> deleteCustomerAddress(String addressId) async {
    try {
      await supabase
          .from('unified_customer_addresses')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', addressId);

      return true;
    } catch (e) {
      return false;
    }
  }

  // Search unified customers
  Future<List<UnifiedCustomer>> searchUnifiedCustomers({
    required String query,
    String? salesAgentId,
    int limit = 20,
  }) async {
    try {
      var searchQuery = supabase
          .from('unified_customers')
          .select()
          .eq('is_active', true)
          .or('full_name.ilike.%$query%,email.ilike.%$query%,phone_number.ilike.%$query%,organization_name.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(limit);

      // TODO: Fix Supabase API - .eq() method issue
      // if (salesAgentId != null) {
      //   searchQuery = searchQuery.eq('sales_agent_id', salesAgentId);
      // }

      final response = await searchQuery;
      return response.map((json) => UnifiedCustomer.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search customers: $e');
    }
  }
}
