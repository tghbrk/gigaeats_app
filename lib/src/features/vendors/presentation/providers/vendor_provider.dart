import 'package:flutter_riverpod/flutter_riverpod.dart';

// Import models
import '../../data/models/vendor.dart';

// Import repository providers
import '../../../presentation/providers/repository_providers.dart';

// Import core utilities
import '../../../../core/utils/logger.dart';

/// Vendor state model
class VendorState {
  final List<Vendor> vendors;
  final bool isLoading;
  final String? errorMessage;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;
  final List<CuisineType> selectedCuisines;
  final bool onlyOpenVendors;

  const VendorState({
    this.vendors = const [],
    this.isLoading = false,
    this.errorMessage,
    this.hasMore = true,
    this.currentPage = 1,
    this.searchQuery = '',
    this.selectedCuisines = const [],
    this.onlyOpenVendors = false,
  });

  VendorState copyWith({
    List<Vendor>? vendors,
    bool? isLoading,
    String? errorMessage,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
    List<CuisineType>? selectedCuisines,
    bool? onlyOpenVendors,
  }) {
    return VendorState(
      vendors: vendors ?? this.vendors,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCuisines: selectedCuisines ?? this.selectedCuisines,
      onlyOpenVendors: onlyOpenVendors ?? this.onlyOpenVendors,
    );
  }

  /// Get filtered vendors based on current filters
  List<Vendor> get filteredVendors {
    var filtered = vendors.where((vendor) {
      // Search query filter
      if (searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        if (!vendor.businessName.toLowerCase().contains(query) &&
            !(vendor.description?.toLowerCase().contains(query) ?? false) &&
            // TODO: Restore when cuisine.name is available
            // !vendor.cuisineTypes.any((cuisine) => cuisine.name.toLowerCase().contains(query))) {
            !vendor.cuisineTypes.any((cuisine) => cuisine.toString().toLowerCase().contains(query))) {
          return false;
        }
      }

      // Cuisine filter
      if (selectedCuisines.isNotEmpty) {
        // TODO: Restore original cuisine type comparison when CuisineType enum is properly defined
        // Original: if (!vendor.cuisineTypes.any((cuisine) => selectedCuisines.contains(cuisine.toString()))) {
        if (!vendor.cuisineTypes.any((cuisine) => selectedCuisines.any((selected) => selected.toString() == cuisine.toString()))) {
          return false;
        }
      }

      // Open vendors filter
      // TODO: Restore when isCurrentlyOpen is available
      // if (onlyOpenVendors && !vendor.isCurrentlyOpen) {
      // TODO: Restore dead code - commented out for analyzer cleanup
      // if (onlyOpenVendors && false) { // Placeholder - assume closed
      //   return false;
      // }

      return true;
    }).toList();

    // Sort by rating and status
    filtered.sort((a, b) {
      // Active vendors first
      if (a.isActive != b.isActive) {
        return a.isActive ? -1 : 1;
      }
      // Then by rating
      // TODO: Restore when stats.rating is available
      // return b.stats.rating.compareTo(a.stats.rating);
      return 0; // Placeholder - no sorting by rating
    });

    return filtered;
  }
}

/// Vendor Provider Notifier
class VendorNotifier extends StateNotifier<VendorState> {
  final Ref ref;
  final AppLogger _logger = AppLogger();

  VendorNotifier(this.ref) : super(const VendorState());

  /// Load vendors
  Future<void> loadVendors({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        vendors: [],
        currentPage: 1,
        hasMore: true,
        errorMessage: null,
      );
    }

    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    _logger.info('🏪 [VENDOR-PROVIDER] Loading vendors (page: ${state.currentPage})');

