import '../models/menu_item.dart' as menu_item;
import '../models/advanced_pricing.dart';
import '../models/menu_organization.dart';
import '../../../../core/utils/logger.dart';

// Import specific types for validation
import '../models/menu_item.dart' show DietaryType, CustomizationOption;

// Temporary enum for validation compatibility
enum MenuItemCustomizationType {
  radio,
  checkbox,
  text,
  dropdown,
  slider,
}

/// Comprehensive validation service for menu management
/// Provides robust validation for all menu-related operations with detailed error messages
class MenuValidationService {
  final AppLogger _logger = AppLogger();

  // ==================== MENU ITEM VALIDATION ====================

  /// Validate menu item data
  MenuValidationResult validateMenuItem(menu_item.MenuItem menuItem) {
    final errors = <String, String>{};
    final warnings = <String>[];

    try {
      // Basic information validation
      _validateBasicInfo(menuItem, errors);
      
      // Pricing validation
      _validatePricing(menuItem, errors, warnings);
      
      // Dietary and allergen validation
      _validateDietaryInfo(menuItem, errors, warnings);
      
      // Image validation
      _validateImages(menuItem, errors, warnings);
      
      // Availability validation
      _validateAvailability(menuItem, errors, warnings);

      return MenuValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      _logger.error('Error validating menu item: $e');
      return MenuValidationResult(
        isValid: false,
        errors: {'general': 'Validation failed: $e'},
        warnings: warnings,
      );
    }
  }

  void _validateBasicInfo(menu_item.MenuItem menuItem, Map<String, String> errors) {
    // Name validation
    if (menuItem.name.trim().isEmpty) {
      errors['name'] = 'Menu item name is required';
    } else if (menuItem.name.trim().length < 2) {
      errors['name'] = 'Menu item name must be at least 2 characters';
    } else if (menuItem.name.trim().length > 100) {
      errors['name'] = 'Menu item name cannot exceed 100 characters';
    } else if (!_isValidMenuItemName(menuItem.name)) {
      errors['name'] = 'Menu item name contains invalid characters';
    }

    // Description validation
    if (menuItem.description.trim().isEmpty) {
      errors['description'] = 'Description is required';
    } else if (menuItem.description.trim().length < 10) {
      errors['description'] = 'Description must be at least 10 characters';
    } else if (menuItem.description.trim().length > 500) {
      errors['description'] = 'Description cannot exceed 500 characters';
    }

    // Category validation
    if (menuItem.category.trim().isEmpty) {
      errors['category'] = 'Category is required';
    }

    // Vendor ID validation
    if (menuItem.vendorId.trim().isEmpty) {
      errors['vendorId'] = 'Vendor ID is required';
    } else if (!_isValidUuid(menuItem.vendorId)) {
      errors['vendorId'] = 'Invalid vendor ID format';
    }
  }

  void _validatePricing(menu_item.MenuItem menuItem, Map<String, String> errors, List<String> warnings) {
    // Base price validation
    if (menuItem.basePrice <= 0) {
      errors['basePrice'] = 'Base price must be greater than 0';
    } else if (menuItem.basePrice > 9999.99) {
      errors['basePrice'] = 'Base price cannot exceed RM 9,999.99';
    } else if (menuItem.basePrice < 0.50) {
      warnings.add('Base price is very low (less than RM 0.50)');
    }

    // Price precision validation
    final priceString = menuItem.basePrice.toStringAsFixed(2);
    final decimalPart = priceString.split('.')[1];
    if (decimalPart.length > 2) {
      errors['basePrice'] = 'Price cannot have more than 2 decimal places';
    }
  }

  void _validateDietaryInfo(menu_item.MenuItem menuItem, Map<String, String> errors, List<String> warnings) {
    // Dietary types validation
    if (menuItem.dietaryTypes.isEmpty) {
      warnings.add('No dietary information specified');
    }

    // Halal certification validation
    if (menuItem.dietaryTypes.contains(DietaryType.halal) && !menuItem.isHalalCertified) {
      warnings.add('Item marked as halal but not certified - consider adding certification');
    }

    // Allergen validation
    if (menuItem.allergens.isNotEmpty && menuItem.allergens.length > 15) {
      warnings.add('Large number of allergens listed - please verify accuracy');
    }
  }

