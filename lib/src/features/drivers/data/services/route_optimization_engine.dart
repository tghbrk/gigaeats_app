import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../models/route_optimization_models.dart';
import '../models/navigation_models.dart';
import '../../../orders/data/models/order.dart';
import 'preparation_time_service.dart';

/// Advanced route optimization engine with TSP algorithms and multi-criteria optimization
/// Implements Traveling Salesman Problem solutions for optimal multi-order routing
class RouteOptimizationEngine {
  final PreparationTimeService _preparationTimeService = PreparationTimeService();

  /// Calculate optimal route using multi-criteria TSP optimization
  Future<OptimizedRoute> calculateOptimalRoute({
    required List<Order> orders,
    required LatLng driverLocation,
    OptimizationCriteria? criteria,
    Map<String, PreparationWindow>? preparationWindows,
  }) async {
    try {
      debugPrint('🔄 [OPTIMIZATION] Starting route optimization for ${orders.length} orders');
      
      criteria ??= OptimizationCriteria.balanced();
      
      if (!criteria.isValid) {
        throw ArgumentError('Invalid optimization criteria: weights must sum to 1.0');
      }
      
      // 1. Get preparation time predictions if not provided
      preparationWindows ??= await _preparationTimeService.predictPreparationTimes(orders);
      
      // 2. Calculate distance matrix between all points
      final distanceMatrix = await _calculateDistanceMatrix(orders, driverLocation);
      
      // 3. Get real-time traffic conditions
      final trafficConditions = await _getTrafficConditions(orders, driverLocation);
      
      // 4. Solve TSP with multi-criteria optimization
      final solution = await _solveTSP(
        orders: orders,
        driverLocation: driverLocation,
        distanceMatrix: distanceMatrix,
        trafficConditions: trafficConditions,
        preparationWindows: preparationWindows,
        criteria: criteria,
      );
      
      debugPrint('✅ [OPTIMIZATION] Route optimization completed with score: ${solution.optimizationScore.toStringAsFixed(1)}%');
      return solution;
    } catch (e) {
      debugPrint('❌ [OPTIMIZATION] Error calculating optimal route: $e');
      throw Exception('Route optimization failed: $e');
    }
  }

  /// Reoptimize route based on current progress and events
  Future<RouteUpdate?> reoptimizeRoute(
    OptimizedRoute currentRoute,
    RouteProgress progress,
    List<RouteEvent> events,
  ) async {
    try {
      debugPrint('🔄 [OPTIMIZATION] Checking if reoptimization is needed');
      
      // Analyze events to determine if reoptimization is beneficial
      final reoptimizationReason = _analyzeReoptimizationNeed(events);
      
      if (reoptimizationReason == null) {
        debugPrint('📊 [OPTIMIZATION] No reoptimization needed');
        return null;
      }
      
      debugPrint('🔄 [OPTIMIZATION] Reoptimizing route due to: ${reoptimizationReason.displayName}');
      
      // Get remaining orders (not yet completed)
      final remainingOrders = await _getRemainingOrders(currentRoute, progress);
      
      if (remainingOrders.length <= 1) {
        debugPrint('📊 [OPTIMIZATION] Only one order remaining, no reoptimization needed');
        return null;
      }
      
      // Get current driver location from progress
      final driverLocation = await _getCurrentDriverLocation();
      
      // Recalculate optimal route for remaining orders
      final newRoute = await calculateOptimalRoute(
        orders: remainingOrders,
        driverLocation: driverLocation,
        criteria: currentRoute.criteria,
      );
      
      // Check if new route is significantly better
      final improvementThreshold = 0.05; // 5% improvement threshold
      final currentScore = currentRoute.optimizationScore;
      final newScore = newRoute.optimizationScore;
      
      if (newScore - currentScore < improvementThreshold) {
        debugPrint('📊 [OPTIMIZATION] New route not significantly better, keeping current route');
        return null;
      }
      
      // Create route update
      final routeUpdate = RouteUpdate(
        routeId: currentRoute.id,
        updatedWaypoints: newRoute.waypoints,
        newOptimizationScore: newScore,
        reason: reoptimizationReason,
        updatedAt: DateTime.now(),
        changes: {
          'score_improvement': newScore - currentScore,
          'remaining_orders': remainingOrders.length,
          'trigger_events': events.map((e) => e.type.name).toList(),
        },
      );
      
      debugPrint('✅ [OPTIMIZATION] Route reoptimized with ${((newScore - currentScore) * 100).toStringAsFixed(1)}% improvement');
      return routeUpdate;
    } catch (e) {
      debugPrint('❌ [OPTIMIZATION] Error reoptimizing route: $e');
      return null;
    }
  }

