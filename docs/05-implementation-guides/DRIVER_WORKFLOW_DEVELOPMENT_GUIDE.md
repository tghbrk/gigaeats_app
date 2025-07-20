# Driver Workflow Enhancement Development Guide

## 🎯 Overview

This comprehensive development guide provides step-by-step implementation instructions for the GigaEats Driver Workflow Enhancement project, including code examples, testing procedures, and integration checkpoints following the established Flutter/Riverpod/Supabase architecture patterns.

## 📋 Prerequisites

### **Development Environment Setup**
- Flutter SDK 3.16.0 or higher
- Dart SDK 3.2.0 or higher
- Android Studio with Android emulator (emulator-5554)
- VS Code or IntelliJ IDEA Ultimate
- Supabase CLI for database migrations
- Google Maps API key with required permissions

### **Required Dependencies**
```yaml
# pubspec.yaml additions
dependencies:
  google_maps_flutter: ^2.5.0
  geolocator: ^10.1.0
  flutter_tts: ^3.8.3
  flutter_speed_dial: ^7.0.0
  reorderables: ^0.6.0
  
dev_dependencies:
  integration_test: ^3.1.0
  mockito: ^5.4.2
  build_runner: ^2.4.7
```

## 🏗️ Phase 1: Foundation Enhancement (Weeks 1-3)

### **Week 1: Database Schema Implementation**

#### **Step 1.1: Create Migration Files**
```bash
# Create new migration files
supabase migration new multi_order_batch_system
supabase migration new enhanced_location_tracking
supabase migration new route_optimization_tables
```

#### **Step 1.2: Implement Batch Management Tables**
```sql
-- supabase/migrations/025_multi_order_batch_system.sql
-- Core delivery batch management
CREATE TABLE delivery_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    batch_number TEXT NOT NULL UNIQUE,
    status batch_status_enum NOT NULL DEFAULT 'planned',
    total_distance_km DECIMAL(8,2),
    estimated_duration_minutes INTEGER,
    optimization_score DECIMAL(5,2),
    max_orders INTEGER DEFAULT 3,
    max_deviation_km DECIMAL(6,2) DEFAULT 5.0,
    planned_start_time TIMESTAMPTZ,
    actual_start_time TIMESTAMPTZ,
    estimated_completion_time TIMESTAMPTZ,
    actual_completion_time TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Batch status enum
CREATE TYPE batch_status_enum AS ENUM (
    'planned', 'optimized', 'active', 'paused', 'completed', 'cancelled', 'split'
);

-- Batch orders association
CREATE TABLE batch_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID NOT NULL REFERENCES delivery_batches(id) ON DELETE CASCADE,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    pickup_sequence INTEGER NOT NULL,
    delivery_sequence INTEGER NOT NULL,
    estimated_pickup_time TIMESTAMPTZ,
    estimated_delivery_time TIMESTAMPTZ,
    actual_pickup_time TIMESTAMPTZ,
    actual_delivery_time TIMESTAMPTZ,
    distance_from_previous_km DECIMAL(6,2),
    travel_time_from_previous_minutes INTEGER,
    pickup_status order_pickup_status DEFAULT 'pending',
    delivery_status order_delivery_status DEFAULT 'pending',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(batch_id, order_id),
    UNIQUE(batch_id, pickup_sequence),
    UNIQUE(batch_id, delivery_sequence)
);

-- Apply migration
supabase db push
```

#### **Step 1.3: Set Up RLS Policies**
```sql
-- Enable RLS
ALTER TABLE delivery_batches ENABLE ROW LEVEL SECURITY;
ALTER TABLE batch_orders ENABLE ROW LEVEL SECURITY;

-- Driver access policies
CREATE POLICY "Drivers can view their own batches" ON delivery_batches
    FOR SELECT USING (driver_id = auth.uid()::uuid);

CREATE POLICY "Drivers can update their own batches" ON delivery_batches
    FOR UPDATE USING (driver_id = auth.uid()::uuid);

-- Batch orders policies
CREATE POLICY "Drivers can view batch orders for their batches" ON batch_orders
    FOR SELECT USING (
        batch_id IN (
            SELECT id FROM delivery_batches WHERE driver_id = auth.uid()::uuid
        )
    );
```

