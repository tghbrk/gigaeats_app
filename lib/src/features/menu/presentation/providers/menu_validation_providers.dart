import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/validation/menu_validation_service.dart';
import '../../data/models/menu_item.dart';
import '../../data/models/advanced_pricing.dart';
import '../../data/models/menu_organization.dart';

// ==================== VALIDATION SERVICE PROVIDER ====================

/// Menu validation service provider
final menuValidationServiceProvider = Provider<MenuValidationService>((ref) {
  return MenuValidationService();
});

// ==================== VALIDATION RESULT PROVIDERS ====================

/// Menu item validation provider
final menuItemValidationProvider = Provider.family<MenuValidationResult, MenuItem>((ref, menuItem) {
  final validationService = ref.watch(menuValidationServiceProvider);
  return validationService.validateMenuItem(menuItem);
});

/// Advanced pricing validation provider
final advancedPricingValidationProvider = Provider.family<MenuValidationResult, AdvancedPricingConfig>((ref, config) {
  final validationService = ref.watch(menuValidationServiceProvider);
  return validationService.validateAdvancedPricing(config);
});

/// Menu organization validation provider
final menuOrganizationValidationProvider = Provider.family<MenuValidationResult, MenuOrganizationConfig>((ref, config) {
  final validationService = ref.watch(menuValidationServiceProvider);
  return validationService.validateMenuOrganization(config);
});

/// Customizations validation provider
final customizationsValidationProvider = Provider.family<MenuValidationResult, List<MenuItemCustomization>>((ref, customizations) {
  final validationService = ref.watch(menuValidationServiceProvider);
  return validationService.validateCustomizations(customizations);
});

// ==================== FORM VALIDATION STATE NOTIFIERS ====================

/// Menu item form validation state notifier
final menuItemFormValidationProvider = StateNotifierProvider.autoDispose<MenuItemFormValidationNotifier, MenuItemFormValidationState>((ref) {
  final validationService = ref.watch(menuValidationServiceProvider);
  return MenuItemFormValidationNotifier(validationService);
});

class MenuItemFormValidationNotifier extends StateNotifier<MenuItemFormValidationState> {
  final MenuValidationService _validationService;

  MenuItemFormValidationNotifier(this._validationService) : super(const MenuItemFormValidationState());

  /// Validate menu item and update state
  void validateMenuItem(MenuItem menuItem) {
    final result = _validationService.validateMenuItem(menuItem);
    state = state.copyWith(
      validationResult: result,
      isValidating: false,
      lastValidated: DateTime.now(),
    );
  }

  /// Validate specific field
  void validateField(String fieldName, dynamic value, MenuItem menuItem) {
    state = state.copyWith(isValidating: true);
    
    // Create a copy of the menu item with the updated field
    final updatedMenuItem = _updateMenuItemField(menuItem, fieldName, value);
    
    // Validate the updated menu item
    final result = _validationService.validateMenuItem(updatedMenuItem);
    
    state = state.copyWith(
      validationResult: result,
      isValidating: false,
      lastValidatedField: fieldName,
      lastValidated: DateTime.now(),
    );
  }

  /// Clear validation state
  void clearValidation() {
    state = const MenuItemFormValidationState();
  }

  /// Set validation as loading
  void setValidating(bool isValidating) {
    state = state.copyWith(isValidating: isValidating);
  }

  MenuItem _updateMenuItemField(MenuItem menuItem, String fieldName, dynamic value) {
    switch (fieldName) {
      case 'name':
        return menuItem.copyWith(name: value as String);
      case 'description':
        return menuItem.copyWith(description: value as String);
      case 'basePrice':
        return menuItem.copyWith(basePrice: value as double);
      case 'category':
        return menuItem.copyWith(category: value as String);
      case 'availableQuantity':
        return menuItem.copyWith(availableQuantity: value as int?);
      case 'preparationTimeMinutes':
        return menuItem.copyWith(preparationTimeMinutes: value as int?);
      case 'status':
        return menuItem.copyWith(status: value as MenuItemStatus?);
      case 'isHalalCertified':
        return menuItem.copyWith(isHalalCertified: value as bool);
      case 'dietaryTypes':
        return menuItem.copyWith(dietaryTypes: value as List<DietaryType>);
      case 'allergens':
        return menuItem.copyWith(allergens: value as List<String>);
      case 'imageUrls':
        return menuItem.copyWith(imageUrls: value as List<String>);
      default:
        return menuItem;
    }
  }
}

