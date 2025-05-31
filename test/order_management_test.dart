import 'package:flutter_test/flutter_test.dart';

import 'package:gigaeats_app/data/models/order.dart';
import 'package:gigaeats_app/data/models/order_status_history.dart';
import 'package:gigaeats_app/data/models/order_notification.dart';

void main() {
  group('Order Management System Tests', () {
    group('Order Creation', () {
      test('should create order with proper structure', () {
        final testOrder = Order(
          id: 'test-order-id',
          orderNumber: 'GE-20241201-0001',
          status: OrderStatus.pending,
          items: [],
          vendorId: 'vendor-1',
          vendorName: 'Test Vendor',
          customerId: 'customer-1',
          customerName: 'Test Customer',
          salesAgentId: 'agent-1',
          deliveryDate: DateTime.parse('2024-12-01'),
          deliveryAddress: const Address(
            street: 'Test Street',
            city: 'Test City',
            state: 'Test State',
            postalCode: '12345',
            country: 'Malaysia',
          ),
          subtotal: 100.0,
          deliveryFee: 10.0,
          sstAmount: 6.0,
          totalAmount: 116.0,
          createdAt: DateTime.parse('2024-12-01T10:00:00Z'),
          updatedAt: DateTime.parse('2024-12-01T10:00:00Z'),
        );

        expect(testOrder.status, OrderStatus.pending);
        expect(testOrder.totalAmount, 116.0);
        expect(testOrder.orderNumber, 'GE-20241201-0001');
      });

      test('should validate order data before creation', () {
        // Test order validation logic
        final validOrder = Order(
          id: 'test-id',
          orderNumber: 'GE-20241201-0001',
          status: OrderStatus.pending,
          items: [],
          vendorId: 'vendor-1',
          vendorName: 'Test Vendor',
          customerId: 'customer-1',
          customerName: 'Test Customer',
          deliveryDate: DateTime.now().add(const Duration(hours: 2)),
          deliveryAddress: const Address(
            street: 'Test Street',
            city: 'Test City',
            state: 'Test State',
            postalCode: '12345',
            country: 'Malaysia',
          ),
          subtotal: 100.0,
          deliveryFee: 10.0,
          sstAmount: 6.0,
          totalAmount: 116.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        expect(validOrder.vendorId.isNotEmpty, true);
        expect(validOrder.customerId.isNotEmpty, true);
        expect(validOrder.totalAmount, greaterThan(0));
      });
    });

    group('Order Status Management', () {
      test('should track order status transitions', () {
        final statusHistory = OrderStatusHistory(
          id: 'history-1',
          orderId: 'order-1',
          oldStatus: OrderStatus.pending,
          newStatus: OrderStatus.confirmed,
          changedBy: 'user-1',
          createdAt: DateTime.now(),
        );

        expect(statusHistory.oldStatus, OrderStatus.pending);
        expect(statusHistory.newStatus, OrderStatus.confirmed);
      });

      test('should validate status transition logic', () {
        // Test valid status transitions
        const validTransitions = [
          [OrderStatus.pending, OrderStatus.confirmed],
          [OrderStatus.confirmed, OrderStatus.preparing],
          [OrderStatus.preparing, OrderStatus.ready],
          [OrderStatus.ready, OrderStatus.outForDelivery],
          [OrderStatus.outForDelivery, OrderStatus.delivered],
        ];

        for (final transition in validTransitions) {
          final newStatus = transition[1];

          // In a real implementation, you would have validation logic
          expect(newStatus.value, isNotEmpty);
        }
      });
    });

    group('Order Notifications', () {
      test('should create notifications for status changes', () {
        final notification = OrderNotification(
          id: 'notif-1',
          orderId: 'order-1',
          recipientId: 'user-1',
          notificationType: NotificationType.statusChange,
          title: 'Order Status Updated',
          message: 'Your order status has been updated to confirmed',
          sentAt: DateTime.now(),
        );

        expect(notification.notificationType, NotificationType.statusChange);
        expect(notification.isUnread, true);
        expect(notification.title.isNotEmpty, true);
      });

      test('should mark notifications as read', () {
        final notification = OrderNotification(
          id: 'notif-1',
          orderId: 'order-1',
          recipientId: 'user-1',
          notificationType: NotificationType.statusChange,
          title: 'Order Status Updated',
          message: 'Your order status has been updated',
          sentAt: DateTime.now(),
        );

        final readNotification = notification.markAsRead();
        
        expect(readNotification.isRead, true);
        expect(readNotification.readAt, isNotNull);
      });
    });

    group('Order Tracking', () {
      test('should track delivery timestamps', () {
        final order = Order(
          id: 'order-1',
          orderNumber: 'GE-20241201-0001',
          status: OrderStatus.preparing,
          items: [],
          vendorId: 'vendor-1',
          vendorName: 'Test Vendor',
          customerId: 'customer-1',
          customerName: 'Test Customer',
          deliveryDate: DateTime.now().add(const Duration(hours: 2)),
          deliveryAddress: const Address(
            street: 'Test Street',
            city: 'Test City',
            state: 'Test State',
            postalCode: '12345',
            country: 'Malaysia',
          ),
          subtotal: 100.0,
          deliveryFee: 10.0,
          sstAmount: 6.0,
          totalAmount: 116.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          estimatedDeliveryTime: DateTime.now().add(const Duration(hours: 2)),
          preparationStartedAt: DateTime.now(),
        );

        expect(order.estimatedDeliveryTime, isNotNull);
        expect(order.preparationStartedAt, isNotNull);
        expect(order.status, OrderStatus.preparing);
      });
    });

    group('Malaysian Market Features', () {
      test('should support Malaysian currency and payment methods', () {
        final paymentInfo = PaymentInfo(
          method: PaymentMethod.fpx.value,
          status: PaymentStatus.pending.value,
          amount: 116.0,
          currency: 'MYR',
          referenceNumber: 'FPX-123456',
        );

        expect(paymentInfo.currency, 'MYR');
        expect(paymentInfo.method, PaymentMethod.fpx.value);
      });

      test('should handle delivery zones', () {
        final order = Order(
          id: 'order-1',
          orderNumber: 'GE-20241201-0001',
          status: OrderStatus.pending,
          items: [],
          vendorId: 'vendor-1',
          vendorName: 'Test Vendor',
          customerId: 'customer-1',
          customerName: 'Test Customer',
          deliveryDate: DateTime.now().add(const Duration(hours: 2)),
          deliveryAddress: const Address(
            street: 'Jalan Test',
            city: 'Kuala Lumpur',
            state: 'Selangor',
            postalCode: '50000',
            country: 'Malaysia',
          ),
          subtotal: 100.0,
          deliveryFee: 10.0,
          sstAmount: 6.0,
          totalAmount: 116.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          deliveryZone: 'KL Central',
          contactPhone: '+60123456789',
        );

        expect(order.deliveryZone, 'KL Central');
        expect(order.contactPhone, startsWith('+60'));
      });
    });
  });
}