  void _validateImages(menu_item.MenuItem menuItem, Map<String, String> errors, List<String> warnings) {
    // Image URL validation
    if (menuItem.imageUrls.isEmpty) {
      warnings.add('No images provided - consider adding at least one image');
    } else if (menuItem.imageUrls.length > 10) {
      warnings.add('Too many images - consider limiting to 5-10 images for better performance');
    }

    // Validate each image URL
    for (int i = 0; i < menuItem.imageUrls.length; i++) {
      final url = menuItem.imageUrls[i];
      if (!_isValidImageUrl(url)) {
        errors['imageUrl_$i'] = 'Invalid image URL format';
      }
    }
  }

  void _validateAvailability(menu_item.MenuItem menuItem, Map<String, String> errors, List<String> warnings) {
    // Stock quantity validation
    if (menuItem.stockQuantity != null) {
      if (menuItem.stockQuantity! < 0) {
        errors['stockQuantity'] = 'Stock quantity cannot be negative';
      } else if (menuItem.stockQuantity! == 0 && menuItem.isAvailable) {
        warnings.add('Item is marked as available but has zero stock');
      }
    }

    // Preparation time validation
    if (menuItem.preparationTimeMinutes < 0) {
      errors['preparationTime'] = 'Preparation time cannot be negative';
    } else if (menuItem.preparationTimeMinutes > 180) {
      warnings.add('Preparation time is very long (over 3 hours)');
    }
  }

  // ==================== ADVANCED PRICING VALIDATION ====================

  /// Validate advanced pricing configuration
  MenuValidationResult validateAdvancedPricing(AdvancedPricingConfig config) {
    final errors = <String, String>{};
    final warnings = <String>[];

    try {
      // Validate bulk pricing tiers
      _validateBulkPricingTiers(config.bulkPricingTiers, config.basePrice, errors, warnings);
      
      // Validate promotional pricing
      _validatePromotionalPricing(config.promotionalPricing, config.basePrice, errors, warnings);
      
      // Validate time-based pricing rules
      _validateTimeBasedPricingRules(config.timeBasedRules, errors, warnings);
      
      // Validate price limits
      _validatePriceLimits(config, errors, warnings);

      return MenuValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      _logger.error('Error validating advanced pricing: $e');
      return MenuValidationResult(
        isValid: false,
        errors: {'general': 'Pricing validation failed: $e'},
        warnings: warnings,
      );
    }
  }

  void _validateBulkPricingTiers(
    List<EnhancedBulkPricingTier> tiers,
    double basePrice,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    if (tiers.isEmpty) return;

    // Sort tiers by minimum quantity for validation
    final sortedTiers = List<EnhancedBulkPricingTier>.from(tiers)
      ..sort((a, b) => a.minimumQuantity.compareTo(b.minimumQuantity));

    for (int i = 0; i < sortedTiers.length; i++) {
      final tier = sortedTiers[i];
      final prefix = 'bulkTier_$i';

      // Quantity validation
      if (tier.minimumQuantity <= 0) {
        errors['${prefix}_minQuantity'] = 'Minimum quantity must be greater than 0';
      }

      if (tier.maximumQuantity != null && tier.maximumQuantity! <= tier.minimumQuantity) {
        errors['${prefix}_maxQuantity'] = 'Maximum quantity must be greater than minimum quantity';
      }

      // Price validation
      if (tier.pricePerUnit <= 0) {
        errors['${prefix}_price'] = 'Price per unit must be greater than 0';
      } else if (tier.pricePerUnit >= basePrice) {
        warnings.add('Bulk tier ${i + 1} price is not lower than base price');
      }

      // Overlap validation
      if (i > 0) {
        final previousTier = sortedTiers[i - 1];
        if (previousTier.maximumQuantity == null || 
            tier.minimumQuantity <= previousTier.maximumQuantity!) {
          errors['${prefix}_overlap'] = 'Bulk tier ${i + 1} overlaps with previous tier';
        }
      }

      // Validity period validation
      if (tier.validFrom != null && tier.validUntil != null) {
        if (tier.validUntil!.isBefore(tier.validFrom!)) {
          errors['${prefix}_validity'] = 'End date must be after start date';
        }
      }
    }
  }

