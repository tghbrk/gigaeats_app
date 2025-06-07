# GigaEats Delivery Proof System Documentation

## Overview

The GigaEats Delivery Proof System is a comprehensive solution for capturing, storing, and managing proof of delivery for food orders. This system provides complete transparency and accountability in the delivery process through photo capture, GPS location tracking, and real-time status updates.

## Features

### 📸 Photo Capture
- **Camera Integration**: Native camera access with proper permissions
- **Photo Upload**: Automatic upload to dedicated Supabase storage bucket
- **Image Preview**: Real-time photo preview and retake functionality
- **Quality Control**: Image validation and error handling

### 📍 GPS Location Tracking
- **Real-time Location**: Accurate GPS coordinate capture
- **Location Accuracy**: Validation with accuracy metrics (±meters)
- **Address Resolution**: Automatic address lookup from coordinates
- **Permission Handling**: Proper location permission management

### 💾 Backend Storage
- **Database Schema**: Comprehensive delivery_proofs table
- **Automatic Triggers**: Order status updates on proof submission
- **Security**: Row Level Security (RLS) policies
- **Storage Bucket**: Dedicated delivery-proofs bucket

### ⚡ Real-time Updates
- **Live Synchronization**: Real-time order status updates
- **Visual Indicators**: UI badges and highlights for updates
- **Connection Status**: Live/Offline connection monitoring
- **Cross-platform**: Android and web compatibility

## Architecture

### Database Schema

```sql
-- Delivery Proofs Table
CREATE TABLE delivery_proofs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    photo_url TEXT NOT NULL,
    signature_url TEXT,
    recipient_name TEXT,
    notes TEXT,
    delivered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    delivered_by TEXT NOT NULL,
    latitude DECIMAL(10, 8),
    longitude DECIMAL(11, 8),
    location_accuracy DECIMAL(8, 2),
    delivery_address TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    CONSTRAINT unique_order_proof UNIQUE(order_id)
);
```

### Storage Structure

```
delivery-proofs/
├── proof_delivery_{order_id}_{timestamp}.jpg
├── signature_{order_id}_{timestamp}.png
└── ...
```

### Real-time Providers

```dart
// Main real-time provider
final deliveryProofRealtimeProvider = StateNotifierProvider<
    DeliveryProofRealtimeNotifier, 
    DeliveryProofRealtimeState
>((ref) {
    final orderRepository = ref.watch(orderRepositoryProvider);
    final supabase = ref.watch(supabaseProvider);
    return DeliveryProofRealtimeNotifier(orderRepository, supabase);
});

// Family providers
final deliveryProofProvider = Provider.family<ProofOfDelivery?, String>((ref, orderId) {
    final realtimeState = ref.watch(deliveryProofRealtimeProvider);
    return realtimeState.deliveryProofs[orderId];
});
```

## Implementation Guide

### 1. Database Setup

Run the migration script to create the delivery proof infrastructure:

```bash
# Apply the delivery proof migration
supabase db push
```

The migration includes:
- `delivery_proofs` table creation
- Automatic triggers for order status updates
- RLS policies for secure access
- Storage bucket creation

### 2. Flutter Integration

#### Add Dependencies

```yaml
dependencies:
  image_picker: ^1.0.4
  geolocator: ^10.1.0
  permission_handler: ^11.0.1
  cached_network_image: ^3.3.0
```

#### Implement Photo Capture

```dart
import 'package:image_picker/image_picker.dart';

class ProofOfDeliveryCapture extends ConsumerStatefulWidget {
  final Order order;
  final Function(ProofOfDelivery) onProofCaptured;

  const ProofOfDeliveryCapture({
    super.key,
    required this.order,
    required this.onProofCaptured,
  });
}
```

#### Add Location Services

```dart
import 'package:geolocator/geolocator.dart';

Future<LocationData> _captureLocation() async {
  final permission = await Geolocator.requestPermission();
  if (permission == LocationPermission.denied) {
    throw Exception('Location permission denied');
  }

  final position = await Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.high,
  );

  return LocationData(
    latitude: position.latitude,
    longitude: position.longitude,
    accuracy: position.accuracy,
  );
}
```

### 3. Backend Integration

#### Repository Method

```dart
Future<void> storeDeliveryProof(String orderId, ProofOfDelivery proof) async {
  try {
    // Insert delivery proof record
    await _supabase.from('delivery_proofs').insert({
      'order_id': orderId,
      'photo_url': proof.photoUrl,
      'recipient_name': proof.recipientName,
      'notes': proof.notes,
      'delivered_at': proof.deliveredAt.toIso8601String(),
      'delivered_by': proof.deliveredBy,
      'latitude': proof.latitude,
      'longitude': proof.longitude,
      'location_accuracy': proof.locationAccuracy,
      'delivery_address': proof.deliveryAddress,
    });

    DebugLogger.info('Delivery proof stored successfully for order: $orderId');
  } catch (e) {
    DebugLogger.error('Failed to store delivery proof: $e');
    rethrow;
  }
}
```

