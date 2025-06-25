
import 'package:uuid/uuid.dart';

import '../models/menu_item.dart';
import '../models/product.dart' as product_model;
import '../repositories/customization_repository.dart';

class MenuService {
  static final List<MenuCategory> _categories = [];
  static final List<MenuItem> _menuItems = [];
  static final _uuid = const Uuid();
  static final _customizationRepository = CustomizationRepository();

  // Get all categories for a vendor
  Future<List<MenuCategory>> getVendorCategories(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    final categories = _categories.where((c) => c.vendorId == vendorId && c.isActive).toList();
    categories.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    
    if (categories.isEmpty) {
      // Generate default categories for new vendors
      await _generateDefaultCategories(vendorId);
      return _categories.where((c) => c.vendorId == vendorId && c.isActive).toList();
    }
    
    return categories;
  }

  // Get menu items for a vendor
  Future<List<MenuItem>> getVendorMenuItems(String vendorId, {String? categoryId}) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate API delay
    
    var items = _menuItems.where((item) => 
        item.vendorId == vendorId && 
        item.isActive
    ).toList();
    
    if (categoryId != null) {
      items = items.where((item) => item.category == categoryId).toList();
    }
    
    if (items.isEmpty) {
      // Generate sample menu items for new vendors
      await _generateSampleMenuItems(vendorId);
      items = _menuItems.where((item) => 
          item.vendorId == vendorId && 
          item.isActive
      ).toList();
    }
    
