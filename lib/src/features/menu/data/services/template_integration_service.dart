import 'package:flutter/foundation.dart';

import '../models/customization_template.dart';
import '../models/product.dart' as product_model;
import '../repositories/customization_template_repository.dart';

/// Service for integrating template-based customizations with order processing
class TemplateIntegrationService {
  final CustomizationTemplateRepository _templateRepository;

  /// Getter to access the template repository
  CustomizationTemplateRepository get templateRepository => _templateRepository;

  TemplateIntegrationService(this._templateRepository);

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
