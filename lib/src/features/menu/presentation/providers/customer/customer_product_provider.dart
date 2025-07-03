import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/product.dart';
import '../../../data/repositories/menu_item_repository.dart';
import '../../../data/services/customer/product_service.dart';

/// Provider for MenuItemRepository
final menuItemRepositoryProvider = Provider<MenuItemRepository>((ref) {
  return MenuItemRepository();
});

/// Provider for CustomerProductService
final customerProductServiceProvider = Provider<CustomerProductService>((ref) {
  final repository = ref.watch(menuItemRepositoryProvider);
  return CustomerProductService(menuItemRepository: repository);
});

/// Provider for vendor products
final vendorProductsProvider = FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.getVendorProducts(vendorId);
});

/// Provider for vendor products with filters
final filteredVendorProductsProvider = FutureProvider.family<List<Product>, VendorProductsFilter>((ref, filter) async {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.getVendorProducts(
    filter.vendorId,
    category: filter.category,
    isAvailable: filter.isAvailable,
    isHalal: filter.isHalal,
    isVegetarian: filter.isVegetarian,
    maxPrice: filter.maxPrice,
    limit: filter.limit,
  );
});

/// Provider for a specific product by ID
final productByIdProvider = FutureProvider.family<Product?, String>((ref, productId) async {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.getProductById(productId);
});

/// Provider for featured products
final featuredProductsProvider = FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.getFeaturedProducts(vendorId);
});

/// Provider for vendor categories
final vendorCategoriesProvider = FutureProvider.family<List<String>, String>((ref, vendorId) async {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.getVendorCategories(vendorId);
});

/// Provider for product search
final productSearchProvider = FutureProvider.family<List<Product>, ProductSearchParams>((ref, params) async {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.searchProducts(params.vendorId, params.query, limit: params.limit);
});

/// Provider for products by category
final productsByCategoryProvider = FutureProvider.family<List<Product>, CategoryParams>((ref, params) async {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.getProductsByCategory(params.vendorId, params.category);
});

/// Stream provider for real-time vendor products
final vendorProductsStreamProvider = StreamProvider.family<List<Product>, String>((ref, vendorId) {
  final productService = ref.watch(customerProductServiceProvider);
  return productService.getVendorProductsStream(vendorId);
});

/// Filter class for vendor products
class VendorProductsFilter {
  final String vendorId;
  final String? category;
  final bool? isAvailable;
  final bool? isHalal;
  final bool? isVegetarian;
  final double? maxPrice;
  final int limit;

  const VendorProductsFilter({
    required this.vendorId,
    this.category,
    this.isAvailable = true,
    this.isHalal,
    this.isVegetarian,
    this.maxPrice,
    this.limit = 50,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VendorProductsFilter &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          category == other.category &&
          isAvailable == other.isAvailable &&
          isHalal == other.isHalal &&
          isVegetarian == other.isVegetarian &&
          maxPrice == other.maxPrice &&
          limit == other.limit;

  @override
  int get hashCode =>
      vendorId.hashCode ^
      category.hashCode ^
      isAvailable.hashCode ^
      isHalal.hashCode ^
      isVegetarian.hashCode ^
      maxPrice.hashCode ^
      limit.hashCode;
}

/// Search parameters class
class ProductSearchParams {
  final String vendorId;
  final String query;
  final int limit;

  const ProductSearchParams({
    required this.vendorId,
    required this.query,
    this.limit = 20,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProductSearchParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          query == other.query &&
          limit == other.limit;

  @override
  int get hashCode => vendorId.hashCode ^ query.hashCode ^ limit.hashCode;
}

/// Category parameters class
class CategoryParams {
  final String vendorId;
  final String category;

  const CategoryParams({
    required this.vendorId,
    required this.category,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          category == other.category;

  @override
  int get hashCode => vendorId.hashCode ^ category.hashCode;
}
