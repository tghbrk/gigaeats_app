import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../providers/customer_delivery_tracking_provider.dart';
import '../../data/services/customer_delivery_tracking_service.dart';
import '../../../orders/data/models/order.dart';
import '../../../../shared/widgets/custom_error_widget.dart';
import '../../../../core/utils/logger.dart';

/// Customer order tracking screen with live GPS tracking
class CustomerOrderTrackingScreen extends ConsumerStatefulWidget {
  final String orderId;

  const CustomerOrderTrackingScreen({
    super.key,
    required this.orderId,
  });

  @override
  ConsumerState<CustomerOrderTrackingScreen> createState() => _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState extends ConsumerState<CustomerOrderTrackingScreen> {
  GoogleMapController? _mapController;
  final AppLogger _logger = AppLogger();

  @override
  void initState() {
    super.initState();
    _logger.info('CustomerOrderTrackingScreen: Initializing for order ${widget.orderId}');
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trackingState = ref.watch(orderTrackingProvider(widget.orderId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track Your Order'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          // Connection status indicator
          Consumer(
            builder: (context, ref, child) {
              final trackingState = ref.watch(orderTrackingProvider(widget.orderId));
              if (trackingState.isLoading) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                );
              } else if (trackingState.error != null) {
                return Icon(
                  Icons.error_outline,
                  color: Colors.red.shade300,
                  size: 20,
                );
              } else if (trackingState.isTracking) {
                return Icon(
                  Icons.wifi,
                  color: Colors.green.shade300,
                  size: 20,
                );
              } else {
                return Icon(
                  Icons.wifi_off,
                  color: Colors.red.shade300,
                  size: 20,
                );
              }
            },
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(orderTrackingProvider(widget.orderId).notifier).refresh();
            },
          ),
        ],
      ),
      body: _buildBody(context, trackingState),
    );
  }

  Widget _buildBody(BuildContext context, CustomerDeliveryTrackingState state) {
    if (state.isLoading && state.trackingInfo == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading tracking information...'),
          ],
        ),
      );
    }

    if (state.error != null) {
      return CustomErrorWidget(
        message: 'Failed to load tracking information: ${state.error}',
        onRetry: () {
          ref.read(orderTrackingProvider(widget.orderId).notifier).clearError();
          ref.read(orderTrackingProvider(widget.orderId).notifier).refresh();
        },
      );
    }

    if (state.trackingInfo == null) {
      return _buildNoTrackingAvailable();
    }

    return Column(
      children: [
        // Order status header
        _buildOrderStatusHeader(state.trackingInfo!),
        
        // Map view
        Expanded(
          flex: 2,
          child: _buildMapView(state),
        ),
        
        // Delivery information
        _buildDeliveryInfo(state.trackingInfo!),
      ],
    );
  }

  Widget _buildNoTrackingAvailable() {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.location_off,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'Tracking Not Available',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Live tracking will be available once a driver is assigned to your order.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.pop(),
              child: const Text('Back to Orders'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderStatusHeader(DeliveryTrackingInfo trackingInfo) {
    final theme = Theme.of(context);
    final order = trackingInfo.order;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${order.orderNumber}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      order.vendorName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(order.status),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.person,
                size: 16,
                color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 8),
              Text(
                'Driver: ${trackingInfo.driver.name}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
              ),
              const Spacer(),
              if (trackingInfo.estimatedArrival != null) ...[
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                ),
                const SizedBox(width: 4),
                Text(
                  'ETA: ${trackingInfo.estimatedTimeRemaining}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(OrderStatus status) {
    final theme = Theme.of(context);
    
    Color backgroundColor;
    Color textColor;
    String text;

    switch (status) {
      case OrderStatus.confirmed:
        backgroundColor = Colors.blue.shade100;
        textColor = Colors.blue.shade800;
        text = 'Confirmed';
        break;
      case OrderStatus.preparing:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade800;
        text = 'Preparing';
        break;
      case OrderStatus.ready:
        backgroundColor = Colors.purple.shade100;
        textColor = Colors.purple.shade800;
        text = 'Ready';
        break;
      case OrderStatus.outForDelivery:
        backgroundColor = Colors.green.shade100;
        textColor = Colors.green.shade800;
        text = 'Out for Delivery';
        break;
      case OrderStatus.delivered:
        backgroundColor = Colors.green.shade200;
        textColor = Colors.green.shade900;
        text = 'Delivered';
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
        text = status.toString().split('.').last;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildMapView(CustomerDeliveryTrackingState state) {
    final trackingInfo = state.trackingInfo!;
    final driverLocation = trackingInfo.currentDriverLocation;
    final deliveryLocation = trackingInfo.deliveryDestination;

    // Default to Kuala Lumpur if no locations available
    final initialLocation = driverLocation ?? deliveryLocation ?? const LatLng(3.1390, 101.6869);

    return GoogleMap(
      onMapCreated: (GoogleMapController controller) {
        _mapController = controller;
        _fitMapToShowAllMarkers(state);
      },
      initialCameraPosition: CameraPosition(
        target: initialLocation,
        zoom: 14.0,
      ),
      markers: state.markers,
      polylines: state.polylines,
      myLocationEnabled: false,
      myLocationButtonEnabled: false,
      zoomControlsEnabled: true,
      mapToolbarEnabled: false,
    );
  }

  void _fitMapToShowAllMarkers(CustomerDeliveryTrackingState state) {
    if (_mapController == null || state.markers.isEmpty) return;

    final bounds = _calculateBounds(state.markers);
    _mapController!.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, 100.0),
    );
  }

  LatLngBounds _calculateBounds(Set<Marker> markers) {
    final positions = markers.map((marker) => marker.position).toList();
    
    double minLat = positions.first.latitude;
    double maxLat = positions.first.latitude;
    double minLng = positions.first.longitude;
    double maxLng = positions.first.longitude;

    for (final position in positions) {
      minLat = math.min(minLat, position.latitude);
      maxLat = math.max(maxLat, position.latitude);
      minLng = math.min(minLng, position.longitude);
      maxLng = math.max(maxLng, position.longitude);
    }

    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  Widget _buildDeliveryInfo(DeliveryTrackingInfo trackingInfo) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                trackingInfo.isDriverTracking ? Icons.gps_fixed : Icons.gps_off,
                color: trackingInfo.isDriverTracking ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                trackingInfo.isDriverTracking ? 'Live Tracking Active' : 'Tracking Unavailable',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: trackingInfo.isDriverTracking ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.schedule,
                  title: 'Estimated Arrival',
                  value: trackingInfo.estimatedTimeRemaining,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildInfoCard(
                  icon: Icons.phone,
                  title: 'Driver Contact',
                  value: trackingInfo.driver.phoneNumber,
                  onTap: () => _callDriver(trackingInfo.driver.phoneNumber),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(8),
          border: onTap != null ? Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)) : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _callDriver(String phoneNumber) {
    // TODO: Implement phone call functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Calling $phoneNumber...')),
    );
  }
}
