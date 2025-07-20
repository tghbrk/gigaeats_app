# Batch Delivery Management System

## 🎯 Overview

The Batch Delivery Management System orchestrates the complete lifecycle of multi-order deliveries, from intelligent batch creation through execution monitoring to completion analytics. It provides comprehensive tools for managing 2-3 orders simultaneously while maintaining service quality and customer satisfaction.

## 🚀 Key Features

### **Intelligent Batch Creation**
- **Automatic order grouping** based on proximity, preparation times, and delivery windows
- **Driver capacity management** with configurable batch size limits
- **Real-time eligibility checking** for order batching compatibility
- **Constraint-based optimization** considering distance, time, and customer preferences

### **Batch Lifecycle Management**
- **Status tracking** through planned → optimized → active → completed states
- **Real-time progress monitoring** with individual order status updates
- **Dynamic batch modification** including order addition, removal, and resequencing
- **Completion analytics** with performance metrics and insights

### **Customer Communication**
- **Automated batch notifications** informing customers of delivery sequencing
- **Real-time ETA updates** with traffic-adjusted delivery times
- **Proactive delay notifications** with revised delivery estimates
- **Delivery confirmation** with photo proof and customer feedback collection

## 🏗️ Technical Architecture

### **Multi-Order Batch Service**
```dart
class MultiOrderBatchService {
  final SupabaseClient _supabase;
  final RouteOptimizationEngine _routeEngine;
  final PreparationTimeService _preparationService;
  final CustomerNotificationService _notificationService;
  
  /// Create optimized delivery batch
  Future<DeliveryBatch> createOptimizedBatch({
    required String driverId,
    required List<String> orderIds,
    int maxOrders = 3,
    double maxDeviationKm = 5.0,
  }) async {
    // 1. Validate orders are eligible for batching
    final orders = await _validateOrdersForBatching(orderIds, maxDeviationKm);
    
    // 2. Check driver capacity and availability
    await _validateDriverCapacity(driverId, orders.length);
    
    // 3. Get preparation time predictions
    final preparationWindows = await _preparationService
        .predictPreparationTimes(orders);
    
    // 4. Calculate optimal route
    final optimizedRoute = await _routeEngine.calculateOptimalRoute(
      orders: orders,
      driverLocation: await _getDriverLocation(driverId),
      preparationWindows: preparationWindows,
    );
    
    // 5. Create batch in database
    final batch = await _createBatchInDatabase(
      driverId: driverId,
      orders: orders,
      route: optimizedRoute,
    );
    
    // 6. Send initial customer notifications
    await _notificationService.notifyCustomersOfBatch(batch);
    
    return batch;
  }
  
  /// Validate orders can be batched together
  Future<List<BatchedOrder>> _validateOrdersForBatching(
    List<String> orderIds,
    double maxDeviationKm,
  ) async {
    final orders = await _getOrders(orderIds);
    
    // Check order status eligibility
    for (final order in orders) {
      if (!_isOrderEligibleForBatching(order)) {
        throw BatchValidationException(
          'Order ${order.orderNumber} is not eligible for batching. Status: ${order.status}'
        );
      }
    }
    
    // Check geographic proximity
    final centerPoint = _calculateGeographicCenter(orders);
    for (final order in orders) {
      final distance = _calculateDistance(centerPoint, order.deliveryLocation);
      if (distance > maxDeviationKm * 1000) {
        throw BatchValidationException(
          'Order ${order.orderNumber} is too far from batch center (${distance.toStringAsFixed(0)}m)'
        );
      }
    }
    
    // Check delivery time compatibility
    _validateDeliveryTimeCompatibility(orders);
    
    return orders.map((order) => BatchedOrder.fromOrder(order)).toList();
  }
  
  /// Start batch execution
  Future<void> startBatchExecution(String batchId) async {
    final batch = await _getBatch(batchId);
    if (batch == null) throw Exception('Batch not found');
    
    // Update batch status
    await _updateBatchStatus(batchId, BatchStatus.active);
    
    // Start location tracking
    await _startBatchLocationTracking(batchId);
    
    // Initialize progress monitoring
    await _initializeBatchProgressMonitoring(batchId);
    
    // Send batch start notifications
    await _notificationService.sendBatchStartNotifications(batch);
  }
  
  /// Add order to existing batch
  Future<DeliveryBatch?> addOrderToBatch(
    String batchId,
    String orderId,
    {bool reoptimize = true}
  ) async {
    final batch = await _getBatch(batchId);
    if (batch == null) return null;
    
    // Check if batch can accommodate another order
    if (batch.orders.length >= batch.maxOrders) {
      throw BatchCapacityException('Batch is at maximum capacity');
    }
    
    // Validate new order compatibility
    final newOrder = await _getOrder(orderId);
    final updatedOrders = [...batch.orders, BatchedOrder.fromOrder(newOrder)];
    
    await _validateOrdersForBatching(
      updatedOrders.map((o) => o.id).toList(),
      batch.maxDeviationKm,
    );
    
    // Add order to batch
    await _addOrderToBatchInDatabase(batchId, orderId);
    
    // Reoptimize route if requested
    if (reoptimize) {
      final reoptimizedBatch = await optimizeBatch(batch);
      await _notificationService.sendBatchUpdateNotifications(reoptimizedBatch);
      return reoptimizedBatch;
    }
    
    return await _getBatch(batchId);
  }
}
```