#### **Step 1.4: Enable Real-Time Subscriptions**
```sql
-- Enable real-time replication
ALTER TABLE delivery_batches REPLICA IDENTITY FULL;
ALTER TABLE batch_orders REPLICA IDENTITY FULL;

-- Create publication
CREATE PUBLICATION batch_delivery_updates FOR TABLE 
    delivery_batches, batch_orders, orders;
```

### **Week 2: Enhanced Location Service**

#### **Step 2.1: Create Enhanced Location Service**
```dart
// lib/src/features/drivers/data/services/enhanced_location_service.dart
class EnhancedLocationService {
  final SupabaseClient _supabase;
  final GeofencingService _geofencingService;
  
  StreamSubscription<Position>? _locationSubscription;
  Timer? _locationUpdateTimer;
  bool _isTracking = false;
  
  /// Start enhanced location tracking with geofencing
  Future<bool> startEnhancedLocationTracking({
    required String driverId,
    String? batchId,
    List<Geofence>? geofences,
    int intervalSeconds = 15,
  }) async {
    try {
      debugPrint('🚗 [ENHANCED-LOCATION] Starting enhanced tracking for driver: $driverId');
      
      // Check permissions
      if (!await _checkLocationPermissions()) {
        throw Exception('Location permissions not granted');
      }
      
      // Stop any existing tracking
      await stopLocationTracking();
      
      // Set up geofences if provided
      if (geofences != null && geofences.isNotEmpty) {
        await _geofencingService.setupGeofences(geofences);
      }
      
      _isTracking = true;
      
      // Start high-accuracy location stream
      _locationSubscription = Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 5, // Update every 5 meters
        ),
      ).listen(
        (position) => _handleLocationUpdate(driverId, batchId, position),
        onError: (error) => debugPrint('🚗 [ENHANCED-LOCATION] Stream error: $error'),
      );
      
      // Start periodic updates for reliability
      _locationUpdateTimer = Timer.periodic(
        Duration(seconds: intervalSeconds),
        (timer) => _updateLocationPeriodically(driverId, batchId),
      );
      
      debugPrint('🚗 [ENHANCED-LOCATION] Enhanced tracking started successfully');
      return true;
    } catch (e) {
      debugPrint('🚗 [ENHANCED-LOCATION] Error starting tracking: $e');
      return false;
    }
  }
  
  /// Handle real-time location updates
  Future<void> _handleLocationUpdate(
    String driverId,
    String? batchId,
    Position position,
  ) async {
    if (!_isTracking) return;
    
    try {
      // Save to enhanced tracking table
      await _supabase.from('driver_location_tracking').insert({
        'driver_id': driverId,
        'batch_id': batchId,
        'latitude': position.latitude,
        'longitude': position.longitude,
        'accuracy_meters': position.accuracy,
        'bearing_degrees': position.heading,
        'speed_kmh': position.speed * 3.6, // Convert m/s to km/h
        'device_timestamp': position.timestamp.toIso8601String(),
        'recorded_at': DateTime.now().toIso8601String(),
      });
      
      // Update driver's last known location
      await _supabase.from('drivers').update({
        'last_location': 'POINT(${position.longitude} ${position.latitude})',
        'last_seen': DateTime.now().toIso8601String(),
      }).eq('id', driverId);
      
    } catch (e) {
      debugPrint('🚗 [ENHANCED-LOCATION] Error saving location: $e');
    }
  }
}
```

#### **Step 2.2: Implement Geofencing Service**
```dart
// lib/src/features/drivers/data/services/geofencing_service.dart
class GeofencingService {
  final List<Geofence> _activeGeofences = [];
  final StreamController<GeofenceEvent> _eventController = StreamController.broadcast();
  
  Stream<GeofenceEvent> get eventStream => _eventController.stream;
  
  /// Set up geofences for automatic status transitions
  Future<void> setupGeofences(List<Geofence> geofences) async {
    debugPrint('🎯 [GEOFENCING] Setting up ${geofences.length} geofences');
    
    _activeGeofences.clear();
    _activeGeofences.addAll(geofences);
    
    // Log geofence setup for debugging
    for (final geofence in geofences) {
      debugPrint('🎯 [GEOFENCING] Geofence: ${geofence.id} at ${geofence.center} (${geofence.radius}m)');
    }
  }
  
  /// Check if position is within any geofence
  void checkGeofences(Position position) {
    for (final geofence in _activeGeofences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.center.latitude,
        geofence.center.longitude,
      );
      
      if (distance <= geofence.radius) {
        debugPrint('🎯 [GEOFENCING] Entered geofence: ${geofence.id}');
        
        _eventController.add(GeofenceEvent(
          geofenceId: geofence.id,
          type: GeofenceEventType.enter,
          position: position,
          timestamp: DateTime.now(),
        ));
      }
    }
  }
}
```

