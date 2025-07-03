import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

/// Service to resolve customer names from different customer types
/// Handles both individual customers (customer_profiles) and business customers (customers)
class CustomerNameResolverService {
  final SupabaseClient _supabase;

  CustomerNameResolverService(this._supabase);

  /// Resolve customer name by customer ID
  /// First checks customer_profiles table, then customers table
  Future<String> resolveCustomerName(String customerId) async {
    try {
      debugPrint('CustomerNameResolverService: Resolving name for customer ID: $customerId');

      // First try customer_profiles table (individual customers)
      final profileResponse = await _supabase
          .from('customer_profiles')
          .select('full_name')
          .eq('id', customerId)
          .maybeSingle();

      if (profileResponse != null && profileResponse['full_name'] != null) {
        final name = profileResponse['full_name'] as String;
        debugPrint('CustomerNameResolverService: Found name in customer_profiles: $name');
        return name;
      }

      // If not found, try customers table (business customers)
      final customerResponse = await _supabase
          .from('customers')
          .select('organization_name, contact_person_name')
          .eq('id', customerId)
          .maybeSingle();

      if (customerResponse != null) {
        final orgName = customerResponse['organization_name'] as String?;
        final contactName = customerResponse['contact_person_name'] as String?;
        
        // Prefer organization name, fallback to contact person name
        final name = orgName?.isNotEmpty == true ? orgName! : (contactName ?? 'Unknown Customer');
        debugPrint('CustomerNameResolverService: Found name in customers: $name');
        return name;
      }

      debugPrint('CustomerNameResolverService: No customer found with ID: $customerId');
      return 'Unknown Customer';
    } catch (e) {
      debugPrint('CustomerNameResolverService: Error resolving customer name: $e');
      return 'Unknown Customer';
    }
  }

  /// Resolve multiple customer names in batch
  Future<Map<String, String>> resolveCustomerNames(List<String> customerIds) async {
    try {
      debugPrint('CustomerNameResolverService: Resolving names for ${customerIds.length} customers');

      final Map<String, String> nameMap = {};

      // Batch fetch from customer_profiles
      final profilesResponse = await _supabase
          .from('customer_profiles')
          .select('id, full_name')
          .inFilter('id', customerIds);

      for (final profile in profilesResponse) {
        final id = profile['id'] as String;
        final name = profile['full_name'] as String?;
        if (name?.isNotEmpty == true) {
          nameMap[id] = name!;
        }
      }

      // Find remaining customer IDs not found in profiles
      final remainingIds = customerIds.where((id) => !nameMap.containsKey(id)).toList();

      if (remainingIds.isNotEmpty) {
        // Batch fetch from customers table
        final customersResponse = await _supabase
            .from('customers')
            .select('id, organization_name, contact_person_name')
            .inFilter('id', remainingIds);

        for (final customer in customersResponse) {
          final id = customer['id'] as String;
          final orgName = customer['organization_name'] as String?;
          final contactName = customer['contact_person_name'] as String?;
          
          // Prefer organization name, fallback to contact person name
          final name = orgName?.isNotEmpty == true ? orgName! : (contactName ?? 'Unknown Customer');
          nameMap[id] = name;
        }
      }

      // Fill in any missing names
      for (final id in customerIds) {
        if (!nameMap.containsKey(id)) {
          nameMap[id] = 'Unknown Customer';
        }
      }

      debugPrint('CustomerNameResolverService: Resolved ${nameMap.length} customer names');
      return nameMap;
    } catch (e) {
      debugPrint('CustomerNameResolverService: Error resolving customer names in batch: $e');
      
      // Return default names for all IDs
      final Map<String, String> defaultMap = {};
      for (final id in customerIds) {
        defaultMap[id] = 'Unknown Customer';
      }
      return defaultMap;
    }
  }

  /// Get customer contact information for order details
  Future<Map<String, dynamic>?> getCustomerContactInfo(String customerId) async {
    try {
      debugPrint('CustomerNameResolverService: Getting contact info for customer ID: $customerId');

      // First try customer_profiles table
      final profileResponse = await _supabase
          .from('customer_profiles')
          .select('full_name, phone_number, user_id')
          .eq('id', customerId)
          .maybeSingle();

      if (profileResponse != null) {
        // Get email from auth.users if available
        String? email;
        try {
          final userResponse = await _supabase
              .from('auth.users')
              .select('email')
              .eq('id', profileResponse['user_id'])
              .maybeSingle();
          email = userResponse?['email'] as String?;
        } catch (e) {
          debugPrint('CustomerNameResolverService: Could not fetch email from auth.users: $e');
        }

        return {
          'name': profileResponse['full_name'],
          'phone': profileResponse['phone_number'],
          'email': email,
          'type': 'individual',
        };
      }

      // If not found, try customers table
      final customerResponse = await _supabase
          .from('customers')
          .select('organization_name, contact_person_name, email, phone_number')
          .eq('id', customerId)
          .maybeSingle();

      if (customerResponse != null) {
        return {
          'name': customerResponse['organization_name'] ?? customerResponse['contact_person_name'],
          'contact_person': customerResponse['contact_person_name'],
          'phone': customerResponse['phone_number'],
          'email': customerResponse['email'],
          'type': 'business',
        };
      }

      debugPrint('CustomerNameResolverService: No contact info found for customer ID: $customerId');
      return null;
    } catch (e) {
      debugPrint('CustomerNameResolverService: Error getting customer contact info: $e');
      return null;
    }
  }
}