  void _validatePromotionalPricing(
    List<PromotionalPricing> promotions,
    double basePrice,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    for (int i = 0; i < promotions.length; i++) {
      final promotion = promotions[i];
      final prefix = 'promotion_$i';

      // Name validation
      if (promotion.name.trim().isEmpty) {
        errors['${prefix}_name'] = 'Promotion name is required';
      } else if (promotion.name.trim().length > 100) {
        errors['${prefix}_name'] = 'Promotion name cannot exceed 100 characters';
      }

      // Value validation
      if (promotion.value <= 0) {
        errors['${prefix}_value'] = 'Promotion value must be greater than 0';
      } else if (promotion.type == PromotionalPricingType.percentage && promotion.value > 100) {
        errors['${prefix}_value'] = 'Percentage discount cannot exceed 100%';
      } else if (promotion.type == PromotionalPricingType.fixedAmount && promotion.value >= basePrice) {
        warnings.add('Fixed discount for promotion ${i + 1} is greater than or equal to base price');
      }

      // Date validation
      if (promotion.validUntil.isBefore(promotion.validFrom)) {
        errors['${prefix}_dates'] = 'End date must be after start date';
      } else if (promotion.validFrom.isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
        warnings.add('Promotion ${i + 1} start date is in the past');
      }

      // Usage limit validation
      if (promotion.usageLimit != null) {
        if (promotion.usageLimit! <= 0) {
          errors['${prefix}_usageLimit'] = 'Usage limit must be greater than 0';
        } else if (promotion.currentUsage > promotion.usageLimit!) {
          errors['${prefix}_usage'] = 'Current usage exceeds usage limit';
        }
      }

      // Minimum order validation
      if (promotion.minimumOrderAmount != null && promotion.minimumOrderAmount! <= 0) {
        errors['${prefix}_minOrder'] = 'Minimum order amount must be greater than 0';
      }

      // Days validation
      if (promotion.applicableDays.isNotEmpty) {
        final validDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        for (final day in promotion.applicableDays) {
          if (!validDays.contains(day.toLowerCase())) {
            errors['${prefix}_days'] = 'Invalid day specified: $day';
          }
        }
      }

      // Time validation
      if (promotion.startTime != null && promotion.endTime != null) {
        final startMinutes = promotion.startTime!.hour * 60 + promotion.startTime!.minute;
        final endMinutes = promotion.endTime!.hour * 60 + promotion.endTime!.minute;
        
        if (endMinutes <= startMinutes) {
          errors['${prefix}_time'] = 'End time must be after start time';
        }
      }
    }

    // Check for conflicting promotions
    _validatePromotionConflicts(promotions, warnings);
  }

  void _validateTimeBasedPricingRules(
    List<TimeBasedPricingRule> rules,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    for (int i = 0; i < rules.length; i++) {
      final rule = rules[i];
      final prefix = 'timeRule_$i';

      // Name validation
      if (rule.name.trim().isEmpty) {
        errors['${prefix}_name'] = 'Rule name is required';
      }

      // Multiplier validation
      if (rule.multiplier <= 0) {
        errors['${prefix}_multiplier'] = 'Price multiplier must be greater than 0';
      } else if (rule.multiplier > 5.0) {
        warnings.add('Time rule ${i + 1} has a very high multiplier (${rule.multiplier}x)');
      }

      // Time validation
      final startMinutes = rule.startTime.hour * 60 + rule.startTime.minute;
      final endMinutes = rule.endTime.hour * 60 + rule.endTime.minute;
      
      if (endMinutes <= startMinutes) {
        errors['${prefix}_time'] = 'End time must be after start time';
      }

      // Days validation
      if (rule.applicableDays.isNotEmpty) {
        final validDays = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        for (final day in rule.applicableDays) {
          if (!validDays.contains(day.toLowerCase())) {
            errors['${prefix}_days'] = 'Invalid day specified: $day';
          }
        }
      }

      // Priority validation
      if (rule.priority < 0 || rule.priority > 10) {
        errors['${prefix}_priority'] = 'Priority must be between 0 and 10';
      }
    }

    // Check for overlapping time rules
    _validateTimeRuleConflicts(rules, warnings);
  }

