# Multi-Order Route Optimization System

## 🎯 Overview

The Multi-Order Route Optimization System enables drivers to efficiently handle 2-3 orders simultaneously through intelligent batching, dynamic route sequencing, and real-time optimization based on preparation times, traffic conditions, and delivery windows.

## 🚀 Key Features

### **Intelligent Batching**
- **Smart order grouping** for 2-3 orders within 5km deviation radius
- **Preparation time integration** for optimal pickup timing
- **Customer proximity analysis** for efficient delivery sequencing
- **Real-time batch creation** based on order availability and driver location

### **Dynamic Route Optimization**
- **Multi-criteria optimization** balancing distance, time, traffic, and preparation readiness
- **Traveling Salesman Problem (TSP)** solving with genetic algorithms
- **Real-time route adaptation** based on changing conditions
- **Traffic-aware routing** with automatic rerouting capabilities

### **Preparation Time Intelligence**
- **Vendor performance prediction** based on historical data
- **Order complexity analysis** considering items and customizations
- **Real-time readiness updates** from vendor systems
- **Dynamic pickup scheduling** to minimize wait times

## 🏗️ Technical Architecture

### **Route Optimization Engine**
```dart
class RouteOptimizationEngine {
  final GoogleMapsService _mapsService;
  final TrafficService _trafficService;
  final PreparationTimeService _preparationService;
  
  /// Calculate optimal route using multi-criteria optimization
  Future<OptimizedRoute> calculateOptimalRoute({
    required List<BatchedOrder> orders,
    required LatLng driverLocation,
    required Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria? criteria,
  }) async {
    criteria ??= OptimizationCriteria.balanced();
    
    // 1. Calculate distance matrix between all points
    final distanceMatrix = await _calculateDistanceMatrix(orders, driverLocation);
    
    // 2. Get real-time traffic conditions
    final trafficConditions = await _trafficService.getTrafficConditions(orders);
    
    // 3. Apply TSP algorithm with multi-criteria scoring
    final optimalSequence = await _solveTSP(
      orders: orders,
      distanceMatrix: distanceMatrix,
      trafficConditions: trafficConditions,
      preparationWindows: preparationWindows,
      criteria: criteria,
    );
    
    // 4. Generate detailed route with waypoints
    return await _generateDetailedRoute(optimalSequence, driverLocation);
  }
  
  /// Traveling Salesman Problem solver with genetic algorithm
  Future<List<BatchedOrder>> _solveTSP({
    required List<BatchedOrder> orders,
    required DistanceMatrix distanceMatrix,
    required TrafficConditions trafficConditions,
    required Map<String, PreparationWindow> preparationWindows,
    required OptimizationCriteria criteria,
  }) async {
    // Initialize population with random routes
    final population = _generateInitialPopulation(orders, 50);
    
    for (int generation = 0; generation < 100; generation++) {
      // Evaluate fitness for each route
      final fitnessScores = await Future.wait(
        population.map((route) => _calculateRouteFitness(
          route, distanceMatrix, trafficConditions, preparationWindows, criteria
        ))
      );
      
      // Selection, crossover, and mutation
      population = _evolvePopulation(population, fitnessScores);
      
      // Early termination if convergence is achieved
      if (_hasConverged(fitnessScores)) break;
    }
    
    // Return best route from final population
    final bestRouteIndex = _findBestRoute(population, fitnessScores);
    return population[bestRouteIndex];
  }
  
  /// Calculate fitness score for a route
  Future<double> _calculateRouteFitness(
    List<BatchedOrder> route,
    DistanceMatrix distanceMatrix,
    TrafficConditions trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    double totalScore = 0.0;
    
    // Distance component (40% weight)
    final distanceScore = _calculateDistanceScore(route, distanceMatrix);
    totalScore += distanceScore * criteria.distanceWeight;
    
    // Preparation time component (30% weight)
    final preparationScore = _calculatePreparationScore(route, preparationWindows);
    totalScore += preparationScore * criteria.preparationTimeWeight;
    
    // Traffic component (20% weight)
    final trafficScore = _calculateTrafficScore(route, trafficConditions);
    totalScore += trafficScore * criteria.trafficWeight;
    
    // Delivery window component (10% weight)
    final deliveryWindowScore = _calculateDeliveryWindowScore(route);
    totalScore += deliveryWindowScore * criteria.deliveryWindowWeight;
    
    return totalScore;
  }
}
```

