import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:go_router/go_router.dart';

import '../../../vendors/data/models/vendor.dart';
import '../../../menu/data/models/product.dart';
import '../../../vendors/presentation/providers/vendor_provider.dart';
import '../../../../presentation/providers/repository_providers.dart';
import '../providers/cart_provider.dart';
import '../../../menu/presentation/widgets/product_card.dart';
import 'product_details_screen.dart';

class VendorDetailsScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const VendorDetailsScreen({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<VendorDetailsScreen> createState() => _VendorDetailsScreenState();
}

class _VendorDetailsScreenState extends ConsumerState<VendorDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';

  // Create stable parameters to prevent provider recreation - following TestMenuScreen pattern
  late final Map<String, dynamic> _stableProviderParams;

  @override
  void initState() {
    super.initState();
    debugPrint('🔧 VendorDetailsScreen: initState() called for vendor ${widget.vendorId}');
    _tabController = TabController(length: 2, vsync: this);

    // Create stable parameters once and never change them - no category filtering in provider
    _stableProviderParams = {
      'vendorId': widget.vendorId,
      'isAvailable': true,
      'useStream': !kIsWeb, // Use stream for mobile, future for web
    };
    debugPrint('🔧 VendorDetailsScreen: initState() completed, stable params: $_stableProviderParams');
  }

  @override
  void dispose() {
    debugPrint('🔧 VendorDetailsScreen: dispose() called for vendor ${widget.vendorId}');
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🔧 VendorDetailsScreen: build() called for vendor ${widget.vendorId}');

    final vendorAsync = ref.watch(vendorDetailsProvider(widget.vendorId));
    final cartState = ref.watch(cartProvider);

    // Use stable provider parameters - following TestMenuScreen pattern
    final productsAsync = ref.watch(platformMenuItemsProvider(_stableProviderParams));

    debugPrint('🔧 VendorDetailsScreen: About to build Scaffold');

    return Scaffold(
      body: vendorAsync.when(
        data: (vendor) {
          debugPrint('🔧 VendorDetailsScreen: vendorAsync.when.data() called');
          if (vendor == null) {
            debugPrint('🔧 VendorDetailsScreen: Vendor is null, showing not found');
            return const Center(child: Text('Vendor not found'));
          }
          debugPrint('🔧 VendorDetailsScreen: About to call _buildVendorDetails');
          final result = _buildVendorDetails(vendor, productsAsync, cartState);
          debugPrint('🔧 VendorDetailsScreen: _buildVendorDetails completed');
          return result;
        },
        loading: () {
          debugPrint('🔧 VendorDetailsScreen: vendorAsync.when.loading() called');
          return const Center(child: CircularProgressIndicator());
        },
        error: (error, stack) {
          debugPrint('🔧 VendorDetailsScreen: vendorAsync.when.error() called: $error');
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error loading vendor: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(vendorDetailsProvider(widget.vendorId)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: cartState.isEmpty
          ? null
          : FloatingActionButton.extended(
              heroTag: "vendor_details_cart_fab",
              onPressed: () => _showCartSummary(context),
              icon: const Icon(Icons.shopping_cart),
              label: Text('Cart (${cartState.totalItems})'),
            ),
    );
  }

  Widget _buildVendorDetails(Vendor vendor, AsyncValue<List<Product>> productsAsync, CartState cartState) {
    debugPrint('🔧 _buildVendorDetails: Called with vendor ${vendor.businessName}');
    debugPrint('🔧 _buildVendorDetails: productsAsync state: ${productsAsync.runtimeType}');
    debugPrint('🔧 _buildVendorDetails: cartState: ${cartState.totalItems} items');

    final theme = Theme.of(context);

    return CustomScrollView(
      slivers: [
        // App Bar with Vendor Image
        SliverAppBar(
          expandedHeight: 250,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              vendor.businessName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    offset: Offset(0, 1),
                    blurRadius: 3,
                    color: Colors.black54,
                  ),
                ],
              ),
            ),
            background: Stack(
              fit: StackFit.expand,
              children: [
                vendor.coverImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: vendor.coverImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(
                            child: Icon(Icons.restaurant, size: 64),
                          ),
                        ),
                      )
                    : Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: Icon(Icons.restaurant, size: 64),
                        ),
                      ),
                // Gradient overlay
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Vendor Information
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rating and Verification
                Row(
                  children: [
                    Icon(Icons.star, color: Colors.amber.shade600, size: 20),
                    const SizedBox(width: 4),
                    Text(
                      vendor.rating.toStringAsFixed(1),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '(${vendor.totalReviews} reviews)',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    if (vendor.isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified, size: 16, color: Colors.blue.shade700),
                            const SizedBox(width: 4),
                            Text(
                              'Verified',
                              style: TextStyle(
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  vendor.description ?? 'No description available',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 16),

                // Cuisine Types
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: vendor.cuisineTypes.map((cuisine) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        cuisine,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 16),

                // Business Info
                _buildInfoRow(Icons.location_on, 'Location', vendor.fullAddress),
                _buildInfoRow(Icons.access_time, 'Operating Hours', 'Mon-Sun: 9:00 AM - 10:00 PM'),
                _buildInfoRow(Icons.delivery_dining, 'Delivery Radius', '10 km'),
                _buildInfoRow(Icons.shopping_cart, 'Min Order', 'RM ${(vendor.minimumOrderAmount ?? 0.0).toStringAsFixed(0)}'),

                if (vendor.isHalalCertified)
                  _buildInfoRow(Icons.verified, 'Halal Certified', 'Yes'),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Tab Bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _SliverTabBarDelegate(
            TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Menu'),
                Tab(text: 'Info'),
              ],
            ),
          ),
        ),

        // Tab Content
        SliverFillRemaining(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMenuTab(productsAsync),
              _buildInfoTab(vendor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuTab(AsyncValue<List<Product>> productsAsync) {
    debugPrint('🔧 _buildMenuTab: Called with productsAsync state: ${productsAsync.runtimeType}');

    return productsAsync.when(
      data: (products) {
        debugPrint('VendorDetailsScreen: Got ${products.length} menu items');
        debugPrint('VendorDetailsScreen: First few items: ${products.take(3).map((p) => p.name).toList()}');

        if (products.isEmpty) {
          debugPrint('VendorDetailsScreen: No products found, showing empty state');
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No menu items available'),
              ],
            ),
          );
        }

        debugPrint('VendorDetailsScreen: Successfully loaded ${products.length} products');

        // Get unique categories
        final categories = ['All', ...products.map((p) => p.category).toSet()];

        // Filter products by selected category - CLIENT-SIDE FILTERING to prevent infinite loops
        final filteredProducts = _selectedCategory == 'All'
            ? products
            : products.where((p) => p.category == _selectedCategory).toList();

        return Column(
          children: [
            // Category Filter
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        debugPrint('VendorDetailsScreen: Category filter changed from $_selectedCategory to $category');
                        setState(() {
                          _selectedCategory = category;
                        });
                        debugPrint('VendorDetailsScreen: setState completed, new category = $_selectedCategory');
                      },
                    ),
                  );
                },
              ),
            ),

            // Products Grid
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.525, // Perfect adjustment to eliminate the last 0.143 pixels
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  final product = filteredProducts[index];
                  return ProductCard(
                    product: product,
                    onTap: () => _showProductDetails(product),
                    onAddToCart: () => _addToCart(product),
                  );
                },
              ),
            ),
          ],
        );
      },
      loading: () {
        debugPrint('VendorDetailsScreen: Menu items loading...');
        return const Center(child: CircularProgressIndicator());
      },
      error: (error, stack) {
        debugPrint('VendorDetailsScreen: Menu items error: $error');
        debugPrint('VendorDetailsScreen: Stack trace: $stack');
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error loading menu: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  debugPrint('VendorDetailsScreen: Retrying menu items load...');
                  // Use stable provider parameters for retry - no dynamic parameters
                  ref.invalidate(platformMenuItemsProvider(_stableProviderParams));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildInfoTab(Vendor vendor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Business Information',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoCard('Business Details', [
            'Owner: ${vendor.ownerName}',
            'Email: ${vendor.email}',
            'Phone: ${vendor.phoneNumber}',
            'SSM: ${vendor.businessRegistrationNumber}',
          ]),
          const SizedBox(height: 16),
          _buildInfoCard('Operating Information', [
            'Min Order: RM ${(vendor.minimumOrderAmount ?? 0.0).toStringAsFixed(0)}',
            'Delivery Radius: 10 km',
            'Payment Methods: Cash, Online Banking',
          ]),
          if (vendor.isHalalCertified) ...[
            const SizedBox(height: 16),
            _buildInfoCard('Certifications', [
              'Halal Certified: Yes',
              if (vendor.halalCertificationNumber != null)
                'Halal Cert No: ${vendor.halalCertificationNumber}',
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<String> items) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...items.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(item),
            )),
          ],
        ),
      ),
    );
  }

  void _addToCart(Product product) {
    final vendorAsync = ref.read(vendorDetailsProvider(widget.vendorId));

    vendorAsync.whenData((vendor) {
      if (vendor != null) {
        ref.read(cartProvider.notifier).addItem(
          product: product,
          vendor: vendor,
          quantity: 1,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${product.name} added to cart'),
            action: SnackBarAction(
              label: 'View Cart',
              onPressed: () => _showCartSummary(context),
            ),
          ),
        );
      }
    });
  }

  void _showProductDetails(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailsScreen(product: product),
      ),
    );
  }

  void _showCartSummary(BuildContext context) {
    context.push('/sales-agent/cart');
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverTabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) => false;
}