  /// Calculate distance matrix between all pickup/delivery points
  Future<List<List<double>>> _calculateDistanceMatrix(
    List<Order> orders,
    LatLng driverLocation,
  ) async {
    try {
      debugPrint('🗺️ [OPTIMIZATION] Calculating distance matrix');
      
      // Create list of all points (driver location + pickup + delivery locations)
      final points = <LatLng>[driverLocation];
      
      // Add pickup locations (vendor addresses)
      for (final order in orders) {
        // TODO: Get actual vendor coordinates from vendor table
        // For now, use delivery address as approximation
        points.add(LatLng(
          order.deliveryAddress.latitude ?? 3.1390,
          order.deliveryAddress.longitude ?? 101.6869,
        ));
      }
      
      // Add delivery locations
      for (final order in orders) {
        points.add(LatLng(
          order.deliveryAddress.latitude ?? 3.1390,
          order.deliveryAddress.longitude ?? 101.6869,
        ));
      }
      
      // Calculate distance matrix
      final matrix = <List<double>>[];
      
      for (int i = 0; i < points.length; i++) {
        final row = <double>[];
        for (int j = 0; j < points.length; j++) {
          if (i == j) {
            row.add(0.0);
          } else {
            final distance = Geolocator.distanceBetween(
              points[i].latitude,
              points[i].longitude,
              points[j].latitude,
              points[j].longitude,
            ) / 1000.0; // Convert to kilometers
            row.add(distance);
          }
        }
        matrix.add(row);
      }
      
      debugPrint('✅ [OPTIMIZATION] Distance matrix calculated for ${points.length} points');
      return matrix;
    } catch (e) {
      debugPrint('❌ [OPTIMIZATION] Error calculating distance matrix: $e');
      throw Exception('Failed to calculate distance matrix: $e');
    }
  }

  /// Get real-time traffic conditions for route points
  Future<Map<String, TrafficCondition>> _getTrafficConditions(
    List<Order> orders,
    LatLng driverLocation,
  ) async {
    try {
      debugPrint('🚦 [OPTIMIZATION] Getting traffic conditions');
      
      // In a real implementation, this would query Google Traffic API or similar
      // For now, simulate traffic conditions based on time of day and location
      final trafficConditions = <String, TrafficCondition>{};
      final now = DateTime.now();
      final hour = now.hour;
      
      // Simulate traffic based on time of day
      TrafficCondition baseCondition;
      if ((hour >= 7 && hour <= 9) || (hour >= 17 && hour <= 19)) {
        baseCondition = TrafficCondition.heavy; // Rush hours
      } else if (hour >= 11 && hour <= 14) {
        baseCondition = TrafficCondition.moderate; // Lunch hours
      } else {
        baseCondition = TrafficCondition.light; // Off-peak
      }
      
      // Add some randomness for different areas
      final random = Random();
      for (final order in orders) {
        final variation = random.nextDouble();
        TrafficCondition condition;
        
        if (variation < 0.2) {
          condition = TrafficCondition.severe;
        } else if (variation < 0.4) {
          condition = TrafficCondition.heavy;
        } else if (variation < 0.7) {
          condition = baseCondition;
        } else {
          condition = TrafficCondition.light;
        }
        
        trafficConditions[order.id] = condition;
      }
      
      debugPrint('✅ [OPTIMIZATION] Traffic conditions retrieved');
      return trafficConditions;
    } catch (e) {
      debugPrint('❌ [OPTIMIZATION] Error getting traffic conditions: $e');
      return {};
    }
  }