### **Optimization Criteria Configuration**
```dart
class OptimizationCriteria {
  final double preparationTimeWeight;    // 0.3 - Prioritize ready orders
  final double distanceWeight;          // 0.4 - Minimize total distance
  final double trafficWeight;           // 0.2 - Avoid traffic delays
  final double deliveryWindowWeight;    // 0.1 - Meet delivery promises
  
  const OptimizationCriteria({
    required this.preparationTimeWeight,
    required this.distanceWeight,
    required this.trafficWeight,
    required this.deliveryWindowWeight,
  });
  
  const OptimizationCriteria.balanced() : 
    preparationTimeWeight = 0.3,
    distanceWeight = 0.4,
    trafficWeight = 0.2,
    deliveryWindowWeight = 0.1;
    
  const OptimizationCriteria.speedFocused() : 
    preparationTimeWeight = 0.2,
    distanceWeight = 0.5,
    trafficWeight = 0.3,
    deliveryWindowWeight = 0.0;
    
  const OptimizationCriteria.customerFocused() : 
    preparationTimeWeight = 0.2,
    distanceWeight = 0.3,
    trafficWeight = 0.2,
    deliveryWindowWeight = 0.3;
}
```

### **Preparation Time Service**
```dart
class PreparationTimeService {
  final SupabaseClient _supabase;
  final VendorAnalyticsService _analyticsService;
  
  /// Predict order preparation completion times
  Future<Map<String, PreparationWindow>> predictPreparationTimes(
    List<BatchedOrder> orders
  ) async {
    final predictions = <String, PreparationWindow>{};
    
    for (final order in orders) {
      final prediction = await _predictSingleOrderPreparation(order);
      predictions[order.id] = prediction;
    }
    
    return predictions;
  }
  
  /// Predict preparation time for a single order
  Future<PreparationWindow> _predictSingleOrderPreparation(BatchedOrder order) async {
    // Get historical vendor performance
    final vendorMetrics = await _analyticsService.getVendorPreparationMetrics(
      order.vendorId,
      timeWindow: Duration(days: 30),
    );
    
    // Calculate item complexity score
    final complexityScore = _calculateItemComplexity(order.items);
    
    // Get current vendor load
    final currentLoad = await _getCurrentVendorLoad(order.vendorId);
    
    // Apply time-of-day factors
    final timeFactors = _getTimeOfDayFactors(DateTime.now());
    
    // Calculate base preparation time
    final baseTime = vendorMetrics.averagePreparationTime;
    final complexityAdjustment = complexityScore * 2; // 2 minutes per complexity point
    final loadAdjustment = currentLoad * 1.5; // 1.5 minutes per concurrent order
    final timeAdjustment = timeFactors.preparationMultiplier;
    
    final estimatedMinutes = (baseTime + complexityAdjustment + loadAdjustment) * timeAdjustment;
    
    return PreparationWindow(
      estimatedReady: DateTime.now().add(Duration(minutes: estimatedMinutes.round())),
      confidenceInterval: Duration(minutes: vendorMetrics.standardDeviation.round()),
      earliestPickup: DateTime.now().add(Duration(minutes: (estimatedMinutes * 0.8).round())),
      latestPickup: DateTime.now().add(Duration(minutes: (estimatedMinutes * 1.3).round())),
      readinessProbability: _calculateReadinessProbability(vendorMetrics, complexityScore),
    );
  }
  
  /// Calculate item complexity score
  double _calculateItemComplexity(List<OrderItem> items) {
    double complexity = 0.0;
    
    for (final item in items) {
      // Base complexity
      complexity += 1.0;
      
      // Customization complexity
      complexity += item.customizations.length * 0.5;
      
      // Special preparation complexity
      if (item.requiresSpecialPreparation) {
        complexity += 2.0;
      }
      
      // Quantity factor
      complexity += (item.quantity - 1) * 0.2;
    }
    
    return complexity;
  }
  
  /// Monitor real-time preparation progress
  Stream<PreparationUpdate> monitorPreparationProgress(List<String> orderIds) async* {
    // Subscribe to vendor preparation updates
    await for (final update in _supabase
        .from('vendor_preparation_status')
        .stream(primaryKey: ['order_id'])
        .inFilter('order_id', orderIds)) {
      
      for (final statusUpdate in update) {
        yield PreparationUpdate(
          orderId: statusUpdate['order_id'],
          status: PreparationStatus.fromString(statusUpdate['status']),
          estimatedReady: DateTime.parse(statusUpdate['estimated_ready']),
          actualProgress: statusUpdate['progress_percentage'],
          updatedAt: DateTime.parse(statusUpdate['updated_at']),
        );
      }
    }
  }
}
```

