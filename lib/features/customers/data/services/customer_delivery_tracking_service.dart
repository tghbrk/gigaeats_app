import 'dart:async';
import 'dart:math' as math;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../vendors/data/models/delivery_tracking.dart';
import '../../../vendors/data/models/driver.dart';
import '../../../orders/data/models/order.dart';
import '../../../../core/utils/logger.dart';

/// Customer delivery tracking service for real-time order tracking
class CustomerDeliveryTrackingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();
  
  StreamSubscription<List<Map<String, dynamic>>>? _trackingSubscription;
  StreamSubscription<List<Map<String, dynamic>>>? _orderSubscription;
  StreamController<DeliveryTrackingInfo?>? _trackingController;
  
  /// Get current delivery tracking for an order
  Future<DeliveryTrackingInfo?> getOrderDeliveryTracking(String orderId) async {
    try {
      _logger.info('CustomerDeliveryTrackingService: Getting delivery tracking for order $orderId');

      // Get order details with driver information
      final orderResponse = await _supabase
          .from('orders')
          .select('''
            *,
            drivers!assigned_driver_id(
              id,
              name,
              phone_number,
              vehicle_details,
              last_location,
              last_seen
            )
          ''')
          .eq('id', orderId)
          .single();

      final order = Order.fromJson(orderResponse);
      
      if (order.assignedDriverId == null) {
        _logger.info('CustomerDeliveryTrackingService: No driver assigned to order $orderId');
        return null;
      }

      // Get latest delivery tracking data
      final trackingResponse = await _supabase
          .from('delivery_tracking')
          .select('*')
          .eq('order_id', orderId)
          .order('recorded_at', ascending: false)
          .limit(1);

      DeliveryTracking? latestTracking;
      if (trackingResponse.isNotEmpty) {
        latestTracking = DeliveryTracking.fromJson(trackingResponse.first);
      }

      // Get driver information
      final driverResponse = await _supabase
          .from('drivers')
          .select('*')
          .eq('id', order.assignedDriverId!)
          .single();

      final driver = Driver.fromJson(driverResponse);

      return DeliveryTrackingInfo(
        order: order,
        driver: driver,
        latestTracking: latestTracking,
        estimatedArrival: _calculateEstimatedArrival(order, latestTracking),
      );
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingService: Error getting delivery tracking', e);
      return null;
    }
  }

  /// Start real-time tracking for an order
  Stream<DeliveryTrackingInfo?> trackOrderRealtime(String orderId) {
    _logger.info('CustomerDeliveryTrackingService: Starting real-time tracking for order $orderId');

    // Close existing controller if any
    _trackingController?.close();
    _trackingController = StreamController<DeliveryTrackingInfo?>();

    // Subscribe to delivery tracking updates
    _trackingSubscription = _supabase
        .from('delivery_tracking')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .listen((data) async {
          try {
            if (data.isNotEmpty) {
              final trackingInfo = await getOrderDeliveryTracking(orderId);
              _trackingController?.add(trackingInfo);
            }
          } catch (e) {
            _logger.error('CustomerDeliveryTrackingService: Error in tracking stream', e);
            _trackingController?.addError(e);
          }
        });

    // Subscribe to order status updates
    _orderSubscription = _supabase
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', orderId)
        .listen((data) async {
          try {
            if (data.isNotEmpty) {
              final trackingInfo = await getOrderDeliveryTracking(orderId);
              _trackingController?.add(trackingInfo);
            }
          } catch (e) {
            _logger.error('CustomerDeliveryTrackingService: Error in order stream', e);
            _trackingController?.addError(e);
          }
        });

    // Get initial data
    getOrderDeliveryTracking(orderId).then((trackingInfo) {
      _trackingController?.add(trackingInfo);
    }).catchError((e) {
      _trackingController?.addError(e);
    });

    return _trackingController!.stream;
  }

  /// Calculate estimated arrival time
  DateTime? _calculateEstimatedArrival(Order order, DeliveryTracking? tracking) {
    if (tracking == null) return null;

    try {
      // Simple estimation based on distance and average speed
      // In production, you'd use Google Directions API for accurate ETA
      
      final currentLocation = tracking.location;
      final deliveryLocation = _parseDeliveryAddress(order.deliveryAddress);
      
      if (deliveryLocation == null) return null;

      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        deliveryLocation.latitude,
        deliveryLocation.longitude,
      );

      // Assume average speed of 30 km/h in urban areas
      const averageSpeedKmh = 30.0;
      final estimatedHours = distance / averageSpeedKmh;
      final estimatedMinutes = (estimatedHours * 60).round();

      return DateTime.now().add(Duration(minutes: estimatedMinutes));
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingService: Error calculating ETA', e);
      return null;
    }
  }

  /// Parse delivery address to get coordinates
  LatLng? _parseDeliveryAddress(Address? address) {
    try {
      if (address == null) return null;

      // For now, use mock coordinates based on city
      // In production, you'd geocode the actual address
      final city = address.city;

      switch (city.toLowerCase()) {
        case 'kuala lumpur':
          return const LatLng(3.1390, 101.6869);
        case 'petaling jaya':
          return const LatLng(3.1073, 101.6067);
        case 'shah alam':
          return const LatLng(3.0733, 101.5185);
        default:
          return const LatLng(3.1390, 101.6869); // Default to KL
      }
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingService: Error parsing delivery address', e);
      return null;
    }
  }

  /// Calculate distance between two points (Haversine formula)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const earthRadius = 6371.0; // Earth's radius in kilometers

    final dLat = _degreesToRadians(lat2 - lat1);
    final dLon = _degreesToRadians(lon2 - lon1);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_degreesToRadians(lat1)) * math.cos(_degreesToRadians(lat2)) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.asin(math.sqrt(a));

    return earthRadius * c;
  }

  double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180);
  }

  /// Get delivery route polyline points
  Future<List<LatLng>> getDeliveryRoute(String orderId) async {
    try {
      final trackingInfo = await getOrderDeliveryTracking(orderId);
      if (trackingInfo?.latestTracking == null || trackingInfo?.order.deliveryAddress == null) {
        return [];
      }

      final currentLocation = trackingInfo!.latestTracking!.location;
      final deliveryLocation = _parseDeliveryAddress(trackingInfo.order.deliveryAddress);

      if (deliveryLocation == null) return [];

      // For now, return a simple straight line route
      // TODO: Integrate with Google Directions API for actual route
      return [
        LatLng(currentLocation.latitude, currentLocation.longitude),
        deliveryLocation,
      ];
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingService: Error getting delivery route', e);
      return [];
    }
  }

  /// Get estimated delivery time based on current location and traffic
  Future<Duration?> getEstimatedDeliveryTime(String orderId) async {
    try {
      final trackingInfo = await getOrderDeliveryTracking(orderId);
      if (trackingInfo?.latestTracking == null) return null;

      final currentLocation = trackingInfo!.latestTracking!.location;
      final deliveryLocation = _parseDeliveryAddress(trackingInfo.order.deliveryAddress);

      if (deliveryLocation == null) return null;

      final distance = _calculateDistance(
        currentLocation.latitude,
        currentLocation.longitude,
        deliveryLocation.latitude,
        deliveryLocation.longitude,
      );

      // Estimate based on average speed in urban areas (25 km/h including traffic)
      final estimatedHours = distance / 25.0;
      final estimatedMinutes = (estimatedHours * 60).round();

      return Duration(minutes: estimatedMinutes);
    } catch (e) {
      _logger.error('CustomerDeliveryTrackingService: Error calculating estimated delivery time', e);
      return null;
    }
  }

  /// Stop real-time tracking
  void stopTracking() {
    _trackingSubscription?.cancel();
    _orderSubscription?.cancel();
    _trackingController?.close();
    _trackingSubscription = null;
    _orderSubscription = null;
    _trackingController = null;
    _logger.info('CustomerDeliveryTrackingService: Stopped real-time tracking');
  }

  /// Dispose resources
  void dispose() {
    stopTracking();
  }
}

