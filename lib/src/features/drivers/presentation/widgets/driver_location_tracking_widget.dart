import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../providers/driver_location_providers.dart';

/// Widget for driver location tracking controls
/// Provides UI for starting/stopping location tracking and viewing status
class DriverLocationTrackingWidget extends ConsumerWidget {
  final String? orderId;
  final VoidCallback? onTrackingStarted;
  final VoidCallback? onTrackingStopped;

  const DriverLocationTrackingWidget({
    super.key,
    this.orderId,
    this.onTrackingStarted,
    this.onTrackingStopped,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isTracking = ref.watch(locationTrackingStatusProvider);
    final locationPermissionsAsync = ref.watch(locationPermissionsProvider);
    final currentLocation = ref.watch(driverCurrentLocationProvider);
    final locationActions = ref.read(driverLocationActionsProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: isTracking ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  'Location Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildStatusChip(isTracking, theme),
              ],
            ),
            const SizedBox(height: 16),
            
            // Location permissions status
            locationPermissionsAsync.when(
              data: (permission) => _buildPermissionsStatus(
                permission == LocationPermission.whileInUse || permission == LocationPermission.always,
                theme
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => Text(
                'Error checking permissions: $error',
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Current location status
            currentLocation != null
                ? _buildLocationStatus({
                    'latitude': currentLocation.latitude,
                    'longitude': currentLocation.longitude,
                    'last_seen': DateTime.now().toIso8601String(),
                  }, theme)
                : const Row(
                    children: [
                      Icon(Icons.location_off, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Location not available'),
                    ],
                  ),
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: _buildTrackingButton(
                    context,
                    ref,
                    isTracking,
                    locationActions,
                  ),
                ),
                const SizedBox(width: 8),
                _buildRefreshButton(context, ref, locationActions),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(bool isTracking, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isTracking ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isTracking ? Colors.green : Colors.grey,
          width: 1,
        ),
      ),
      child: Text(
        isTracking ? 'Active' : 'Inactive',
        style: theme.textTheme.bodySmall?.copyWith(
          color: isTracking ? Colors.green : Colors.grey,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPermissionsStatus(bool hasPermissions, ThemeData theme) {
    return Row(
      children: [
        Icon(
          hasPermissions ? Icons.check_circle : Icons.error,
          color: hasPermissions ? Colors.green : Colors.red,
          size: 16,
        ),
        const SizedBox(width: 8),
        Text(
          hasPermissions ? 'Location permissions granted' : 'Location permissions required',
          style: theme.textTheme.bodySmall?.copyWith(
            color: hasPermissions ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  Widget _buildLocationStatus(Map<String, dynamic>? location, ThemeData theme) {
    if (location == null) {
      return Row(
        children: [
          Icon(Icons.location_off, color: Colors.grey, size: 16),
          const SizedBox(width: 8),
          Text(
            'No location data available',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      );
    }

    final lastSeen = location['last_seen'] as String?;
    final lastSeenTime = lastSeen != null ? DateTime.parse(lastSeen) : null;
    final timeAgo = lastSeenTime != null 
        ? _formatTimeAgo(DateTime.now().difference(lastSeenTime))
        : 'Unknown';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.location_on, color: Colors.blue, size: 16),
            const SizedBox(width: 8),
            Text(
              'Last location update: $timeAgo',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
        if (lastSeenTime != null) ...[
          const SizedBox(height: 4),
          Text(
            'Updated at: ${lastSeenTime.toLocal().toString().substring(0, 19)}',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Widget _buildTrackingButton(
    BuildContext context,
    WidgetRef ref,
    bool isTracking,
    DriverLocationActionsService locationActions,
  ) {
    return ElevatedButton.icon(
      onPressed: () async {
        if (isTracking) {
          await _stopTracking(context, ref, locationActions);
        } else {
          await _startTracking(context, ref, locationActions);
        }
      },
      icon: Icon(isTracking ? Icons.stop : Icons.play_arrow),
      label: Text(isTracking ? 'Stop Tracking' : 'Start Tracking'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isTracking ? Colors.red : Colors.green,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildRefreshButton(
    BuildContext context,
    WidgetRef ref,
    DriverLocationActionsService locationActions,
  ) {
    return IconButton(
      onPressed: () async {
        await _refreshLocation(context, ref, locationActions);
      },
      icon: const Icon(Icons.refresh),
      tooltip: 'Refresh location',
    );
  }

  Future<void> _startTracking(
    BuildContext context,
    WidgetRef ref,
    DriverLocationActionsService locationActions,
  ) async {
    try {
      // Check permissions first
      final hasPermissions = await locationActions.checkPermissions();
      if (!hasPermissions) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permissions are required for tracking'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      bool success = false;
      if (orderId != null) {
        success = await locationActions.startTrackingForOrder(orderId!);
      } else {
        // Start general location tracking
        success = await locationActions.updateCurrentLocation();
      }

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location tracking started'),
              backgroundColor: Colors.green,
            ),
          );
          onTrackingStarted?.call();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to start location tracking'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _stopTracking(
    BuildContext context,
    WidgetRef ref,
    DriverLocationActionsService locationActions,
  ) async {
    try {
      await locationActions.stopTracking();
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location tracking stopped'),
            backgroundColor: Colors.orange,
          ),
        );
        onTrackingStopped?.call();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error stopping tracking: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _refreshLocation(
    BuildContext context,
    WidgetRef ref,
    DriverLocationActionsService locationActions,
  ) async {
    try {
      final success = await locationActions.updateCurrentLocation();
      
      // Refresh providers
      ref.invalidate(driverCurrentLocationProvider);
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Location updated' : 'Failed to update location'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error refreshing location: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimeAgo(Duration duration) {
    if (duration.inMinutes < 1) {
      return 'Just now';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ago';
    } else if (duration.inHours < 24) {
      return '${duration.inHours}h ago';
    } else {
      return '${duration.inDays}d ago';
    }
  }
}