  /// Solve TSP using hybrid optimization approach
  Future<OptimizedRoute> _solveTSP({
    required List<Order> orders,
    required LatLng driverLocation,
    required List<List<double>> distanceMatrix,
    required Map<String, TrafficCondition> trafficConditions,
    required Map<String, PreparationWindow> preparationWindows,
    required OptimizationCriteria criteria,
  }) async {
    try {
      debugPrint('🧮 [OPTIMIZATION] Solving TSP with ${orders.length} orders');
      
      final stopwatch = Stopwatch()..start();
      
      // For small problems (≤3 orders), use exact solution
      List<int> bestSequence;
      if (orders.length <= 3) {
        bestSequence = await _solveExactTSP(
          orders,
          distanceMatrix,
          trafficConditions,
          preparationWindows,
          criteria,
        );
      } else {
        // For larger problems, use heuristic approach
        bestSequence = await _solveHeuristicTSP(
          orders,
          distanceMatrix,
          trafficConditions,
          preparationWindows,
          criteria,
        );
      }
      
      stopwatch.stop();
      debugPrint('⏱️ [OPTIMIZATION] TSP solved in ${stopwatch.elapsedMilliseconds}ms');
      
      // Convert solution to optimized route
      final optimizedRoute = await _buildOptimizedRoute(
        orders,
        bestSequence,
        driverLocation,
        distanceMatrix,
        trafficConditions,
        preparationWindows,
        criteria,
      );
      
      return optimizedRoute;
    } catch (e) {
      debugPrint('❌ [OPTIMIZATION] Error solving TSP: $e');
      throw Exception('TSP optimization failed: $e');
    }
  }

  /// Solve TSP exactly using brute force (for small problems)
  Future<List<int>> _solveExactTSP(
    List<Order> orders,
    List<List<double>> distanceMatrix,
    Map<String, TrafficCondition> trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    debugPrint('🎯 [OPTIMIZATION] Using exact TSP solution');
    
    final orderIndices = List.generate(orders.length, (i) => i);
    double bestScore = double.negativeInfinity;
    List<int> bestSequence = orderIndices;
    
    // Generate all permutations
    final permutations = _generatePermutations(orderIndices);
    
    for (final sequence in permutations) {
      final score = await _evaluateSequence(
        sequence,
        orders,
        distanceMatrix,
        trafficConditions,
        preparationWindows,
        criteria,
      );
      
      if (score > bestScore) {
        bestScore = score;
        bestSequence = List.from(sequence);
      }
    }
    
    debugPrint('🎯 [OPTIMIZATION] Exact solution found with score: ${bestScore.toStringAsFixed(2)}');
    return bestSequence;
  }

  /// Solve TSP using heuristic approach (for larger problems)
  Future<List<int>> _solveHeuristicTSP(
    List<Order> orders,
    List<List<double>> distanceMatrix,
    Map<String, TrafficCondition> trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    debugPrint('🚀 [OPTIMIZATION] Using heuristic TSP solution');
    
    // Start with nearest neighbor heuristic
    List<int> currentSequence = await _nearestNeighborHeuristic(
      orders,
      distanceMatrix,
      trafficConditions,
      preparationWindows,
      criteria,
    );
    
    // Improve with 2-opt local search
    currentSequence = await _twoOptImprovement(
      currentSequence,
      orders,
      distanceMatrix,
      trafficConditions,
      preparationWindows,
      criteria,
    );
    
    return currentSequence;
  }

