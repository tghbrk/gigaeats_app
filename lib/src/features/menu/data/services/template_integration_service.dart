import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customization_template.dart';
import '../models/product.dart' as product_model;

import '../repositories/customization_template_repository.dart';
import '../repositories/menu_item_repository.dart';
import '../../presentation/utils/template_debug_logger.dart';

/// Service for integrating template-based customizations with order processing
/// Enhanced for template-only workflow
class TemplateIntegrationService {
  final CustomizationTemplateRepository _templateRepository;
  final MenuItemRepository? _menuItemRepository;
  final SupabaseClient? _supabase;

  /// Getter to access the template repository
  CustomizationTemplateRepository get templateRepository => _templateRepository;

  TemplateIntegrationService(
    this._templateRepository, {
    MenuItemRepository? menuItemRepository,
    SupabaseClient? supabase,
  })  : _menuItemRepository = menuItemRepository,
        _supabase = supabase;

  /// Resolves all customizations for a menu item including templates
  Future<List<product_model.MenuItemCustomization>> resolveMenuItemCustomizations(
    String menuItemId,
  ) async {
    try {
      debugPrint('🔗 [TEMPLATE-INTEGRATION] Resolving customizations for menu item: $menuItemId');

      // Get linked templates for the menu item
      final templates = await _templateRepository.getMenuItemTemplates(menuItemId);
      
      // Convert templates to MenuItemCustomization format
      final templateCustomizations = templates.map((template) => 
        _convertTemplateToCustomization(template)
      ).toList();

      debugPrint('✅ [TEMPLATE-INTEGRATION] Resolved ${templateCustomizations.length} template customizations');
      return templateCustomizations;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Error resolving customizations: $e');
      return [];
    }
  }

  /// Converts a CustomizationTemplate to MenuItemCustomization format
  product_model.MenuItemCustomization _convertTemplateToCustomization(
    CustomizationTemplate template,
  ) {
    return product_model.MenuItemCustomization(
      id: template.id,
      name: template.name,
      type: template.isSingleSelection ? 'radio' : 'checkbox',
      isRequired: template.isRequired,
      options: template.options.map((option) => 
        product_model.CustomizationOption(
          id: option.id,
          name: option.name,
          additionalPrice: option.additionalPrice,
          isDefault: option.isDefault,
        )
      ).toList(),
    );
  }