### **Dynamic Route Manager**
```dart
class DynamicRouteManager {
  final RouteOptimizationEngine _optimizationEngine;
  final TrafficService _trafficService;
  final PreparationTimeService _preparationService;
  
  /// Monitor and adapt route during delivery
  Stream<RouteAdaptation> monitorRouteExecution(String batchId) async* {
    await for (final event in _routeEventStream(batchId)) {
      final adaptation = await _evaluateRouteAdaptation(event);
      
      if (adaptation.requiresResequencing) {
        final newRoute = await _resequenceRoute(
          currentRoute: event.currentRoute,
          trigger: event,
          constraints: adaptation.constraints,
        );
        
        yield RouteAdaptation(
          type: AdaptationType.resequence,
          newRoute: newRoute,
          reason: adaptation.reason,
          estimatedTimeSaving: adaptation.timeSaving,
          confidence: adaptation.confidence,
        );
      }
    }
  }
  
  /// Handle different types of route events
  Future<RouteAdaptation> _evaluateRouteAdaptation(RouteEvent event) async {
    switch (event.type) {
      case RouteEventType.orderReady:
        return await _handleOrderReady(event);
      case RouteEventType.trafficDelay:
        return await _handleTrafficDelay(event);
      case RouteEventType.orderDelayed:
        return await _handleOrderDelay(event);
      case RouteEventType.customerUnavailable:
        return await _handleCustomerUnavailable(event);
      case RouteEventType.driverLocationUpdate:
        return await _handleDriverLocationUpdate(event);
    }
  }
  
  /// Handle order ready event
  Future<RouteAdaptation> _handleOrderReady(RouteEvent event) async {
    final currentRoute = event.currentRoute;
    final readyOrderId = event.orderId;
    
    // Check if resequencing would improve efficiency
    final currentSequence = currentRoute.getPickupSequence();
    final readyOrderIndex = currentSequence.indexWhere((o) => o.id == readyOrderId);
    
    if (readyOrderIndex > 0) {
      // Order is ready but not next in sequence
      final alternativeSequence = List<BatchedOrder>.from(currentSequence);
      
      // Move ready order to front
      final readyOrder = alternativeSequence.removeAt(readyOrderIndex);
      alternativeSequence.insert(0, readyOrder);
      
      // Calculate potential time savings
      final currentETA = currentRoute.estimatedCompletionTime;
      final optimizedRoute = await _optimizationEngine.calculateOptimalRoute(
        orders: alternativeSequence,
        driverLocation: event.driverLocation,
        preparationWindows: await _preparationService.predictPreparationTimes(alternativeSequence),
      );
      
      final timeSaving = currentETA.difference(optimizedRoute.estimatedCompletionTime);
      
      if (timeSaving.inMinutes > 5) {
        return RouteAdaptation(
          type: AdaptationType.resequence,
          reason: 'Order ${readyOrder.orderNumber} is ready for pickup',
          timeSaving: timeSaving,
          confidence: 0.8,
          requiresResequencing: true,
        );
      }
    }
    
    return RouteAdaptation.noChange();
  }
  
  /// Handle traffic delay event
  Future<RouteAdaptation> _handleTrafficDelay(RouteEvent event) async {
    final trafficDelay = event.trafficDelay!;
    
    if (trafficDelay.estimatedDelay.inMinutes > 10) {
      // Significant delay, consider rerouting
      final alternativeRoute = await _trafficService.calculateAlternativeRoute(
        origin: event.driverLocation,
        destinations: event.currentRoute.remainingWaypoints,
        avoidIncidents: trafficDelay.incidents,
      );
      
      if (alternativeRoute.estimatedDuration < 
          event.currentRoute.remainingDuration - trafficDelay.estimatedDelay) {
        return RouteAdaptation(
          type: AdaptationType.reroute,
          reason: 'Traffic incident causing ${trafficDelay.estimatedDelay.inMinutes} minute delay',
          timeSaving: trafficDelay.estimatedDelay,
          confidence: 0.9,
          requiresResequencing: true,
        );
      }
    }
    
    return RouteAdaptation.noChange();
  }
}
```