  /// Nearest neighbor heuristic for TSP
  Future<List<int>> _nearestNeighborHeuristic(
    List<Order> orders,
    List<List<double>> distanceMatrix,
    Map<String, TrafficCondition> trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    final sequence = <int>[];
    final unvisited = Set<int>.from(List.generate(orders.length, (i) => i));
    
    // Start with the order that has the best preparation time alignment
    int current = _findBestStartingOrder(orders, preparationWindows);
    sequence.add(current);
    unvisited.remove(current);
    
    while (unvisited.isNotEmpty) {
      double bestScore = double.negativeInfinity;
      int bestNext = -1;
      
      for (final next in unvisited) {
        final score = await _evaluateTransition(
          current,
          next,
          orders,
          distanceMatrix,
          trafficConditions,
          preparationWindows,
          criteria,
        );
        
        if (score > bestScore) {
          bestScore = score;
          bestNext = next;
        }
      }
      
      sequence.add(bestNext);
      unvisited.remove(bestNext);
      current = bestNext;
    }
    
    return sequence;
  }

  /// 2-opt improvement for TSP solution
  Future<List<int>> _twoOptImprovement(
    List<int> sequence,
    List<Order> orders,
    List<List<double>> distanceMatrix,
    Map<String, TrafficCondition> trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    List<int> bestSequence = List.from(sequence);
    double bestScore = await _evaluateSequence(
      bestSequence,
      orders,
      distanceMatrix,
      trafficConditions,
      preparationWindows,
      criteria,
    );
    
    bool improved = true;
    while (improved) {
      improved = false;
      
      for (int i = 0; i < sequence.length - 1; i++) {
        for (int j = i + 1; j < sequence.length; j++) {
          // Create 2-opt swap
          final newSequence = _twoOptSwap(bestSequence, i, j);
          
          final score = await _evaluateSequence(
            newSequence,
            orders,
            distanceMatrix,
            trafficConditions,
            preparationWindows,
            criteria,
          );
          
          if (score > bestScore) {
            bestScore = score;
            bestSequence = newSequence;
            improved = true;
          }
        }
      }
    }
    
    return bestSequence;
  }

  /// Evaluate sequence quality using multi-criteria scoring
  Future<double> _evaluateSequence(
    List<int> sequence,
    List<Order> orders,
    List<List<double>> distanceMatrix,
    Map<String, TrafficCondition> trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    double totalScore = 0.0;

    // Distance score (lower distance = higher score)
    final distanceScore = _calculateDistanceScore(sequence, distanceMatrix);
    totalScore += distanceScore * criteria.distanceWeight;

    // Preparation time score (better alignment = higher score)
    final preparationScore = _calculatePreparationScore(sequence, orders, preparationWindows);
    totalScore += preparationScore * criteria.preparationTimeWeight;

    // Traffic score (less traffic = higher score)
    final trafficScore = _calculateTrafficScore(sequence, orders, trafficConditions);
    totalScore += trafficScore * criteria.trafficWeight;

    // Delivery window score (meeting windows = higher score)
    final deliveryWindowScore = _calculateDeliveryWindowScore(sequence, orders);
    totalScore += deliveryWindowScore * criteria.deliveryWindowWeight;

    return totalScore;
  }

  /// Evaluate transition between two orders
  Future<double> _evaluateTransition(
    int from,
    int to,
    List<Order> orders,
    List<List<double>> distanceMatrix,
    Map<String, TrafficCondition> trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    // Distance factor
    final distance = distanceMatrix[from + 1][to + 1]; // +1 for driver location offset
    final distanceScore = max(0.0, 1.0 - distance / 20.0); // Normalize to 20km max

    // Preparation time alignment
    final preparationWindow = preparationWindows[orders[to].id];
    final preparationScore = preparationWindow?.confidenceScore ?? 0.5;

    // Traffic factor
    final trafficCondition = trafficConditions[orders[to].id] ?? TrafficCondition.moderate;
    final trafficScore = _getTrafficScore(trafficCondition);

    // Weighted combination
    return (distanceScore * criteria.distanceWeight) +
           (preparationScore * criteria.preparationTimeWeight) +
           (trafficScore * criteria.trafficWeight);
  }