/// Delivery tracking information model
class DeliveryTrackingInfo {
  final Order order;
  final Driver driver;
  final DeliveryTracking? latestTracking;
  final DateTime? estimatedArrival;

  const DeliveryTrackingInfo({
    required this.order,
    required this.driver,
    this.latestTracking,
    this.estimatedArrival,
  });

  /// Get current driver location
  LatLng? get currentDriverLocation {
    if (latestTracking != null) {
      return LatLng(
        latestTracking!.location.latitude,
        latestTracking!.location.longitude,
      );
    }
    return null;
  }

  /// Get delivery destination
  LatLng? get deliveryDestination {
    try {
      final address = order.deliveryAddress;

      // Use coordinates if available
      if (address.latitude != null && address.longitude != null) {
        return LatLng(address.latitude!, address.longitude!);
      }

      // Fallback to city-based coordinates
      final city = address.city;
      switch (city.toLowerCase()) {
        case 'kuala lumpur':
          return const LatLng(3.1390, 101.6869);
        case 'petaling jaya':
          return const LatLng(3.1073, 101.6067);
        case 'shah alam':
          return const LatLng(3.0733, 101.5185);
        case 'subang jaya':
          return const LatLng(3.0488, 101.5810);
        case 'klang':
          return const LatLng(3.0319, 101.4450);
        default:
          return const LatLng(3.1390, 101.6869); // Default to KL
      }
    } catch (e) {
      return const LatLng(3.1390, 101.6869); // Default to KL on error
    }
  }

  /// Check if driver is currently tracking
  bool get isDriverTracking {
    if (latestTracking == null) return false;
    
    final now = DateTime.now();
    final lastUpdate = latestTracking!.recordedAt;
    final timeDifference = now.difference(lastUpdate);
    
    // Consider tracking active if last update was within 5 minutes
    return timeDifference.inMinutes <= 5;
  }

  /// Get estimated time remaining
  String get estimatedTimeRemaining {
    if (estimatedArrival == null) return 'Calculating...';
    
    final now = DateTime.now();
    final remaining = estimatedArrival!.difference(now);
    
    if (remaining.isNegative) return 'Arriving soon';
    
    if (remaining.inHours > 0) {
      return '${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else {
      return '${remaining.inMinutes}m';
    }
  }
}
