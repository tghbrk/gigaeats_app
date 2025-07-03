import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../user_management/domain/driver.dart';

import 'driver_status_indicator.dart';

/// Widget to display driver information for an assigned order
class DriverInfoWidget extends ConsumerWidget {
  final String? driverId;
  final bool showFullInfo;
  final EdgeInsets padding;

  const DriverInfoWidget({
    super.key,
    required this.driverId,
    this.showFullInfo = false,
    this.padding = const EdgeInsets.all(12),
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (driverId == null) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<Driver?>(
      future: _getDriverInfo(driverId!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: padding,
            child: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 8),
                Text('Loading driver info...'),
              ],
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Container(
            padding: padding,
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Colors.red[400],
                ),
                const SizedBox(width: 8),
                const Text('Driver info unavailable'),
              ],
            ),
          );
        }

        final driver = snapshot.data!;
        final theme = Theme.of(context);

        if (showFullInfo) {
          return Container(
            padding: padding,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.indigo.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_shipping,
                      color: Colors.indigo,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Assigned Driver',
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: Colors.indigo,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    DriverStatusIndicator(
                      status: driver.status,
                      size: 12,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                      child: Text(
                        driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.name,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            driver.phoneNumber,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _getVehicleIcon(driver.vehicleDetails.type),
                      size: 16,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      driver.vehicleDetails.displayString,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }

        // Compact view
        return Container(
          padding: padding,
          child: Row(
            children: [
              Icon(
                Icons.local_shipping,
                color: Colors.indigo,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  driver.name,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.indigo,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DriverStatusIndicator(
                status: driver.status,
                size: 12,
              ),
            ],
          ),
        );
      },
    );
  }

  Future<Driver?> _getDriverInfo(String driverId) async {
    try {
      // TODO: Fix repository type mismatch - repository returns new Driver model but widget expects old Driver model
      // final driverRepository = DriverRepository();
      // return await driverRepository.getDriverById(driverId);
      return null; // Temporary fix for type assignment issue
    } catch (e) {
      return null;
    }
  }

  IconData _getVehicleIcon(String vehicleType) {
    switch (vehicleType.toLowerCase()) {
      case 'motorcycle':
        return Icons.two_wheeler;
      case 'car':
        return Icons.directions_car;
      case 'bicycle':
        return Icons.pedal_bike;
      case 'van':
        return Icons.airport_shuttle;
      case 'truck':
        return Icons.local_shipping;
      default:
        return Icons.local_shipping;
    }
  }
}

/// Compact driver info chip for order cards
class DriverInfoChip extends StatelessWidget {
  final String? driverId;
  final VoidCallback? onTap;

  const DriverInfoChip({
    super.key,
    required this.driverId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (driverId == null) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.indigo.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.indigo.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.local_shipping,
              size: 14,
              color: Colors.indigo,
            ),
            const SizedBox(width: 4),
            Text(
              'Driver Assigned',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.indigo,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Driver assignment status widget for order lists
class DriverAssignmentStatus extends StatelessWidget {
  final String? driverId;
  final bool isCompact;

  const DriverAssignmentStatus({
    super.key,
    required this.driverId,
    this.isCompact = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (driverId == null) {
      return Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCompact ? 6 : 8,
          vertical: isCompact ? 2 : 4,
        ),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
          border: Border.all(
            color: Colors.orange.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_search,
              size: isCompact ? 12 : 14,
              color: Colors.orange,
            ),
            SizedBox(width: isCompact ? 2 : 4),
            Text(
              'Needs Driver',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.orange,
                fontWeight: FontWeight.w500,
                fontSize: isCompact ? 10 : 12,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 6 : 8,
        vertical: isCompact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.indigo.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(isCompact ? 8 : 12),
        border: Border.all(
          color: Colors.indigo.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle,
            size: isCompact ? 12 : 14,
            color: Colors.indigo,
          ),
          SizedBox(width: isCompact ? 2 : 4),
          Text(
            'Driver Assigned',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.indigo,
              fontWeight: FontWeight.w500,
              fontSize: isCompact ? 10 : 12,
            ),
          ),
        ],
      ),
    );
  }
}