### 4. Real-time Setup

#### Configure Real-time Subscriptions

```dart
void _setupRealtimeSubscriptions() {
  // Subscribe to delivery_proofs table changes
  _deliveryProofChannel = _supabase
      .channel('delivery_proofs_realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'delivery_proofs',
        callback: (payload) => _handleDeliveryProofUpdate(payload),
      )
      .subscribe();

  // Subscribe to orders table changes
  _orderChannel = _supabase
      .channel('orders_delivery_realtime')
      .onPostgresChanges(
        event: PostgresChangeEvent.update,
        schema: 'public',
        table: 'orders',
        callback: (payload) => _handleOrderUpdate(payload),
      )
      .subscribe();
}
```

## Usage Guide

### For Vendors

1. **Access Delivery Proof**:
   - Navigate to vendor orders screen
   - Select an order with "ready" or "out for delivery" status
   - Tap on the order to open details
   - Use the delivery proof capture interface

2. **Capture Proof**:
   - Take a photo of the delivered order
   - Capture current GPS location
   - Fill in recipient name (optional)
   - Add delivery notes (optional)
   - Submit the proof

3. **Real-time Updates**:
   - Order status automatically updates to "delivered"
   - Real-time indicators show in the orders list
   - Other users see updates immediately

### For Testing

Access the delivery proof test interface:

1. **Via Vendor Dashboard**:
   - Go to Vendor Dashboard
   - Tap the developer tools icon
   - Select "Delivery Testing"
   - Choose "Open Delivery Test"

2. **Test Orders**:
   - View available orders for testing
   - Select orders in appropriate status
   - Test complete delivery proof workflow

## Security

### Row Level Security (RLS) Policies

```sql
-- Users can view delivery proofs for orders they're involved in
CREATE POLICY "Users can view delivery proofs for their orders" ON delivery_proofs
FOR SELECT USING (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = delivery_proofs.order_id
    AND (
      o.vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
      o.sales_agent_id = auth.uid() OR
      EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role = 'admin')
    )
  )
);

-- Users can create delivery proofs for orders they're responsible for
CREATE POLICY "Users can create delivery proofs for their orders" ON delivery_proofs
FOR INSERT WITH CHECK (
  EXISTS (
    SELECT 1 FROM orders o
    WHERE o.id = delivery_proofs.order_id
    AND (
      o.vendor_id IN (SELECT id FROM vendors WHERE user_id = auth.uid()) OR
      o.sales_agent_id = auth.uid()
    )
  )
);
```

### Storage Security

```sql
-- Delivery proofs bucket policies
CREATE POLICY "Users can upload delivery proof photos" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'delivery-proofs' AND
  auth.role() = 'authenticated'
);

CREATE POLICY "Users can view delivery proof photos" ON storage.objects
FOR SELECT USING (
  bucket_id = 'delivery-proofs' AND
  auth.role() = 'authenticated'
);
```

## Troubleshooting

### Common Issues

1. **Camera Permission Denied**:
   - Check app permissions in device settings
   - Ensure camera permission is granted
   - Restart the app if needed

2. **Location Not Available**:
   - Enable location services on device
   - Grant location permission to app
   - Check GPS signal strength

3. **Photo Upload Failed**:
   - Check internet connectivity
   - Verify Supabase storage configuration
   - Check storage bucket permissions

4. **Real-time Updates Not Working**:
   - Verify Supabase real-time is enabled
   - Check network connectivity
   - Restart the app to re-establish connections

### Debug Logging

Enable debug logging to troubleshoot issues:

```dart
DebugLogger.info('Delivery proof capture started', tag: 'DeliveryProof');
DebugLogger.error('Photo upload failed: $error', tag: 'DeliveryProof');
```

## Performance Considerations

### Photo Optimization
- Images are automatically compressed before upload
- Maximum file size limits are enforced
- Progressive upload with retry logic

### Location Accuracy
- High accuracy GPS is used for delivery location
- Timeout handling for location requests
- Fallback to last known location if needed

### Real-time Efficiency
- Selective real-time subscriptions
- Efficient state management
- Connection pooling and reuse

## Future Enhancements

### Planned Features
- **Digital Signatures**: Customer signature capture
- **Delivery Time Windows**: Scheduled delivery slots
- **Route Optimization**: Delivery route planning
- **Customer Notifications**: SMS/Push notifications
- **Analytics Dashboard**: Delivery performance metrics

### Integration Opportunities
- **Third-party Logistics**: Integration with delivery services
- **IoT Sensors**: Temperature monitoring for food safety
- **AI/ML**: Delivery time prediction and optimization
- **Blockchain**: Immutable delivery proof records

## Support

For technical support or questions about the delivery proof system:

1. Check this documentation first
2. Review the troubleshooting section
3. Check debug logs for error details
4. Contact the development team with specific error messages

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Compatibility**: Flutter 3.x, Supabase 2.x
