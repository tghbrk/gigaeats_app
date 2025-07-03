import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/enhanced_order_tracking_service.dart';
import '../../data/models/order_tracking_models.dart';
import '../../data/models/order.dart';
import '../../../core/utils/logger.dart';

/// Enhanced order tracking state
class EnhancedOrderTrackingState {
  final Map<String, OrderTrackingStatus> trackingStatuses;
  final Map<String, List<OrderTrackingUpdate>> recentUpdates;
  final Map<String, bool> isTracking;
  final String? error;
  final DateTime lastUpdated;

  const EnhancedOrderTrackingState({
    this.trackingStatuses = const {},
    this.recentUpdates = const {},
    this.isTracking = const {},
    this.error,
    required this.lastUpdated,
  });

  EnhancedOrderTrackingState copyWith({
    Map<String, OrderTrackingStatus>? trackingStatuses,
    Map<String, List<OrderTrackingUpdate>>? recentUpdates,
    Map<String, bool>? isTracking,
    String? error,
    DateTime? lastUpdated,
  }) {
    return EnhancedOrderTrackingState(
      trackingStatuses: trackingStatuses ?? this.trackingStatuses,
      recentUpdates: recentUpdates ?? this.recentUpdates,
      isTracking: isTracking ?? this.isTracking,
      error: error,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  OrderTrackingStatus? getTrackingStatus(String orderId) {
    return trackingStatuses[orderId];
  }

  List<OrderTrackingUpdate> getRecentUpdates(String orderId) {
    return recentUpdates[orderId] ?? [];
  }

  bool isOrderTracking(String orderId) {
    return isTracking[orderId] ?? false;
  }
}

/// Enhanced order tracking notifier
class EnhancedOrderTrackingNotifier extends StateNotifier<EnhancedOrderTrackingState> {
  final EnhancedOrderTrackingService _trackingService;
  final AppLogger _logger = AppLogger();

  final Map<String, StreamSubscription<OrderTrackingUpdate>> _trackingSubscriptions = {};

  EnhancedOrderTrackingNotifier(this._trackingService)
      : super(EnhancedOrderTrackingState(lastUpdated: DateTime.now()));

  /// Start tracking an order
  Future<void> startTracking(String orderId) async {
    try {
      _logger.info('📍 [ORDER-TRACKING-PROVIDER] Starting tracking for: $orderId');

      // Update tracking state
      final updatedIsTracking = Map<String, bool>.from(state.isTracking);
      updatedIsTracking[orderId] = true;

      state = state.copyWith(
        isTracking: updatedIsTracking,
        error: null,
      );

      // Get initial tracking status
      final trackingStatus = await _trackingService.getOrderTrackingStatus(orderId);
      
      final updatedStatuses = Map<String, OrderTrackingStatus>.from(state.trackingStatuses);
      updatedStatuses[orderId] = trackingStatus;

      state = state.copyWith(trackingStatuses: updatedStatuses);

      // Subscribe to tracking updates
      final trackingStream = _trackingService.trackOrder(orderId);
      _trackingSubscriptions[orderId] = trackingStream.listen(
        (update) => _handleTrackingUpdate(orderId, update),
        onError: (error) => _handleTrackingError(orderId, error),
      );

      _logger.info('✅ [ORDER-TRACKING-PROVIDER] Tracking started for: $orderId');

    } catch (e) {
      _logger.error('❌ [ORDER-TRACKING-PROVIDER] Failed to start tracking', e);
      
      state = state.copyWith(error: 'Failed to start tracking: ${e.toString()}');
    }
  }

  /// Stop tracking an order
  void stopTracking(String orderId) {
    _logger.info('🛑 [ORDER-TRACKING-PROVIDER] Stopping tracking for: $orderId');

    // Cancel subscription
    _trackingSubscriptions[orderId]?.cancel();
    _trackingSubscriptions.remove(orderId);

    // Stop service tracking
    _trackingService.stopTracking(orderId);

    // Update state
    final updatedIsTracking = Map<String, bool>.from(state.isTracking);
    updatedIsTracking[orderId] = false;

    state = state.copyWith(isTracking: updatedIsTracking);
  }

  /// Handle tracking update
  void _handleTrackingUpdate(String orderId, OrderTrackingUpdate update) {
    _logger.info('📱 [ORDER-TRACKING-PROVIDER] Update received for: $orderId, type: ${update.type}');

    // Update recent updates
    final updatedRecentUpdates = Map<String, List<OrderTrackingUpdate>>.from(state.recentUpdates);
    final currentUpdates = updatedRecentUpdates[orderId] ?? [];
    
    // Add new update and keep only last 10
    final newUpdates = [update, ...currentUpdates].take(10).toList();
    updatedRecentUpdates[orderId] = newUpdates;

    // Update tracking status if provided
    Map<String, OrderTrackingStatus>? updatedStatuses;
    if (update.trackingStatus != null) {
      updatedStatuses = Map<String, OrderTrackingStatus>.from(state.trackingStatuses);
      updatedStatuses[orderId] = update.trackingStatus!;
    } else if (update.newStatus != null) {
      // Update status in existing tracking status
      final currentStatus = state.trackingStatuses[orderId];
      if (currentStatus != null) {
        updatedStatuses = Map<String, OrderTrackingStatus>.from(state.trackingStatuses);
        updatedStatuses[orderId] = currentStatus.copyWith(
          currentStatus: update.newStatus!,
          lastUpdated: update.timestamp,
        );
      }
    }

    state = state.copyWith(
      recentUpdates: updatedRecentUpdates,
      trackingStatuses: updatedStatuses,
    );
  }

  /// Handle tracking error
  void _handleTrackingError(String orderId, dynamic error) {
    _logger.error('❌ [ORDER-TRACKING-PROVIDER] Tracking error for: $orderId', error);

    state = state.copyWith(error: 'Tracking error: ${error.toString()}');
  }

  /// Get order tracking timeline
  List<OrderTrackingTimelineEntry> getOrderTimeline(String orderId) {
    final trackingStatus = state.trackingStatuses[orderId];
    if (trackingStatus == null) return [];

    final timeline = <OrderTrackingTimelineEntry>[];
    final currentStatus = trackingStatus.currentStatus;
    final statusHistory = trackingStatus.statusHistory;
    final estimatedTimes = trackingStatus.estimatedTimes;

    // Define all possible statuses in order
    final allStatuses = [
      OrderStatus.pending,
      OrderStatus.confirmed,
      OrderStatus.preparing,
      OrderStatus.ready,
      OrderStatus.outForDelivery,
      OrderStatus.delivered,
    ];

    for (final status in allStatuses) {
      // Find actual timestamp from history
      final historyEntry = statusHistory
          .where((entry) => entry.status == status)
          .firstOrNull;

      // Determine if this status is completed, current, or future
      final statusIndex = allStatuses.indexOf(status);
      final currentIndex = allStatuses.indexOf(currentStatus);
      
      final isCompleted = statusIndex < currentIndex;
      final isCurrent = statusIndex == currentIndex;
      final isEstimated = statusIndex > currentIndex;

      // Get estimated time if not completed
      DateTime? timestamp = historyEntry?.createdAt;
      if (timestamp == null && isEstimated) {
        switch (status) {
          case OrderStatus.preparing:
            timestamp = estimatedTimes.preparation;
            break;
          case OrderStatus.ready:
            timestamp = estimatedTimes.ready;
            break;
          case OrderStatus.delivered:
            timestamp = estimatedTimes.delivery;
            break;
          default:
            break;
        }
      }

      timeline.add(OrderTrackingTimelineEntry(
        status: status,
        title: _getStatusTitle(status),
        description: _getStatusDescription(status),
        timestamp: timestamp,
        isCompleted: isCompleted,
        isCurrent: isCurrent,
        isEstimated: isEstimated,
      ));
    }

    return timeline;
  }

  /// Get status title
  String _getStatusTitle(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Order Placed';
      case OrderStatus.confirmed:
        return 'Order Confirmed';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.outForDelivery:
        return 'Out for Delivery';
      case OrderStatus.delivered:
        return 'Delivered';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }

  /// Get status description
  String _getStatusDescription(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return 'Your order has been received';
      case OrderStatus.confirmed:
        return 'Restaurant confirmed your order';
      case OrderStatus.preparing:
        return 'Your food is being prepared';
      case OrderStatus.ready:
        return 'Order is ready for pickup/delivery';
      case OrderStatus.outForDelivery:
        return 'Driver is on the way';
      case OrderStatus.delivered:
        return 'Order has been delivered';
      case OrderStatus.cancelled:
        return 'Order was cancelled';
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Refresh tracking status
  Future<void> refreshTrackingStatus(String orderId) async {
    try {
      final trackingStatus = await _trackingService.getOrderTrackingStatus(orderId);
      
      final updatedStatuses = Map<String, OrderTrackingStatus>.from(state.trackingStatuses);
      updatedStatuses[orderId] = trackingStatus;

      state = state.copyWith(trackingStatuses: updatedStatuses);

    } catch (e) {
      _logger.error('❌ [ORDER-TRACKING-PROVIDER] Failed to refresh tracking status', e);
      state = state.copyWith(error: 'Failed to refresh: ${e.toString()}');
    }
  }

  @override
  void dispose() {
    // Cancel all subscriptions
    for (final subscription in _trackingSubscriptions.values) {
      subscription.cancel();
    }
    _trackingSubscriptions.clear();

    // Dispose tracking service
    _trackingService.dispose();

    super.dispose();
  }
}

/// Enhanced order tracking provider
final enhancedOrderTrackingProvider = StateNotifierProvider<EnhancedOrderTrackingNotifier, EnhancedOrderTrackingState>((ref) {
  final trackingService = ref.watch(enhancedOrderTrackingServiceProvider);
  return EnhancedOrderTrackingNotifier(trackingService);
});

/// Enhanced order tracking service provider
final enhancedOrderTrackingServiceProvider = Provider<EnhancedOrderTrackingService>((ref) {
  return EnhancedOrderTrackingService();
});

/// Order tracking status provider
final orderTrackingStatusProvider = Provider.family<OrderTrackingStatus?, String>((ref, orderId) {
  return ref.watch(enhancedOrderTrackingProvider).getTrackingStatus(orderId);
});

/// Order tracking updates provider
final orderTrackingUpdatesProvider = Provider.family<List<OrderTrackingUpdate>, String>((ref, orderId) {
  return ref.watch(enhancedOrderTrackingProvider).getRecentUpdates(orderId);
});

/// Order tracking timeline provider
final orderTrackingTimelineProvider = Provider.family<List<OrderTrackingTimelineEntry>, String>((ref, orderId) {
  return ref.watch(enhancedOrderTrackingProvider.notifier).getOrderTimeline(orderId);
});

/// Is order tracking provider
final isOrderTrackingProvider = Provider.family<bool, String>((ref, orderId) {
  return ref.watch(enhancedOrderTrackingProvider).isOrderTracking(orderId);
});

/// Order tracking error provider
final orderTrackingErrorProvider = Provider<String?>((ref) {
  return ref.watch(enhancedOrderTrackingProvider).error;
});

/// Extension for nullable first
extension IterableExtension<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (iterator.moveNext()) {
      return iterator.current;
    }
    return null;
  }
}
