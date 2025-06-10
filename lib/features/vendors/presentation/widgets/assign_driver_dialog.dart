import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../orders/data/models/order.dart';
import '../../../orders/data/repositories/order_repository.dart';
import '../../data/models/driver.dart';
import '../../data/repositories/driver_repository.dart';
import 'driver_status_indicator.dart';

/// Dialog for assigning a driver from the vendor's fleet to an order
class AssignDriverDialog extends ConsumerStatefulWidget {
  final Order order;
  final VoidCallback? onDriverAssigned;

  const AssignDriverDialog({
    super.key,
    required this.order,
    this.onDriverAssigned,
  });

  @override
  ConsumerState<AssignDriverDialog> createState() => _AssignDriverDialogState();
}

class _AssignDriverDialogState extends ConsumerState<AssignDriverDialog> {
  Driver? _selectedDriver;
  bool _isLoading = false;
  String _searchQuery = '';
  List<Driver> _availableDrivers = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAvailableDrivers();
  }

  Future<void> _loadAvailableDrivers() async {
    try {
      final authState = ref.read(authStateProvider);
      if (authState.user?.role != UserRole.vendor) {
        throw Exception('Only vendors can assign drivers');
      }

      // Get the actual vendor ID from the vendors table using the user ID
      final userId = authState.user?.id ?? '';
      if (userId.isEmpty) {
        throw Exception('User ID not found');
      }

      debugPrint('🚗 AssignDriverDialog: Looking up vendor for user ID: $userId');

      final supabase = Supabase.instance.client;
      final vendorResponse = await supabase
          .from('vendors')
          .select('id')
          .eq('user_id', userId)
          .single();

      final vendorId = vendorResponse['id'] as String;
      debugPrint('🚗 AssignDriverDialog: Found vendor ID: $vendorId');

      final driverRepository = DriverRepository();
      final drivers = await driverRepository.getAvailableDriversForVendor(vendorId);

      if (mounted) {
        setState(() {
          _availableDrivers = drivers;
          _errorMessage = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredDrivers = _getFilteredDrivers();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.local_shipping,
                    color: theme.colorScheme.onPrimary,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Assign Driver',
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Order #${widget.order.orderNumber}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Search drivers...',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              ),
            ),

            // Driver List
            Expanded(
              child: _buildDriverList(filteredDrivers),
            ),

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _selectedDriver != null && !_isLoading
                          ? _assignDriver
                          : null,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Assign Driver'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDriverList(List<Driver> drivers) {
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Error loading drivers',
              style: TextStyle(
                fontSize: 18,
                color: Colors.red[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage!,
              style: TextStyle(
                color: Colors.red[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadAvailableDrivers,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (drivers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No available drivers',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'All drivers are currently offline or on delivery',
              style: TextStyle(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: _loadAvailableDrivers,
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: drivers.length,
      itemBuilder: (context, index) {
        final driver = drivers[index];
        final isSelected = _selectedDriver?.id == driver.id;

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedDriver = driver;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: isSelected
                    ? Border.all(
                        color: Theme.of(context).colorScheme.primary,
                        width: 2,
                      )
                    : null,
              ),
              child: Row(
                children: [
                  // Driver Avatar
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                    child: Text(
                      driver.name.isNotEmpty ? driver.name[0].toUpperCase() : 'D',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
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
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            DriverStatusIndicator(
                              status: driver.status,
                              showLabel: true,
                              size: 12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver.phoneNumber,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              _getVehicleIcon(driver.vehicleDetails.type),
                              size: 16,
                              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              driver.vehicleDetails.displayString,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  
                  // Selection Indicator
                  if (isSelected)
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Driver> _getFilteredDrivers() {
    if (_searchQuery.isEmpty) {
      return _availableDrivers;
    }

    return _availableDrivers.where((driver) {
      return driver.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             driver.phoneNumber.contains(_searchQuery) ||
             driver.vehicleDetails.plateNumber.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
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

  Future<void> _assignDriver() async {
    if (_selectedDriver == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final orderRepository = OrderRepository();
      await orderRepository.assignDriverToOrder(widget.order.id, _selectedDriver!.id);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedDriver!.name} assigned to Order #${widget.order.orderNumber}',
            ),
            backgroundColor: Colors.green,
          ),
        );
        widget.onDriverAssigned?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to assign driver: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
