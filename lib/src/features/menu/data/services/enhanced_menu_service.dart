import '../models/advanced_pricing.dart';
import '../models/menu_organization.dart';
import '../repositories/enhanced_menu_repository.dart';
import '../../../../core/errors/menu_exceptions.dart';
import '../../../../core/utils/logger.dart';

/// Enhanced menu service providing high-level business logic for menu management
class EnhancedMenuService {
  final EnhancedMenuRepository _repository;
  final AppLogger _logger = AppLogger();

  EnhancedMenuService(this._repository);

  // ==================== ADVANCED PRICING SERVICES ====================

  /// Get complete pricing configuration for a menu item
  Future<AdvancedPricingConfig> getAdvancedPricingConfig(String menuItemId) async {
    try {
      _logger.info('Getting advanced pricing config for item: $menuItemId');

      // Get base menu item
      final menuItem = await _repository.getMenuItemById(menuItemId);
      if (menuItem == null) {
        throw MenuExceptionFactory.notFound('Menu item', menuItemId);
      }

      // Get all pricing components
      final bulkTiers = await _repository.getEnhancedBulkPricingTiers(menuItemId);
      final promotions = await _repository.getPromotionalPricing(menuItemId);
      final timeRules = await _repository.getTimeBasedPricingRules(menuItemId);

      return AdvancedPricingConfig(
        menuItemId: menuItemId,
        basePrice: menuItem.basePrice,
        bulkPricingTiers: bulkTiers,
        promotionalPricing: promotions,
        timeBasedRules: timeRules,
        enableDynamicPricing: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Failed to get advanced pricing config: $e');
      throw MenuExceptionFactory.fromError(e, context: 'Get pricing config');
    }
  }

  /// Save complete pricing configuration
  Future<AdvancedPricingConfig> saveAdvancedPricingConfig(
    String menuItemId,
    AdvancedPricingConfig config,
  ) async {
    try {
      _logger.info('Saving advanced pricing config for item: $menuItemId');

      // Validate pricing configuration
      _validatePricingConfig(config);

      // Save bulk pricing tiers
      final savedBulkTiers = <EnhancedBulkPricingTier>[];
      for (final tier in config.bulkPricingTiers) {
        final savedTier = await _repository.saveEnhancedBulkPricingTier(menuItemId, tier);
        savedBulkTiers.add(savedTier);
      }

      // Save promotional pricing
      final savedPromotions = <PromotionalPricing>[];
      for (final promotion in config.promotionalPricing) {
        final savedPromotion = await _repository.savePromotionalPricing(menuItemId, promotion);
        savedPromotions.add(savedPromotion);
      }

      // Return updated configuration
      return config.copyWith(
        bulkPricingTiers: savedBulkTiers,
        promotionalPricing: savedPromotions,
        updatedAt: DateTime.now(),
      );
    } catch (e) {
      _logger.error('Failed to save advanced pricing config: $e');
      throw MenuExceptionFactory.fromError(e, context: 'Save pricing config');
    }
  }

  /// Calculate effective price with detailed breakdown
  Future<PricingCalculationResult> calculateEffectivePrice(
    String menuItemId,
    int quantity, {
    DateTime? orderTime,
    Map<String, dynamic>? customerContext,
  }) async {
    try {
      _logger.info('Calculating effective price for item: $menuItemId, quantity: $quantity');

      // Validate inputs
      if (quantity <= 0) {
        throw MenuValidationException('Quantity must be greater than 0');
      }

      // Calculate price using database function
      var result = await _repository.calculateEffectivePrice(
        menuItemId,
        quantity,
        orderTime: orderTime,
      );

      // Add customer-specific adjustments if needed
      if (customerContext != null) {
        result = _applyCustomerSpecificAdjustments(result, customerContext);
      }

      _logger.info('Price calculation completed: ${result.totalPrice}');
      return result;
    } catch (e) {
      _logger.error('Failed to calculate effective price: $e');
      throw MenuExceptionFactory.pricingError(e.toString());
    }
  }

  /// Validate pricing rules for conflicts
  Future<List<String>> validatePricingRules(String menuItemId) async {
    try {
      final warnings = <String>[];
      
      // Get all pricing components
      final bulkTiers = await _repository.getEnhancedBulkPricingTiers(menuItemId);
      final promotions = await _repository.getPromotionalPricing(menuItemId);
      final timeRules = await _repository.getTimeBasedPricingRules(menuItemId);

      // Check for overlapping bulk tiers
      for (int i = 0; i < bulkTiers.length; i++) {
        for (int j = i + 1; j < bulkTiers.length; j++) {
          if (_bulkTiersOverlap(bulkTiers[i], bulkTiers[j])) {
            warnings.add('Bulk pricing tiers ${i + 1} and ${j + 1} have overlapping quantity ranges');
          }
        }
      }

      // Check for conflicting promotions
      for (int i = 0; i < promotions.length; i++) {
        for (int j = i + 1; j < promotions.length; j++) {
          if (_promotionsConflict(promotions[i], promotions[j])) {
            warnings.add('Promotions "${promotions[i].name}" and "${promotions[j].name}" may conflict');
          }
        }
      }

      // Check for extreme price variations
      if (timeRules.isNotEmpty) {
        final multipliers = timeRules.map((rule) => rule.multiplier).toList();
        final maxMultiplier = multipliers.reduce((a, b) => a > b ? a : b);
        final minMultiplier = multipliers.reduce((a, b) => a < b ? a : b);
        
        if (maxMultiplier / minMultiplier > 2.0) {
          warnings.add('Large price variation detected between time-based rules');
        }
      }

      return warnings;
    } catch (e) {
      _logger.error('Failed to validate pricing rules: $e');
      return ['Error validating pricing rules: $e'];
    }
  }

  // ==================== MENU ORGANIZATION SERVICES ====================

  /// Get complete menu organization for a vendor
  Future<MenuOrganizationConfig> getMenuOrganization(String vendorId) async {
    try {
      _logger.info('Getting menu organization for vendor: $vendorId');

      final config = await _repository.getMenuOrganizationConfig(vendorId);
      if (config != null) {
        return config;
      }

      // Create default configuration if none exists
      return _createDefaultOrganizationConfig(vendorId);
    } catch (e) {
      _logger.error('Failed to get menu organization: $e');
      throw MenuExceptionFactory.organizationError(e.toString());
    }
  }

  /// Save menu organization configuration
  Future<MenuOrganizationConfig> saveMenuOrganization(
    String vendorId,
    MenuOrganizationConfig config,
  ) async {
    try {
      _logger.info('Saving menu organization for vendor: $vendorId');

      // Validate organization configuration
      _validateOrganizationConfig(config);

      // Save configuration
      final savedConfig = await _repository.saveMenuOrganizationConfig(vendorId, config);

      _logger.info('Menu organization saved successfully');
      return savedConfig;
    } catch (e) {
      _logger.error('Failed to save menu organization: $e');
      throw MenuExceptionFactory.organizationError(e.toString());
    }
  }

  /// Reorder categories with validation
  Future<bool> reorderCategories(
    String vendorId,
    List<String> categoryIds,
  ) async {
    try {
      _logger.info('Reordering categories for vendor: $vendorId');

      // Validate category ownership
      final categories = await _repository.getEnhancedMenuCategories(vendorId);
      final ownedCategoryIds = categories.map((c) => c.id).toSet();
      
      for (final categoryId in categoryIds) {
        if (!ownedCategoryIds.contains(categoryId)) {
          throw MenuUnauthorizedException('Category not owned by vendor: $categoryId');
        }
      }

      // Create reorder data
      final categoryOrders = categoryIds.asMap().entries.map((entry) => {
        'category_id': entry.value,
        'sort_order': entry.key,
      }).toList();

      // Execute reorder
      final success = await _repository.reorderCategories(vendorId, categoryOrders);

      if (success) {
        _logger.info('Categories reordered successfully');
      }

      return success;
    } catch (e) {
      _logger.error('Failed to reorder categories: $e');
      throw MenuExceptionFactory.organizationError(e.toString());
    }
  }

  /// Reorder menu items within a category
  Future<bool> reorderMenuItems(
    String vendorId,
    String categoryId,
    List<String> menuItemIds,
  ) async {
    try {
      _logger.info('Reordering menu items in category: $categoryId');

      // Create reorder data
      final itemOrders = menuItemIds.asMap().entries.map((entry) => {
        'menu_item_id': entry.value,
        'sort_order': entry.key,
      }).toList();

      // Execute reorder
      final success = await _repository.reorderMenuItems(vendorId, categoryId, itemOrders);

      if (success) {
        _logger.info('Menu items reordered successfully');
      }

      return success;
    } catch (e) {
      _logger.error('Failed to reorder menu items: $e');
      throw MenuExceptionFactory.organizationError(e.toString());
    }
  }

  /// Update item badges (featured, recommended, etc.)
  Future<bool> updateItemBadges(
    String vendorId,
    String menuItemId,
    String categoryId,
    Map<String, bool> badges,
  ) async {
    try {
      _logger.info('Updating item badges for item: $menuItemId');

      // Validate badge values
      final validBadges = ['is_featured', 'is_recommended', 'is_new', 'is_popular'];
      for (final badge in badges.keys) {
        if (!validBadges.contains(badge)) {
          throw MenuValidationException('Invalid badge type: $badge');
        }
      }

      // Execute update
      final success = await _repository.updateItemBadges(vendorId, menuItemId, categoryId, badges);

      if (success) {
        _logger.info('Item badges updated successfully');
      }

      return success;
    } catch (e) {
      _logger.error('Failed to update item badges: $e');
      throw MenuExceptionFactory.organizationError(e.toString());
    }
  }

  // ==================== ANALYTICS SERVICES ====================

  /// Get comprehensive menu performance dashboard
  Future<Map<String, dynamic>> getMenuPerformanceDashboard(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      _logger.info('Getting menu performance dashboard for vendor: $vendorId');

      final dashboard = await _repository.getMenuPerformanceDashboard(
        vendorId,
        startDate: startDate,
        endDate: endDate,
      );

      // Add calculated insights
      dashboard['insights'] = _generatePerformanceInsights(dashboard);

      return dashboard;
    } catch (e) {
      _logger.error('Failed to get menu performance dashboard: $e');
      throw MenuExceptionFactory.analyticsError(e.toString());
    }
  }

