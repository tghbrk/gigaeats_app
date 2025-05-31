import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/vendor.dart';
import '../models/product.dart';
import 'base_repository.dart';

class VendorRepository extends BaseRepository {
  VendorRepository({
    SupabaseClient? client,
  }) : super(client: client);

  /// Get vendors with optional filters
  Future<List<Vendor>> getVendors({
    String? searchQuery,
    List<String>? cuisineTypes,
    double? minRating,
    bool? isHalalOnly,
    double? maxDistance,
    double? latitude,
    double? longitude,
    int limit = 20,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      var query = authenticatedClient
          .from('vendors')
          .select('*')
          .eq('is_active', true);
          // Temporarily removed is_verified filter for testing

      // Apply search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'business_name.ilike.%$searchQuery%,'
          'description.ilike.%$searchQuery%,'
          'business_type.ilike.%$searchQuery%'
        );
      }

      // Apply cuisine type filter
      if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
        query = query.overlaps('cuisine_types', cuisineTypes);
      }

      // Apply rating filter
      if (minRating != null) {
        query = query.gte('rating', minRating);
      }

      // Apply halal filter
      if (isHalalOnly == true) {
        query = query.eq('is_halal_certified', true);
      }

      // Apply ordering and pagination after filters
      final response = await query
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      // Handle empty results gracefully
      if (response.isEmpty) {
        debugPrint('VendorRepository: No vendors found with current filters');
        return [];
      }

      return response.map((json) {
        try {
          // Handle potential null values and type conversions
          final processedJson = Map<String, dynamic>.from(json);

          // Ensure rating is a double
          if (processedJson['rating'] != null) {
            processedJson['rating'] = double.tryParse(processedJson['rating'].toString()) ?? 0.0;
          } else {
            processedJson['rating'] = 0.0;
          }

          // Ensure arrays are not null
          processedJson['cuisine_types'] = processedJson['cuisine_types'] ?? [];
          processedJson['gallery_images'] = processedJson['gallery_images'] ?? [];
          processedJson['service_areas'] = processedJson['service_areas'] ?? [];

          // Ensure numeric fields are properly typed
          if (processedJson['minimum_order_amount'] != null) {
            processedJson['minimum_order_amount'] = double.tryParse(processedJson['minimum_order_amount'].toString());
          }
          if (processedJson['delivery_fee'] != null) {
            processedJson['delivery_fee'] = double.tryParse(processedJson['delivery_fee'].toString());
          }
          if (processedJson['free_delivery_threshold'] != null) {
            processedJson['free_delivery_threshold'] = double.tryParse(processedJson['free_delivery_threshold'].toString());
          }

          return Vendor.fromJson(processedJson);
        } catch (e) {
          debugPrint('Error parsing vendor JSON: $e');
          debugPrint('JSON data: $json');
          rethrow;
        }
      }).toList();
    });
  }

  /// Get vendors stream for real-time updates
  Stream<List<Vendor>> getVendorsStream({
    String? searchQuery,
    List<String>? cuisineTypes,
    String? location,
  }) {
    return executeStreamQuery(() {
      var query = client
          .from('vendors')
          .select('''
            *,
            user:users!vendors_user_id_fkey(
              id,
              email,
              full_name,
              phone_number,
              profile_image_url
            )
          ''')
          .eq('is_active', true);
          // Temporarily removed is_verified filter for testing

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('business_name', '%$searchQuery%');
      }

      if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
        query = query.overlaps('cuisine_types', cuisineTypes);
      }

      if (location != null && location.isNotEmpty) {
        query = query.contains('service_areas', [location]);
      }

      return query
          .asStream()
          .map((data) => data.map((json) => Vendor.fromJson(json)).toList());
    });
  }

  /// Get vendor by ID
  Future<Vendor?> getVendorById(String vendorId) async {
    return executeQuery(() async {
      final response = await client
          .from('vendors')
          .select('''
            *,
            user:users!vendors_user_id_fkey(
              id,
              email,
              full_name,
              phone_number,
              profile_image_url
            )
          ''')
          .eq('id', vendorId)
          .single();

      return Vendor.fromJson(response);
    });
  }

  /// Get vendor by User ID (for vendor users)
  Future<Vendor?> getVendorByUserId(String userId) async {
    return executeQuery(() async {
      final response = await client
          .from('vendors')
          .select('''
            *,
            user:users!vendors_user_id_fkey(
              id,
              email,
              full_name,
              phone_number,
              profile_image_url
            )
          ''')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null ? Vendor.fromJson(response) : null;
    });
  }

  /// Create or update vendor profile
  Future<Vendor> upsertVendor(Vendor vendor) async {
    return executeQuery(() async {
      final vendorData = vendor.toJson();

      // Remove nested user data as it's handled separately
      vendorData.remove('user');

      final response = await client
          .from('vendors')
          .upsert(vendorData)
          .select('''
            *,
            user:users!vendors_user_id_fkey(
              id,
              email,
              full_name,
              phone_number,
              profile_image_url
            )
          ''')
          .single();

      return Vendor.fromJson(response);
    });
  }

  /// Get vendor products/menu items
  Future<List<Product>> getVendorProducts(
    String vendorId, {
    String? category,
    bool? isVegetarian,
    bool? isHalal,
    double? maxPrice,
    bool? isAvailable,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('VendorRepository: Getting products for vendor $vendorId');
      debugPrint('VendorRepository: Platform is ${kIsWeb ? "web" : "mobile"}');

      // Use authenticated client for web platform
      final queryClient = kIsWeb ? await getAuthenticatedClient() : client;

      var query = queryClient
          .from('menu_items')
          .select('*')
          .eq('vendor_id', vendorId);

      if (category != null) {
        query = query.eq('category', category);
      }

      if (isVegetarian == true) {
        query = query.eq('is_vegetarian', true);
      }

      if (isHalal == true) {
        query = query.eq('is_halal', true);
      }

      if (maxPrice != null) {
        query = query.lte('base_price', maxPrice);
      }

      if (isAvailable != null) {
        query = query.eq('is_available', isAvailable);
      }

      final response = await query
          .order('is_featured', ascending: false)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('VendorRepository: Found ${response.length} products');

      return response.map((json) {
        try {
          // Handle potential null values and type conversions
          final processedJson = Map<String, dynamic>.from(json);

          // Ensure required fields have default values
          processedJson['description'] = processedJson['description'] ?? '';
          processedJson['tags'] = processedJson['tags'] ?? [];
          processedJson['allergens'] = processedJson['allergens'] ?? [];
          processedJson['gallery_images'] = processedJson['gallery_images'] ?? [];
          processedJson['currency'] = processedJson['currency'] ?? 'MYR';

          // Ensure numeric fields are properly typed
          if (processedJson['base_price'] != null) {
            processedJson['base_price'] = double.tryParse(processedJson['base_price'].toString()) ?? 0.0;
          }
          if (processedJson['bulk_price'] != null) {
            processedJson['bulk_price'] = double.tryParse(processedJson['bulk_price'].toString());
          }
          if (processedJson['rating'] != null) {
            processedJson['rating'] = double.tryParse(processedJson['rating'].toString()) ?? 0.0;
          }

          return Product.fromJson(processedJson);
        } catch (e) {
          debugPrint('Error parsing product JSON: $e');
          debugPrint('JSON: $json');
          rethrow;
        }
      }).toList();
    });
  }

  /// Get available cuisine types
  Future<List<String>> getAvailableCuisineTypes() async {
    return executeQuery(() async {
      final response = await client
          .from('vendors')
          .select('cuisine_types')
          .eq('is_active', true)
          .eq('is_verified', true);

      final Set<String> cuisineTypes = {};
      for (final vendor in response) {
        final types = vendor['cuisine_types'] as List<dynamic>?;
        if (types != null) {
          cuisineTypes.addAll(types.cast<String>());
        }
      }

      return cuisineTypes.toList()..sort();
    });
  }

  /// Get featured vendors
  Future<List<Vendor>> getFeaturedVendors({int limit = 5}) async {
    return executeQuery(() async {
      final response = await client
          .from('vendors')
          .select('*')
          .eq('is_active', true)
          // Temporarily removed is_verified and rating filters for testing
          .order('rating', ascending: false)
          .order('total_orders', ascending: false)
          .limit(limit);

      return response.map((json) {
        try {
          // Handle potential null values and type conversions
          final processedJson = Map<String, dynamic>.from(json);

          // Ensure rating is a double
          if (processedJson['rating'] != null) {
            processedJson['rating'] = double.tryParse(processedJson['rating'].toString()) ?? 0.0;
          } else {
            processedJson['rating'] = 0.0;
          }

          // Ensure arrays are not null
          processedJson['cuisine_types'] = processedJson['cuisine_types'] ?? [];
          processedJson['gallery_images'] = processedJson['gallery_images'] ?? [];
          processedJson['service_areas'] = processedJson['service_areas'] ?? [];

          // Ensure numeric fields are properly typed
          if (processedJson['minimum_order_amount'] != null) {
            processedJson['minimum_order_amount'] = double.tryParse(processedJson['minimum_order_amount'].toString());
          }
          if (processedJson['delivery_fee'] != null) {
            processedJson['delivery_fee'] = double.tryParse(processedJson['delivery_fee'].toString());
          }
          if (processedJson['free_delivery_threshold'] != null) {
            processedJson['free_delivery_threshold'] = double.tryParse(processedJson['free_delivery_threshold'].toString());
          }

          return Vendor.fromJson(processedJson);
        } catch (e) {
          debugPrint('Error parsing featured vendor JSON: $e');
          debugPrint('JSON data: $json');
          rethrow;
        }
      }).toList();
    });
  }

  /// Get nearby vendors (requires location data in vendors table)
  Future<List<Vendor>> getNearbyVendors({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    return executeQuery(() async {
      // Note: This would require PostGIS extension for proper geospatial queries
      // For now, we'll return all vendors and let the client filter
      final response = await client
          .from('vendors')
          .select('''
            *,
            user:users!vendors_user_id_fkey(
              id,
              email,
              full_name,
              phone_number,
              profile_image_url
            )
          ''')
          .eq('is_active', true)
          // Temporarily removed is_verified filter for testing
          .order('rating', ascending: false)
          .limit(limit);

      return response.map((json) => Vendor.fromJson(json)).toList();
    });
  }

  /// Update vendor rating (called after order completion)
  Future<void> updateVendorRating(String vendorId, double newRating) async {
    return executeQuery(() async {
      await client
          .from('vendors')
          .update({
            'rating': newRating,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);
    });
  }

  /// Increment vendor order count
  Future<void> incrementOrderCount(String vendorId) async {
    return executeQuery(() async {
      await client.rpc('increment_vendor_orders', params: {
        'vendor_id': vendorId,
      });
    });
  }
}
