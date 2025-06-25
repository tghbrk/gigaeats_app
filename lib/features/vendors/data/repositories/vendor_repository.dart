import 'package:flutter/foundation.dart';

import '../models/vendor.dart';
import '../../../menu/data/models/product.dart';
import 'base_repository.dart';

class VendorRepository extends BaseRepository {
  VendorRepository();

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
      var query = supabase
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
      final response = await supabase
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
      final response = await supabase
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

      final response = await supabase
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
      debugPrint('VendorRepository: ===== getVendorProducts CALLED for vendor $vendorId =====');
      debugPrint('VendorRepository: Getting products for vendor $vendorId');
      debugPrint('VendorRepository: Platform is ${kIsWeb ? "web" : "mobile"}');

      // Use authenticated client for web platform
      final queryClient = kIsWeb ? await getAuthenticatedClient() : supabase;

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

      // Load customizations for each menu item
      final products = <Product>[];
      for (final json in response) {
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

          final product = Product.fromJson(processedJson);

          // Load customizations for this menu item
          final customizations = await _getMenuItemCustomizations(product.id);

          // Create product with customizations
          final productWithCustomizations = product.copyWith(customizations: customizations);
          products.add(productWithCustomizations);

          debugPrint('VendorRepository: Loaded ${customizations.length} customizations for ${product.name}');
        } catch (e) {
          debugPrint('Error parsing product JSON: $e');
          debugPrint('JSON: $json');
          rethrow;
        }
      }

      debugPrint('VendorRepository: Returning ${products.length} products with customizations');
      return products;
    });
  }

  /// Get available cuisine types
  Future<List<String>> getAvailableCuisineTypes() async {
    return executeQuery(() async {
      final response = await supabase
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
      final response = await supabase
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
      final response = await supabase
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
      await supabase
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
      await supabase.rpc('increment_vendor_orders', params: {
        'vendor_id': vendorId,
      });
    });
  }

  /// Get vendor dashboard metrics
  Future<Map<String, dynamic>> getVendorDashboardMetrics(String vendorId) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .rpc('get_vendor_dashboard_metrics', params: {'p_vendor_id': vendorId});

      if (response.isNotEmpty) {
        return response.first as Map<String, dynamic>;
      }

      return {
        'today_orders': 0,
        'today_revenue': 0.0,
        'pending_orders': 0,
        'avg_preparation_time': 0,
        'rating': 0.0,
        'total_reviews': 0,
      };
    });
  }

  /// Get vendor filtered metrics for a specific date range
  Future<Map<String, dynamic>> getVendorFilteredMetrics(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      // Set default date range if not provided
      final effectiveStartDate = startDate ?? DateTime.now();
      final effectiveEndDate = endDate ?? DateTime.now();

      // Format dates for SQL queries
      final startDateStr = effectiveStartDate.toIso8601String().split('T')[0];
      final endDateStr = effectiveEndDate.toIso8601String().split('T')[0];

      debugPrint('🔍 [VENDOR-METRICS] Getting filtered metrics for vendor $vendorId from $startDateStr to $endDateStr');

      // Get total orders and revenue for the date range
      final ordersResponse = await authenticatedClient
          .from('orders')
          .select('total_amount')
          .eq('vendor_id', vendorId)
          .eq('status', 'delivered')
          .gte('created_at', '${startDateStr}T00:00:00')
          .lte('created_at', '${endDateStr}T23:59:59');

      final totalOrders = ordersResponse.length;
      final totalRevenue = ordersResponse.fold<double>(
        0.0,
        (sum, order) => sum + (order['total_amount'] as num).toDouble(),
      );
      final avgOrderValue = totalOrders > 0 ? totalRevenue / totalOrders : 0.0;

      // Get pending orders (current, not filtered by date)
      final pendingResponse = await authenticatedClient
          .from('orders')
          .select('id')
          .eq('vendor_id', vendorId)
          .inFilter('status', ['pending', 'confirmed', 'preparing']);

      final pendingOrders = pendingResponse.length;

      // Get vendor rating and review count (overall, not filtered by date)
      final vendorResponse = await authenticatedClient
          .from('vendors')
          .select('rating, total_reviews')
          .eq('id', vendorId)
          .single();

      final rating = (vendorResponse['rating'] as num?)?.toDouble() ?? 0.0;
      final totalReviews = vendorResponse['total_reviews'] as int? ?? 0;

      debugPrint('🔍 [VENDOR-METRICS] Results: orders=$totalOrders, revenue=$totalRevenue, pending=$pendingOrders');

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'avg_order_value': avgOrderValue,
        'pending_orders': pendingOrders,
        'avg_preparation_time': 0, // TODO: Calculate from order timestamps
        'rating': rating,
        'total_reviews': totalReviews,
      };
    });
  }

  /// Get vendor analytics for a date range
  Future<List<Map<String, dynamic>>> getVendorAnalytics(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      var query = authenticatedClient
          .from('vendor_analytics')
          .select('*')
          .eq('vendor_id', vendorId);

      if (startDate != null) {
        query = query.gte('date', startDate.toIso8601String().split('T')[0]);
      }
      if (endDate != null) {
        query = query.lte('date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query.order('date', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Get vendor notifications
  Future<List<Map<String, dynamic>>> getVendorNotifications(
    String vendorId, {
    bool? unreadOnly,
    int limit = 20,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      var query = authenticatedClient
          .from('vendor_notifications')
          .select('*')
          .eq('vendor_id', vendorId);

      if (unreadOnly == true) {
        query = query.eq('is_read', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);
      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      await authenticatedClient
          .from('vendor_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    });
  }

  /// Get vendor settings
  Future<Map<String, dynamic>?> getVendorSettings(String vendorId) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .from('vendor_settings')
          .select('*')
          .eq('vendor_id', vendorId)
          .maybeSingle();

      return response;
    });
  }

  /// Update vendor settings
  Future<void> updateVendorSettings(
    String vendorId,
    Map<String, dynamic> settings,
  ) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      try {
        // Try to update first
        await authenticatedClient
            .from('vendor_settings')
            .update({
              ...settings,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('vendor_id', vendorId);
      } catch (e) {
        // If update fails (likely because no record exists), try to insert
        try {
          await authenticatedClient
              .from('vendor_settings')
              .insert({
                'vendor_id': vendorId,
                ...settings,
                'created_at': DateTime.now().toIso8601String(),
                'updated_at': DateTime.now().toIso8601String(),
              });
        } catch (insertError) {
          // If insert also fails, it might be a duplicate key error
          // Try update one more time
          await authenticatedClient
              .from('vendor_settings')
              .update({
                ...settings,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('vendor_id', vendorId);
        }
      }
    });
  }

  /// Update vendor profile
  Future<void> updateVendorProfile(
    String vendorId,
    Map<String, dynamic> profileData,
  ) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      await authenticatedClient
          .from('vendors')
          .update({
            ...profileData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);
    });
  }

  /// Create menu item
  Future<Map<String, dynamic>> createMenuItem(
    String vendorId,
    Map<String, dynamic> menuItemData,
  ) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .from('menu_items')
          .insert({
            'vendor_id': vendorId,
            ...menuItemData,
            'created_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    });
  }

  /// Update menu item
  Future<void> updateMenuItem(
    String menuItemId,
    Map<String, dynamic> menuItemData,
  ) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      await authenticatedClient
          .from('menu_items')
          .update({
            ...menuItemData,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', menuItemId);
    });
  }

  /// Delete menu item
  Future<void> deleteMenuItem(String menuItemId) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      await authenticatedClient
          .from('menu_items')
          .delete()
          .eq('id', menuItemId);
    });
  }

  /// Delete vendor (soft delete by setting is_active to false)
  Future<void> deleteVendor(String vendorId) async {
    return executeQuery(() async {
      debugPrint('VendorRepository: Soft deleting vendor: $vendorId');

      final authenticatedClient = await getAuthenticatedClient();
      await authenticatedClient
          .from('vendors')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', vendorId);

      debugPrint('VendorRepository: Vendor soft deleted successfully');
    });
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    Map<String, dynamic>? metadata,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final updateData = <String, dynamic>{
        'status': newStatus,
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add status-specific timestamps
      switch (newStatus) {
        case 'confirmed':
          // Order confirmed, no specific timestamp needed
          break;
        case 'preparing':
          updateData['preparation_started_at'] = DateTime.now().toIso8601String();
          break;
        case 'ready':
          updateData['ready_at'] = DateTime.now().toIso8601String();
          break;
        case 'out_for_delivery':
          updateData['out_for_delivery_at'] = DateTime.now().toIso8601String();
          break;
        case 'delivered':
          updateData['actual_delivery_time'] = DateTime.now().toIso8601String();
          break;
      }

      if (metadata != null) {
        updateData.addAll(metadata);
      }

      await authenticatedClient
          .from('orders')
          .update(updateData)
          .eq('id', orderId);
    });
  }

  /// Get vendor orders with filters
  Future<List<Map<String, dynamic>>> getVendorOrders(
    String vendorId, {
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      var query = authenticatedClient
          .from('orders')
          .select('''
            *,
            customer:customers!orders_customer_id_fkey(
              id,
              organization_name,
              contact_person_name,
              email,
              phone_number
            ),
            order_items:order_items(
              id,
              name,
              description,
              unit_price,
              quantity,
              total_price,
              notes
            )
          ''')
          .eq('vendor_id', vendorId);

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Get vendor sales breakdown by category for analytics
  Future<List<Map<String, dynamic>>> getVendorSalesBreakdown(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .rpc('get_vendor_sales_breakdown', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
      });

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Get total orders count for a vendor (real-time calculation)
  Future<int> getVendorTotalOrdersCount(String vendorId) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .from('orders')
          .select('id')
          .eq('vendor_id', vendorId);

      debugPrint('🔍 [VENDOR-ORDERS-COUNT] Vendor ID: $vendorId, Total Orders: ${response.length}');
      return response.length;
    });
  }

  /// Calculate vendor rating based on order performance (real-time calculation)
  /// Since no reviews table exists, this calculates rating based on:
  /// - Order completion rate (delivered vs total)
  /// - Customer retention (repeat customers)
  /// - Order fulfillment consistency
  Future<Map<String, dynamic>> getVendorRatingMetrics(String vendorId) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();

      // Get all orders for the vendor
      final allOrdersResponse = await authenticatedClient
          .from('orders')
          .select('id, status, customer_id, created_at')
          .eq('vendor_id', vendorId);

      final totalOrders = allOrdersResponse.length;

      if (totalOrders == 0) {
        return {
          'rating': 0.0,
          'total_reviews': 0,
          'completion_rate': 0.0,
          'total_orders': 0,
        };
      }

      // Calculate completion rate (delivered orders)
      final deliveredOrders = allOrdersResponse
          .where((order) => order['status'] == 'delivered')
          .length;
      final completionRate = deliveredOrders / totalOrders;

      // Calculate customer retention (unique vs repeat customers)
      final customerIds = allOrdersResponse
          .map((order) => order['customer_id'] as String)
          .toList();
      final uniqueCustomers = customerIds.toSet().length;
      final retentionRate = uniqueCustomers > 0 ?
          (totalOrders - uniqueCustomers) / totalOrders : 0.0;

      // Calculate rating based on performance metrics
      // Base rating starts at 3.0, with bonuses for good performance
      double rating = 3.0;

      // Completion rate bonus (up to +1.5 points)
      rating += completionRate * 1.5;

      // Customer retention bonus (up to +0.5 points)
      rating += retentionRate * 0.5;

      // Ensure rating is between 0.0 and 5.0
      rating = rating.clamp(0.0, 5.0);

      final result = {
        'rating': double.parse(rating.toStringAsFixed(1)),
        'total_reviews': totalOrders, // Use total orders as "review" count
        'completion_rate': double.parse((completionRate * 100).toStringAsFixed(1)),
        'total_orders': totalOrders,
      };

      debugPrint('🔍 [VENDOR-RATING-METRICS] Vendor ID: $vendorId');
      debugPrint('🔍 [VENDOR-RATING-METRICS] Total Orders: $totalOrders, Delivered: $deliveredOrders');
      debugPrint('🔍 [VENDOR-RATING-METRICS] Completion Rate: ${(completionRate * 100).toStringAsFixed(1)}%');
      debugPrint('🔍 [VENDOR-RATING-METRICS] Calculated Rating: ${rating.toStringAsFixed(1)}');

      return result;
    });
  }

  /// Get vendor top performing products
  Future<List<Map<String, dynamic>>> getVendorTopProducts(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .rpc('get_vendor_top_products', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
        'p_limit': limit,
      });

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Get vendor category performance analytics
  Future<List<Map<String, dynamic>>> getVendorCategoryPerformance(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .rpc('get_vendor_category_performance', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
      });

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Get vendor revenue trends for analytics
  Future<List<Map<String, dynamic>>> getVendorRevenueTrends(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    String period = 'daily', // daily, weekly, monthly
  }) async {
    return executeQuery(() async {
      final authenticatedClient = await getAuthenticatedClient();
      final response = await authenticatedClient
          .rpc('get_vendor_revenue_trends', params: {
        'p_vendor_id': vendorId,
        'p_start_date': startDate?.toIso8601String().split('T')[0],
        'p_end_date': endDate?.toIso8601String().split('T')[0],
        'p_period': period,
      });

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Helper method to get customizations for a menu item
  Future<List<MenuItemCustomization>> _getMenuItemCustomizations(String menuItemId) async {
    return executeQuery(() async {
      final customizationsResponse = await supabase
          .from('menu_item_customizations')
          .select('*')
          .eq('menu_item_id', menuItemId)
          .order('display_order');

      final customizations = <MenuItemCustomization>[];

      for (final customizationData in customizationsResponse) {
        final optionsResponse = await supabase
            .from('customization_options')
            .select('*')
            .eq('customization_id', customizationData['id'])
            .order('display_order');

        final options = optionsResponse.map((optionData) => CustomizationOption(
          id: optionData['id'],
          name: optionData['name'],
          additionalPrice: (optionData['additional_price'] ?? 0.0).toDouble(),
          isDefault: optionData['is_default'] ?? false,
        )).toList();

        customizations.add(MenuItemCustomization(
          id: customizationData['id'],
          name: customizationData['name'],
          type: customizationData['type'] ?? 'single',
          isRequired: customizationData['is_required'] ?? false,
          options: options,
        ));
      }

      return customizations;
    });
  }
}