  /// Track menu item view
  Future<void> trackMenuItemView(String menuItemId) async {
    try {
      await _repository.updateMenuItemAnalytics(
        menuItemId,
        incrementViews: 1,
      );
    } catch (e) {
      _logger.error('Failed to track menu item view: $e');
      // Don't throw exception for analytics tracking failures
    }
  }

  /// Track menu item order
  Future<void> trackMenuItemOrder(String menuItemId, double revenue) async {
    try {
      await _repository.updateMenuItemAnalytics(
        menuItemId,
        incrementOrders: 1,
        addRevenue: revenue,
      );
    } catch (e) {
      _logger.error('Failed to track menu item order: $e');
      // Don't throw exception for analytics tracking failures
    }
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Validate pricing configuration
  void _validatePricingConfig(AdvancedPricingConfig config) {
    // Validate bulk pricing tiers
    for (final tier in config.bulkPricingTiers) {
      if (tier.minimumQuantity <= 0) {
        throw MenuValidationException('Minimum quantity must be greater than 0');
      }
      if (tier.pricePerUnit < 0) {
        throw MenuValidationException('Price per unit cannot be negative');
      }
      if (tier.maximumQuantity != null && tier.maximumQuantity! <= tier.minimumQuantity) {
        throw MenuValidationException('Maximum quantity must be greater than minimum quantity');
      }
    }

    // Validate promotional pricing
    for (final promotion in config.promotionalPricing) {
      if (promotion.validUntil.isBefore(promotion.validFrom)) {
        throw MenuValidationException('Promotion end date must be after start date');
      }
      if (promotion.value <= 0) {
        throw MenuValidationException('Promotion value must be greater than 0');
      }
    }
  }

  /// Validate organization configuration
  void _validateOrganizationConfig(MenuOrganizationConfig config) {
    // Validate categories
    final categoryIds = config.categories.map((c) => c.id).toSet();
    if (categoryIds.length != config.categories.length) {
      throw MenuValidationException('Duplicate category IDs found');
    }

    // Validate hierarchy
    for (final category in config.categories) {
      if (category.parentCategoryId != null) {
        if (!categoryIds.contains(category.parentCategoryId)) {
          throw MenuValidationException('Parent category not found: ${category.parentCategoryId}');
        }
      }
    }
  }

  /// Check if bulk pricing tiers overlap
  bool _bulkTiersOverlap(EnhancedBulkPricingTier tier1, EnhancedBulkPricingTier tier2) {
    final tier1Max = tier1.maximumQuantity ?? double.infinity;
    final tier2Max = tier2.maximumQuantity ?? double.infinity;

    return !(tier1Max < tier2.minimumQuantity || tier2Max < tier1.minimumQuantity);
  }

  /// Check if promotions conflict
  bool _promotionsConflict(PromotionalPricing promo1, PromotionalPricing promo2) {
    // Check date overlap
    if (promo1.validUntil.isBefore(promo2.validFrom) || 
        promo2.validUntil.isBefore(promo1.validFrom)) {
      return false;
    }

    // Check day overlap
    if (promo1.applicableDays.isNotEmpty && promo2.applicableDays.isNotEmpty) {
      final commonDays = promo1.applicableDays.toSet().intersection(promo2.applicableDays.toSet());
      return commonDays.isNotEmpty;
    }

    return true;
  }

  /// Apply customer-specific pricing adjustments
  PricingCalculationResult _applyCustomerSpecificAdjustments(
    PricingCalculationResult result,
    Map<String, dynamic> customerContext,
  ) {
    // Implement customer-specific logic here
    // For example: loyalty discounts, membership pricing, etc.
    return result;
  }

  /// Create default organization configuration
  MenuOrganizationConfig _createDefaultOrganizationConfig(String vendorId) {
    return MenuOrganizationConfig(
      vendorId: vendorId,
      displayStyle: MenuDisplayStyle.grid,
      enableCategoryImages: true,
      enableSubcategories: false,
      enableDragAndDrop: true,
      showItemCounts: true,
      groupByAvailability: false,
      updatedAt: DateTime.now(),
    );
  }

  /// Generate performance insights from dashboard data
  Map<String, dynamic> _generatePerformanceInsights(Map<String, dynamic> dashboard) {
    final insights = <String, dynamic>{};

    // Add performance insights logic here
    insights['total_items_analyzed'] = dashboard['top_performing_items']?.length ?? 0;
    insights['revenue_trend'] = 'stable'; // Calculate based on historical data
    insights['top_category'] = dashboard['category_performance']?.isNotEmpty == true
        ? dashboard['category_performance'][0]['category_name']
        : null;

    return insights;
  }
}
