import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../data/models/driver.dart';
import 'driver_status_indicator.dart';

/// Card widget to display driver information in a list
class DriverCard extends StatelessWidget {
  final Driver driver;
  final VoidCallback? onTap;
  final Function(DriverStatus)? onStatusChanged;
  final bool showActions;

  const DriverCard({
    super.key,
    required this.driver,
    this.onTap,
    this.onStatusChanged,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  // Driver Avatar
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  
                  // Driver Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                driver.name,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DriverStatusIndicator(status: driver.status),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver.phoneNumber,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Actions Menu
                  if (showActions)
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleAction(context, value),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit),
                              SizedBox(width: 8),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'status',
                          child: Row(
                            children: [
                              Icon(Icons.swap_horiz),
                              SizedBox(width: 8),
                              Text('Change Status'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'performance',
                          child: Row(
                            children: [
                              Icon(Icons.analytics),
                              SizedBox(width: 8),
                              Text('Performance'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red),
                              SizedBox(width: 8),
                              Text('Remove', style: TextStyle(color: Colors.red)),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Vehicle Information
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getVehicleIcon(driver.vehicleDetails.type),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver.vehicleDetails.displayString,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            driver.vehicleDetails.typeDisplayName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Status Information
              Row(
                children: [
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      'Activity',
                      driver.activityStatus,
                      _getActivityColor(driver.activityStatus),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoChip(
                      context,
                      'Last Seen',
                      _formatLastSeen(driver.lastSeen),
                      Colors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label, String value, Color color) {
    final theme = Theme.of(context);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
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

  Color _getActivityColor(String activityStatus) {
    switch (activityStatus.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'recent':
        return Colors.orange;
      case 'inactive':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Never';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d').format(lastSeen);
    }
  }

  void _handleAction(BuildContext context, String action) {
    switch (action) {
      case 'edit':
        _showEditDialog(context);
        break;
      case 'status':
        _showStatusDialog(context);
        break;
      case 'performance':
        _showPerformanceDialog(context);
        break;
      case 'delete':
        _showDeleteDialog(context);
        break;
    }
  }

  void _showEditDialog(BuildContext context) {
    // TODO: Implement edit driver dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit driver - Coming soon!')),
    );
  }

  void _showStatusDialog(BuildContext context) {
    if (onStatusChanged == null) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Change ${driver.name} Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: DriverStatus.values.map((status) {
            return ListTile(
              leading: DriverStatusIndicator(status: status),
              title: Text(status.displayName),
              selected: status == driver.status,
              onTap: () {
                Navigator.of(context).pop();
                onStatusChanged!(status);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _showPerformanceDialog(BuildContext context) {
    // TODO: Implement performance dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver performance - Coming soon!')),
    );
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Driver'),
        content: Text('Are you sure you want to remove ${driver.name} from your fleet?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Implement driver removal
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Remove driver - Coming soon!')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}
