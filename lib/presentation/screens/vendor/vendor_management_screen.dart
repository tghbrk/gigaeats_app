import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/vendor.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/profile_image_picker.dart';
import '../../../core/utils/responsive_utils.dart';

class VendorManagementScreen extends ConsumerStatefulWidget {
  const VendorManagementScreen({super.key});

  @override
  ConsumerState<VendorManagementScreen> createState() => _VendorManagementScreenState();
}

class _VendorManagementScreenState extends ConsumerState<VendorManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String? _selectedCuisineType;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Use platform-aware data fetching
    final vendorsAsync = kIsWeb
        ? ref.watch(platformVendorsProvider)
        : ref.watch(vendorsStreamProvider({
            'searchQuery': _searchQuery.isEmpty ? null : _searchQuery,
            'cuisineTypes': _selectedCuisineType != null ? [_selectedCuisineType!] : null,
            'location': null,
          }));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vendor Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All Vendors', icon: Icon(Icons.restaurant)),
            Tab(text: 'Pending', icon: Icon(Icons.pending)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddVendorDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (kIsWeb) {
                ref.invalidate(platformVendorsProvider);
              } else {
                ref.invalidate(vendorsStreamProvider);
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Search Bar
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search vendors...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest,
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                ),
                const SizedBox(height: 12),
                
                // Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _selectedCuisineType == null,
                        onSelected: (selected) {
                          setState(() {
                            _selectedCuisineType = null;
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      ...['Malaysian', 'Chinese', 'Indian', 'Western', 'Japanese', 'Thai'].map(
                        (cuisine) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(cuisine),
                            selected: _selectedCuisineType == cuisine,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCuisineType = selected ? cuisine : null;
                              });
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildVendorsList(vendorsAsync, showAll: true),
                _buildVendorsList(vendorsAsync, showAll: false),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVendorsList(AsyncValue vendorsAsync, {required bool showAll}) {
    return vendorsAsync.when(
      data: (vendorsData) {
        List<Vendor> vendors;

        // Handle different data types based on platform
        if (kIsWeb && vendorsData is List<Vendor>) {
          // Web platform returns List<Vendor> from platformVendorsProvider
          vendors = vendorsData;
        } else if (vendorsData is List<dynamic>) {
          // Mobile platform returns List<dynamic> from vendorsStreamProvider
          vendors = vendorsData.map((data) => Vendor.fromJson(data)).toList();
        } else {
          vendors = [];
        }

        // Apply search and cuisine type filters for web platform
        if (kIsWeb) {
          if (_searchQuery.isNotEmpty) {
            vendors = vendors
                .where((vendor) => vendor.businessName.toLowerCase().contains(_searchQuery.toLowerCase()))
                .toList();
          }

          if (_selectedCuisineType != null) {
            vendors = vendors
                .where((vendor) => vendor.cuisineTypes.contains(_selectedCuisineType))
                .toList();
          }
        }

        if (vendors.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 64,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'No vendors found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Try adjusting your search or filters',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          );
        }

        // Filter based on tab
        final filteredVendors = showAll
            ? vendors
            : vendors.where((vendor) => !vendor.isVerified).toList();

        if (filteredVendors.isEmpty && !showAll) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 64, color: Colors.green),
                SizedBox(height: 16),
                Text('No pending vendors'),
                Text('All vendors are verified!'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            if (kIsWeb) {
              ref.invalidate(platformVendorsProvider);
            } else {
              ref.invalidate(vendorsStreamProvider);
            }
          },
          child: ResponsiveContainer(
            child: context.isDesktop
                ? _buildDesktopVendorsList(filteredVendors)
                : _buildMobileVendorsList(filteredVendors),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error loading vendors: $error'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (kIsWeb) {
                  ref.invalidate(platformVendorsProvider);
                } else {
                  ref.invalidate(vendorsStreamProvider);
                }
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileVendorsList(List<Vendor> vendors) {
    return ListView.builder(
      padding: context.responsivePadding,
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return _buildVendorCard(vendor);
      },
    );
  }

  Widget _buildDesktopVendorsList(List<Vendor> vendors) {
    return GridView.builder(
      padding: context.responsivePadding,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: context.gridColumns,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: vendors.length,
      itemBuilder: (context, index) {
        final vendor = vendors[index];
        return _buildVendorCard(vendor);
      },
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/vendor-details/${vendor.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Vendor Image
              ProfileImagePicker(
                currentImageUrl: vendor.coverImageUrl,
                userId: vendor.id,
                size: 60,
                isEditable: false,
              ),
              const SizedBox(width: 16),

              // Vendor Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.businessName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        if (vendor.isVerified)
                          Icon(Icons.verified, color: Colors.blue.shade600, size: 20),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor.cuisineTypes.join(', '),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.star, color: Colors.amber.shade600, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          vendor.rating.toStringAsFixed(1),
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${vendor.totalOrders} orders',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: vendor.isActive ? Colors.green.shade100 : Colors.red.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            vendor.isActive ? 'Active' : 'Inactive',
                            style: TextStyle(
                              color: vendor.isActive ? Colors.green.shade700 : Colors.red.shade700,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action Button
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () => _showVendorActions(vendor),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.analytics, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Analytics Coming Soon'),
          Text('Vendor performance metrics and insights'),
        ],
      ),
    );
  }

  void _showVendorActions(Vendor vendor) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.visibility),
              title: const Text('View Details'),
              onTap: () {
                Navigator.pop(context);
                context.push('/vendor-details/${vendor.id}');
              },
            ),
            if (!vendor.isVerified)
              ListTile(
                leading: const Icon(Icons.verified, color: Colors.green),
                title: const Text('Approve Vendor'),
                onTap: () {
                  Navigator.pop(context);
                  _approveVendor(vendor);
                },
              ),
            ListTile(
              leading: Icon(
                vendor.isActive ? Icons.pause : Icons.play_arrow,
                color: vendor.isActive ? Colors.orange : Colors.green,
              ),
              title: Text(vendor.isActive ? 'Deactivate' : 'Activate'),
              onTap: () {
                Navigator.pop(context);
                _toggleVendorStatus(vendor);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Vendor'),
              onTap: () {
                Navigator.pop(context);
                _editVendor(vendor);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showAddVendorDialog() {
    // TODO: Implement add vendor dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Add vendor feature coming soon')),
    );
  }

  void _approveVendor(Vendor vendor) {
    // TODO: Implement vendor approval
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${vendor.businessName} approved')),
    );
  }

  void _toggleVendorStatus(Vendor vendor) {
    // TODO: Implement vendor status toggle
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '${vendor.businessName} ${vendor.isActive ? 'deactivated' : 'activated'}',
        ),
      ),
    );
  }

  void _editVendor(Vendor vendor) {
    // TODO: Implement vendor editing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Edit ${vendor.businessName}')),
    );
  }
}
