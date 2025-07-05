import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/features/menu/data/models/customization_template.dart';

void main() {
  group('CustomizationTemplate Model Tests', () {
    test('should create template with required properties', () {
      // Arrange & Act
      final template = CustomizationTemplate(
        id: 'template-123',
        vendorId: 'vendor-456',
        name: 'Size Options',
        description: 'Choose your preferred size',
        type: 'single',
        isRequired: true,
        displayOrder: 1,
        isActive: true,
        usageCount: 5,
        options: [],
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );

      // Assert
      expect(template.id, 'template-123');
      expect(template.vendorId, 'vendor-456');
      expect(template.name, 'Size Options');
      expect(template.description, 'Choose your preferred size');
      expect(template.type, 'single');
      expect(template.isRequired, true);
      expect(template.displayOrder, 1);
      expect(template.isActive, true);
      expect(template.usageCount, 5);
    });

    test('should identify single selection type', () {
      // Arrange
      final singleTemplate = CustomizationTemplate(
        id: 'template-1',
        vendorId: 'vendor-1',
        name: 'Size',
        type: 'single',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(singleTemplate.isSingleSelection, isTrue);
      expect(singleTemplate.isMultipleSelection, isFalse);
    });

    test('should identify multiple selection type', () {
      // Arrange
      final multipleTemplate = CustomizationTemplate(
        id: 'template-1',
        vendorId: 'vendor-1',
        name: 'Toppings',
        type: 'multiple',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(multipleTemplate.isMultipleSelection, isTrue);
      expect(multipleTemplate.isSingleSelection, isFalse);
    });

    test('should validate template correctly', () {
      // Arrange
      final validTemplate = CustomizationTemplate(
        id: 'template-1',
        vendorId: 'vendor-1',
        name: 'Size Options',
        type: 'single',
        options: [
          TemplateOption(
            id: 'option-1',
            templateId: 'template-1',
            name: 'Small',
            isDefault: true,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final invalidTemplate = CustomizationTemplate(
        id: 'template-2',
        vendorId: 'vendor-1',
        name: '', // Empty name
        type: 'single',
        options: [], // No options
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act & Assert
      expect(validTemplate.isValid, isTrue);
      expect(invalidTemplate.isValid, isFalse);
    });

    test('should create template for creation', () {
      // Act
      final template = CustomizationTemplate.create(
        vendorId: 'vendor-123',
        name: 'Test Template',
        description: 'Test description',
        type: 'single',
        isRequired: true,
      );

      // Assert
      expect(template.vendorId, equals('vendor-123'));
      expect(template.name, equals('Test Template'));
      expect(template.description, equals('Test description'));
      expect(template.type, equals('single'));
      expect(template.isRequired, isTrue);
      expect(template.id, isEmpty); // Should be empty for creation
    });

    test('should copy template with updated fields', () {
      // Arrange
      final original = CustomizationTemplate(
        id: 'template-1',
        vendorId: 'vendor-1',
        name: 'Original Name',
        type: 'single',
        isRequired: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Act
      final updated = original.copyWith(
        name: 'Updated Name',
        isRequired: true,
      );

      // Assert
      expect(updated.id, equals(original.id));
      expect(updated.vendorId, equals(original.vendorId));
      expect(updated.name, equals('Updated Name'));
      expect(updated.isRequired, isTrue);
      expect(updated.type, equals(original.type));
    });
  });
}
