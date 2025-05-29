import 'dart:convert';

import '../../../core/errors/exceptions.dart';
import '../../../core/utils/logger.dart';
import '../../services/cache_service.dart';
import '../../models/user.dart';
import '../../models/vendor.dart';
import '../../models/order.dart';
import '../../models/product.dart';

/// Local data source for caching operations
abstract class CacheDataSource {
  // User caching
  Future<void> cacheUser(User user);
  Future<User?> getCachedUser(String userId);
  Future<void> removeCachedUser(String userId);
  Future<List<User>> getCachedUsers();

  // Vendor caching
  Future<void> cacheVendor(Vendor vendor);
  Future<Vendor?> getCachedVendor(String vendorId);
  Future<void> removeCachedVendor(String vendorId);
  Future<List<Vendor>> getCachedVendors();

  // Order caching
  Future<void> cacheOrder(Order order);
  Future<Order?> getCachedOrder(String orderId);
  Future<void> removeCachedOrder(String orderId);
  Future<List<Order>> getCachedOrders();

  // Product caching
  Future<void> cacheProduct(Product product);
  Future<Product?> getCachedProduct(String productId);
  Future<void> removeCachedProduct(String productId);
  Future<List<Product>> getCachedProducts();

  // Generic caching
  Future<void> cacheData<T>(String key, T data, {Duration? expiration});
  Future<T?> getCachedData<T>(String key);
  Future<void> removeCachedData(String key);

  // Cache management
  Future<void> clearAllCache();
  Future<void> clearCacheCategory(CacheCategory category);
}

/// Implementation of CacheDataSource using CacheService
class CacheDataSourceImpl implements CacheDataSource {
  final CacheService _cacheService;
  final AppLogger _logger = AppLogger();

  CacheDataSourceImpl({CacheService? cacheService})
      : _cacheService = cacheService ?? CacheService();

  @override
  Future<void> cacheUser(User user) async {
    try {
      await _cacheService.store(
        'user_${user.id}',
        user.toJson(),
        category: CacheCategory.user,
      );
      _logger.debug('Cached user: ${user.id}');
    } catch (e) {
      _logger.error('Failed to cache user: ${user.id}', e);
      throw CacheException(
        message: 'Failed to cache user data',
        details: e,
      );
    }
  }

  @override
  Future<User?> getCachedUser(String userId) async {
    try {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(
        'user_$userId',
        category: CacheCategory.user,
      );

      if (cachedData == null) return null;

      return User.fromJson(cachedData);
    } catch (e) {
      _logger.warning('Failed to get cached user: $userId', e);
      return null;
    }
  }

  @override
  Future<void> removeCachedUser(String userId) async {
    try {
      await _cacheService.remove('user_$userId');
      _logger.debug('Removed cached user: $userId');
    } catch (e) {
      _logger.error('Failed to remove cached user: $userId', e);
    }
  }

  @override
  Future<List<User>> getCachedUsers() async {
    try {
      // This is a simplified implementation
      // In a real scenario, you might want to store a list of user IDs
      // and fetch them individually or store the entire list
      return [];
    } catch (e) {
      _logger.error('Failed to get cached users', e);
      return [];
    }
  }

  @override
  Future<void> cacheVendor(Vendor vendor) async {
    try {
      await _cacheService.store(
        'vendor_${vendor.id}',
        vendor.toJson(),
        category: CacheCategory.vendor,
      );
      _logger.debug('Cached vendor: ${vendor.id}');
    } catch (e) {
      _logger.error('Failed to cache vendor: ${vendor.id}', e);
      throw CacheException(
        message: 'Failed to cache vendor data',
        details: e,
      );
    }
  }

  @override
  Future<Vendor?> getCachedVendor(String vendorId) async {
    try {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(
        'vendor_$vendorId',
        category: CacheCategory.vendor,
      );

      if (cachedData == null) return null;

      return Vendor.fromJson(cachedData);
    } catch (e) {
      _logger.warning('Failed to get cached vendor: $vendorId', e);
      return null;
    }
  }

  @override
  Future<void> removeCachedVendor(String vendorId) async {
    try {
      await _cacheService.remove('vendor_$vendorId');
      _logger.debug('Removed cached vendor: $vendorId');
    } catch (e) {
      _logger.error('Failed to remove cached vendor: $vendorId', e);
    }
  }

