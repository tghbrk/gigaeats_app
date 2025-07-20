import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/geofence.dart';
import '../models/geofence_event.dart';

/// Geofencing service for automatic status transitions and location-based triggers
class GeofencingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  
  // Active geofences
  final List<Geofence> _activeGeofences = [];
  final Map<String, GeofenceEvent> _lastEvents = {};
  final Map<String, DateTime> _entryTimes = {};
  
  // Event streaming
  final StreamController<GeofenceEvent> _eventController = StreamController<GeofenceEvent>.broadcast();
  Stream<GeofenceEvent> get eventStream => _eventController.stream;
  
  // Configuration
  static const Duration _dwellThreshold = Duration(seconds: 30);
  
  bool _isInitialized = false;

  /// Initialize the geofencing service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    debugPrint('🎯 [GEOFENCING] Initializing geofencing service');
    _isInitialized = true;
    
    debugPrint('🎯 [GEOFENCING] Geofencing service initialized');
  }

  /// Set up multiple geofences
  Future<void> setupGeofences(List<Geofence> geofences) async {
    debugPrint('🎯 [GEOFENCING] Setting up ${geofences.length} geofences');
    
    await clearGeofences();
    
    for (final geofence in geofences) {
      await addGeofence(geofence);
    }
    
    debugPrint('🎯 [GEOFENCING] Setup complete: ${_activeGeofences.length} active geofences');
  }

  /// Add a single geofence
  Future<void> addGeofence(Geofence geofence) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    // Remove existing geofence with same ID
    _activeGeofences.removeWhere((g) => g.id == geofence.id);
    
    // Add new geofence if active and not expired
    if (geofence.isActive && !geofence.isExpired) {
      _activeGeofences.add(geofence);
      debugPrint('🎯 [GEOFENCING] Added geofence: ${geofence.id} at ${geofence.center} (${geofence.radius}m)');
    }
  }

  /// Remove a geofence
  Future<void> removeGeofence(String geofenceId) async {
    _activeGeofences.removeWhere((g) => g.id == geofenceId);
    _lastEvents.remove(geofenceId);
    _entryTimes.remove(geofenceId);
    
    debugPrint('🎯 [GEOFENCING] Removed geofence: $geofenceId');
  }

  /// Clear all geofences
  Future<void> clearGeofences() async {
    final count = _activeGeofences.length;
    _activeGeofences.clear();
    _lastEvents.clear();
    _entryTimes.clear();
    
    debugPrint('🎯 [GEOFENCING] Cleared $count geofences');
  }

  /// Check geofences against current position
  Future<void> checkGeofences(Position position) async {
    if (!_isInitialized || _activeGeofences.isEmpty) return;
    
    final currentTime = DateTime.now();
    
    for (final geofence in _activeGeofences) {
      // Skip expired geofences
      if (geofence.isExpired) continue;
      
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.center.latitude,
        geofence.center.longitude,
      );
      
      final isInside = distance <= geofence.radius;
      final wasInside = _entryTimes.containsKey(geofence.id);
      
      // Handle entry event
      if (isInside && !wasInside) {
        await _handleGeofenceEntry(geofence, position, currentTime);
      }
      // Handle exit event
      else if (!isInside && wasInside) {
        await _handleGeofenceExit(geofence, position, currentTime);
      }
      // Handle dwell event
      else if (isInside && wasInside) {
        await _handleGeofenceDwell(geofence, position, currentTime);
      }
    }
  }

  /// Handle geofence entry
  Future<void> _handleGeofenceEntry(Geofence geofence, Position position, DateTime timestamp) async {
    if (!geofence.events.contains(GeofenceEventType.enter)) return;
    
    _entryTimes[geofence.id] = timestamp;
    
    final event = GeofenceEvent.fromPosition(
      geofenceId: geofence.id,
      type: GeofenceEventType.enter,
      position: position,
      orderId: geofence.orderId,
      batchId: geofence.batchId,
      metadata: {
        'geofence_radius': geofence.radius,
        'geofence_type': geofence.type,
        'auto_transition': geofence.autoTransitionStatus,
      },
    );
    
    _lastEvents[geofence.id] = event;
    _eventController.add(event);
    
    // Save to database
    await _saveEventToDatabase(event);
    
    debugPrint('🎯 [GEOFENCING] ENTER: ${geofence.id} at ${position.latitude}, ${position.longitude}');
  }

  /// Handle geofence exit
  Future<void> _handleGeofenceExit(Geofence geofence, Position position, DateTime timestamp) async {
    if (!geofence.events.contains(GeofenceEventType.exit)) return;
    
    final entryTime = _entryTimes.remove(geofence.id);
    final dwellDuration = entryTime != null ? timestamp.difference(entryTime) : null;
    
    final event = GeofenceEvent.fromPosition(
      geofenceId: geofence.id,
      type: GeofenceEventType.exit,
      position: position,
      orderId: geofence.orderId,
      batchId: geofence.batchId,
      metadata: {
        'geofence_radius': geofence.radius,
        'geofence_type': geofence.type,
        'dwell_duration_seconds': dwellDuration?.inSeconds,
      },
    );
    
    _lastEvents[geofence.id] = event;
    _eventController.add(event);
    
    // Save to database
    await _saveEventToDatabase(event);
    
    debugPrint('🎯 [GEOFENCING] EXIT: ${geofence.id} (dwell: ${dwellDuration?.inSeconds}s)');
  }

  /// Handle geofence dwell
  Future<void> _handleGeofenceDwell(Geofence geofence, Position position, DateTime timestamp) async {
    if (!geofence.events.contains(GeofenceEventType.dwell)) return;
    
    final entryTime = _entryTimes[geofence.id];
    if (entryTime == null) return;
    
    final dwellDuration = timestamp.difference(entryTime);
    
    // Only trigger dwell event after threshold and if not already triggered recently
    if (dwellDuration >= _dwellThreshold) {
      final lastEvent = _lastEvents[geofence.id];
      if (lastEvent?.type == GeofenceEventType.dwell) {
        final timeSinceLastDwell = timestamp.difference(lastEvent!.timestamp);
        if (timeSinceLastDwell < _dwellThreshold) return; // Too soon for another dwell event
      }
      
      final event = GeofenceEvent.fromPosition(
        geofenceId: geofence.id,
        type: GeofenceEventType.dwell,
        position: position,
        orderId: geofence.orderId,
        batchId: geofence.batchId,
        metadata: {
          'geofence_radius': geofence.radius,
          'geofence_type': geofence.type,
          'dwell_duration_seconds': dwellDuration.inSeconds,
        },
      );
      
      _lastEvents[geofence.id] = event;
      _eventController.add(event);
      
      // Save to database
      await _saveEventToDatabase(event);
      
      debugPrint('🎯 [GEOFENCING] DWELL: ${geofence.id} (${dwellDuration.inSeconds}s)');
    }
  }

  /// Save geofence event to database
  Future<void> _saveEventToDatabase(GeofenceEvent event) async {
    try {
      await _supabase.from('geofence_events').insert({
        'id': event.id,
        'geofence_id': event.geofenceId,
        'event_type': event.type.name,
        'latitude': event.latitude,
        'longitude': event.longitude,
        'accuracy': event.accuracy,
        'timestamp': event.timestamp.toIso8601String(),
        'driver_id': event.driverId,
        'order_id': event.orderId,
        'batch_id': event.batchId,
        'speed': event.speed,
        'heading': event.heading,
        'metadata': event.metadata,
      });
    } catch (e) {
      debugPrint('❌ [GEOFENCING] Error saving event to database: $e');
    }
  }

  /// Get active geofences
  List<Geofence> get activeGeofences => List.unmodifiable(_activeGeofences);

  /// Get geofence by ID
  Geofence? getGeofence(String id) {
    try {
      return _activeGeofences.firstWhere((g) => g.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Check if position is inside any geofence
  bool isInsideAnyGeofence(Position position) {
    return _activeGeofences.any((geofence) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.center.latitude,
        geofence.center.longitude,
      );
      return distance <= geofence.radius;
    });
  }

  /// Get geofences containing the position
  List<Geofence> getGeofencesContaining(Position position) {
    return _activeGeofences.where((geofence) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.center.latitude,
        geofence.center.longitude,
      );
      return distance <= geofence.radius;
    }).toList();
  }

  /// Get distance to nearest geofence
  double? getDistanceToNearestGeofence(Position position) {
    if (_activeGeofences.isEmpty) return null;
    
    double minDistance = double.infinity;
    
    for (final geofence in _activeGeofences) {
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        geofence.center.latitude,
        geofence.center.longitude,
      );
      
      // Distance to geofence boundary
      final distanceToBoundary = max(0.0, distance - geofence.radius);
      minDistance = min(minDistance, distanceToBoundary);
    }
    
    return minDistance == double.infinity ? null : minDistance;
  }

  /// Dispose resources
  Future<void> dispose() async {
    debugPrint('🎯 [GEOFENCING] Disposing geofencing service');
    
    await clearGeofences();
    await _eventController.close();
    _isInitialized = false;
  }
}