  /// Validates customization selections against template requirements
  ValidationResult validateCustomizationSelections({
    required String menuItemId,
    required Map<String, dynamic> selections,
    required List<CustomizationTemplate> templates,
  }) {
    final errors = <String>[];
    final warnings = <String>[];

    for (final template in templates) {
      final templateId = template.id;
      final selection = selections[templateId];

      // Check required templates
      if (template.isRequired && (selection == null || _isSelectionEmpty(selection))) {
        errors.add('${template.name} is required');
        continue;
      }

      // Validate single selection templates
      if (template.isSingleSelection && selection != null) {
        if (selection is List && selection.length > 1) {
          errors.add('${template.name} allows only one selection');
        }
      }

      // Validate option existence
      if (selection != null && !_isSelectionEmpty(selection)) {
        final validOptionIds = template.options.map((o) => o.id).toSet();
        final selectedOptionIds = _extractOptionIds(selection);
        
        for (final optionId in selectedOptionIds) {
          if (!validOptionIds.contains(optionId)) {
            warnings.add('Invalid option selected for ${template.name}');
          }
        }
      }
    }

    return ValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Calculates additional cost from template-based customizations
  double calculateTemplateCustomizationCost({
    required Map<String, dynamic> selections,
    required List<CustomizationTemplate> templates,
  }) {
    double totalCost = 0.0;

    for (final template in templates) {
      final selection = selections[template.id];
      if (selection == null || _isSelectionEmpty(selection)) continue;

      final selectedOptionIds = _extractOptionIds(selection);
      
      for (final optionId in selectedOptionIds) {
        final option = template.options.firstWhere(
          (o) => o.id == optionId,
          orElse: () => throw Exception('Option not found: $optionId'),
        );
        totalCost += option.additionalPrice;
      }
    }

    return totalCost;
  }

  /// Formats customization selections for display
  String formatCustomizationSelections({
    required Map<String, dynamic> selections,
    required List<CustomizationTemplate> templates,
  }) {
    final parts = <String>[];

    for (final template in templates) {
      final selection = selections[template.id];
      if (selection == null || _isSelectionEmpty(selection)) continue;

      final selectedOptions = <String>[];
      final selectedOptionIds = _extractOptionIds(selection);
      
      for (final optionId in selectedOptionIds) {
        try {
          final option = template.options.firstWhere((o) => o.id == optionId);
          selectedOptions.add(option.name);
        } catch (e) {
          // Option not found, skip
        }
      }

      if (selectedOptions.isNotEmpty) {
        parts.add('${template.name}: ${selectedOptions.join(', ')}');
      }
    }

    return parts.isNotEmpty ? parts.join('\n') : 'No customizations';
  }

  /// Converts template-based selections to order item format
  Map<String, dynamic> convertSelectionsToOrderFormat({
    required Map<String, dynamic> selections,
    required List<CustomizationTemplate> templates,
  }) {
    final orderCustomizations = <String, dynamic>{};

    for (final template in templates) {
      final selection = selections[template.id];
      if (selection == null || _isSelectionEmpty(selection)) continue;

      final selectedOptionIds = _extractOptionIds(selection);
      final selectedOptions = <Map<String, dynamic>>[];

      for (final optionId in selectedOptionIds) {
        try {
          final option = template.options.firstWhere((o) => o.id == optionId);
          selectedOptions.add({
            'id': option.id,
            'name': option.name,
            'price': option.additionalPrice,
            'template_id': template.id,
            'template_name': template.name,
          });
        } catch (e) {
          // Option not found, skip
        }
      }

      if (selectedOptions.isNotEmpty) {
        orderCustomizations[template.id] = template.isSingleSelection 
            ? selectedOptions.first 
            : selectedOptions;
      }
    }

    return orderCustomizations;
  }

  /// Merges template-based and direct customizations
  Map<String, dynamic> mergeCustomizations({
    required Map<String, dynamic> templateSelections,
    required Map<String, dynamic> directCustomizations,
    required List<CustomizationTemplate> templates,
  }) {
    final merged = <String, dynamic>{};

    // Add direct customizations first
    merged.addAll(directCustomizations);

    // Add template-based customizations
    final templateCustomizations = convertSelectionsToOrderFormat(
      selections: templateSelections,
      templates: templates,
    );
    merged.addAll(templateCustomizations);

    return merged;
  }

  /// Extracts option IDs from selection data
  List<String> _extractOptionIds(dynamic selection) {
    if (selection is String) {
      return [selection];
    } else if (selection is Map<String, dynamic>) {
      final id = selection['id'];
      return id != null ? [id.toString()] : [];
    } else if (selection is List) {
      return selection.map((item) {
        if (item is String) return item;
        if (item is Map<String, dynamic>) {
          final id = item['id'];
          return id?.toString() ?? '';
        }
        return '';
      }).where((id) => id.isNotEmpty).toList();
    }
    return [];
  }

  /// Checks if a selection is empty
  bool _isSelectionEmpty(dynamic selection) {
    if (selection == null) return true;
    if (selection is String) return selection.isEmpty;
    if (selection is List) return selection.isEmpty;
    if (selection is Map) return selection.isEmpty;
    return false;
  }

  /// Updates template usage statistics after order completion
  Future<void> updateTemplateUsageStats({
    required String orderId,
    required Map<String, dynamic> customizations,
  }) async {
    try {
      debugPrint('📊 [TEMPLATE-INTEGRATION] Updating template usage stats for order: $orderId');

      // Extract template IDs from customizations
      final templateIds = <String>{};
      
      for (final value in customizations.values) {
        if (value is Map<String, dynamic> && value.containsKey('template_id')) {
          templateIds.add(value['template_id'].toString());
        } else if (value is List) {
          for (final item in value) {
            if (item is Map<String, dynamic> && item.containsKey('template_id')) {
              templateIds.add(item['template_id'].toString());
            }
          }
        }
      }

      // Update usage count for each template
      for (final templateId in templateIds) {
        try {
          await _templateRepository.updateTemplateUsageCount(templateId);
        } catch (e) {
          debugPrint('⚠️ [TEMPLATE-INTEGRATION] Failed to update usage for template $templateId: $e');
        }
      }

      debugPrint('✅ [TEMPLATE-INTEGRATION] Updated usage stats for ${templateIds.length} templates');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Error updating template usage stats: $e');
    }
  }

  // ==================== ENHANCED TEMPLATE-ONLY WORKFLOW METHODS ====================

  /// Migrate menu item from direct customizations to template-only
  Future<bool> migrateMenuItemToTemplateOnly({
    required String menuItemId,
    required List<String> templateIds,
    bool preserveDirectCustomizations = false,
  }) async {
    final session = TemplateDebugLogger.createSession('migrate_menu_item_to_template_only');

    session.addEvent('Starting migration for menu item: $menuItemId');
    session.addEvent('Template IDs to link: ${templateIds.length}');
    session.addEvent('Preserve direct customizations: $preserveDirectCustomizations');

    TemplateDebugLogger.logWorkflowEvent(
      workflow: 'template_migration',
      event: 'started',
      data: {
        'menuItemId': menuItemId,
        'templateIds': templateIds,
        'preserveDirectCustomizations': preserveDirectCustomizations,
      },
    );

    if (_menuItemRepository == null || _supabase == null) {
      TemplateDebugLogger.logError(
        operation: 'migrate_menu_item_to_template_only',
        error: 'Menu item repository or Supabase client not available',
        context: {
          'menuItemId': menuItemId,
          'hasMenuItemRepository': _menuItemRepository != null,
          'hasSupabaseClient': _supabase != null,
        },
      );
      session.complete('error: missing dependencies');
      return false;
    }

    try {
      // Get current menu item
      final menuItem = await _menuItemRepository!.getMenuItemById(menuItemId);
      if (menuItem == null) {
        throw Exception('Menu item not found: $menuItemId');
      }

      // Link templates to menu item
      for (int i = 0; i < templateIds.length; i++) {
        await _templateRepository.linkTemplateToMenuItem(
          menuItemId: menuItemId,
          templateId: templateIds[i],
          displayOrder: i,
        );
      }

      // If not preserving direct customizations, clear them
      if (!preserveDirectCustomizations) {
        final updatedMenuItem = menuItem.copyWith(customizations: []);
        await _menuItemRepository!.updateMenuItem(updatedMenuItem);
      }

      debugPrint('✅ [TEMPLATE-INTEGRATION] Successfully migrated menu item to template-only');
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Error migrating menu item: $e');
      return false;
    }
  }

  /// Sync template usage counts across all menu items
  Future<void> syncTemplateUsageCounts(String vendorId) async {
    debugPrint('🔄 [TEMPLATE-INTEGRATION] Syncing template usage counts for vendor: $vendorId');

    try {
      // Get all templates for vendor
      final templates = await _templateRepository.getVendorTemplates(vendorId);

      for (final template in templates) {
        // Get menu items using this template
        final menuItemIds = await _templateRepository.getMenuItemsUsingTemplate(template.id);

        // Update usage count if different
        if (template.usageCount != menuItemIds.length) {
          final updatedTemplate = template.copyWith(usageCount: menuItemIds.length);
          await _templateRepository.updateTemplate(updatedTemplate);
          debugPrint('🔄 [TEMPLATE-INTEGRATION] Updated usage count for template ${template.name}: ${menuItemIds.length}');
        }
      }

      debugPrint('✅ [TEMPLATE-INTEGRATION] Template usage counts synced for vendor: $vendorId');
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Error syncing template usage counts: $e');
      rethrow;
    }
  }

  /// Validate template-menu item relationships for template-only workflow
  Future<Map<String, dynamic>> validateTemplateOnlyWorkflow(String vendorId) async {
    debugPrint('🔍 [TEMPLATE-INTEGRATION] Validating template-only workflow for vendor: $vendorId');

    if (_menuItemRepository == null) {
      return {
        'valid': false,
        'issues': ['Menu item repository not available'],
        'statistics': {},
      };
    }

    try {
      final validation = <String, dynamic>{
        'valid': true,
        'issues': <String>[],
        'statistics': <String, dynamic>{},
      };

      // Get all templates and menu items for vendor
      final templates = await _templateRepository.getVendorTemplates(vendorId);
      final menuItems = await _menuItemRepository!.getMenuItems(vendorId);

      // Check for orphaned templates (no menu items using them)
      final orphanedTemplates = <String>[];
      for (final template in templates) {
        final menuItemIds = await _templateRepository.getMenuItemsUsingTemplate(template.id);
        if (menuItemIds.isEmpty && template.isActive) {
          orphanedTemplates.add(template.name);
        }
      }

      if (orphanedTemplates.isNotEmpty) {
        validation['issues'].add('Orphaned templates: ${orphanedTemplates.join(', ')}');
        validation['valid'] = false;
      }

      // Check for menu items with both direct customizations and templates
      final hybridMenuItems = <String>[];
      for (final menuItem in menuItems) {
        final linkedTemplates = await _templateRepository.getMenuItemTemplates(menuItem.id);
        if (menuItem.customizations.isNotEmpty && linkedTemplates.isNotEmpty) {
          hybridMenuItems.add(menuItem.name);
        }
      }

      if (hybridMenuItems.isNotEmpty) {
        validation['issues'].add('Menu items with both direct customizations and templates: ${hybridMenuItems.join(', ')}');
        validation['valid'] = false;
      }

      // Generate statistics
      validation['statistics'] = {
        'total_templates': templates.length,
        'active_templates': templates.where((t) => t.isActive).length,
        'total_menu_items': menuItems.length,
        'menu_items_with_templates': 0, // TODO: Calculate based on template links
        'menu_items_with_direct_customizations': menuItems.where((m) => m.customizations.isNotEmpty).length,
        'orphaned_templates_count': orphanedTemplates.length,
        'hybrid_menu_items_count': hybridMenuItems.length,
        'template_only_adoption_rate': '0.0', // TODO: Calculate based on template links
      };

      debugPrint('✅ [TEMPLATE-INTEGRATION] Validation completed for vendor: $vendorId');
      return validation;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Error validating template-only workflow: $e');
      return {
        'valid': false,
        'issues': ['Validation failed: $e'],
        'statistics': {},
      };
    }
  }

  /// Update template display order for a menu item
  Future<bool> updateTemplateDisplayOrder({
    required String menuItemId,
    required List<String> templateIds,
  }) async {
    debugPrint('🔄 [TEMPLATE-INTEGRATION] Updating template display order for menu item: $menuItemId');

    if (_supabase == null) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Supabase client not available');
      return false;
    }

    try {
      // Update display order for each template
      for (int i = 0; i < templateIds.length; i++) {
        await _supabase!
            .from('menu_item_template_links')
            .update({'display_order': i})
            .eq('menu_item_id', menuItemId)
            .eq('template_id', templateIds[i]);
      }

      debugPrint('✅ [TEMPLATE-INTEGRATION] Template display order updated for menu item: $menuItemId');
      return true;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Error updating template display order: $e');
      return false;
    }
  }

