import '../constants/menu_constants.dart';

/// Utility class for menu item validation
class MenuValidationUtils {
  
  /// Validate menu item name
  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Menu item name is required';
    }
    
    if (value.trim().length < MenuValidationConstants.minNameLength) {
      return 'Name must be at least ${MenuValidationConstants.minNameLength} characters';
    }
    
    if (value.trim().length > MenuValidationConstants.maxNameLength) {
      return 'Name must be less than ${MenuValidationConstants.maxNameLength} characters';
    }
    
    return null;
  }

  /// Validate menu item description
  static String? validateDescription(String? value) {
    if (value != null && value.trim().length > MenuValidationConstants.maxDescriptionLength) {
      return 'Description must be less than ${MenuValidationConstants.maxDescriptionLength} characters';
    }
    
    return null;
  }

  /// Validate price
  static String? validatePrice(String? value, {bool isRequired = true}) {
    if (value == null || value.trim().isEmpty) {
      return isRequired ? 'Price is required' : null;
    }
    
    final price = double.tryParse(value);
    if (price == null) {
      return 'Please enter a valid price';
    }
    
    if (price < MenuValidationConstants.minPrice) {
      return 'Price must be at least RM ${MenuValidationConstants.minPrice.toStringAsFixed(2)}';
    }
    
    if (price > MenuValidationConstants.maxPrice) {
      return 'Price must be less than RM ${MenuValidationConstants.maxPrice.toStringAsFixed(2)}';
    }
    
    return null;
  }

  /// Validate quantity
  static String? validateQuantity(String? value, {bool isRequired = true, String? fieldName}) {
    final field = fieldName ?? 'Quantity';
    
    if (value == null || value.trim().isEmpty) {
      return isRequired ? '$field is required' : null;
    }
    
    final quantity = int.tryParse(value);
    if (quantity == null) {
      return 'Please enter a valid $field';
    }
    
    if (quantity < MenuValidationConstants.minQuantity) {
      return '$field must be at least ${MenuValidationConstants.minQuantity}';
    }
    
    if (quantity > MenuValidationConstants.maxQuantity) {
      return '$field must be less than ${MenuValidationConstants.maxQuantity}';
    }
    
    return null;
  }

  /// Validate preparation time
  static String? validatePreparationTime(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Preparation time is required';
    }
    
    final time = int.tryParse(value);
    if (time == null) {
      return 'Please enter a valid preparation time';
    }
    
    if (time < MenuValidationConstants.minPrepTime) {
      return 'Preparation time must be at least ${MenuValidationConstants.minPrepTime} minutes';
    }
    
    if (time > MenuValidationConstants.maxPrepTime) {
      return 'Preparation time must be less than ${MenuValidationConstants.maxPrepTime} minutes';
    }
    
    return null;
  }

  /// Validate bulk pricing consistency
  static String? validateBulkPricing(String? bulkPrice, String? bulkMinQuantity, double basePrice) {
    if (bulkPrice != null && bulkPrice.trim().isNotEmpty) {
      final bulk = double.tryParse(bulkPrice);
      if (bulk == null) {
        return 'Please enter a valid bulk price';
      }
      
      if (bulk >= basePrice) {
        return 'Bulk price should be less than base price';
      }
      
      if (bulkMinQuantity == null || bulkMinQuantity.trim().isEmpty) {
        return 'Bulk minimum quantity is required when bulk price is set';
      }
      
      final minQty = int.tryParse(bulkMinQuantity);
      if (minQty == null || minQty <= 1) {
        return 'Bulk minimum quantity must be greater than 1';
      }
    }
    
    return null;
  }

  /// Validate quantity range (min vs max)
  static String? validateQuantityRange(String? minQuantity, String? maxQuantity) {
    if (minQuantity != null && maxQuantity != null && 
        minQuantity.trim().isNotEmpty && maxQuantity.trim().isNotEmpty) {
      final min = int.tryParse(minQuantity);
      final max = int.tryParse(maxQuantity);
      
      if (min != null && max != null && max < min) {
        return 'Maximum quantity must be greater than or equal to minimum quantity';
      }
    }
    
    return null;
  }

  /// Validate category selection
  static String? validateCategory(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please select a category';
    }
    
    return null;
  }

  /// Validate customization name
  static String? validateCustomizationName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Customization name is required';
    }
    
    if (value.trim().length < 2) {
      return 'Customization name must be at least 2 characters';
    }
    
    if (value.trim().length > 50) {
      return 'Customization name must be less than 50 characters';
    }
    
    return null;
  }

  /// Validate customization option name
  static String? validateCustomizationOptionName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Option name is required';
    }
    
    if (value.trim().length < 1) {
      return 'Option name cannot be empty';
    }
    
    if (value.trim().length > 30) {
      return 'Option name must be less than 30 characters';
    }
    
    return null;
  }

  /// Validate image file size
  static String? validateImageSize(int fileSizeBytes) {
    if (fileSizeBytes > MenuValidationConstants.maxImageSize) {
      final maxSizeMB = MenuValidationConstants.maxImageSize / (1024 * 1024);
      return 'Image size must be less than ${maxSizeMB.toStringAsFixed(1)}MB';
    }
    
    return null;
  }

  /// Validate image file type
  static String? validateImageType(String fileName) {
    final extension = fileName.toLowerCase().split('.').last;
    
    if (!MenuValidationConstants.allowedImageTypes.contains(extension)) {
      return 'Only ${MenuValidationConstants.allowedImageTypes.join(', ')} files are allowed';
    }
    
    return null;
  }

  /// Validate spicy level
  static String? validateSpicyLevel(int level) {
    if (level < 0 || level > 5) {
      return 'Spicy level must be between 0 and 5';
    }
    
    return null;
  }

  /// Check if all required fields are filled for menu item
  static bool isMenuItemValid({
    required String name,
    required String category,
    required double basePrice,
    required int preparationTime,
    required int minOrderQuantity,
    String? maxOrderQuantity,
    String? bulkPrice,
    String? bulkMinQuantity,
  }) {
    // Check required fields
    if (name.trim().isEmpty || category.trim().isEmpty) {
      return false;
    }
    
    if (basePrice <= 0 || preparationTime <= 0 || minOrderQuantity <= 0) {
      return false;
    }
    
    // Check optional bulk pricing consistency
    if (bulkPrice != null && bulkPrice.trim().isNotEmpty) {
      final bulk = double.tryParse(bulkPrice);
      final minQty = int.tryParse(bulkMinQuantity ?? '');
      
      if (bulk == null || minQty == null || bulk >= basePrice || minQty <= 1) {
        return false;
      }
    }
    
    // Check quantity range
    if (maxOrderQuantity != null && maxOrderQuantity.trim().isNotEmpty) {
      final max = int.tryParse(maxOrderQuantity);
      if (max == null || max < minOrderQuantity) {
        return false;
      }
    }
    
    return true;
  }

  /// Get validation summary for menu item
  static List<String> getValidationErrors({
    required String name,
    required String category,
    required String basePrice,
    required String preparationTime,
    required String minOrderQuantity,
    String? maxOrderQuantity,
    String? bulkPrice,
    String? bulkMinQuantity,
  }) {
    final errors = <String>[];
    
    final nameError = validateName(name);
    if (nameError != null) errors.add(nameError);
    
    final categoryError = validateCategory(category);
    if (categoryError != null) errors.add(categoryError);
    
    final priceError = validatePrice(basePrice);
    if (priceError != null) errors.add(priceError);
    
    final prepTimeError = validatePreparationTime(preparationTime);
    if (prepTimeError != null) errors.add(prepTimeError);
    
    final minQtyError = validateQuantity(minOrderQuantity, fieldName: 'Minimum order quantity');
    if (minQtyError != null) errors.add(minQtyError);
    
    if (maxOrderQuantity != null && maxOrderQuantity.trim().isNotEmpty) {
      final maxQtyError = validateQuantity(maxOrderQuantity, isRequired: false, fieldName: 'Maximum order quantity');
      if (maxQtyError != null) errors.add(maxQtyError);
    }
    
    final rangeError = validateQuantityRange(minOrderQuantity, maxOrderQuantity);
    if (rangeError != null) errors.add(rangeError);
    
    if (bulkPrice != null && bulkPrice.trim().isNotEmpty) {
      final basePriceValue = double.tryParse(basePrice) ?? 0.0;
      final bulkError = validateBulkPricing(bulkPrice, bulkMinQuantity, basePriceValue);
      if (bulkError != null) errors.add(bulkError);
    }
    
    return errors;
  }
}
