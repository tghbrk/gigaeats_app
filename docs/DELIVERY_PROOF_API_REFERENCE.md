# Delivery Proof System API Reference

## Overview

This document provides detailed API reference for the GigaEats Delivery Proof System, including database schemas, Flutter widgets, providers, and service methods.

## Database Schema

### delivery_proofs Table

```sql
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

#### Field Descriptions

| Field | Type | Description | Required |
|-------|------|-------------|----------|
| `id` | UUID | Primary key, auto-generated | Yes |
| `order_id` | UUID | Reference to orders table | Yes |
| `photo_url` | TEXT | URL to delivery photo in storage | Yes |
| `signature_url` | TEXT | URL to customer signature | No |
| `recipient_name` | TEXT | Name of person who received delivery | No |
| `notes` | TEXT | Additional delivery notes | No |
| `delivered_at` | TIMESTAMPTZ | Timestamp of delivery | Yes |
| `delivered_by` | TEXT | Name/ID of delivery person | Yes |
| `latitude` | DECIMAL(10,8) | GPS latitude coordinate | No |
| `longitude` | DECIMAL(11,8) | GPS longitude coordinate | No |
| `location_accuracy` | DECIMAL(8,2) | GPS accuracy in meters | No |
| `delivery_address` | TEXT | Resolved address from coordinates | No |
| `created_at` | TIMESTAMPTZ | Record creation timestamp | Auto |
| `updated_at` | TIMESTAMPTZ | Record update timestamp | Auto |

### Database Triggers

#### handle_delivery_proof_creation()

Automatically updates order status when delivery proof is created:

```sql
CREATE OR REPLACE FUNCTION handle_delivery_proof_creation()
RETURNS TRIGGER AS $$
BEGIN
  -- Update the order status to 'delivered' and set actual delivery time
  UPDATE orders 
  SET 
    status = 'delivered',
    actual_delivery_time = NEW.delivered_at,
    delivery_proof_id = NEW.id,
    updated_at = NOW()
  WHERE id = NEW.order_id;
  
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_delivery_proof_creation
    AFTER INSERT ON delivery_proofs
    FOR EACH ROW
    EXECUTE FUNCTION handle_delivery_proof_creation();
```

## Flutter Models

### ProofOfDelivery

```dart
class ProofOfDelivery {
  final String photoUrl;
  final String? signatureUrl;
  final String? recipientName;
  final String? notes;
  final DateTime deliveredAt;
  final String deliveredBy;
  final double? latitude;
  final double? longitude;
  final double? locationAccuracy;
  final String? deliveryAddress;

  const ProofOfDelivery({
    required this.photoUrl,
    this.signatureUrl,
    this.recipientName,
    this.notes,
    required this.deliveredAt,
    required this.deliveredBy,
    this.latitude,
    this.longitude,
    this.locationAccuracy,
    this.deliveryAddress,
  });

  factory ProofOfDelivery.fromJson(Map<String, dynamic> json) {
    return ProofOfDelivery(
      photoUrl: json['photo_url'] as String,
      signatureUrl: json['signature_url'] as String?,
      recipientName: json['recipient_name'] as String?,
      notes: json['notes'] as String?,
      deliveredAt: DateTime.parse(json['delivered_at'] as String),
      deliveredBy: json['delivered_by'] as String,
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      locationAccuracy: json['location_accuracy'] != null ? (json['location_accuracy'] as num).toDouble() : null,
      deliveryAddress: json['delivery_address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photo_url': photoUrl,
      'signature_url': signatureUrl,
      'recipient_name': recipientName,
      'notes': notes,
      'delivered_at': deliveredAt.toIso8601String(),
      'delivered_by': deliveredBy,
      'latitude': latitude,
      'longitude': longitude,
      'location_accuracy': locationAccuracy,
      'delivery_address': deliveryAddress,
    };
  }
}
```

### LocationData

```dart
class LocationData {
  final double latitude;
  final double longitude;
  final double accuracy;
  final String? address;

  const LocationData({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    this.address,
  });

  factory LocationData.fromPosition(Position position, {String? address}) {
    return LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      accuracy: position.accuracy,
      address: address,
    );
  }
}
```

## Flutter Widgets

### ProofOfDeliveryCapture

Main widget for capturing delivery proof:

```dart
class ProofOfDeliveryCapture extends ConsumerStatefulWidget {
  final Order order;
  final Function(ProofOfDelivery) onProofCaptured;

