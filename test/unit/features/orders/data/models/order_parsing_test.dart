import 'package:flutter_test/flutter_test.dart';
import 'package:gigaeats_app/src/features/orders/data/models/order.dart';

void main() {
  group('Order Model Parsing Tests', () {
    group('Order.fromJson', () {
      test('should parse order with nested menu_items correctly', () {
        // Arrange
        final json = {
          'id': 'order-123',
          'order_number': 'GE1234567890',
          'status': 'confirmed',
          'vendor_id': 'vendor-123',
          'customer_id': 'customer-123',
          'delivery_date': '2025-08-10T10:00:00Z',
          'delivery_address': {
            'street': '123 Main St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 25.50,
          'delivery_fee': 5.00,
          'sst_amount': 1.83,
          'total_amount': 32.33,
          'created_at': '2025-08-10T09:00:00Z',
          'updated_at': '2025-08-10T09:30:00Z',
          'payment_method': 'wallet',
          'payment_status': 'paid',
          'vendor': {
            'business_name': 'Test Restaurant',
          },
          'order_items': [
            {
              'id': 'item-1',
              'menu_item_id': 'menu-1',
              'quantity': 2,
              'unit_price': 10.50,
              'total_price': 21.00,
              'menu_items': {
                'id': 'menu-1',
                'name': 'Nasi Lemak',
                'description': 'Traditional Malaysian rice dish',
                'image_url': 'https://example.com/nasi-lemak.jpg',
              },
            },
            {
              'id': 'item-2',
              'menu_item_id': 'menu-2',
              'quantity': 1,
              'unit_price': 4.50,
              'total_price': 4.50,
              'menu_items': {
                'id': 'menu-2',
                'name': 'Teh Tarik',
                'description': 'Malaysian pulled tea',
                'image_url': 'https://example.com/teh-tarik.jpg',
              },
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.id, equals('order-123'));
        expect(order.orderNumber, equals('GE1234567890'));
        expect(order.status, equals(OrderStatus.confirmed));
        expect(order.vendorName, equals('Test Restaurant'));
        expect(order.items.length, equals(2));

        // Check first item
        final firstItem = order.items[0];
        expect(firstItem.id, equals('item-1'));
        expect(firstItem.name, equals('Nasi Lemak'));
        expect(firstItem.description, equals('Traditional Malaysian rice dish'));
        expect(firstItem.imageUrl, equals('https://example.com/nasi-lemak.jpg'));
        expect(firstItem.quantity, equals(2));
        expect(firstItem.unitPrice, equals(10.50));
        expect(firstItem.totalPrice, equals(21.00));

        // Check second item
        final secondItem = order.items[1];
        expect(secondItem.id, equals('item-2'));
        expect(secondItem.name, equals('Teh Tarik'));
        expect(secondItem.description, equals('Malaysian pulled tea'));
        expect(secondItem.imageUrl, equals('https://example.com/teh-tarik.jpg'));
        expect(secondItem.quantity, equals(1));
        expect(secondItem.unitPrice, equals(4.50));
        expect(secondItem.totalPrice, equals(4.50));
      });

      test('should parse order with legacy menu_item structure', () {
        // Arrange
        final json = {
          'id': 'order-456',
          'order_number': 'GE9876543210',
          'status': 'delivered',
          'vendor_id': 'vendor-456',
          'customer_id': 'customer-456',
          'delivery_date': '2025-08-10T12:00:00Z',
          'delivery_address': {
            'street': '456 Side St',
            'city': 'Petaling Jaya',
            'state': 'Selangor',
            'postal_code': '47000',
            'country': 'Malaysia',
          },
          'subtotal': 15.00,
          'delivery_fee': 3.00,
          'sst_amount': 1.08,
          'total_amount': 19.08,
          'created_at': '2025-08-10T11:00:00Z',
          'updated_at': '2025-08-10T11:45:00Z',
          'payment_method': 'credit_card',
          'payment_status': 'paid',
          'vendor': {
            'business_name': 'Legacy Restaurant',
          },
          'order_items': [
            {
              'id': 'item-3',
              'menu_item_id': 'menu-3',
              'quantity': 1,
              'unit_price': 15.00,
              'total_price': 15.00,
              'menu_item': {
                'id': 'menu-3',
                'name': 'Char Kway Teow',
                'description': 'Stir-fried rice noodles',
                'image_url': 'https://example.com/char-kway-teow.jpg',
              },
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.id, equals('order-456'));
        expect(order.orderNumber, equals('GE9876543210'));
        expect(order.status, equals(OrderStatus.delivered));
        expect(order.vendorName, equals('Legacy Restaurant'));
        expect(order.items.length, equals(1));

        // Check item with legacy menu_item structure
        final item = order.items[0];
        expect(item.id, equals('item-3'));
        expect(item.name, equals('Char Kway Teow'));
        expect(item.description, equals('Stir-fried rice noodles'));
        expect(item.imageUrl, equals('https://example.com/char-kway-teow.jpg'));
        expect(item.quantity, equals(1));
        expect(item.unitPrice, equals(15.00));
        expect(item.totalPrice, equals(15.00));
      });

      test('should handle order with no menu item data gracefully', () {
        // Arrange
        final json = {
          'id': 'order-789',
          'order_number': 'GE5555555555',
          'status': 'pending',
          'vendor_id': 'vendor-789',
          'customer_id': 'customer-789',
          'delivery_date': '2025-08-10T14:00:00Z',
          'delivery_address': {
            'street': '789 Third St',
            'city': 'Shah Alam',
            'state': 'Selangor',
            'postal_code': '40000',
            'country': 'Malaysia',
          },
          'subtotal': 12.00,
          'delivery_fee': 4.00,
          'sst_amount': 0.96,
          'total_amount': 16.96,
          'created_at': '2025-08-10T13:00:00Z',
          'updated_at': '2025-08-10T13:15:00Z',
          'vendor': {
            'business_name': 'Minimal Restaurant',
          },
          'order_items': [
            {
              'id': 'item-4',
              'menu_item_id': 'menu-4',
              'name': 'Basic Item',
              'description': 'Basic description',
              'quantity': 1,
              'unit_price': 12.00,
              'total_price': 12.00,
              // No nested menu_item or menu_items
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.id, equals('order-789'));
        expect(order.items.length, equals(1));

        final item = order.items[0];
        expect(item.name, equals('Basic Item'));
        expect(item.description, equals('Basic description'));
        expect(item.imageUrl, isNull);
      });

      test('should handle empty order_items list', () {
        // Arrange
        final json = {
          'id': 'order-empty',
          'order_number': 'GE0000000000',
          'status': 'cancelled',
          'vendor_id': 'vendor-empty',
          'customer_id': 'customer-empty',
          'delivery_date': '2025-08-10T16:00:00Z',
          'delivery_address': {
            'street': '000 Empty St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 0.00,
          'delivery_fee': 0.00,
          'sst_amount': 0.00,
          'total_amount': 0.00,
          'created_at': '2025-08-10T15:00:00Z',
          'updated_at': '2025-08-10T15:30:00Z',
          'vendor': {
            'business_name': 'Empty Restaurant',
          },
          'order_items': [],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.id, equals('order-empty'));
        expect(order.items, isEmpty);
        expect(order.status, equals(OrderStatus.cancelled));
      });
    });

    group('Edge Cases and Error Handling', () {
      test('should handle missing required fields with defaults', () {
        // Arrange
        final json = {
          'id': 'order-minimal',
          'order_number': 'GE1111111111',
          // Missing status - should default to pending
          'vendor_id': 'vendor-minimal',
          'customer_id': 'customer-minimal',
          'delivery_date': '2025-08-10T18:00:00Z',
          'delivery_address': {
            'street': '111 Minimal St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 10.00,
          'delivery_fee': 2.00,
          'sst_amount': 0.72,
          'total_amount': 12.72,
          'created_at': '2025-08-10T17:00:00Z',
          'updated_at': '2025-08-10T17:30:00Z',
          // Missing vendor data - should use default
          'order_items': [
            {
              'id': 'item-minimal',
              'menu_item_id': 'menu-minimal',
              'quantity': 1,
              // Missing prices - should handle gracefully
              'menu_items': {
                'id': 'menu-minimal',
                'name': 'Minimal Item',
                // Missing description - should default to empty
              },
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.status, equals(OrderStatus.pending));
        expect(order.vendorName, equals('Unknown Vendor'));
        expect(order.items.length, equals(1));

        final item = order.items[0];
        expect(item.name, equals('Minimal Item'));
        expect(item.description, equals(''));
        expect(item.unitPrice, equals(0.0));
        expect(item.totalPrice, equals(0.0));
      });

      test('should handle both menu_items and menu_item in same order', () {
        // Arrange
        final json = {
          'id': 'order-mixed',
          'order_number': 'GE2222222222',
          'status': 'preparing',
          'vendor_id': 'vendor-mixed',
          'customer_id': 'customer-mixed',
          'delivery_date': '2025-08-10T20:00:00Z',
          'delivery_address': {
            'street': '222 Mixed St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 30.00,
          'delivery_fee': 6.00,
          'sst_amount': 2.16,
          'total_amount': 38.16,
          'created_at': '2025-08-10T19:00:00Z',
          'updated_at': '2025-08-10T19:30:00Z',
          'vendor': {
            'business_name': 'Mixed Restaurant',
          },
          'order_items': [
            {
              'id': 'item-new',
              'menu_item_id': 'menu-new',
              'quantity': 2,
              'unit_price': 12.00,
              'total_price': 24.00,
              'menu_items': {
                'id': 'menu-new',
                'name': 'New Style Item',
                'description': 'New format',
                'image_url': 'https://example.com/new.jpg',
              },
            },
            {
              'id': 'item-legacy',
              'menu_item_id': 'menu-legacy',
              'quantity': 1,
              'unit_price': 6.00,
              'total_price': 6.00,
              'menu_item': {
                'id': 'menu-legacy',
                'name': 'Legacy Style Item',
                'description': 'Legacy format',
                'image_url': 'https://example.com/legacy.jpg',
              },
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.items.length, equals(2));

        // Check new format item
        final newItem = order.items[0];
        expect(newItem.name, equals('New Style Item'));
        expect(newItem.description, equals('New format'));
        expect(newItem.imageUrl, equals('https://example.com/new.jpg'));

        // Check legacy format item
        final legacyItem = order.items[1];
        expect(legacyItem.name, equals('Legacy Style Item'));
        expect(legacyItem.description, equals('Legacy format'));
        expect(legacyItem.imageUrl, equals('https://example.com/legacy.jpg'));
      });

      test('should handle null payment method gracefully', () {
        // Arrange
        final json = {
          'id': 'order-null-payment',
          'order_number': 'GE3333333333',
          'status': 'pending',
          'vendor_id': 'vendor-null',
          'customer_id': 'customer-null',
          'delivery_date': '2025-08-10T22:00:00Z',
          'delivery_address': {
            'street': '333 Null St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 8.00,
          'delivery_fee': 2.00,
          'sst_amount': 0.60,
          'total_amount': 10.60,
          'created_at': '2025-08-10T21:00:00Z',
          'updated_at': '2025-08-10T21:30:00Z',
          'payment_method': null,
          'payment_status': null,
          'vendor': {
            'business_name': 'Null Payment Restaurant',
          },
          'order_items': [],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.paymentMethod, isNull);
        expect(order.paymentStatus, isNull);
        expect(order.paymentReference, isNull);
      });
    });

    group('OrderItem.fromJson', () {
      test('should parse OrderItem correctly', () {
        // Arrange
        final json = {
          'id': 'item-standalone',
          'menu_item_id': 'menu-standalone',
          'name': 'Standalone Item',
          'description': 'Standalone description',
          'unit_price': 15.50,
          'quantity': 3,
          'total_price': 46.50,
          'image_url': 'https://example.com/standalone.jpg',
          'customizations': {
            'spice_level': 'medium',
            'extra_sauce': true,
          },
          'notes': 'Extra spicy please',
        };

        // Act
        final orderItem = OrderItem.fromJson(json);

        // Assert
        expect(orderItem.id, equals('item-standalone'));
        expect(orderItem.menuItemId, equals('menu-standalone'));
        expect(orderItem.name, equals('Standalone Item'));
        expect(orderItem.description, equals('Standalone description'));
        expect(orderItem.unitPrice, equals(15.50));
        expect(orderItem.quantity, equals(3));
        expect(orderItem.totalPrice, equals(46.50));
        expect(orderItem.imageUrl, equals('https://example.com/standalone.jpg'));
        expect(orderItem.customizations, isNotNull);
        expect(orderItem.customizations!['spice_level'], equals('medium'));
        expect(orderItem.customizations!['extra_sauce'], equals(true));
        expect(orderItem.notes, equals('Extra spicy please'));
      });

      test('should handle backward compatibility properties', () {
        // Arrange
        final json = {
          'id': 'item-compat',
          'menu_item_id': 'menu-compat',
          'name': 'Compat Item',
          'description': 'Compat description',
          'unit_price': 12.00, // Required field
          'quantity': 2,
          'total_price': 24.00, // Required field
          'price': 12.00, // Legacy field (should be ignored in favor of unit_price)
          'subtotal': 24.00, // Legacy field (should be ignored in favor of total_price)
        };

        // Act
        final orderItem = OrderItem.fromJson(json);

        // Assert
        expect(orderItem.price, equals(12.00)); // Should map to unitPrice
        expect(orderItem.subtotal, equals(24.00)); // Should map to totalPrice
        expect(orderItem.unitPrice, equals(12.00));
        expect(orderItem.totalPrice, equals(24.00));
      });

      test('should handle minimal OrderItem data', () {
        // Arrange
        final json = {
          'id': 'item-minimal',
          'menu_item_id': 'menu-minimal',
          'name': 'Minimal Item',
          'description': 'Minimal description',
          'unit_price': 8.50,
          'quantity': 1,
          'total_price': 8.50,
        };

        // Act
        final orderItem = OrderItem.fromJson(json);

        // Assert
        expect(orderItem.id, equals('item-minimal'));
        expect(orderItem.menuItemId, equals('menu-minimal'));
        expect(orderItem.name, equals('Minimal Item'));
        expect(orderItem.description, equals('Minimal description'));
        expect(orderItem.unitPrice, equals(8.50));
        expect(orderItem.quantity, equals(1));
        expect(orderItem.totalPrice, equals(8.50));
        expect(orderItem.imageUrl, isNull);
        expect(orderItem.customizations, isNull);
        expect(orderItem.notes, isNull);
      });
    });

    group('Menu Item Flattening Logic', () {
      test('should prioritize existing item fields over nested menu item data', () {
        // Arrange - This tests the scenario where order_item has its own name/description
        // but also has nested menu_item data (the nested data should NOT override existing)
        final json = {
          'id': 'order-priority',
          'order_number': 'GE4444444444',
          'status': 'ready',
          'vendor_id': 'vendor-priority',
          'customer_id': 'customer-priority',
          'delivery_date': '2025-08-11T10:00:00Z',
          'delivery_address': {
            'street': '444 Priority St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 20.00,
          'delivery_fee': 4.00,
          'sst_amount': 1.44,
          'total_amount': 25.44,
          'created_at': '2025-08-11T09:00:00Z',
          'updated_at': '2025-08-11T09:30:00Z',
          'vendor': {
            'business_name': 'Priority Restaurant',
          },
          'order_items': [
            {
              'id': 'item-priority',
              'menu_item_id': 'menu-priority',
              'name': 'Custom Order Item Name', // This should take priority
              'description': 'Custom order description', // This should take priority
              'image_url': 'https://example.com/custom.jpg', // This should take priority
              'quantity': 1,
              'unit_price': 20.00,
              'total_price': 20.00,
              'menu_items': {
                'id': 'menu-priority',
                'name': 'Original Menu Item Name', // Should be ignored
                'description': 'Original menu description', // Should be ignored
                'image_url': 'https://example.com/original.jpg', // Should be ignored
              },
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.items.length, equals(1));
        final item = order.items[0];

        // Should use the existing order item fields, not the nested menu item data
        expect(item.name, equals('Custom Order Item Name'));
        expect(item.description, equals('Custom order description'));
        expect(item.imageUrl, equals('https://example.com/custom.jpg'));
      });

      test('should use nested menu item data when order item fields are missing', () {
        // Arrange - This tests the scenario where order_item is missing name/description
        // and should fall back to nested menu_item data
        final json = {
          'id': 'order-fallback',
          'order_number': 'GE5555555555',
          'status': 'preparing',
          'vendor_id': 'vendor-fallback',
          'customer_id': 'customer-fallback',
          'delivery_date': '2025-08-11T12:00:00Z',
          'delivery_address': {
            'street': '555 Fallback St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 18.00,
          'delivery_fee': 3.50,
          'sst_amount': 1.29,
          'total_amount': 22.79,
          'created_at': '2025-08-11T11:00:00Z',
          'updated_at': '2025-08-11T11:30:00Z',
          'vendor': {
            'business_name': 'Fallback Restaurant',
          },
          'order_items': [
            {
              'id': 'item-fallback',
              'menu_item_id': 'menu-fallback',
              // Missing name, description, image_url - should use nested data
              'quantity': 2,
              'unit_price': 9.00,
              'total_price': 18.00,
              'menu_items': {
                'id': 'menu-fallback',
                'name': 'Fallback Menu Item', // Should be used
                'description': 'Fallback menu description', // Should be used
                'image_url': 'https://example.com/fallback.jpg', // Should be used
              },
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.items.length, equals(1));
        final item = order.items[0];

        // Should use the nested menu item data since order item fields are missing
        expect(item.name, equals('Fallback Menu Item'));
        expect(item.description, equals('Fallback menu description'));
        expect(item.imageUrl, equals('https://example.com/fallback.jpg'));
      });

      test('should handle completely missing menu item data with defaults', () {
        // Arrange - This tests the scenario where there's no nested menu item data at all
        final json = {
          'id': 'order-defaults',
          'order_number': 'GE6666666666',
          'status': 'confirmed',
          'vendor_id': 'vendor-defaults',
          'customer_id': 'customer-defaults',
          'delivery_date': '2025-08-11T14:00:00Z',
          'delivery_address': {
            'street': '666 Default St',
            'city': 'Kuala Lumpur',
            'state': 'Selangor',
            'postal_code': '50000',
            'country': 'Malaysia',
          },
          'subtotal': 12.00,
          'delivery_fee': 2.50,
          'sst_amount': 0.87,
          'total_amount': 15.37,
          'created_at': '2025-08-11T13:00:00Z',
          'updated_at': '2025-08-11T13:30:00Z',
          'vendor': {
            'business_name': 'Default Restaurant',
          },
          'order_items': [
            {
              'id': 'item-defaults',
              'menu_item_id': 'menu-defaults',
              // Missing name, description, image_url and no nested menu item data
              'quantity': 1,
              'unit_price': 12.00,
              'total_price': 12.00,
              // No menu_items or menu_item nested data
            },
          ],
        };

        // Act
        final order = Order.fromJson(json);

        // Assert
        expect(order.items.length, equals(1));
        final item = order.items[0];

        // Should use default values when no data is available
        expect(item.name, equals('Unknown Item'));
        expect(item.description, equals(''));
        expect(item.imageUrl, isNull);
      });
    });
  });
}
