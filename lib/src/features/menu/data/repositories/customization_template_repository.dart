import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/customization_template.dart';
import '../models/template_usage_analytics.dart';

/// Repository for managing customization templates
class CustomizationTemplateRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  // =====================================================
  // TEMPLATE CRUD OPERATIONS
  // =====================================================

  /// Get all templates for a vendor
  Future<List<CustomizationTemplate>> getVendorTemplates(
    String vendorId, {
    bool? isActive,
    String? searchQuery,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 [TEMPLATE-REPO] Getting templates for vendor: $vendorId');

      var query = _supabase
          .from('customization_templates')
          .select('''
            *,
            template_options (
              id,
              template_id,
              name,
              additional_price,
              is_default,
              is_available,
              display_order,
              created_at,
              updated_at
            )
          ''')
          .eq('vendor_id', vendorId);

      // Apply filters
      if (isActive != null) {
        query = query.eq('is_active', isActive);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
      }

      final response = await query
          .order('display_order')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final templates = <CustomizationTemplate>[];
      for (final templateData in response) {
        final options = <TemplateOption>[];
        
        if (templateData['template_options'] != null) {
          for (final optionData in templateData['template_options']) {
            options.add(TemplateOption.fromJson(optionData));
          }
        }

        final template = CustomizationTemplate.fromJson(templateData).copyWith(
          options: options,
        );
        templates.add(template);
      }

      debugPrint('✅ [TEMPLATE-REPO] Retrieved ${templates.length} templates');
      return templates;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting templates: $e');
      throw Exception('Failed to fetch templates: $e');
    }
  }

  /// Get a specific template by ID
  Future<CustomizationTemplate?> getTemplateById(String templateId) async {
    try {
      debugPrint('🔍 [TEMPLATE-REPO] Getting template: $templateId');

      final response = await _supabase
          .from('customization_templates')
          .select('''
            *,
            template_options (
              id,
              template_id,
              name,
              additional_price,
              is_default,
              is_available,
              display_order,
              created_at,
              updated_at
            )
          ''')
          .eq('id', templateId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [TEMPLATE-REPO] Template not found: $templateId');
        return null;
      }

      final options = <TemplateOption>[];
      if (response['template_options'] != null) {
        for (final optionData in response['template_options']) {
          options.add(TemplateOption.fromJson(optionData));
        }
      }

      final template = CustomizationTemplate.fromJson(response).copyWith(
        options: options,
      );

      debugPrint('✅ [TEMPLATE-REPO] Retrieved template: ${template.name}');
      return template;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting template: $e');
      throw Exception('Failed to fetch template: $e');
    }
  }

  /// Create a new template
  Future<CustomizationTemplate> createTemplate(CustomizationTemplate template) async {
    try {
      debugPrint('🔧 [TEMPLATE-REPO] Creating template: ${template.name}');

      // Get current vendor ID from auth
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) {
        throw Exception('Vendor not found');
      }

      // Create template data
      final templateData = {
        'vendor_id': vendorId,
        'name': template.name,
        'description': template.description,
        'type': template.type,
        'is_required': template.isRequired,
        'display_order': template.displayOrder,
        'is_active': template.isActive,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final templateResponse = await _supabase
          .from('customization_templates')
          .insert(templateData)
          .select()
          .single();

      final createdTemplate = CustomizationTemplate.fromJson(templateResponse);

      // Create template options if provided
      final createdOptions = <TemplateOption>[];
      if (template.options.isNotEmpty) {
        for (int i = 0; i < template.options.length; i++) {
          final option = template.options[i];
          final createdOption = await _createTemplateOption(
            createdTemplate.id,
            option.copyWith(displayOrder: i),
          );
          createdOptions.add(createdOption);
        }
      }

      final finalTemplate = createdTemplate.copyWith(options: createdOptions);
      debugPrint('✅ [TEMPLATE-REPO] Created template: ${finalTemplate.name}');
      return finalTemplate;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error creating template: $e');
      throw Exception('Failed to create template: $e');
    }
  }

  /// Update an existing template
  Future<CustomizationTemplate> updateTemplate(CustomizationTemplate template) async {
    try {
      debugPrint('🔧 [TEMPLATE-REPO] Updating template: ${template.id}');

      final updateData = {
        'name': template.name,
        'description': template.description,
        'type': template.type,
        'is_required': template.isRequired,
        'display_order': template.displayOrder,
        'is_active': template.isActive,
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _supabase
          .from('customization_templates')
          .update(updateData)
          .eq('id', template.id)
          .select()
          .single();

      // Update template options
      await _updateTemplateOptions(template.id, template.options);

      // Fetch updated template with options
      final updatedTemplate = await getTemplateById(template.id);
      if (updatedTemplate == null) {
        throw Exception('Template not found after update');
      }

      debugPrint('✅ [TEMPLATE-REPO] Updated template: ${updatedTemplate.name}');
      return updatedTemplate;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error updating template: $e');
      throw Exception('Failed to update template: $e');
    }
  }

  /// Delete a template
  Future<void> deleteTemplate(String templateId) async {
    try {
      debugPrint('🗑️ [TEMPLATE-REPO] Deleting template: $templateId');

      await _supabase
          .from('customization_templates')
          .delete()
          .eq('id', templateId);

      debugPrint('✅ [TEMPLATE-REPO] Deleted template: $templateId');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error deleting template: $e');
      throw Exception('Failed to delete template: $e');
    }
  }

  // =====================================================
  // TEMPLATE OPTION OPERATIONS
  // =====================================================

  /// Create a template option
  Future<TemplateOption> _createTemplateOption(String templateId, TemplateOption option) async {
    final optionData = {
      'template_id': templateId,
      'name': option.name,
      'additional_price': option.additionalPrice,
      'is_default': option.isDefault,
      'is_available': option.isAvailable,
      'display_order': option.displayOrder,
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final response = await _supabase
        .from('template_options')
        .insert(optionData)
        .select()
        .single();

    return TemplateOption.fromJson(response);
  }

  /// Update template options (delete existing and recreate)
  Future<void> _updateTemplateOptions(String templateId, List<TemplateOption> options) async {
    // Delete existing options
    await _supabase
        .from('template_options')
        .delete()
        .eq('template_id', templateId);

    // Create new options
    for (int i = 0; i < options.length; i++) {
      final option = options[i];
      await _createTemplateOption(templateId, option.copyWith(displayOrder: i));
    }
  }

  // =====================================================
  // MENU ITEM TEMPLATE LINKING OPERATIONS
  // =====================================================

  /// Link a template to a menu item
  Future<MenuItemTemplateLink> linkTemplateToMenuItem({
    required String menuItemId,
    required String templateId,
    int displayOrder = 0,
  }) async {
    try {
      debugPrint('🔗 [TEMPLATE-REPO] Linking template $templateId to menu item $menuItemId');

      final linkData = {
        'menu_item_id': menuItemId,
        'template_id': templateId,
        'display_order': displayOrder,
        'is_active': true,
        // Note: linked_at has a default value of now() in the database
      };

      final response = await _supabase
          .from('menu_item_template_links')
          .insert(linkData)
          .select()
          .single();

      final link = MenuItemTemplateLink.fromJson(response);
      debugPrint('✅ [TEMPLATE-REPO] Linked template to menu item');
      return link;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error linking template: $e');
      throw Exception('Failed to link template to menu item: $e');
    }
  }

  /// Unlink a template from a menu item
  Future<void> unlinkTemplateFromMenuItem({
    required String menuItemId,
    required String templateId,
  }) async {
    try {
      debugPrint('🔗 [TEMPLATE-REPO] Unlinking template $templateId from menu item $menuItemId');

      await _supabase
          .from('menu_item_template_links')
          .delete()
          .eq('menu_item_id', menuItemId)
          .eq('template_id', templateId);

      debugPrint('✅ [TEMPLATE-REPO] Unlinked template from menu item');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error unlinking template: $e');
      throw Exception('Failed to unlink template from menu item: $e');
    }
  }

  /// Get all templates linked to a menu item
  Future<List<CustomizationTemplate>> getMenuItemTemplates(String menuItemId) async {
    try {
      debugPrint('🔍 [TEMPLATE-REPO] Getting templates for menu item: $menuItemId');

      final response = await _supabase
          .from('menu_item_template_links')
          .select('''
            display_order,
            is_active,
            customization_templates (
              *,
              template_options (
                id,
                template_id,
                name,
                additional_price,
                is_default,
                is_available,
                display_order,
                created_at,
                updated_at
              )
            )
          ''')
          .eq('menu_item_id', menuItemId)
          .eq('is_active', true)
          .order('display_order');

      final templates = <CustomizationTemplate>[];
      for (final linkData in response) {
        final templateData = linkData['customization_templates'];
        if (templateData != null) {
          final options = <TemplateOption>[];

          if (templateData['template_options'] != null) {
            for (final optionData in templateData['template_options']) {
              options.add(TemplateOption.fromJson(optionData));
            }
          }

          final template = CustomizationTemplate.fromJson(templateData).copyWith(
            options: options,
          );
          templates.add(template);
        }
      }

      debugPrint('✅ [TEMPLATE-REPO] Retrieved ${templates.length} linked templates');
      return templates;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting menu item templates: $e');
      throw Exception('Failed to fetch menu item templates: $e');
    }
  }

  /// Get all menu items using a specific template
  Future<List<String>> getMenuItemsUsingTemplate(String templateId) async {
    try {
      debugPrint('🔍 [TEMPLATE-REPO] Getting menu items using template: $templateId');

      final response = await _supabase
          .from('menu_item_template_links')
          .select('menu_item_id')
          .eq('template_id', templateId)
          .eq('is_active', true);

      final menuItemIds = response.map((link) => link['menu_item_id'] as String).toList();
      debugPrint('✅ [TEMPLATE-REPO] Found ${menuItemIds.length} menu items using template');
      return menuItemIds;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting menu items using template: $e');
      throw Exception('Failed to fetch menu items using template: $e');
    }
  }

  /// Bulk link templates to multiple menu items
  Future<List<MenuItemTemplateLink>> bulkLinkTemplatesToMenuItems({
    required List<String> menuItemIds,
    required List<String> templateIds,
  }) async {
    try {
      debugPrint('🔗 [TEMPLATE-REPO] Bulk linking ${templateIds.length} templates to ${menuItemIds.length} menu items');

      final links = <MenuItemTemplateLink>[];
      final linkData = <Map<String, dynamic>>[];

      for (final menuItemId in menuItemIds) {
        for (int i = 0; i < templateIds.length; i++) {
          linkData.add({
            'menu_item_id': menuItemId,
            'template_id': templateIds[i],
            'display_order': i,
            'is_active': true,
            // Note: linked_at has a default value of now() in the database
          });
        }
      }

      final response = await _supabase
          .from('menu_item_template_links')
          .insert(linkData)
          .select();

      for (final linkJson in response) {
        links.add(MenuItemTemplateLink.fromJson(linkJson));
      }

      debugPrint('✅ [TEMPLATE-REPO] Created ${links.length} template links');
      return links;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error bulk linking templates: $e');
      throw Exception('Failed to bulk link templates: $e');
    }
  }

  // =====================================================
  // ANALYTICS AND USAGE TRACKING
  // =====================================================

  /// Get template usage analytics for a vendor
  Future<List<TemplateUsageAnalytics>> getTemplateAnalytics({
    required String vendorId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      debugPrint('📊 [TEMPLATE-REPO] Getting analytics for vendor: $vendorId');

      var query = _supabase
          .from('template_usage_analytics')
          .select('*')
          .eq('vendor_id', vendorId);

      if (startDate != null) {
        query = query.gte('analytics_date', startDate.toIso8601String().split('T')[0]);
      }

      if (endDate != null) {
        query = query.lte('analytics_date', endDate.toIso8601String().split('T')[0]);
      }

      final response = await query
          .order('analytics_date', ascending: false)
          .limit(limit);

      final analytics = response.map((json) => TemplateUsageAnalytics.fromJson(json)).toList();
      debugPrint('✅ [TEMPLATE-REPO] Retrieved ${analytics.length} analytics records');
      return analytics;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting analytics: $e');
      throw Exception('Failed to fetch template analytics: $e');
    }
  }

  /// Get analytics summary for a vendor
  Future<TemplateAnalyticsSummary> getAnalyticsSummary({
    required String vendorId,
    required DateTime periodStart,
    required DateTime periodEnd,
  }) async {
    try {
      debugPrint('📊 [TEMPLATE-REPO] Getting analytics summary for vendor: $vendorId');

      // Get aggregated data using database function
      final response = await _supabase.rpc('get_template_analytics_summary', params: {
        'vendor_id_param': vendorId,
        'start_date': periodStart.toIso8601String().split('T')[0],
        'end_date': periodEnd.toIso8601String().split('T')[0],
      });

      // Get top performing templates
      final topTemplates = await _getTopPerformingTemplates(vendorId, periodStart, periodEnd);

      final summary = TemplateAnalyticsSummary(
        vendorId: vendorId,
        totalTemplates: response['total_templates'] ?? 0,
        activeTemplates: response['active_templates'] ?? 0,
        totalMenuItemsUsingTemplates: response['total_menu_items'] ?? 0,
        totalOrdersWithTemplates: response['total_orders'] ?? 0,
        totalRevenueFromTemplates: (response['total_revenue'] ?? 0.0).toDouble(),
        periodStart: periodStart,
        periodEnd: periodEnd,
        topPerformingTemplates: topTemplates,
      );

      debugPrint('✅ [TEMPLATE-REPO] Retrieved analytics summary');
      return summary;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting analytics summary: $e');
      throw Exception('Failed to fetch analytics summary: $e');
    }
  }

  /// Get top performing templates
  Future<List<TemplateUsageAnalytics>> _getTopPerformingTemplates(
    String vendorId,
    DateTime startDate,
    DateTime endDate, {
    int limit = 5,
  }) async {
    final response = await _supabase
        .from('template_usage_analytics')
        .select('*')
        .eq('vendor_id', vendorId)
        .gte('analytics_date', startDate.toIso8601String().split('T')[0])
        .lte('analytics_date', endDate.toIso8601String().split('T')[0])
        .order('revenue_generated', ascending: false)
        .limit(limit);

    return response.map((json) => TemplateUsageAnalytics.fromJson(json)).toList();
  }

  /// Get template performance metrics
  Future<List<TemplatePerformanceMetrics>> getTemplatePerformanceMetrics({
    required String vendorId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('📊 [TEMPLATE-REPO] Getting performance metrics for vendor: $vendorId');

      final response = await _supabase.rpc('get_template_performance_metrics', params: {
        'vendor_id_param': vendorId,
        'start_date': startDate?.toIso8601String().split('T')[0],
        'end_date': endDate?.toIso8601String().split('T')[0],
      });

      final metrics = <TemplatePerformanceMetrics>[];
      for (final metricData in response) {
        metrics.add(TemplatePerformanceMetrics.fromJson(metricData));
      }

      debugPrint('✅ [TEMPLATE-REPO] Retrieved ${metrics.length} performance metrics');
      return metrics;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting performance metrics: $e');
      throw Exception('Failed to fetch performance metrics: $e');
    }
  }

  /// Update template usage count (called when linking/unlinking)
  Future<void> updateTemplateUsageCount(String templateId) async {
    try {
      await _supabase.rpc('update_template_usage_count_manual', params: {
        'template_id_param': templateId,
      });
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error updating usage count: $e');
      // Don't throw here as this is a background operation
    }
  }

  // =====================================================
  // SEARCH AND FILTERING
  // =====================================================

  /// Search templates by name or description
  Future<List<CustomizationTemplate>> searchTemplates({
    required String vendorId,
    required String query,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 [TEMPLATE-REPO] Searching templates: $query');

      final response = await _supabase
          .from('customization_templates')
          .select('''
            *,
            template_options (
              id,
              template_id,
              name,
              additional_price,
              is_default,
              is_available,
              display_order,
              created_at,
              updated_at
            )
          ''')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('usage_count', ascending: false)
          .limit(limit);

      final templates = <CustomizationTemplate>[];
      for (final templateData in response) {
        final options = <TemplateOption>[];

        if (templateData['template_options'] != null) {
          for (final optionData in templateData['template_options']) {
            options.add(TemplateOption.fromJson(optionData));
          }
        }

        final template = CustomizationTemplate.fromJson(templateData).copyWith(
          options: options,
        );
        templates.add(template);
      }

      debugPrint('✅ [TEMPLATE-REPO] Found ${templates.length} templates');
      return templates;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error searching templates: $e');
      throw Exception('Failed to search templates: $e');
    }
  }

  /// Get popular templates (most used)
  Future<List<CustomizationTemplate>> getPopularTemplates({
    required String vendorId,
    int limit = 10,
  }) async {
    return getVendorTemplates(
      vendorId,
      isActive: true,
      limit: limit,
    );
  }

  // =====================================================
  // TEMPLATE OPTIONS MANAGEMENT
  // =====================================================

  /// Add an option to a template
  Future<TemplateOption> addOptionToTemplate(String templateId, Map<String, dynamic> optionData) async {
    try {
      debugPrint('🔧 [TEMPLATE-REPO] Adding option to template: $templateId');

      final data = {
        'template_id': templateId,
        'name': optionData['name'],
        'additional_price': optionData['price'] ?? 0.0,
        'is_default': optionData['is_default'] ?? false,
        'is_available': optionData['is_available'] ?? true,
        'display_order': optionData['display_order'] ?? 0,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('template_options')
          .insert(data)
          .select()
          .single();

      final option = TemplateOption.fromJson(response);
      debugPrint('✅ [TEMPLATE-REPO] Added option: ${option.name}');
      return option;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error adding option: $e');
      throw Exception('Failed to add option: $e');
    }
  }

  /// Get all options for a template
  Future<List<TemplateOption>> getTemplateOptions(String templateId) async {
    try {
      debugPrint('🔍 [TEMPLATE-REPO] Getting options for template: $templateId');

      final response = await _supabase
          .from('template_options')
          .select()
          .eq('template_id', templateId)
          .order('display_order')
          .order('created_at');

      final options = response.map((json) => TemplateOption.fromJson(json)).toList();
      debugPrint('✅ [TEMPLATE-REPO] Retrieved ${options.length} options');
      return options;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting options: $e');
      throw Exception('Failed to fetch options: $e');
    }
  }

  /// Alias for getVendorTemplates for backward compatibility
  Future<List<CustomizationTemplate>> getTemplatesByVendor(String vendorId) async {
    return getVendorTemplates(vendorId);
  }

  // =====================================================
  // VALIDATION METHODS
  // =====================================================

  /// Validate template data before creation/update
  bool validateTemplateData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (data['vendor_id'] == null || data['vendor_id'].toString().trim().isEmpty) {
        return false;
      }

      if (data['name'] == null || data['name'].toString().trim().isEmpty) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Validation error: $e');
      return false;
    }
  }

  /// Validate option data before creation/update
  bool validateOptionData(Map<String, dynamic> data) {
    try {
      // Check required fields
      if (data['template_id'] == null || data['template_id'].toString().trim().isEmpty) {
        return false;
      }

      if (data['name'] == null || data['name'].toString().trim().isEmpty) {
        return false;
      }

      // Check price is not negative
      if (data['price'] != null && data['price'] < 0) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Option validation error: $e');
      return false;
    }
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  /// Get current vendor ID from authenticated user
  Future<String?> _getCurrentVendorId() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('vendors')
          .select('id')
          .eq('user_id', user.id)
          .maybeSingle();

      return response?['id'];
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error getting vendor ID: $e');
      return null;
    }
  }

  /// Bulk link multiple templates to multiple menu items
  Future<Map<String, bool>> bulkLinkTemplates({
    required List<String> menuItemIds,
    required List<String> templateIds,
  }) async {
    final results = <String, bool>{};

    try {
      debugPrint('🔗 [TEMPLATE-REPO] Bulk linking ${templateIds.length} templates to ${menuItemIds.length} menu items');

      // First, check for existing links to avoid duplicates
      final existingLinks = await _supabase
          .from('menu_item_template_links')
          .select('menu_item_id, template_id')
          .inFilter('menu_item_id', menuItemIds)
          .inFilter('template_id', templateIds);

      final existingLinkSet = <String>{};
      for (final link in existingLinks) {
        existingLinkSet.add('${link['menu_item_id']}_${link['template_id']}');
      }

      // Create only new combinations that don't already exist
      final links = <Map<String, dynamic>>[];

      for (final menuItemId in menuItemIds) {
        for (final templateId in templateIds) {
          final linkKey = '${menuItemId}_$templateId';
          if (!existingLinkSet.contains(linkKey)) {
            links.add({
              'menu_item_id': menuItemId,
              'template_id': templateId,
              'display_order': 0,
              'is_active': true,
              // Note: linked_at has a default value of now() in the database
            });
          }
        }
      }

      if (links.isNotEmpty) {
        debugPrint('🔗 [TEMPLATE-REPO] Inserting ${links.length} new links (${existingLinks.length} already exist)');

        // Batch insert only new links
        await _supabase
            .from('menu_item_template_links')
            .insert(links);

        debugPrint('✅ [TEMPLATE-REPO] Successfully inserted ${links.length} new template links');
      } else {
        debugPrint('ℹ️ [TEMPLATE-REPO] All template links already exist, no new links to create');
      }

      // Mark all as successful
      for (final menuItemId in menuItemIds) {
        results[menuItemId] = true;
      }

      debugPrint('✅ [TEMPLATE-REPO] Bulk linked templates successfully');

    } on PostgrestException catch (e) {
      debugPrint('⚠️ [TEMPLATE-REPO] Batch insert failed, trying individual inserts: ${e.message}');

      // If batch insert fails, try individual inserts to identify failures
      for (final menuItemId in menuItemIds) {
        try {
          for (final templateId in templateIds) {
            await _linkTemplateToMenuItemSafe(
              menuItemId: menuItemId,
              templateId: templateId,
            );
          }
          results[menuItemId] = true;
        } catch (e) {
          debugPrint('❌ [TEMPLATE-REPO] Failed to link templates to menu item $menuItemId: $e');
          results[menuItemId] = false;
        }
      }
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error in bulk linking: $e');
      // Mark all as failed
      for (final menuItemId in menuItemIds) {
        results[menuItemId] = false;
      }
    }

    return results;
  }

  /// Safely link a template to a menu item, checking for existing links first
  Future<void> _linkTemplateToMenuItemSafe({
    required String menuItemId,
    required String templateId,
  }) async {
    try {
      // Check if link already exists
      final existingLink = await _supabase
          .from('menu_item_template_links')
          .select('id')
          .eq('menu_item_id', menuItemId)
          .eq('template_id', templateId)
          .maybeSingle();

      if (existingLink != null) {
        debugPrint('ℹ️ [TEMPLATE-REPO] Link already exists for menu item $menuItemId and template $templateId');
        return;
      }

      // Create new link
      await linkTemplateToMenuItem(
        menuItemId: menuItemId,
        templateId: templateId,
      );
    } catch (e) {
      debugPrint('❌ [TEMPLATE-REPO] Error in safe linking: $e');
      rethrow;
    }
  }

  /// Bulk unlink templates from multiple menu items
  Future<Map<String, bool>> bulkUnlinkTemplates({
    required List<String> menuItemIds,
    required List<String> templateIds,
  }) async {
    final results = <String, bool>{};

    try {
      debugPrint('🔗 [TEMPLATE-REPO] Bulk unlinking ${templateIds.length} templates from ${menuItemIds.length} menu items');

      // Delete all links for the specified combinations
      await _supabase
          .from('menu_item_template_links')
          .delete()
          .inFilter('menu_item_id', menuItemIds)
          .inFilter('template_id', templateIds);

      // Mark all as successful
      for (final menuItemId in menuItemIds) {
        results[menuItemId] = true;
      }

      debugPrint('✅ [TEMPLATE-REPO] Bulk unlinked templates successfully');

    } catch (e) {
      debugPrint('⚠️ [TEMPLATE-REPO] Batch delete failed, trying individual deletes: $e');

      // If batch delete fails, try individual deletes
      for (final menuItemId in menuItemIds) {
        try {
          for (final templateId in templateIds) {
            await unlinkTemplateFromMenuItem(
              menuItemId: menuItemId,
              templateId: templateId,
            );
          }
          results[menuItemId] = true;
        } catch (e) {
          debugPrint('❌ [TEMPLATE-REPO] Failed to unlink templates from menu item $menuItemId: $e');
          results[menuItemId] = false;
        }
      }
    }

    return results;
  }
}