    try {
      final repository = ref.read(vendorRepositoryProvider);
      final newVendors = await repository.getActiveVendors();

      final allVendors = refresh ? newVendors : [...state.vendors, ...newVendors];
      
      state = state.copyWith(
        vendors: allVendors,
        isLoading: false,
        hasMore: newVendors.length >= 20, // Assuming page size of 20
        currentPage: state.currentPage + 1,
      );

      _logger.info('✅ [VENDOR-PROVIDER] Loaded ${newVendors.length} vendors. Total: ${allVendors.length}');
    } catch (e) {
      _logger.error('❌ [VENDOR-PROVIDER] Failed to load vendors: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load vendors: ${e.toString()}',
      );
    }
  }

  /// Search vendors
  void searchVendors(String query) {
    _logger.info('🔍 [VENDOR-PROVIDER] Searching vendors: $query');
    state = state.copyWith(searchQuery: query);
  }

  /// Filter by cuisine types
  void filterByCuisines(List<CuisineType> cuisines) {
    _logger.info('🍽️ [VENDOR-PROVIDER] Filtering by cuisines: ${cuisines.map((c) => c.name).join(', ')}');
    state = state.copyWith(selectedCuisines: cuisines);
  }

  /// Toggle cuisine filter
  void toggleCuisineFilter(CuisineType cuisine) {
    final currentCuisines = List<CuisineType>.from(state.selectedCuisines);
    if (currentCuisines.contains(cuisine)) {
      currentCuisines.remove(cuisine);
    } else {
      currentCuisines.add(cuisine);
    }
    state = state.copyWith(selectedCuisines: currentCuisines);
  }

  /// Toggle open vendors only filter
  void toggleOpenVendorsOnly() {
    state = state.copyWith(onlyOpenVendors: !state.onlyOpenVendors);
  }

  /// Clear all filters
  void clearFilters() {
    _logger.info('🧹 [VENDOR-PROVIDER] Clearing all filters');
    state = state.copyWith(
      searchQuery: '',
      selectedCuisines: [],
      onlyOpenVendors: false,
    );
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Refresh vendors
  Future<void> refresh() async {
    await loadVendors(refresh: true);
  }

  /// Update vendor status
  Future<bool> updateVendorStatus(String vendorId, VendorStatus newStatus) async {
    _logger.info('🔄 [VENDOR-PROVIDER] Updating vendor $vendorId status to ${newStatus.name}');

    try {
      final repository = ref.read(vendorRepositoryProvider);
      await repository.updateVendorStatus(vendorId, newStatus);

      // Update local state
      final updatedVendors = state.vendors.map((vendor) {
        if (vendor.id == vendorId) {
          // TODO: Restore status parameter when copyWith supports it - commented out for analyzer cleanup
          return vendor; // vendor.copyWith(status: newStatus);
        }
        return vendor;
      }).toList();

      state = state.copyWith(vendors: updatedVendors);
      _logger.info('✅ [VENDOR-PROVIDER] Vendor status updated successfully');
      return true;
    } catch (e) {
      _logger.error('❌ [VENDOR-PROVIDER] Failed to update vendor status: $e');
      state = state.copyWith(errorMessage: 'Failed to update vendor status: ${e.toString()}');
      return false;
    }
  }
}

/// Vendor Provider
final vendorProvider = StateNotifierProvider<VendorNotifier, VendorState>((ref) {
  return VendorNotifier(ref);
});

/// Single Vendor Provider
final singleVendorProvider = FutureProvider.family<Vendor?, String>((ref, vendorId) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getVendorById(vendorId);
});

/// Vendor Details Provider (alias for singleVendorProvider for compatibility)
final vendorDetailsProvider = singleVendorProvider;

/// Vendor Stream Provider for real-time updates
final vendorStreamProvider = StreamProvider.family<Map<String, dynamic>?, String>((ref, vendorId) {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.watchVendorStatus(vendorId);
});

/// Available Vendors Provider
final availableVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getActiveVendors();
});

/// Vendors by Cuisine Provider
final vendorsByCuisineProvider = FutureProvider.family<List<Vendor>, CuisineType>((ref, cuisine) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getVendorsByCuisine(cuisine);
});

/// Nearby Vendors Provider
final nearbyVendorsProvider = FutureProvider.family<List<Vendor>, ({double latitude, double longitude, double radiusKm})>((ref, params) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getNearbyVendors(
    params.latitude,
    params.longitude,
    params.radiusKm,
  );
});

/// Top Rated Vendors Provider
final topRatedVendorsProvider = FutureProvider.family<List<Vendor>, int>((ref, limit) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getTopRatedVendors(limit);
});

/// Featured Vendors Provider
final featuredVendorsProvider = FutureProvider<List<Vendor>>((ref) async {
  final repository = ref.watch(vendorRepositoryProvider);
  return repository.getFeaturedVendors();
});

