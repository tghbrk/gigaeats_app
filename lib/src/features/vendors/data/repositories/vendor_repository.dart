import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/vendor.dart';
import '../../../../core/data/repositories/base_repository.dart';
import '../../../menu/data/models/product.dart';

/// Repository for vendor-related operations
class VendorRepository extends BaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get all vendors
  Future<List<Vendor>> getVendors({
    bool? isActive,
    String? cuisineType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('vendors')
          .select('*');

      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      if (cuisineType != null) {
        query = query.contains('cuisine_types', [cuisineType]);
      }

      final response = await query
          .order('name')
          .range(offset, offset + limit - 1);

      return response.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendors: $e');
    }
  }

  /// Get vendor by ID
  Future<Vendor?> getVendorById(String vendorId) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('id', vendorId)
          .maybeSingle();

      if (response == null) return null;
      return Vendor.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch vendor: $e');
    }
  }

  /// Create vendor
  Future<Vendor> createVendor(Vendor vendor) async {
    try {
      final response = await _supabase
          .from('vendors')
          .insert(vendor.toJson())
          .select()
          .single();

      return Vendor.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create vendor: $e');
    }
  }

  /// Update vendor
  Future<Vendor> updateVendor(Vendor vendor) async {
    try {
      final response = await _supabase
          .from('vendors')
          .update(vendor.toJson())
          .eq('id', vendor.id)
          .select()
          .single();

      return Vendor.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update vendor: $e');
    }
  }

  /// Delete vendor
  Future<void> deleteVendor(String vendorId) async {
    try {
      await _supabase
          .from('vendors')
          .delete()
          .eq('id', vendorId);
    } catch (e) {
      throw Exception('Failed to delete vendor: $e');
    }
  }

  /// Get vendors by sales agent
  Future<List<Vendor>> getVendorsBySalesAgent(String salesAgentId) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('sales_agent_id', salesAgentId)
          .eq('is_active', true)
          .order('name');

      return response.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendors by sales agent: $e');
    }
  }

  /// Get vendors stream for real-time updates
  Stream<List<Vendor>> getVendorsStream({
    String? searchQuery,
    List<String>? cuisineTypes,
    String? location,
  }) {
    var query = _supabase
        .from('vendors')
        .stream(primaryKey: ['id'])
        .eq('is_active', true);

    return query.map((data) => data.map((json) => Vendor.fromJson(json)).toList());
  }

  /// Get featured vendors
  Future<List<Vendor>> getFeaturedVendors({int limit = 5}) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('is_active', true)
          .eq('is_featured', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured vendors: $e');
    }
  }

  /// Get available cuisine types
  Future<List<String>> getAvailableCuisineTypes() async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('cuisine_types')
          .eq('is_active', true);

      final Set<String> cuisineTypes = {};
      for (final vendor in response) {
        final types = vendor['cuisine_types'] as List<dynamic>?;
        if (types != null) {
          cuisineTypes.addAll(types.cast<String>());
        }
      }

      return cuisineTypes.toList()..sort();
    } catch (e) {
      throw Exception('Failed to fetch cuisine types: $e');
    }
  }

  /// Search vendors
  Future<List<Vendor>> searchVendors({
    required String query,
    String? cuisineType,
    bool? isActive,
    int limit = 20,
  }) async {
    try {
      var searchQuery = _supabase
          .from('vendors')
          .select('*')
          .or('name.ilike.%$query%,description.ilike.%$query%');

      if (isActive != null) {
        searchQuery = searchQuery.eq('is_active', isActive);
      }

      if (cuisineType != null) {
        searchQuery = searchQuery.contains('cuisine_types', [cuisineType]);
      }

      final response = await searchQuery
          .order('name')
          .limit(limit);

      return response.map((json) => Vendor.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to search vendors: $e');
    }
  }

  /// Update vendor status
  Future<void> updateVendorStatus(String vendorId, bool isActive) async {
    try {
      await _supabase
          .from('vendors')
          .update({'is_active': isActive})
          .eq('id', vendorId);
    } catch (e) {
      throw Exception('Failed to update vendor status: $e');
    }
  }

  /// Get vendor statistics
  Future<Map<String, dynamic>> getVendorStats(String vendorId) async {
    try {
      // This would typically involve multiple queries or a stored procedure
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, total_amount, status')
          .eq('vendor_id', vendorId);

      final totalOrders = ordersResponse.length;
      final totalRevenue = ordersResponse
          .where((order) => order['status'] == 'delivered')
          .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'active_orders': ordersResponse.where((order) =>
          ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(order['status'])
        ).length,
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor stats: $e');
    }
  }

  /// Get vendor by user ID
  Future<Vendor?> getVendorByUserId(String userId) async {
    try {
      final response = await _supabase
          .from('vendors')
          .select('*')
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) return null;
      return Vendor.fromJson(response);
    } catch (e) {
      throw Exception('Failed to fetch vendor by user ID: $e');
    }
  }

  /// Get vendor products
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
    try {
      var query = _supabase
          .from('menu_items')
          .select('*')
          .eq('vendor_id', vendorId);

      if (category != null) {
        query = query.eq('category', category);
      }

      if (isVegetarian != null) {
        query = query.eq('is_vegetarian', isVegetarian);
      }

      if (isHalal != null) {
        query = query.eq('is_halal', isHalal);
      }

      if (maxPrice != null) {
        query = query.lte('base_price', maxPrice);
      }

      if (isAvailable != null) {
        query = query.eq('is_available', isAvailable);
      } else {
        // Default to available products only
        query = query.eq('is_available', true);
      }

      final response = await query
          .order('name')
          .range(offset, offset + limit - 1);

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendor products: $e');
    }
  }

  /// Get vendor dashboard metrics
  Future<Map<String, dynamic>> getVendorDashboardMetrics(String vendorId) async {
    try {
      // Get orders data
      final ordersResponse = await _supabase
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('vendor_id', vendorId);

      // Get menu items count
      final menuItemsResponse = await _supabase
          .from('menu_items')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('is_available', true);

      final totalOrders = ordersResponse.length;
      final totalRevenue = ordersResponse
          .where((order) => order['status'] == 'delivered')
          .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      final activeOrders = ordersResponse.where((order) =>
        ['pending', 'confirmed', 'preparing', 'ready', 'out_for_delivery'].contains(order['status'])
      ).length;

      final totalMenuItems = menuItemsResponse.length;

      // Calculate today's orders
      final today = DateTime.now();
      final todayStart = DateTime(today.year, today.month, today.day);
      final todayOrders = ordersResponse.where((order) {
        final orderDate = DateTime.parse(order['created_at']);
        return orderDate.isAfter(todayStart);
      }).length;

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'active_orders': activeOrders,
        'total_menu_items': totalMenuItems,
        'today_orders': todayOrders,
        'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor dashboard metrics: $e');
    }
  }

  /// Get vendor filtered metrics
  Future<Map<String, dynamic>> getVendorFilteredMetrics(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    try {
      var query = _supabase
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('vendor_id', vendorId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      if (status != null) {
        query = query.eq('status', status);
      }

      final ordersResponse = await query;

      final totalOrders = ordersResponse.length;
      final totalRevenue = ordersResponse
          .where((order) => order['status'] == 'delivered')
          .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      return {
        'total_orders': totalOrders,
        'total_revenue': totalRevenue,
        'average_order_value': totalOrders > 0 ? totalRevenue / totalOrders : 0.0,
        'period_start': startDate?.toIso8601String(),
        'period_end': endDate?.toIso8601String(),
        'filter_status': status,
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor filtered metrics: $e');
    }
  }

  /// Get vendor total orders count
  Future<int> getVendorTotalOrdersCount(String vendorId) async {
    try {
      final response = await _supabase
          .from('orders')
          .select('id')
          .eq('vendor_id', vendorId);

      return response.length;
    } catch (e) {
      throw Exception('Failed to fetch vendor total orders count: $e');
    }
  }

  /// Get vendor rating metrics
  Future<Map<String, dynamic>> getVendorRatingMetrics(String vendorId) async {
    try {
      final response = await _supabase
          .from('order_reviews')
          .select('rating, comment')
          .eq('vendor_id', vendorId);

      if (response.isEmpty) {
        return {
          'average_rating': 0.0,
          'total_reviews': 0,
          'rating_distribution': {
            '5': 0,
            '4': 0,
            '3': 0,
            '2': 0,
            '1': 0,
          },
        };
      }

      final ratings = response.map((review) => review['rating'] as int).toList();
      final averageRating = ratings.fold<double>(0, (sum, rating) => sum + rating) / ratings.length;

      final ratingDistribution = <String, int>{
        '5': 0,
        '4': 0,
        '3': 0,
        '2': 0,
        '1': 0,
      };

      for (final rating in ratings) {
        ratingDistribution[rating.toString()] = (ratingDistribution[rating.toString()] ?? 0) + 1;
      }

      return {
        'average_rating': averageRating,
        'total_reviews': response.length,
        'rating_distribution': ratingDistribution,
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor rating metrics: $e');
    }
  }

  /// Get vendor analytics
  Future<Map<String, dynamic>> getVendorAnalytics(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('orders')
          .select('id, total_amount, status, created_at, order_items(*)')
          .eq('vendor_id', vendorId);

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final ordersResponse = await query;

      final totalOrders = ordersResponse.length;
      final completedOrders = ordersResponse.where((order) => order['status'] == 'delivered').toList();
      final totalRevenue = completedOrders
          .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      // Calculate daily breakdown
      final dailyBreakdown = <String, Map<String, dynamic>>{};
      for (final order in ordersResponse) {
        final orderDate = DateTime.parse(order['created_at']);
        final dateKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';

        if (!dailyBreakdown.containsKey(dateKey)) {
          dailyBreakdown[dateKey] = {
            'orders': 0,
            'revenue': 0.0,
          };
        }

        dailyBreakdown[dateKey]!['orders'] = (dailyBreakdown[dateKey]!['orders'] as int) + 1;
        if (order['status'] == 'delivered') {
          dailyBreakdown[dateKey]!['revenue'] = (dailyBreakdown[dateKey]!['revenue'] as double) + (order['total_amount'] as num).toDouble();
        }
      }

      return {
        'total_orders': totalOrders,
        'completed_orders': completedOrders.length,
        'total_revenue': totalRevenue,
        'average_order_value': completedOrders.isNotEmpty ? totalRevenue / completedOrders.length : 0.0,
        'completion_rate': totalOrders > 0 ? (completedOrders.length / totalOrders) * 100 : 0.0,
        'daily_breakdown': dailyBreakdown,
        'period_start': startDate?.toIso8601String(),
        'period_end': endDate?.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor analytics: $e');
    }
  }

  /// Get vendor sales breakdown
  Future<Map<String, dynamic>> getVendorSalesBreakdown(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('orders')
          .select('id, total_amount, status, created_at')
          .eq('vendor_id', vendorId)
          .eq('status', 'delivered');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final ordersResponse = await query;

      final totalRevenue = ordersResponse
          .fold<double>(0, (sum, order) => sum + (order['total_amount'] as num).toDouble());

      // Calculate monthly breakdown
      final monthlyBreakdown = <String, double>{};
      for (final order in ordersResponse) {
        final orderDate = DateTime.parse(order['created_at']);
        final monthKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}';

        monthlyBreakdown[monthKey] = (monthlyBreakdown[monthKey] ?? 0.0) + (order['total_amount'] as num).toDouble();
      }

      return {
        'total_revenue': totalRevenue,
        'total_orders': ordersResponse.length,
        'average_order_value': ordersResponse.isNotEmpty ? totalRevenue / ordersResponse.length : 0.0,
        'monthly_breakdown': monthlyBreakdown,
        'period_start': startDate?.toIso8601String(),
        'period_end': endDate?.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor sales breakdown: $e');
    }
  }

  /// Get vendor top products
  Future<List<Map<String, dynamic>>> getVendorTopProducts(
    String vendorId, {
    int limit = 10,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get order items with menu item details
      var query = _supabase
          .from('order_items')
          .select('quantity, menu_item_id, menu_items(name, base_price)')
          .eq('menu_items.vendor_id', vendorId);

      if (startDate != null || endDate != null) {
        // Join with orders to filter by date
        query = _supabase
            .from('order_items')
            .select('quantity, menu_item_id, menu_items(name, base_price), orders(created_at)')
            .eq('menu_items.vendor_id', vendorId);

        if (startDate != null) {
          query = query.gte('orders.created_at', startDate.toIso8601String());
        }

        if (endDate != null) {
          query = query.lte('orders.created_at', endDate.toIso8601String());
        }
      }

      final response = await query;

      // Group by menu item and calculate totals
      final productStats = <String, Map<String, dynamic>>{};

      for (final item in response) {
        final menuItemId = item['menu_item_id'] as String;
        final quantity = item['quantity'] as int;
        final menuItem = item['menu_items'] as Map<String, dynamic>;

        if (!productStats.containsKey(menuItemId)) {
          productStats[menuItemId] = {
            'menu_item_id': menuItemId,
            'name': menuItem['name'],
            'base_price': menuItem['base_price'],
            'total_quantity': 0,
            'total_revenue': 0.0,
          };
        }

        productStats[menuItemId]!['total_quantity'] =
            (productStats[menuItemId]!['total_quantity'] as int) + quantity;
        productStats[menuItemId]!['total_revenue'] =
            (productStats[menuItemId]!['total_revenue'] as double) +
            (quantity * (menuItem['base_price'] as num).toDouble());
      }

      // Sort by total quantity and return top products
      final sortedProducts = productStats.values.toList()
        ..sort((a, b) => (b['total_quantity'] as int).compareTo(a['total_quantity'] as int));

      return sortedProducts.take(limit).toList();
    } catch (e) {
      throw Exception('Failed to fetch vendor top products: $e');
    }
  }

  /// Get vendor category performance
  Future<Map<String, dynamic>> getVendorCategoryPerformance(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      // Get menu items with their categories and order data
      var query = _supabase
          .from('order_items')
          .select('quantity, menu_items(category, base_price)')
          .eq('menu_items.vendor_id', vendorId);

      if (startDate != null || endDate != null) {
        query = _supabase
            .from('order_items')
            .select('quantity, menu_items(category, base_price), orders(created_at)')
            .eq('menu_items.vendor_id', vendorId);

        if (startDate != null) {
          query = query.gte('orders.created_at', startDate.toIso8601String());
        }

        if (endDate != null) {
          query = query.lte('orders.created_at', endDate.toIso8601String());
        }
      }

      final response = await query;

      // Group by category
      final categoryStats = <String, Map<String, dynamic>>{};

      for (final item in response) {
        final quantity = item['quantity'] as int;
        final menuItem = item['menu_items'] as Map<String, dynamic>;
        final category = menuItem['category'] as String? ?? 'Uncategorized';

        if (!categoryStats.containsKey(category)) {
          categoryStats[category] = {
            'category': category,
            'total_quantity': 0,
            'total_revenue': 0.0,
            'item_count': 0,
          };
        }

        categoryStats[category]!['total_quantity'] =
            (categoryStats[category]!['total_quantity'] as int) + quantity;
        categoryStats[category]!['total_revenue'] =
            (categoryStats[category]!['total_revenue'] as double) +
            (quantity * (menuItem['base_price'] as num).toDouble());
        categoryStats[category]!['item_count'] =
            (categoryStats[category]!['item_count'] as int) + 1;
      }

      return {
        'categories': categoryStats.values.toList(),
        'total_categories': categoryStats.length,
        'period_start': startDate?.toIso8601String(),
        'period_end': endDate?.toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to fetch vendor category performance: $e');
    }
  }

  /// Get vendor revenue trends
  Future<List<Map<String, dynamic>>> getVendorRevenueTrends(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    String period = 'daily', // daily, weekly, monthly
  }) async {
    try {
      var query = _supabase
          .from('orders')
          .select('total_amount, created_at')
          .eq('vendor_id', vendorId)
          .eq('status', 'delivered');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query.order('created_at');

      // Group by period
      final trends = <String, Map<String, dynamic>>{};

      for (final order in response) {
        final orderDate = DateTime.parse(order['created_at']);
        String periodKey;

        switch (period) {
          case 'weekly':
            final weekStart = orderDate.subtract(Duration(days: orderDate.weekday - 1));
            periodKey = '${weekStart.year}-W${((weekStart.difference(DateTime(weekStart.year, 1, 1)).inDays) / 7).ceil()}';
            break;
          case 'monthly':
            periodKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}';
            break;
          case 'daily':
          default:
            periodKey = '${orderDate.year}-${orderDate.month.toString().padLeft(2, '0')}-${orderDate.day.toString().padLeft(2, '0')}';
            break;
        }

        if (!trends.containsKey(periodKey)) {
          trends[periodKey] = {
            'period': periodKey,
            'revenue': 0.0,
            'orders': 0,
            'date': orderDate.toIso8601String(),
          };
        }

        trends[periodKey]!['revenue'] =
            (trends[periodKey]!['revenue'] as double) + (order['total_amount'] as num).toDouble();
        trends[periodKey]!['orders'] =
            (trends[periodKey]!['orders'] as int) + 1;
      }

      // Sort by period and return as list
      final sortedTrends = trends.values.toList()
        ..sort((a, b) => (a['period'] as String).compareTo(b['period'] as String));

      return sortedTrends;
    } catch (e) {
      throw Exception('Failed to fetch vendor revenue trends: $e');
    }
  }

  /// Get vendor notifications
  Future<List<Map<String, dynamic>>> getVendorNotifications(
    String vendorId, {
    bool? isRead,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      var query = _supabase
          .from('notifications')
          .select('*')
          .eq('vendor_id', vendorId);

      if (isRead != null) {
        query = query.eq('is_read', isRead);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response;
    } catch (e) {
      throw Exception('Failed to fetch vendor notifications: $e');
    }
  }
}