### **Batch Progress Monitoring**
```dart
class BatchProgressMonitor {
  final SupabaseClient _supabase;
  final CustomerNotificationService _notificationService;
  
  /// Monitor batch execution progress
  Stream<BatchProgress> monitorBatchProgress(String batchId) async* {
    await for (final update in _supabase
        .from('batch_orders')
        .stream(primaryKey: ['id'])
        .eq('batch_id', batchId)) {
      
      final progress = _calculateBatchProgress(update);
      yield progress;
      
      // Send customer updates if significant progress
      if (_shouldSendProgressUpdate(progress)) {
        await _notificationService.sendProgressUpdate(batchId, progress);
      }
    }
  }
  
  /// Calculate overall batch progress
  BatchProgress _calculateBatchProgress(List<Map<String, dynamic>> batchOrders) {
    int totalSteps = batchOrders.length * 2; // pickup + delivery for each order
    int completedSteps = 0;
    
    final orderProgress = <String, OrderProgress>{};
    
    for (final orderData in batchOrders) {
      final orderId = orderData['order_id'] as String;
      final pickupStatus = OrderPickupStatus.fromString(orderData['pickup_status']);
      final deliveryStatus = OrderDeliveryStatus.fromString(orderData['delivery_status']);
      
      int orderSteps = 0;
      if (pickupStatus == OrderPickupStatus.pickedUp) orderSteps++;
      if (deliveryStatus == OrderDeliveryStatus.delivered) orderSteps++;
      
      completedSteps += orderSteps;
      
      orderProgress[orderId] = OrderProgress(
        orderId: orderId,
        pickupStatus: pickupStatus,
        deliveryStatus: deliveryStatus,
        estimatedPickupTime: DateTime.tryParse(orderData['estimated_pickup_time'] ?? ''),
        estimatedDeliveryTime: DateTime.tryParse(orderData['estimated_delivery_time'] ?? ''),
        actualPickupTime: DateTime.tryParse(orderData['actual_pickup_time'] ?? ''),
        actualDeliveryTime: DateTime.tryParse(orderData['actual_delivery_time'] ?? ''),
      );
    }
    
    return BatchProgress(
      batchId: batchOrders.first['batch_id'],
      totalOrders: batchOrders.length,
      completedSteps: completedSteps,
      totalSteps: totalSteps,
      progressPercentage: (completedSteps / totalSteps * 100).round(),
      orderProgress: orderProgress,
      currentPhase: _determineCurrentPhase(orderProgress),
      estimatedCompletion: _calculateEstimatedCompletion(orderProgress),
    );
  }
  
  /// Determine current batch phase
  BatchPhase _determineCurrentPhase(Map<String, OrderProgress> orderProgress) {
    final allPickedUp = orderProgress.values
        .every((progress) => progress.pickupStatus == OrderPickupStatus.pickedUp);
    
    if (!allPickedUp) {
      return BatchPhase.pickupPhase;
    } else {
      return BatchPhase.deliveryPhase;
    }
  }
}
```