  @override
  Future<List<Vendor>> getCachedVendors() async {
    try {
      final cachedData = await _cacheService.get<List<dynamic>>(
        'vendors_list',
        category: CacheCategory.vendor,
      );

      if (cachedData == null) return [];

      return cachedData
          .map((json) => Vendor.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Failed to get cached vendors', e);
      return [];
    }
  }

  @override
  Future<void> cacheOrder(Order order) async {
    try {
      await _cacheService.store(
        'order_${order.id}',
        order.toJson(),
        category: CacheCategory.order,
      );
      _logger.debug('Cached order: ${order.id}');
    } catch (e) {
      _logger.error('Failed to cache order: ${order.id}', e);
      throw CacheException(
        message: 'Failed to cache order data',
        details: e,
      );
    }
  }

  @override
  Future<Order?> getCachedOrder(String orderId) async {
    try {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(
        'order_$orderId',
        category: CacheCategory.order,
      );

      if (cachedData == null) return null;

      return Order.fromJson(cachedData);
    } catch (e) {
      _logger.warning('Failed to get cached order: $orderId', e);
      return null;
    }
  }

  @override
  Future<void> removeCachedOrder(String orderId) async {
    try {
      await _cacheService.remove('order_$orderId');
      _logger.debug('Removed cached order: $orderId');
    } catch (e) {
      _logger.error('Failed to remove cached order: $orderId', e);
    }
  }

  @override
  Future<List<Order>> getCachedOrders() async {
    try {
      final cachedData = await _cacheService.get<List<dynamic>>(
        'orders_list',
        category: CacheCategory.order,
      );

      if (cachedData == null) return [];

      return cachedData
          .map((json) => Order.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Failed to get cached orders', e);
      return [];
    }
  }

  @override
  Future<void> cacheProduct(Product product) async {
    try {
      await _cacheService.store(
        'product_${product.id}',
        product.toJson(),
        category: CacheCategory.menuItem,
      );
      _logger.debug('Cached product: ${product.id}');
    } catch (e) {
      _logger.error('Failed to cache product: ${product.id}', e);
      throw CacheException(
        message: 'Failed to cache product data',
        details: e,
      );
    }
  }

  @override
  Future<Product?> getCachedProduct(String productId) async {
    try {
      final cachedData = await _cacheService.get<Map<String, dynamic>>(
        'product_$productId',
        category: CacheCategory.menuItem,
      );

      if (cachedData == null) return null;

      return Product.fromJson(cachedData);
    } catch (e) {
      _logger.warning('Failed to get cached product: $productId', e);
      return null;
    }
  }

  @override
  Future<void> removeCachedProduct(String productId) async {
    try {
      await _cacheService.remove('product_$productId');
      _logger.debug('Removed cached product: $productId');
    } catch (e) {
      _logger.error('Failed to remove cached product: $productId', e);
    }
  }

  @override
  Future<List<Product>> getCachedProducts() async {
    try {
      final cachedData = await _cacheService.get<List<dynamic>>(
        'products_list',
        category: CacheCategory.menuItem,
      );

      if (cachedData == null) return [];

      return cachedData
          .map((json) => Product.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _logger.error('Failed to get cached products', e);
      return [];
    }
  }

  @override
  Future<void> cacheData<T>(String key, T data, {Duration? expiration}) async {
    try {
      String serializedData;
      if (data is Map || data is List) {
        serializedData = json.encode(data);
      } else {
        serializedData = data.toString();
      }

      await _cacheService.store(
        key,
        serializedData,
        expiration: expiration,
        category: CacheCategory.general,
      );
      _logger.debug('Cached data for key: $key');
    } catch (e) {
      _logger.error('Failed to cache data for key: $key', e);
      throw CacheException(
        message: 'Failed to cache data',
        details: e,
      );
    }
  }

  @override
  Future<T?> getCachedData<T>(String key) async {
    try {
      final cachedData = await _cacheService.get<String>(
        key,
        category: CacheCategory.general,
      );

      if (cachedData == null) return null;

      // Try to decode as JSON first
      try {
        final decoded = json.decode(cachedData);
        return decoded as T?;
      } catch (_) {
        // If JSON decoding fails, return as string if T is String
        if (T == String) {
          return cachedData as T?;
        }
        return null;
      }
    } catch (e) {
      _logger.warning('Failed to get cached data for key: $key', e);
      return null;
    }
  }

  @override
  Future<void> removeCachedData(String key) async {
    try {
      await _cacheService.remove(key);
      _logger.debug('Removed cached data for key: $key');
    } catch (e) {
      _logger.error('Failed to remove cached data for key: $key', e);
    }
  }

  @override
  Future<void> clearAllCache() async {
    try {
      await _cacheService.clearAll();
      _logger.info('Cleared all cache');
    } catch (e) {
      _logger.error('Failed to clear all cache', e);
      throw CacheException(
        message: 'Failed to clear cache',
        details: e,
      );
    }
  }

  @override
  Future<void> clearCacheCategory(CacheCategory category) async {
    try {
      await _cacheService.clearCategory(category);
      _logger.info('Cleared cache for category: ${category.name}');
    } catch (e) {
      _logger.error('Failed to clear cache for category: ${category.name}', e);
      throw CacheException(
        message: 'Failed to clear cache category',
        details: e,
      );
    }
  }
}
