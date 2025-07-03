import 'package:equatable/equatable.dart';

/// Vendor entity representing the core vendor data
class VendorEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final String address;
  final String city;
  final String state;
  final String postalCode;
  final String phoneNumber;
  final String email;
  final VendorStatusEntity status;
  final VendorCategoryEntity category;
  final double rating;
  final int totalReviews;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> imageUrls;
  final Map<String, dynamic>? businessHours;
  final double? deliveryFee;
  final double? minimumOrder;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const VendorEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.address,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.phoneNumber,
    required this.email,
    required this.status,
    required this.category,
    required this.rating,
    required this.totalReviews,
    this.logoUrl,
    this.bannerUrl,
    required this.imageUrls,
    this.businessHours,
    this.deliveryFee,
    this.minimumOrder,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Create a copy of the vendor entity with updated fields
  VendorEntity copyWith({
    String? id,
    String? name,
    String? description,
    String? address,
    String? city,
    String? state,
    String? postalCode,
    String? phoneNumber,
    String? email,
    VendorStatusEntity? status,
    VendorCategoryEntity? category,
    double? rating,
    int? totalReviews,
    String? logoUrl,
    String? bannerUrl,
    List<String>? imageUrls,
    Map<String, dynamic>? businessHours,
    double? deliveryFee,
    double? minimumOrder,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VendorEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      status: status ?? this.status,
      category: category ?? this.category,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      imageUrls: imageUrls ?? this.imageUrls,
      businessHours: businessHours ?? this.businessHours,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minimumOrder: minimumOrder ?? this.minimumOrder,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        address,
        city,
        state,
        postalCode,
        phoneNumber,
        email,
        status,
        category,
        rating,
        totalReviews,
        logoUrl,
        bannerUrl,
        imageUrls,
        businessHours,
        deliveryFee,
        minimumOrder,
        isActive,
        createdAt,
        updatedAt,
      ];

  @override
  String toString() {
    return 'VendorEntity(id: $id, name: $name, status: $status, category: $category)';
  }
}

/// Vendor status entity
enum VendorStatusEntity {
  pending,
  approved,
  rejected,
  suspended,
  inactive;

  /// Get display name for the status
  String get displayName {
    switch (this) {
      case VendorStatusEntity.pending:
        return 'Pending Approval';
      case VendorStatusEntity.approved:
        return 'Approved';
      case VendorStatusEntity.rejected:
        return 'Rejected';
      case VendorStatusEntity.suspended:
        return 'Suspended';
      case VendorStatusEntity.inactive:
        return 'Inactive';
    }
  }

  /// Get status value as string
  String get value {
    switch (this) {
      case VendorStatusEntity.pending:
        return 'pending';
      case VendorStatusEntity.approved:
        return 'approved';
      case VendorStatusEntity.rejected:
        return 'rejected';
      case VendorStatusEntity.suspended:
        return 'suspended';
      case VendorStatusEntity.inactive:
        return 'inactive';
    }
  }

  /// Create status from string value
  static VendorStatusEntity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'pending':
        return VendorStatusEntity.pending;
      case 'approved':
        return VendorStatusEntity.approved;
      case 'rejected':
        return VendorStatusEntity.rejected;
      case 'suspended':
        return VendorStatusEntity.suspended;
      case 'inactive':
        return VendorStatusEntity.inactive;
      default:
        throw ArgumentError('Invalid vendor status: $value');
    }
  }

  /// Check if vendor can accept orders
  bool get canAcceptOrders {
    return this == VendorStatusEntity.approved;
  }

  /// Check if vendor is visible to customers
  bool get isVisible {
    return this == VendorStatusEntity.approved;
  }
}

/// Vendor category entity
enum VendorCategoryEntity {
  restaurant,
  fastFood,
  cafe,
  bakery,
  grocery,
  pharmacy,
  electronics,
  clothing,
  books,
  other;

  /// Get display name for the category
  String get displayName {
    switch (this) {
      case VendorCategoryEntity.restaurant:
        return 'Restaurant';
      case VendorCategoryEntity.fastFood:
        return 'Fast Food';
      case VendorCategoryEntity.cafe:
        return 'Café';
      case VendorCategoryEntity.bakery:
        return 'Bakery';
      case VendorCategoryEntity.grocery:
        return 'Grocery';
      case VendorCategoryEntity.pharmacy:
        return 'Pharmacy';
      case VendorCategoryEntity.electronics:
        return 'Electronics';
      case VendorCategoryEntity.clothing:
        return 'Clothing';
      case VendorCategoryEntity.books:
        return 'Books';
      case VendorCategoryEntity.other:
        return 'Other';
    }
  }

  /// Get category value as string
  String get value {
    switch (this) {
      case VendorCategoryEntity.restaurant:
        return 'restaurant';
      case VendorCategoryEntity.fastFood:
        return 'fast_food';
      case VendorCategoryEntity.cafe:
        return 'cafe';
      case VendorCategoryEntity.bakery:
        return 'bakery';
      case VendorCategoryEntity.grocery:
        return 'grocery';
      case VendorCategoryEntity.pharmacy:
        return 'pharmacy';
      case VendorCategoryEntity.electronics:
        return 'electronics';
      case VendorCategoryEntity.clothing:
        return 'clothing';
      case VendorCategoryEntity.books:
        return 'books';
      case VendorCategoryEntity.other:
        return 'other';
    }
  }

  /// Create category from string value
  static VendorCategoryEntity fromString(String value) {
    switch (value.toLowerCase()) {
      case 'restaurant':
        return VendorCategoryEntity.restaurant;
      case 'fast_food':
      case 'fastfood':
        return VendorCategoryEntity.fastFood;
      case 'cafe':
      case 'café':
        return VendorCategoryEntity.cafe;
      case 'bakery':
        return VendorCategoryEntity.bakery;
      case 'grocery':
        return VendorCategoryEntity.grocery;
      case 'pharmacy':
        return VendorCategoryEntity.pharmacy;
      case 'electronics':
        return VendorCategoryEntity.electronics;
      case 'clothing':
        return VendorCategoryEntity.clothing;
      case 'books':
        return VendorCategoryEntity.books;
      case 'other':
        return VendorCategoryEntity.other;
      default:
        throw ArgumentError('Invalid vendor category: $value');
    }
  }
}

/// Vendor analytics entity
class VendorAnalyticsEntity extends Equatable {
  final String vendorId;
  final int totalOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int totalCustomers;
  final double customerRetentionRate;
  final Map<String, int> ordersByDay;
  final Map<String, double> revenueByDay;
  final List<String> topSellingItems;
  final DateTime periodStart;
  final DateTime periodEnd;

  const VendorAnalyticsEntity({
    required this.vendorId,
    required this.totalOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalCustomers,
    required this.customerRetentionRate,
    required this.ordersByDay,
    required this.revenueByDay,
    required this.topSellingItems,
    required this.periodStart,
    required this.periodEnd,
  });

  @override
  List<Object?> get props => [
        vendorId,
        totalOrders,
        totalRevenue,
        averageOrderValue,
        totalCustomers,
        customerRetentionRate,
        ordersByDay,
        revenueByDay,
        topSellingItems,
        periodStart,
        periodEnd,
      ];

  @override
  String toString() {
    return 'VendorAnalyticsEntity(vendorId: $vendorId, totalOrders: $totalOrders, totalRevenue: $totalRevenue)';
  }
}