### **Customer Communication Service**
```dart
class BatchDeliveryNotificationService {
  final SupabaseClient _supabase;
  final FCMService _fcmService;
  final SMSService _smsService;
  
  /// Send initial batch creation notifications
  Future<void> notifyCustomersOfBatch(DeliveryBatch batch) async {
    for (int i = 0; i < batch.orders.length; i++) {
      final order = batch.orders[i];
      
      await _sendBatchNotification(
        customerId: order.customerId,
        notification: BatchNotification(
          type: BatchNotificationType.batchCreated,
          orderId: order.id,
          orderNumber: order.orderNumber,
          batchInfo: BatchInfo(
            totalOrders: batch.orders.length,
            deliverySequence: i + 1,
            estimatedDeliveryTime: order.estimatedDeliveryTime,
            driverName: batch.driverName,
            driverPhone: batch.driverPhone,
            trackingUrl: _generateBatchTrackingUrl(batch.id),
          ),
          message: _generateBatchCreationMessage(order, batch),
        ),
      );
    }
  }
  
  /// Send batch start notifications
  Future<void> sendBatchStartNotifications(DeliveryBatch batch) async {
    for (final order in batch.orders) {
      await _sendBatchNotification(
        customerId: order.customerId,
        notification: BatchNotification(
          type: BatchNotificationType.batchStarted,
          orderId: order.id,
          orderNumber: order.orderNumber,
          message: 'Your driver has started the delivery route. '
                  'You are delivery #${order.deliverySequence} of ${batch.orders.length}. '
                  'Estimated arrival: ${_formatTime(order.estimatedDeliveryTime)}',
        ),
      );
    }
  }
  
  /// Send real-time progress updates
  Future<void> sendProgressUpdate({
    required String batchId,
    required BatchProgress progress,
  }) async {
    final batch = await _getBatch(batchId);
    if (batch == null) return;
    
    for (final order in batch.orders) {
      final orderProgress = progress.orderProgress[order.id];
      if (orderProgress == null) continue;
      
      // Send pickup completion notification
      if (orderProgress.pickupStatus == OrderPickupStatus.pickedUp &&
          orderProgress.actualPickupTime != null) {
        await _sendBatchNotification(
          customerId: order.customerId,
          notification: BatchNotification(
            type: BatchNotificationType.orderPickedUp,
            orderId: order.id,
            orderNumber: order.orderNumber,
            message: 'Your order has been picked up! '
                    'Estimated delivery: ${_formatTime(orderProgress.estimatedDeliveryTime)}',
          ),
        );
      }
      
      // Send en route to delivery notification
      if (orderProgress.deliveryStatus == OrderDeliveryStatus.enRoute) {
        await _sendBatchNotification(
          customerId: order.customerId,
          notification: BatchNotification(
            type: BatchNotificationType.enRouteToDelivery,
            orderId: order.id,
            orderNumber: order.orderNumber,
            message: 'Your driver is on the way! '
                    'Estimated arrival: ${_formatTime(orderProgress.estimatedDeliveryTime)}',
          ),
        );
      }
    }
  }
  
  /// Send delay notifications with updated ETAs
  Future<void> sendDelayNotification({
    required String batchId,
    required Duration delay,
    required String reason,
  }) async {
    final batch = await _getBatch(batchId);
    if (batch == null) return;
    
    for (final order in batch.orders) {
      final newETA = order.estimatedDeliveryTime.add(delay);
      
      await _sendBatchNotification(
        customerId: order.customerId,
        notification: BatchNotification(
          type: BatchNotificationType.deliveryDelayed,
          orderId: order.id,
          orderNumber: order.orderNumber,
          message: 'Your delivery has been delayed by ${delay.inMinutes} minutes due to $reason. '
                  'New estimated arrival: ${_formatTime(newETA)}',
        ),
      );
      
      // Update ETA in database
      await _updateOrderETA(order.id, newETA);
    }
  }
  
  String _generateBatchCreationMessage(BatchedOrder order, DeliveryBatch batch) {
    final sequence = batch.orders.indexWhere((o) => o.id == order.id) + 1;
    
    return 'Your order #${order.orderNumber} has been batched with ${batch.orders.length - 1} other orders '
           'for efficient delivery. You are delivery #$sequence. '
           'Estimated delivery time: ${_formatTime(order.estimatedDeliveryTime)}. '
           'Track your delivery: ${_generateBatchTrackingUrl(batch.id)}';
  }
}
```

