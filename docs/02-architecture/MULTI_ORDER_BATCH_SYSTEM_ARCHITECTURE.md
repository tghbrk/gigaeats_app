# Multi-Order Batch System Architecture

## 🏗️ System Overview

The Multi-Order Batch System architecture extends the existing GigaEats driver workflow to support intelligent batching of 2-3 orders with optimized routing, real-time tracking, and automated customer communication.

## 📊 Database Schema Design

### **Core Batch Management Tables**

#### **Delivery Batches Table**
```sql
-- Core delivery batch management
CREATE TABLE delivery_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    batch_number TEXT NOT NULL UNIQUE,
    status batch_status_enum NOT NULL DEFAULT 'planned',
    
    -- Route optimization data
    total_distance_km DECIMAL(8,2),
    estimated_duration_minutes INTEGER,
    optimization_score DECIMAL(5,2), -- 0-100 efficiency score
    
    -- Batch constraints
    max_orders INTEGER DEFAULT 3,
    max_deviation_km DECIMAL(6,2) DEFAULT 5.0,
    
    -- Timing
    planned_start_time TIMESTAMPTZ,
    actual_start_time TIMESTAMPTZ,
    estimated_completion_time TIMESTAMPTZ,
    actual_completion_time TIMESTAMPTZ,
    
    -- Metadata
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes for performance
    INDEX idx_delivery_batches_driver_status (driver_id, status),
    INDEX idx_delivery_batches_planned_start (planned_start_time)
);

-- Batch status enum
CREATE TYPE batch_status_enum AS ENUM (
    'planned',      -- Batch created, orders assigned
    'optimized',    -- Route optimized, ready to start
    'active',       -- Driver started batch execution
    'paused',       -- Temporarily paused
    'completed',    -- All orders delivered
    'cancelled',    -- Batch cancelled
    'split'         -- Batch split into multiple batches
);
```

#### **Batch Orders Association Table**
```sql
-- Many-to-many relationship between batches and orders
CREATE TABLE batch_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES delivery_batches(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    
    -- Sequence and routing
    pickup_sequence INTEGER NOT NULL,
    delivery_sequence INTEGER NOT NULL,
    
    -- Timing estimates
    estimated_pickup_time TIMESTAMPTZ,
    estimated_delivery_time TIMESTAMPTZ,
    actual_pickup_time TIMESTAMPTZ,
    actual_delivery_time TIMESTAMPTZ,
    
    -- Route optimization data
    distance_from_previous_km DECIMAL(6,2),
    travel_time_from_previous_minutes INTEGER,
    
    -- Status tracking
    pickup_status order_pickup_status DEFAULT 'pending',
    delivery_status order_delivery_status DEFAULT 'pending',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(batch_id, order_id),
    UNIQUE(batch_id, pickup_sequence),
    UNIQUE(batch_id, delivery_sequence),
    
    -- Indexes
    INDEX idx_batch_orders_batch_sequence (batch_id, pickup_sequence),
    INDEX idx_batch_orders_timing (estimated_pickup_time, estimated_delivery_time)
);

-- Order status enums for batch context
CREATE TYPE order_pickup_status AS ENUM (
    'pending',      -- Not yet picked up
    'en_route',     -- Driver heading to pickup
    'arrived',      -- Driver at pickup location
    'picked_up',    -- Order collected
    'skipped'       -- Pickup skipped (order not ready)
);

CREATE TYPE order_delivery_status AS ENUM (
    'pending',      -- Not yet delivered
    'en_route',     -- Driver heading to delivery
    'arrived',      -- Driver at delivery location
    'delivered',    -- Successfully delivered
    'failed',       -- Delivery failed
    'rescheduled'   -- Delivery rescheduled
);
```

### **Route Optimization Tables**

#### **Optimized Routes Table**
```sql
-- Store calculated route information
CREATE TABLE optimized_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES delivery_batches(id) ON DELETE CASCADE,
    
    -- Route metadata
    route_version INTEGER NOT NULL DEFAULT 1,
    optimization_algorithm TEXT NOT NULL, -- 'tsp_genetic', 'nearest_neighbor', etc.
    optimization_criteria JSONB NOT NULL, -- Weights for distance, time, traffic
    
    -- Route geometry and waypoints
    route_polyline TEXT, -- Encoded polyline for full route
    total_distance_meters INTEGER NOT NULL,
    estimated_duration_seconds INTEGER NOT NULL,
    
    -- Traffic and conditions
    traffic_conditions JSONB, -- Real-time traffic data at calculation time
    weather_conditions JSONB, -- Weather impact on route
    
    -- Performance metrics
    fuel_efficiency_score DECIMAL(5,2),
    carbon_footprint_kg DECIMAL(8,3),
    
    -- Timing
    calculated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    valid_until TIMESTAMPTZ, -- Route validity expiration
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(batch_id, route_version),
    
    -- Indexes
    INDEX idx_optimized_routes_batch_version (batch_id, route_version DESC),
    INDEX idx_optimized_routes_calculated (calculated_at)
);
```