  const ProofOfDeliveryCapture({
    super.key,
    required this.order,
    required this.onProofCaptured,
  });

  @override
  ConsumerState<ProofOfDeliveryCapture> createState() => _ProofOfDeliveryCaptureState();
}
```

#### Properties

| Property | Type | Description |
|----------|------|-------------|
| `order` | Order | The order for which proof is being captured |
| `onProofCaptured` | Function(ProofOfDelivery) | Callback when proof is successfully captured |

#### Methods

| Method | Description |
|--------|-------------|
| `_capturePhoto(ImageSource source)` | Captures photo from camera or gallery |
| `_captureLocation()` | Gets current GPS location |
| `_submitProofOfDelivery()` | Submits the complete proof |

### DeliveryConfirmationSummary

Widget for displaying delivery proof summary:

```dart
class DeliveryConfirmationSummary extends StatelessWidget {
  final Order order;
  final String? photoUrl;
  final LocationData? locationData;
  final String? recipientName;
  final String? notes;
  final VoidCallback? onEditPhoto;
  final VoidCallback? onEditLocation;
  final VoidCallback? onConfirmDelivery;
  final bool isSubmitting;

  const DeliveryConfirmationSummary({
    super.key,
    required this.order,
    this.photoUrl,
    this.locationData,
    this.recipientName,
    this.notes,
    this.onEditPhoto,
    this.onEditLocation,
    this.onConfirmDelivery,
    this.isSubmitting = false,
  });
}
```

## Riverpod Providers

### deliveryProofRealtimeProvider

Main provider for real-time delivery proof updates:

```dart
final deliveryProofRealtimeProvider = StateNotifierProvider<
    DeliveryProofRealtimeNotifier, 
    DeliveryProofRealtimeState
>((ref) {
  final orderRepository = ref.watch(orderRepositoryProvider);
  final supabase = ref.watch(supabaseProvider);
  return DeliveryProofRealtimeNotifier(orderRepository, supabase);
});
```

### deliveryProofProvider

Family provider for getting delivery proof by order ID:

```dart
final deliveryProofProvider = Provider.family<ProofOfDelivery?, String>((ref, orderId) {
  final realtimeState = ref.watch(deliveryProofRealtimeProvider);
  return realtimeState.deliveryProofs[orderId];
});
```

### hasDeliveryUpdateProvider

Provider to check if an order has recent delivery updates:

```dart
final hasDeliveryUpdateProvider = Provider.family<bool, String>((ref, orderId) {
  final realtimeState = ref.watch(deliveryProofRealtimeProvider);
  return realtimeState.updatedOrders.containsKey(orderId) ||
         realtimeState.deliveryProofs.containsKey(orderId);
});
```

### deliveryRealtimeConnectionProvider

Provider for real-time connection status:

```dart
final deliveryRealtimeConnectionProvider = Provider<bool>((ref) {
  final realtimeState = ref.watch(deliveryProofRealtimeProvider);
  return realtimeState.isConnected;
});
```

## Repository Methods

### OrderRepository

#### storeDeliveryProof

```dart
Future<void> storeDeliveryProof(String orderId, ProofOfDelivery proof) async {
  try {
    DebugLogger.info('Storing delivery proof for order: $orderId', tag: 'OrderRepository');

    final response = await _supabase.from('delivery_proofs').insert({
      'order_id': orderId,
      'photo_url': proof.photoUrl,
      'signature_url': proof.signatureUrl,
      'recipient_name': proof.recipientName,
      'notes': proof.notes,
      'delivered_at': proof.deliveredAt.toIso8601String(),
      'delivered_by': proof.deliveredBy,
      'latitude': proof.latitude,
      'longitude': proof.longitude,
      'location_accuracy': proof.locationAccuracy,
      'delivery_address': proof.deliveryAddress,
    });

    DebugLogger.info('Delivery proof stored successfully', tag: 'OrderRepository');
  } catch (e) {
    DebugLogger.error('Failed to store delivery proof: $e', tag: 'OrderRepository');
    rethrow;
  }
}
```

#### getDeliveryProof

```dart
Future<ProofOfDelivery?> getDeliveryProof(String orderId) async {
  try {
    final response = await _supabase
        .from('delivery_proofs')
        .select()
        .eq('order_id', orderId)
        .maybeSingle();

    if (response == null) return null;

    return ProofOfDelivery.fromJson(response);
  } catch (e) {
    DebugLogger.error('Failed to get delivery proof: $e', tag: 'OrderRepository');
    rethrow;
  }
}
```

## Service Classes

### CameraPermissionService

```dart
class CameraPermissionService {
  static Future<bool> requestCameraPermission() async {
    final status = await Permission.camera.request();
    return status == PermissionStatus.granted;
  }

