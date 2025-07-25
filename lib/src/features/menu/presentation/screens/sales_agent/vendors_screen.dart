import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../vendors/data/models/vendor.dart';
// import '../../../vendors/presentation/providers/vendor_provider.dart' as vendor_provider; // Unused
import '../../../../user_management/presentation/providers/vendor_provider.dart' as user_vendor_provider;
// import '../../../../presentation/providers/repository_providers.dart'; // Unused
// import '../../data/models/vendor_filters.dart'; // Using user_vendor_provider.VendorFilters instead

import '../../../../core/widgets/search_bar_widget.dart';


class VendorsScreen extends ConsumerStatefulWidget {
  const VendorsScreen({super.key});

  @override
  ConsumerState<VendorsScreen> createState() => _VendorsScreenState();
}

class _VendorsScreenState extends ConsumerState<VendorsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorsState = ref.watch(user_vendor_provider.vendorsProvider);
    // TODO: Fix featuredVendorsProvider import issue - commenting out for now
    // final featuredVendorsAsync = ref.watch(featuredVendorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Browse Vendors'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterBottomSheet(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(user_vendor_provider.vendorsProvider.notifier).refresh();
          // ref.invalidate(featuredVendorsProvider); // TODO: Fix provider import
        },
        child: CustomScrollView(
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SearchBarWidget(
                  // controller parameter temporarily removed for quick launch
                  hintText: 'Search vendors, cuisine types...',
                  onChanged: (query) {
                    ref.read(user_vendor_provider.vendorsProvider.notifier).updateSearchQuery(query);
                  },
                  // onClear parameter temporarily removed for quick launch
                ),
              ),
            ),

            // Active Filters
            if (vendorsState.filters.hasActiveFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Filters',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(user_vendor_provider.vendorsProvider.notifier).clearFilters();
                              _searchController.clear();
                            },
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _buildActiveFilters(vendorsState.filters),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

            // Featured Vendors Section
            if (!vendorsState.filters.hasActiveFilters)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Featured Vendors',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // TODO: Restore featured vendors section when provider is fixed
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'Featured vendors section temporarily disabled',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

            // All Vendors Section
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  vendorsState.filters.hasActiveFilters
                      ? 'Search Results (${vendorsState.vendors.length})'
                      : 'All Vendors',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Vendors List
            if (vendorsState.isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
              )
            else if (vendorsState.errorMessage != null)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Theme.of(context).colorScheme.error,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading vendors',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vendorsState.errorMessage!,
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(user_vendor_provider.vendorsProvider.notifier).refresh();
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (vendorsState.vendors.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No vendors found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your search or filters',
                          style: Theme.of(context).textTheme.bodyMedium,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final vendor = vendorsState.vendors[index];
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: index < vendorsState.vendors.length - 1 ? 16 : 32,
                        ),
                        child: Card(
                          child: ListTile(
                            title: Text(vendor.businessName),
                            subtitle: Text(vendor.description ?? 'No description'),
                            onTap: () => _navigateToVendorDetails(vendor),
                          ),
                        ),
                      );
                    },
                    childCount: vendorsState.vendors.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters(user_vendor_provider.VendorFilters filters) {
    final chips = <Widget>[];

    if (filters.searchQuery?.isNotEmpty ?? false) {
      chips.add(
        FilterChip(
          label: Text('Search: ${filters.searchQuery}'),
          selected: true,
          onSelected: (_) {},
          onDeleted: () {
            _searchController.clear();
            ref.read(user_vendor_provider.vendorsProvider.notifier).updateSearchQuery('');
          },
        ),
      );
    }

    for (final cuisine in filters.cuisineTypes) {
      chips.add(
        FilterChip(
          label: Text(cuisine),
          selected: true,
          onSelected: (_) {},
          onDeleted: () {
            ref.read(user_vendor_provider.vendorsProvider.notifier).toggleCuisineType(cuisine);
          },
        ),
      );
    }

    if (filters.minRating != null) {
      chips.add(
        FilterChip(
          label: Text('Rating: ${filters.minRating}+ ⭐'),
          selected: true,
          onSelected: (_) {},
          onDeleted: () {
            ref.read(user_vendor_provider.vendorsProvider.notifier).setMinRating(null);
          },
        ),
      );
    }

    // TODO: Fix VendorFilters type mismatch - isHalalOnly property not available
    // if (filters.isHalalOnly) {
    //   chips.add(
    //     FilterChip(
    //       label: const Text('Halal Only'),
    //       selected: true,
    //       onSelected: (_) {},
    //       onDeleted: () {
    //         ref.read(user_vendor_provider.vendorsProvider.notifier).toggleHalalOnly();
    //       },
    //     ),
    //   );
    // }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: chips,
    );
  }

  void _showFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => const VendorFiltersBottomSheet(),
    );
  }

  void _navigateToVendorDetails(Vendor vendor) {
    context.push('/vendor-details/${vendor.id}');
  }
}

// Placeholder for filter bottom sheet
class VendorFiltersBottomSheet extends ConsumerWidget {
  const VendorFiltersBottomSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Filters',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          const Text('Filter options coming soon...'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