    return items;
  }

  // Create a new menu category
  Future<MenuCategory> createCategory({
    required String vendorId,
    required String name,
    String? description,
    String? imageUrl,
    int? sortOrder,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
    
    final category = MenuCategory(
      id: _uuid.v4(),
      vendorId: vendorId,
      name: name,
      description: description,
      imageUrl: imageUrl,
      sortOrder: sortOrder ?? _categories.where((c) => c.vendorId == vendorId).length,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _categories.add(category);
    return category;
  }

  // Create a new menu item
  Future<MenuItem> createMenuItem({
    required String vendorId,
    required String name,
    required String description,
    required String category,
    required double basePrice,
    List<BulkPricingTier>? bulkPricingTiers,
    int? minimumOrderQuantity,
    int? maximumOrderQuantity,
    List<String>? imageUrls,
    List<DietaryType>? dietaryTypes,
    List<String>? allergens,
    int? preparationTimeMinutes,
    int? availableQuantity,
    String? unit,
    bool? isHalalCertified,
    List<String>? tags,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
    
    final menuItem = MenuItem(
      id: _uuid.v4(),
      vendorId: vendorId,
      name: name,
      description: description,
      category: category,
      basePrice: basePrice,
      bulkPricingTiers: bulkPricingTiers ?? [],
      minimumOrderQuantity: minimumOrderQuantity ?? 1,
      maximumOrderQuantity: maximumOrderQuantity,
      imageUrls: imageUrls ?? [],
      dietaryTypes: dietaryTypes ?? [],
      allergens: allergens ?? [],
      preparationTimeMinutes: preparationTimeMinutes ?? 30,
      availableQuantity: availableQuantity,
      unit: unit ?? 'pax',
      isHalalCertified: isHalalCertified ?? false,
      tags: tags ?? [],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _menuItems.add(menuItem);
    return menuItem;
  }

  // Update menu item
  Future<MenuItem> updateMenuItem(String itemId, MenuItem updatedItem) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
    
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw Exception('Menu item not found');
    }
    
    final updated = updatedItem.copyWith(updatedAt: DateTime.now());
    _menuItems[index] = updated;
    return updated;
  }

  // Update menu item availability
  Future<void> updateItemAvailability(String itemId, MenuItemStatus status, {int? availableQuantity}) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate API delay
    
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw Exception('Menu item not found');
    }
    
    _menuItems[index] = _menuItems[index].copyWith(
      status: status,
      availableQuantity: availableQuantity,
      updatedAt: DateTime.now(),
    );
  }

  // Delete menu item (soft delete)
  Future<void> deleteMenuItem(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate API delay
    
    final index = _menuItems.indexWhere((item) => item.id == itemId);
    if (index == -1) {
      throw Exception('Menu item not found');
    }
    
    _menuItems[index] = _menuItems[index].copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
  }

  // Get menu item by ID
  Future<MenuItem?> getMenuItem(String itemId) async {
    await Future.delayed(const Duration(milliseconds: 200)); // Simulate API delay
    
    try {
      return _menuItems.firstWhere((item) => item.id == itemId && item.isActive);
    } catch (e) {
      return null;
    }
  }

  // Search menu items
  Future<List<MenuItem>> searchMenuItems({
    required String vendorId,
    String? query,
    String? category,
    List<DietaryType>? dietaryTypes,
    double? minPrice,
    double? maxPrice,
    bool? isHalalCertified,
  }) async {
    await Future.delayed(const Duration(milliseconds: 400)); // Simulate API delay
    
    var items = _menuItems.where((item) => 
        item.vendorId == vendorId && 
        item.isActive &&
        item.status == MenuItemStatus.available
    ).toList();
    
    if (query != null && query.isNotEmpty) {
      final lowerQuery = query.toLowerCase();
      items = items.where((item) => 
          item.name.toLowerCase().contains(lowerQuery) ||
          item.description.toLowerCase().contains(lowerQuery) ||
          item.tags.any((tag) => tag.toLowerCase().contains(lowerQuery))
      ).toList();
    }
    
    if (category != null) {
      items = items.where((item) => item.category == category).toList();
    }
    
    if (dietaryTypes != null && dietaryTypes.isNotEmpty) {
      items = items.where((item) => 
          dietaryTypes.any((type) => item.dietaryTypes.contains(type))
      ).toList();
    }
    
    if (minPrice != null) {
      items = items.where((item) => item.basePrice >= minPrice).toList();
    }
    
    if (maxPrice != null) {
      items = items.where((item) => item.basePrice <= maxPrice).toList();
    }
    
    if (isHalalCertified == true) {
      items = items.where((item) => item.isHalalCertified).toList();
    }
    
    return items;
  }

  // Generate default categories for a vendor
  Future<void> _generateDefaultCategories(String vendorId) async {
    final defaultCategories = [
      'Main Courses',
      'Appetizers',
      'Desserts',
      'Beverages',
      'Rice & Noodles',
      'Vegetarian',
    ];
    
    for (int i = 0; i < defaultCategories.length; i++) {
      await createCategory(
        vendorId: vendorId,
        name: defaultCategories[i],
        sortOrder: i,
      );
    }
  }

  // Generate sample menu items for a vendor
  Future<void> _generateSampleMenuItems(String vendorId) async {
    final categories = await getVendorCategories(vendorId);
    if (categories.isEmpty) return;
    
    final sampleItems = [
      {
        'name': 'Nasi Lemak Set',
        'description': 'Traditional Malaysian coconut rice with sambal, anchovies, peanuts, and egg',
        'category': categories.first.id,
        'basePrice': 12.0,
        'bulkTiers': [
          BulkPricingTier(minimumQuantity: 50, pricePerUnit: 10.0, discountPercentage: 16.7),
          BulkPricingTier(minimumQuantity: 100, pricePerUnit: 9.0, discountPercentage: 25.0),
        ],
        'minQty': 10,
        'dietaryTypes': [DietaryType.halal],
        'isHalal': true,
        'prepTime': 45,
      },
      {
        'name': 'Chicken Rendang',
        'description': 'Slow-cooked chicken in rich coconut curry sauce',
        'category': categories.first.id,
        'basePrice': 18.0,
        'bulkTiers': [
          BulkPricingTier(minimumQuantity: 30, pricePerUnit: 16.0, discountPercentage: 11.1),
          BulkPricingTier(minimumQuantity: 80, pricePerUnit: 15.0, discountPercentage: 16.7),
        ],
        'minQty': 20,
        'dietaryTypes': [DietaryType.halal],
        'isHalal': true,
        'prepTime': 60,
      },
      {
        'name': 'Vegetarian Curry',
        'description': 'Mixed vegetables in aromatic curry sauce',
        'category': categories.length > 5 ? categories[5].id : categories.first.id,
        'basePrice': 14.0,
        'bulkTiers': [
          BulkPricingTier(minimumQuantity: 40, pricePerUnit: 12.0, discountPercentage: 14.3),
        ],
        'minQty': 15,
        'dietaryTypes': [DietaryType.vegetarian, DietaryType.halal],
        'isHalal': true,
        'prepTime': 40,
      },
    ];
    
    for (final item in sampleItems) {
      await createMenuItem(
        vendorId: vendorId,
        name: item['name'] as String,
        description: item['description'] as String,
        category: item['category'] as String,
        basePrice: item['basePrice'] as double,
        bulkPricingTiers: item['bulkTiers'] as List<BulkPricingTier>,
        minimumOrderQuantity: item['minQty'] as int,
        dietaryTypes: item['dietaryTypes'] as List<DietaryType>,
        isHalalCertified: item['isHalal'] as bool,
        preparationTimeMinutes: item['prepTime'] as int,
        unit: 'pax',
        availableQuantity: 500,
      );
    }
  }

  // Get vendor menu statistics
  Future<Map<String, dynamic>> getVendorMenuStats(String vendorId) async {
    await Future.delayed(const Duration(milliseconds: 300)); // Simulate API delay
    
    final items = await getVendorMenuItems(vendorId);
    final categories = await getVendorCategories(vendorId);
    
    final availableItems = items.where((item) => item.status == MenuItemStatus.available).length;
    final outOfStockItems = items.where((item) => item.status == MenuItemStatus.outOfStock).length;
    final halalItems = items.where((item) => item.isHalalCertified).length;
    
    final avgPrice = items.isNotEmpty 
        ? items.map((item) => item.basePrice).reduce((a, b) => a + b) / items.length
        : 0.0;
    
    return {
      'totalItems': items.length,
      'totalCategories': categories.length,
      'availableItems': availableItems,
      'outOfStockItems': outOfStockItems,
      'halalItems': halalItems,
      'averagePrice': avgPrice,
    };
  }

  // Customization Management Methods

  // Get all customizations for a menu item
  Future<List<product_model.MenuItemCustomization>> getMenuItemCustomizations(String menuItemId) async {
    return await _customizationRepository.getMenuItemCustomizations(menuItemId);
  }

  // Create a new customization group
  Future<product_model.MenuItemCustomization> createCustomization({
    required String menuItemId,
    required String name,
    required String type,
    required bool isRequired,
    int displayOrder = 0,
  }) async {
    return await _customizationRepository.createCustomization(
      menuItemId: menuItemId,
      name: name,
      type: type,
      isRequired: isRequired,
      displayOrder: displayOrder,
    );
  }

  // Update an existing customization group
  Future<product_model.MenuItemCustomization> updateCustomization({
    required String customizationId,
    String? name,
    String? type,
    bool? isRequired,
    int? displayOrder,
  }) async {
    return await _customizationRepository.updateCustomization(
      customizationId: customizationId,
      name: name,
      type: type,
      isRequired: isRequired,
      displayOrder: displayOrder,
    );
  }

  // Delete a customization group
  Future<void> deleteCustomization(String customizationId) async {
    return await _customizationRepository.deleteCustomization(customizationId);
  }

  // Create a new customization option
  Future<product_model.CustomizationOption> createCustomizationOption({
    required String customizationId,
    required String name,
    required double additionalPrice,
    bool isDefault = false,
    bool isAvailable = true,
    int displayOrder = 0,
  }) async {
    return await _customizationRepository.createCustomizationOption(
      customizationId: customizationId,
      name: name,
      additionalPrice: additionalPrice,
      isDefault: isDefault,
      isAvailable: isAvailable,
      displayOrder: displayOrder,
    );
  }

  // Update an existing customization option
  Future<product_model.CustomizationOption> updateCustomizationOption({
    required String optionId,
    String? name,
    double? additionalPrice,
    bool? isDefault,
    bool? isAvailable,
    int? displayOrder,
  }) async {
    return await _customizationRepository.updateCustomizationOption(
      optionId: optionId,
      name: name,
      additionalPrice: additionalPrice,
      isDefault: isDefault,
      isAvailable: isAvailable,
      displayOrder: displayOrder,
    );
  }

  // Delete a customization option
  Future<void> deleteCustomizationOption(String optionId) async {
    return await _customizationRepository.deleteCustomizationOption(optionId);
  }

  // Validate customizations for an order
  Future<bool> validateOrderCustomizations({
    required String menuItemId,
    required Map<String, dynamic> customizations,
  }) async {
    return await _customizationRepository.validateOrderCustomizations(
      menuItemId: menuItemId,
      customizations: customizations,
    );
  }

  // Get menu item with all customizations
  Future<Map<String, dynamic>> getMenuItemWithCustomizations(String menuItemId) async {
    return await _customizationRepository.getMenuItemWithCustomizations(menuItemId);
  }

  // Bulk create customizations for a menu item
  Future<List<product_model.MenuItemCustomization>> bulkCreateCustomizations({
    required String menuItemId,
    required List<product_model.MenuItemCustomization> customizations,
  }) async {
    return await _customizationRepository.bulkCreateCustomizations(
      menuItemId: menuItemId,
      customizations: customizations,
    );
  }

  // Convert Product to MenuItem (for backward compatibility)
  MenuItem productToMenuItem(product_model.Product product) {
    return MenuItem(
      id: product.id,
      vendorId: product.vendorId,
      name: product.name,
      description: product.description ?? '',
      category: product.category,
      basePrice: product.basePrice,
      bulkPricingTiers: [], // Convert if needed
      minimumOrderQuantity: 1,
      maximumOrderQuantity: null,
      imageUrls: product.imageUrl != null ? [product.imageUrl!] : [],
      dietaryTypes: (product.isVegetarian ?? false) ? [DietaryType.vegetarian] : [],
      allergens: [],
      preparationTimeMinutes: 30,
      availableQuantity: null,
      unit: 'pax',
      isHalalCertified: product.isHalal ?? false,
      tags: product.tags,
      status: (product.isAvailable ?? true) ? MenuItemStatus.available : MenuItemStatus.outOfStock,
      createdAt: product.createdAt ?? DateTime.now(),
      updatedAt: product.updatedAt ?? DateTime.now(),
    );
  }

  // Convert MenuItem to Product (for new customization features)
  product_model.Product menuItemToProduct(MenuItem menuItem, {List<product_model.MenuItemCustomization>? customizations}) {
    return product_model.Product(
      id: menuItem.id,
      vendorId: menuItem.vendorId,
      name: menuItem.name,
      description: menuItem.description,
      category: menuItem.category,
      basePrice: menuItem.basePrice,
      imageUrl: menuItem.imageUrls.isNotEmpty ? menuItem.imageUrls.first : null,
      isAvailable: menuItem.status == MenuItemStatus.available,
      isVegetarian: menuItem.dietaryTypes.contains(DietaryType.vegetarian),
      isHalal: menuItem.isHalalCertified,
      tags: menuItem.tags,
      rating: 0.0,
      totalReviews: 0,
      createdAt: menuItem.createdAt,
      updatedAt: menuItem.updatedAt,
      customizations: customizations ?? [],
    );
  }
}
