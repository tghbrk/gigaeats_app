import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../data/models/user_role.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../user_management/domain/driver.dart';
import '../widgets/driver_card.dart';
import '../../widgets/add_driver_dialog.dart';
import '../widgets/driver_status_indicator.dart';
import 'driver_tracking_screen.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/error_widget.dart';
import '../../../../presentation/providers/repository_providers.dart';

/// Provider for vendor drivers
final vendorDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final driverRepository = ref.read(driverRepositoryProvider);
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.vendor) {
    throw Exception('Only vendors can access driver management');
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

  return driverRepository.getDriversForVendor(vendorId);
});

/// Provider for available drivers (online status)
final availableDriversProvider = FutureProvider<List<Driver>>((ref) async {
  final driverRepository = ref.read(driverRepositoryProvider);
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.vendor) {
    throw Exception('Only vendors can access driver management');
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

  return driverRepository.getAvailableDriversForVendor(vendorId);
});

/// Provider for driver statistics
final driverStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final driverRepository = ref.read(driverRepositoryProvider);
  final authState = ref.read(authStateProvider);

  if (authState.user?.role != UserRole.vendor) {
    throw Exception('Only vendors can access driver management');
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

  return driverRepository.getDriverStatistics(vendorId);
});

/// Driver Management Screen for vendors to manage their delivery fleet
class DriverManagementScreen extends ConsumerStatefulWidget {
  const DriverManagementScreen({super.key});

  @override
  ConsumerState<DriverManagementScreen> createState() => _DriverManagementScreenState();
}

class _DriverManagementScreenState extends ConsumerState<DriverManagementScreen> {
  String _searchQuery = '';
  DriverStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final driversAsync = ref.watch(vendorDriversProvider);
    final statsAsync = ref.watch(driverStatisticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fleet Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.location_on),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const DriverTrackingScreen(),
                ),
              );
            },
            tooltip: 'Live Tracking',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.invalidate(vendorDriversProvider);
              ref.invalidate(driverStatisticsProvider);
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDriverDialog(),
        icon: const Icon(Icons.person_add),
        label: const Text('Add Driver'),
      ),
    );
  }

  Widget _buildStatisticsHeader(AsyncValue<Map<String, dynamic>> statsAsync) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: statsAsync.when(
        data: (stats) => Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Drivers',
                '${stats['total'] ?? 0}',
                Icons.people,
                Colors.blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Online',
                '${stats['online'] ?? 0}',
                Icons.check_circle,
                Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'On Delivery',
                '${stats['on_delivery'] ?? 0}',
                Icons.local_shipping,
                Colors.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Offline',
                '${stats['offline'] ?? 0}',
                Icons.cancel,
                Colors.grey,
              ),
            ),
          ],
        ),
        loading: () => const SizedBox(
          height: 80,
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Container(
          height: 80,
          padding: const EdgeInsets.all(16),
          child: Text('Error loading statistics: $error'),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilterBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
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
          const SizedBox(width: 12),
          DropdownButton<DriverStatus?>(
            value: _statusFilter,
            hint: const Text('Status'),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All'),
              ),
              ...DriverStatus.values.map((status) => DropdownMenuItem(
                value: status,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DriverStatusIndicator(status: status, size: 12),
                    const SizedBox(width: 8),
                    Text(status.displayName),
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
        ],
      ),
    );
  }

  Widget _buildDriversList(AsyncValue<List<Driver>> driversAsync) {
    return driversAsync.when(
      data: (drivers) {
        // Apply search and filter
        var filteredDrivers = drivers;
        
        if (_searchQuery.isNotEmpty) {
          filteredDrivers = filteredDrivers.where((driver) =>
            driver.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            driver.phoneNumber.contains(_searchQuery)
          ).toList();
        }
        
        if (_statusFilter != null) {
          filteredDrivers = filteredDrivers.where((driver) =>
            driver.status == _statusFilter
          ).toList();
        }

        if (filteredDrivers.isEmpty) {
          return _buildEmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: filteredDrivers.length,
          itemBuilder: (context, index) {
            final driver = filteredDrivers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DriverCard(
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
        onRetry: () => ref.invalidate(vendorDriversProvider),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.local_shipping_outlined,
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
            'Add your first driver to start managing your fleet',
            style: TextStyle(
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _showAddDriverDialog(),
            icon: const Icon(Icons.person_add),
            label: const Text('Add Driver'),
          ),
        ],
      ),
    );
  }

  void _showAddDriverDialog() {
    showDialog(
      context: context,
      builder: (context) => AddDriverDialog(
        onDriverAdded: () {
          ref.invalidate(vendorDriversProvider);
          ref.invalidate(driverStatisticsProvider);
        },
      ),
    );
  }

  void _showDriverDetails(Driver driver) {
    // TODO: Navigate to driver details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Driver details for ${driver.name} - Coming soon!'),
      ),
    );
  }


}
