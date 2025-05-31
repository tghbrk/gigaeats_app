import '../models/vendor.dart';
import '../models/product.dart';
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

}
