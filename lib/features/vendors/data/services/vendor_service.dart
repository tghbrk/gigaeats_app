import '../models/vendor.dart';
import '../../../menu/data/models/product.dart';
import '../repositories/vendor_repository.dart';

class VendorService {
  final VendorRepository _vendorRepository;

  VendorService({VendorRepository? vendorRepository})
      : _vendorRepository = vendorRepository ?? VendorRepository();

  Future<List<Vendor>> getVendors({
    String? searchQuery,
    List<String>? cuisineTypes,
    double? minRating,
    bool? isHalalOnly,
    double? maxDistance,
    double? latitude,
    double? longitude,
  }) async {
    return await _vendorRepository.getVendors(
      searchQuery: searchQuery,
      cuisineTypes: cuisineTypes,
      minRating: minRating,
      isHalalOnly: isHalalOnly,
      maxDistance: maxDistance,
      latitude: latitude,
      longitude: longitude,
    );
  }

  Future<Vendor?> getVendorById(String vendorId) async {
    return await _vendorRepository.getVendorById(vendorId);
  }

  Future<List<Product>> getVendorProducts(String vendorId, {
    String? category,
    bool? isVegetarian,
    bool? isHalal,
    double? maxPrice,
  }) async {
    return await _vendorRepository.getVendorProducts(
      vendorId,
      category: category,
      isVegetarian: isVegetarian,
      isHalal: isHalal,
      maxPrice: maxPrice,
    );
  }

  Future<List<String>> getAvailableCuisineTypes() async {
    return await _vendorRepository.getAvailableCuisineTypes();
  }

  Future<List<Vendor>> getFeaturedVendors({int limit = 5}) async {
    return await _vendorRepository.getFeaturedVendors(limit: limit);
  }

  Future<List<Vendor>> getNearbyVendors({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    return await _vendorRepository.getNearbyVendors(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      limit: limit,
    );
  }

  /// Get vendor dashboard metrics
  Future<Map<String, dynamic>> getVendorDashboardMetrics(String vendorId) async {
    return await _vendorRepository.getVendorDashboardMetrics(vendorId);
  }

  /// Get vendor analytics for a date range
  Future<List<Map<String, dynamic>>> getVendorAnalytics(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _vendorRepository.getVendorAnalytics(
      vendorId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get vendor notifications
  Future<List<Map<String, dynamic>>> getVendorNotifications(
    String vendorId, {
    bool? unreadOnly,
    int limit = 20,
  }) async {
    return await _vendorRepository.getVendorNotifications(
      vendorId,
      unreadOnly: unreadOnly,
      limit: limit,
    );
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    return await _vendorRepository.markNotificationAsRead(notificationId);
  }

  /// Get vendor settings
  Future<Map<String, dynamic>?> getVendorSettings(String vendorId) async {
    return await _vendorRepository.getVendorSettings(vendorId);
  }

  /// Update vendor settings
  Future<void> updateVendorSettings(
    String vendorId,
    Map<String, dynamic> settings,
  ) async {
    return await _vendorRepository.updateVendorSettings(vendorId, settings);
  }

  /// Update vendor profile
  Future<void> updateVendorProfile(
    String vendorId,
    Map<String, dynamic> profileData,
  ) async {
    return await _vendorRepository.updateVendorProfile(vendorId, profileData);
  }

  /// Create menu item
  Future<Map<String, dynamic>> createMenuItem(
    String vendorId,
    Map<String, dynamic> menuItemData,
  ) async {
    return await _vendorRepository.createMenuItem(vendorId, menuItemData);
  }

  /// Update menu item
  Future<void> updateMenuItem(
    String menuItemId,
    Map<String, dynamic> menuItemData,
  ) async {
    return await _vendorRepository.updateMenuItem(menuItemId, menuItemData);
  }

  /// Delete menu item
  Future<void> deleteMenuItem(String menuItemId) async {
    return await _vendorRepository.deleteMenuItem(menuItemId);
  }

  /// Update order status
  Future<void> updateOrderStatus(
    String orderId,
    String newStatus, {
    Map<String, dynamic>? metadata,
  }) async {
    return await _vendorRepository.updateOrderStatus(
      orderId,
      newStatus,
      metadata: metadata,
    );
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
    return await _vendorRepository.getVendorOrders(
      vendorId,
      status: status,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
      offset: offset,
    );
  }

  /// Get vendor sales breakdown by category for analytics
  Future<List<Map<String, dynamic>>> getVendorSalesBreakdown(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _vendorRepository.getVendorSalesBreakdown(
      vendorId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get vendor top performing products
  Future<List<Map<String, dynamic>>> getVendorTopProducts(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 10,
  }) async {
    return await _vendorRepository.getVendorTopProducts(
      vendorId,
      startDate: startDate,
      endDate: endDate,
      limit: limit,
    );
  }

  /// Get vendor category performance analytics
  Future<List<Map<String, dynamic>>> getVendorCategoryPerformance(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return await _vendorRepository.getVendorCategoryPerformance(
      vendorId,
      startDate: startDate,
      endDate: endDate,
    );
  }

  /// Get vendor revenue trends for analytics
  Future<List<Map<String, dynamic>>> getVendorRevenueTrends(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
    String period = 'daily',
  }) async {
    return await _vendorRepository.getVendorRevenueTrends(
      vendorId,
      startDate: startDate,
      endDate: endDate,
      period: period,
    );
  }

}