  /// Clean up orphaned template links
  Future<int> cleanupOrphanedTemplateLinks() async {
    debugPrint('🧹 [TEMPLATE-INTEGRATION] Cleaning up orphaned template links');

    if (_supabase == null) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Supabase client not available');
      return 0;
    }

    try {
      // Get all links
      final allLinks = await _supabase!
          .from('menu_item_template_links')
          .select('id, menu_item_id, template_id');

      int deletedCount = 0;

      for (final link in allLinks) {
        // Check if menu item exists
        final menuItemExists = await _supabase!
            .from('menu_items')
            .select('id')
            .eq('id', link['menu_item_id'])
            .maybeSingle();

        // Check if template exists
        final templateExists = await _supabase!
            .from('customization_templates')
            .select('id')
            .eq('id', link['template_id'])
            .maybeSingle();

        // Delete link if either menu item or template doesn't exist
        if (menuItemExists == null || templateExists == null) {
          await _supabase!
              .from('menu_item_template_links')
              .delete()
              .eq('id', link['id']);

          deletedCount++;
          debugPrint('🧹 [TEMPLATE-INTEGRATION] Deleted orphaned link: ${link['id']}');
        }
      }

      debugPrint('✅ [TEMPLATE-INTEGRATION] Cleanup completed: $deletedCount orphaned links removed');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ [TEMPLATE-INTEGRATION] Error cleaning up orphaned links: $e');
      return 0;
    }
  }
}

/// Result of customization validation
class ValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const ValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });

  bool get hasWarnings => warnings.isNotEmpty;
  bool get hasErrors => errors.isNotEmpty;
}
