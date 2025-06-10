import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/driver.dart';
import '../../data/repositories/driver_repository.dart';
import '../widgets/driver_status_indicator.dart';
import '../widgets/delivery_tracking_widget.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';

/// Provider for active drivers (on delivery)
final activeDriversProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.vendor) {
    throw Exception('Only vendors can access driver tracking');
  }

  // Get the actual vendor ID from the vendors table using the user ID
  final userId = authState.user?.id ?? '';
  if (userId.isEmpty) {
    throw Exception('User ID not found');
  }

  final supabase = Supabase.instance.client;
  final vendorResponse = await supabase
      .from('vendors')
      .select('id')
      .eq('user_id', userId)
      .single();

  final vendorId = vendorResponse['id'] as String;
  final driverRepository = DriverRepository();

  return driverRepository.getDriversWithCurrentOrders(vendorId);
});

/// Driver tracking screen for monitoring active deliveries
class DriverTrackingScreen extends ConsumerStatefulWidget {
  const DriverTrackingScreen({super.key});

  @override
  ConsumerState<DriverTrackingScreen> createState() => _DriverTrackingScreenState();
}

class _DriverTrackingScreenState extends ConsumerState<DriverTrackingScreen> {
  String _selectedFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeDriversAsync = ref.watch(activeDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Tracking'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(activeDriversProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Bar
          _buildFilterBar(),
          
          // Drivers List
          Expanded(
            child: activeDriversAsync.when(
              data: (drivers) => _buildDriversList(drivers),
              loading: () => const LoadingWidget(),
              error: (error, stack) => CustomErrorWidget(
                message: 'Failed to load driver tracking data: $error',
                onRetry: () => ref.invalidate(activeDriversProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'Filter:',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('all', 'All Drivers'),
                  const SizedBox(width: 8),
                  _buildFilterChip('on_delivery', 'On Delivery'),
                  const SizedBox(width: 8),
                  _buildFilterChip('online', 'Online'),
                  const SizedBox(width: 8),
                  _buildFilterChip('offline', 'Offline'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _selectedFilter == value;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = value;
        });
      },
      selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildDriversList(List<Map<String, dynamic>> driversData) {
    // Filter drivers based on selected filter
    final filteredDrivers = driversData.where((driverData) {
      if (_selectedFilter == 'all') return true;
      
      final status = driverData['status'] as String?;
      return status == _selectedFilter;
    }).toList();

    if (filteredDrivers.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredDrivers.length,
      itemBuilder: (context, index) {
        final driverData = filteredDrivers[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildDriverTrackingCard(driverData),
        );
      },
    );
  }

  Widget _buildDriverTrackingCard(Map<String, dynamic> driverData) {
    final theme = Theme.of(context);
    
    // Extract driver information
    final name = driverData['name'] as String;
    final phoneNumber = driverData['phone_number'] as String;
    final status = DriverStatus.fromString(driverData['status'] as String);
    final vehicleDetails = driverData['vehicle_details'] as Map<String, dynamic>?;
    final currentOrder = driverData['current_order'] as Map<String, dynamic>?;
    final lastSeen = driverData['last_seen'] != null 
        ? DateTime.parse(driverData['last_seen'] as String)
        : null;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Driver Header
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'D',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          DriverStatusIndicator(
                            status: status,
                            showLabel: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        phoneNumber,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Vehicle Information
            if (vehicleDetails != null) ...[
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
                      _getVehicleIcon(vehicleDetails['type'] as String? ?? 'motorcycle'),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _formatVehicleInfo(vehicleDetails),
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            
            // Current Order Information
            if (currentOrder != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
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
                          Icons.receipt_long,
                          color: Colors.indigo,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Current Delivery',
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: Colors.indigo,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Order #${currentOrder['order_number']}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (currentOrder['customer_name'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Customer: ${currentOrder['customer_name']}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    if (currentOrder['delivery_address'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Delivery: ${_formatAddress(currentOrder['delivery_address'])}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              
              // Live Tracking Widget
              DeliveryTrackingWidget(
                orderId: currentOrder['id'] as String,
                isCompact: true,
              ),
            ] else ...[
              // No current order
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Colors.grey[600],
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      status == DriverStatus.online 
                          ? 'Available for delivery'
                          : 'Not available',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Last Seen Information
            if (lastSeen != null) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Last seen: ${_formatLastSeen(lastSeen)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.location_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No drivers found',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Drivers will appear here when they are active',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
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

  String _formatVehicleInfo(Map<String, dynamic> vehicleDetails) {
    final plateNumber = vehicleDetails['plate_number'] as String? ?? '';
    final brand = vehicleDetails['brand'] as String?;
    final model = vehicleDetails['model'] as String?;
    
    final parts = <String>[];
    if (brand != null && model != null) {
      parts.add('$brand $model');
    }
    parts.add(plateNumber);
    
    return parts.join(' • ');
  }

  String _formatAddress(dynamic address) {
    if (address is String) {
      return address;
    } else if (address is Map<String, dynamic>) {
      final street = address['street'] as String? ?? '';
      final city = address['city'] as String? ?? '';
      return '$street, $city';
    }
    return 'Address not available';
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
