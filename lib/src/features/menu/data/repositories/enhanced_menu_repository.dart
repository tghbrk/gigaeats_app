import '../models/advanced_pricing.dart';
import '../models/menu_organization.dart';
import '../models/menu_item.dart';
import '../../../../core/errors/menu_exceptions.dart';
import '../../../../core/utils/logger.dart';
import 'base_menu_repository.dart';

/// Enhanced menu repository with support for advanced pricing, organization, and analytics
class EnhancedMenuRepository extends BaseMenuRepository {
  final AppLogger _logger = AppLogger();

  EnhancedMenuRepository({super.client});

  /// Get menu item by ID with enhanced features
  Future<MenuItem?> getMenuItemById(String itemId) async {
    try {
      final response = await supabase
          .from('menu_items')
          .select('*')
          .eq('id', itemId)
          .maybeSingle();

      if (response == null) return null;

      return MenuItem.fromJson(response);
    } catch (e) {
      _logger.error('Failed to get menu item by ID: $itemId', e);
      throw MenuNotFoundException('Menu item not found: $itemId');
    }
  }

  // ==================== ADVANCED PRICING METHODS ====================

  /// Get enhanced bulk pricing tiers for a menu item
  Future<List<EnhancedBulkPricingTier>> getEnhancedBulkPricingTiers(String menuItemId) async {
    return executeQuery(() async {
      _logger.info('Getting enhanced bulk pricing tiers for item: $menuItemId');

      final response = await supabase
          .from('enhanced_bulk_pricing_tiers')
          .select('*')
          .eq('menu_item_id', menuItemId)
          .eq('is_active', true)
          .order('minimum_quantity');

      return response.map((json) => EnhancedBulkPricingTier.fromJson(json)).toList();
    });
  }

  /// Create or update enhanced bulk pricing tier
  Future<EnhancedBulkPricingTier> saveEnhancedBulkPricingTier(
    String menuItemId,
    EnhancedBulkPricingTier tier,
  ) async {
    return executeQuery(() async {
      await _validateVendorOwnership(menuItemId);

      final tierData = tier.toJson();
      tierData['menu_item_id'] = menuItemId;

      if (tier.id != null) {
        // Update existing tier
        final response = await supabase
            .from('enhanced_bulk_pricing_tiers')
            .update(tierData)
            .eq('id', tier.id!)
            .select()
            .single();

        return EnhancedBulkPricingTier.fromJson(response);
      } else {
        // Create new tier
        final response = await supabase
            .from('enhanced_bulk_pricing_tiers')
            .insert(tierData)
            .select()
            .single();

        return EnhancedBulkPricingTier.fromJson(response);
      }
    });
  }

  /// Get promotional pricing for a menu item
  Future<List<PromotionalPricing>> getPromotionalPricing(String menuItemId) async {
    return executeQuery(() async {
      _logger.info('Getting promotional pricing for item: $menuItemId');

      final response = await supabase
          .from('promotional_pricing')
          .select('*')
          .eq('menu_item_id', menuItemId)
          .eq('is_active', true)
          .order('created_at', ascending: false);

      return response.map((json) => PromotionalPricing.fromJson(json)).toList();
    });
  }

  /// Create or update promotional pricing
  Future<PromotionalPricing> savePromotionalPricing(
    String menuItemId,
    PromotionalPricing promotion,
  ) async {
    return executeQuery(() async {
      await _validateVendorOwnership(menuItemId);

      final promotionData = promotion.toJson();
      promotionData['menu_item_id'] = menuItemId;

      if (promotion.id != null) {
        // Update existing promotion
        final response = await supabase
            .from('promotional_pricing')
            .update(promotionData)
            .eq('id', promotion.id!)
            .select()
            .single();

        return PromotionalPricing.fromJson(response);
      } else {
        // Create new promotion
        final response = await supabase
            .from('promotional_pricing')
            .insert(promotionData)
            .select()
            .single();

        return PromotionalPricing.fromJson(response);
      }
    });
  }

  /// Get time-based pricing rules for a menu item
  Future<List<TimeBasedPricingRule>> getTimeBasedPricingRules(String menuItemId) async {
    return executeQuery(() async {
      _logger.info('Getting time-based pricing rules for item: $menuItemId');

      final response = await supabase
          .from('time_based_pricing_rules')
          .select('*')
          .eq('menu_item_id', menuItemId)
          .eq('is_active', true)
          .order('priority', ascending: false);

      return response.map((json) => TimeBasedPricingRule.fromJson(json)).toList();
    });
  }

  /// Calculate effective price for a menu item
  Future<PricingCalculationResult> calculateEffectivePrice(
    String menuItemId,
    int quantity, {
    DateTime? orderTime,
  }) async {
    return executeQuery(() async {
      _logger.info('Calculating effective price for item: $menuItemId, quantity: $quantity');

      final response = await supabase.rpc('calculate_effective_price', params: {
        'item_id': menuItemId,
        'quantity': quantity,
        'order_time': (orderTime ?? DateTime.now()).toIso8601String(),
      });

      return PricingCalculationResult.fromJson(response);
    });
  }

