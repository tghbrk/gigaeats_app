import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'vendor_filters.g.dart';

/// Vendor filters for searching and filtering vendors
@JsonSerializable()
class VendorFilters extends Equatable {
  /// Search query for vendor name or cuisine type
  final String? searchQuery;
  
  /// Filter by cuisine types
  final List<String>? cuisineTypes;
  
  /// Filter by delivery methods
  final List<String>? deliveryMethods;
  
  /// Filter by rating (minimum rating)
  final double? minRating;
  
  /// Filter by price range
  final PriceRange? priceRange;
  
  /// Filter by distance (in kilometers)
  final double? maxDistance;
  
  /// Filter by vendor status
  final bool? isOpen;
  
  /// Filter by halal certification
  final bool? isHalalCertified;
  
  /// Sort options
  final VendorSortOption? sortBy;
  
  /// Sort order (ascending/descending)
  final bool sortAscending;
  
  /// Location for distance-based filtering
  final LocationFilter? location;

  const VendorFilters({
    this.searchQuery,
    this.cuisineTypes,
    this.deliveryMethods,
    this.minRating,
    this.priceRange,
    this.maxDistance,
    this.isOpen,
    this.isHalalCertified,
    this.sortBy,
    this.sortAscending = true,
    this.location,
  });

  /// Create empty filters
  const VendorFilters.empty()
      : searchQuery = null,
        cuisineTypes = null,
        deliveryMethods = null,
        minRating = null,
        priceRange = null,
        maxDistance = null,
        isOpen = null,
        isHalalCertified = null,
        sortBy = null,
        sortAscending = true,
        location = null;

  /// Create filters with search query only
  const VendorFilters.search(String query)
      : searchQuery = query,
        cuisineTypes = null,
        deliveryMethods = null,
        minRating = null,
        priceRange = null,
        maxDistance = null,
        isOpen = null,
        isHalalCertified = null,
        sortBy = null,
        sortAscending = true,
        location = null;

  factory VendorFilters.fromJson(Map<String, dynamic> json) =>
      _$VendorFiltersFromJson(json);

  Map<String, dynamic> toJson() => _$VendorFiltersToJson(this);

  VendorFilters copyWith({
    String? searchQuery,
    List<String>? cuisineTypes,
    List<String>? deliveryMethods,
    double? minRating,
    PriceRange? priceRange,
    double? maxDistance,
    bool? isOpen,
    bool? isHalalCertified,
    VendorSortOption? sortBy,
    bool? sortAscending,
    LocationFilter? location,
  }) {
    return VendorFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      deliveryMethods: deliveryMethods ?? this.deliveryMethods,
      minRating: minRating ?? this.minRating,
      priceRange: priceRange ?? this.priceRange,
      maxDistance: maxDistance ?? this.maxDistance,
      isOpen: isOpen ?? this.isOpen,
      isHalalCertified: isHalalCertified ?? this.isHalalCertified,
      sortBy: sortBy ?? this.sortBy,
      sortAscending: sortAscending ?? this.sortAscending,
      location: location ?? this.location,
    );
  }

  /// Check if filters are empty
  bool get isEmpty {
    return searchQuery == null &&
        (cuisineTypes == null || cuisineTypes!.isEmpty) &&
        (deliveryMethods == null || deliveryMethods!.isEmpty) &&
        minRating == null &&
        priceRange == null &&
        maxDistance == null &&
        isOpen == null &&
        isHalalCertified == null &&
        sortBy == null &&
        location == null;
  }

  /// Check if filters have any active filters
  bool get hasActiveFilters => !isEmpty;

  @override
  List<Object?> get props => [
        searchQuery,
        cuisineTypes,
        deliveryMethods,
        minRating,
        priceRange,
        maxDistance,
        isOpen,
        isHalalCertified,
        sortBy,
        sortAscending,
        location,
      ];
}

/// Price range filter
@JsonSerializable()
class PriceRange extends Equatable {
  final double? minPrice;
  final double? maxPrice;

  const PriceRange({
    this.minPrice,
    this.maxPrice,
  });

  factory PriceRange.fromJson(Map<String, dynamic> json) =>
      _$PriceRangeFromJson(json);

  Map<String, dynamic> toJson() => _$PriceRangeToJson(this);

  @override
  List<Object?> get props => [minPrice, maxPrice];
}

/// Location filter for distance-based filtering
@JsonSerializable()
class LocationFilter extends Equatable {
  final double latitude;
  final double longitude;
  final String? address;

  const LocationFilter({
    required this.latitude,
    required this.longitude,
    this.address,
  });

  factory LocationFilter.fromJson(Map<String, dynamic> json) =>
      _$LocationFilterFromJson(json);

  Map<String, dynamic> toJson() => _$LocationFilterToJson(this);

  @override
  List<Object?> get props => [latitude, longitude, address];
}

/// Vendor sort options
enum VendorSortOption {
  @JsonValue('name')
  name,
  @JsonValue('rating')
  rating,
  @JsonValue('distance')
  distance,
  @JsonValue('delivery_time')
  deliveryTime,
  @JsonValue('price')
  price,
  @JsonValue('popularity')
  popularity,
}

/// Extension for VendorSortOption
extension VendorSortOptionExtension on VendorSortOption {
  String get displayName {
    switch (this) {
      case VendorSortOption.name:
        return 'Name';
      case VendorSortOption.rating:
        return 'Rating';
      case VendorSortOption.distance:
        return 'Distance';
      case VendorSortOption.deliveryTime:
        return 'Delivery Time';
      case VendorSortOption.price:
        return 'Price';
      case VendorSortOption.popularity:
        return 'Popularity';
    }
  }

  String get value {
    switch (this) {
      case VendorSortOption.name:
        return 'name';
      case VendorSortOption.rating:
        return 'rating';
      case VendorSortOption.distance:
        return 'distance';
      case VendorSortOption.deliveryTime:
        return 'delivery_time';
      case VendorSortOption.price:
        return 'price';
      case VendorSortOption.popularity:
        return 'popularity';
    }
  }
}
