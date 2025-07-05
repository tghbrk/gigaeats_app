import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/enhanced_menu_repository.dart';
import '../../data/services/enhanced_menu_service.dart';
import '../../data/models/advanced_pricing.dart';
import '../../data/models/menu_organization.dart';

// ==================== REPOSITORY PROVIDERS ====================

/// Enhanced menu repository provider
final enhancedMenuRepositoryProvider = Provider<EnhancedMenuRepository>((ref) {
  return EnhancedMenuRepository();
});

/// Enhanced menu service provider
final enhancedMenuServiceProvider = Provider<EnhancedMenuService>((ref) {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return EnhancedMenuService(repository);
});

// ==================== ADVANCED PRICING PROVIDERS ====================

/// Advanced pricing configuration provider for a menu item
final advancedPricingConfigProvider = FutureProvider.family<AdvancedPricingConfig, String>((ref, menuItemId) async {
  final service = ref.watch(enhancedMenuServiceProvider);
  return service.getAdvancedPricingConfig(menuItemId);
});

/// Enhanced bulk pricing tiers provider
final enhancedBulkPricingTiersProvider = FutureProvider.family<List<EnhancedBulkPricingTier>, String>((ref, menuItemId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getEnhancedBulkPricingTiers(menuItemId);
});

/// Promotional pricing provider
final promotionalPricingProvider = FutureProvider.family<List<PromotionalPricing>, String>((ref, menuItemId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getPromotionalPricing(menuItemId);
});

/// Time-based pricing rules provider
final timeBasedPricingRulesProvider = FutureProvider.family<List<TimeBasedPricingRule>, String>((ref, menuItemId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getTimeBasedPricingRules(menuItemId);
});

/// Pricing calculation provider
final pricingCalculationProvider = FutureProvider.family<PricingCalculationResult, PricingCalculationParams>((ref, params) async {
  final service = ref.watch(enhancedMenuServiceProvider);
  return service.calculateEffectivePrice(
    params.menuItemId,
    params.quantity,
    orderTime: params.orderTime,
    customerContext: params.customerContext,
  );
});

/// Pricing validation provider
final pricingValidationProvider = FutureProvider.family<List<String>, String>((ref, menuItemId) async {
  final service = ref.watch(enhancedMenuServiceProvider);
  return service.validatePricingRules(menuItemId);
});

// ==================== MENU ORGANIZATION PROVIDERS ====================

/// Menu organization configuration provider
final menuOrganizationConfigProvider = FutureProvider.family<MenuOrganizationConfig, String>((ref, vendorId) async {
  final service = ref.watch(enhancedMenuServiceProvider);
  return service.getMenuOrganization(vendorId);
});

/// Enhanced menu categories provider
final enhancedMenuCategoriesProvider = FutureProvider.family<List<EnhancedMenuCategory>, String>((ref, vendorId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getEnhancedMenuCategories(vendorId);
});

/// Menu hierarchy provider
final menuHierarchyProvider = FutureProvider.family<List<MenuHierarchyNode>, String>((ref, vendorId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getMenuHierarchy(vendorId);
});

/// Menu item positions provider
final menuItemPositionsProvider = FutureProvider.family<List<MenuItemPosition>, String>((ref, categoryId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getMenuItemPositions(categoryId);
});

// ==================== CUSTOMIZATION PROVIDERS ====================

/// Enhanced menu item with customizations provider
final enhancedMenuItemWithCustomizationsProvider = FutureProvider.family<Map<String, dynamic>?, String>((ref, menuItemId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getEnhancedMenuItemWithCustomizations(menuItemId);
});

/// Customization templates provider
final customizationTemplatesProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, vendorId) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.getCustomizationTemplates(vendorId);
});

/// Customization price calculation provider
final customizationPriceCalculationProvider = FutureProvider.family<Map<String, dynamic>, CustomizationPriceParams>((ref, params) async {
  final repository = ref.watch(enhancedMenuRepositoryProvider);
  return repository.calculateCustomizationPrice(
    params.customizationId,
    params.selectedOptions,
    quantity: params.quantity,
  );
});

// ==================== ANALYTICS PROVIDERS ====================

