# Route Optimization System API Documentation

## 🎯 Overview

This document provides comprehensive API documentation for the GigaEats Multi-Order Route Optimization System, including Edge Functions, database schemas, real-time subscriptions, and integration points.

## 📋 Table of Contents

- [Edge Functions API](#edge-functions-api)
- [Database Schema](#database-schema)
- [Real-time Subscriptions](#real-time-subscriptions)
- [Integration Points](#integration-points)
- [Authentication & Security](#authentication--security)
- [Error Handling](#error-handling)
- [Rate Limiting](#rate-limiting)

## 🚀 Edge Functions API

### Base URL
```
https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/
```

### Authentication
All Edge Functions require authentication via Bearer token:
```
Authorization: Bearer YOUR_ACCESS_TOKEN
```

---

## 1. Create Delivery Batch

**Endpoint:** `POST /create-delivery-batch`

Creates a new delivery batch with intelligent order grouping and driver assignment.

### Request Body
```json
{
  "orders": [
    {
      "orderId": "string",
      "vendorId": "string",
      "customerId": "string",
      "deliveryAddress": {
        "latitude": "number",
        "longitude": "number",
        "address": "string"
      },
      "vendorAddress": {
        "latitude": "number",
        "longitude": "number",
        "address": "string"
      },
      "estimatedPreparationTime": "number", // minutes
      "priority": "string", // "normal" | "high" | "urgent"
      "deliveryWindow": {
        "start": "string", // ISO 8601
        "end": "string"   // ISO 8601
      }
    }
  ],
  "driverLocation": {
    "latitude": "number",
    "longitude": "number"
  },
  "maxOrders": "number", // optional, default: 3
  "maxDeviationKm": "number", // optional, default: 5.0
  "algorithm": "string" // optional, "nearest_neighbor" | "genetic_algorithm" | "simulated_annealing"
}
```

### Response
```json
{
  "success": true,
  "batchId": "string",
  "assignedDriverId": "string",
  "orders": [
    {
      "orderId": "string",
      "sequenceNumber": "number",
      "estimatedPickupTime": "string", // ISO 8601
      "estimatedDeliveryTime": "string" // ISO 8601
    }
  ],
  "optimizedRoute": {
    "totalDistanceMeters": "number",
    "estimatedDurationSeconds": "number",
    "optimizationScore": "number",
    "waypoints": [
      {
        "type": "string", // "pickup" | "delivery"
        "orderId": "string",
        "location": {
          "latitude": "number",
          "longitude": "number"
        },
        "estimatedArrivalTime": "string" // ISO 8601
      }
    ]
  },
  "metadata": {
    "algorithm": "string",
    "calculationTimeMs": "number",
    "createdAt": "string" // ISO 8601
  }
}
```

### Error Responses
```json
{
  "success": false,
  "error": "string",
  "code": "string", // "INVALID_INPUT" | "NO_AVAILABLE_DRIVER" | "OPTIMIZATION_FAILED"
  "details": "object" // optional
}
```

---

## 2. Optimize Delivery Route

**Endpoint:** `POST /optimize-delivery-route`

Optimizes an existing delivery route using advanced TSP algorithms.

### Request Body
```json
{
  "batchId": "string",
  "driverLocation": {
    "latitude": "number",
    "longitude": "number"
  },
  "algorithm": "string", // optional
  "constraints": {
    "maxCalculationTimeMs": "number", // optional, default: 5000
    "minOptimizationScore": "number", // optional, default: 70.0
    "considerTraffic": "boolean", // optional, default: true
    "considerPreparationTimes": "boolean" // optional, default: true
  }
}
```

### Response
```json
{
  "success": true,
  "batchId": "string",
  "optimizedRoute": {
    "totalDistanceMeters": "number",
    "estimatedDurationSeconds": "number",
    "optimizationScore": "number",
    "improvementOverPrevious": "number", // percentage
    "waypoints": [
      {
        "type": "string",
        "orderId": "string",
        "location": {
          "latitude": "number",
          "longitude": "number"
        },
        "estimatedArrivalTime": "string",
        "sequenceNumber": "number"
      }
    ]
  },
  "performance": {
    "algorithm": "string",
    "calculationTimeMs": "number",
    "convergenceAchieved": "boolean",
    "iterations": "number"
  }
}
```

---

## 3. Manage Delivery Batch

**Endpoint:** `POST /manage-delivery-batch`

Manages delivery batch operations including status updates, order modifications, and driver reassignment.

### Request Body
```json
{
  "batchId": "string",
  "action": "string", // "update_status" | "add_order" | "remove_order" | "reassign_driver"
  "data": {
    // Action-specific data
    "status": "string", // for update_status: "active" | "completed" | "cancelled"
    "orderId": "string", // for add_order/remove_order
    "newDriverId": "string", // for reassign_driver
    "reason": "string" // optional
  }
}
```

### Response
```json
{
  "success": true,
  "batchId": "string",
  "action": "string",
  "result": {
    "status": "string",
    "orderCount": "number",
    "assignedDriverId": "string",
    "updatedAt": "string" // ISO 8601
  }
}
```

---

## 📊 Database Schema

### Core Tables

#### `delivery_batches`
```sql
CREATE TABLE delivery_batches (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES drivers(id),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    total_orders INTEGER NOT NULL DEFAULT 0,
    optimization_score DECIMAL(5,2),
    total_distance_meters INTEGER,
    estimated_duration_seconds INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    cancelled_at TIMESTAMP WITH TIME ZONE,
    cancellation_reason TEXT
);
```

#### `driver_batch_orders`
```sql
CREATE TABLE driver_batch_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES delivery_batches(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    sequence_number INTEGER NOT NULL,
    pickup_sequence INTEGER,
    delivery_sequence INTEGER,
    estimated_pickup_time TIMESTAMP WITH TIME ZONE,
    estimated_delivery_time TIMESTAMP WITH TIME ZONE,
    actual_pickup_time TIMESTAMP WITH TIME ZONE,
    actual_delivery_time TIMESTAMP WITH TIME ZONE,
    status VARCHAR(20) DEFAULT 'pending'
);
```

#### `route_optimizations`
```sql
CREATE TABLE route_optimizations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES delivery_batches(id) ON DELETE CASCADE,
    algorithm_used VARCHAR(50) NOT NULL,
    optimization_score DECIMAL(5,2) NOT NULL,
    total_distance_meters INTEGER NOT NULL,
    estimated_duration_seconds INTEGER NOT NULL,
    calculation_time_ms INTEGER NOT NULL,
    improvement_over_baseline_percent DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

#### `batch_waypoints`
```sql
CREATE TABLE batch_waypoints (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES delivery_batches(id) ON DELETE CASCADE,
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    waypoint_type VARCHAR(20) NOT NULL, -- 'pickup' or 'delivery'
    sequence_number INTEGER NOT NULL,
    latitude DECIMAL(10,8) NOT NULL,
    longitude DECIMAL(11,8) NOT NULL,
    estimated_arrival_time TIMESTAMP WITH TIME ZONE,
    actual_arrival_time TIMESTAMP WITH TIME ZONE,
    address TEXT
);
```

### Performance Monitoring Tables

#### `tsp_performance_metrics`
```sql
CREATE TABLE tsp_performance_metrics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    batch_id UUID REFERENCES delivery_batches(id),
    algorithm_used VARCHAR(50) NOT NULL,
    calculation_time_ms INTEGER NOT NULL,
    optimization_score DECIMAL(5,2) NOT NULL,
    convergence_achieved BOOLEAN DEFAULT false,
    iterations INTEGER,
    memory_usage_mb DECIMAL(8,2),
    route_quality_score DECIMAL(5,2),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);
```

### Feature Management Tables

#### `feature_flags`
```sql
CREATE TABLE feature_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    feature_group VARCHAR(100) NOT NULL,
    flag_key VARCHAR(100) NOT NULL,
    flag_value TEXT NOT NULL,
    value_type VARCHAR(20) NOT NULL DEFAULT 'string',
    description TEXT,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(feature_group, flag_key)
);
```

#### `beta_testing_drivers`
```sql
CREATE TABLE beta_testing_drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    program_name VARCHAR(100) NOT NULL DEFAULT 'route_optimization',
    enrolled_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    status VARCHAR(20) NOT NULL DEFAULT 'active',
    feedback_count INTEGER DEFAULT 0,
    performance_score DECIMAL(5,2),
    notes TEXT,
    UNIQUE(driver_id, program_name)
);
```

---

## 🔄 Real-time Subscriptions

### Batch Status Updates
```javascript
const batchSubscription = supabase
  .channel('batch_updates')
  .on('postgres_changes', {
    event: '*',
    schema: 'public',
    table: 'delivery_batches',
    filter: `driver_id=eq.${driverId}`
  }, (payload) => {
    console.log('Batch update:', payload);
  })
  .subscribe();
```

### Route Optimization Updates
```javascript
const routeSubscription = supabase
  .channel('route_updates')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'route_optimizations'
  }, (payload) => {
    console.log('New route optimization:', payload);
  })
  .subscribe();
```

### Performance Metrics Updates
```javascript
const metricsSubscription = supabase
  .channel('performance_metrics')
  .on('postgres_changes', {
    event: 'INSERT',
    schema: 'public',
    table: 'tsp_performance_metrics'
  }, (payload) => {
    console.log('Performance metrics:', payload);
  })
  .subscribe();
```

---

## 🔗 Integration Points

### Flutter Application Integration

#### Multi-Order Batch Service
```dart
class MultiOrderBatchService {
  Future<BatchCreationResult> createBatch(List<Order> orders) async {
    final response = await _supabase.functions.invoke(
      'create-delivery-batch',
      body: {
        'orders': orders.map((o) => o.toJson()).toList(),
        'driverLocation': await _getCurrentLocation(),
      },
    );
    
    return BatchCreationResult.fromJson(response.data);
  }
}
```

#### Route Optimization Provider
```dart
class RouteOptimizationProvider extends StateNotifier<RouteOptimizationState> {
  Future<void> optimizeRoute(String batchId) async {
    state = state.copyWith(isOptimizing: true);
    
    try {
      final response = await _supabase.functions.invoke(
        'optimize-delivery-route',
        body: {'batchId': batchId},
      );
      
      state = state.copyWith(
        optimizedRoute: OptimizedRoute.fromJson(response.data),
        isOptimizing: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isOptimizing: false);
    }
  }
}
```

### Google Maps Integration
```dart
class GoogleMapsService {
  Future<List<LatLng>> getOptimizedWaypoints(List<Waypoint> waypoints) async {
    // Integration with Google Maps Directions API
    // for real-time traffic and route optimization
  }
}
```

---

## 🔐 Authentication & Security

### Row Level Security (RLS) Policies

#### Delivery Batches
```sql
-- Drivers can only access their own batches
CREATE POLICY "Drivers can access own batches" ON delivery_batches
    FOR ALL TO authenticated
    USING (driver_id = (SELECT id FROM drivers WHERE user_id = auth.uid()));

-- Admin users can access all batches
CREATE POLICY "Admin users can access all batches" ON delivery_batches
    FOR ALL TO authenticated
    USING (
        EXISTS (
            SELECT 1 FROM user_profiles 
            WHERE user_profiles.user_id = auth.uid() 
            AND user_profiles.role = 'Admin'
        )
    );
```

### API Security
- All Edge Functions require valid JWT tokens
- Rate limiting: 100 requests per minute per user
- Input validation and sanitization
- SQL injection prevention through parameterized queries
- CORS configuration for allowed origins

---

## ⚠️ Error Handling

### Standard Error Response Format
```json
{
  "success": false,
  "error": "Human-readable error message",
  "code": "MACHINE_READABLE_ERROR_CODE",
  "details": {
    "field": "specific field that caused the error",
    "value": "invalid value",
    "expected": "expected format or value"
  },
  "timestamp": "2024-12-22T10:30:00Z",
  "requestId": "unique-request-identifier"
}
```

### Common Error Codes
- `INVALID_INPUT`: Request validation failed
- `UNAUTHORIZED`: Authentication required or invalid
- `FORBIDDEN`: Insufficient permissions
- `NOT_FOUND`: Resource not found
- `OPTIMIZATION_FAILED`: Route optimization algorithm failed
- `NO_AVAILABLE_DRIVER`: No drivers available for assignment
- `BATCH_LIMIT_EXCEEDED`: Maximum batch size exceeded
- `CALCULATION_TIMEOUT`: Optimization calculation timed out
- `SYSTEM_OVERLOAD`: System temporarily unavailable

---

## 📈 Rate Limiting

### Limits by Endpoint
- `create-delivery-batch`: 10 requests per minute
- `optimize-delivery-route`: 20 requests per minute
- `manage-delivery-batch`: 50 requests per minute

### Rate Limit Headers
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1640181600
```

### Rate Limit Exceeded Response
```json
{
  "success": false,
  "error": "Rate limit exceeded",
  "code": "RATE_LIMIT_EXCEEDED",
  "details": {
    "limit": 100,
    "remaining": 0,
    "resetTime": "2024-12-22T10:35:00Z"
  }
}
```

---

## 📞 Support & Contact

For API support and technical questions:
- **Email**: api-support@gigaeats.com
- **Documentation**: https://docs.gigaeats.com/api
- **Status Page**: https://status.gigaeats.com
- **GitHub Issues**: https://github.com/gigaeats/route-optimization/issues

---

*Last Updated: December 22, 2024*
*API Version: 1.0.0*