  /// Calculate distance score for sequence
  double _calculateDistanceScore(List<int> sequence, List<List<double>> distanceMatrix) {
    if (sequence.isEmpty) return 0.0;

    double totalDistance = 0.0;

    // Distance from driver to first pickup
    totalDistance += distanceMatrix[0][sequence.first + 1];

    // Distance between consecutive pickups
    for (int i = 0; i < sequence.length - 1; i++) {
      totalDistance += distanceMatrix[sequence[i] + 1][sequence[i + 1] + 1];
    }

    // Distance from last pickup to first delivery (simplified)
    final deliveryOffset = sequence.length + 1;
    totalDistance += distanceMatrix[sequence.last + 1][sequence.first + deliveryOffset];

    // Distance between consecutive deliveries
    for (int i = 0; i < sequence.length - 1; i++) {
      totalDistance += distanceMatrix[sequence[i] + deliveryOffset][sequence[i + 1] + deliveryOffset];
    }

    // Normalize score (lower distance = higher score)
    return max(0.0, 1.0 - totalDistance / 50.0); // Normalize to 50km max
  }

  /// Calculate preparation time alignment score
  double _calculatePreparationScore(
    List<int> sequence,
    List<Order> orders,
    Map<String, PreparationWindow> preparationWindows,
  ) {
    if (sequence.isEmpty) return 0.0;

    double totalScore = 0.0;
    DateTime currentTime = DateTime.now();

    for (final orderIndex in sequence) {
      final order = orders[orderIndex];
      final preparationWindow = preparationWindows[order.id];

      if (preparationWindow != null) {
        // Score based on how well pickup time aligns with preparation completion
        final pickupTime = currentTime.add(const Duration(minutes: 15)); // Estimated travel time

        if (preparationWindow.isReadyBy(pickupTime)) {
          // Order will be ready - good alignment
          totalScore += preparationWindow.confidenceScore;
        } else {
          // Order won't be ready - penalize based on delay
          final delay = preparationWindow.estimatedCompletionTime.difference(pickupTime);
          final delayPenalty = max(0.0, 1.0 - delay.inMinutes / 30.0); // 30 min max penalty
          totalScore += preparationWindow.confidenceScore * delayPenalty;
        }

        // Update current time for next order
        currentTime = currentTime.add(const Duration(minutes: 20)); // Estimated time per order
      } else {
        totalScore += 0.5; // Default score for missing preparation data
      }
    }

    return sequence.isEmpty ? 0.0 : totalScore / sequence.length;
  }

  /// Calculate traffic score for sequence
  double _calculateTrafficScore(
    List<int> sequence,
    List<Order> orders,
    Map<String, TrafficCondition> trafficConditions,
  ) {
    if (sequence.isEmpty) return 0.0;

    double totalScore = 0.0;

    for (final orderIndex in sequence) {
      final order = orders[orderIndex];
      final trafficCondition = trafficConditions[order.id] ?? TrafficCondition.moderate;
      totalScore += _getTrafficScore(trafficCondition);
    }

    return totalScore / sequence.length;
  }

  /// Calculate delivery window score
  double _calculateDeliveryWindowScore(List<int> sequence, List<Order> orders) {
    // For now, return a default score since delivery windows aren't implemented
    // In a real implementation, this would check if deliveries can be made within customer windows
    return 0.8;
  }

  /// Get traffic score for condition
  double _getTrafficScore(TrafficCondition condition) {
    switch (condition) {
      case TrafficCondition.clear:
        return 1.0;
      case TrafficCondition.light:
        return 0.8;
      case TrafficCondition.moderate:
        return 0.6;
      case TrafficCondition.heavy:
        return 0.4;
      case TrafficCondition.severe:
        return 0.2;
      case TrafficCondition.unknown:
        return 0.6;
    }
  }

