import 'dart:convert';
import '../models/product.dart';

/// Utility class for handling Product model serialization and database operations
class ProductSerializationUtils {
  
  /// Convert Product to database-compatible Map
  static Map<String, dynamic> toDatabase(Product product) {
    final json = product.toJson();
    
    // Convert customizations to JSON string for database storage
    if (json['customizations'] != null && json['customizations'] is List) {
      json['customizations'] = jsonEncode(json['customizations']);
    }
    
    // Ensure proper null handling for optional fields
    json.removeWhere((key, value) => value == null);
    
    return json;
  }
  
  /// Convert database Map to Product
  static Product fromDatabase(Map<String, dynamic> data) {
    // Handle customizations JSON string from database
    if (data['customizations'] != null && data['customizations'] is String) {
      try {
        final customizationsJson = jsonDecode(data['customizations'] as String);
        data['customizations'] = customizationsJson;
      } catch (e) {
        // If JSON parsing fails, set empty list
        data['customizations'] = <Map<String, dynamic>>[];
      }
    }
    
    return Product.fromJson(data);
  }
  
  /// Convert customizations list to JSON string for database storage
  static String customizationsToJson(List<MenuItemCustomization> customizations) {
    if (customizations.isEmpty) return '[]';
    
    try {
      final jsonList = customizations.map((c) => c.toJson()).toList();
      return jsonEncode(jsonList);
    } catch (e) {
      return '[]';
    }
  }
  