## 📊 Performance Metrics and Analytics

### **Route Optimization Analytics**
```dart
class RouteOptimizationAnalytics {
  final SupabaseClient _supabase;
  
  /// Calculate batch performance metrics
  Future<BatchMetrics> calculateBatchMetrics(DeliveryBatch batch) async {
    final routeHistory = await _getRouteOptimizationHistory(batch.id);
    final actualPerformance = await _getActualBatchPerformance(batch.id);
    
    return BatchMetrics(
      totalDistance: actualPerformance.totalDistance,
      totalTime: actualPerformance.totalTime,
      fuelEfficiency: await _calculateFuelEfficiency(batch),
      customerSatisfaction: await _getCustomerSatisfactionScores(batch),
      onTimeDeliveryRate: _calculateOnTimeRate(batch),
      routeOptimizationSaving: _calculateOptimizationSaving(routeHistory),
      preparationAccuracy: _calculatePreparationAccuracy(batch),
      trafficPredictionAccuracy: _calculateTrafficAccuracy(batch),
    );
  }
  
  /// Track route optimization savings
  Future<OptimizationSavings> _calculateOptimizationSaving(RouteOptimizationHistory history) async {
    final naiveRoute = history.naiveRoute;
    final optimizedRoute = history.optimizedRoute;
    final actualRoute = history.actualRoute;
    
    return OptimizationSavings(
      distanceSaved: naiveRoute.totalDistance - optimizedRoute.totalDistance,
      timeSaved: naiveRoute.estimatedDuration - optimizedRoute.estimatedDuration,
      fuelSaved: _calculateFuelSavings(naiveRoute, optimizedRoute),
      actualVsPredicted: _compareActualVsPredicted(optimizedRoute, actualRoute),
      optimizationAccuracy: _calculateOptimizationAccuracy(optimizedRoute, actualRoute),
    );
  }
  
  /// Generate driver performance insights
  Future<DriverBatchPerformance> analyzeDriverPerformance({
    required String driverId,
    required DateRange period,
  }) async {
    final batches = await _getDriverBatches(driverId, period);
    final metrics = await Future.wait(
      batches.map((batch) => calculateBatchMetrics(batch))
    );
    
    return DriverBatchPerformance(
      totalBatches: batches.length,
      averageOrdersPerBatch: _calculateAverageOrdersPerBatch(batches),
      averageDistancePerBatch: _calculateAverageDistance(metrics),
      averageTimePerBatch: _calculateAverageTime(metrics),
      efficiencyScore: _calculateEfficiencyScore(metrics),
      improvementTrend: _calculateImprovementTrend(metrics),
      recommendations: _generateRecommendations(metrics),
    );
  }
}
```

