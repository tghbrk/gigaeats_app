import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_order.dart';

import 'geocoding_service.dart';
import 'adaptive_location_service.dart';

/// Service for GPS-based proximity detection and automatic status updates
/// Handles geofencing logic for driver arrival detection
class DriverProximityService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final GeocodingService _geocodingService;
  final AdaptiveLocationService _adaptiveLocationService;
  
  // Configurable proximity thresholds
  static const double arrivalRadiusMeters = 100.0;
  static const double accuracyThresholdMeters = 50.0;
  static const int minReadingsForConfirmation = 3;
  static const Duration proximityCheckInterval = Duration(seconds: 10);
  
  // Active monitoring state
  StreamSubscription<Position>? _proximitySubscription;
  Timer? _proximityTimer;
  String? _currentOrderId;
  String? _currentDriverId;
  bool _isMonitoring = false;
  
  // Arrival confirmation tracking
  final Map<String, List<DateTime>> _arrivalReadings = {};
  
  DriverProximityService({
    GeocodingService? geocodingService,
    AdaptiveLocationService? adaptiveLocationService,
  }) : _geocodingService = geocodingService ?? _createDefaultGeocodingService(),
       _adaptiveLocationService = adaptiveLocationService ?? AdaptiveLocationService();

  /// Create default geocoding service
  static GeocodingService _createDefaultGeocodingService() {
    // This will be initialized properly when SharedPreferences is available
    // For now, we'll handle this in the provider
    throw UnimplementedError('GeocodingService must be provided');
  }

  /// Start proximity monitoring for an active order
  Future<bool> startProximityMonitoring(String driverId, String orderId) async {
    try {
      debugPrint('DriverProximityService: Starting proximity monitoring for order: $orderId');
      
      // Stop any existing monitoring
      await stopProximityMonitoring();
      
      _currentDriverId = driverId;
      _currentOrderId = orderId;
      _isMonitoring = true;
      
      // Start adaptive location monitoring for better battery efficiency
      final adaptiveStarted = await _adaptiveLocationService.startAdaptiveMonitoring(
        orderId,
        DriverOrderStatus.assigned, // Default status, will be updated as needed
      );

      if (!adaptiveStarted) {
        debugPrint('DriverProximityService: Failed to start adaptive location monitoring, falling back to basic monitoring');

        // Fallback to basic monitoring
        _proximityTimer = Timer.periodic(proximityCheckInterval, (timer) async {
          await _checkProximity();
        });

        _proximitySubscription = Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.medium, // Use medium for better battery life
            distanceFilter: 10, // Update every 10 meters for efficiency
          ),
        ).listen(
          (Position position) async {
            await _handleLocationUpdate(position);
          },
          onError: (error) {
            debugPrint('DriverProximityService: Location stream error: $error');
          },
        );
      } else {
        // Use adaptive location service for position updates
        _proximityTimer = Timer.periodic(proximityCheckInterval, (timer) async {
          final position = _adaptiveLocationService.currentPosition;
          if (position != null) {
            await _handleLocationUpdate(position);
          }
        });
      }
      
      debugPrint('DriverProximityService: Proximity monitoring started successfully');
      return true;
    } catch (e) {
      debugPrint('DriverProximityService: Error starting proximity monitoring: $e');
      return false;
    }
  }
  
  /// Stop proximity monitoring
  Future<void> stopProximityMonitoring() async {
    debugPrint('DriverProximityService: Stopping proximity monitoring');

    _proximitySubscription?.cancel();
    _proximityTimer?.cancel();

    // Stop adaptive location monitoring
    await _adaptiveLocationService.stopMonitoring();

    _proximitySubscription = null;
    _proximityTimer = null;
    _currentOrderId = null;
    _currentDriverId = null;
    _isMonitoring = false;
    _arrivalReadings.clear();
  }
  
  /// Check if driver is within arrival radius of vendor location
  Future<bool> checkArrivalAtVendor(String orderId, Position driverLocation) async {
    try {
      final vendorLocation = await _getVendorLocation(orderId);
      if (vendorLocation == null) return false;
      
      final distance = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        vendorLocation['latitude']!.toDouble(),
        vendorLocation['longitude']!.toDouble(),
      );

      debugPrint('DriverProximityService: Distance to vendor: ${distance.toStringAsFixed(1)}m');

      return distance <= arrivalRadiusMeters &&
             driverLocation.accuracy <= accuracyThresholdMeters;
    } catch (e) {
      debugPrint('DriverProximityService: Error checking vendor arrival: $e');
      return false;
    }
  }
  
  /// Check if driver is within arrival radius of customer location
  Future<bool> checkArrivalAtCustomer(String orderId, Position driverLocation) async {
    try {
      final customerLocation = await _getCustomerLocation(orderId);
      if (customerLocation == null) return false;
      
      final distance = Geolocator.distanceBetween(
        driverLocation.latitude,
        driverLocation.longitude,
        customerLocation['latitude']!.toDouble(),
        customerLocation['longitude']!.toDouble(),
      );

      debugPrint('DriverProximityService: Distance to customer: ${distance.toStringAsFixed(1)}m');

      return distance <= arrivalRadiusMeters &&
             driverLocation.accuracy <= accuracyThresholdMeters;
    } catch (e) {
      debugPrint('DriverProximityService: Error checking customer arrival: $e');
      return false;
    }
  }
  
  /// Handle location updates and check for arrivals
  Future<void> _handleLocationUpdate(Position position) async {
    if (!_isMonitoring || _currentOrderId == null) return;
    
    try {
      // Get current order status
      final order = await _getCurrentOrder();
      if (order == null) return;
      
      // Check for arrivals based on current status
      if (order.status == DriverOrderStatus.onRouteToVendor) {
        final arrivedAtVendor = await checkArrivalAtVendor(_currentOrderId!, position);
        if (arrivedAtVendor) {
          await _confirmArrival('vendor', DriverOrderStatus.arrivedAtVendor);
        }
      } else if (order.status == DriverOrderStatus.onRouteToCustomer) {
        final arrivedAtCustomer = await checkArrivalAtCustomer(_currentOrderId!, position);
        if (arrivedAtCustomer) {
          await _confirmArrival('customer', DriverOrderStatus.arrivedAtCustomer);
        }
      }
    } catch (e) {
      debugPrint('DriverProximityService: Error handling location update: $e');
    }
  }
  
  /// Periodic proximity check (backup to location stream)
  Future<void> _checkProximity() async {
    if (!_isMonitoring || _currentOrderId == null) return;
    
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      
      await _handleLocationUpdate(position);
    } catch (e) {
      debugPrint('DriverProximityService: Error in periodic proximity check: $e');
    }
  }
  
  /// Confirm arrival with multiple readings to prevent false positives
  Future<void> _confirmArrival(String locationType, DriverOrderStatus newStatus) async {
    final key = '${_currentOrderId}_$locationType';
    final now = DateTime.now();
    
    // Add reading
    _arrivalReadings[key] ??= [];
    _arrivalReadings[key]!.add(now);
    
    // Remove old readings (older than 1 minute)
    _arrivalReadings[key]!.removeWhere(
      (reading) => now.difference(reading).inMinutes > 1,
    );
    
    // Check if we have enough confirmations
    if (_arrivalReadings[key]!.length >= minReadingsForConfirmation) {
      debugPrint('DriverProximityService: Confirmed arrival at $locationType');
      
      // Trigger status update
      await _updateOrderStatus(newStatus);
      
      // Clear readings for this location
      _arrivalReadings.remove(key);
    }
  }
  
  /// Update order status automatically
  Future<void> _updateOrderStatus(DriverOrderStatus newStatus) async {
    try {
      if (_currentOrderId == null || _currentDriverId == null) return;
      
      debugPrint('DriverProximityService: Auto-updating status to ${newStatus.displayName}');
      
      // Call the order update RPC
      await _supabase.rpc('update_driver_order_status', params: {
        'order_id': _currentOrderId,
        'new_status': newStatus.value,
        'driver_id': _currentDriverId,
      });
      
      debugPrint('DriverProximityService: Status updated successfully');
    } catch (e) {
      debugPrint('DriverProximityService: Error updating order status: $e');
    }
  }
  
  /// Get current order details
  Future<DriverOrder?> _getCurrentOrder() async {
    try {
      if (_currentOrderId == null) return null;
      
      final response = await _supabase
          .from('orders')
          .select('''
            id,
            status,
            vendor_name,
            delivery_address,
            vendor:vendors!orders_vendor_id_fkey(
              business_address
            )
          ''')
          .eq('id', _currentOrderId!)
          .single();
      
      return DriverOrder.fromJson({
        ...response,
        'status': response['status'],
        'order_number': 'AUTO-${response['id'].substring(0, 8)}',
        'customer_name': 'Customer',
        'total_amount': 0.0,
        'delivery_fee': 0.0,
        'created_at': DateTime.now().toIso8601String(),
        'vendor_address': response['vendor']?['business_address'],
      });
    } catch (e) {
      debugPrint('DriverProximityService: Error getting current order: $e');
      return null;
    }
  }
  
  /// Get vendor location coordinates
  Future<Map<String, double>?> _getVendorLocation(String orderId) async {
    try {
      // Get vendor address from order
      final response = await _supabase
          .from('orders')
          .select('vendor_address, vendor_name')
          .eq('id', orderId)
          .single();

      String? address = response['vendor_address'] as String?;
      if (address == null || address.isEmpty) {
        address = response['vendor_name'] as String?;
      }

      if (address == null || address.isEmpty) {
        debugPrint('DriverProximityService: No vendor address found for order $orderId');
        return null;
      }

      // Geocode the address
      final result = await _geocodingService.geocodeAddress(address);
      if (result != null) {
        debugPrint('DriverProximityService: Geocoded vendor address "$address" to ${result.latitude}, ${result.longitude}');
        return {
          'latitude': result.latitude,
          'longitude': result.longitude,
        };
      } else {
        debugPrint('DriverProximityService: Failed to geocode vendor address: $address');
        return null;
      }
    } catch (e) {
      debugPrint('DriverProximityService: Error getting vendor location: $e');
      return null;
    }
  }
  
  /// Get customer location coordinates
  Future<Map<String, double>?> _getCustomerLocation(String orderId) async {
    try {
      // Get delivery address from order
      final response = await _supabase
          .from('orders')
          .select('delivery_address')
          .eq('id', orderId)
          .single();

      final deliveryAddress = response['delivery_address'];
      String? address;

      // Handle different delivery address formats
      if (deliveryAddress is String) {
        address = deliveryAddress;
      } else if (deliveryAddress is Map) {
        // If it's a JSON object, try to extract the address
        address = deliveryAddress['address'] as String? ??
                 deliveryAddress['full_address'] as String? ??
                 deliveryAddress['street'] as String?;
      }

      if (address == null || address.isEmpty) {
        debugPrint('DriverProximityService: No delivery address found for order $orderId');
        return null;
      }

      // Geocode the address
      final result = await _geocodingService.geocodeAddress(address);
      if (result != null) {
        debugPrint('DriverProximityService: Geocoded delivery address "$address" to ${result.latitude}, ${result.longitude}');
        return {
          'latitude': result.latitude,
          'longitude': result.longitude,
        };
      } else {
        debugPrint('DriverProximityService: Failed to geocode delivery address: $address');
        return null;
      }
    } catch (e) {
      debugPrint('DriverProximityService: Error getting customer location: $e');
      return null;
    }
  }
  
  /// Check if proximity monitoring is active
  bool get isMonitoring => _isMonitoring;
  
  /// Get current monitored order ID
  String? get currentOrderId => _currentOrderId;
}
