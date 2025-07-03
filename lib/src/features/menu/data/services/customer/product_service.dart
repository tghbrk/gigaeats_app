import '../../models/product.dart';
import '../../repositories/menu_item_repository.dart';
import '../../../../core/utils/logger.dart';

/// Product service for customer interface
/// Provides methods to fetch menu items and products for customers
class CustomerProductService {
  final MenuItemRepository _menuItemRepository;
  final AppLogger _logger = AppLogger();

  CustomerProductService({MenuItemRepository? menuItemRepository})
      : _menuItemRepository = menuItemRepository ?? MenuItemRepository();

  /// Get all products for a vendor
  Future<List<Product>> getVendorProducts(
    String vendorId, {
    String? category,
    bool? isAvailable = true,
    bool? isHalal,
    bool? isVegetarian,
    double? maxPrice,
    int limit = 50,
  }) async {
    try {
      _logger.info('CustomerProductService: Fetching products for vendor $vendorId');
      
      final products = await _menuItemRepository.getMenuItems(
        vendorId,
        category: category,
        isAvailable: isAvailable,
        isVegetarian: isVegetarian,
        isHalal: isHalal,
        maxPrice: maxPrice,
        limit: limit,
      );

      _logger.info('CustomerProductService: Found ${products.length} products for vendor $vendorId');
      return products;
    } catch (e) {
      _logger.error('CustomerProductService: Error fetching vendor products', e);
      rethrow;
    }
  }

  /// Get a specific product by ID
  Future<Product?> getProductById(String productId) async {
    try {
      _logger.info('CustomerProductService: Fetching product $productId');
      
      final product = await _menuItemRepository.getMenuItemById(productId);
      
      if (product != null) {
        _logger.info('CustomerProductService: Found product ${product.name}');
      } else {
        _logger.warning('CustomerProductService: Product $productId not found');
      }
      
      return product;
    } catch (e) {
      _logger.error('CustomerProductService: Error fetching product $productId', e);
      rethrow;
    }
  }

  /// Get featured products for a vendor
  Future<List<Product>> getFeaturedProducts(String vendorId, {int limit = 5}) async {
    try {
      _logger.info('CustomerProductService: Fetching featured products for vendor $vendorId');
      
      final products = await _menuItemRepository.getFeaturedMenuItems(vendorId, limit: limit);
      
      _logger.info('CustomerProductService: Found ${products.length} featured products');
      return products;
    } catch (e) {
      _logger.error('CustomerProductService: Error fetching featured products', e);
      rethrow;
    }
  }

  /// Search products for a vendor
  Future<List<Product>> searchProducts(
    String vendorId,
    String query, {
    int limit = 20,
  }) async {
    try {
      _logger.info('CustomerProductService: Searching products for vendor $vendorId with query "$query"');
      
      final products = await _menuItemRepository.searchMenuItems(vendorId, query, limit: limit);
      
      _logger.info('CustomerProductService: Found ${products.length} products matching "$query"');
      return products;
    } catch (e) {
      _logger.error('CustomerProductService: Error searching products', e);
      rethrow;
    }
  }

  /// Get products by category for a vendor
  Future<List<Product>> getProductsByCategory(String vendorId, String category) async {
    try {
      _logger.info('CustomerProductService: Fetching products for vendor $vendorId in category $category');
      
      final products = await _menuItemRepository.getMenuItems(
        vendorId,
        category: category,
        isAvailable: true,
      );
      
      _logger.info('CustomerProductService: Found ${products.length} products in category $category');
      return products;
    } catch (e) {
      _logger.error('CustomerProductService: Error fetching products by category', e);
      rethrow;
    }
  }

  /// Get available categories for a vendor
  Future<List<String>> getVendorCategories(String vendorId) async {
    try {
      _logger.info('CustomerProductService: Fetching categories for vendor $vendorId');
      
      final products = await _menuItemRepository.getMenuItems(vendorId, isAvailable: true);
      final categories = products.map((p) => p.category).toSet().toList();
      categories.sort();
      
      _logger.info('CustomerProductService: Found ${categories.length} categories for vendor $vendorId');
      return categories;
    } catch (e) {
      _logger.error('CustomerProductService: Error fetching vendor categories', e);
      rethrow;
    }
  }

  /// Get real-time stream of products for a vendor
  Stream<List<Product>> getVendorProductsStream(String vendorId) {
    try {
      _logger.info('CustomerProductService: Starting real-time stream for vendor $vendorId');
      
      return _menuItemRepository.getMenuItemsStream(vendorId);
    } catch (e) {
      _logger.error('CustomerProductService: Error creating products stream', e);
      rethrow;
    }
  }
}
