import 'package:flutter/foundation.dart';
import '../models/product.dart';

/// Service for converting between complex customization objects and simple text format
class CustomizationFormatter {
  
  /// Convert MenuItemCustomization objects to simple text format
  /// Format: "Group: Option1(+price), Option2(+price); NextGroup: Option1(+price)"
  static String formatCustomizationsToText(List<MenuItemCustomization> customizations) {
    if (customizations.isEmpty) return '';
    
    final groups = <String>[];
    
    for (final customization in customizations) {
      final groupName = customization.isRequired ? '${customization.name}*' : customization.name;
      final options = <String>[];
      
      for (final option in customization.options) {
        final price = option.additionalPrice;
        final priceText = price == 0 ? '+0' : '+${price.toStringAsFixed(2)}';
        options.add('${option.name}($priceText)');
      }
      
      if (options.isNotEmpty) {
        groups.add('$groupName: ${options.join(', ')}');
      }
    }
    
    return groups.join('; ');
  }
  
  /// Parse simple text format back to MenuItemCustomization objects
  /// Input: "Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50), Bacon(+2.00)"
  static List<MenuItemCustomization> parseCustomizationsFromText(String text) {
    if (text.trim().isEmpty) return [];
    
    final customizations = <MenuItemCustomization>[];
    
    try {
      // Split by semicolon to get groups
      final groups = text.split(';').map((g) => g.trim()).where((g) => g.isNotEmpty);
      
      for (final group in groups) {
        final customization = _parseCustomizationGroup(group);
        if (customization != null) {
          customizations.add(customization);
        }
      }
    } catch (e) {
      debugPrint('❌ [CUSTOMIZATION-FORMATTER] Error parsing customizations: $e');
      debugPrint('❌ [CUSTOMIZATION-FORMATTER] Input text: $text');
      // Return empty list instead of throwing to prevent import failures
      return [];
    }
    
    return customizations;
  }
  
  /// Parse a single customization group
  /// Input: "Size*: Small(+0), Large(+2.00)"
  static MenuItemCustomization? _parseCustomizationGroup(String groupText) {
    try {
      // Split by colon to separate group name from options
      final colonIndex = groupText.indexOf(':');
      if (colonIndex == -1) {
        debugPrint('⚠️ [CUSTOMIZATION-FORMATTER] Invalid group format (no colon): $groupText');
        return null;
      }
      
      final groupNamePart = groupText.substring(0, colonIndex).trim();
      final optionsPart = groupText.substring(colonIndex + 1).trim();
      
      // Check if required (ends with *)
      final isRequired = groupNamePart.endsWith('*');
      final groupName = isRequired ? groupNamePart.substring(0, groupNamePart.length - 1) : groupNamePart;
      
      // Parse options
      final options = _parseOptions(optionsPart);
      if (options.isEmpty) {
        debugPrint('⚠️ [CUSTOMIZATION-FORMATTER] No valid options found for group: $groupName');
        return null;
      }
      
      return MenuItemCustomization(
        name: groupName,
        type: 'single', // Default to single selection, can be enhanced later
        isRequired: isRequired,
        options: options,
      );
    } catch (e) {
      debugPrint('❌ [CUSTOMIZATION-FORMATTER] Error parsing group: $groupText, Error: $e');
      return null;
    }
  }
  
  /// Parse options from text
  /// Input: "Small(+0), Large(+2.00), Extra Large(+4.00)"
  static List<CustomizationOption> _parseOptions(String optionsText) {
    final options = <CustomizationOption>[];
    
    try {
      // Split by comma to get individual options
      final optionTexts = optionsText.split(',').map((o) => o.trim()).where((o) => o.isNotEmpty);
      
      for (final optionText in optionTexts) {
        final option = _parseOption(optionText);
        if (option != null) {
          options.add(option);
        }
      }
    } catch (e) {
      debugPrint('❌ [CUSTOMIZATION-FORMATTER] Error parsing options: $optionsText, Error: $e');
    }
    
    return options;
  }
  
