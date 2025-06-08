import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/features/menu/data/models/product.dart';
import 'package:gigaeats_app/features/menu/data/utils/product_serialization_utils.dart';

void main() {
  group('Zero Price Customization Tests', () {
    test('ProductSerializationUtils should allow zero price customizations', () {
      // Create a product with zero-price customizations
      final product = Product(
        id: 'test-id',
        vendorId: 'vendor-id',
        name: 'Test Burger',
        description: 'A test burger with free customizations',
        category: 'Main Course',
        tags: [],
        basePrice: 15.0,
        currency: 'MYR',
        includesSst: false,
        isAvailable: true,
        minOrderQuantity: 1,
        preparationTimeMinutes: 20,
        allergens: [],
        isHalal: true,
        isVegetarian: false,
        isVegan: false,
        isSpicy: false,
        spicyLevel: 0,
        galleryImages: [],
        isFeatured: false,
        customizations: [
          MenuItemCustomization(
            id: 'customization-1',
            name: 'Free Add-ons',
            type: 'multiple',
            isRequired: false,
            options: [
              CustomizationOption(
                id: 'option-1',
                name: 'Extra Napkins',
                additionalPrice: 0.0, // Free option
                isDefault: false,
              ),
              CustomizationOption(
                id: 'option-2',
                name: 'No Ice',
                additionalPrice: 0.0, // Free option
                isDefault: false,
              ),
              CustomizationOption(
                id: 'option-3',
                name: 'Extra Sauce',
                additionalPrice: 2.0, // Paid option
                isDefault: false,
              ),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test validation - should pass with zero prices
      final errors = ProductSerializationUtils.validateForDatabase(product);
      
      // Should have no validation errors
      expect(errors.isEmpty, true, reason: 'Zero price customizations should be valid');
    });

    test('ProductSerializationUtils should reject negative price customizations', () {
      // Create a product with negative-price customizations
      final product = Product(
        id: 'test-id',
        vendorId: 'vendor-id',
        name: 'Test Burger',
        description: 'A test burger with invalid customizations',
        category: 'Main Course',
        tags: [],
        basePrice: 15.0,
        currency: 'MYR',
        includesSst: false,
        isAvailable: true,
        minOrderQuantity: 1,
        preparationTimeMinutes: 20,
        allergens: [],
        isHalal: true,
        isVegetarian: false,
        isVegan: false,
        isSpicy: false,
        spicyLevel: 0,
        galleryImages: [],
        isFeatured: false,
        customizations: [
          MenuItemCustomization(
            id: 'customization-1',
            name: 'Invalid Add-ons',
            type: 'multiple',
            isRequired: false,
            options: [
              CustomizationOption(
                id: 'option-1',
                name: 'Negative Price Option',
                additionalPrice: -1.0, // Invalid negative price
                isDefault: false,
              ),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test validation - should fail with negative prices
      final errors = ProductSerializationUtils.validateForDatabase(product);
      
      // Should have validation errors for negative price
      expect(errors.isNotEmpty, true, reason: 'Negative price customizations should be invalid');
      expect(errors.values.any((error) => error.contains('negative')), true, 
        reason: 'Error message should mention negative price');
    });

    test('ProductSerializationUtils helper methods should work correctly', () {
      final freeOption = CustomizationOption(
        id: 'free-option',
        name: 'Free Option',
        additionalPrice: 0.0,
        isDefault: false,
      );

      final paidOption = CustomizationOption(
        id: 'paid-option',
        name: 'Paid Option',
        additionalPrice: 2.5,
        isDefault: false,
      );

      // Test isOptionFree
      expect(ProductSerializationUtils.isOptionFree(freeOption), true);
      expect(ProductSerializationUtils.isOptionFree(paidOption), false);

      // Test customization filtering
      final customization = MenuItemCustomization(
        id: 'test-customization',
        name: 'Test Customization',
        type: 'multiple',
        isRequired: false,
        options: [freeOption, paidOption],
      );

      final freeOptions = ProductSerializationUtils.getFreeOptions(customization);
      final paidOptions = ProductSerializationUtils.getPaidOptions(customization);

      expect(freeOptions.length, 1);
      expect(freeOptions.first.name, 'Free Option');
      expect(paidOptions.length, 1);
      expect(paidOptions.first.name, 'Paid Option');
    });

    test('ProductSerializationUtils pricing summary should work correctly', () {
      final product = Product(
        id: 'test-id',
        vendorId: 'vendor-id',
        name: 'Test Product',
        description: 'Test product',
        category: 'Test',
        tags: [],
        basePrice: 10.0,
        currency: 'MYR',
        includesSst: false,
        isAvailable: true,
        minOrderQuantity: 1,
        preparationTimeMinutes: 10,
        allergens: [],
        isHalal: true,
        isVegetarian: false,
        isVegan: false,
        isSpicy: false,
        spicyLevel: 0,
        galleryImages: [],
        isFeatured: false,
        customizations: [
          MenuItemCustomization(
            id: 'customization-1',
            name: 'Test Customization',
            type: 'multiple',
            isRequired: false,
            options: [
              CustomizationOption(
                id: 'free-option',
                name: 'Free Option',
                additionalPrice: 0.0,
                isDefault: false,
              ),
              CustomizationOption(
                id: 'paid-option',
                name: 'Paid Option',
                additionalPrice: 3.0,
                isDefault: false,
              ),
            ],
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Test pricing summary with both free and paid options selected
      final selectedOptions = ['free-option', 'paid-option'];
      final summary = ProductSerializationUtils.getCustomizationPricingSummary(product, selectedOptions);

      expect(summary['freeOptions'], ['Free Option']);
      expect(summary['paidOptions'], [{'name': 'Paid Option', 'price': 3.0}]);
      expect(summary['totalPaidPrice'], 3.0);
      expect(summary['hasFreeOptions'], true);
      expect(summary['hasPaidOptions'], true);
    });
  });
}