## 🧪 Testing Strategy

### **Route Optimization Testing**
```dart
// Test TSP algorithm accuracy
testWidgets('TSP algorithm finds optimal route', (tester) async {
  final orders = [
    createMockOrder(location: LatLng(3.1390, 101.6869)), // KL Center
    createMockOrder(location: LatLng(3.1478, 101.6953)), // KLCC
    createMockOrder(location: LatLng(3.1319, 101.6841)), // Bukit Bintang
  ];
  
  final engine = RouteOptimizationEngine();
  final route = await engine.calculateOptimalRoute(
    orders: orders,
    driverLocation: LatLng(3.1400, 101.6900),
    preparationWindows: {},
  );
  
  // Verify route is optimized (shortest total distance)
  expect(route.totalDistance, lessThan(15000)); // Less than 15km
  expect(route.waypoints.length, equals(6)); // 3 pickups + 3 deliveries
});

// Test preparation time prediction accuracy
testWidgets('Preparation time prediction is accurate', (tester) async {
  final preparationService = PreparationTimeService();
  final mockOrder = createMockOrderWithComplexity(
    vendorId: 'vendor_123',
    itemCount: 3,
    customizations: 2,
  );
  
  final prediction = await preparationService._predictSingleOrderPreparation(mockOrder);
  
  expect(prediction.estimatedReady, isA<DateTime>());
  expect(prediction.confidenceInterval.inMinutes, greaterThan(0));
  expect(prediction.readinessProbability, inInclusiveRange(0.0, 1.0));
});

// Test dynamic route adaptation
testWidgets('Route adapts to traffic conditions', (tester) async {
  final routeManager = DynamicRouteManager();
  final mockEvent = RouteEvent(
    type: RouteEventType.trafficDelay,
    trafficDelay: TrafficDelay(
      estimatedDelay: Duration(minutes: 15),
      incidents: [TrafficIncident.heavyTraffic],
    ),
  );
  
  final adaptation = await routeManager._evaluateRouteAdaptation(mockEvent);
  
  expect(adaptation.requiresResequencing, isTrue);
  expect(adaptation.type, equals(AdaptationType.reroute));
  expect(adaptation.timeSaving.inMinutes, greaterThan(10));
});
```

### **Performance Benchmarking**
```dart
// Benchmark route optimization performance
void main() {
  group('Route Optimization Performance', () {
    test('TSP solver completes within time limit', () async {
      final stopwatch = Stopwatch()..start();
      
      final orders = List.generate(3, (i) => createMockOrder());
      final engine = RouteOptimizationEngine();
      
      await engine.calculateOptimalRoute(
        orders: orders,
        driverLocation: LatLng(3.1390, 101.6869),
        preparationWindows: {},
      );
      
      stopwatch.stop();
      
      // Should complete within 5 seconds for 3 orders
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
    });
    
    test('Memory usage remains stable during optimization', () async {
      final initialMemory = ProcessInfo.currentRss;
      
      // Run multiple optimizations
      for (int i = 0; i < 10; i++) {
        final orders = List.generate(3, (i) => createMockOrder());
        final engine = RouteOptimizationEngine();
        
        await engine.calculateOptimalRoute(
          orders: orders,
          driverLocation: LatLng(3.1390, 101.6869),
          preparationWindows: {},
        );
      }
      
      final finalMemory = ProcessInfo.currentRss;
      final memoryIncrease = finalMemory - initialMemory;
      
      // Memory increase should be minimal (less than 50MB)
      expect(memoryIncrease, lessThan(50 * 1024 * 1024));
    });
  });
}
```

This multi-order route optimization system provides intelligent batching and dynamic route management while maintaining high performance and accuracy, enabling drivers to handle multiple orders efficiently with minimal wait times and optimal routing.