  void _validatePriceLimits(
    AdvancedPricingConfig config,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    if (config.minimumPrice != null) {
      if (config.minimumPrice! <= 0) {
        errors['minimumPrice'] = 'Minimum price must be greater than 0';
      } else if (config.minimumPrice! > config.basePrice) {
        warnings.add('Minimum price is higher than base price');
      }
    }

    if (config.maximumPrice != null) {
      if (config.maximumPrice! <= 0) {
        errors['maximumPrice'] = 'Maximum price must be greater than 0';
      } else if (config.maximumPrice! < config.basePrice) {
        warnings.add('Maximum price is lower than base price');
      }
    }

    if (config.minimumPrice != null && config.maximumPrice != null) {
      if (config.maximumPrice! <= config.minimumPrice!) {
        errors['priceRange'] = 'Maximum price must be greater than minimum price';
      }
    }
  }

  void _validatePromotionConflicts(List<PromotionalPricing> promotions, List<String> warnings) {
    for (int i = 0; i < promotions.length; i++) {
      for (int j = i + 1; j < promotions.length; j++) {
        final promo1 = promotions[i];
        final promo2 = promotions[j];

        // Check date overlap
        if (!(promo1.validUntil.isBefore(promo2.validFrom) || 
              promo2.validUntil.isBefore(promo1.validFrom))) {
          
          // Check day overlap
          final days1 = promo1.applicableDays.map((d) => d.toLowerCase()).toSet();
          final days2 = promo2.applicableDays.map((d) => d.toLowerCase()).toSet();
          
          if (days1.isEmpty || days2.isEmpty || days1.intersection(days2).isNotEmpty) {
            warnings.add('Promotions "${promo1.name}" and "${promo2.name}" may conflict');
          }
        }
      }
    }
  }

  void _validateTimeRuleConflicts(List<TimeBasedPricingRule> rules, List<String> warnings) {
    for (int i = 0; i < rules.length; i++) {
      for (int j = i + 1; j < rules.length; j++) {
        final rule1 = rules[i];
        final rule2 = rules[j];

        // Check day overlap
        final days1 = rule1.applicableDays.map((d) => d.toLowerCase()).toSet();
        final days2 = rule2.applicableDays.map((d) => d.toLowerCase()).toSet();
        
        if (days1.isEmpty || days2.isEmpty || days1.intersection(days2).isNotEmpty) {
          // Check time overlap
          final start1 = rule1.startTime.hour * 60 + rule1.startTime.minute;
          final end1 = rule1.endTime.hour * 60 + rule1.endTime.minute;
          final start2 = rule2.startTime.hour * 60 + rule2.startTime.minute;
          final end2 = rule2.endTime.hour * 60 + rule2.endTime.minute;

          if (!(end1 <= start2 || end2 <= start1)) {
            warnings.add('Time rules "${rule1.name}" and "${rule2.name}" have overlapping times');
          }
        }
      }
    }
  }

  // ==================== MENU ORGANIZATION VALIDATION ====================

  /// Validate menu organization configuration
  MenuValidationResult validateMenuOrganization(MenuOrganizationConfig config) {
    final errors = <String, String>{};
    final warnings = <String>[];

    try {
      // Validate categories
      _validateCategories(config.categories, errors, warnings);

      // Validate item positions
      _validateItemPositions(config.itemPositions, errors, warnings);

      // Validate organization settings
      _validateOrganizationSettings(config, errors, warnings);

      return MenuValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      _logger.error('Error validating menu organization: $e');
      return MenuValidationResult(
        isValid: false,
        errors: {'general': 'Organization validation failed: $e'},
        warnings: warnings,
      );
    }
  }

