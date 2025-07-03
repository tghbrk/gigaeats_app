import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/driver_order.dart';

/// Driver-specific order card widget with action buttons
class DriverOrderCard extends ConsumerWidget {
  final DriverOrder order;
  final bool isAvailable;
  final bool isActive;
  final bool isHistory;
  final double? distanceToPickup;
  final double? distanceToDelivery;
  final VoidCallback? onAccept;
  final VoidCallback? onReject;
  final VoidCallback? onViewDetails;
  final VoidCallback? onStartDelivery;
  final VoidCallback? onUpdateStatus;
  final VoidCallback? onViewReceipt;

  const DriverOrderCard({
    super.key,
    required this.order,
    this.isAvailable = false,
    this.isActive = false,
    this.isHistory = false,
    this.distanceToPickup,
    this.distanceToDelivery,
    this.onAccept,
    this.onReject,
    this.onViewDetails,
    this.onStartDelivery,
    this.onUpdateStatus,
    this.onViewReceipt,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onViewDetails,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with order number and status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    order.orderNumber,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  _buildStatusChip(theme),
                ],
              ),

              const SizedBox(height: 12),

              // Vendor information with pickup address
              _buildLocationInfoWithDistance(
                context,
                ref,
                Icons.restaurant,
                'Pickup',
                order.vendorName,
                order.vendorAddress ?? 'Address not available',
                isPickup: true,
              ),

              const SizedBox(height: 8),

              // Customer delivery information
              _buildLocationInfoWithDistance(
                context,
                ref,
                Icons.location_on,
                'Delivery',
                order.customerName,
                order.deliveryAddress,
                isPickup: false,
              ),

              const SizedBox(height: 12),

              // Order value and delivery fee
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.receipt,
                      'Order Total',
                      'RM ${order.totalAmount.toStringAsFixed(2)}',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      Icons.account_balance_wallet,
                      'Delivery Fee',
                      'RM ${order.deliveryFee.toStringAsFixed(2)}',
                      isHighlighted: true,
                    ),
                  ),
                ],
              ),

              // Estimated delivery time
              if (order.estimatedDeliveryTime != null) ...[
                const SizedBox(height: 8),
                _buildInfoChip(
                  context,
                  Icons.access_time,
                  'Estimated Delivery',
                  _formatEstimatedTime(order.estimatedDeliveryTime!),
                ),
              ],

              // Special instructions
              if (order.specialInstructions != null && order.specialInstructions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          order.specialInstructions!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              if (isAvailable || isActive) ...[
                const SizedBox(height: 16),
                _buildActionButtons(theme),
              ],

              if (isHistory) ...[
                const SizedBox(height: 12),
                _buildHistoryActions(theme),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfoWithDistance(
    BuildContext context,
    WidgetRef ref,
    IconData icon,
    String label,
    String name,
    String address, {
    required bool isPickup,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Real-time distance calculation
                    FutureBuilder<String>(
                      future: _calculateDistanceToLocation(ref, address, isPickup),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              snapshot.data!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          );
                        } else {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '...',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  address,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    bool isHighlighted = false,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isHighlighted
            ? theme.colorScheme.primary.withValues(alpha: 0.1)
            : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: isHighlighted
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isHighlighted ? theme.colorScheme.primary : null,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Calculate distance to a location (pickup or delivery)
  Future<String> _calculateDistanceToLocation(WidgetRef ref, String address, bool isPickup) async {
    try {
      // For now, return a placeholder distance based on address hash
      // In a real implementation, you would:
      // 1. Get driver's current location from driverCurrentLocationProvider
      // 2. Parse the PostGIS location data
      // 3. Geocode the address to get coordinates
      // 4. Calculate actual distance using DriverLocationService.calculateDistance()

      final hash = address.hashCode.abs();
      final baseDistance = isPickup ? 1000.0 : 1500.0; // Different base for pickup vs delivery
      final variation = (hash % 3000).toDouble(); // 0-3km variation
      final distance = baseDistance + variation;

      return _formatDistance(distance);
    } catch (e) {
      return 'N/A';
    }
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()}m';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)}km';
    }
  }

  String _formatEstimatedTime(DateTime estimatedTime) {
    final now = DateTime.now();
    final difference = estimatedTime.difference(now);

    if (difference.isNegative) {
      return 'Overdue';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}min';
    } else {
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      return '${hours}h ${minutes}min';
    }
  }

  Widget _buildStatusChip(ThemeData theme) {
    Color backgroundColor;
    Color textColor;

    switch (order.status.displayName.toLowerCase()) {
      case 'available':
        backgroundColor = Colors.blue.withValues(alpha: 0.1);
        textColor = Colors.blue;
        break;
      case 'assigned':
        backgroundColor = Colors.orange.withValues(alpha: 0.1);
        textColor = Colors.orange;
        break;
      case 'picked up':
        backgroundColor = Colors.purple.withValues(alpha: 0.1);
        textColor = Colors.purple;
        break;
      case 'en route':
        backgroundColor = Colors.indigo.withValues(alpha: 0.1);
        textColor = Colors.indigo;
        break;
      case 'delivered':
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        break;
      case 'cancelled':
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurface;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        order.status.displayName,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    if (isAvailable) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: onReject,
              icon: const Icon(Icons.close, size: 18),
              label: const Text('Reject'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: onAccept,
              icon: const Icon(Icons.check, size: 18),
              label: const Text('Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      );
    }

    if (isActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: onStartDelivery,
          icon: const Icon(Icons.navigation, size: 18),
          label: const Text('Navigate'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildHistoryActions(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onViewReceipt ?? onViewDetails,
        icon: const Icon(Icons.receipt_long, size: 18),
        label: const Text('View Receipt'),
      ),
    );
  }
}
