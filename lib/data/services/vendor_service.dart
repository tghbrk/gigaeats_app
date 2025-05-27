import '../models/vendor.dart';
import '../models/product.dart';
import 'mock_data.dart';

class VendorService {
  // In a real app, this would make API calls
  // TODO: Replace with actual API integration

  Future<List<Vendor>> getVendors({
    String? searchQuery,
    List<String>? cuisineTypes,
    double? minRating,
    bool? isHalalOnly,
    double? maxDistance,
    double? latitude,
    double? longitude,
  }) async {
    // Simulate API delay
    await Future.delayed(const Duration(milliseconds: 800));

    // TODO: Replace with actual API call
    var vendors = MockData.sampleVendors;

    // Apply filters
    if (searchQuery != null && searchQuery.isNotEmpty) {
      vendors = vendors.where((vendor) {
        return vendor.businessName.toLowerCase().contains(searchQuery.toLowerCase()) ||
            vendor.description.toLowerCase().contains(searchQuery.toLowerCase()) ||
            vendor.cuisineTypes.any((cuisine) =>
                cuisine.toLowerCase().contains(searchQuery.toLowerCase()));
      }).toList();
    }

    if (cuisineTypes != null && cuisineTypes.isNotEmpty) {
      vendors = vendors.where((vendor) {
        return vendor.cuisineTypes.any((cuisine) => cuisineTypes.contains(cuisine));
      }).toList();
    }

    if (minRating != null) {
      vendors = vendors.where((vendor) => vendor.rating >= minRating).toList();
    }

    if (isHalalOnly == true) {
      vendors = vendors.where((vendor) => vendor.isHalalCertified).toList();
    }

    // Sort by rating (highest first)
    vendors.sort((a, b) => b.rating.compareTo(a.rating));

    return vendors;
  }

  Future<Vendor?> getVendorById(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 300));

    // TODO: Replace with actual API call
    try {
      return MockData.sampleVendors.firstWhere((vendor) => vendor.id == vendorId);
    } catch (e) {
      return null;
    }
  }

  Future<List<Product>> getVendorProducts(String vendorId, {
    String? category,
    bool? isVegetarian,
    bool? isHalal,
    double? maxPrice,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500));

    // TODO: Replace with actual API call
    var products = MockData.getProductsForVendor(vendorId);

    // Apply filters
    if (category != null) {
      products = products.where((product) => product.category == category).toList();
    }

    if (isVegetarian == true) {
      products = products.where((product) => product.isVegetarian).toList();
    }

    if (isHalal == true) {
      products = products.where((product) => product.isHalal).toList();
    }

    if (maxPrice != null) {
      products = products.where((product) =>
          product.pricing.effectivePrice <= maxPrice).toList();
    }

    // Sort by rating and featured status
    products.sort((a, b) {
      if (a.isFeatured && !b.isFeatured) return -1;
      if (!a.isFeatured && b.isFeatured) return 1;
      return b.rating.compareTo(a.rating);
    });

    return products;
  }

  Future<List<String>> getAvailableCuisineTypes() async {
    await Future.delayed(const Duration(milliseconds: 200));

    // TODO: Replace with actual API call
    return MockData.cuisineTypes;
  }

  Future<List<Vendor>> getFeaturedVendors({int limit = 5}) async {
    await Future.delayed(const Duration(milliseconds: 400));

    // TODO: Replace with actual API call
    return MockData.sampleVendors.take(limit).toList();
  }

  Future<List<Vendor>> getNearbyVendors({
    required double latitude,
    required double longitude,
    double radiusKm = 10.0,
    int limit = 10,
  }) async {
    await Future.delayed(const Duration(milliseconds: 600));

    // TODO: Replace with actual API call
    return <Vendor>[];
  }

}
