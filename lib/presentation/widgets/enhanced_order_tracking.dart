import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/order.dart';
import '../../data/models/order_status_history.dart';
import '../providers/order_provider.dart';

class EnhancedOrderTracking extends ConsumerWidget {
  final String orderId;

  const EnhancedOrderTracking({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderTrackingProvider(orderId));
    final statusHistoryAsync = ref.watch(orderStatusHistoryProvider(orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Tracking'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(orderTrackingProvider(orderId).notifier).refresh();
              ref.invalidate(orderStatusHistoryProvider(orderId));
            },
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return const Center(child: Text('Order not found'));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildOrderHeader(order),
                const SizedBox(height: 24),
                _buildTrackingTimeline(order),
                const SizedBox(height: 24),
                _buildOrderDetails(order),
                const SizedBox(height: 24),
                statusHistoryAsync.when(
                  data: (history) => _buildStatusHistory(history),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Text('Error loading history: $error'),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading order: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.read(orderTrackingProvider(orderId).notifier).refresh(),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderHeader(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                _buildStatusChip(order.status),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Vendor: ${order.vendorName}',
              style: const TextStyle(fontSize: 16),
            ),
            if (order.estimatedDeliveryTime != null) ...[
              const SizedBox(height: 4),
              Text(
                'Estimated Delivery: ${DateFormat('MMM dd, yyyy HH:mm').format(order.estimatedDeliveryTime!)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
            if (order.deliveryZone != null) ...[
              const SizedBox(height: 4),
              Text(
                'Delivery Zone: ${order.deliveryZone}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    Color color;
    switch (status) {
      case OrderStatus.pending:
        color = Colors.orange;
        break;
      case OrderStatus.confirmed:
        color = Colors.blue;
        break;
      case OrderStatus.preparing:
        color = Colors.purple;
        break;
      case OrderStatus.ready:
        color = Colors.green;
        break;
      case OrderStatus.outForDelivery:
        color = Colors.indigo;
        break;
      case OrderStatus.delivered:
        color = Colors.green[700]!;
        break;
      case OrderStatus.cancelled:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        status.displayName,
        style: const TextStyle(color: Colors.white),
      ),
      backgroundColor: color,
    );
  }

  Widget _buildTrackingTimeline(Order order) {
    final steps = [
      _TimelineStep(
        title: 'Order Placed',
        time: order.createdAt,
        isCompleted: true,
        icon: Icons.shopping_cart,
      ),
      _TimelineStep(
        title: 'Order Confirmed',
        time: order.status.index >= OrderStatus.confirmed.index ? order.updatedAt : null,
        isCompleted: order.status.index >= OrderStatus.confirmed.index,
        icon: Icons.check_circle,
      ),
      _TimelineStep(
        title: 'Preparation Started',
        time: order.preparationStartedAt,
        isCompleted: order.status.index >= OrderStatus.preparing.index,
        icon: Icons.restaurant,
      ),
      _TimelineStep(
        title: 'Order Ready',
        time: order.readyAt,
        isCompleted: order.status.index >= OrderStatus.ready.index,
        icon: Icons.done_all,
      ),
      _TimelineStep(
        title: 'Out for Delivery',
        time: order.outForDeliveryAt,
        isCompleted: order.status.index >= OrderStatus.outForDelivery.index,
        icon: Icons.local_shipping,
      ),
      _TimelineStep(
        title: 'Delivered',
        time: order.actualDeliveryTime,
        isCompleted: order.status == OrderStatus.delivered,
        icon: Icons.home,
      ),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Progress',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...steps.map((step) => _buildTimelineItem(step)),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineItem(_TimelineStep step) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: step.isCompleted ? Colors.green : Colors.grey[300],
              shape: BoxShape.circle,
            ),
            child: Icon(
              step.icon,
              color: step.isCompleted ? Colors.white : Colors.grey[600],
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontWeight: step.isCompleted ? FontWeight.bold : FontWeight.normal,
                    color: step.isCompleted ? Colors.black : Colors.grey[600],
                  ),
                ),
                if (step.time != null)
                  Text(
                    DateFormat('MMM dd, yyyy HH:mm').format(step.time!),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderDetails(Order order) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Order Details',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow('Total Amount', 'RM ${order.totalAmount.toStringAsFixed(2)}'),
            _buildDetailRow('Delivery Fee', 'RM ${order.deliveryFee.toStringAsFixed(2)}'),
            _buildDetailRow('SST', 'RM ${order.sstAmount.toStringAsFixed(2)}'),
            if (order.contactPhone != null)
              _buildDetailRow('Contact Phone', order.contactPhone!),
            if (order.specialInstructions != null) ...[
              const SizedBox(height: 8),
              const Text(
                'Special Instructions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(order.specialInstructions!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusHistory(List<OrderStatusHistory> history) {
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...history.map((entry) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${entry.oldStatus?.displayName ?? 'New'} → ${entry.newStatus.displayName}',
                    ),
                  ),
                  Text(
                    DateFormat('MMM dd, HH:mm').format(entry.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }
}

class _TimelineStep {
  final String title;
  final DateTime? time;
  final bool isCompleted;
  final IconData icon;

  _TimelineStep({
    required this.title,
    this.time,
    required this.isCompleted,
    required this.icon,
  });
}