### **Batch Analytics Service**
```dart
class BatchAnalyticsService {
  final SupabaseClient _supabase;
  
  /// Calculate comprehensive batch metrics
  Future<BatchMetrics> calculateBatchMetrics(String batchId) async {
    final batch = await _getBatch(batchId);
    if (batch == null) throw Exception('Batch not found');
    
    final routeHistory = await _getRouteOptimizationHistory(batchId);
    final actualPerformance = await _getActualBatchPerformance(batchId);
    final customerFeedback = await _getCustomerFeedback(batchId);
    
    return BatchMetrics(
      batchId: batchId,
      totalOrders: batch.orders.length,
      totalDistance: actualPerformance.totalDistance,
      totalTime: actualPerformance.totalTime,
      averageDeliveryTime: _calculateAverageDeliveryTime(actualPerformance),
      onTimeDeliveryRate: _calculateOnTimeRate(actualPerformance),
      customerSatisfactionScore: _calculateSatisfactionScore(customerFeedback),
      fuelEfficiency: _calculateFuelEfficiency(actualPerformance),
      routeOptimizationSaving: _calculateOptimizationSaving(routeHistory),
      driverEfficiencyScore: _calculateDriverEfficiency(actualPerformance),
      preparationAccuracy: _calculatePreparationAccuracy(batch, actualPerformance),
      trafficPredictionAccuracy: _calculateTrafficAccuracy(routeHistory, actualPerformance),
    );
  }
  
  /// Generate batch performance report
  Future<BatchPerformanceReport> generateBatchReport({
    required String driverId,
    required DateRange period,
  }) async {
    final batches = await _getDriverBatches(driverId, period);
    final metrics = await Future.wait(
      batches.map((batch) => calculateBatchMetrics(batch.id))
    );
    
    return BatchPerformanceReport(
      driverId: driverId,
      period: period,
      totalBatches: batches.length,
      totalOrders: metrics.fold(0, (sum, m) => sum + m.totalOrders),
      averageOrdersPerBatch: metrics.isEmpty ? 0 : 
          metrics.fold(0, (sum, m) => sum + m.totalOrders) / metrics.length,
      averageBatchTime: _calculateAverageBatchTime(metrics),
      overallOnTimeRate: _calculateOverallOnTimeRate(metrics),
      overallSatisfactionScore: _calculateOverallSatisfactionScore(metrics),
      totalDistanceSaved: _calculateTotalDistanceSaved(metrics),
      totalTimeSaved: _calculateTotalTimeSaved(metrics),
      efficiencyTrend: _calculateEfficiencyTrend(metrics),
      recommendations: _generatePerformanceRecommendations(metrics),
    );
  }
  
  /// Calculate route optimization savings
  OptimizationSavings _calculateOptimizationSaving(RouteOptimizationHistory history) {
    final naiveDistance = history.naiveRoute.totalDistance;
    final optimizedDistance = history.optimizedRoute.totalDistance;
    final actualDistance = history.actualRoute?.totalDistance ?? optimizedDistance;
    
    final naiveTime = history.naiveRoute.estimatedDuration;
    final optimizedTime = history.optimizedRoute.estimatedDuration;
    final actualTime = history.actualRoute?.actualDuration ?? optimizedTime;
    
    return OptimizationSavings(
      distanceSaved: naiveDistance - optimizedDistance,
      timeSaved: naiveTime - optimizedTime,
      fuelSaved: _calculateFuelSavings(naiveDistance, optimizedDistance),
      actualVsPredicted: ActualVsPredicted(
        distanceAccuracy: _calculateAccuracy(optimizedDistance, actualDistance),
        timeAccuracy: _calculateAccuracy(optimizedTime.inMinutes, actualTime.inMinutes),
      ),
      optimizationEffectiveness: _calculateOptimizationEffectiveness(
        naiveDistance, optimizedDistance, actualDistance
      ),
    );
  }
}
```

## 📱 UI Integration

