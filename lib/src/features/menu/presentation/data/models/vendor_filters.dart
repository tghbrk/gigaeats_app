import 'package:equatable/equatable.dart';

/// Vendor filters for searching and filtering vendors
class VendorFilters extends Equatable {
  final String? searchQuery;
  final List<String> categories;
  final double? minRating;
  final double? maxDeliveryFee;
  final int? maxDeliveryTime;
  final bool? isOpen;
  final bool? hasPromotion;
  final bool? acceptsVouchers;
  final String? sortBy;
  final bool? isAscending;
  final double? minOrderValue;
  final double? maxOrderValue;
  final List<String> cuisineTypes;
  final List<String> deliveryMethods;
  final double? latitude;
  final double? longitude;
  final double? radiusKm;

  const VendorFilters({
    this.searchQuery,
    this.categories = const [],
    this.minRating,
    this.maxDeliveryFee,
    this.maxDeliveryTime,
    this.isOpen,
    this.hasPromotion,
    this.acceptsVouchers,
    this.sortBy,
    this.isAscending,
    this.minOrderValue,
    this.maxOrderValue,
    this.cuisineTypes = const [],
    this.deliveryMethods = const [],
    this.latitude,
    this.longitude,
    this.radiusKm,
  });

  /// Create VendorFilters from JSON
  factory VendorFilters.fromJson(Map<String, dynamic> json) {
    return VendorFilters(
      searchQuery: json['search_query'] as String?,
      categories: (json['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      minRating: json['min_rating']?.toDouble(),
      maxDeliveryFee: json['max_delivery_fee']?.toDouble(),
      maxDeliveryTime: json['max_delivery_time'] as int?,
      isOpen: json['is_open'] as bool?,
      hasPromotion: json['has_promotion'] as bool?,
      acceptsVouchers: json['accepts_vouchers'] as bool?,
      sortBy: json['sort_by'] as String?,
      isAscending: json['is_ascending'] as bool?,
      minOrderValue: json['min_order_value']?.toDouble(),
      maxOrderValue: json['max_order_value']?.toDouble(),
      cuisineTypes: (json['cuisine_types'] as List<dynamic>?)?.cast<String>() ?? [],
      deliveryMethods: (json['delivery_methods'] as List<dynamic>?)?.cast<String>() ?? [],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
      radiusKm: json['radius_km']?.toDouble(),
    );
  }

  /// Convert VendorFilters to JSON
  Map<String, dynamic> toJson() {
    return {
      'search_query': searchQuery,
      'categories': categories,
      'min_rating': minRating,
      'max_delivery_fee': maxDeliveryFee,
      'max_delivery_time': maxDeliveryTime,
      'is_open': isOpen,
      'has_promotion': hasPromotion,
      'accepts_vouchers': acceptsVouchers,
      'sort_by': sortBy,
      'is_ascending': isAscending,
      'min_order_value': minOrderValue,
      'max_order_value': maxOrderValue,
      'cuisine_types': cuisineTypes,
      'delivery_methods': deliveryMethods,
      'latitude': latitude,
      'longitude': longitude,
      'radius_km': radiusKm,
    };
  }

  /// Create a copy of VendorFilters with updated fields
  VendorFilters copyWith({
    String? searchQuery,
    List<String>? categories,
    double? minRating,
    double? maxDeliveryFee,
    int? maxDeliveryTime,
    bool? isOpen,
    bool? hasPromotion,
    bool? acceptsVouchers,
    String? sortBy,
    bool? isAscending,
    double? minOrderValue,
    double? maxOrderValue,
    List<String>? cuisineTypes,
    List<String>? deliveryMethods,
    double? latitude,
    double? longitude,
    double? radiusKm,
  }) {
    return VendorFilters(
      searchQuery: searchQuery ?? this.searchQuery,
      categories: categories ?? this.categories,
      minRating: minRating ?? this.minRating,
      maxDeliveryFee: maxDeliveryFee ?? this.maxDeliveryFee,
      maxDeliveryTime: maxDeliveryTime ?? this.maxDeliveryTime,
      isOpen: isOpen ?? this.isOpen,
      hasPromotion: hasPromotion ?? this.hasPromotion,
      acceptsVouchers: acceptsVouchers ?? this.acceptsVouchers,
      sortBy: sortBy ?? this.sortBy,
      isAscending: isAscending ?? this.isAscending,
      minOrderValue: minOrderValue ?? this.minOrderValue,
      maxOrderValue: maxOrderValue ?? this.maxOrderValue,
      cuisineTypes: cuisineTypes ?? this.cuisineTypes,
      deliveryMethods: deliveryMethods ?? this.deliveryMethods,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radiusKm: radiusKm ?? this.radiusKm,
    );
  }

  /// Clear all filters
  VendorFilters clear() {
    return const VendorFilters();
  }

  /// Check if any filters are applied
  bool get hasFilters {
    return searchQuery != null ||
        categories.isNotEmpty ||
        minRating != null ||
        maxDeliveryFee != null ||
        maxDeliveryTime != null ||
        isOpen != null ||
        hasPromotion != null ||
        acceptsVouchers != null ||
        minOrderValue != null ||
        maxOrderValue != null ||
        cuisineTypes.isNotEmpty ||
        deliveryMethods.isNotEmpty ||
        (latitude != null && longitude != null);
  }

  /// Get active filter count
  int get activeFilterCount {
    int count = 0;
    if (searchQuery != null && searchQuery!.isNotEmpty) count++;
    if (categories.isNotEmpty) count++;
    if (minRating != null) count++;
    if (maxDeliveryFee != null) count++;
    if (maxDeliveryTime != null) count++;
    if (isOpen != null) count++;
    if (hasPromotion != null) count++;
    if (acceptsVouchers != null) count++;
    if (minOrderValue != null) count++;
    if (maxOrderValue != null) count++;
    if (cuisineTypes.isNotEmpty) count++;
    if (deliveryMethods.isNotEmpty) count++;
    if (latitude != null && longitude != null) count++;
    return count;
  }

  /// Create default filters
  factory VendorFilters.defaults() {
    return const VendorFilters(
      sortBy: 'rating',
      isAscending: false,
      radiusKm: 10.0,
    );
  }

  /// Create filters for nearby vendors
  factory VendorFilters.nearby({
    required double latitude,
    required double longitude,
    double radiusKm = 5.0,
  }) {
    return VendorFilters(
      latitude: latitude,
      longitude: longitude,
      radiusKm: radiusKm,
      isOpen: true,
      sortBy: 'distance',
      isAscending: true,
    );
  }

  /// Create filters for popular vendors
  factory VendorFilters.popular() {
    return const VendorFilters(
      minRating: 4.0,
      sortBy: 'rating',
      isAscending: false,
      isOpen: true,
    );
  }

  /// Create filters for fast delivery
  factory VendorFilters.fastDelivery() {
    return const VendorFilters(
      maxDeliveryTime: 30,
      sortBy: 'delivery_time',
      isAscending: true,
      isOpen: true,
    );
  }

  /// Create filters for promotions
  factory VendorFilters.withPromotions() {
    return const VendorFilters(
      hasPromotion: true,
      sortBy: 'rating',
      isAscending: false,
      isOpen: true,
    );
  }

  @override
  List<Object?> get props => [
        searchQuery,
        categories,
        minRating,
        maxDeliveryFee,
        maxDeliveryTime,
        isOpen,
        hasPromotion,
        acceptsVouchers,
        sortBy,
        isAscending,
        minOrderValue,
        maxOrderValue,
        cuisineTypes,
        deliveryMethods,
        latitude,
        longitude,
        radiusKm,
      ];
}