#### **Route Waypoints Table**
```sql
-- Detailed waypoint information for routes
CREATE TABLE route_waypoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_id UUID NOT NULL REFERENCES optimized_routes(id) ON DELETE CASCADE,
    
    -- Waypoint details
    waypoint_type waypoint_type_enum NOT NULL,
    sequence_number INTEGER NOT NULL,
    
    -- Location
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    address TEXT NOT NULL,
    
    -- Associated order (if applicable)
    order_id UUID REFERENCES orders(id) ON DELETE SET NULL,
    vendor_id UUID REFERENCES vendors(id) ON DELETE SET NULL,
    customer_id UUID REFERENCES customers(id) ON DELETE SET NULL,
    
    -- Timing and navigation
    estimated_arrival_time TIMESTAMPTZ,
    estimated_departure_time TIMESTAMPTZ,
    dwell_time_minutes INTEGER DEFAULT 5, -- Expected stop duration
    
    -- Navigation instructions
    navigation_instruction TEXT,
    distance_from_previous_meters INTEGER,
    travel_time_from_previous_seconds INTEGER,
    
    -- Status tracking
    status waypoint_status_enum DEFAULT 'pending',
    actual_arrival_time TIMESTAMPTZ,
    actual_departure_time TIMESTAMPTZ,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Constraints
    UNIQUE(route_id, sequence_number),
    
    -- Indexes
    INDEX idx_route_waypoints_route_sequence (route_id, sequence_number),
    INDEX idx_route_waypoints_order (order_id),
    INDEX idx_route_waypoints_timing (estimated_arrival_time)
);

-- Waypoint enums
CREATE TYPE waypoint_type_enum AS ENUM (
    'pickup',       -- Order pickup location
    'delivery',     -- Order delivery location
    'fuel_stop',    -- Fuel/charging stop
    'break',        -- Driver break location
    'depot'         -- Return to depot
);

CREATE TYPE waypoint_status_enum AS ENUM (
    'pending',      -- Not yet reached
    'approaching',  -- Within 500m
    'arrived',      -- At location
    'completed',    -- Task completed
    'skipped'       -- Waypoint skipped
);
```

### **Enhanced Location Tracking**

#### **Driver Location Tracking Table**
```sql
-- Enhanced driver location tracking
CREATE TABLE driver_location_tracking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    batch_id UUID REFERENCES delivery_batches(id) ON DELETE SET NULL,
    
    -- Location data
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    altitude_meters DECIMAL(8,2),
    accuracy_meters DECIMAL(6,2),
    bearing_degrees DECIMAL(5,2), -- 0-360 degrees
    speed_kmh DECIMAL(5,2),
    
    -- Context
    current_waypoint_id UUID REFERENCES route_waypoints(id),
    distance_to_next_waypoint_meters INTEGER,
    eta_to_next_waypoint TIMESTAMPTZ,
    
    -- Device and network info
    device_timestamp TIMESTAMPTZ NOT NULL,
    network_type TEXT, -- '4G', '5G', 'WiFi'
    battery_level INTEGER, -- 0-100
    
    -- Geofencing
    is_at_pickup_location BOOLEAN DEFAULT FALSE,
    is_at_delivery_location BOOLEAN DEFAULT FALSE,
    geofence_events JSONB, -- Array of geofence entry/exit events
    
    recorded_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- Indexes for real-time queries
    INDEX idx_driver_location_driver_time (driver_id, recorded_at DESC),
    INDEX idx_driver_location_batch (batch_id, recorded_at DESC),
    INDEX idx_driver_location_spatial (latitude, longitude),
    INDEX idx_driver_location_waypoint (current_waypoint_id)
);

-- Spatial index for location queries
CREATE INDEX idx_driver_location_gist ON driver_location_tracking 
USING GIST (ST_Point(longitude, latitude));
```

## 🔧 Service Layer Architecture