/// Menu performance dashboard provider
final menuPerformanceDashboardProvider = FutureProvider.family<Map<String, dynamic>, MenuPerformanceParams>((ref, params) async {
  final service = ref.watch(enhancedMenuServiceProvider);
  return service.getMenuPerformanceDashboard(
    params.vendorId,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

// ==================== STATE NOTIFIER PROVIDERS ====================

/// Advanced pricing configuration state notifier
final advancedPricingConfigNotifierProvider = StateNotifierProvider.family<AdvancedPricingConfigNotifier, AsyncValue<AdvancedPricingConfig>, String>((ref, menuItemId) {
  final service = ref.watch(enhancedMenuServiceProvider);
  return AdvancedPricingConfigNotifier(service, menuItemId);
});

/// Menu organization state notifier
final menuOrganizationNotifierProvider = StateNotifierProvider.family<MenuOrganizationNotifier, AsyncValue<MenuOrganizationConfig>, String>((ref, vendorId) {
  final service = ref.watch(enhancedMenuServiceProvider);
  return MenuOrganizationNotifier(service, vendorId);
});

// ==================== PARAMETER CLASSES ====================

/// Parameters for pricing calculation
class PricingCalculationParams {
  final String menuItemId;
  final int quantity;
  final DateTime? orderTime;
  final Map<String, dynamic>? customerContext;

  const PricingCalculationParams({
    required this.menuItemId,
    required this.quantity,
    this.orderTime,
    this.customerContext,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PricingCalculationParams &&
          runtimeType == other.runtimeType &&
          menuItemId == other.menuItemId &&
          quantity == other.quantity &&
          orderTime == other.orderTime;

  @override
  int get hashCode => Object.hash(menuItemId, quantity, orderTime);
}

/// Parameters for customization price calculation
class CustomizationPriceParams {
  final String customizationId;
  final List<Map<String, dynamic>> selectedOptions;
  final int quantity;

  const CustomizationPriceParams({
    required this.customizationId,
    required this.selectedOptions,
    this.quantity = 1,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomizationPriceParams &&
          runtimeType == other.runtimeType &&
          customizationId == other.customizationId &&
          quantity == other.quantity;

  @override
  int get hashCode => Object.hash(customizationId, selectedOptions, quantity);
}

/// Parameters for menu performance dashboard
class MenuPerformanceParams {
  final String vendorId;
  final DateTime? startDate;
  final DateTime? endDate;

  const MenuPerformanceParams({
    required this.vendorId,
    this.startDate,
    this.endDate,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MenuPerformanceParams &&
          runtimeType == other.runtimeType &&
          vendorId == other.vendorId &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(vendorId, startDate, endDate);
}

// ==================== STATE NOTIFIERS ====================

/// State notifier for advanced pricing configuration
class AdvancedPricingConfigNotifier extends StateNotifier<AsyncValue<AdvancedPricingConfig>> {
  final EnhancedMenuService _service;
  final String _menuItemId;

  AdvancedPricingConfigNotifier(this._service, this._menuItemId) : super(const AsyncValue.loading()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    try {
      final config = await _service.getAdvancedPricingConfig(_menuItemId);
      state = AsyncValue.data(config);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveConfig(AdvancedPricingConfig config) async {
    state = const AsyncValue.loading();
    try {
      final savedConfig = await _service.saveAdvancedPricingConfig(_menuItemId, config);
      state = AsyncValue.data(savedConfig);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadConfig();
  }
}

/// State notifier for menu organization
class MenuOrganizationNotifier extends StateNotifier<AsyncValue<MenuOrganizationConfig>> {
  final EnhancedMenuService _service;
  final String _vendorId;

  MenuOrganizationNotifier(this._service, this._vendorId) : super(const AsyncValue.loading()) {
    _loadOrganization();
  }

  Future<void> _loadOrganization() async {
    try {
      final config = await _service.getMenuOrganization(_vendorId);
      state = AsyncValue.data(config);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> saveOrganization(MenuOrganizationConfig config) async {
    state = const AsyncValue.loading();
    try {
      final savedConfig = await _service.saveMenuOrganization(_vendorId, config);
      state = AsyncValue.data(savedConfig);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reorderCategories(List<String> categoryIds) async {
    try {
      await _service.reorderCategories(_vendorId, categoryIds);
      await _loadOrganization(); // Refresh after reorder
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> reorderMenuItems(String categoryId, List<String> menuItemIds) async {
    try {
      await _service.reorderMenuItems(_vendorId, categoryId, menuItemIds);
      await _loadOrganization(); // Refresh after reorder
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateItemBadges(String menuItemId, String categoryId, Map<String, bool> badges) async {
    try {
      await _service.updateItemBadges(_vendorId, menuItemId, categoryId, badges);
      await _loadOrganization(); // Refresh after update
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> refresh() async {
    await _loadOrganization();
  }
}