### **Batch Management Dashboard**
```dart
class BatchManagementDashboard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeBatch = ref.watch(activeBatchProvider);
    final batchProgress = ref.watch(batchProgressProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Batch Delivery'),
        actions: [
          IconButton(
            onPressed: () => _showBatchMenu(context),
            icon: Icon(Icons.more_vert),
          ),
        ],
      ),
      body: activeBatch.when(
        data: (batch) => batch != null
            ? BatchActiveView(batch: batch, progress: batchProgress.value)
            : BatchCreationView(),
        loading: () => Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorView(error: error),
      ),
    );
  }
}

class BatchActiveView extends StatelessWidget {
  final DeliveryBatch batch;
  final BatchProgress? progress;
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Batch overview card
        BatchOverviewCard(batch: batch, progress: progress),
        
        // Progress indicator
        if (progress != null)
          BatchProgressIndicator(progress: progress!),
        
        // Order list
        Expanded(
          child: ListView.builder(
            itemCount: batch.orders.length,
            itemBuilder: (context, index) {
              final order = batch.orders[index];
              final orderProgress = progress?.orderProgress[order.id];
              
              return BatchOrderCard(
                order: order,
                progress: orderProgress,
                sequenceNumber: index + 1,
                onStatusUpdate: (status) => _updateOrderStatus(order.id, status),
                onCustomerContact: () => _contactCustomer(order),
              );
            },
          ),
        ),
      ],
    );
  }
}
```

## 🧪 Testing Strategy

### **Batch Management Testing**
```dart
// Test batch creation validation
testWidgets('Batch creation validates order compatibility', (tester) async {
  final batchService = MultiOrderBatchService();
  
  // Test with compatible orders
  final compatibleOrders = [
    'order_1', // Location: KL Center
    'order_2', // Location: KLCC (2km away)
    'order_3', // Location: Bukit Bintang (1.5km away)
  ];
  
  final batch = await batchService.createOptimizedBatch(
    driverId: 'driver_123',
    orderIds: compatibleOrders,
  );
  
  expect(batch.orders.length, equals(3));
  expect(batch.status, equals(BatchStatus.planned));
  
  // Test with incompatible orders (too far apart)
  final incompatibleOrders = [
    'order_1', // Location: KL Center
    'order_4', // Location: Petaling Jaya (15km away)
  ];
  
  expect(
    () => batchService.createOptimizedBatch(
      driverId: 'driver_123',
      orderIds: incompatibleOrders,
    ),
    throwsA(isA<BatchValidationException>()),
  );
});

// Test batch progress monitoring
testWidgets('Batch progress is calculated correctly', (tester) async {
  final progressMonitor = BatchProgressMonitor();
  
  final mockBatchOrders = [
    {
      'batch_id': 'batch_123',
      'order_id': 'order_1',
      'pickup_status': 'picked_up',
      'delivery_status': 'pending',
    },
    {
      'batch_id': 'batch_123',
      'order_id': 'order_2',
      'pickup_status': 'pending',
      'delivery_status': 'pending',
    },
  ];
  
  final progress = progressMonitor._calculateBatchProgress(mockBatchOrders);
  
  expect(progress.totalOrders, equals(2));
  expect(progress.completedSteps, equals(1)); // One pickup completed
  expect(progress.totalSteps, equals(4)); // 2 pickups + 2 deliveries
  expect(progress.progressPercentage, equals(25));
  expect(progress.currentPhase, equals(BatchPhase.pickupPhase));
});

// Test customer notification delivery
testWidgets('Customer notifications are sent correctly', (tester) async {
  final notificationService = BatchDeliveryNotificationService();
  final mockBatch = createMockBatch(orderCount: 2);
  
  await notificationService.notifyCustomersOfBatch(mockBatch);
  
  // Verify notifications were sent to all customers
  verify(mockFCMService.sendNotification(any)).called(2);
  
  // Verify notification content includes batch information
  final capturedNotifications = verify(mockFCMService.sendNotification(captureAny)).captured;
  
  for (final notification in capturedNotifications) {
    expect(notification.data['batch_id'], equals(mockBatch.id));
    expect(notification.data['total_orders'], equals('2'));
    expect(notification.data['tracking_url'], isNotEmpty);
  }
});
```

This batch delivery management system provides comprehensive orchestration of multi-order deliveries with intelligent automation, real-time monitoring, and proactive customer communication to ensure high service quality and customer satisfaction.
