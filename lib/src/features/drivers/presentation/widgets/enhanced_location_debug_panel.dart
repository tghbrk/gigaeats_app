import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../data/models/driver_order.dart';
import '../../data/models/geofence.dart';
import '../providers/enhanced_location_provider.dart';

/// Debug panel for testing enhanced location service functionality
/// This widget demonstrates the integration of geofencing, battery optimization, and automatic status transitions
class EnhancedLocationDebugPanel extends ConsumerStatefulWidget {
  final String driverId;
  final String? orderId;
  final String? batchId;

  const EnhancedLocationDebugPanel({
    super.key,
    required this.driverId,
    this.orderId,
    this.batchId,
  });

  @override
  ConsumerState<EnhancedLocationDebugPanel> createState() => _EnhancedLocationDebugPanelState();
}

class _EnhancedLocationDebugPanelState extends ConsumerState<EnhancedLocationDebugPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final locationState = ref.watch(enhancedLocationProvider);
    final locationNotifier = ref.read(enhancedLocationProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: ExpansionTile(
        title: const Text(
          '🚗 Enhanced Location Debug Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          locationState.isTracking 
            ? '✅ Tracking Active (${locationState.isEnhancedMode ? "Enhanced" : "Basic"})'
            : '❌ Tracking Inactive',
        ),
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status Section
                _buildStatusSection(locationState),
                const SizedBox(height: 16),
                
                // Controls Section
                _buildControlsSection(locationState, locationNotifier),
                const SizedBox(height: 16),
                
                // Battery Section
                _buildBatterySection(locationState),
                const SizedBox(height: 16),
                
                // Geofences Section
                _buildGeofencesSection(locationState, locationNotifier),
                const SizedBox(height: 16),
                
                // Recent Events Section
                _buildEventsSection(locationState),
                
                // Error Section
                if (locationState.error != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorSection(locationState),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusSection(EnhancedLocationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📍 Location Status', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoRow('Tracking', state.isTracking ? 'Active' : 'Inactive'),
        _buildInfoRow('Mode', state.isEnhancedMode ? 'Enhanced' : 'Basic'),
        _buildInfoRow('Driver ID', state.currentDriverId ?? 'None'),
        _buildInfoRow('Order ID', state.currentOrderId ?? 'None'),
        _buildInfoRow('Batch ID', state.currentBatchId ?? 'None'),
        if (state.currentPosition != null) ...[
          _buildInfoRow('Latitude', state.currentPosition!.latitude.toStringAsFixed(6)),
          _buildInfoRow('Longitude', state.currentPosition!.longitude.toStringAsFixed(6)),
          _buildInfoRow('Accuracy', '${state.currentPosition!.accuracy.toStringAsFixed(1)}m'),
          _buildInfoRow('Speed', '${(state.currentPosition!.speed * 3.6).toStringAsFixed(1)} km/h'),
        ],
      ],
    );
  }

  Widget _buildControlsSection(EnhancedLocationState state, EnhancedLocationNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🎮 Controls', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ElevatedButton.icon(
              onPressed: state.isTracking ? null : () => _startEnhancedTracking(notifier),
              icon: const Icon(Icons.play_arrow),
              label: const Text('Start Enhanced'),
            ),
            ElevatedButton.icon(
              onPressed: state.isTracking ? null : () => _startBasicTracking(notifier),
              icon: const Icon(Icons.location_on),
              label: const Text('Start Basic'),
            ),
            ElevatedButton.icon(
              onPressed: !state.isTracking ? null : () => notifier.stopLocationTracking(),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
            ElevatedButton.icon(
              onPressed: () => notifier.getCurrentLocation(),
              icon: const Icon(Icons.my_location),
              label: const Text('Get Location'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBatterySection(EnhancedLocationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('🔋 Battery Optimization', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoRow('Battery Level', '${state.batteryLevel}%'),
        _buildInfoRow('Low Battery', state.isLowBattery ? 'Yes' : 'No'),
        _buildInfoRow('Charging', state.isCharging ? 'Yes' : 'No'),
        if (state.batteryOptimizationSettings != null) ...[
          _buildInfoRow('Power Saving', state.batteryOptimizationSettings!['power_saving_active']?.toString() ?? 'No'),
          _buildInfoRow('Recommended Accuracy', state.batteryOptimizationSettings!['recommended_accuracy'] ?? 'Unknown'),
          _buildInfoRow('Recommended Interval', '${state.batteryOptimizationSettings!['recommended_interval_seconds'] ?? 15}s'),
        ],
      ],
    );
  }

  Widget _buildGeofencesSection(EnhancedLocationState state, EnhancedLocationNotifier notifier) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🎯 Geofences', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addTestGeofence(notifier),
              icon: const Icon(Icons.add_location),
              label: const Text('Add Test'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildInfoRow('Active Geofences', state.activeGeofences.length.toString()),
        if (state.activeGeofences.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...state.activeGeofences.map((geofence) => Card(
            child: ListTile(
              dense: true,
              title: Text(geofence.id),
              subtitle: Text('${geofence.center.latitude.toStringAsFixed(4)}, ${geofence.center.longitude.toStringAsFixed(4)} (${geofence.radius}m)'),
              trailing: IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => notifier.removeGeofence(geofence.id),
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildEventsSection(EnhancedLocationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('📋 Recent Events', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        _buildInfoRow('Recent Events', state.recentEvents.length.toString()),
        if (state.recentEvents.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...state.recentEvents.take(3).map((event) => Card(
            child: ListTile(
              dense: true,
              leading: Icon(
                event.isEntry ? Icons.login : Icons.logout,
                color: event.isEntry ? Colors.green : Colors.red,
              ),
              title: Text('${event.typeDisplayName} ${event.geofenceId}'),
              subtitle: Text(
                '${event.timestamp.toLocal().toString().substring(11, 19)} - '
                '${event.latitude.toStringAsFixed(4)}, ${event.longitude.toStringAsFixed(4)}',
              ),
            ),
          )),
        ],
      ],
    );
  }

  Widget _buildErrorSection(EnhancedLocationState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('❌ Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            border: Border.all(color: Colors.red.shade200),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            state.error!,
            style: TextStyle(color: Colors.red.shade700),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startEnhancedTracking(EnhancedLocationNotifier notifier) async {
    final geofences = <Geofence>[];
    
    // Add test geofences if we have order ID
    if (widget.orderId != null) {
      // Add a test vendor geofence (using current location + 100m offset)
      final currentPosition = await Geolocator.getCurrentPosition();
      geofences.add(Geofence.vendorPickup(
        orderId: widget.orderId!,
        location: GeofenceLocation(
          latitude: currentPosition.latitude + 0.001, // ~100m north
          longitude: currentPosition.longitude,
        ),
        description: 'Test Vendor Location',
      ));
      
      geofences.add(Geofence.customerDelivery(
        orderId: widget.orderId!,
        location: GeofenceLocation(
          latitude: currentPosition.latitude - 0.001, // ~100m south
          longitude: currentPosition.longitude,
        ),
        description: 'Test Customer Location',
      ));
    }
    
    await notifier.startEnhancedTracking(
      driverId: widget.driverId,
      orderId: widget.orderId,
      batchId: widget.batchId,
      geofences: geofences,
      intervalSeconds: 10,
      enableGeofencing: true,
      enableBatteryOptimization: true,
    );
  }

  Future<void> _startBasicTracking(EnhancedLocationNotifier notifier) async {
    await notifier.startLocationTracking(
      widget.driverId,
      widget.orderId ?? 'test-order',
      intervalSeconds: 30,
    );
  }

  Future<void> _addTestGeofence(EnhancedLocationNotifier notifier) async {
    try {
      final currentPosition = await Geolocator.getCurrentPosition();
      final testGeofence = Geofence(
        id: 'test_${DateTime.now().millisecondsSinceEpoch}',
        center: GeofenceLocation(
          latitude: currentPosition.latitude,
          longitude: currentPosition.longitude,
        ),
        radius: 50,
        events: [GeofenceEventType.enter, GeofenceEventType.exit],
        description: 'Test Geofence',
        metadata: {
          'type': 'test',
          'created_at': DateTime.now().toIso8601String(),
        },
      );
      
      await notifier.addGeofence(testGeofence);
    } catch (e) {
      debugPrint('Error adding test geofence: $e');
    }
  }
}
