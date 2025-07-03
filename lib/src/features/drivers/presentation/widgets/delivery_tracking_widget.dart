import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../data/models/delivery_tracking.dart';
import '../../data/repositories/delivery_tracking_repository.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';

/// Provider for delivery tracking stream
final deliveryTrackingProvider = StreamProvider.family<List<DeliveryTracking>, String>((ref, orderId) {
  final trackingRepository = DeliveryTrackingRepository();
  return trackingRepository.streamTrackingUpdates(orderId);
});

/// Provider for delivery route
final deliveryRouteProvider = FutureProvider.family<DeliveryRoute, String>((ref, orderId) async {
  final trackingRepository = DeliveryTrackingRepository();
  return trackingRepository.getDeliveryRoute(orderId);
});

/// Widget to display real-time delivery tracking information
class DeliveryTrackingWidget extends ConsumerWidget {
  final String orderId;
  final bool showMap;
  final bool isCompact;

  const DeliveryTrackingWidget({
    super.key,
    required this.orderId,
    this.showMap = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingAsync = ref.watch(deliveryTrackingProvider(orderId));
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(isCompact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: theme.colorScheme.primary,
                  size: isCompact ? 20 : 24,
                ),
                SizedBox(width: isCompact ? 6 : 8),
                Expanded(
                  child: Text(
                    'Live Tracking',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: isCompact ? 14 : 16,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () => ref.invalidate(deliveryTrackingProvider(orderId)),
                  iconSize: isCompact ? 20 : 24,
                ),
              ],
            ),
            
            SizedBox(height: isCompact ? 8 : 12),
            
            // Tracking Content
            trackingAsync.when(
              data: (trackingPoints) => _buildTrackingContent(
                context,
                trackingPoints,
                isCompact,
              ),
              loading: () => SizedBox(
                height: isCompact ? 60 : 80,
                child: const LoadingWidget(),
              ),
              error: (error, stack) => SizedBox(
                height: isCompact ? 60 : 80,
                child: CustomErrorWidget(
                  message: 'Failed to load tracking data',
                  onRetry: () => ref.invalidate(deliveryTrackingProvider(orderId)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingContent(
    BuildContext context,
    List<DeliveryTracking> trackingPoints,
    bool compact,
  ) {
    if (trackingPoints.isEmpty) {
      return _buildNoTrackingData(context, compact);
    }

    final latestPoint = trackingPoints.last;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Latest Location Info
        Container(
          padding: EdgeInsets.all(compact ? 8 : 12),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.my_location,
                    color: theme.colorScheme.primary,
                    size: compact ? 16 : 18,
                  ),
                  SizedBox(width: compact ? 4 : 6),
                  Text(
                    'Current Location',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: compact ? 12 : 14,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatTime(latestPoint.recordedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontSize: compact ? 10 : 12,
                    ),
                  ),
                ],
              ),
              
              if (!compact) ...[
                SizedBox(height: 8),
                Text(
                  latestPoint.location.displayString,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
              
              SizedBox(height: compact ? 4 : 8),
              
              // Speed and Accuracy
              Row(
                children: [
                  if (latestPoint.speed != null) ...[
                    Icon(
                      Icons.speed,
                      size: compact ? 14 : 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: compact ? 2 : 4),
                    Text(
                      latestPoint.speedDisplay,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                    SizedBox(width: compact ? 8 : 12),
                  ],
                  
                  if (latestPoint.accuracy != null) ...[
                    Icon(
                      Icons.gps_fixed,
                      size: compact ? 14 : 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    SizedBox(width: compact ? 2 : 4),
                    Text(
                      latestPoint.accuracyDisplay,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: compact ? 10 : 12,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        
        if (!compact) ...[
          SizedBox(height: 12),
          
          // Tracking Statistics
          _buildTrackingStats(context, trackingPoints),
          
          SizedBox(height: 12),
          
          // Recent Tracking Points
          _buildRecentPoints(context, trackingPoints.take(3).toList()),
        ],
      ],
    );
  }

  Widget _buildNoTrackingData(BuildContext context, bool compact) {
    final theme = Theme.of(context);
    
    return Container(
      padding: EdgeInsets.all(compact ? 12 : 16),
      child: Column(
        children: [
          Icon(
            Icons.location_off,
            size: compact ? 32 : 48,
            color: Colors.grey[400],
          ),
          SizedBox(height: compact ? 6 : 8),
          Text(
            'No tracking data available',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
              fontSize: compact ? 12 : 14,
            ),
          ),
          if (!compact) ...[
            SizedBox(height: 4),
            Text(
              'Tracking will start when driver begins delivery',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTrackingStats(BuildContext context, List<DeliveryTracking> points) {
    if (points.length < 2) return const SizedBox.shrink();

    final route = DeliveryRoute.fromTrackingPoints(
      orderId: orderId,
      driverId: points.first.driverId,
      trackingPoints: points,
    );

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Distance',
            route.totalDistanceKm != null 
                ? '${route.totalDistanceKm!.toStringAsFixed(1)} km'
                : 'N/A',
            Icons.straighten,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Duration',
            route.duration != null 
                ? _formatDuration(route.duration!)
                : 'N/A',
            Icons.timer,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _buildStatCard(
            context,
            'Avg Speed',
            route.averageSpeed != null 
                ? '${route.averageSpeed!.toStringAsFixed(1)} km/h'
                : 'N/A',
            Icons.speed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentPoints(BuildContext context, List<DeliveryTracking> points) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Updates',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: 8),
        ...points.map((point) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Icon(
                Icons.location_on,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  _formatTime(point.recordedAt),
                  style: theme.textTheme.bodySmall,
                ),
              ),
              if (point.speed != null)
                Text(
                  point.speedDisplay,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                ),
            ],
          ),
        )),
      ],
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else {
      return DateFormat('HH:mm').format(dateTime);
    }
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}
