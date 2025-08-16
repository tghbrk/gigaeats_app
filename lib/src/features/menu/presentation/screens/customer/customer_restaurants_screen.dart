import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../user_management/presentation/providers/vendor_provider.dart';
import '../../../../user_management/domain/vendor.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../core/utils/logger.dart';
import '../../../../../design_system/layout/ge_screen.dart';
import '../../../../../design_system/navigation/ge_app_bar.dart';
import '../../../../../design_system/navigation/ge_bottom_navigation.dart';
import '../../../../../design_system/widgets/buttons/ge_button.dart';
import '../../../../data/models/user_role.dart';

class CustomerRestaurantsScreen extends ConsumerStatefulWidget {
  const CustomerRestaurantsScreen({super.key});

  @override
  ConsumerState<CustomerRestaurantsScreen> createState() => _CustomerRestaurantsScreenState();
}

class _CustomerRestaurantsScreenState extends ConsumerState<CustomerRestaurantsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final AppLogger _logger = AppLogger();
  String _searchQuery = '';
  String _selectedCuisine = 'All';
  String _sortBy = 'rating';

  @override
  void initState() {
    super.initState();
    _logger.info('🏪 [RESTAURANTS-SCREEN] Screen initialized');
    // Load vendors when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _logger.info('🏪 [RESTAURANTS-SCREEN] Loading vendors...');
      ref.read(vendorsProvider.notifier).loadVendors();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorsProvider);

    // Debug logging for UI state
    _logger.info('🏪 [RESTAURANTS-SCREEN] Building UI with state:');
    _logger.info('  - Loading: ${vendorState.isLoading}');
    _logger.info('  - Error: ${vendorState.errorMessage}');
    _logger.info('  - Vendors count: ${vendorState.vendors.length}');
    _logger.info('  - Search query: $_searchQuery');
    _logger.info('  - Selected cuisine: $_selectedCuisine');
    _logger.info('  - Sort by: $_sortBy');

    return GEScreen(
      appBar: GEAppBar.withRole(
        title: 'Restaurants',
        userRole: UserRole.customer,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildFilterChips(),
          Expanded(
            child: vendorState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : vendorState.errorMessage != null
                    ? _buildErrorState(vendorState.errorMessage!)
                    : _buildRestaurantsList(vendorState.vendors),
          ),
        ],
      ),
      bottomNavigationBar: GEBottomNavigation.navigationBar(
        destinations: GERoleNavigationConfig.customer.destinations,
        selectedIndex: 1, // Restaurants is selected
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/customer/dashboard');
              break;
            case 1:
              // Already on restaurants
              break;
            case 2:
              context.push('/customer/cart');
              break;
            case 3:
              context.push('/customer/orders');
              break;
            case 4:
              context.push('/customer/profile');
              break;
          }
        },
        userRole: UserRole.customer,
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search restaurants, cuisines...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: Colors.grey[50],
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
      ),
    );
  }

  Widget _buildFilterChips() {
    final cuisines = ['All', 'Malaysian', 'Chinese', 'Indian', 'Western', 'Japanese', 'Thai'];
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: cuisines.length,
        itemBuilder: (context, index) {
          final cuisine = cuisines[index];
          final isSelected = _selectedCuisine == cuisine;
          
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(cuisine),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedCuisine = cuisine;
                });
              },
              backgroundColor: Colors.grey[100],
              selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
              checkmarkColor: Theme.of(context).colorScheme.primary,
            ),
          );
        },
      ),
    );
  }

  Widget _buildRestaurantsList(List<Vendor> vendors) {
    _logger.info('🏪 [RESTAURANTS-SCREEN] Building restaurants list with ${vendors.length} vendors');

    final filteredVendors = _filterVendors(vendors);
    _logger.info('🏪 [RESTAURANTS-SCREEN] After filtering: ${filteredVendors.length} vendors');
    _logger.info('🏪 [RESTAURANTS-SCREEN] Filtered vendor names: ${filteredVendors.map((v) => v.businessName).join(', ')}');

    if (filteredVendors.isEmpty) {
      _logger.info('❌ [RESTAURANTS-SCREEN] No vendors to display - showing empty state');
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () {
        _logger.info('🔄 [RESTAURANTS-SCREEN] Pull to refresh triggered');
        return ref.read(vendorsProvider.notifier).loadVendors();
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredVendors.length,
        itemBuilder: (context, index) {
          final vendor = filteredVendors[index];
          return _buildRestaurantCard(vendor);
        },
      ),
    );
  }

  Widget _buildRestaurantCard(Vendor vendor) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/customer/restaurant/${vendor.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Restaurant image
            Container(
              height: 160,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                color: Colors.grey[200],
              ),
              child: vendor.coverImageUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                      child: Image.network(
                        vendor.coverImageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                      ),
                    )
                  : _buildImagePlaceholder(),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Restaurant name and rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          vendor.businessName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Icon(
                            Icons.star,
                            size: 16,
                            color: Colors.amber[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '4.5', // TODO: Get actual rating
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Cuisine type and delivery info
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        vendor.cuisineTypes.isNotEmpty ? vendor.cuisineTypes.first : 'Various',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '30-45 min', // TODO: Get actual delivery time
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Address
                  Row(
                    children: [
                      Icon(
                        Icons.location_on,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${vendor.address.city}, ${vendor.address.state}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Status and action button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: vendor.isActive 
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          vendor.isActive ? 'Open' : 'Closed',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: vendor.isActive ? Colors.green[700] : Colors.red[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GEButton.primary(
                        text: 'View Menu',
                        onPressed: vendor.isActive
                            ? () => context.push('/customer/restaurant/${vendor.id}')
                            : null,
                        size: GEButtonSize.small,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 48,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    _logger.info('📭 [RESTAURANTS-SCREEN] Displaying empty state - no restaurants found');
    _logger.info('📭 [RESTAURANTS-SCREEN] Current filters: search="$_searchQuery", cuisine="$_selectedCuisine", sort="$_sortBy"');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No restaurants found',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filters',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Something went wrong',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            GEButton.primary(
              text: 'Try Again',
              // TODO: Fix vendorsProvider import
              onPressed: () {}, // => ref.read(vendorsProvider.notifier).loadVendors(),
            ),
          ],
        ),
      ),
    );
  }

  List<Vendor> _filterVendors(List<Vendor> vendors) {
    var filtered = vendors.where((vendor) => vendor.isActive).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((vendor) {
        return vendor.businessName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               vendor.cuisineTypes.any((cuisine) => cuisine.toLowerCase().contains(_searchQuery.toLowerCase()));
      }).toList();
    }

    // Apply cuisine filter
    if (_selectedCuisine != 'All') {
      filtered = filtered.where((vendor) {
        return vendor.cuisineTypes.any((cuisine) => cuisine.toLowerCase() == _selectedCuisine.toLowerCase());
      }).toList();
    }

    // Apply sorting
    switch (_sortBy) {
      case 'rating':
        // TODO: Sort by actual rating when available
        break;
      case 'distance':
        // TODO: Sort by distance when location is available
        break;
      case 'name':
        filtered.sort((a, b) => a.businessName.compareTo(b.businessName));
        break;
    }

    return filtered;
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Sort By',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...['rating', 'distance', 'name'].map((sort) => RadioListTile<String>(
              title: Text(_getSortDisplayName(sort)),
              value: sort,
              groupValue: _sortBy,
              onChanged: (value) {
                setState(() {
                  _sortBy = value!;
                });
                Navigator.pop(context);
              },
            )),
          ],
        ),
      ),
    );
  }

  String _getSortDisplayName(String sort) {
    switch (sort) {
      case 'rating':
        return 'Rating';
      case 'distance':
        return 'Distance';
      case 'name':
        return 'Name';
      default:
        return sort;
    }
  }


}
