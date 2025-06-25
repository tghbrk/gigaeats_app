import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../features/vendors/presentation/providers/vendor_provider.dart';
import '../../../../features/vendors/data/models/vendor.dart';
import '../../../../features/menu/data/models/product.dart';
import '../providers/customer_cart_provider.dart';
import '../providers/customer_product_provider.dart';
import '../providers/vendor_details_provider.dart';
import '../widgets/vendor_gallery_widget.dart';
import '../widgets/vendor_business_hours_widget.dart';
import '../../utils/vendor_utils.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../shared/widgets/custom_error_widget.dart';

class CustomerRestaurantDetailsScreen extends ConsumerStatefulWidget {
  final String restaurantId;

  const CustomerRestaurantDetailsScreen({
    super.key,
    required this.restaurantId,
  });

  @override
  ConsumerState<CustomerRestaurantDetailsScreen> createState() => _CustomerRestaurantDetailsScreenState();
}

class _CustomerRestaurantDetailsScreenState extends ConsumerState<CustomerRestaurantDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Load vendor data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(vendorsProvider.notifier).loadVendors();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vendorState = ref.watch(vendorsProvider);
    final cartState = ref.watch(customerCartProvider);
    final theme = Theme.of(context);

    // Find the current vendor
    final vendor = vendorState.vendors.where((v) => v.id == widget.restaurantId).firstOrNull;

    if (vendor == null && !vendorState.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Restaurant Not Found')),
        body: const Center(child: Text('Restaurant not found')),
      );
    }

    return Scaffold(
      body: vendorState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              slivers: [
                _buildSliverAppBar(vendor!, theme),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildRestaurantInfo(vendor, theme),
                      _buildTabBar(theme),
                    ],
                  ),
                ),
                SliverFillRemaining(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildMenuTab(vendor),
                      _buildInfoTab(vendor),
                    ],
                  ),
                ),
              ],
            ),
      bottomNavigationBar: cartState.items.isNotEmpty ? _buildCartBottomBar(cartState, theme) : null,
    );
  }

  Widget _buildSliverAppBar(Vendor vendor, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          vendor.businessName,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            shadows: [Shadow(color: Colors.black54, blurRadius: 2)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            vendor.coverImageUrl != null
                ? Image.network(
                    vendor.coverImageUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => _buildImagePlaceholder(),
                  )
                : _buildImagePlaceholder(),
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
      actions: [
        Consumer(
          builder: (context, ref, child) {
            final favoriteAsync = ref.watch(vendorFavoriteNotifierProvider(vendor.id));
            return favoriteAsync.when(
              data: (isFavorited) => IconButton(
                icon: Icon(
                  isFavorited ? Icons.favorite : Icons.favorite_border,
                  color: isFavorited ? Colors.red : null,
                ),
                onPressed: () {
                  ref.read(vendorFavoriteNotifierProvider(vendor.id).notifier).toggleFavorite();
                },
              ),
              loading: () => const IconButton(
                icon: Icon(Icons.favorite_border),
                onPressed: null,
              ),
              error: (_, _) => IconButton(
                icon: const Icon(Icons.favorite_border),
                onPressed: () {
                  ref.read(vendorFavoriteNotifierProvider(vendor.id).notifier).toggleFavorite();
                },
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareVendor(vendor),
        ),
      ],
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Icon(
          Icons.restaurant,
          size: 64,
          color: Colors.grey[400],
        ),
      ),
    );
  }

  Widget _buildRestaurantInfo(Vendor vendor, ThemeData theme) {
    final isOpen = VendorUtils.isVendorOpen(vendor);
    final statusText = VendorUtils.getVendorStatusText(vendor);
    final estimatedDeliveryTime = VendorUtils.getEstimatedDeliveryTime(vendor);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating and basic info
          Row(
            children: [
              Icon(Icons.star, color: Colors.amber[600], size: 20),
              const SizedBox(width: 4),
              Text(
                '${vendor.rating.toStringAsFixed(1)} (${vendor.totalReviews} reviews)',
                style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOpen ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  statusText,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isOpen ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Cuisine types and features
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              ...vendor.cuisineTypes.map((cuisine) => Chip(
                label: Text(cuisine),
                backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                labelStyle: TextStyle(color: theme.colorScheme.primary),
              )),
              if (vendor.isHalalCertified)
                Chip(
                  label: const Text('Halal'),
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  labelStyle: const TextStyle(color: Colors.green),
                  avatar: const Icon(Icons.verified, size: 16, color: Colors.green),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Delivery info
          Row(
            children: [
              Icon(Icons.delivery_dining, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                'Delivery: RM ${vendor.deliveryFee?.toStringAsFixed(2) ?? '5.00'}',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(width: 16),
              Icon(Icons.access_time, color: Colors.grey[600], size: 20),
              const SizedBox(width: 8),
              Text(
                estimatedDeliveryTime,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
          
          if (vendor.minimumOrderAmount != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.shopping_cart, color: Colors.grey[600], size: 20),
                const SizedBox(width: 8),
                Text(
                  'Min order: RM ${vendor.minimumOrderAmount!.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ],
          
          if (vendor.description?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            Text(
              vendor.description!,
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[700]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: Colors.grey[600],
        indicatorColor: theme.colorScheme.primary,
        tabs: const [
          Tab(text: 'Menu'),
          Tab(text: 'Info'),
        ],
      ),
    );
  }

  Widget _buildMenuTab(Vendor vendor) {
    final productsAsync = ref.watch(vendorProductsProvider(vendor.id));

    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.restaurant_menu, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No menu items available'),
                SizedBox(height: 8),
                Text('This restaurant hasn\'t added any menu items yet.'),
              ],
            ),
          );
        }

        return Column(
          children: [
            _buildSearchAndFilter(products),
            Expanded(
              child: _buildMenuList(_filterProducts(products)),
            ),
          ],
        );
      },
      loading: () => const LoadingWidget(message: 'Loading menu items...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load menu items: $error',
        onRetry: () => ref.refresh(vendorProductsProvider(vendor.id)),
      ),
    );
  }

  Widget _buildSearchAndFilter(List<Product> products) {
    final categories = ['All', ...products.map((p) => p.category).toSet()];
    
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search menu items...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          
          const SizedBox(height: 12),
          
          // Category filter
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = _selectedCategory == category;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) => setState(() => _selectedCategory = category),
                    backgroundColor: Colors.grey[100],
                    selectedColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<Product> _filterProducts(List<Product> products) {
    var filtered = products.where((product) => product.isAvailable ?? true).toList();

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               (product.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    // Apply category filter
    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    return filtered;
  }

  Widget _buildMenuList(List<Product> products) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _buildMenuItemCard(product);
      },
    );
  }

  Widget _buildMenuItemCard(Product product) {
    final theme = Theme.of(context);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _showMenuItemDetails(product),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: product.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          product.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.fastfood,
                            color: Colors.grey[400],
                          ),
                        ),
                      )
                    : Icon(Icons.fastfood, color: Colors.grey[400]),
              ),
              
              const SizedBox(width: 12),
              
              // Product details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    
                    if (product.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        product.description!,
                        style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    const SizedBox(height: 8),
                    
                    // Tags and features
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        if (product.isHalal == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Halal',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green[700],
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (product.isVegetarian == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Vegetarian',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.orange[700],
                                fontSize: 10,
                              ),
                            ),
                          ),
                        if (product.isSpicy == true)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Spicy',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.red[700],
                                fontSize: 10,
                              ),
                            ),
                          ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Price and add button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'RM ${product.basePrice.toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        CustomButton(
                          text: 'Add',
                          onPressed: () => _addToCart(product),
                          type: ButtonType.primary,
                          isExpanded: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTab(Vendor vendor) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Gallery
          if (vendor.coverImageUrl != null || vendor.galleryImages.isNotEmpty) ...[
            VendorGalleryWidget(
              coverImageUrl: vendor.coverImageUrl,
              galleryImages: vendor.galleryImages,
              vendorName: vendor.businessName,
            ),
            const SizedBox(height: 24),
          ],

          // Business Hours
          VendorBusinessHoursWidget(vendor: vendor),
          const SizedBox(height: 24),

          // Placeholder for Promotions (will be enabled when database is ready)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Promotions & Offers',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Promotions feature will be available once database tables are created.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Placeholder for Reviews (will be enabled when database is ready)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Customer Reviews',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reviews feature will be available once database tables are created.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          _buildInfoSection(
            'Business Information',
            [
              _buildInfoRow('Business Name', vendor.businessName),
              _buildInfoRow('Registration Number', vendor.businessRegistrationNumber),
              _buildInfoRow('Business Type', vendor.businessType),
              if (vendor.isHalalCertified && vendor.halalCertificationNumber != null)
                _buildInfoRow('Halal Certification', vendor.halalCertificationNumber!),
            ],
          ),

          const SizedBox(height: 24),

          _buildInfoSection(
            'Contact & Location',
            [
              _buildInfoRow('Address', vendor.businessAddress),
              if (vendor.serviceAreas?.isNotEmpty == true)
                _buildInfoRow('Service Areas', vendor.serviceAreas!.join(', ')),
            ],
          ),

          const SizedBox(height: 24),

          _buildInfoSection(
            'Delivery Information',
            [
              _buildInfoRow('Delivery Fee', VendorUtils.formatDeliveryFee(
                vendor.deliveryFee,
                vendor.freeDeliveryThreshold,
                0.0
              )),
              if (vendor.minimumOrderAmount != null)
                _buildInfoRow('Minimum Order', 'RM ${vendor.minimumOrderAmount!.toStringAsFixed(2)}'),
              if (vendor.freeDeliveryThreshold != null)
                _buildInfoRow('Free Delivery Above', 'RM ${vendor.freeDeliveryThreshold!.toStringAsFixed(2)}'),
              _buildInfoRow('Estimated Delivery', VendorUtils.getEstimatedDeliveryTime(vendor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartBottomBar(CustomerCartState cartState, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.2),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${cartState.totalItems}',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'View Cart',
                    style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'RM ${cartState.totalAmount.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            CustomButton(
              text: 'View Cart',
              onPressed: () => context.push('/customer/cart'),
              type: ButtonType.primary,
              isExpanded: false,
            ),
          ],
        ),
      ),
    );
  }

  void _showMenuItemDetails(Product product) {
    context.push('/customer/menu-item/${product.id}');
  }



  void _addToCart(Product product) {
    if (product.customizations.isNotEmpty) {
      // Show customization dialog
      _showMenuItemDetails(product);
    } else {
      // Add directly to cart - for now just show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${product.name} added to cart'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _shareVendor(Vendor vendor) {
    // TODO: Implement proper sharing functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${vendor.businessName}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
