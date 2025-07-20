# GigaEats Driver Workflow Database Schema Investigation

## 🎯 Investigation Summary

This document provides a comprehensive analysis of the GigaEats database schema and RLS policies related to the driver workflow system, identifying potential issues and areas for improvement.

## 🔍 Current Database Schema Analysis

### **Orders Table Schema**
```sql
-- Core order fields
id UUID PRIMARY KEY
order_number TEXT UNIQUE
status order_status_enum NOT NULL DEFAULT 'pending'
vendor_id UUID REFERENCES vendors(id)
customer_id UUID REFERENCES customers(id)
sales_agent_id UUID REFERENCES users(id)
assigned_driver_id UUID REFERENCES drivers(id)

-- Tracking timestamps
preparation_started_at TIMESTAMP WITH TIME ZONE
ready_at TIMESTAMP WITH TIME ZONE
out_for_delivery_at TIMESTAMP WITH TIME ZONE
actual_delivery_time TIMESTAMP WITH TIME ZONE
estimated_delivery_time TIMESTAMP WITH TIME ZONE

-- Financial fields
subtotal DECIMAL(12,2)
delivery_fee DECIMAL(12,2)
sst_amount DECIMAL(12,2)
total_amount DECIMAL(12,2)

-- Delivery information
delivery_method TEXT -- 'own_fleet', 'customer_pickup', 'sales_agent_pickup'
delivery_address TEXT
delivery_latitude DECIMAL(10,8)
delivery_longitude DECIMAL(11,8)

-- Metadata
created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
```

### **Drivers Table Schema**
```sql
-- Core driver fields
id UUID PRIMARY KEY DEFAULT gen_random_uuid()
vendor_id UUID NOT NULL REFERENCES vendors(id)
user_id UUID REFERENCES auth.users(id)
name TEXT NOT NULL
phone_number TEXT NOT NULL

-- Status tracking
status driver_status NOT NULL DEFAULT 'offline' -- 'offline', 'online', 'on_delivery'
current_delivery_status TEXT DEFAULT NULL -- Granular workflow tracking

-- Location tracking
last_location GEOMETRY(Point, 4326)
last_seen TIMESTAMPTZ
vehicle_details JSONB DEFAULT '{}'

-- Metadata
is_active BOOLEAN NOT NULL DEFAULT true
created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
```

### **Order Status Enum Values**
**Current Values (Confirmed)**:
```sql
CREATE TYPE order_status_enum AS ENUM (
  'pending',
  'confirmed', 
  'preparing',
  'ready',
  'out_for_delivery',
  'delivered',
  'cancelled',
  -- Granular driver workflow statuses (added via migrations)
  'assigned',
  'on_route_to_vendor',
  'arrived_at_vendor', 
  'picked_up',
  'on_route_to_customer',
  'arrived_at_customer'
);
```

### **Driver Status Enum Values**
```sql
CREATE TYPE driver_status AS ENUM (
  'offline',
  'online', 
  'on_delivery'
);
```

## 🚨 Identified Issues and Concerns

### **1. Enum Conversion Mismatch**
**Issue**: Frontend uses camelCase enum values while database uses snake_case
- Frontend: `onRouteToVendor`, `arrivedAtVendor`, `pickedUp`
- Database: `on_route_to_vendor`, `arrived_at_vendor`, `picked_up`

**Impact**: Potential conversion errors in DriverOrderStatus.fromString() method

### **2. Dual Status Tracking System**
**Issue**: Two separate status tracking mechanisms:
- `orders.status` (order_status_enum) - Customer/vendor visible
- `drivers.current_delivery_status` (TEXT) - Internal driver workflow

**Concern**: Potential synchronization issues between these two status systems

### **3. RLS Policy Complexity**
**Issue**: Multiple overlapping RLS policies for driver order access:
- "Drivers can update assigned and available orders"
- "Drivers can view their own profile" 
- "Drivers can manage their own tracking data"

**Concern**: Complex permission validation logic may cause authorization failures

### **4. Missing Database Constraints**
**Issues Identified**:
- No foreign key constraint validation for `current_delivery_status` values
- No check constraint ensuring `assigned_driver_id` matches delivery method
- Missing indexes on frequently queried columns

### **5. Trigger Function Conflicts**
**Issue**: Multiple trigger functions handling order status validation:
- `validate_order_status_transitions()`
- `validate_driver_order_status_update()`

**Concern**: Potential conflicts or duplicate validation logic

## 📊 Database Performance Analysis

### **Missing Indexes**
```sql
-- Recommended indexes for driver workflow optimization
CREATE INDEX IF NOT EXISTS idx_orders_status_assigned_driver 
ON orders(status, assigned_driver_id) 
WHERE assigned_driver_id IS NOT NULL;

CREATE INDEX IF NOT EXISTS idx_orders_delivery_method_status 
ON orders(delivery_method, status) 
WHERE delivery_method = 'own_fleet';

CREATE INDEX IF NOT EXISTS idx_drivers_status_delivery_status 
ON drivers(status, current_delivery_status) 
WHERE status = 'on_delivery';
```

### **Query Performance Concerns**
1. **Real-time order fetching**: Complex filtering in `incomingOrdersStreamProvider`
2. **Driver status updates**: Multiple table updates in single transaction
3. **Order assignment**: Race conditions in concurrent driver acceptance

## 🔧 RLS Policy Analysis

### **Current Driver Order Policies**
```sql
-- Policy: "Drivers can update assigned and available orders"
USING (
  (assigned_driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()))
  OR 
  (status = 'ready' AND delivery_method = 'own_fleet' AND assigned_driver_id IS NULL)
)
WITH CHECK (
  (assigned_driver_id IN (SELECT id FROM drivers WHERE user_id = auth.uid()))
  OR 
  (assigned_driver_id IS NULL)
);
```

**Analysis**: Policy allows both order acceptance and status updates but may be too permissive

### **Potential Security Issues**
1. **Driver impersonation**: Insufficient validation of driver identity
2. **Order hijacking**: Race conditions in order assignment
3. **Status manipulation**: Drivers could potentially skip workflow steps

## 🎯 Recommendations

### **1. Schema Improvements**
- Add check constraints for status transitions
- Create composite indexes for common query patterns
- Implement proper foreign key constraints

### **2. Enum Standardization**
- Standardize on snake_case for all database enums
- Update frontend conversion logic to handle both formats
- Add validation functions for enum conversions

### **3. RLS Policy Optimization**
- Consolidate overlapping policies
- Add more granular permission checks
- Implement audit logging for sensitive operations

### **4. Performance Enhancements**
- Add missing indexes for driver workflow queries
- Optimize real-time subscription filters
- Implement connection pooling for high-concurrency scenarios

## ✅ Verification Checklist

- [x] Analyzed current orders table schema
- [x] Reviewed drivers table structure  
- [x] Verified enum value definitions
- [x] Identified RLS policy configurations
- [x] Assessed database constraints and indexes
- [x] Documented potential issues and concerns
- [x] Provided actionable recommendations

## 📝 Next Steps

1. **Immediate**: Fix enum conversion issues in frontend code
2. **Short-term**: Add missing database indexes and constraints
3. **Medium-term**: Consolidate and optimize RLS policies
4. **Long-term**: Implement comprehensive audit logging system

---

**Investigation Date**: 2025-01-19  
**Status**: Complete  
**Priority**: High - Critical for driver workflow stability