### **Week 3: Core Navigation Service Enhancement**

#### **Step 3.1: Create Enhanced Navigation Service**
```dart
// lib/src/features/drivers/data/services/enhanced_navigation_service.dart
class EnhancedNavigationService {
  final GoogleMapsService _mapsService;
  final VoiceNavigationService _voiceService;
  final GeofencingService _geofencingService;
  
  /// Start comprehensive in-app navigation
  Future<NavigationSession> startInAppNavigation({
    required LatLng origin,
    required LatLng destination,
    required String orderId,
    String? batchId,
    NavigationPreferences? preferences,
  }) async {
    debugPrint('🧭 [NAVIGATION] Starting in-app navigation for order: $orderId');
    
    try {
      // Calculate optimal route with traffic
      final route = await _mapsService.calculateRoute(
        origin: origin,
        destination: destination,
        includeTraffic: true,
        includeAlternatives: true,
      );
      
      // Set up destination geofence
      await _geofencingService.setupGeofences([
        Geofence(
          id: 'destination_$orderId',
          center: destination,
          radius: 50, // 50 meters
          events: [GeofenceEventType.enter],
        ),
      ]);
      
      // Initialize voice guidance
      await _voiceService.initialize(
        language: preferences?.language ?? 'en-MY',
      );
      
      // Create navigation session
      final session = NavigationSession(
        id: _generateSessionId(),
        orderId: orderId,
        batchId: batchId,
        route: route,
        startTime: DateTime.now(),
        preferences: preferences ?? NavigationPreferences.defaults(),
      );
      
      debugPrint('🧭 [NAVIGATION] Navigation session created: ${session.id}');
      return session;
      
    } catch (e) {
      debugPrint('🧭 [NAVIGATION] Error starting navigation: $e');
      rethrow;
    }
  }
}
```

## 🔧 Phase 2: Multi-Order Batch System (Weeks 4-7)

### **Week 4-5: Batch Management Backend**

#### **Step 4.1: Create Multi-Order Batch Service**
```dart
// lib/src/features/drivers/data/services/multi_order_batch_service.dart
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
    debugPrint('🚛 [BATCH] Creating batch for driver: $driverId with ${orderIds.length} orders');
    
    try {
      // 1. Validate orders are eligible for batching
      final orders = await _validateOrdersForBatching(orderIds, maxDeviationKm);
      debugPrint('🚛 [BATCH] Orders validated successfully');
      
      // 2. Check driver capacity
      await _validateDriverCapacity(driverId, orders.length);
      debugPrint('🚛 [BATCH] Driver capacity validated');
      
      // 3. Get preparation time predictions
      final preparationWindows = await _preparationService
          .predictPreparationTimes(orders);
      debugPrint('🚛 [BATCH] Preparation times predicted');
      
      // 4. Calculate optimal route
      final optimizedRoute = await _routeEngine.calculateOptimalRoute(
        orders: orders,
        driverLocation: await _getDriverLocation(driverId),
        preparationWindows: preparationWindows,
      );
      debugPrint('🚛 [BATCH] Route optimized: ${optimizedRoute.totalDistance}m');
      
      // 5. Create batch in database
      final batch = await _createBatchInDatabase(
        driverId: driverId,
        orders: orders,
        route: optimizedRoute,
        maxOrders: maxOrders,
        maxDeviationKm: maxDeviationKm,
      );
      
      debugPrint('🚛 [BATCH] Batch created successfully: ${batch.id}');
      return batch;
      
    } catch (e) {
      debugPrint('🚛 [BATCH] Error creating batch: $e');
      rethrow;
    }
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
    
    return orders.map((order) => BatchedOrder.fromOrder(order)).toList();
  }
}
```