  /// Find best starting order based on preparation times
  int _findBestStartingOrder(
    List<Order> orders,
    Map<String, PreparationWindow> preparationWindows,
  ) {
    int bestOrder = 0;
    double bestScore = 0.0;

    for (int i = 0; i < orders.length; i++) {
      final order = orders[i];
      final preparationWindow = preparationWindows[order.id];

      if (preparationWindow != null) {
        // Prefer orders that will be ready soon
        final readinessScore = preparationWindow.isReadyBy(DateTime.now().add(const Duration(minutes: 10))) ? 1.0 : 0.5;
        final confidenceScore = preparationWindow.confidenceScore;
        final totalScore = readinessScore * confidenceScore;

        if (totalScore > bestScore) {
          bestScore = totalScore;
          bestOrder = i;
        }
      }
    }

    return bestOrder;
  }

  /// Generate all permutations for exact TSP
  List<List<int>> _generatePermutations(List<int> items) {
    if (items.length <= 1) return [items];

    final permutations = <List<int>>[];

    for (int i = 0; i < items.length; i++) {
      final current = items[i];
      final remaining = [...items.sublist(0, i), ...items.sublist(i + 1)];

      for (final perm in _generatePermutations(remaining)) {
        permutations.add([current, ...perm]);
      }
    }

    return permutations;
  }

  /// Perform 2-opt swap
  List<int> _twoOptSwap(List<int> sequence, int i, int j) {
    final newSequence = List<int>.from(sequence);

    // Reverse the segment between i and j
    final segment = newSequence.sublist(i, j + 1).reversed.toList();
    newSequence.replaceRange(i, j + 1, segment);

    return newSequence;
  }

  /// Analyze if reoptimization is needed based on events
  RouteUpdateReason? _analyzeReoptimizationNeed(List<RouteEvent> events) {
    for (final event in events) {
      switch (event.type) {
        case RouteEventType.trafficIncident:
          final severity = event.data['severity'] as String? ?? 'moderate';
          if (severity == 'severe' || severity == 'heavy') {
            return RouteUpdateReason.trafficChange;
          }
          break;

        case RouteEventType.preparationDelay:
          final delayMinutes = event.data['delay_minutes'] as int? ?? 0;
          if (delayMinutes > 15) {
            return RouteUpdateReason.preparationDelay;
          }
          break;

        case RouteEventType.orderReady:
          // Order ready earlier than expected might trigger reoptimization
          final earlyMinutes = event.data['early_minutes'] as int? ?? 0;
          if (earlyMinutes > 10) {
            return RouteUpdateReason.systemOptimization;
          }
          break;

        default:
          break;
      }
    }

    return null;
  }

  /// Get remaining orders from current route and progress
  Future<List<Order>> _getRemainingOrders(OptimizedRoute route, RouteProgress progress) async {
    // This would query the database for orders that haven't been completed yet
    // For now, return empty list as placeholder
    return [];
  }

  /// Get current driver location
  Future<LatLng> _getCurrentDriverLocation() async {
    // This would get the driver's current location from GPS
    // For now, return default location
    return const LatLng(3.1390, 101.6869); // KL city center
  }