### **Multi-Order Batch Service**
```dart
class MultiOrderBatchService {
  final SupabaseClient _supabase;
  final RouteOptimizationEngine _routeEngine;
  final PreparationTimeService _preparationService;
  
  /// Create optimized delivery batch
  Future<DeliveryBatch> createOptimizedBatch({
    required String driverId,
    required List<String> orderIds,
    int maxOrders = 3,
    double maxDeviationKm = 5.0,
  }) async {
    // 1. Validate orders are eligible for batching
    final orders = await _validateOrdersForBatching(orderIds, maxDeviationKm);
    
    // 2. Get preparation time predictions
    final preparationWindows = await _preparationService
        .predictPreparationTimes(orders);
    
    // 3. Calculate optimal route
    final optimizedRoute = await _routeEngine.calculateOptimalRoute(
      orders: orders,
      driverLocation: await _getDriverLocation(driverId),
      preparationWindows: preparationWindows,
    );
    
    // 4. Create batch in database
    return await _createBatchInDatabase(
      driverId: driverId,
      orders: orders,
      route: optimizedRoute,
    );
  }
  
  /// Dynamic batch optimization during delivery
  Future<DeliveryBatch> optimizeBatch(
    DeliveryBatch currentBatch,
    {bool considerTraffic = true, bool considerPreparationTimes = true}
  ) async {
    final currentProgress = await _getBatchProgress(currentBatch.id);
    final events = await _getRecentRouteEvents(currentBatch.id);
    
    final reoptimizedRoute = await _routeEngine.reoptimizeRoute(
      currentBatch.route,
      currentProgress,
      events,
    );
    
    if (reoptimizedRoute.improvementScore > 0.1) {
      return await _updateBatchRoute(currentBatch, reoptimizedRoute);
    }
    
    return currentBatch;
  }
}
```

### **Route Optimization Engine**
```dart
class RouteOptimizationEngine {
  final GoogleMapsService _mapsService;
  final TrafficService _trafficService;
  
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
    // Genetic algorithm implementation for TSP
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
    }
    
    // Return best route from final population
    final bestRouteIndex = _findBestRoute(population, fitnessScores);
    return population[bestRouteIndex];
  }
}
```

## 🔄 Provider State Management Flow

### **Batch Management Providers**
```dart
// Core batch state management
final activeBatchProvider = StreamProvider<DeliveryBatch?>((ref) {
  final supabase = ref.read(supabaseProvider);
  final authState = ref.read(authStateProvider);
  
  if (authState.user?.id == null) return Stream.value(null);
  
  return supabase
      .from('delivery_batches')
      .stream(primaryKey: ['id'])
      .eq('driver_id', authState.user!.id)
      .inFilter('status', ['planned', 'optimized', 'active', 'paused'])
      .map((data) => data.isNotEmpty 
          ? DeliveryBatch.fromJson(data.first) 
          : null);
});

// Batch optimization provider
final batchOptimizationProvider = FutureProvider.family<OptimizedRoute, String>((ref, batchId) async {
  final batchService = ref.read(multiOrderBatchServiceProvider);
  final batch = await batchService.getBatch(batchId);
  
  if (batch == null) throw Exception('Batch not found');
  
  return await batchService.optimizeBatch(batch);
});

// Batch progress tracking
final batchProgressProvider = StateNotifierProvider<BatchProgressNotifier, BatchProgress>((ref) {
  return BatchProgressNotifier(ref);
});

class BatchProgressNotifier extends StateNotifier<BatchProgress> {
  final Ref _ref;
  StreamSubscription? _progressSubscription;
  
  BatchProgressNotifier(this._ref) : super(BatchProgress.initial()) {
    _initializeProgressTracking();
  }
  
  void _initializeProgressTracking() {
    final activeBatch = _ref.read(activeBatchProvider);
    
    activeBatch.whenData((batch) {
      if (batch != null) {
        _startProgressTracking(batch.id);
      }
    });
  }
  
  void _startProgressTracking(String batchId) {
    final supabase = _ref.read(supabaseProvider);
    
    _progressSubscription = supabase
        .from('batch_orders')
        .stream(primaryKey: ['id'])
        .eq('batch_id', batchId)
        .listen((data) {
      final progress = _calculateBatchProgress(data);
      state = progress;
    });
  }
}
```

### **Enhanced Navigation Providers**
```dart
// Enhanced navigation state management
final enhancedNavigationProvider = StateNotifierProvider<NavigationNotifier, NavigationState>((ref) {
  return NavigationNotifier(ref);
});

class NavigationNotifier extends StateNotifier<NavigationState> {
  final Ref _ref;
  NavigationSession? _currentSession;
  StreamSubscription? _instructionSubscription;
  
  NavigationNotifier(this._ref) : super(NavigationState.initial());
  
  /// Start in-app navigation for batch delivery
  Future<void> startBatchNavigation(DeliveryBatch batch) async {
    final navigationService = _ref.read(enhancedNavigationServiceProvider);
    final currentLocation = await _getCurrentLocation();
    
    // Start navigation to first waypoint
    final firstWaypoint = batch.route.waypoints.first;
    
    _currentSession = await navigationService.startInAppNavigation(
      origin: currentLocation,
      destination: firstWaypoint.location,
      orderId: firstWaypoint.orderId,
      batchId: batch.id,
    );
    
    state = state.copyWith(
      isNavigating: true,
      currentSession: _currentSession,
      currentWaypoint: firstWaypoint,
    );
    
    _startInstructionStream();
  }
  
  void _startInstructionStream() {
    if (_currentSession == null) return;
    
    _instructionSubscription = _currentSession!.instructionStream.listen((instruction) {
      state = state.copyWith(currentInstruction: instruction);
      
      // Handle automatic status transitions
      _handleLocationBasedStatusUpdate(instruction);
    });
  }
  
  Future<void> _handleLocationBasedStatusUpdate(NavigationInstruction instruction) async {
    if (instruction.type == ManeuverType.arrive) {
      final workflowProvider = _ref.read(enhancedDriverWorkflowProvider.notifier);
      await workflowProvider.handleWaypointArrival(state.currentWaypoint!);
    }
  }
}
```

