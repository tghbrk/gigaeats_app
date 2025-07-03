// Export the unified vendor models from the correct location
export '../../../user_management/domain/vendor.dart';

// Re-export commonly used types for convenience
export '../../../user_management/domain/vendor.dart' show Vendor;

// Compatibility layer for old Vendor model usage
import '../../../user_management/domain/vendor.dart' as unified;

// Create compatibility enums
enum VendorStatus {
  active,
  inactive,
  suspended,
  pendingVerification,
}

enum BusinessType {
  restaurant,
  cafe,
  foodTruck,
  catering,
  bakery,
  grocery,
  other,
}

enum CuisineType {
  malay,
  chinese,
  indian,
  western,
  japanese,
  korean,
  thai,
  italian,
  middleEastern,
  fusion,
  vegetarian,
  halal,
  other,
}

// Extension to add compatibility methods to the unified Vendor model
extension VendorCompatibility on unified.Vendor {
  // Compatibility getters for old model structure
  String get name => businessName;
  VendorStatus get status => isActive ? VendorStatus.active : VendorStatus.inactive;
}