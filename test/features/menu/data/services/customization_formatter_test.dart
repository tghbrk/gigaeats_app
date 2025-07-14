import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/features/menu/data/services/customization_formatter.dart';
import 'package:gigaeats_app/src/features/menu/data/models/product.dart';

void main() {
  group('CustomizationFormatter', () {
    group('formatCustomizationsToText', () {
      test('should format empty list to empty string', () {
        final result = CustomizationFormatter.formatCustomizationsToText([]);
        expect(result, '');
      });

      test('should format single group with options', () {
        final customizations = [
          MenuItemCustomization(
            name: 'Size',
            type: 'single',
            isRequired: true,
            options: [
              CustomizationOption(id: '1', name: 'Small', additionalPrice: 0.0),
              CustomizationOption(id: '2', name: 'Large', additionalPrice: 2.00),
            ],
          ),
        ];

        final result = CustomizationFormatter.formatCustomizationsToText(customizations);
        expect(result, 'Size*: Small(+0), Large(+2.00)');
      });

      test('should format multiple groups', () {
        final customizations = [
          MenuItemCustomization(
            name: 'Size',
            type: 'single',
            isRequired: true,
            options: [
              CustomizationOption(id: '1', name: 'Small', additionalPrice: 0.0),
              CustomizationOption(id: '2', name: 'Large', additionalPrice: 2.00),
            ],
          ),
          MenuItemCustomization(
            name: 'Add-ons',
            type: 'multiple',
            isRequired: false,
            options: [
              CustomizationOption(id: '3', name: 'Cheese', additionalPrice: 1.50),
              CustomizationOption(id: '4', name: 'Bacon', additionalPrice: 2.00),
            ],
          ),
        ];

        final result = CustomizationFormatter.formatCustomizationsToText(customizations);
        expect(result, 'Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50), Bacon(+2.00)');
      });
    });

    group('parseCustomizationsFromText', () {
      test('should parse empty string to empty list', () {
        final result = CustomizationFormatter.parseCustomizationsFromText('');
        expect(result, isEmpty);
      });

      test('should parse single group', () {
        const text = 'Size*: Small(+0), Large(+2.00)';
        final result = CustomizationFormatter.parseCustomizationsFromText(text);

        expect(result, hasLength(1));
        expect(result[0].name, 'Size');
        expect(result[0].isRequired, true);
        expect(result[0].options, hasLength(2));
        expect(result[0].options[0].name, 'Small');
        expect(result[0].options[0].additionalPrice, 0.0);
        expect(result[0].options[1].name, 'Large');
        expect(result[0].options[1].additionalPrice, 2.00);
      });

      test('should parse multiple groups', () {
        const text = 'Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50), Bacon(+2.00)';
        final result = CustomizationFormatter.parseCustomizationsFromText(text);

        expect(result, hasLength(2));
        
        // First group
        expect(result[0].name, 'Size');
        expect(result[0].isRequired, true);
        expect(result[0].options, hasLength(2));
        
        // Second group
        expect(result[1].name, 'Add-ons');
        expect(result[1].isRequired, false);
        expect(result[1].options, hasLength(2));
        expect(result[1].options[0].name, 'Cheese');
        expect(result[1].options[0].additionalPrice, 1.50);
      });

      test('should handle complex names with spaces and special characters', () {
        const text = 'Protein Choice*: Grilled Chicken(+3.00), Beef Rendang(+4.50), Fish & Chips(+5.00)';
        final result = CustomizationFormatter.parseCustomizationsFromText(text);

        expect(result, hasLength(1));
        expect(result[0].name, 'Protein Choice');
        expect(result[0].isRequired, true);
        expect(result[0].options, hasLength(3));
        expect(result[0].options[0].name, 'Grilled Chicken');
        expect(result[0].options[1].name, 'Beef Rendang');
        expect(result[0].options[2].name, 'Fish & Chips');
      });

      test('should handle invalid format gracefully', () {
        const text = 'Invalid format without proper structure';
        final result = CustomizationFormatter.parseCustomizationsFromText(text);
        expect(result, isEmpty);
      });

      test('should handle malformed prices gracefully', () {
        const text = 'Size: Small(invalid), Large(+2.00)';
        final result = CustomizationFormatter.parseCustomizationsFromText(text);

        expect(result, hasLength(1));
        expect(result[0].options, hasLength(2));
        expect(result[0].options[0].additionalPrice, 0.0); // Default to 0 for invalid price
        expect(result[0].options[1].additionalPrice, 2.00);
      });
    });

    group('validateCustomizationText', () {
      test('should validate empty text as valid', () {
        final result = CustomizationFormatter.validateCustomizationText('');
        expect(result.isValid, true);
      });

      test('should validate correct format', () {
        const text = 'Size*: Small(+0), Large(+2.00); Add-ons: Cheese(+1.50)';
        final result = CustomizationFormatter.validateCustomizationText(text);
        expect(result.isValid, true);
        expect(result.message, contains('2 group(s)'));
      });

      test('should reject invalid format', () {
        const text = 'Invalid format';
        final result = CustomizationFormatter.validateCustomizationText(text);
        expect(result.isValid, false);
        expect(result.message, contains('Invalid customization format'));
      });

      test('should reject negative prices', () {
        const text = 'Size: Small(+0), Large(-2.00)';
        final result = CustomizationFormatter.validateCustomizationText(text);
        expect(result.isValid, false);
        expect(result.message, contains('Negative price'));
      });
    });

    group('round-trip conversion', () {
      test('should maintain data integrity through format->parse->format cycle', () {
        final originalCustomizations = [
          MenuItemCustomization(
            name: 'Size',
            type: 'single',
            isRequired: true,
            options: [
              CustomizationOption(id: '1', name: 'Small', additionalPrice: 0.0),
              CustomizationOption(id: '2', name: 'Medium', additionalPrice: 2.00),
              CustomizationOption(id: '3', name: 'Large', additionalPrice: 4.00),
            ],
          ),
          MenuItemCustomization(
            name: 'Spice Level',
            type: 'single',
            isRequired: false,
            options: [
              CustomizationOption(id: '4', name: 'Mild', additionalPrice: 0.0),
              CustomizationOption(id: '5', name: 'Hot', additionalPrice: 0.0),
              CustomizationOption(id: '6', name: 'Extra Hot', additionalPrice: 1.00),
            ],
          ),
        ];

        // Format to text
        final text = CustomizationFormatter.formatCustomizationsToText(originalCustomizations);
        
        // Parse back to objects
        final parsedCustomizations = CustomizationFormatter.parseCustomizationsFromText(text);
        
        // Format again to text
        final finalText = CustomizationFormatter.formatCustomizationsToText(parsedCustomizations);

        // Should be identical
        expect(finalText, text);
        expect(parsedCustomizations, hasLength(originalCustomizations.length));
        
        // Check first group
        expect(parsedCustomizations[0].name, originalCustomizations[0].name);
        expect(parsedCustomizations[0].isRequired, originalCustomizations[0].isRequired);
        expect(parsedCustomizations[0].options, hasLength(originalCustomizations[0].options.length));
        
        // Check option details
        for (int i = 0; i < parsedCustomizations[0].options.length; i++) {
          expect(parsedCustomizations[0].options[i].name, originalCustomizations[0].options[i].name);
          expect(parsedCustomizations[0].options[i].additionalPrice, originalCustomizations[0].options[i].additionalPrice);
        }
      });
    });
  });
}
