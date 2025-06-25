# Customer GPS Tracking System

## Overview

The Customer GPS Tracking System provides real-time order tracking functionality for customers when their orders are being delivered by GigaEats' own delivery fleet. This system integrates with the existing driver GPS tracking infrastructure to provide customers with live location updates, estimated arrival times, and route visualization.

## Features

### 🗺️ Real-time Map Tracking
- Live driver location updates every 10-30 seconds
- Customer delivery address visualization
- Route polyline between driver and destination
- Google Maps integration with pan/zoom controls

### 📱 Customer Interface
- Accessible via "Track Order" button on order cards
- Real-time status updates without manual refresh
- Connection status indicators
- Driver contact information display
- Estimated arrival time calculations

### 🔒 Security & Privacy
- RLS policies ensure customers only see their own order tracking
- Driver location only visible during active deliveries
- Automatic access revocation when delivery completes

## Architecture

### Database Schema

#### RLS Policies for Customer Access
```sql
-- Customers can view tracking for their orders
CREATE POLICY "Customers can view tracking for their orders" ON delivery_tracking
  FOR SELECT USING (
    order_id IN (
      SELECT o.id FROM orders o
      WHERE o.customer_id IN (
        SELECT cp.id FROM customer_profiles cp
        WHERE cp.user_id = auth.uid()
      )
      AND o.status = 'out_for_delivery'
      AND o.delivery_method = 'own_fleet'
      AND o.assigned_driver_id IS NOT NULL
    )
  );

-- Customers can view driver info for active deliveries
CREATE POLICY "Customers can view driver info for their active deliveries" ON drivers
  FOR SELECT USING (
    id IN (
      SELECT o.assigned_driver_id FROM orders o
      WHERE o.customer_id IN (
        SELECT cp.id FROM customer_profiles cp
        WHERE cp.user_id = auth.uid()
      )
      AND o.status = 'out_for_delivery'
      AND o.delivery_method = 'own_fleet'
      AND o.assigned_driver_id IS NOT NULL
    )
  );
```

### Flutter Architecture

#### Key Components
1. **CustomerOrderTrackingScreen**: Main tracking interface
2. **CustomerDeliveryTrackingService**: Backend integration
3. **CustomerDeliveryTrackingProvider**: State management with Riverpod
4. **DeliveryTrackingInfo**: Data model for tracking information

#### State Management Flow
```dart
// Provider setup
final orderTrackingProvider = StateNotifierProvider.family.autoDispose<
  CustomerDeliveryTrackingNotifier, 
  CustomerDeliveryTrackingState, 
  String
>((ref, orderId) {
  final trackingService = ref.watch(customerDeliveryTrackingServiceProvider);
  final notifier = CustomerDeliveryTrackingNotifier(trackingService);
  
  // Auto-start tracking when provider is created
  Future.microtask(() => notifier.startTracking(orderId));
  
  return notifier;
});
```

## Implementation Details

### Real-time Updates
- Supabase real-time subscriptions for delivery_tracking table
- Automatic map marker updates when driver location changes
- Order status monitoring for delivery completion

### Route Calculation
- Haversine formula for distance calculations
- Estimated arrival time based on average urban speeds (25 km/h)
- Future integration planned with Google Directions API

### Error Handling
- Connection status indicators in app bar
- Graceful fallbacks when GPS is unavailable
- Retry mechanisms for failed location updates

## Usage

### Customer Access Flow
1. Customer places order with "own_fleet" delivery method
2. Vendor assigns driver to order
3. Order status changes to "out_for_delivery"
4. "Track Order" button becomes available on customer order card
5. Customer taps button to navigate to tracking screen
6. Real-time tracking begins automatically

### Tracking Screen Features
- **Map View**: Shows driver location and delivery destination
- **Order Header**: Order details and vendor information
- **Driver Info**: Driver name, phone, and vehicle details
- **ETA Display**: Estimated arrival time with live updates
- **Connection Status**: WiFi icon indicating tracking status

## Security Considerations

### Access Control
- Customers can only track their own orders
- Tracking only available during active delivery (out_for_delivery status)
- Driver location hidden after delivery completion
- RLS policies prevent cross-customer data access

### Privacy Protection
- Driver personal information limited to name and phone
- Location data automatically purged after delivery
- No historical location tracking for customers

## Configuration

### Required Permissions
- Customer role must have 'orders.read' permission
- Real-time subscriptions enabled for delivery_tracking table
- Google Maps API key configured for map display

### Environment Setup
```dart
// Supabase configuration
const String deliveryTrackingTable = 'delivery_tracking';
const String driversTable = 'drivers';

// Real-time channel configuration
final trackingChannel = supabase
  .channel('customer_tracking_$orderId')
  .onPostgresChanges(
    event: PostgresChangeEvent.all,
    schema: 'public',
    table: 'delivery_tracking',
    filter: PostgresChangeFilter(
      type: PostgresChangeFilterType.eq,
      column: 'order_id',
      value: orderId,
    ),
    callback: (payload) => handleLocationUpdate(payload),
  );
```

## Testing

### Test Scenarios
1. **Happy Path**: Order with assigned driver and active tracking
2. **No Driver**: Order without assigned driver (should show fallback)
3. **GPS Disabled**: Driver with GPS disabled (should show last known location)
4. **Connection Loss**: Network interruption during tracking
5. **Order Completion**: Tracking stops when order is delivered

### Mock Data Setup
```dart
// Test order with tracking data
final testOrder = Order(
  id: 'test-order-123',
  status: OrderStatus.outForDelivery,
  deliveryMethod: DeliveryMethod.ownFleet,
  assignedDriverId: 'test-driver-456',
  // ... other required fields
);

// Test driver location
final testTracking = DeliveryTracking(
  orderId: 'test-order-123',
  driverId: 'test-driver-456',
  location: TrackingLocation(
    latitude: 3.1390,
    longitude: 101.6869,
  ),
  recordedAt: DateTime.now(),
);
```

## Future Enhancements

### Planned Features
- Google Directions API integration for accurate routes
- Traffic-aware ETA calculations
- Push notifications for delivery milestones
- Customer delivery preferences
- Multi-stop delivery optimization

### Performance Optimizations
- Location update batching
- Map marker clustering for multiple orders
- Offline map caching
- Background location sync

## Troubleshooting

### Common Issues
1. **Tracking Not Starting**: Check RLS policies and order status
2. **Map Not Loading**: Verify Google Maps API key
3. **Location Not Updating**: Check driver GPS permissions
4. **Connection Errors**: Verify Supabase real-time configuration

### Debug Tools
- Connection status indicator in app bar
- Console logging for tracking events
- Error boundary for graceful failure handling
- Network request monitoring

## Related Documentation
- [Fleet Management System](./FLEET_MANAGEMENT_SYSTEM.md)
- [Order Management System](./ORDER_MANAGEMENT_SYSTEM.md)
- [Driver Mobile Interface](./DRIVER_MOBILE_INTERFACE.md)
- [Real-time Notifications](./REALTIME_NOTIFICATIONS.md)