/// Vendor Statistics Provider
// TODO: Restore when VendorStats is implemented
final vendorStatsProvider = FutureProvider.family<dynamic, String>((ref, vendorId) async {
  // TODO: Use repository when vendor operations are restored
  // final repository = ref.watch(vendorRepositoryProvider);
  // TODO: Use vendor when vendor operations are restored
  // final vendor = await repository.getVendorById(vendorId);
  // return vendor?.stats ?? const VendorStats();
  return null; // Placeholder for undefined stats
});

/// Cuisine Types Provider
final cuisineTypesProvider = Provider<List<CuisineType>>((ref) {
  return CuisineType.values;
});

/// Available Cuisine Types Provider (from active vendors)
final availableCuisineTypesProvider = FutureProvider<List<CuisineType>>((ref) async {
  // TODO: Restore vendors when cuisineTypes iteration is fixed - commented out for analyzer cleanup
  // final vendors = await ref.watch(availableVendorsProvider.future);
  final cuisines = <CuisineType>{};

  // TODO: Restore vendor iteration when cuisineTypes is fixed - commented out for analyzer cleanup
  // for (final vendor in vendors) {
  //   cuisines.addAll(vendor.cuisineTypes);
  // }
  
  return cuisines.toList()..sort((a, b) => a.name.compareTo(b.name));
});

/// Business Types Provider
final businessTypesProvider = Provider<List<BusinessType>>((ref) {
  return BusinessType.values;
});

/// Vendor Search Suggestions Provider
final vendorSearchSuggestionsProvider = FutureProvider.family<List<String>, String>((ref, query) async {
  if (query.length < 2) return [];
  
  final vendors = await ref.watch(availableVendorsProvider.future);
  final suggestions = <String>{};
  
  final lowerQuery = query.toLowerCase();
  
  for (final vendor in vendors) {
    // Add business name if it matches
    if (vendor.businessName.toLowerCase().contains(lowerQuery)) {
      suggestions.add(vendor.businessName);
    }
    
    // Add cuisine types if they match
    // TODO: Restore when cuisineTypes are CuisineType objects instead of Strings - commented out for analyzer cleanup
    // for (final cuisine in vendor.cuisineTypes) {
    //   if (cuisine.name.toLowerCase().contains(lowerQuery)) {
    //     suggestions.add(cuisine.name);
    //   }
    // }
    for (final cuisine in vendor.cuisineTypes) {
      if (cuisine.toLowerCase().contains(lowerQuery)) {
        suggestions.add(cuisine);
      }
    }
  }
  
  return suggestions.take(10).toList();
});

/// Vendor Delivery Areas Provider
// TODO: Restore ServiceArea type - commented out for analyzer cleanup
final vendorDeliveryAreasProvider = FutureProvider.family<List<dynamic>, String>((ref, vendorId) async {
  final repository = ref.watch(vendorRepositoryProvider);
  final vendor = await repository.getVendorById(vendorId);
  return vendor?.serviceAreas ?? [];
});

/// Can Deliver To Provider
final canDeliverToProvider = FutureProvider.family<bool, ({String vendorId, String postalCode})>((ref, params) async {
  // TODO: Restore vendor access when deliversToPostalCode method exists - commented out for analyzer cleanup
  // final vendor = await ref.watch(singleVendorProvider(params.vendorId).future);
  return false; // vendor?.deliversToPostalCode(params.postalCode) ?? false;
});

/// Delivery Fee Provider
final deliveryFeeProvider = FutureProvider.family<double?, ({String vendorId, String postalCode})>((ref, params) async {
  // TODO: Restore vendor access when getDeliveryFeeForPostalCode method exists - commented out for analyzer cleanup
  // final vendor = await ref.watch(singleVendorProvider(params.vendorId).future);
  return null; // vendor?.getDeliveryFeeForPostalCode(params.postalCode);
});

/// Minimum Order Provider
final minimumOrderProvider = FutureProvider.family<double?, ({String vendorId, String postalCode})>((ref, params) async {
  // TODO: Restore vendor access when getMinimumOrderForPostalCode method exists - commented out for analyzer cleanup
  // final vendor = await ref.watch(singleVendorProvider(params.vendorId).future);
  return null; // vendor?.getMinimumOrderForPostalCode(params.postalCode);
});
