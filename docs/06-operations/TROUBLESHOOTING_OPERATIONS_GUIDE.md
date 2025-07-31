# Route Optimization System - Troubleshooting & Operations Guide

## 🎯 Overview

This guide provides comprehensive troubleshooting procedures, debugging techniques, performance optimization strategies, and operational maintenance tasks for the GigaEats Multi-Order Route Optimization System.

## 📋 Table of Contents

- [Common Issues & Solutions](#common-issues--solutions)
- [Debugging Procedures](#debugging-procedures)
- [Performance Optimization](#performance-optimization)
- [Monitoring & Alerting](#monitoring--alerting)
- [Emergency Procedures](#emergency-procedures)
- [Maintenance Tasks](#maintenance-tasks)
- [System Health Checks](#system-health-checks)

---

## 🚨 Common Issues & Solutions

### 1. Route Optimization Failures

#### **Issue**: TSP Algorithm Timeout
**Symptoms**: 
- Edge Function returns `CALCULATION_TIMEOUT` error
- Optimization takes longer than 5 seconds
- High CPU usage on Edge Functions

**Diagnosis**:
```sql
-- Check recent optimization performance
SELECT 
    algorithm_used,
    AVG(calculation_time_ms) as avg_time,
    COUNT(*) as attempts,
    COUNT(*) FILTER (WHERE calculation_time_ms > 5000) as timeouts
FROM tsp_performance_metrics 
WHERE created_at >= NOW() - INTERVAL '1 hour'
GROUP BY algorithm_used;
```

**Solutions**:
1. **Immediate**: Switch to faster algorithm
   ```sql
   UPDATE feature_flags 
   SET flag_value = 'nearest_neighbor' 
   WHERE flag_key = 'default_tsp_algorithm';
   ```

2. **Short-term**: Reduce batch size
   ```sql
   UPDATE feature_flags 
   SET flag_value = '2' 
   WHERE flag_key = 'max_batch_orders';
   ```

3. **Long-term**: Optimize algorithm parameters
   - Reduce genetic algorithm population size
   - Decrease simulated annealing iterations
   - Implement early convergence detection

#### **Issue**: No Available Drivers
**Symptoms**:
- `NO_AVAILABLE_DRIVER` error in batch creation
- Orders remain unassigned
- Driver utilization appears low

**Diagnosis**:
```sql
-- Check driver availability
SELECT 
    status,
    COUNT(*) as driver_count,
    COUNT(*) FILTER (WHERE last_location_update > NOW() - INTERVAL '10 minutes') as active_recently
FROM drivers 
GROUP BY status;

-- Check current batch assignments
SELECT 
    d.id,
    d.status,
    COUNT(db.id) as active_batches
FROM drivers d
LEFT JOIN delivery_batches db ON d.id = db.driver_id AND db.status = 'active'
GROUP BY d.id, d.status
HAVING COUNT(db.id) > 0;
```

**Solutions**:
1. **Check driver status filters**:
   ```dart
   // Verify driver availability query
   final availableDrivers = await supabase
       .from('drivers')
       .select('*')
       .eq('status', 'online')
       .is_('current_batch_id', null);
   ```

2. **Expand search radius**:
   ```sql
   UPDATE feature_flags 
   SET flag_value = '10.0' 
   WHERE flag_key = 'max_deviation_km';
   ```

3. **Review driver assignment logic**:
   - Check location update frequency
   - Verify driver status transitions
   - Review batch capacity limits

### 2. Database Performance Issues

#### **Issue**: Slow Route Optimization Queries
**Symptoms**:
- Database query timeouts
- High database CPU usage
- Slow batch creation

**Diagnosis**:
```sql
-- Check slow queries
SELECT 
    query,
    mean_exec_time,
    calls,
    total_exec_time
FROM pg_stat_statements 
WHERE query LIKE '%delivery_batches%' OR query LIKE '%route_optimization%'
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Check index usage
SELECT 
    schemaname,
    tablename,
    indexname,
    idx_scan,
    idx_tup_read,
    idx_tup_fetch
FROM pg_stat_user_indexes 
WHERE tablename IN ('delivery_batches', 'driver_batch_orders', 'route_optimizations')
ORDER BY idx_scan DESC;
```

**Solutions**:
1. **Add missing indexes**:
   ```sql
   -- Common performance indexes
   CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_delivery_batches_driver_status 
   ON delivery_batches(driver_id, status);
   
   CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_driver_batch_orders_batch_sequence 
   ON driver_batch_orders(batch_id, sequence_number);
   
   CREATE INDEX CONCURRENTLY IF NOT EXISTS idx_route_optimizations_created_at 
   ON route_optimizations(created_at DESC);
   ```

2. **Optimize queries**:
   ```sql
   -- Use EXPLAIN ANALYZE to identify bottlenecks
   EXPLAIN ANALYZE 
   SELECT * FROM delivery_batches 
   WHERE driver_id = $1 AND status = 'active';
   ```

3. **Update table statistics**:
   ```sql
   ANALYZE delivery_batches;
   ANALYZE driver_batch_orders;
   ANALYZE route_optimizations;
   ```

### 3. Real-time Subscription Issues

#### **Issue**: Missed Real-time Updates
**Symptoms**:
- UI not updating with batch status changes
- Drivers not receiving route updates
- Stale data in mobile app

**Diagnosis**:
```javascript
// Check subscription status
const channel = supabase.channel('batch_updates');
console.log('Channel status:', channel.state);

// Monitor connection health
supabase.realtime.onOpen(() => console.log('Realtime connected'));
supabase.realtime.onClose(() => console.log('Realtime disconnected'));
supabase.realtime.onError((error) => console.error('Realtime error:', error));
```

**Solutions**:
1. **Reconnect subscriptions**:
   ```dart
   // Implement reconnection logic
   void _handleRealtimeReconnection() {
     _subscription?.unsubscribe();
     _subscription = _supabase
         .channel('batch_updates')
         .onPostgresChanges(
           event: PostgresChangeEvent.all,
           schema: 'public',
           table: 'delivery_batches',
           callback: _handleBatchUpdate,
         )
         .subscribe();
   }
   ```

2. **Check RLS policies**:
   ```sql
   -- Verify user can access data
   SELECT * FROM delivery_batches 
   WHERE driver_id = (SELECT id FROM drivers WHERE user_id = auth.uid());
   ```

3. **Implement fallback polling**:
   ```dart
   // Fallback to periodic polling if realtime fails
   Timer.periodic(Duration(seconds: 30), (timer) {
     if (!_realtimeConnected) {
       _fetchBatchUpdates();
     }
   });
   ```

---

## 🔍 Debugging Procedures

### 1. Edge Function Debugging

#### Enable Debug Logging
```typescript
// In Edge Function code
console.log('DEBUG: Function invoked with:', JSON.stringify(req.body));
console.log('DEBUG: User ID:', user?.id);
console.log('DEBUG: Processing batch creation...');
```

#### Check Function Logs
```bash
# View Edge Function logs
supabase functions logs create-delivery-batch --follow

# Filter by error level
supabase functions logs create-delivery-batch --level error
```

#### Test Edge Functions Locally
```bash
# Start local development
supabase functions serve create-delivery-batch --debug

# Test with curl
curl -X POST http://localhost:54321/functions/v1/create-delivery-batch \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"orders": [...], "driverLocation": {...}}'
```

### 2. Database Query Debugging

#### Enable Query Logging
```sql
-- Enable slow query logging
ALTER SYSTEM SET log_min_duration_statement = 1000; -- Log queries > 1s
SELECT pg_reload_conf();

-- Check current settings
SHOW log_min_duration_statement;
SHOW log_statement;
```

#### Analyze Query Performance
```sql
-- Reset statistics
SELECT pg_stat_reset();

-- Run your queries...

-- Check performance
SELECT 
    query,
    calls,
    total_exec_time,
    mean_exec_time,
    stddev_exec_time,
    rows
FROM pg_stat_statements 
ORDER BY total_exec_time DESC
LIMIT 20;
```

### 3. Flutter Application Debugging

#### Enable Comprehensive Logging
```dart
class DebugLogger {
  static void logBatchCreation(String message, [Object? data]) {
    if (kDebugMode) {
      print('🚛 [BATCH] $message');
      if (data != null) print('   Data: ${jsonEncode(data)}');
    }
  }
  
  static void logRouteOptimization(String message, [Object? data]) {
    if (kDebugMode) {
      print('🗺️ [ROUTE] $message');
      if (data != null) print('   Data: ${jsonEncode(data)}');
    }
  }
}
```

#### Monitor Provider State Changes
```dart
class RouteOptimizationProvider extends StateNotifier<RouteOptimizationState> {
  @override
  set state(RouteOptimizationState newState) {
    DebugLogger.logRouteOptimization(
      'State change: ${state.runtimeType} -> ${newState.runtimeType}',
      {
        'previous': state.toJson(),
        'new': newState.toJson(),
      }
    );
    super.state = newState;
  }
}
```

---

## ⚡ Performance Optimization

### 1. Database Optimization

#### Query Optimization
```sql
-- Optimize batch retrieval
CREATE OR REPLACE VIEW driver_active_batches AS
SELECT 
    db.*,
    COUNT(dbo.id) as order_count,
    AVG(ro.optimization_score) as avg_optimization_score
FROM delivery_batches db
LEFT JOIN driver_batch_orders dbo ON db.id = dbo.batch_id
LEFT JOIN route_optimizations ro ON db.id = ro.batch_id
WHERE db.status = 'active'
GROUP BY db.id;

-- Use materialized view for heavy analytics
CREATE MATERIALIZED VIEW batch_performance_summary AS
SELECT 
    DATE(created_at) as date,
    algorithm_used,
    COUNT(*) as total_optimizations,
    AVG(calculation_time_ms) as avg_calculation_time,
    AVG(optimization_score) as avg_optimization_score,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY calculation_time_ms) as p95_calculation_time
FROM tsp_performance_metrics
GROUP BY DATE(created_at), algorithm_used;

-- Refresh materialized view daily
CREATE OR REPLACE FUNCTION refresh_performance_summary()
RETURNS void AS $$
BEGIN
    REFRESH MATERIALIZED VIEW batch_performance_summary;
END;
$$ LANGUAGE plpgsql;
```

#### Connection Pool Optimization
```sql
-- Optimize connection settings
ALTER SYSTEM SET max_connections = 200;
ALTER SYSTEM SET shared_buffers = '256MB';
ALTER SYSTEM SET effective_cache_size = '1GB';
ALTER SYSTEM SET work_mem = '4MB';
ALTER SYSTEM SET maintenance_work_mem = '64MB';
SELECT pg_reload_conf();
```

### 2. Algorithm Performance Tuning

#### Genetic Algorithm Optimization
```typescript
// Optimized GA parameters
const GA_CONFIG = {
  populationSize: 50,        // Reduced from 100
  maxGenerations: 100,       // Reduced from 200
  mutationRate: 0.1,
  crossoverRate: 0.8,
  elitismRate: 0.1,
  convergenceThreshold: 0.001,
  maxStagnantGenerations: 20  // Early termination
};
```

#### Simulated Annealing Tuning
```typescript
// Optimized SA parameters
const SA_CONFIG = {
  initialTemperature: 1000,
  coolingRate: 0.95,
  minTemperature: 0.1,
  maxIterations: 1000,      // Reduced from 2000
  reheatingThreshold: 50    // Reheat if no improvement
};
```

### 3. Caching Strategies

#### Redis Caching for Route Calculations
```typescript
// Cache route calculations
const cacheKey = `route_${JSON.stringify(waypoints)}`;
const cachedRoute = await redis.get(cacheKey);

if (cachedRoute) {
  return JSON.parse(cachedRoute);
}

const optimizedRoute = await calculateRoute(waypoints);
await redis.setex(cacheKey, 3600, JSON.stringify(optimizedRoute)); // 1 hour cache
```

#### Flutter State Caching
```dart
class CachedRouteOptimizationProvider extends StateNotifier<RouteOptimizationState> {
  final Map<String, OptimizedRoute> _routeCache = {};
  
  Future<OptimizedRoute> getOptimizedRoute(String batchId) async {
    if (_routeCache.containsKey(batchId)) {
      return _routeCache[batchId]!;
    }
    
    final route = await _fetchOptimizedRoute(batchId);
    _routeCache[batchId] = route;
    return route;
  }
}
```

---

## 📊 Monitoring & Alerting

### 1. Key Performance Indicators (KPIs)

#### System Health Metrics
```sql
-- Create monitoring dashboard query
CREATE OR REPLACE FUNCTION get_system_health_metrics()
RETURNS JSON AS $$
DECLARE
    result JSON;
BEGIN
    SELECT json_build_object(
        'batch_creation_rate', (
            SELECT COUNT(*) FROM delivery_batches 
            WHERE created_at >= NOW() - INTERVAL '1 hour'
        ),
        'avg_optimization_time', (
            SELECT AVG(calculation_time_ms) FROM tsp_performance_metrics 
            WHERE created_at >= NOW() - INTERVAL '1 hour'
        ),
        'success_rate', (
            SELECT 
                COUNT(*) FILTER (WHERE optimization_score >= 70) * 100.0 / COUNT(*)
            FROM route_optimizations 
            WHERE created_at >= NOW() - INTERVAL '1 hour'
        ),
        'active_batches', (
            SELECT COUNT(*) FROM delivery_batches WHERE status = 'active'
        ),
        'driver_utilization', (
            SELECT 
                COUNT(*) FILTER (WHERE status = 'busy') * 100.0 / COUNT(*)
            FROM drivers WHERE status IN ('online', 'busy')
        )
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

#### Alert Thresholds
```sql
-- Set up automated alerts
CREATE OR REPLACE FUNCTION check_system_alerts()
RETURNS TABLE(alert_type TEXT, message TEXT, severity TEXT) AS $$
BEGIN
    -- High optimization time alert
    RETURN QUERY
    SELECT 
        'high_optimization_time'::TEXT,
        'Average optimization time exceeded 5 seconds'::TEXT,
        'warning'::TEXT
    WHERE (
        SELECT AVG(calculation_time_ms) FROM tsp_performance_metrics 
        WHERE created_at >= NOW() - INTERVAL '15 minutes'
    ) > 5000;
    
    -- Low success rate alert
    RETURN QUERY
    SELECT 
        'low_success_rate'::TEXT,
        'Optimization success rate below 80%'::TEXT,
        'critical'::TEXT
    WHERE (
        SELECT 
            COUNT(*) FILTER (WHERE optimization_score >= 70) * 100.0 / NULLIF(COUNT(*), 0)
        FROM route_optimizations 
        WHERE created_at >= NOW() - INTERVAL '15 minutes'
    ) < 80;
    
    -- High error rate alert
    RETURN QUERY
    SELECT 
        'high_error_rate'::TEXT,
        'Edge function error rate exceeded 5%'::TEXT,
        'critical'::TEXT
    WHERE (
        SELECT COUNT(*) FROM incidents 
        WHERE created_at >= NOW() - INTERVAL '15 minutes'
        AND type = 'edge_function_error'
    ) > 5;
END;
$$ LANGUAGE plpgsql;
```

### 2. Automated Monitoring

#### Health Check Cron Job
```sql
-- Schedule health checks every 5 minutes
SELECT cron.schedule(
    'system-health-check',
    '*/5 * * * *',
    $$
    INSERT INTO system_health_logs (
        timestamp,
        metrics,
        alerts
    ) VALUES (
        NOW(),
        get_system_health_metrics(),
        (SELECT json_agg(row_to_json(alerts)) FROM check_system_alerts() alerts)
    );
    $$
);
```

---

## 🚨 Emergency Procedures

### 1. System-Wide Rollback

#### Immediate Actions
```bash
# 1. Disable all route optimization features
curl -X POST https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/emergency-disable \
  -H "Authorization: Bearer $ADMIN_TOKEN" \
  -d '{"reason": "System performance degradation"}'

# 2. Check system status
curl -X GET https://abknoalhfltlhhdbclpv.supabase.co/functions/v1/system-status \
  -H "Authorization: Bearer $ADMIN_TOKEN"
```

#### Database Rollback
```sql
-- Cancel all active batches
UPDATE delivery_batches 
SET 
    status = 'cancelled',
    cancellation_reason = 'Emergency system rollback',
    cancelled_at = NOW()
WHERE status = 'active';

-- Disable feature flags
UPDATE feature_flags 
SET flag_value = 'false' 
WHERE feature_group = 'route_optimization' 
AND flag_key LIKE 'enable_%';
```

### 2. Performance Degradation Response

#### Immediate Mitigation
```sql
-- Switch to fastest algorithm
UPDATE feature_flags 
SET flag_value = 'nearest_neighbor' 
WHERE flag_key = 'default_tsp_algorithm';

-- Reduce batch size
UPDATE feature_flags 
SET flag_value = '2' 
WHERE flag_key = 'max_batch_orders';

-- Increase timeout
UPDATE feature_flags 
SET flag_value = '10000' 
WHERE flag_key = 'max_calculation_time_ms';
```

---

## 🔧 Maintenance Tasks

### 1. Daily Maintenance

#### Database Cleanup
```sql
-- Clean up old performance metrics (keep 30 days)
DELETE FROM tsp_performance_metrics 
WHERE created_at < NOW() - INTERVAL '30 days';

-- Clean up resolved incidents (keep 90 days)
DELETE FROM incidents 
WHERE status = 'resolved' 
AND resolved_at < NOW() - INTERVAL '90 days';

-- Update table statistics
ANALYZE delivery_batches;
ANALYZE driver_batch_orders;
ANALYZE route_optimizations;
ANALYZE tsp_performance_metrics;
```

#### Log Rotation
```bash
# Rotate Edge Function logs
supabase functions logs rotate --days 7

# Archive old logs
supabase functions logs archive --before "2024-12-15"
```

### 2. Weekly Maintenance

#### Performance Review
```sql
-- Weekly performance report
SELECT 
    DATE_TRUNC('week', created_at) as week,
    algorithm_used,
    COUNT(*) as optimizations,
    AVG(calculation_time_ms) as avg_time,
    AVG(optimization_score) as avg_score,
    PERCENTILE_CONT(0.95) WITHIN GROUP (ORDER BY calculation_time_ms) as p95_time
FROM tsp_performance_metrics 
WHERE created_at >= NOW() - INTERVAL '4 weeks'
GROUP BY DATE_TRUNC('week', created_at), algorithm_used
ORDER BY week DESC, algorithm_used;
```

#### Index Maintenance
```sql
-- Rebuild indexes if needed
REINDEX INDEX CONCURRENTLY idx_delivery_batches_driver_status;
REINDEX INDEX CONCURRENTLY idx_route_optimizations_created_at;

-- Check index bloat
SELECT 
    schemaname,
    tablename,
    indexname,
    pg_size_pretty(pg_relation_size(indexrelid)) as size,
    idx_scan,
    idx_tup_read
FROM pg_stat_user_indexes 
WHERE schemaname = 'public'
ORDER BY pg_relation_size(indexrelid) DESC;
```

---

## ✅ System Health Checks

### 1. Automated Health Checks

#### Edge Function Health
```bash
#!/bin/bash
# health_check.sh

FUNCTIONS=("create-delivery-batch" "optimize-delivery-route" "manage-delivery-batch")
BASE_URL="https://abknoalhfltlhhdbclpv.supabase.co/functions/v1"

for func in "${FUNCTIONS[@]}"; do
    response=$(curl -s -o /dev/null -w "%{http_code}" -X HEAD "$BASE_URL/$func")
    if [ "$response" -eq 200 ] || [ "$response" -eq 405 ]; then
        echo "✅ $func: Healthy"
    else
        echo "❌ $func: Unhealthy (HTTP $response)"
    fi
done
```

#### Database Health
```sql
-- Database health check function
CREATE OR REPLACE FUNCTION database_health_check()
RETURNS JSON AS $$
DECLARE
    result JSON;
    connection_count INTEGER;
    slow_queries INTEGER;
    lock_count INTEGER;
BEGIN
    -- Check connection count
    SELECT COUNT(*) INTO connection_count FROM pg_stat_activity;
    
    -- Check for slow queries
    SELECT COUNT(*) INTO slow_queries 
    FROM pg_stat_activity 
    WHERE state = 'active' 
    AND query_start < NOW() - INTERVAL '30 seconds';
    
    -- Check for locks
    SELECT COUNT(*) INTO lock_count 
    FROM pg_locks 
    WHERE NOT granted;
    
    SELECT json_build_object(
        'status', CASE 
            WHEN connection_count > 180 OR slow_queries > 5 OR lock_count > 10 
            THEN 'unhealthy'
            ELSE 'healthy'
        END,
        'connections', connection_count,
        'slow_queries', slow_queries,
        'blocked_queries', lock_count,
        'timestamp', NOW()
    ) INTO result;
    
    RETURN result;
END;
$$ LANGUAGE plpgsql;
```

### 2. Manual Health Verification

#### System Status Checklist
- [ ] All Edge Functions responding (< 2s response time)
- [ ] Database queries executing normally (< 1s average)
- [ ] Real-time subscriptions connected
- [ ] No critical alerts in last 15 minutes
- [ ] Batch creation success rate > 95%
- [ ] Route optimization success rate > 90%
- [ ] Driver utilization within normal range (60-80%)
- [ ] System health score > 85%

#### Performance Baseline Verification
```sql
-- Verify performance baselines
WITH current_metrics AS (
    SELECT 
        AVG(calculation_time_ms) as avg_calc_time,
        AVG(optimization_score) as avg_opt_score,
        COUNT(*) as total_optimizations
    FROM tsp_performance_metrics 
    WHERE created_at >= NOW() - INTERVAL '1 hour'
)
SELECT 
    CASE 
        WHEN avg_calc_time <= 3000 THEN '✅ Calculation time OK'
        ELSE '❌ Calculation time HIGH: ' || avg_calc_time || 'ms'
    END as calc_time_status,
    CASE 
        WHEN avg_opt_score >= 75 THEN '✅ Optimization score OK'
        ELSE '❌ Optimization score LOW: ' || avg_opt_score
    END as opt_score_status,
    CASE 
        WHEN total_optimizations > 0 THEN '✅ System active'
        ELSE '⚠️ No recent optimizations'
    END as activity_status
FROM current_metrics;
```

---

## 📞 Escalation Procedures

### Level 1: Automated Response
- System health monitoring detects issues
- Automated alerts sent to operations team
- Basic mitigation applied (algorithm switching, parameter adjustment)

### Level 2: Operations Team
- Manual investigation and diagnosis
- Advanced troubleshooting procedures
- Feature flag adjustments and rollbacks

### Level 3: Engineering Team
- Code-level debugging and fixes
- Database schema modifications
- Algorithm optimization and tuning

### Level 4: Emergency Response
- System-wide rollback procedures
- Incident commander activation
- Customer communication and status updates

---

*Last Updated: December 22, 2024*
*Version: 1.0.0*