  void _validateCategories(
    List<EnhancedMenuCategory> categories,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    if (categories.isEmpty) {
      warnings.add('No categories defined - consider organizing menu items into categories');
      return;
    }

    final categoryIds = <String>{};
    final categoryNames = <String>{};

    for (int i = 0; i < categories.length; i++) {
      final category = categories[i];
      final prefix = 'category_$i';

      // ID uniqueness validation
      if (categoryIds.contains(category.id)) {
        errors['${prefix}_id'] = 'Duplicate category ID: ${category.id}';
      } else {
        categoryIds.add(category.id);
      }

      // Name validation
      if (category.name.trim().isEmpty) {
        errors['${prefix}_name'] = 'Category name is required';
      } else if (category.name.trim().length < 2) {
        errors['${prefix}_name'] = 'Category name must be at least 2 characters';
      } else if (category.name.trim().length > 50) {
        errors['${prefix}_name'] = 'Category name cannot exceed 50 characters';
      } else if (categoryNames.contains(category.name.toLowerCase())) {
        warnings.add('Duplicate category name: ${category.name}');
      } else {
        categoryNames.add(category.name.toLowerCase());
      }

      // Description validation
      if (category.description != null && category.description!.length > 200) {
        errors['${prefix}_description'] = 'Category description cannot exceed 200 characters';
      }

      // Sort order validation
      if (category.sortOrder < 0) {
        errors['${prefix}_sortOrder'] = 'Sort order cannot be negative';
      }

      // Parent category validation
      if (category.parentCategoryId != null) {
        if (!categoryIds.contains(category.parentCategoryId)) {
          // Check if parent exists in the list (might be defined later)
          final parentExists = categories.any((cat) => cat.id == category.parentCategoryId);
          if (!parentExists) {
            errors['${prefix}_parent'] = 'Parent category not found: ${category.parentCategoryId}';
          }
        }

        // Prevent circular references
        if (category.parentCategoryId == category.id) {
          errors['${prefix}_circular'] = 'Category cannot be its own parent';
        }
      }

      // Icon validation
      if (category.iconName != null && !_isValidIconName(category.iconName!)) {
        warnings.add('Invalid icon name for category: ${category.name}');
      }

      // Image URL validation
      if (category.imageUrl != null && !_isValidImageUrl(category.imageUrl!)) {
        errors['${prefix}_image'] = 'Invalid image URL format';
      }
    }

    // Validate hierarchy depth
    _validateCategoryHierarchy(categories, errors, warnings);
  }

  void _validateItemPositions(
    List<MenuItemPosition> positions,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    final positionKeys = <String>{};

    for (int i = 0; i < positions.length; i++) {
      final position = positions[i];
      final prefix = 'position_$i';

      // Unique position validation
      final key = '${position.menuItemId}_${position.categoryId}';
      if (positionKeys.contains(key)) {
        errors['${prefix}_duplicate'] = 'Duplicate position for item in category';
      } else {
        positionKeys.add(key);
      }

      // Sort order validation
      if (position.sortOrder < 0) {
        errors['${prefix}_sortOrder'] = 'Sort order cannot be negative';
      }

      // Menu item ID validation
      if (!_isValidUuid(position.menuItemId)) {
        errors['${prefix}_menuItemId'] = 'Invalid menu item ID format';
      }

      // Category ID validation
      if (!_isValidUuid(position.categoryId)) {
        errors['${prefix}_categoryId'] = 'Invalid category ID format';
      }

      // Badge validation
      final badgeCount = [
        position.isFeatured,
        position.isRecommended,
        position.isNew,
        position.isPopular,
      ].where((badge) => badge).length;

      if (badgeCount > 2) {
        warnings.add('Item has many badges - consider limiting to 1-2 for better visual impact');
      }
    }
  }

  void _validateOrganizationSettings(
    MenuOrganizationConfig config,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    // Display style validation
    if (!MenuDisplayStyle.values.contains(config.displayStyle)) {
      errors['displayStyle'] = 'Invalid display style';
    }

    // Subcategories validation
    if (config.enableSubcategories) {
      final hasSubcategories = config.categories.any((cat) => cat.parentCategoryId != null);
      if (!hasSubcategories) {
        warnings.add('Subcategories enabled but no subcategories defined');
      }
    }

    // Category images validation
    if (config.enableCategoryImages) {
      final categoriesWithImages = config.categories.where((cat) => cat.imageUrl != null).length;
      if (categoriesWithImages == 0) {
        warnings.add('Category images enabled but no categories have images');
      }
    }
  }

