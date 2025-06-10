# GigaEats Fleet Management System

## 🚚 Overview

The GigaEats Fleet Management System provides vendors with comprehensive tools to manage their delivery drivers, track performance, and optimize delivery operations.

## 🏗️ Architecture

### Database Schema

#### Drivers Table
```sql
CREATE TABLE drivers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendors(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    name TEXT NOT NULL,
    phone_number TEXT NOT NULL,
    vehicle_details JSONB DEFAULT '{}',
    status driver_status NOT NULL DEFAULT 'offline',
    last_location GEOMETRY(Point, 4326),
    last_seen TIMESTAMPTZ,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

#### Driver Status Enum
```sql
CREATE TYPE driver_status AS ENUM ('offline', 'online', 'on_delivery');
```

#### Delivery Tracking Table
```sql
CREATE TABLE delivery_tracking (
    id BIGSERIAL PRIMARY KEY,
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    driver_id UUID NOT NULL REFERENCES drivers(id) ON DELETE CASCADE,
    location GEOMETRY(Point, 4326) NOT NULL,
    speed DECIMAL(5,2),
    heading DECIMAL(5,2),
    accuracy DECIMAL(8,2),
    recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'
);
```

### Flutter Implementation

#### Key Components
- **Driver Repository**: Handles all driver-related database operations
- **Fleet Screen**: Main interface for driver management
- **Add Driver Dialog**: Form for creating new drivers
- **Assign Driver Dialog**: Interface for assigning drivers to orders
- **Driver Status Indicator**: Visual status representation

#### Provider Architecture
```dart
// Driver management state
final driverProvider = StateNotifierProvider<DriverNotifier, DriverState>((ref) {
  return DriverNotifier(ref.read(driverRepositoryProvider));
});

// Available drivers for assignment
final availableDriversProvider = FutureProvider.family<List<Driver>, String>((ref, vendorId) {
  return ref.read(driverRepositoryProvider).getAvailableDriversForVendor(vendorId);
});
```

## 🔧 Features

### Driver Management
- ✅ Add new drivers with vehicle details
- ✅ Update driver information
- ✅ Activate/deactivate drivers
- ✅ Real-time status tracking

### Driver Assignment
- ✅ Assign drivers to orders
- ✅ Filter available drivers by status
- ✅ Search drivers by name/phone/vehicle

### Performance Tracking
- ✅ Driver statistics (total, online, offline, on delivery)
- ✅ Delivery performance metrics
- ✅ Real-time location tracking

### Security
- ✅ Row Level Security (RLS) policies
- ✅ Vendor-specific driver access
- ✅ Secure driver assignment

## 🚀 Usage

### Adding a Driver
1. Navigate to Fleet screen in vendor dashboard
2. Click "Add Driver" button
3. Fill in driver details (name, phone, vehicle info)
4. Submit form to create driver

### Assigning a Driver
1. Go to order details screen
2. Click "Assign Driver" button
3. Select from available online drivers
4. Confirm assignment

### Managing Driver Status
- Drivers can be set to online/offline/on_delivery
- Status updates are reflected in real-time
- Only online drivers are available for assignment

## 🔒 Security Implementation

### RLS Policies
```sql
-- Vendors can only manage their own drivers
CREATE POLICY "Vendors can manage their own drivers" ON drivers
  FOR ALL USING (
    vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid())
  );
```

### Vendor ID Lookup
The system uses proper vendor ID lookup to ensure security:
```dart
// Get actual vendor ID from vendors table
final vendorResponse = await supabase
    .from('vendors')
    .select('id')
    .eq('user_id', userId)
    .single();

final vendorId = vendorResponse['id'] as String;
```

## 🧪 Testing

### Test Scenarios
- ✅ Driver creation with valid data
- ✅ Driver assignment to orders
- ✅ Status updates and real-time sync
- ✅ RLS policy enforcement
- ✅ Vendor isolation verification

### Test Data
- Test vendor: `55555555-6666-7777-8888-999999999999`
- Test drivers with various statuses
- Sample orders for assignment testing

## 📱 Platform Support

- ✅ Android (Primary testing platform)
- ✅ Web (Secondary support)
- ✅ iOS (Compatible but not extensively tested)

## 🔄 Real-time Updates

The system supports real-time updates for:
- Driver status changes
- Location tracking
- Order assignments
- Performance metrics

## 📊 Analytics Integration

Fleet management integrates with vendor analytics to provide:
- Driver performance metrics
- Delivery efficiency statistics
- Fleet utilization reports
- Cost analysis and optimization insights