  /// Build optimized route from TSP solution
  Future<OptimizedRoute> _buildOptimizedRoute(
    List<Order> orders,
    List<int> sequence,
    LatLng driverLocation,
    List<List<double>> distanceMatrix,
    Map<String, TrafficCondition> trafficConditions,
    Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria criteria,
  ) async {
    final waypoints = <RouteWaypoint>[];
    DateTime currentTime = DateTime.now();
    double totalDistance = 0.0;
    Duration totalDuration = Duration.zero;

    // Create pickup waypoints
    for (int i = 0; i < sequence.length; i++) {
      final orderIndex = sequence[i];
      final order = orders[orderIndex];

      // Calculate distance from previous point
      double distanceFromPrevious;
      if (i == 0) {
        distanceFromPrevious = distanceMatrix[0][orderIndex + 1]; // From driver location
      } else {
        distanceFromPrevious = distanceMatrix[sequence[i - 1] + 1][orderIndex + 1];
      }

      totalDistance += distanceFromPrevious;

      // Estimate travel time (40 km/h average)
      final travelTime = Duration(minutes: (distanceFromPrevious / 40 * 60).round());
      currentTime = currentTime.add(travelTime);
      totalDuration = totalDuration + travelTime;

      // Create pickup waypoint
      final pickupWaypoint = RouteWaypoint.pickup(
        orderId: order.id,
        location: LatLng(
          order.deliveryAddress.latitude ?? 3.1390,
          order.deliveryAddress.longitude ?? 101.6869,
        ),
        sequence: i + 1,
        estimatedArrivalTime: currentTime,
        estimatedDuration: const Duration(minutes: 5), // Pickup time
        distanceFromPrevious: distanceFromPrevious,
      );

      waypoints.add(pickupWaypoint);

      // Add pickup time
      currentTime = currentTime.add(const Duration(minutes: 5));
      totalDuration = totalDuration + const Duration(minutes: 5);
    }

    // Create delivery waypoints (same sequence for simplicity)
    for (int i = 0; i < sequence.length; i++) {
      final orderIndex = sequence[i];
      final order = orders[orderIndex];

      // Calculate distance from previous point
      double distanceFromPrevious;
      if (i == 0) {
        // Distance from last pickup to first delivery
        distanceFromPrevious = distanceMatrix[sequence.last + 1][orderIndex + 1];
      } else {
        distanceFromPrevious = distanceMatrix[sequence[i - 1] + 1][orderIndex + 1];
      }

      totalDistance += distanceFromPrevious;

      // Estimate travel time
      final travelTime = Duration(minutes: (distanceFromPrevious / 40 * 60).round());
      currentTime = currentTime.add(travelTime);
      totalDuration = totalDuration + travelTime;

      // Create delivery waypoint
      final deliveryWaypoint = RouteWaypoint.delivery(
        orderId: order.id,
        location: LatLng(
          order.deliveryAddress.latitude ?? 3.1390,
          order.deliveryAddress.longitude ?? 101.6869,
        ),
        sequence: sequence.length + i + 1,
        estimatedArrivalTime: currentTime,
        estimatedDuration: const Duration(minutes: 3), // Delivery time
        distanceFromPrevious: distanceFromPrevious,
      );

      waypoints.add(deliveryWaypoint);

      // Add delivery time
      currentTime = currentTime.add(const Duration(minutes: 3));
      totalDuration = totalDuration + const Duration(minutes: 3);
    }

    // Calculate optimization score
    final optimizationScore = await _evaluateSequence(
      sequence,
      orders,
      distanceMatrix,
      trafficConditions,
      preparationWindows,
      criteria,
    ) * 100; // Convert to percentage

    // Determine overall traffic condition
    final trafficScores = trafficConditions.values.map(_getTrafficScore).toList();
    final avgTrafficScore = trafficScores.isEmpty ? 0.6 : trafficScores.reduce((a, b) => a + b) / trafficScores.length;

    TrafficCondition overallTraffic;
    if (avgTrafficScore >= 0.8) {
      overallTraffic = TrafficCondition.light;
    } else if (avgTrafficScore >= 0.6) {
      overallTraffic = TrafficCondition.moderate;
    } else if (avgTrafficScore >= 0.4) {
      overallTraffic = TrafficCondition.heavy;
    } else {
      overallTraffic = TrafficCondition.severe;
    }

    return OptimizedRoute(
      id: 'route_${DateTime.now().millisecondsSinceEpoch}',
      batchId: 'batch_${orders.first.id}', // Simplified batch ID
      waypoints: waypoints,
      totalDistanceKm: totalDistance,
      totalDuration: totalDuration,
      durationInTraffic: Duration(minutes: (totalDuration.inMinutes * 1.2).round()), // 20% traffic delay
      optimizationScore: optimizationScore,
      criteria: criteria,
      calculatedAt: DateTime.now(),
      overallTrafficCondition: overallTraffic,
    );
  }
}