  void _validateCategoryHierarchy(
    List<EnhancedMenuCategory> categories,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    // Build hierarchy map
    final hierarchyMap = <String, List<String>>{};
    for (final category in categories) {
      if (category.parentCategoryId != null) {
        hierarchyMap.putIfAbsent(category.parentCategoryId!, () => []).add(category.id);
      }
    }

    // Check for circular references
    for (final category in categories) {
      if (_hasCircularReference(category.id, hierarchyMap, <String>{})) {
        errors['hierarchy_circular'] = 'Circular reference detected in category hierarchy';
        break;
      }
    }

    // Check hierarchy depth
    int maxDepth = 0;
    for (final category in categories) {
      if (category.parentCategoryId == null) {
        final depth = _calculateCategoryDepth(category.id, hierarchyMap);
        maxDepth = depth > maxDepth ? depth : maxDepth;
      }
    }

    if (maxDepth > 3) {
      warnings.add('Category hierarchy is very deep ($maxDepth levels) - consider flattening for better UX');
    }
  }

  // ==================== CUSTOMIZATION VALIDATION ====================

  /// Validate menu item customizations
  MenuValidationResult validateCustomizations(List<menu_item.MenuItemCustomization> customizations) {
    final errors = <String, String>{};
    final warnings = <String>[];

    try {
      for (int i = 0; i < customizations.length; i++) {
        final customization = customizations[i];
        final prefix = 'customization_$i';

        // Name validation
        if (customization.name.trim().isEmpty) {
          errors['${prefix}_name'] = 'Customization name is required';
        } else if (customization.name.trim().length > 100) {
          errors['${prefix}_name'] = 'Customization name cannot exceed 100 characters';
        }

        // Type validation - check if type is one of the valid string values
        final validTypes = ['radio', 'checkbox', 'text', 'dropdown', 'slider', 'single', 'multiple'];
        if (!validTypes.contains(customization.type)) {
          errors['${prefix}_type'] = 'Invalid customization type. Must be one of: ${validTypes.join(', ')}';
        }

        // Note: minSelections and maxSelections properties don't exist in current MenuItemCustomization model
        // Selection limits validation is commented out for compatibility

        // Basic required validation
        if (customization.isRequired && customization.options.isEmpty) {
          warnings.add('Customization "${customization.name}" is required but has no options');
        }

        // Options validation
        _validateCustomizationOptions(customization.options, prefix, errors, warnings);

        // Pricing validation
        _validateCustomizationPricing(customization, prefix, errors, warnings);
      }

      return MenuValidationResult(
        isValid: errors.isEmpty,
        errors: errors,
        warnings: warnings,
      );
    } catch (e) {
      _logger.error('Error validating customizations: $e');
      return MenuValidationResult(
        isValid: false,
        errors: {'general': 'Customization validation failed: $e'},
        warnings: warnings,
      );
    }
  }

  void _validateCustomizationOptions(
    List<CustomizationOption> options,
    String prefix,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    if (options.isEmpty) {
      errors['${prefix}_options'] = 'At least one customization option is required';
      return;
    }

    final optionNames = <String>{};

    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      final optionPrefix = '${prefix}_option_$i';

      // Name validation
      if (option.name.trim().isEmpty) {
        errors['${optionPrefix}_name'] = 'Option name is required';
      } else if (option.name.trim().length > 50) {
        errors['${optionPrefix}_name'] = 'Option name cannot exceed 50 characters';
      } else if (optionNames.contains(option.name.toLowerCase())) {
        errors['${optionPrefix}_name'] = 'Duplicate option name: ${option.name}';
      } else {
        optionNames.add(option.name.toLowerCase());
      }

      // Price validation
      if (option.additionalCost < 0) {
        errors['${optionPrefix}_price'] = 'Additional price cannot be negative';
      } else if (option.additionalCost > 999.99) {
        errors['${optionPrefix}_price'] = 'Additional price cannot exceed RM 999.99';
      }

      // Note: stockQuantity and isAvailable properties don't exist in current CustomizationOption model
      // These validations are commented out for compatibility

      // Default option validation
      // Note: isAvailable property doesn't exist, so we skip this validation
      // if (!option.isAvailable && option.isDefault) {
      //   warnings.add('Option "${option.name}" is set as default but not available');
      // }

      // Note: imageUrl property doesn't exist in current CustomizationOption model
      // Image validation is commented out for compatibility
      // if (option.imageUrl != null && !_isValidImageUrl(option.imageUrl!)) {
      //   errors['${optionPrefix}_image'] = 'Invalid image URL format';
      // }
    }

