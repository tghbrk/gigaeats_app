import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/customer_order_history_service.dart';

import '../../../../presentation/providers/repository_providers.dart';

/// Provider for customer order history service
final customerOrderHistoryServiceProvider = Provider<CustomerOrderHistoryService>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  return CustomerOrderHistoryService(orderRepository: orderRepository);
});

/// Provider for customer order history service with auto-dispose
final customerOrderHistoryServiceAutoDisposeProvider = Provider.autoDispose<CustomerOrderHistoryService>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final service = CustomerOrderHistoryService(orderRepository: orderRepository);
  
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});
