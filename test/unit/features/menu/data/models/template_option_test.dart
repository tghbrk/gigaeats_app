import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/features/menu/data/models/customization_template.dart';

void main() {
  group('TemplateOption Model Tests', () {
    late Map<String, dynamic> validOptionJson;
    late TemplateOption validOption;

    setUp(() {
      validOptionJson = {
        'id': 'option-123',
        'template_id': 'template-456',
        'name': 'Large',
        'additional_price': 5.50,
        'display_order': 1,
        'is_available': true,
        'created_at': '2024-01-01T00:00:00Z',
        'updated_at': '2024-01-01T00:00:00Z',
      };

      validOption = TemplateOption(
        id: 'option-123',
        templateId: 'template-456',
        name: 'Large',
        additionalPrice: 5.50,
        displayOrder: 1,
        isAvailable: true,
        createdAt: DateTime.parse('2024-01-01T00:00:00Z'),
        updatedAt: DateTime.parse('2024-01-01T00:00:00Z'),
      );
    });

    group('JSON Serialization', () {
      test('should create TemplateOption from valid JSON', () {
        // Act
        final option = TemplateOption.fromJson(validOptionJson);

        // Assert
        expect(option.id, equals('option-123'));
        expect(option.templateId, equals('template-456'));
        expect(option.name, equals('Large'));
        expect(option.additionalPrice, equals(5.50));
        expect(option.price, equals(5.50)); // Backward compatibility getter
        expect(option.displayOrder, equals(1));
        expect(option.isAvailable, isTrue);
        expect(option.createdAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
        expect(option.updatedAt, equals(DateTime.parse('2024-01-01T00:00:00Z')));
      });

      test('should convert TemplateOption to JSON', () {
        // Act
        final json = validOption.toJson();

        // Assert
        expect(json['id'], equals('option-123'));
        expect(json['template_id'], equals('template-456'));
        expect(json['name'], equals('Large'));
        expect(json['additional_price'], equals(5.50));
        expect(json['display_order'], equals(1));
        expect(json['is_available'], isTrue);
        expect(json['created_at'], equals('2024-01-01T00:00:00Z'));
        expect(json['updated_at'], equals('2024-01-01T00:00:00Z'));
      });

      test('should handle missing optional fields in JSON', () {
        // Arrange
        final minimalJson = {
          'id': 'option-123',
          'template_id': 'template-456',
          'name': 'Large',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        // Act
        final option = TemplateOption.fromJson(minimalJson);

        // Assert
        expect(option.id, equals('option-123'));
        expect(option.templateId, equals('template-456'));
        expect(option.name, equals('Large'));
        expect(option.additionalPrice, equals(0.0)); // Default value
        expect(option.price, equals(0.0)); // Default value via getter
        expect(option.displayOrder, equals(0)); // Default value
        expect(option.isAvailable, isTrue); // Default value
      });
    });

    group('Validation', () {
      test('should validate required fields', () {
        // Act & Assert
        expect(() => TemplateOption.fromJson({}), throwsA(isA<TypeError>()));
      });

      test('should validate name is not empty', () {
        // Arrange
        final invalidJson = Map<String, dynamic>.from(validOptionJson);
        invalidJson['name'] = '';

        // Act
        final option = TemplateOption.fromJson(invalidJson);

        // Assert
        expect(option.isValid, isFalse);
      });

      test('should validate template_id is not empty', () {
        // Arrange
        final invalidJson = Map<String, dynamic>.from(validOptionJson);
        invalidJson['template_id'] = '';

        // Act
        final option = TemplateOption.fromJson(invalidJson);

        // Assert
        expect(option.isValid, isFalse);
      });

      test('should validate price is not negative', () {
        // Arrange
        final invalidJson = Map<String, dynamic>.from(validOptionJson);
        invalidJson['price'] = -1.0;

        // Act
        final option = TemplateOption.fromJson(invalidJson);

        // Assert
        expect(option.isValid, isFalse);
      });

      test('should be valid with all required fields', () {
        // Act & Assert
        expect(validOption.isValid, isTrue);
      });

      test('should be valid with zero price', () {
        // Arrange
        final freeOption = validOption.copyWith(additionalPrice: 0.0);

        // Act & Assert
        expect(freeOption.isValid, isTrue);
      });
    });

    group('Equality and Hashing', () {
      test('should be equal when all properties match', () {
        // Arrange
        final option1 = TemplateOption.fromJson(validOptionJson);
        final option2 = TemplateOption.fromJson(validOptionJson);

        // Act & Assert
        expect(option1, equals(option2));
        expect(option1.hashCode, equals(option2.hashCode));
      });

      test('should not be equal when properties differ', () {
        // Arrange
        final option1 = validOption;
        final option2 = validOption.copyWith(name: 'Medium');

        // Act & Assert
        expect(option1, isNot(equals(option2)));
        expect(option1.hashCode, isNot(equals(option2.hashCode)));
      });
    });

    group('Copy With', () {
      test('should create copy with updated properties', () {
        // Act
        final updatedOption = validOption.copyWith(
          name: 'Extra Large',
          additionalPrice: 7.50,
          isAvailable: false,
        );

        // Assert
        expect(updatedOption.id, equals(validOption.id));
        expect(updatedOption.templateId, equals(validOption.templateId));
        expect(updatedOption.name, equals('Extra Large'));
        expect(updatedOption.additionalPrice, equals(7.50));
        expect(updatedOption.price, equals(7.50)); // Backward compatibility getter
        expect(updatedOption.isAvailable, isFalse);
      });

      test('should preserve original when no changes provided', () {
        // Act
        final copiedOption = validOption.copyWith();

        // Assert
        expect(copiedOption, equals(validOption));
      });
    });

    group('Business Logic', () {
      test('should identify free options', () {
        // Arrange
        final freeOption = validOption.copyWith(additionalPrice: 0.0);
        final paidOption = validOption.copyWith(additionalPrice: 5.50);

        // Act & Assert
        expect(freeOption.isFree, isTrue);
        expect(paidOption.isFree, isFalse);
      });

      test('should identify premium options', () {
        // Arrange
        final premiumOption = validOption.copyWith(additionalPrice: 15.0);
        final regularOption = validOption.copyWith(additionalPrice: 3.0);

        // Act & Assert
        expect(premiumOption.isPremium, isTrue);
        expect(regularOption.isPremium, isFalse);
      });

      test('should format price correctly', () {
        // Arrange
        final freeOption = validOption.copyWith(additionalPrice: 0.0);
        final paidOption = validOption.copyWith(additionalPrice: 5.50);
        final expensiveOption = validOption.copyWith(additionalPrice: 12.99);

        // Act & Assert
        expect(freeOption.formattedPrice, equals('Free'));
        expect(paidOption.formattedPrice, equals('RM 5.50'));
        expect(expensiveOption.formattedPrice, equals('RM 12.99'));
      });

      test('should calculate display priority correctly', () {
        // Arrange
        final highPriorityOption = validOption.copyWith(displayOrder: 1);
        final lowPriorityOption = validOption.copyWith(displayOrder: 10);

        // Act & Assert
        expect(highPriorityOption.displayOrder, lessThan(lowPriorityOption.displayOrder));
      });
    });

    group('Test Factory Methods', () {
      test('should create test option with default values', () {
        // Act
        final testOption = TemplateOption.test();

        // Assert
        expect(testOption.id, isNotEmpty);
        expect(testOption.templateId, isNotEmpty);
        expect(testOption.name, isNotEmpty);
        expect(testOption.isValid, isTrue);
      });

      test('should create test option with custom values', () {
        // Act
        final testOption = TemplateOption.test(
          name: 'Custom Test Option',
          additionalPrice: 10.0,
          isAvailable: false,
        );

        // Assert
        expect(testOption.name, equals('Custom Test Option'));
        expect(testOption.additionalPrice, equals(10.0));
        expect(testOption.price, equals(10.0)); // Backward compatibility getter
        expect(testOption.isAvailable, isFalse);
      });
    });

    group('Edge Cases', () {
      test('should handle null values gracefully', () {
        // Arrange
        final jsonWithNulls = {
          'id': 'option-123',
          'template_id': 'template-456',
          'name': 'Large',
          'created_at': '2024-01-01T00:00:00Z',
          'updated_at': '2024-01-01T00:00:00Z',
        };

        // Act
        final option = TemplateOption.fromJson(jsonWithNulls);

        // Assert
        expect(option.additionalPrice, equals(0.0)); // Default value
        expect(option.isValid, isTrue);
      });

      test('should handle extreme price values', () {
        // Arrange
        final extremeJson = Map<String, dynamic>.from(validOptionJson);
        extremeJson['price'] = 999.99;

        // Act
        final option = TemplateOption.fromJson(extremeJson);

        // Assert
        expect(option.price, equals(999.99));
        expect(option.isValid, isTrue);
      });

      test('should handle very long names', () {
        // Arrange
        final longName = 'A' * 1000;
        final longNameJson = Map<String, dynamic>.from(validOptionJson);
        longNameJson['name'] = longName;

        // Act
        final option = TemplateOption.fromJson(longNameJson);

        // Assert
        expect(option.name, equals(longName));
        expect(option.isValid, isTrue);
      });
    });

    group('Sorting and Comparison', () {
      test('should sort by display order', () {
        // Arrange
        final option1 = validOption.copyWith(displayOrder: 3);
        final option2 = validOption.copyWith(displayOrder: 1);
        final option3 = validOption.copyWith(displayOrder: 2);
        final options = [option1, option2, option3];

        // Act
        options.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

        // Assert
        expect(options[0].displayOrder, equals(1));
        expect(options[1].displayOrder, equals(2));
        expect(options[2].displayOrder, equals(3));
      });

      test('should sort by price', () {
        // Arrange
        final option1 = validOption.copyWith(additionalPrice: 10.0);
        final option2 = validOption.copyWith(additionalPrice: 5.0);
        final option3 = validOption.copyWith(additionalPrice: 15.0);
        final options = [option1, option2, option3];

        // Act
        options.sort((a, b) => a.price.compareTo(b.price));

        // Assert
        expect(options[0].price, equals(5.0));
        expect(options[1].price, equals(10.0));
        expect(options[2].price, equals(15.0));
      });
    });
  });
}
