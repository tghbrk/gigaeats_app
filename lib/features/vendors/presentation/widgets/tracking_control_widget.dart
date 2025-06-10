import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/location_tracking_service.dart';

/// Provider for location tracking service
final locationTrackingServiceProvider = Provider<LocationTrackingService>((ref) {
  return LocationTrackingService();
});

/// Provider for tracking status
final trackingStatusProvider = StateNotifierProvider<TrackingStatusNotifier, TrackingStatus>((ref) {
  final service = ref.read(locationTrackingServiceProvider);
  return TrackingStatusNotifier(service);
});

/// Tracking status model
class TrackingStatus {
  final bool isTracking;
  final String? orderId;
  final String? driverId;
  final String? error;

  const TrackingStatus({
    required this.isTracking,
    this.orderId,
    this.driverId,
    this.error,
  });

  TrackingStatus copyWith({
    bool? isTracking,
    String? orderId,
    String? driverId,
    String? error,
  }) {
    return TrackingStatus(
      isTracking: isTracking ?? this.isTracking,
      orderId: orderId ?? this.orderId,
      driverId: driverId ?? this.driverId,
      error: error ?? this.error,
    );
  }
}

/// State notifier for tracking status
class TrackingStatusNotifier extends StateNotifier<TrackingStatus> {
  final LocationTrackingService _service;

  TrackingStatusNotifier(this._service) : super(const TrackingStatus(isTracking: false));

  Future<void> startTracking(String orderId, String driverId) async {
    try {
      state = state.copyWith(error: null);
      
      final success = await _service.startTracking(
        orderId: orderId,
        driverId: driverId,
      );

      if (success) {
        state = TrackingStatus(
          isTracking: true,
          orderId: orderId,
          driverId: driverId,
        );
      } else {
        state = state.copyWith(
          error: 'Failed to start tracking. Please check location permissions.',
        );
      }
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> stopTracking() async {
    try {
      await _service.stopTracking();
      state = const TrackingStatus(isTracking: false);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Widget for controlling location tracking
class TrackingControlWidget extends ConsumerWidget {
  final String? orderId;
  final String? driverId;
  final bool isCompact;

  const TrackingControlWidget({
    super.key,
    this.orderId,
    this.driverId,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingStatus = ref.watch(trackingStatusProvider);
    final theme = Theme.of(context);

    // Show error if any
    if (trackingStatus.error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(trackingStatus.error!),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Dismiss',
              onPressed: () => ref.read(trackingStatusProvider.notifier).clearError(),
            ),
          ),
        );
      });
    }

    if (isCompact) {
      return _buildCompactControl(context, ref, trackingStatus, theme);
    }

    return _buildFullControl(context, ref, trackingStatus, theme);
  }

  Widget _buildCompactControl(
    BuildContext context,
    WidgetRef ref,
    TrackingStatus status,
    ThemeData theme,
  ) {
    if (orderId == null || driverId == null) {
      return const SizedBox.shrink();
    }

    final isCurrentlyTracking = status.isTracking && 
                               status.orderId == orderId && 
                               status.driverId == driverId;

    return IconButton(
      onPressed: () => _toggleTracking(ref, isCurrentlyTracking),
      icon: Icon(
        isCurrentlyTracking ? Icons.stop_circle : Icons.play_circle,
        color: isCurrentlyTracking ? Colors.red : Colors.green,
      ),
      tooltip: isCurrentlyTracking ? 'Stop Tracking' : 'Start Tracking',
    );
  }

  Widget _buildFullControl(
    BuildContext context,
    WidgetRef ref,
    TrackingStatus status,
    ThemeData theme,
  ) {
    final canTrack = orderId != null && driverId != null;
    final isCurrentlyTracking = status.isTracking && 
                               status.orderId == orderId && 
                               status.driverId == driverId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  'GPS Tracking',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isCurrentlyTracking ? Colors.green : Colors.grey).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (isCurrentlyTracking ? Colors.green : Colors.grey).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isCurrentlyTracking ? Colors.green : Colors.grey,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isCurrentlyTracking ? 'Active' : 'Inactive',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isCurrentlyTracking ? Colors.green : Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            if (status.isTracking && status.orderId != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.blue.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Currently Tracking',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.blue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Order: ${status.orderId}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      'Driver: ${status.driverId}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: canTrack ? () => _toggleTracking(ref, isCurrentlyTracking) : null,
                    icon: Icon(
                      isCurrentlyTracking ? Icons.stop : Icons.play_arrow,
                    ),
                    label: Text(
                      isCurrentlyTracking ? 'Stop Tracking' : 'Start Tracking',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCurrentlyTracking ? Colors.red : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                if (!canTrack) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _showTrackingInfo(context),
                    icon: const Icon(Icons.info_outline),
                    tooltip: 'Tracking Info',
                  ),
                ],
              ],
            ),
            
            if (!canTrack) ...[
              const SizedBox(height: 8),
              Text(
                'Tracking requires an active order with assigned driver',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleTracking(WidgetRef ref, bool isCurrentlyTracking) {
    final notifier = ref.read(trackingStatusProvider.notifier);
    
    if (isCurrentlyTracking) {
      notifier.stopTracking();
    } else if (orderId != null && driverId != null) {
      notifier.startTracking(orderId!, driverId!);
    }
  }

  void _showTrackingInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('GPS Tracking'),
        content: const Text(
          'GPS tracking is available when:\n\n'
          '• An order is assigned to a driver\n'
          '• The order status is "Out for Delivery"\n'
          '• Location permissions are granted\n\n'
          'Tracking helps customers see real-time delivery progress.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

/// Simple tracking status indicator
class TrackingStatusIndicator extends ConsumerWidget {
  final double size;

  const TrackingStatusIndicator({
    super.key,
    this.size = 16,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingStatus = ref.watch(trackingStatusProvider);
    
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: trackingStatus.isTracking ? Colors.green : Colors.grey,
        shape: BoxShape.circle,
      ),
      child: trackingStatus.isTracking
          ? Icon(
              Icons.location_on,
              size: size * 0.7,
              color: Colors.white,
            )
          : null,
    );
  }
}