  // ==================== MENU ORGANIZATION METHODS ====================

  /// Get enhanced menu categories for a vendor
  Future<List<EnhancedMenuCategory>> getEnhancedMenuCategories(String vendorId) async {
    return executeQuery(() async {
      _logger.info('Getting enhanced menu categories for vendor: $vendorId');

      final response = await supabase
          .from('enhanced_menu_categories')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('sort_order');

      return response.map((json) => EnhancedMenuCategory.fromJson(json)).toList();
    });
  }

  /// Get menu hierarchy for a vendor
  Future<List<MenuHierarchyNode>> getMenuHierarchy(String vendorId) async {
    return executeQuery(() async {
      _logger.info('Getting menu hierarchy for vendor: $vendorId');

      final response = await supabase.rpc('get_menu_hierarchy', params: {
        'vendor_uuid': vendorId,
      });

      if (response is List) {
        return response.map((json) => MenuHierarchyNode.fromJson(json)).toList();
      }
      return [];
    });
  }

  /// Create or update enhanced menu category
  Future<EnhancedMenuCategory> saveEnhancedMenuCategory(
    String vendorId,
    EnhancedMenuCategory category,
  ) async {
    return executeQuery(() async {
      await _validateVendorAccess(vendorId);

      final categoryData = category.toJson();
      categoryData['vendor_id'] = vendorId;

      if (category.id.isNotEmpty) {
        // Update existing category
        final response = await supabase
            .from('enhanced_menu_categories')
            .update(categoryData)
            .eq('id', category.id)
            .select()
            .single();

        return EnhancedMenuCategory.fromJson(response);
      } else {
        // Create new category
        final response = await supabase
            .from('enhanced_menu_categories')
            .insert(categoryData)
            .select()
            .single();

        return EnhancedMenuCategory.fromJson(response);
      }
    });
  }

  /// Reorder categories for a vendor
  Future<bool> reorderCategories(
    String vendorId,
    List<Map<String, dynamic>> categoryOrders,
  ) async {
    return executeQuery(() async {
      await _validateVendorAccess(vendorId);

      final response = await supabase.rpc('reorder_categories', params: {
        'vendor_uuid': vendorId,
        'category_orders': categoryOrders,
      });

      return response == true;
    });
  }

  /// Get menu item positions for a category
  Future<List<MenuItemPosition>> getMenuItemPositions(String categoryId) async {
    return executeQuery(() async {
      _logger.info('Getting menu item positions for category: $categoryId');

      final response = await supabase
          .from('menu_item_positions')
          .select('*')
          .eq('category_id', categoryId)
          .order('sort_order');

      return response.map((json) => MenuItemPosition.fromJson(json)).toList();
    });
  }

  /// Reorder menu items within a category
  Future<bool> reorderMenuItems(
    String vendorId,
    String categoryId,
    List<Map<String, dynamic>> itemOrders,
  ) async {
    return executeQuery(() async {
      await _validateVendorAccess(vendorId);

      final response = await supabase.rpc('reorder_menu_items', params: {
        'vendor_uuid': vendorId,
        'category_uuid': categoryId,
        'item_orders': itemOrders,
      });

      return response == true;
    });
  }

  /// Update item badges (featured, recommended, etc.)
  Future<bool> updateItemBadges(
    String vendorId,
    String menuItemId,
    String categoryId,
    Map<String, dynamic> badges,
  ) async {
    return executeQuery(() async {
      await _validateVendorAccess(vendorId);

      final response = await supabase.rpc('update_item_badges', params: {
        'vendor_uuid': vendorId,
        'item_uuid': menuItemId,
        'category_uuid': categoryId,
        'badges': badges,
      });

      return response == true;
    });
  }

  /// Get menu organization configuration for a vendor
  Future<MenuOrganizationConfig?> getMenuOrganizationConfig(String vendorId) async {
    return executeQuery(() async {
      _logger.info('Getting menu organization config for vendor: $vendorId');

      final response = await supabase
          .from('menu_organization_config')
          .select('*')
          .eq('vendor_id', vendorId)
          .maybeSingle();

      if (response != null) {
        // Get categories and positions separately
        final categories = await getEnhancedMenuCategories(vendorId);
        final positions = await _getAllMenuItemPositions(vendorId);

        return MenuOrganizationConfig.fromJson(response).copyWith(
          categories: categories,
          itemPositions: positions,
        );
      }

      return null;
    });
  }

  /// Save menu organization configuration
  Future<MenuOrganizationConfig> saveMenuOrganizationConfig(
    String vendorId,
    MenuOrganizationConfig config,
  ) async {
    return executeQuery(() async {
      await _validateVendorAccess(vendorId);

      final configData = config.toJson();
      configData['vendor_id'] = vendorId;
      configData.remove('categories'); // Handle separately
      configData.remove('itemPositions'); // Handle separately

      final response = await supabase
          .from('menu_organization_config')
          .upsert(configData)
          .select()
          .single();

      return MenuOrganizationConfig.fromJson(response);
    });
  }