  static Future<bool> hasCameraPermission() async {
    final status = await Permission.camera.status;
    return status == PermissionStatus.granted;
  }
}
```

### LocationService

```dart
class LocationService {
  static Future<LocationData> getCurrentLocation() async {
    final permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) {
      throw LocationPermissionException('Location permission denied');
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
      timeLimit: const Duration(seconds: 30),
    );

    return LocationData.fromPosition(position);
  }

  static Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final placemark = placemarks.first;
        return '${placemark.street}, ${placemark.locality}, ${placemark.administrativeArea}';
      }
    } catch (e) {
      DebugLogger.error('Failed to get address: $e', tag: 'LocationService');
    }
    return null;
  }
}
```

## Real-time State Management

### DeliveryProofRealtimeState

```dart
class DeliveryProofRealtimeState {
  final Map<String, ProofOfDelivery> deliveryProofs;
  final Map<String, Order> updatedOrders;
  final bool isConnected;
  final DateTime? lastUpdate;
  final String? error;

  const DeliveryProofRealtimeState({
    this.deliveryProofs = const {},
    this.updatedOrders = const {},
    this.isConnected = false,
    this.lastUpdate,
    this.error,
  });

  DeliveryProofRealtimeState copyWith({
    Map<String, ProofOfDelivery>? deliveryProofs,
    Map<String, Order>? updatedOrders,
    bool? isConnected,
    DateTime? lastUpdate,
    String? error,
  }) {
    return DeliveryProofRealtimeState(
      deliveryProofs: deliveryProofs ?? this.deliveryProofs,
      updatedOrders: updatedOrders ?? this.updatedOrders,
      isConnected: isConnected ?? this.isConnected,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      error: error ?? this.error,
    );
  }
}
```

### DeliveryProofRealtimeNotifier

```dart
class DeliveryProofRealtimeNotifier extends StateNotifier<DeliveryProofRealtimeState> {
  final OrderRepository _orderRepository;
  final SupabaseClient _supabase;
  RealtimeChannel? _deliveryProofChannel;
  RealtimeChannel? _orderChannel;

  DeliveryProofRealtimeNotifier(this._orderRepository, this._supabase) 
      : super(const DeliveryProofRealtimeState()) {
    _setupRealtimeSubscriptions();
  }

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

    state = state.copyWith(isConnected: true);
  }

  @override
  void dispose() {
    _deliveryProofChannel?.unsubscribe();
    _orderChannel?.unsubscribe();
    super.dispose();
  }
}
```

## Error Handling

### Custom Exceptions

```dart
class DeliveryProofException implements Exception {
  final String message;
  final String? code;

  const DeliveryProofException(this.message, {this.code});

  @override
  String toString() => 'DeliveryProofException: $message';
}

class LocationPermissionException extends DeliveryProofException {
  const LocationPermissionException(String message) : super(message, code: 'LOCATION_PERMISSION');
}

class CameraPermissionException extends DeliveryProofException {
  const CameraPermissionException(String message) : super(message, code: 'CAMERA_PERMISSION');
}

class PhotoUploadException extends DeliveryProofException {
  const PhotoUploadException(String message) : super(message, code: 'PHOTO_UPLOAD');
}
```

## Configuration

### Supabase Configuration

```dart
class SupabaseConfig {
  static const String deliveryProofsBucket = 'delivery-proofs';
  
  // Storage policies
  static const Map<String, String> storagePolicies = {
    'delivery_proofs_upload': '''
      CREATE POLICY "Users can upload delivery proof photos" ON storage.objects
      FOR INSERT WITH CHECK (
        bucket_id = 'delivery-proofs' AND
        auth.role() = 'authenticated'
      );
    ''',
    'delivery_proofs_view': '''
      CREATE POLICY "Users can view delivery proof photos" ON storage.objects
      FOR SELECT USING (
        bucket_id = 'delivery-proofs' AND
        auth.role() = 'authenticated'
      );
    ''',
  };
}
```

---

**Last Updated**: January 2025  
**Version**: 1.0.0  
**Compatibility**: Flutter 3.x, Supabase 2.x