    // Default option validation
    final defaultOptions = options.where((opt) => opt.isDefault).length;
    if (defaultOptions == 0) {
      warnings.add('No default option specified - consider setting a default');
    } else if (defaultOptions > 1) {
      warnings.add('Multiple default options specified - only one should be default');
    }

    // Note: isAvailable property doesn't exist in current CustomizationOption model
    // Available options validation is commented out for compatibility
    // final availableOptions = options.where((opt) => opt.isAvailable).length;
    // if (availableOptions == 0) {
    //   errors['${prefix}_availability'] = 'At least one option must be available';
    // }

    // Basic validation - ensure at least one option exists
    if (options.isEmpty) {
      warnings.add('No customization options provided');
    }
  }

  void _validateCustomizationPricing(
    menu_item.MenuItemCustomization customization,
    String prefix,
    Map<String, String> errors,
    List<String> warnings,
  ) {
    // Note: Current MenuItemCustomization model doesn't have pricing-specific properties
    // This validation is simplified for compatibility with the current model structure

    // Basic validation using additionalCost from the customization
    if (customization.additionalCost != null) {
      if (customization.additionalCost! < 0) {
        errors['${prefix}_additionalCost'] = 'Additional cost cannot be negative';
      } else if (customization.additionalCost! > 999.99) {
        errors['${prefix}_additionalCost'] = 'Additional cost cannot exceed RM 999.99';
      }
    }

    // Validate options pricing
    for (int i = 0; i < customization.options.length; i++) {
      final option = customization.options[i];
      if (option.additionalCost < 0) {
        errors['${prefix}_option_${i}_cost'] = 'Option additional cost cannot be negative';
      }
    }
  }

  // ==================== UTILITY METHODS ====================

  bool _isValidMenuItemName(String name) {
    // Simple validation - just check for basic characters
    return name.trim().isNotEmpty && name.length <= 100;
  }

  bool _isValidUuid(String uuid) {
    final regex = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$');
    return regex.hasMatch(uuid);
  }

  bool _isValidImageUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  bool _isValidIconName(String iconName) {
    // List of valid Material Design icon names for categories
    final validIcons = [
      'rice_bowl', 'ramen_dining', 'local_drink', 'cake', 'restaurant',
      'dinner_dining', 'eco', 'set_meal', 'restaurant_menu', 'fastfood',
      'local_pizza', 'local_cafe', 'icecream', 'breakfast_dining'
    ];
    return validIcons.contains(iconName);
  }

  bool _hasCircularReference(String categoryId, Map<String, List<String>> hierarchyMap, Set<String> visited) {
    if (visited.contains(categoryId)) {
      return true;
    }

    visited.add(categoryId);
    final children = hierarchyMap[categoryId] ?? [];

    for (final childId in children) {
      if (_hasCircularReference(childId, hierarchyMap, visited)) {
        return true;
      }
    }

    visited.remove(categoryId);
    return false;
  }

  int _calculateCategoryDepth(String categoryId, Map<String, List<String>> hierarchyMap) {
    final children = hierarchyMap[categoryId] ?? [];
    if (children.isEmpty) {
      return 1;
    }

    int maxChildDepth = 0;
    for (final childId in children) {
      final childDepth = _calculateCategoryDepth(childId, hierarchyMap);
      maxChildDepth = childDepth > maxChildDepth ? childDepth : maxChildDepth;
    }

    return maxChildDepth + 1;
  }
}

/// Result of menu validation
class MenuValidationResult {
  final bool isValid;
  final Map<String, String> errors;
  final List<String> warnings;

  const MenuValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  /// Get error message for a specific field
  String? getFieldError(String fieldName) => errors[fieldName];

  /// Check if a specific field has an error
  bool hasFieldError(String fieldName) => errors.containsKey(fieldName);

  /// Get all error messages
  List<String> get allErrors => errors.values.toList();

  /// Get summary of validation result
  String get summary {
    if (isValid) {
      return warnings.isEmpty 
          ? 'Validation passed'
          : 'Validation passed with ${warnings.length} warning(s)';
    } else {
      return 'Validation failed with ${errors.length} error(s)';
    }
  }

  @override
  String toString() {
    return 'MenuValidationResult(isValid: $isValid, errors: ${errors.length}, warnings: ${warnings.length})';
  }
}
