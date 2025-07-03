import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user_management/domain/vendor.dart';
import '../../../menu/data/models/product.dart';
import '../../data/services/vendor_service.dart';
import 'vendor_repository_providers.dart';
import '../../../../core/utils/logger.dart';

// Vendor Service Provider
final vendorServiceProvider = Provider<VendorService>((ref) {
  final vendorRepository = ref.watch(vendorRepositoryProvider);
  return VendorService(vendorRepository: vendorRepository);
});

// Vendors List Provider
final vendorsProvider = StateNotifierProvider<VendorsNotifier, VendorsState>((ref) {
  final vendorService = ref.watch(vendorServiceProvider);
  return VendorsNotifier(vendorService);
});

// Featured Vendors Provider (using service layer)
final featuredVendorsServiceProvider = FutureProvider<List<Vendor>>((ref) async {
  final vendorService = ref.watch(vendorServiceProvider);
  return vendorService.getFeaturedVendors();
});

// Vendor Details Provider
final vendorDetailsProvider = FutureProvider.family<Vendor?, String>((ref, vendorId) async {
  final vendorService = ref.watch(vendorServiceProvider);
  return vendorService.getVendorById(vendorId);
});

// Vendor Products Provider (using service layer)
final vendorProductsServiceProvider = FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  final vendorService = ref.watch(vendorServiceProvider);
  return vendorService.getVendorProducts(vendorId);
});

// Available Cuisine Types Provider
final cuisineTypesProvider = FutureProvider<List<String>>((ref) async {
  final vendorService = ref.watch(vendorServiceProvider);
  return vendorService.getAvailableCuisineTypes();
});

// Vendors State
class VendorsState {
  final List<Vendor> vendors;
  final bool isLoading;
  final String? errorMessage;
  final VendorFilters filters;

  const VendorsState({
    this.vendors = const [],
    this.isLoading = false,
    this.errorMessage,
    this.filters = const VendorFilters(),
  });

  VendorsState copyWith({
    List<Vendor>? vendors,
    bool? isLoading,
    String? errorMessage,
    VendorFilters? filters,
  }) {
    return VendorsState(
      vendors: vendors ?? this.vendors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      filters: filters ?? this.filters,
    );
  }
}

// Vendor Filters
class VendorFilters {
  final String? searchQuery;
  final List<String> cuisineTypes;
  final double? minRating;
  final bool isHalalOnly;
  final double? maxDistance;
  final double? latitude;
  final double? longitude;

  const VendorFilters({
    this.searchQuery,
    this.cuisineTypes = const [],
    this.minRating,
    this.isHalalOnly = false,
    this.maxDistance,
    this.latitude,
    this.longitude,
  });

  VendorFilters copyWith({
    String? searchQuery,
    List<String>? cuisineTypes,
    double? minRating,
    bool? isHalalOnly,
    double? maxDistance,
    double? latitude,
    double? longitude,
  }) {
    return VendorFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      minRating: minRating ?? this.minRating,
      isHalalOnly: isHalalOnly ?? this.isHalalOnly,
      maxDistance: maxDistance ?? this.maxDistance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  bool get hasActiveFilters {
    return (searchQuery?.isNotEmpty ?? false) ||
        cuisineTypes.isNotEmpty ||
        minRating != null ||
        isHalalOnly ||
        maxDistance != null;
  }
}

// Vendors Notifier
class VendorsNotifier extends StateNotifier<VendorsState> {
  final VendorService _vendorService;
  final AppLogger _logger = AppLogger();

  VendorsNotifier(this._vendorService) : super(const VendorsState()) {
    loadVendors();
  }

  Future<void> loadVendors() async {
    _logger.info('🏪 [VENDOR-PROVIDER] Starting to load vendors...');
    _logger.info('🏪 [VENDOR-PROVIDER] Current filters: ${state.filters.toString()}');

    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      _logger.info('🏪 [VENDOR-PROVIDER] Calling vendor service with filters:');
      _logger.info('  - Search query: ${state.filters.searchQuery}');
      _logger.info('  - Cuisine types: ${state.filters.cuisineTypes}');
      _logger.info('  - Min rating: ${state.filters.minRating}');
      _logger.info('  - Halal only: ${state.filters.isHalalOnly}');
      _logger.info('  - Max distance: ${state.filters.maxDistance}');
      _logger.info('  - Location: (${state.filters.latitude}, ${state.filters.longitude})');

      final vendors = await _vendorService.getVendors(
        searchQuery: state.filters.searchQuery,
        cuisineTypes: state.filters.cuisineTypes.isNotEmpty
            ? state.filters.cuisineTypes
            : null,
        minRating: state.filters.minRating,
        isHalalOnly: state.filters.isHalalOnly ? true : null,
        maxDistance: state.filters.maxDistance,
        latitude: state.filters.latitude,
        longitude: state.filters.longitude,
      );

      _logger.info('✅ [VENDOR-PROVIDER] Successfully loaded ${vendors.length} vendors');
      _logger.info('🏪 [VENDOR-PROVIDER] Vendor names: ${vendors.map((v) => v.businessName).join(', ')}');

      state = state.copyWith(
        vendors: vendors,
        isLoading: false,
      );
    } catch (e) {
      _logger.error('❌ [VENDOR-PROVIDER] Error loading vendors', e);
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void updateFilters(VendorFilters filters) {
    state = state.copyWith(filters: filters);
    loadVendors();
  }

  void updateSearchQuery(String query) {
    final newFilters = state.filters.copyWith(searchQuery: query);
    updateFilters(newFilters);
  }

  void toggleCuisineType(String cuisineType) {
    final currentTypes = List<String>.from(state.filters.cuisineTypes);
    
    if (currentTypes.contains(cuisineType)) {
      currentTypes.remove(cuisineType);
    } else {
      currentTypes.add(cuisineType);
    }
    
    final newFilters = state.filters.copyWith(cuisineTypes: currentTypes);
    updateFilters(newFilters);
  }

  void setMinRating(double? rating) {
    final newFilters = state.filters.copyWith(minRating: rating);
    updateFilters(newFilters);
  }

  void toggleHalalOnly() {
    final newFilters = state.filters.copyWith(
      isHalalOnly: !state.filters.isHalalOnly,
    );
    updateFilters(newFilters);
  }

  void setLocation(double latitude, double longitude, {double? maxDistance}) {
    final newFilters = state.filters.copyWith(
      latitude: latitude,
      longitude: longitude,
      maxDistance: maxDistance,
    );
    updateFilters(newFilters);
  }

  void clearFilters() {
    updateFilters(const VendorFilters());
  }

  void refresh() {
    loadVendors();
  }
}
