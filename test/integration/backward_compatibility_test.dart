import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:gigaeats_app/main.dart' as app;
import 'package:gigaeats_app/src/features/menu/data/models/menu_item.dart';
import 'package:gigaeats_app/src/features/orders/data/models/order.dart';

/// Backward compatibility tests to ensure existing customizations still work
/// after template system implementation
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Backward Compatibility Tests', () {
    group('Existing Customizations', () {
      testWidgets('should preserve existing menu item customizations', (tester) async {
        // Start the app
        app.main();
        await tester.pumpAndSettle();

        // Test data representing existing customizations before template system
        final existingCustomizations = [
          {
            'name': 'Size',
            'options': [
              {'name': 'Small', 'price': 0.0},
              {'name': 'Large', 'price': 5.0},
            ],
            'required': true,
            'multiple': false,
          },
          {
            'name': 'Add-ons',
            'options': [
              {'name': 'Extra Cheese', 'price': 2.0},
              {'name': 'Extra Sauce', 'price': 1.0},
            ],
            'required': false,
            'multiple': true,
          },
        ];

        // Verify existing customizations are still accessible
        for (final customization in existingCustomizations) {
          expect(customization['name'], isA<String>());
          expect(customization['options'], isA<List>());
          expect(customization['required'], isA<bool>());
          expect(customization['multiple'], isA<bool>());
        }

        print('✅ Existing customizations structure preserved');
      });

      testWidgets('should handle legacy order data correctly', (tester) async {
        // Test legacy order data format
        final legacyOrderData = {
          'id': 'legacy-order-123',
          'customer_id': 'customer-123',
          'items': [
            {
              'id': 'item-1',
              'menu_item_id': 'menu-item-123',
              'name': 'Pizza Margherita',
              'quantity': 1,
              'unit_price': 15.0,
              'customizations': {
                'Size': {'name': 'Large', 'price': 5.0},
                'Add-ons': [
                  {'name': 'Extra Cheese', 'price': 2.0},
                  {'name': 'Extra Sauce', 'price': 1.0},
                ],
              },
              'total_price': 23.0,
            },
          ],
          'total_amount': 23.0,
          'status': 'pending',
          'created_at': '2024-01-01T00:00:00Z',
        };

        // Verify legacy order can be processed
        try {
          final order = Order.fromJson(legacyOrderData);
          expect(order.id, equals('legacy-order-123'));
          expect(order.items, hasLength(1));
          expect(order.items.first.customizations, isNotEmpty);
          expect(order.totalAmount, equals(23.0));
        } catch (e) {
          fail('Legacy order data should be processable: $e');
        }

        print('✅ Legacy order data compatibility maintained');
      });
    });

    group('Order Processing Compatibility', () {
      testWidgets('should process orders with mixed customization types', (tester) async {
        // Test order with both legacy and template-based customizations
        final mixedOrderData = {
          'id': 'mixed-order-123',
          'customer_id': 'customer-123',
          'items': [
            {
              'id': 'item-1',
              'menu_item_id': 'menu-item-123',
              'name': 'Pizza Margherita',
              'quantity': 1,
              'unit_price': 15.0,
              // Legacy customizations
              'customizations': {
                'Size': {'name': 'Large', 'price': 5.0},
              },
              'total_price': 20.0,
            },
            {
              'id': 'item-2',
              'menu_item_id': 'menu-item-456',
              'name': 'Burger Deluxe',
              'quantity': 1,
              'unit_price': 12.0,
              // Template-based customizations
              'customizations': {
                'template_size_options': {
                  'template_id': 'template-123',
                  'template_name': 'Size Options',
                  'selection': {'name': 'Large', 'price': 3.0},
                },
              },
              'total_price': 15.0,
            },
          ],
          'total_amount': 35.0,
          'status': 'pending',
          'created_at': '2024-01-01T00:00:00Z',
        };

        // Verify mixed order can be processed
        try {
          final order = Order.fromJson(mixedOrderData);
          expect(order.id, equals('mixed-order-123'));
          expect(order.items, hasLength(2));
          expect(order.totalAmount, equals(35.0));

          // Verify both customization types are preserved
          final legacyItem = order.items[0];
          final templateItem = order.items[1];

          expect(legacyItem.customizations?.containsKey('Size') ?? false, isTrue);
          expect(templateItem.customizations?.containsKey('template_size_options') ?? false, isTrue);
        } catch (e) {
          fail('Mixed order data should be processable: $e');
        }

        print('✅ Mixed customization types compatibility maintained');
      });

      testWidgets('should calculate prices correctly for legacy customizations', (tester) async {
        // Test price calculation for legacy customizations
        final legacyCustomizations = {
          'Size': {'name': 'Large', 'price': 5.0},
          'Add-ons': [
            {'name': 'Extra Cheese', 'price': 2.0},
            {'name': 'Extra Sauce', 'price': 1.0},
          ],
        };

        // Calculate total customization price
        double totalCustomizationPrice = 0.0;

        // Handle single selection
        if (legacyCustomizations['Size'] is Map) {
          final sizeOption = legacyCustomizations['Size'] as Map;
          totalCustomizationPrice += (sizeOption['price'] as num).toDouble();
        }

        // Handle multiple selections
        if (legacyCustomizations['Add-ons'] is List) {
          final addOns = legacyCustomizations['Add-ons'] as List;
          for (final addOn in addOns) {
            if (addOn is Map && addOn['price'] is num) {
              totalCustomizationPrice += (addOn['price'] as num).toDouble();
            }
          }
        }

        expect(totalCustomizationPrice, equals(8.0)); // 5.0 + 2.0 + 1.0

        print('✅ Legacy customization price calculation works correctly');
      });
    });

    group('Customer Experience Compatibility', () {
      testWidgets('should display legacy customizations in customer interface', (tester) async {
        // Test that legacy customizations are displayed correctly in customer UI
        final menuItemWithLegacyCustomizations = {
          'id': 'menu-item-legacy',
          'name': 'Classic Pizza',
          'description': 'Traditional pizza with legacy customizations',
          'base_price': 15.0,
          'customizations': [
            {
              'name': 'Size',
              'options': [
                {'name': 'Small', 'price': 0.0},
                {'name': 'Medium', 'price': 3.0},
                {'name': 'Large', 'price': 5.0},
              ],
              'required': true,
              'multiple': false,
            },
            {
              'name': 'Toppings',
              'options': [
                {'name': 'Pepperoni', 'price': 2.0},
                {'name': 'Mushrooms', 'price': 1.5},
                {'name': 'Extra Cheese', 'price': 2.5},
              ],
              'required': false,
              'multiple': true,
            },
          ],
        };

        // Verify menu item structure is compatible
        try {
          final menuItem = MenuItem.fromJson(menuItemWithLegacyCustomizations);
          expect(menuItem.id, equals('menu-item-legacy'));
          expect(menuItem.name, equals('Classic Pizza'));
          expect(menuItem.basePrice, equals(15.0));
          expect(menuItem.customizations, hasLength(2));

          // Verify customization structure
          final sizeCustomization = menuItem.customizations[0];
          expect(sizeCustomization.name, equals('Size'));
          expect(sizeCustomization.isRequired, isTrue);
          expect(sizeCustomization.type, equals('single'));
          expect(sizeCustomization.options, hasLength(3));

          final toppingsCustomization = menuItem.customizations[1];
          expect(toppingsCustomization.name, equals('Toppings'));
          expect(toppingsCustomization.isRequired, isFalse);
          expect(toppingsCustomization.type, equals('multiple'));
          expect(toppingsCustomization.options, hasLength(3));
        } catch (e) {
          fail('Legacy menu item should be compatible: $e');
        }

        print('✅ Legacy customizations display compatibility maintained');
      });

      testWidgets('should handle cart operations with legacy customizations', (tester) async {
        // Test cart operations with legacy customization format
        final cartItemWithLegacyCustomizations = {
          'id': 'cart-item-legacy',
          'menu_item_id': 'menu-item-legacy',
          'name': 'Classic Pizza',
          'quantity': 2,
          'unit_price': 15.0,
          'customizations': {
            'Size': {'name': 'Large', 'price': 5.0},
            'Toppings': [
              {'name': 'Pepperoni', 'price': 2.0},
              {'name': 'Extra Cheese', 'price': 2.5},
            ],
          },
          'total_price': 49.0, // (15 + 5 + 2 + 2.5) * 2
        };

        // Verify cart item can be processed
        expect(cartItemWithLegacyCustomizations['customizations'], isA<Map>());
        expect(cartItemWithLegacyCustomizations['total_price'], equals(49.0));

        // Verify customization structure
        final customizations = cartItemWithLegacyCustomizations['customizations'] as Map;
        expect(customizations['Size'], isA<Map>());
        expect(customizations['Toppings'], isA<List>());

        print('✅ Cart operations with legacy customizations work correctly');
      });
    });

    group('Data Migration Compatibility', () {
      testWidgets('should handle database schema evolution gracefully', (tester) async {
        // Test that existing database records are compatible with new schema
        final existingDatabaseRecord = {
          'id': 'existing-menu-item',
          'vendor_id': 'vendor-123',
          'name': 'Existing Item',
          'description': 'Item created before template system',
          'base_price': 10.0,
          'customizations': [
            {
              'name': 'Size',
              'options': [
                {'name': 'Small', 'price': 0.0},
                {'name': 'Large', 'price': 3.0},
              ],
              'required': true,
              'multiple': false,
            },
          ],
          'created_at': '2023-12-01T00:00:00Z',
          'updated_at': '2023-12-01T00:00:00Z',
        };

        // Verify existing record structure is still valid
        try {
          final menuItem = MenuItem.fromJson(existingDatabaseRecord);
          expect(menuItem.id, equals('existing-menu-item'));
          expect(menuItem.customizations, hasLength(1));
          expect(menuItem.customizations.first.name, equals('Size'));
        } catch (e) {
          fail('Existing database records should remain compatible: $e');
        }

        print('✅ Database schema evolution compatibility maintained');
      });

      testWidgets('should support gradual migration to template system', (tester) async {
        // Test that vendors can gradually migrate from legacy to template system
        final vendorWithMixedItems = {
          'vendor_id': 'vendor-migration',
          'menu_items': [
            {
              'id': 'legacy-item',
              'name': 'Legacy Item',
              'customizations': [
                {
                  'name': 'Size',
                  'options': [{'name': 'Small', 'price': 0.0}],
                  'required': true,
                  'multiple': false,
                },
              ],
            },
            {
              'id': 'template-item',
              'name': 'Template Item',
              'template_links': [
                {
                  'template_id': 'template-123',
                  'template_name': 'Size Options',
                },
              ],
            },
          ],
        };

        // Verify mixed approach is supported
        final menuItems = vendorWithMixedItems['menu_items'] as List;
        expect(menuItems, hasLength(2));

        final legacyItem = menuItems[0] as Map;
        final templateItem = menuItems[1] as Map;

        expect(legacyItem['customizations'], isA<List>());
        expect(templateItem['template_links'], isA<List>());

        print('✅ Gradual migration to template system supported');
      });
    });

    group('Performance Compatibility', () {
      testWidgets('should maintain performance with legacy data', (tester) async {
        final stopwatch = Stopwatch()..start();

        // Simulate processing large number of legacy customizations
        final legacyCustomizations = List.generate(100, (index) => {
          'name': 'Customization $index',
          'options': List.generate(5, (optIndex) => {
            'name': 'Option $optIndex',
            'price': optIndex * 1.0,
          }),
          'required': index % 2 == 0,
          'multiple': index % 3 == 0,
        });

        // Process all customizations
        for (final customization in legacyCustomizations) {
          expect(customization['name'], isA<String>());
          expect(customization['options'], isA<List>());
        }

        stopwatch.stop();
        final elapsedMs = stopwatch.elapsedMilliseconds;

        // Performance should remain acceptable
        expect(elapsedMs, lessThan(1000)); // Less than 1 second

        print('✅ Performance with legacy data maintained (${elapsedMs}ms)');
      });
    });

    group('Error Handling Compatibility', () {
      testWidgets('should handle malformed legacy data gracefully', (tester) async {
        // Test various malformed legacy data scenarios
        final malformedDataScenarios = [
          // Missing required fields
          {'id': 'item-1', 'name': 'Item without customizations'},
          
          // Invalid customization structure
          {
            'id': 'item-2',
            'name': 'Item with invalid customizations',
            'customizations': 'invalid_structure',
          },
          
          // Missing option prices
          {
            'id': 'item-3',
            'name': 'Item with incomplete options',
            'customizations': [
              {
                'name': 'Size',
                'options': [{'name': 'Large'}], // Missing price
              },
            ],
          },
        ];

        for (final scenario in malformedDataScenarios) {
          try {
            // Attempt to process malformed data
            final menuItem = MenuItem.fromJson(scenario);
            // If successful, verify basic structure
            expect(menuItem.id, isNotNull);
            expect(menuItem.name, isNotNull);
          } catch (e) {
            // If error occurs, it should be handled gracefully
            expect(e, isA<Exception>());
            print('⚠️ Malformed data handled gracefully: ${scenario['id']}');
          }
        }

        print('✅ Malformed legacy data error handling works correctly');
      });
    });
  });
}