#### **Step 4.2: Create Supabase Edge Functions**
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
    
    console.log(`Creating batch for driver ${driver_id} with orders:`, order_ids);
    
    // Initialize Supabase client
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    );
    
    // Validate orders are eligible for batching
    const { data: orders, error: ordersError } = await supabase
      .from('orders')
      .select('*')
      .in('id', order_ids)
      .eq('status', 'ready')
      .is('assigned_driver_id', null);
    
    if (ordersError) throw ordersError;
    if (!orders || orders.length !== order_ids.length) {
      throw new Error('Some orders are not eligible for batching');
    }
    
    // Create batch
    const { data: batch, error: batchError } = await supabase
      .from('delivery_batches')
      .insert({
        driver_id,
        batch_number: `B${Date.now()}`,
        status: 'planned',
        max_orders,
        max_deviation_km,
      })
      .select()
      .single();
    
    if (batchError) throw batchError;
    
    // Add orders to batch
    const batchOrders = order_ids.map((orderId, index) => ({
      batch_id: batch.id,
      order_id: orderId,
      pickup_sequence: index + 1,
      delivery_sequence: index + 1,
    }));
    
    const { error: batchOrdersError } = await supabase
      .from('batch_orders')
      .insert(batchOrders);
    
    if (batchOrdersError) throw batchOrdersError;
    
    // Update orders with batch assignment
    const { error: updateError } = await supabase
      .from('orders')
      .update({ 
        assigned_driver_id: driver_id,
        batch_id: batch.id,
        status: 'assigned'
      })
      .in('id', order_ids);
    
    if (updateError) throw updateError;
    
    console.log(`Batch created successfully: ${batch.id}`);
    
    return new Response(JSON.stringify({ 
      success: true, 
      batch_id: batch.id,
      message: `Batch created with ${order_ids.length} orders`
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 200,
    });
    
  } catch (error) {
    console.error('Error creating batch:', error);
    return new Response(JSON.stringify({ 
      error: error.message 
    }), {
      headers: { 'Content-Type': 'application/json' },
      status: 400,
    });
  }
});
```

### **Week 6-7: Route Optimization Implementation**

#### **Step 6.1: Implement Route Optimization Engine**
```dart
// lib/src/features/drivers/data/services/route_optimization_engine.dart
class RouteOptimizationEngine {
  final GoogleMapsService _mapsService;
  final TrafficService _trafficService;
  
  /// Calculate optimal route using TSP algorithm
  Future<OptimizedRoute> calculateOptimalRoute({
    required List<BatchedOrder> orders,
    required LatLng driverLocation,
    required Map<String, PreparationWindow> preparationWindows,
    OptimizationCriteria? criteria,
  }) async {
    debugPrint('🔄 [OPTIMIZATION] Starting route optimization for ${orders.length} orders');
    
    criteria ??= OptimizationCriteria.balanced();
    
    try {
      // 1. Calculate distance matrix
      final distanceMatrix = await _calculateDistanceMatrix(orders, driverLocation);
      debugPrint('🔄 [OPTIMIZATION] Distance matrix calculated');
      
      // 2. Get traffic conditions
      final trafficConditions = await _trafficService.getTrafficConditions(orders);
      debugPrint('🔄 [OPTIMIZATION] Traffic conditions retrieved');
      
      // 3. Solve TSP with genetic algorithm
      final optimalSequence = await _solveTSP(
        orders: orders,
        distanceMatrix: distanceMatrix,
        trafficConditions: trafficConditions,
        preparationWindows: preparationWindows,
        criteria: criteria,
      );
      debugPrint('🔄 [OPTIMIZATION] TSP solved, optimal sequence found');
      
      // 4. Generate detailed route
      final detailedRoute = await _generateDetailedRoute(optimalSequence, driverLocation);
      debugPrint('🔄 [OPTIMIZATION] Detailed route generated: ${detailedRoute.totalDistance}m');
      
      return detailedRoute;
      
    } catch (e) {
      debugPrint('🔄 [OPTIMIZATION] Error in route optimization: $e');
      rethrow;
    }
  }
  
