import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/product.dart';
import '../../../data/models/vendor.dart';
import '../../providers/cart_provider.dart';

class TestCartHelper {
  static void addTestItemsToCart(WidgetRef ref) {
    print('🛒 TestCartHelper: Adding test items to cart...');
    final cartNotifier = ref.read(cartProvider.notifier);

    // Create test vendor using a real UUID from the database
    final testVendor = Vendor(
      id: '550e8400-e29b-41d4-a716-446655440101', // Nasi Lemak Delicious vendor
      businessName: 'Nasi Lemak Delicious',
      userId: 'test_user_id',
      businessRegistrationNumber: 'SSM123456789',
      businessAddress: '123 Test Street, Kuala Lumpur, Selangor',
      businessType: 'Restaurant',
      cuisineTypes: ['Malaysian', 'Chinese'],
      isHalalCertified: true,
      description: 'A test restaurant for demo purposes',
      rating: 4.5,
      totalReviews: 150,
      isActive: true,
      isVerified: true,
      serviceAreas: ['Kuala Lumpur', 'Selangor'],
      minimumOrderAmount: 20.0,
      deliveryFee: 5.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Create test products
    final testProducts = [
      Product(
        id: '550e8400-e29b-41d4-a716-446655440201', // Test product UUID
        vendorId: testVendor.id,
        name: 'Nasi Lemak',
        description: 'Traditional Malaysian coconut rice with sambal, anchovies, peanuts, and egg',
        category: 'Rice Dishes',
        basePrice: 12.50,
        bulkPrice: 11.00,
        bulkMinQuantity: 5,
        isAvailable: true,
        minOrderQuantity: 1,
        maxOrderQuantity: 10,
        imageUrl: 'https://example.com/nasi-lemak.jpg',
        galleryImages: const [],
        isHalal: true,
        isVegetarian: false,
        isSpicy: true,
        spicyLevel: 2,
        isFeatured: true,
        tags: const ['Malaysian', 'Rice', 'Spicy'],
        nutritionInfo: const {},
        allergens: const [],
        preparationTimeMinutes: 20,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '550e8400-e29b-41d4-a716-446655440202', // Test product UUID
        vendorId: testVendor.id,
        name: 'Char Kway Teow',
        description: 'Stir-fried rice noodles with prawns, Chinese sausage, and bean sprouts',
        category: 'Noodles',
        basePrice: 15.00,
        isAvailable: true,
        minOrderQuantity: 1,
        maxOrderQuantity: 8,
        imageUrl: 'https://example.com/char-kway-teow.jpg',
        galleryImages: const [],
        isHalal: true,
        isVegetarian: false,
        isSpicy: true,
        spicyLevel: 3,
        isFeatured: false,
        tags: const ['Chinese', 'Noodles', 'Spicy'],
        nutritionInfo: const {},
        allergens: const ['Shellfish'],
        preparationTimeMinutes: 15,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      Product(
        id: '550e8400-e29b-41d4-a716-446655440203', // Test product UUID
        vendorId: testVendor.id,
        name: 'Teh Tarik',
        description: 'Traditional Malaysian pulled tea with condensed milk',
        category: 'Beverages',
        basePrice: 3.50,
        bulkPrice: 3.00,
        bulkMinQuantity: 4,
        isAvailable: true,
        minOrderQuantity: 1,
        maxOrderQuantity: 20,
        imageUrl: 'https://example.com/teh-tarik.jpg',
        galleryImages: const [],
        isHalal: true,
        isVegetarian: true,
        isSpicy: false,
        spicyLevel: 0,
        isFeatured: false,
        tags: const ['Beverages', 'Tea', 'Malaysian'],
        nutritionInfo: const {},
        allergens: const ['Dairy'],
        preparationTimeMinutes: 5,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    ];

    // Add items to cart
    for (final product in testProducts) {
      print('🛒 Adding ${product.name} to cart...');
      cartNotifier.addItem(
        product: product,
        vendor: testVendor,
        quantity: product.name == 'Teh Tarik' ? 2 : 1,
        notes: product.name == 'Nasi Lemak' ? 'Extra spicy please' : null,
      );
    }
    print('🛒 TestCartHelper: Finished adding ${testProducts.length} items to cart');
  }

  static void clearCart(WidgetRef ref) {
    ref.read(cartProvider.notifier).clearCart();
  }
}
