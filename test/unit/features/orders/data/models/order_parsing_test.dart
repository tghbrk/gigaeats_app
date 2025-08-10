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
  });
}