/// Advanced pricing form validation state notifier
final advancedPricingFormValidationProvider = StateNotifierProvider.autoDispose<AdvancedPricingFormValidationNotifier, AdvancedPricingFormValidationState>((ref) {
  final validationService = ref.watch(menuValidationServiceProvider);
  return AdvancedPricingFormValidationNotifier(validationService);
});

class AdvancedPricingFormValidationNotifier extends StateNotifier<AdvancedPricingFormValidationState> {
  final MenuValidationService _validationService;

  AdvancedPricingFormValidationNotifier(this._validationService) : super(const AdvancedPricingFormValidationState());

  /// Validate advanced pricing configuration
  void validatePricingConfig(AdvancedPricingConfig config) {
    state = state.copyWith(isValidating: true);
    
    final result = _validationService.validateAdvancedPricing(config);
    
    state = state.copyWith(
      validationResult: result,
      isValidating: false,
      lastValidated: DateTime.now(),
    );
  }

  /// Validate bulk pricing tiers
  void validateBulkPricingTiers(List<EnhancedBulkPricingTier> tiers, double basePrice) {
    state = state.copyWith(isValidating: true);
    
    // Create a minimal config for validation
    final config = AdvancedPricingConfig(
      menuItemId: 'temp',
      basePrice: basePrice,
      bulkPricingTiers: tiers,
      promotionalPricing: [],
      timeBasedRules: [],
      enableDynamicPricing: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final result = _validationService.validateAdvancedPricing(config);
    
    state = state.copyWith(
      validationResult: result,
      isValidating: false,
      lastValidatedSection: 'bulk_pricing',
      lastValidated: DateTime.now(),
    );
  }

  /// Validate promotional pricing
  void validatePromotionalPricing(List<PromotionalPricing> promotions, double basePrice) {
    state = state.copyWith(isValidating: true);
    
    final config = AdvancedPricingConfig(
      menuItemId: 'temp',
      basePrice: basePrice,
      bulkPricingTiers: [],
      promotionalPricing: promotions,
      timeBasedRules: [],
      enableDynamicPricing: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    final result = _validationService.validateAdvancedPricing(config);
    
    state = state.copyWith(
      validationResult: result,
      isValidating: false,
      lastValidatedSection: 'promotional_pricing',
      lastValidated: DateTime.now(),
    );
  }

  /// Clear validation state
  void clearValidation() {
    state = const AdvancedPricingFormValidationState();
  }
}

/// Menu organization form validation state notifier
final menuOrganizationFormValidationProvider = StateNotifierProvider.autoDispose<MenuOrganizationFormValidationNotifier, MenuOrganizationFormValidationState>((ref) {
  final validationService = ref.watch(menuValidationServiceProvider);
  return MenuOrganizationFormValidationNotifier(validationService);
});

class MenuOrganizationFormValidationNotifier extends StateNotifier<MenuOrganizationFormValidationState> {
  final MenuValidationService _validationService;

  MenuOrganizationFormValidationNotifier(this._validationService) : super(const MenuOrganizationFormValidationState());

  /// Validate menu organization configuration
  void validateOrganizationConfig(MenuOrganizationConfig config) {
    state = state.copyWith(isValidating: true);
    
    final result = _validationService.validateMenuOrganization(config);
    
    state = state.copyWith(
      validationResult: result,
      isValidating: false,
      lastValidated: DateTime.now(),
    );
  }

  /// Validate categories
  void validateCategories(List<EnhancedMenuCategory> categories) {
    state = state.copyWith(isValidating: true);
    
    // Create a minimal config for validation
    final config = MenuOrganizationConfig(
      vendorId: 'temp',
      categories: categories,
      itemPositions: [],
      displayStyle: MenuDisplayStyle.grid,
      enableCategoryImages: true,
      enableSubcategories: false,
      enableDragAndDrop: true,
      showItemCounts: true,
      groupByAvailability: false,
      updatedAt: DateTime.now(),
    );
    
    final result = _validationService.validateMenuOrganization(config);
    
    state = state.copyWith(
      validationResult: result,
      isValidating: false,
      lastValidatedSection: 'categories',
      lastValidated: DateTime.now(),
    );
  }

  /// Clear validation state
  void clearValidation() {
    state = const MenuOrganizationFormValidationState();
  }
}

// ==================== VALIDATION STATE MODELS ====================

/// Menu item form validation state
class MenuItemFormValidationState {
  final MenuValidationResult? validationResult;
  final bool isValidating;
  final String? lastValidatedField;
  final DateTime? lastValidated;

  const MenuItemFormValidationState({
    this.validationResult,
    this.isValidating = false,
    this.lastValidatedField,
    this.lastValidated,
  });

  MenuItemFormValidationState copyWith({
    MenuValidationResult? validationResult,
    bool? isValidating,
    String? lastValidatedField,
    DateTime? lastValidated,
  }) {
    return MenuItemFormValidationState(
      validationResult: validationResult ?? this.validationResult,
      isValidating: isValidating ?? this.isValidating,
      lastValidatedField: lastValidatedField ?? this.lastValidatedField,
      lastValidated: lastValidated ?? this.lastValidated,
    );
  }

  bool get isValid => validationResult?.isValid ?? true;
  bool get hasErrors => validationResult != null && !validationResult!.isValid;
  bool get hasWarnings => validationResult?.warnings.isNotEmpty ?? false;
}

/// Advanced pricing form validation state
class AdvancedPricingFormValidationState {
  final MenuValidationResult? validationResult;
  final bool isValidating;
  final String? lastValidatedSection;
  final DateTime? lastValidated;

  const AdvancedPricingFormValidationState({
    this.validationResult,
    this.isValidating = false,
    this.lastValidatedSection,
    this.lastValidated,
  });

  AdvancedPricingFormValidationState copyWith({
    MenuValidationResult? validationResult,
    bool? isValidating,
    String? lastValidatedSection,
    DateTime? lastValidated,
  }) {
    return AdvancedPricingFormValidationState(
      validationResult: validationResult ?? this.validationResult,
      isValidating: isValidating ?? this.isValidating,
      lastValidatedSection: lastValidatedSection ?? this.lastValidatedSection,
      lastValidated: lastValidated ?? this.lastValidated,
    );
  }

  bool get isValid => validationResult?.isValid ?? true;
  bool get hasErrors => validationResult != null && !validationResult!.isValid;
  bool get hasWarnings => validationResult?.warnings.isNotEmpty ?? false;
}

/// Menu organization form validation state
class MenuOrganizationFormValidationState {
  final MenuValidationResult? validationResult;
  final bool isValidating;
  final String? lastValidatedSection;
  final DateTime? lastValidated;

  const MenuOrganizationFormValidationState({
    this.validationResult,
    this.isValidating = false,
    this.lastValidatedSection,
    this.lastValidated,
  });

  MenuOrganizationFormValidationState copyWith({
    MenuValidationResult? validationResult,
    bool? isValidating,
    String? lastValidatedSection,
    DateTime? lastValidated,
  }) {
    return MenuOrganizationFormValidationState(
      validationResult: validationResult ?? this.validationResult,
      isValidating: isValidating ?? this.isValidating,
      lastValidatedSection: lastValidatedSection ?? this.lastValidatedSection,
      lastValidated: lastValidated ?? this.lastValidated,
    );
  }

  bool get isValid => validationResult?.isValid ?? true;
  bool get hasErrors => validationResult != null && !validationResult!.isValid;
  bool get hasWarnings => validationResult?.warnings.isNotEmpty ?? false;
}
