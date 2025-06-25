import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Real-time service for driver notifications and updates
/// Handles Supabase real-time subscriptions for driver-related events
class DriverRealtimeService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Stream controllers for different types of real-time updates
  final StreamController<Map<String, dynamic>> _orderStatusController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _driverNotificationController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _locationUpdateController = StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _performanceUpdateController = StreamController.broadcast();
  
  // Subscription references for cleanup
  RealtimeChannel? _orderStatusChannel;
  RealtimeChannel? _driverNotificationChannel;
  RealtimeChannel? _locationTrackingChannel;
  RealtimeChannel? _performanceChannel;
  
  String? _currentDriverId;

  // Stream getters
  Stream<Map<String, dynamic>> get orderStatusUpdates => _orderStatusController.stream;
  Stream<Map<String, dynamic>> get driverNotifications => _driverNotificationController.stream;
  Stream<Map<String, dynamic>> get locationUpdates => _locationUpdateController.stream;
  Stream<Map<String, dynamic>> get performanceUpdates => _performanceUpdateController.stream;

  /// Initialize real-time subscriptions for a specific driver
  Future<void> initializeForDriver(String driverId) async {
    try {
      debugPrint('DriverRealtimeService: Initializing real-time subscriptions for driver: $driverId');
      
      // Clean up existing subscriptions
      await dispose();
      
      _currentDriverId = driverId;
      
      // Subscribe to order status changes for driver's orders
      await _subscribeToOrderStatusUpdates(driverId);
      
      // Subscribe to driver-specific notifications
      await _subscribeToDriverNotifications(driverId);
      
      // Subscribe to location tracking updates
      await _subscribeToLocationUpdates(driverId);
      
      // Subscribe to performance updates
      await _subscribeToPerformanceUpdates(driverId);
      
      debugPrint('DriverRealtimeService: All subscriptions initialized successfully');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error initializing subscriptions: $e');
      rethrow;
    }
  }

  /// Subscribe to order status changes for driver's assigned orders
  Future<void> _subscribeToOrderStatusUpdates(String driverId) async {
    try {
      _orderStatusChannel = _supabase
          .channel('driver_orders_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'orders',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'assigned_driver_id',
              value: driverId,
            ),
            callback: (payload) {
              debugPrint('DriverRealtimeService: Order status update received: ${payload.newRecord}');
              _orderStatusController.add({
                'type': 'order_status_update',
                'event': payload.eventType.name,
                'old_record': payload.oldRecord,
                'new_record': payload.newRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
          )
          .subscribe();

      debugPrint('DriverRealtimeService: Subscribed to order status updates');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error subscribing to order status updates: $e');
      rethrow;
    }
  }

  /// Subscribe to driver-specific notifications
  Future<void> _subscribeToDriverNotifications(String driverId) async {
    try {
      _driverNotificationChannel = _supabase
          .channel('driver_notifications_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'driver_notifications',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'driver_id',
              value: driverId,
            ),
            callback: (payload) {
              debugPrint('DriverRealtimeService: Driver notification received: ${payload.newRecord}');
              _driverNotificationController.add({
                'type': 'driver_notification',
                'notification': payload.newRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
          )
          .subscribe();

      debugPrint('DriverRealtimeService: Subscribed to driver notifications');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error subscribing to driver notifications: $e');
      rethrow;
    }
  }

  /// Subscribe to location tracking updates
  Future<void> _subscribeToLocationUpdates(String driverId) async {
    try {
      _locationTrackingChannel = _supabase
          .channel('driver_tracking_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.insert,
            schema: 'public',
            table: 'delivery_tracking',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'driver_id',
              value: driverId,
            ),
            callback: (payload) {
              debugPrint('DriverRealtimeService: Location update received: ${payload.newRecord}');
              _locationUpdateController.add({
                'type': 'location_update',
                'tracking_data': payload.newRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
          )
          .subscribe();

      debugPrint('DriverRealtimeService: Subscribed to location updates');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error subscribing to location updates: $e');
      rethrow;
    }
  }

  /// Subscribe to performance metric updates
  Future<void> _subscribeToPerformanceUpdates(String driverId) async {
    try {
      _performanceChannel = _supabase
          .channel('driver_performance_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'driver_performance',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'driver_id',
              value: driverId,
            ),
            callback: (payload) {
              debugPrint('DriverRealtimeService: Performance update received: ${payload.newRecord}');
              _performanceUpdateController.add({
                'type': 'performance_update',
                'event': payload.eventType.name,
                'performance_data': payload.newRecord,
                'timestamp': DateTime.now().toIso8601String(),
              });
            },
          )
          .subscribe();

      debugPrint('DriverRealtimeService: Subscribed to performance updates');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error subscribing to performance updates: $e');
      rethrow;
    }
  }

  /// Send real-time location update
  Future<void> sendLocationUpdate(String driverId, String orderId, double latitude, double longitude, {double? speed, double? heading, double? accuracy}) async {
    try {
      debugPrint('DriverRealtimeService: Sending location update for driver: $driverId');
      
      await _supabase.from('delivery_tracking').insert({
        'driver_id': driverId,
        'order_id': orderId,
        'location': 'POINT($longitude $latitude)',
        'speed': speed,
        'heading': heading,
        'accuracy': accuracy,
        'recorded_at': DateTime.now().toIso8601String(),
      });

      debugPrint('DriverRealtimeService: Location update sent successfully');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error sending location update: $e');
      rethrow;
    }
  }

  /// Mark notification as read
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      debugPrint('DriverRealtimeService: Marking notification as read: $notificationId');
      
      await _supabase
          .from('driver_notifications')
          .update({'is_read': true})
          .eq('id', notificationId);

      debugPrint('DriverRealtimeService: Notification marked as read');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error marking notification as read: $e');
      rethrow;
    }
  }

  /// Get unread notifications count
  Future<int> getUnreadNotificationsCount(String driverId) async {
    try {
      final response = await _supabase
          .from('driver_notifications')
          .select('id')
          .eq('driver_id', driverId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('DriverRealtimeService: Error getting unread notifications count: $e');
      return 0;
    }
  }

  /// Get recent notifications
  Future<List<Map<String, dynamic>>> getRecentNotifications(String driverId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('driver_notifications')
          .select('*')
          .eq('driver_id', driverId)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('DriverRealtimeService: Error getting recent notifications: $e');
      return [];
    }
  }

  /// Update driver status with real-time broadcast
  Future<void> updateDriverStatus(String driverId, String status) async {
    try {
      debugPrint('DriverRealtimeService: Updating driver status to: $status');
      
      await _supabase
          .from('drivers')
          .update({
            'status': status,
            'last_seen': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', driverId);

      debugPrint('DriverRealtimeService: Driver status updated successfully');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error updating driver status: $e');
      rethrow;
    }
  }

  /// Check if driver has active real-time subscriptions
  bool get hasActiveSubscriptions {
    return _orderStatusChannel != null &&
           _driverNotificationChannel != null &&
           _locationTrackingChannel != null &&
           _performanceChannel != null;
  }

  /// Get current driver ID
  String? get currentDriverId => _currentDriverId;

  /// Dispose all subscriptions and clean up resources
  Future<void> dispose() async {
    try {
      debugPrint('DriverRealtimeService: Disposing real-time subscriptions');
      
      // Unsubscribe from all channels
      await _orderStatusChannel?.unsubscribe();
      await _driverNotificationChannel?.unsubscribe();
      await _locationTrackingChannel?.unsubscribe();
      await _performanceChannel?.unsubscribe();
      
      // Clear channel references
      _orderStatusChannel = null;
      _driverNotificationChannel = null;
      _locationTrackingChannel = null;
      _performanceChannel = null;
      
      _currentDriverId = null;
      
      debugPrint('DriverRealtimeService: All subscriptions disposed');
    } catch (e) {
      debugPrint('DriverRealtimeService: Error disposing subscriptions: $e');
    }
  }

  /// Close all stream controllers
  void closeStreams() {
    _orderStatusController.close();
    _driverNotificationController.close();
    _locationUpdateController.close();
    _performanceUpdateController.close();
  }
}