  /// Genetic Algorithm TSP Solver
  Future<List<BatchedOrder>> _solveTSP({
    required List<BatchedOrder> orders,
    required DistanceMatrix distanceMatrix,
    required TrafficConditions trafficConditions,
    required Map<String, PreparationWindow> preparationWindows,
    required OptimizationCriteria criteria,
  }) async {
    const populationSize = 50;
    const maxGenerations = 100;
    const mutationRate = 0.1;
    
    // Initialize population with random routes
    List<List<BatchedOrder>> population = _generateInitialPopulation(orders, populationSize);
    
    for (int generation = 0; generation < maxGenerations; generation++) {
      // Evaluate fitness for each route
      final fitnessScores = await Future.wait(
        population.map((route) => _calculateRouteFitness(
          route, distanceMatrix, trafficConditions, preparationWindows, criteria
        ))
      );
      
      // Selection, crossover, and mutation
      population = _evolvePopulation(population, fitnessScores, mutationRate);
      
      // Early termination if convergence
      if (generation % 10 == 0) {
        final bestFitness = fitnessScores.reduce((a, b) => a > b ? a : b);
        debugPrint('🔄 [TSP] Generation $generation, best fitness: ${bestFitness.toStringAsFixed(2)}');
        
        if (_hasConverged(fitnessScores)) {
          debugPrint('🔄 [TSP] Converged at generation $generation');
          break;
        }
      }
    }
    
    // Return best route
    final finalFitnessScores = await Future.wait(
      population.map((route) => _calculateRouteFitness(
        route, distanceMatrix, trafficConditions, preparationWindows, criteria
      ))
    );
    
    final bestRouteIndex = _findBestRouteIndex(finalFitnessScores);
    return population[bestRouteIndex];
  }
}
```

## 🧪 Testing Procedures

### **Android Emulator Testing Setup**
```bash
# Start Android emulator
emulator -avd Pixel_7_API_34 -no-snapshot-load

# Run app with debugging
flutter run --debug --target-platform android-x64

# Enable location simulation
adb emu geo fix 101.6869 3.1390  # KL coordinates
```

### **Integration Testing**
```dart
// integration_test/multi_order_workflow_test.dart
void main() {
  group('Multi-Order Workflow Integration Tests', () {
    testWidgets('Complete batch delivery workflow', (tester) async {
      // Initialize app
      app.main();
      await tester.pumpAndSettle();
      
      // Login as driver
      await _loginAsDriver(tester);
      
      // Create batch with 3 orders
      await _createBatch(tester, orderCount: 3);
      
      // Verify batch creation
      expect(find.text('Batch #'), findsOneWidget);
      expect(find.text('3 orders'), findsOneWidget);
      
      // Start batch execution
      await tester.tap(find.text('Start Batch'));
      await tester.pumpAndSettle();
      
      // Verify navigation started
      expect(find.byType(GoogleMap), findsOneWidget);
      
      // Simulate order pickup workflow
      for (int i = 0; i < 3; i++) {
        await _simulateOrderPickup(tester, i);
        await _simulateOrderDelivery(tester, i);
      }
      
      // Verify batch completion
      expect(find.text('Batch Completed'), findsOneWidget);
    });
  });
}
```

### **Validation Checkpoints**

#### **Phase 1 Validation**
- [ ] Database migrations applied successfully
- [ ] RLS policies working correctly
- [ ] Real-time subscriptions functioning
- [ ] Enhanced location tracking active
- [ ] Geofencing triggers status updates
- [ ] Voice navigation works in all languages

#### **Phase 2 Validation**
- [ ] Batch creation validates order compatibility
- [ ] Route optimization produces efficient routes
- [ ] TSP algorithm completes within time limits
- [ ] Edge functions handle batch operations
- [ ] Preparation time predictions are accurate
- [ ] Dynamic route adaptation works correctly

#### **Phase 3 Validation**
- [ ] Multi-order dashboard displays correctly
- [ ] Route visualization shows all waypoints
- [ ] Drag-and-drop reordering functions
- [ ] Customer communication sends notifications
- [ ] Real-time progress updates work
- [ ] UI components follow Material Design 3

This development guide provides comprehensive implementation instructions with code examples, testing procedures, and validation checkpoints to ensure successful delivery of the GigaEats Driver Workflow Enhancement project.
