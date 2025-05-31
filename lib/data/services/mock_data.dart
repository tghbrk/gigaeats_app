import '../models/customer.dart';
import '../models/vendor.dart';
import '../models/product.dart';
import '../models/user_role.dart';

/// Mock data service for development and testing
class MockData {
  // Sample customers for testing
  static final List<Customer> sampleCustomers = [
    Customer(
      id: 'cust_001',
      salesAgentId: 'agent_001',
      type: CustomerType.corporate,
      organizationName: 'Tech Solutions Sdn Bhd',
      contactPersonName: 'Ahmad Rahman',
      email: 'ahmad@techsolutions.com.my',
      phoneNumber: '+60123456789',
      address: const CustomerAddress(
        street: 'Level 15, Menara TM, Jalan Pantai Baharu',
        city: 'Kuala Lumpur',
        state: 'Kuala Lumpur',
        postcode: '59200',
      ),
      preferences: const CustomerPreferences(
        preferredCuisines: ['Malaysian', 'Chinese'],
        dietaryRestrictions: ['Halal'],
        spiceToleranceLevel: 3,
      ),
      lastOrderDate: DateTime.now().subtract(const Duration(days: 2)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Customer(
      id: 'cust_002',
      salesAgentId: 'agent_001',
      type: CustomerType.corporate,
      organizationName: 'Digital Marketing Hub',
      contactPersonName: 'Siti Nurhaliza',
      email: 'siti@dmhub.com.my',
      phoneNumber: '+60198765432',
      address: const CustomerAddress(
        street: 'Unit 12-3, Plaza Mont Kiara',
        city: 'Kuala Lumpur',
        state: 'Kuala Lumpur',
        postcode: '50480',
      ),
      preferences: const CustomerPreferences(
        preferredCuisines: ['Western', 'Japanese'],
        dietaryRestrictions: ['Vegetarian'],
        spiceToleranceLevel: 1,
      ),
      lastOrderDate: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
    Customer(
      id: 'cust_003',
      salesAgentId: 'agent_001',
      type: CustomerType.corporate,
      organizationName: 'Personal Order',
      contactPersonName: 'Raj Kumar',
      email: 'raj.kumar@gmail.com',
      phoneNumber: '+60176543210',
      address: const CustomerAddress(
        street: '23, Jalan SS2/24, SS2',
        city: 'Petaling Jaya',
        state: 'Selangor',
        postcode: '47300',
      ),
      preferences: const CustomerPreferences(
        preferredCuisines: ['Indian', 'Malaysian'],
        dietaryRestrictions: ['Vegetarian'],
        spiceToleranceLevel: 5,
      ),
      lastOrderDate: DateTime.now().subtract(const Duration(days: 1)),
      createdAt: DateTime.now().subtract(const Duration(days: 15)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  // Sample vendors for testing
  static final List<Vendor> sampleVendors = [
    Vendor(
      id: 'vendor_001',
      businessName: 'Nasi Lemak Wangi',
      businessRegistrationNumber: 'SSM123456789',
      businessAddress: '45, Jalan Alor, 50200 Kuala Lumpur, Kuala Lumpur, Malaysia',
      businessType: 'restaurant',
      cuisineTypes: const ['Malaysian', 'Local'],
      isHalalCertified: true,
      halalCertificationNumber: 'HALAL001',
      description: 'Authentic Malaysian cuisine with traditional recipes',
      rating: 4.5,
      totalReviews: 128,
      totalOrders: 456,
      isActive: true,
      isVerified: true,
      minimumOrderAmount: 50.0,
      deliveryFee: 5.0,
      freeDeliveryThreshold: 100.0,
      createdAt: DateTime.now().subtract(const Duration(days: 180)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Vendor(
      id: 'vendor_002',
      businessName: 'Western Delights',
      businessRegistrationNumber: 'SSM987654321',
      businessAddress: '12, Jalan Bangsar, 59100 Kuala Lumpur, Kuala Lumpur, Malaysia',
      businessType: 'restaurant',
      cuisineTypes: const ['Western', 'Continental'],
      isHalalCertified: false,
      description: 'Premium Western cuisine for corporate events',
      rating: 4.2,
      totalReviews: 89,
      totalOrders: 234,
      isActive: true,
      isVerified: true,
      minimumOrderAmount: 80.0,
      deliveryFee: 8.0,
      freeDeliveryThreshold: 150.0,
      createdAt: DateTime.now().subtract(const Duration(days: 120)),
      updatedAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
  ];

  // Sample products for testing
  static final List<Product> sampleProducts = [
    Product(
      id: 'prod_001',
      vendorId: 'vendor_001',
      name: 'Nasi Lemak Set',
      description: 'Traditional Malaysian coconut rice with sambal, anchovies, peanuts, and egg',
      category: 'Malaysian',
      basePrice: 12.0,
      isAvailable: true,
      isHalal: true,
      preparationTimeMinutes: 30,
      minOrderQuantity: 10,
      currency: 'MYR',
      includesSst: true,
      tags: const ['Malaysian', 'Traditional', 'Halal'],
      allergens: const ['Nuts'],
      createdAt: DateTime.now().subtract(const Duration(days: 60)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    Product(
      id: 'prod_002',
      vendorId: 'vendor_001',
      name: 'Chicken Rice Set',
      description: 'Hainanese chicken rice with soup and vegetables',
      category: 'Malaysian',
      basePrice: 10.0,
      isAvailable: true,
      isHalal: true,
      preparationTimeMinutes: 25,
      minOrderQuantity: 15,
      currency: 'MYR',
      includesSst: true,
      tags: const ['Malaysian', 'Chicken', 'Halal'],
      allergens: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 45)),
      updatedAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    Product(
      id: 'prod_003',
      vendorId: 'vendor_002',
      name: 'Grilled Chicken Salad',
      description: 'Fresh mixed greens with grilled chicken breast',
      category: 'Western',
      basePrice: 18.0,
      isAvailable: true,
      isHalal: false,
      preparationTimeMinutes: 20,
      minOrderQuantity: 5,
      currency: 'MYR',
      includesSst: true,
      tags: const ['Western', 'Healthy', 'Salad'],
      allergens: const [],
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
      updatedAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
  ];

  /// Get products for a specific vendor
  static List<Product> getProductsForVendor(String vendorId) {
    return sampleProducts.where((product) => product.vendorId == vendorId).toList();
  }

  /// Get vendor by ID
  static Vendor? getVendorById(String vendorId) {
    try {
      return sampleVendors.firstWhere((vendor) => vendor.id == vendorId);
    } catch (e) {
      return null;
    }
  }

  /// Get customer by ID
  static Customer? getCustomerById(String customerId) {
    try {
      return sampleCustomers.firstWhere((customer) => customer.id == customerId);
    } catch (e) {
      return null;
    }
  }

  /// Get product by ID
  static Product? getProductById(String productId) {
    try {
      return sampleProducts.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }
}