## 📡 Real-Time Subscription Patterns

### **Batch Real-Time Updates**
```sql
-- Enable real-time replication for batch management
ALTER TABLE delivery_batches REPLICA IDENTITY FULL;
ALTER TABLE batch_orders REPLICA IDENTITY FULL;
ALTER TABLE route_waypoints REPLICA IDENTITY FULL;
ALTER TABLE driver_location_tracking REPLICA IDENTITY FULL;

-- Create publication for real-time subscriptions
CREATE PUBLICATION batch_delivery_updates FOR TABLE 
    delivery_batches, 
    batch_orders, 
    route_waypoints, 
    driver_location_tracking,
    orders;
```

### **Flutter Real-Time Integration**
```dart
class BatchRealtimeService {
  final SupabaseClient _supabase;
  
  /// Subscribe to batch updates for driver
  Stream<DeliveryBatch?> subscribeToBatchUpdates(String driverId) {
    return _supabase
        .from('delivery_batches')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .inFilter('status', ['planned', 'optimized', 'active', 'paused'])
        .map((data) => data.isNotEmpty 
            ? DeliveryBatch.fromJson(data.first) 
            : null);
  }
  
  /// Subscribe to route waypoint updates
  Stream<List<RouteWaypoint>> subscribeToWaypointUpdates(String routeId) {
    return _supabase
        .from('route_waypoints')
        .stream(primaryKey: ['id'])
        .eq('route_id', routeId)
        .order('sequence_number')
        .map((data) => data.map((json) => RouteWaypoint.fromJson(json)).toList());
  }
  
  /// Subscribe to driver location updates
  Stream<DriverLocation> subscribeToDriverLocation(String driverId) {
    return _supabase
        .from('driver_location_tracking')
        .stream(primaryKey: ['id'])
        .eq('driver_id', driverId)
        .order('recorded_at', ascending: false)
        .limit(1)
        .map((data) => data.isNotEmpty 
            ? DriverLocation.fromJson(data.first) 
            : DriverLocation.unknown());
  }
}
```

## 🔌 API Integration Specifications

### **Supabase Edge Functions**

#### **Create Delivery Batch Function**
```typescript
// supabase/functions/create-delivery-batch/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

interface CreateBatchRequest {
  driver_id: string;
  order_ids: string[];
  max_orders?: number;
  max_deviation_km?: number;
}

serve(async (req) => {
  try {
    const { driver_id, order_ids, max_orders = 3, max_deviation_km = 5.0 }: CreateBatchRequest = await req.json();
    
    // Validate orders are eligible for batching
    const orders = await validateOrdersForBatching(order_ids, max_deviation_km);
    
    // Calculate optimal route
    const optimizedRoute = await calculateOptimalRoute(orders, driver_id);
    
    // Create batch in database
    const batch = await createBatchInDatabase({
      driver_id,
      orders,
      route: optimizedRoute,
      max_orders,
      max_deviation_km
    });
    
    return new Response(JSON.stringify({ success: true, batch }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
```

#### **Optimize Batch Route Function**
```typescript
// supabase/functions/optimize-batch-route/index.ts
serve(async (req) => {
  try {
    const { batch_id, consider_traffic = true, consider_preparation_times = true } = await req.json();
    
    // Get current batch and progress
    const batch = await getBatch(batch_id);
    const progress = await getBatchProgress(batch_id);
    const events = await getRecentRouteEvents(batch_id);
    
    // Reoptimize route
    const reoptimizedRoute = await reoptimizeRoute(batch.route, progress, events, {
      considerTraffic: consider_traffic,
      considerPreparationTimes: consider_preparation_times
    });
    
    // Update batch if improvement is significant
    if (reoptimizedRoute.improvementScore > 0.1) {
      await updateBatchRoute(batch_id, reoptimizedRoute);
    }
    
    return new Response(JSON.stringify({ 
      success: true, 
      route: reoptimizedRoute,
      improvement_score: reoptimizedRoute.improvementScore 
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
```

This architecture provides a comprehensive foundation for the multi-order batch system while maintaining compatibility with the existing GigaEats infrastructure and following established patterns for scalability and maintainability.