  /// Convert JSON string to customizations list from database
  static List<MenuItemCustomization> customizationsFromJson(String? jsonString) {
    if (jsonString == null || jsonString.trim().isEmpty) {
      return <MenuItemCustomization>[];
    }
    
    try {
      final jsonList = jsonDecode(jsonString) as List<dynamic>;
      return jsonList
          .map((json) => MenuItemCustomization.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return <MenuItemCustomization>[];
    }
  }
  
  /// Validate Product data before database insertion
  static Map<String, String> validateForDatabase(Product product) {
    final errors = <String, String>{};
    
    // Required field validation
    if (product.name.trim().isEmpty) {
      errors['name'] = 'Product name is required';
    }
    
    if (product.vendorId.trim().isEmpty) {
      errors['vendor_id'] = 'Vendor ID is required';
    }
    
    if (product.category.trim().isEmpty) {
      errors['category'] = 'Category is required';
    }
    
    if (product.basePrice <= 0) {
      errors['base_price'] = 'Base price must be greater than 0';
    }
    
    // Business logic validation
    if (product.bulkPrice != null && product.bulkMinQuantity != null) {
      if (product.bulkPrice! >= product.basePrice) {
        errors['bulk_price'] = 'Bulk price must be less than base price';
      }
      
      if (product.bulkMinQuantity! <= 1) {
        errors['bulk_min_quantity'] = 'Bulk minimum quantity must be greater than 1';
      }
    }
    
    if (product.maxOrderQuantity != null && product.minOrderQuantity != null) {
      if (product.maxOrderQuantity! < product.minOrderQuantity!) {
        errors['max_order_quantity'] = 'Maximum quantity must be greater than or equal to minimum quantity';
      }
    }
    
    // Customization validation
    for (int i = 0; i < product.customizations.length; i++) {
      final customization = product.customizations[i];
      
      if (customization.name.trim().isEmpty) {
        errors['customization_${i}_name'] = 'Customization name is required';
      }
      
      if (customization.options.isEmpty) {
        errors['customization_${i}_options'] = 'At least one option is required';
      }
      
      for (int j = 0; j < customization.options.length; j++) {
        final option = customization.options[j];
        
        if (option.name.trim().isEmpty) {
          errors['customization_${i}_option_${j}_name'] = 'Option name is required';
        }
        
        if (option.additionalPrice < 0) {
          errors['customization_${i}_option_${j}_price'] = 'Additional price cannot be negative (use 0.00 for free options)';
        }
      }
    }
    
    return errors;
  }
  
  /// Prepare Product data for creation (set defaults, generate IDs, etc.)
  static Product prepareForCreation(Product product, String vendorId) {
    final now = DateTime.now();

    return product.copyWith(
      // Don't set id - let database generate it
      vendorId: vendorId,
      currency: product.currency ?? 'MYR',
      includesSst: product.includesSst ?? false,
      isAvailable: product.isAvailable ?? true,
      minOrderQuantity: product.minOrderQuantity ?? 1,
      preparationTimeMinutes: product.preparationTimeMinutes ?? 30,
      isHalal: product.isHalal ?? false,
      isVegetarian: product.isVegetarian ?? false,
      isVegan: product.isVegan ?? false,
      isSpicy: product.isSpicy ?? false,
      spicyLevel: product.spicyLevel ?? 0,
      isFeatured: product.isFeatured ?? false,
      createdAt: now,
      updatedAt: now,
    );
  }
  
  /// Prepare Product data for update (preserve creation time, update modified time)
  static Product prepareForUpdate(Product product, Product existingProduct) {
    return product.copyWith(
      id: existingProduct.id,
      vendorId: existingProduct.vendorId,
      createdAt: existingProduct.createdAt,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Extract searchable text from Product for search functionality
  static String extractSearchableText(Product product) {
    final searchTerms = <String>[
      product.name,
      product.safeDescription,
      product.category,
      ...product.tags,
      ...product.allergens,
    ];
    
    // Add customization names and option names
    for (final customization in product.customizations) {
      searchTerms.add(customization.name);
      for (final option in customization.options) {
        searchTerms.add(option.name);
      }
    }
    
    return searchTerms
        .where((term) => term.trim().isNotEmpty)
        .map((term) => term.toLowerCase())
        .join(' ');
  }
  
  /// Calculate total price including customizations
  static double calculateTotalPrice(Product product, int quantity, List<String> selectedCustomizationOptionIds) {
    double basePrice = product.getPriceForQuantity(quantity);
    double customizationPrice = 0.0;
    
    // Calculate additional price from selected customizations
    for (final customization in product.customizations) {
      for (final option in customization.options) {
        if (selectedCustomizationOptionIds.contains(option.id)) {
          customizationPrice += option.additionalPrice;
        }
      }
    }
    
    return (basePrice + customizationPrice) * quantity;
  }
  
  /// Check if customization selections are valid
  static Map<String, String> validateCustomizationSelections(
    Product product, 
    Map<String, List<String>> customizationSelections
  ) {
    final errors = <String, String>{};
    
    for (final customization in product.customizations) {
      final selections = customizationSelections[customization.id] ?? [];
      
      // Check required customizations
      if (customization.isRequired && selections.isEmpty) {
        errors[customization.id ?? customization.name] = '${customization.name} is required';
        continue;
      }

      // Check selection type constraints
      if (customization.type == 'single' && selections.length > 1) {
        errors[customization.id ?? customization.name] = '${customization.name} allows only one selection';
        continue;
      }
      
      // Validate that selected options exist
      final validOptionIds = customization.options.map((o) => o.id).toSet();
      for (final selectedId in selections) {
        if (!validOptionIds.contains(selectedId)) {
          errors[customization.id ?? customization.name] = 'Invalid option selected for ${customization.name}';
          break;
        }
      }
    }
    
    return errors;
  }
  
  /// Get default customization selections for a product
  static Map<String, List<String>> getDefaultCustomizationSelections(Product product) {
    final defaults = <String, List<String>>{};
    
    for (final customization in product.customizations) {
      final defaultOptions = customization.options
          .where((option) => option.isDefault)
          .map((option) => option.id ?? '')
          .where((id) => id.isNotEmpty)
          .toList();

      if (defaultOptions.isNotEmpty) {
        defaults[customization.id ?? customization.name] = defaultOptions;
      }
    }
    
    return defaults;
  }

  /// Check if a customization option is free (zero price)
  static bool isOptionFree(CustomizationOption option) {
    return option.additionalPrice == 0.0;
  }

  /// Get all free options from a customization
  static List<CustomizationOption> getFreeOptions(MenuItemCustomization customization) {
    return customization.options.where((option) => isOptionFree(option)).toList();
  }

  /// Get all paid options from a customization
  static List<CustomizationOption> getPaidOptions(MenuItemCustomization customization) {
    return customization.options.where((option) => !isOptionFree(option)).toList();
  }

  /// Calculate price for only paid customizations (excluding free ones)
  static double calculatePaidCustomizationPrice(Product product, List<String> selectedCustomizationOptionIds) {
    double customizationPrice = 0.0;

    for (final customization in product.customizations) {
      for (final option in customization.options) {
        if (selectedCustomizationOptionIds.contains(option.id) && !isOptionFree(option)) {
          customizationPrice += option.additionalPrice;
        }
      }
    }

    return customizationPrice;
  }

  /// Get summary of free and paid customizations for display
  static Map<String, dynamic> getCustomizationPricingSummary(Product product, List<String> selectedCustomizationOptionIds) {
    final freeOptions = <String>[];
    final paidOptions = <Map<String, dynamic>>[];
    double totalPaidPrice = 0.0;

    for (final customization in product.customizations) {
      for (final option in customization.options) {
        if (selectedCustomizationOptionIds.contains(option.id)) {
          if (isOptionFree(option)) {
            freeOptions.add(option.name);
          } else {
            paidOptions.add({
              'name': option.name,
              'price': option.additionalPrice,
            });
            totalPaidPrice += option.additionalPrice;
          }
        }
      }
    }

    return {
      'freeOptions': freeOptions,
      'paidOptions': paidOptions,
      'totalPaidPrice': totalPaidPrice,
      'hasFreeOptions': freeOptions.isNotEmpty,
      'hasPaidOptions': paidOptions.isNotEmpty,
    };
  }
}