  /// Parse a single option
  /// Input: "Large(+2.00)" or "Small(+0)"
  static CustomizationOption? _parseOption(String optionText) {
    try {
      // Find the last opening parenthesis
      final openParenIndex = optionText.lastIndexOf('(');
      final closeParenIndex = optionText.lastIndexOf(')');
      
      if (openParenIndex == -1 || closeParenIndex == -1 || closeParenIndex <= openParenIndex) {
        debugPrint('⚠️ [CUSTOMIZATION-FORMATTER] Invalid option format (no parentheses): $optionText');
        return null;
      }
      
      final optionName = optionText.substring(0, openParenIndex).trim();
      final priceText = optionText.substring(openParenIndex + 1, closeParenIndex).trim();
      
      if (optionName.isEmpty) {
        debugPrint('⚠️ [CUSTOMIZATION-FORMATTER] Empty option name: $optionText');
        return null;
      }
      
      // Parse price (remove + sign if present)
      final cleanPriceText = priceText.startsWith('+') ? priceText.substring(1) : priceText;
      final price = double.tryParse(cleanPriceText) ?? 0.0;
      
      return CustomizationOption(
        id: '', // Will be generated when saved to database
        name: optionName,
        additionalPrice: price,
        isDefault: false, // Could be enhanced to support default options
      );
    } catch (e) {
      debugPrint('❌ [CUSTOMIZATION-FORMATTER] Error parsing option: $optionText, Error: $e');
      return null;
    }
  }
  
  /// Validate customization text format
  static ValidationResult validateCustomizationText(String text) {
    if (text.trim().isEmpty) {
      return ValidationResult(isValid: true, message: 'No customizations specified');
    }
    
    try {
      final customizations = parseCustomizationsFromText(text);
      
      if (customizations.isEmpty) {
        return ValidationResult(
          isValid: false, 
          message: 'Invalid customization format. Expected: "Group: Option1(+price), Option2(+price)"'
        );
      }
      
      // Additional validation
      for (final customization in customizations) {
        if (customization.name.trim().isEmpty) {
          return ValidationResult(isValid: false, message: 'Empty group name found');
        }
        
        if (customization.options.isEmpty) {
          return ValidationResult(
            isValid: false, 
            message: 'Group "${customization.name}" has no options'
          );
        }
        
        for (final option in customization.options) {
          if (option.name.trim().isEmpty) {
            return ValidationResult(
              isValid: false, 
              message: 'Empty option name found in group "${customization.name}"'
            );
          }
          
          if (option.additionalPrice < 0) {
            return ValidationResult(
              isValid: false,
              message: 'Negative price found for option "${option.name}" in group "${customization.name}"'
            );
          }
        }
      }
      
      return ValidationResult(
        isValid: true, 
        message: 'Valid customization format with ${customizations.length} group(s)'
      );
    } catch (e) {
      return ValidationResult(
        isValid: false, 
        message: 'Error parsing customizations: $e'
      );
    }
  }
  
  /// Generate example customization text for documentation
  static String getExampleCustomizationText() {
    return 'Size*: Small(+0), Medium(+2.00), Large(+4.00); Add-ons: Extra Cheese(+1.50), Bacon(+2.00); Spice Level: Mild(+0), Hot(+0), Extra Hot(+1.00)';
  }
  
  /// Get format documentation
  static String getFormatDocumentation() {
    return '''
Customization Format Guide:
• Groups separated by semicolons (;)
• Options separated by commas (,)
• Prices in parentheses: (+0) for free, (+2.00) for RM2.00
• Required groups marked with asterisk (*): Size*
• Example: "Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50)"
''';
  }
}

/// Result of customization validation
class ValidationResult {
  final bool isValid;
  final String message;
  
  const ValidationResult({required this.isValid, required this.message});
}
