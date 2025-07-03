// Export the unified customer models from the correct location
export '../../../user_management/domain/customer.dart' show Customer, CustomerType, CustomerPreferences, CustomerBusinessInfo;
export '../../../user_management/domain/customer_profile.dart' show CustomerProfile;

// Use CustomerAddress from customer.dart only to avoid ambiguous export
export '../../../user_management/domain/customer.dart' show CustomerAddress;

// Compatibility layer for old Customer model usage
import '../../../user_management/domain/customer.dart' as unified;

// Create compatibility enums and classes
enum CustomerStatus {
  active,
  inactive,
  suspended,
  pendingVerification,
}

class CustomerStats {
  final int totalOrders;
  final double totalSpent;
  final double averageOrderValue;
  final DateTime? lastOrderDate;
  final String? favoriteVendorId;
  final String? favoriteCuisineType;

  const CustomerStats({
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.averageOrderValue = 0.0,
    this.lastOrderDate,
    this.favoriteVendorId,
    this.favoriteCuisineType,
  });
}

// Extension to add compatibility methods to the unified Customer model
extension CustomerCompatibility on unified.Customer {
  // Compatibility getters for old model structure
  String get name => contactPersonName;
  String? get companyName => organizationName;
  CustomerStatus get status => isActive ? CustomerStatus.active : CustomerStatus.inactive;

  CustomerStats get stats => CustomerStats(
    totalOrders: totalOrders,
    totalSpent: totalSpent,
    averageOrderValue: averageOrderValue,
    lastOrderDate: lastOrderDate,
  );
}
