import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user_management/domain/driver.dart';
import '../widgets/driver_card.dart';
import '../widgets/driver_status_indicator.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// Provider for all drivers (admin access)
final adminDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final driverRepository = ref.read(driverRepositoryProvider);
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.admin) {
    throw Exception('Only admins can access fleet management');
  }

  return driverRepository.getAllDrivers();
});

/// Provider for driver statistics across all vendors (admin access)
final adminDriverStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final driverRepository = ref.read(driverRepositoryProvider);
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.admin) {
    throw Exception('Only admins can access driver statistics');
  }

  return driverRepository.getAllDriverStatistics();
});

/// Admin Fleet Management Screen for managing all drivers across vendors
class AdminFleetManagementScreen extends ConsumerStatefulWidget {
  const AdminFleetManagementScreen({super.key});

  @override
  ConsumerState<AdminFleetManagementScreen> createState() => _AdminFleetManagementScreenState();
}

class _AdminFleetManagementScreenState extends ConsumerState<AdminFleetManagementScreen> {
  String _searchQuery = '';
  DriverStatus? _statusFilter;
  String? _vendorFilter;

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(adminDriversProvider);
    final statsAsync = ref.watch(adminDriverStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AdminDriverTrackingScreen(),
                ),
              );
            },
            tooltip: 'Live Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(adminDriversProvider);
              ref.invalidate(adminDriverStatisticsProvider);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Statistics Header
          _buildStatisticsHeader(statsAsync),
          
          // Search and Filter Bar
          _buildSearchAndFilterBar(),
          
          // Drivers List
          Expanded(
            child: _buildDriversList(driversAsync),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin_fleet_fab',
        onPressed: () => _showAddDriverDialog(),
        tooltip: 'Add Driver',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildStatisticsHeader(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: statsAsync.when(
        data: (stats) {
          final total = stats['total'] ?? 0;
          final online = stats['online'] ?? 0;
          final offline = stats['offline'] ?? 0;
          final onDelivery = stats['on_delivery'] ?? 0;

          return Row(
            children: [
              Expanded(child: _buildStatCard('Total', '$total', Colors.blue)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Online', '$online', Colors.green)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('Offline', '$offline', Colors.grey)),
              const SizedBox(width: 12),
              Expanded(child: _buildStatCard('On Delivery', '$onDelivery', Colors.orange)),
            ],
          );
        },
        loading: () => const SizedBox(
          height: 80,
          child: LoadingWidget(),
        ),
        error: (error, stack) => SizedBox(
          height: 80,
          child: CustomErrorWidget(
            message: 'Failed to load statistics: $error',
            onRetry: () => ref.invalidate(adminDriverStatisticsProvider),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          // Search Bar
          TextField(
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
          const SizedBox(height: 8),
          
          // Filter Row
          Row(
            children: [
              // Status Filter
              Expanded(
                child: DropdownButtonFormField<DriverStatus?>(
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  initialValue: _statusFilter,
                  items: [
                    const DropdownMenuItem<DriverStatus?>(
                      value: null,
                      child: Text('All Status'),
                    ),
                    ...DriverStatus.values.map((status) => DropdownMenuItem(
                      value: status,
                      child: Row(
                        children: [
                          DriverStatusIndicator(status: status),
                          const SizedBox(width: 8),
                          Text(status.name.toUpperCase()),
                        ],
                      ),
                    )),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _statusFilter = value;
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // Vendor Filter (placeholder for now)
              Expanded(
                child: DropdownButtonFormField<String?>(
                  decoration: const InputDecoration(
                    labelText: 'Vendor',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                  initialValue: _vendorFilter,
                  items: const [
                    DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Vendors'),
                    ),
                    // TODO: Add vendor options
                  ],
                  onChanged: (value) {
                    setState(() {
                      _vendorFilter = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDriversList(AsyncValue<List<Driver>> driversAsync) {
    return driversAsync.when(
      data: (drivers) {
        // Apply filters
        final filteredDrivers = drivers.where((driver) {
          final matchesSearch = _searchQuery.isEmpty ||
              driver.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
              driver.phoneNumber.toLowerCase().contains(_searchQuery.toLowerCase());
          final matchesStatus = _statusFilter == null || driver.status == _statusFilter;
          // TODO: Add vendor filter logic when vendor data is available
          return matchesSearch && matchesStatus;
        }).toList();

        if (filteredDrivers.isEmpty) {
          return const Center(
            child: Text('No drivers found'),
          );
        }

        return ListView.builder(
          key: const ValueKey('admin_drivers_list'),
          padding: const EdgeInsets.all(16),
          itemCount: filteredDrivers.length,
          itemBuilder: (context, index) {
            final driver = filteredDrivers[index];
            return Padding(
              key: ValueKey('admin_driver_${driver.id}'),
              padding: const EdgeInsets.only(bottom: 12),
              child: DriverCard(
                key: ValueKey('admin_driver_card_${driver.id}'),
                driver: driver,
                onTap: () => _showDriverDetails(driver),
              ),
            );
          },
        );
      },
      loading: () => const LoadingWidget(),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load drivers: $error',
        onRetry: () => ref.invalidate(adminDriversProvider),
      ),
    );
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => const AdminAddDriverDialog(),
    );
  }

  void _showDriverDetails(Driver driver) {
    // TODO: Implement driver details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Driver details for ${driver.name}')),
    );
  }

  // TODO: Implement driver status update functionality
  // Future<void> _updateDriverStatus(Driver driver, DriverStatus newStatus) async { ... }
}

/// Admin version of Add Driver Dialog
class AdminAddDriverDialog extends StatelessWidget {
  const AdminAddDriverDialog({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Implement admin-specific add driver dialog with vendor selection
    return AlertDialog(
      title: const Text('Add Driver'),
      content: const Text('Admin add driver functionality coming soon...'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

/// Admin version of Driver Tracking Screen
class AdminDriverTrackingScreen extends StatelessWidget {
  const AdminDriverTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Tracking - Admin'),
      ),
      body: const Center(
        child: Text('Admin driver tracking functionality coming soon...'),
      ),
    );
  }
}