  // ==================== ENHANCED CUSTOMIZATIONS METHODS ====================

  /// Get enhanced menu item with customizations
  Future<Map<String, dynamic>?> getEnhancedMenuItemWithCustomizations(String menuItemId) async {
    return executeQuery(() async {
      _logger.info('Getting enhanced menu item with customizations: $menuItemId');

      final response = await supabase.rpc('get_enhanced_menu_item_with_customizations', params: {
        'item_id': menuItemId,
      });

      return response;
    });
  }

  /// Get customization templates for a vendor
  Future<List<Map<String, dynamic>>> getCustomizationTemplates(String vendorId) async {
    return executeQuery(() async {
      _logger.info('Getting customization templates for vendor: $vendorId');

      final response = await supabase
          .from('customization_templates')
          .select('*')
          .or('vendor_id.eq.$vendorId,is_public.eq.true')
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    });
  }

  /// Calculate customization price
  Future<Map<String, dynamic>> calculateCustomizationPrice(
    String customizationId,
    List<Map<String, dynamic>> selectedOptions, {
    int quantity = 1,
  }) async {
    return executeQuery(() async {
      _logger.info('Calculating customization price for: $customizationId');

      final response = await supabase.rpc('calculate_customization_price', params: {
        'customization_id': customizationId,
        'selected_options': selectedOptions,
        'base_quantity': quantity,
      });

      return response;
    });
  }

  // ==================== ANALYTICS METHODS ====================

  /// Update menu item analytics
  Future<void> updateMenuItemAnalytics(
    String menuItemId, {
    DateTime? date,
    int incrementViews = 0,
    int incrementOrders = 0,
    double addRevenue = 0.0,
  }) async {
    return executeQuery(() async {
      await supabase.rpc('update_menu_item_analytics', params: {
        'item_id': menuItemId,
        'analytics_date': (date ?? DateTime.now()).toIso8601String().split('T')[0],
        'increment_views': incrementViews,
        'increment_orders': incrementOrders,
        'add_revenue': addRevenue,
      });
    });
  }

  /// Get menu performance dashboard
  Future<Map<String, dynamic>> getMenuPerformanceDashboard(
    String vendorId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      _logger.info('Getting menu performance dashboard for vendor: $vendorId');

      final response = await supabase.rpc('get_menu_performance_dashboard', params: {
        'vendor_uuid': vendorId,
        'start_date': (startDate ?? DateTime.now().subtract(const Duration(days: 30)))
            .toIso8601String().split('T')[0],
        'end_date': (endDate ?? DateTime.now()).toIso8601String().split('T')[0],
      });

      return response;
    });
  }

  /// Generate menu optimization suggestions
  Future<int> generateMenuOptimizationSuggestions(String vendorId) async {
    return executeQuery(() async {
      _logger.info('Generating menu optimization suggestions for vendor: $vendorId');

      final response = await supabase.rpc('generate_menu_optimization_suggestions', params: {
        'vendor_uuid': vendorId,
      });

      return response as int;
    });
  }

  // ==================== PRIVATE HELPER METHODS ====================

  /// Validate that the current user owns the menu item
  Future<void> _validateVendorOwnership(String menuItemId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw MenuUnauthorizedException('User not authenticated');
    }

    final response = await supabase
        .from('menu_items')
        .select('vendor_id')
        .eq('id', menuItemId)
        .maybeSingle();

    if (response == null) {
      throw MenuNotFoundException('Menu item not found: $menuItemId');
    }

    final vendorResponse = await supabase
        .from('vendors')
        .select('id')
        .eq('id', response['vendor_id'])
        .eq('user_id', currentUser.id)
        .maybeSingle();

    if (vendorResponse == null) {
      throw MenuUnauthorizedException('User does not own this menu item');
    }
  }

  /// Validate that the current user has access to the vendor
  Future<void> _validateVendorAccess(String vendorId) async {
    final currentUser = supabase.auth.currentUser;
    if (currentUser == null) {
      throw MenuUnauthorizedException('User not authenticated');
    }

    final response = await supabase
        .from('vendors')
        .select('id')
        .eq('id', vendorId)
        .eq('user_id', currentUser.id)
        .maybeSingle();

    if (response == null) {
      throw MenuUnauthorizedException('User does not have access to this vendor');
    }
  }

  /// Get all menu item positions for a vendor
  Future<List<MenuItemPosition>> _getAllMenuItemPositions(String vendorId) async {
    final response = await supabase
        .from('menu_item_positions')
        .select('''
          *,
          menu_items!inner(vendor_id)
        ''')
        .eq('menu_items.vendor_id', vendorId);

    return response.map((json) => MenuItemPosition.fromJson(json)).toList();
  }
}
