import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../user_management/presentation/providers/vendor_provider.dart';
import '../../../../user_management/domain/vendor.dart';
import '../../../data/models/product.dart';
import '../../../../orders/presentation/providers/customer/customer_cart_provider.dart';
import '../../providers/customer/customer_product_provider.dart';
import '../../widgets/customer/vendor_business_hours_widget.dart';
import '../../widgets/customer/vendor_gallery_widget.dart';
import '../../widgets/customer/restaurant_info_card.dart';
import '../../widgets/customer/menu_item_card.dart';

import '../../widgets/customer/category_filter_tabs.dart';
import '../../widgets/customer/quantity_selector_dialog.dart';
import '../../widgets/customer/menu_search_bar.dart';
import '../../../../user_management/application/vendor_utils.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../../shared/widgets/custom_error_widget.dart';
import '../../../../../core/utils/logger.dart';

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
  final TextEditingController _searchController = TextEditingController();
  final AppLogger _logger = AppLogger();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _logger.info('🏪 [RESTAURANT-DETAILS] Initializing screen for restaurant: ${widget.restaurantId}');
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vendorAsync = ref.watch(vendorDetailsProvider(widget.restaurantId));
    final cartState = ref.watch(customerCartProvider);

    return Scaffold(
      body: vendorAsync.when(
        data: (vendor) {
          if (vendor == null) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Restaurant Not Found'),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              body: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.restaurant, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Restaurant not found'),
                    SizedBox(height: 8),
                    Text('The restaurant you\'re looking for doesn\'t exist.'),
                  ],
                ),
              ),
            );
          }

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(vendor, theme),
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    RestaurantInfoCard(
                      vendor: vendor,
                      onFavoritePressed: () => _toggleFavorite(vendor),
                      onSharePressed: () => _shareVendor(vendor),
                    ),
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
          );
        },
        loading: () => Scaffold(
          appBar: AppBar(
            title: const Text('Loading...'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          body: const Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          appBar: AppBar(
            title: const Text('Error'),
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
          ),
          body: CustomErrorWidget(
            message: 'Failed to load restaurant details: $error',
            onRetry: () => ref.refresh(vendorDetailsProvider(widget.restaurantId)),
          ),
        ),
      ),
      bottomNavigationBar: cartState.items.isNotEmpty ? _buildCartBottomBar(cartState, theme) : null,
    );
  }

  Widget _buildSliverAppBar(Vendor vendor, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: theme.colorScheme.surface,
      foregroundColor: theme.colorScheme.onSurface,
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.favorite_border),
          onPressed: () => _toggleFavorite(vendor),
          tooltip: 'Add to favorites',
        ),
        IconButton(
          icon: const Icon(Icons.share),
          onPressed: () => _shareVendor(vendor),
          tooltip: 'Share restaurant',
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            vendor.businessName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
              fontSize: 16,
            ),
          ),
        ),
        titlePadding: const EdgeInsets.only(bottom: 16),
        centerTitle: true,
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
            // Gradient overlay for better text readability
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[300],
      child: const Center(
        child: Icon(
          Icons.restaurant,
          size: 64,
          color: Colors.grey,
        ),
      ),
    );
  }



  Widget _buildTabBar(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(25),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.onPrimary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicator: BoxDecoration(
          color: theme.colorScheme.primary,
          borderRadius: BorderRadius.circular(25),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
        tabs: const [
          Tab(
            height: 48,
            child: Text('Menu'),
          ),
          Tab(
            height: 48,
            child: Text('Info'),
          ),
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

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: MenuSearchBar(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                padding: const EdgeInsets.all(16),
              ),
            ),
            SliverToBoxAdapter(
              child: CategoryFilterTabs(
                categories: ['All', ...products.map((p) => p.category).toSet().toList()..sort()],
                selectedCategory: _selectedCategory,
                onCategorySelected: (category) => setState(() => _selectedCategory = category),
                categoryCounts: _buildCategoryCounts(products),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 16),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final filteredProducts = _filterProducts(products);
                    final product = filteredProducts[index];
                    return MenuItemCard(
                      product: product,
                      onTap: () => _showMenuItemDetails(product),
                      onAddToCart: () => _addToCart(product),
                    );
                  },
                  childCount: _filterProducts(products).length,
                ),
              ),
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





  Map<String, int> _buildCategoryCounts(List<Product> products) {
    final counts = <String, int>{};
    counts['All'] = products.length;

    for (final product in products) {
      counts[product.category] = (counts[product.category] ?? 0) + 1;
    }

    return counts;
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



  // TODO: This method is currently unused but preserved for future card-style menu layout
  // ignore: unused_element
  Widget _buildMenuItemCard(Product product) {
    final theme = Theme.of(context);
    final isAvailable = product.isAvailable ?? true;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: isAvailable ? () => _showMenuItemDetails(product) : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isAvailable ? null : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product image with availability overlay
                Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: theme.colorScheme.surfaceContainerHighest,
                      ),
                      child: product.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.fastfood,
                                  size: 32,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.fastfood,
                              size: 32,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                    ),
                    if (!isAvailable)
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.black.withValues(alpha: 0.6),
                        ),
                        child: Center(
                          child: Text(
                            'Unavailable',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              
                const SizedBox(width: 16),

                // Product details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Product name with availability styling
                      Text(
                        product.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isAvailable
                              ? theme.colorScheme.onSurface
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),

                      if (product.description?.isNotEmpty == true) ...[
                        const SizedBox(height: 6),
                        Text(
                          product.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isAvailable
                                ? theme.colorScheme.onSurfaceVariant
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                            height: 1.4,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],

                      const SizedBox(height: 12),

                      // Enhanced tags and features
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (product.isHalal == true)
                            _buildFeatureChip(
                              theme,
                              'Halal',
                              Colors.green,
                              Icons.verified,
                            ),
                          if (product.isVegetarian == true)
                            _buildFeatureChip(
                              theme,
                              'Vegetarian',
                              Colors.orange,
                              Icons.eco,
                            ),
                          if (product.isSpicy == true)
                            _buildFeatureChip(
                              theme,
                              'Spicy',
                              Colors.red,
                              Icons.local_fire_department,
                            ),
                          if (!isAvailable)
                            _buildFeatureChip(
                              theme,
                              'Unavailable',
                              Colors.grey,
                              Icons.block,
                            ),
                        ],
                    ),
                    
                      const SizedBox(height: 16),

                      // Price and add button with enhanced styling
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RM ${product.basePrice.toStringAsFixed(2)}',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isAvailable
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              if (product.minOrderQuantity != null && product.minOrderQuantity! > 1)
                                Text(
                                  'Min: ${product.minOrderQuantity} pcs',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          if (isAvailable)
                            FilledButton.icon(
                              onPressed: () => _addToCart(product),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Add'),
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          else
                            OutlinedButton(
                              onPressed: null,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Unavailable'),
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
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.1),
            spreadRadius: 0,
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
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
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${cartState.totalItems} item${cartState.totalItems > 1 ? 's' : ''} in cart',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      'RM ${cartState.totalAmount.toStringAsFixed(2)}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton(
                onPressed: () => context.push('/customer/cart'),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'View Cart',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMenuItemDetails(Product product) {
    context.push('/customer/menu-item/${product.id}');
  }

  // TODO: This method is currently unused but preserved for future quantity selector dialog
  // ignore: unused_element
  void _showQuantitySelector(Product product, Vendor vendor) {
    int selectedQuantity = 1;
    final minQuantity = product.minOrderQuantity ?? 1;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Text(
                'Add to Cart',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product info
                  Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        child: product.imageUrl != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.network(
                                  product.imageUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Icon(
                                    Icons.fastfood,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.fastfood,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              'RM ${product.basePrice.toStringAsFixed(2)}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Quantity selector
                  Text(
                    'Quantity',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      IconButton(
                        onPressed: selectedQuantity > minQuantity
                            ? () => setState(() => selectedQuantity--)
                            : null,
                        icon: const Icon(Icons.remove),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        selectedQuantity.toString(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => setState(() => selectedQuantity++),
                        icon: const Icon(Icons.add),
                        style: IconButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (minQuantity > 1) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Minimum order: $minQuantity',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // Total price
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                        Text(
                          'RM ${(product.basePrice * selectedQuantity).toStringAsFixed(2)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _addItemToCart(product, vendor, quantity: selectedQuantity);
                  },
                  child: const Text('Add to Cart'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _addToCart(Product product) {
    final vendorAsync = ref.read(vendorDetailsProvider(widget.restaurantId));

    vendorAsync.when(
      data: (vendor) {
        if (vendor == null) {
          _showErrorSnackBar('Unable to add item: Restaurant information not available');
          return;
        }

        if (product.customizations.isNotEmpty) {
          // Show customization dialog for items with customizations
          _showMenuItemDetails(product);
        } else {
          // Show quantity selector for simple items
          QuantitySelectorDialog.show(
            context: context,
            product: product,
            onAddToCart: (quantity) => _addItemToCart(product, vendor, quantity: quantity),
          );
        }
      },
      loading: () => _showErrorSnackBar('Please wait for restaurant information to load'),
      error: (error, stack) => _showErrorSnackBar('Unable to add item: $error'),
    );
  }

  void _addItemToCart(Product product, Vendor vendor, {
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
  }) {
    try {
      _logger.info('🛒 [RESTAURANT-DETAILS] Adding ${product.name} to cart from ${vendor.businessName}');

      // Check if cart has items from different vendor
      final currentCart = ref.read(customerCartProvider);
      if (currentCart.items.isNotEmpty) {
        final existingVendorId = currentCart.items.first.vendorId;
        if (existingVendorId != vendor.id) {
          _showVendorConflictDialog(product, vendor, quantity, customizations, notes);
          return;
        }
      }

      ref.read(customerCartProvider.notifier).addItem(
        product: product,
        vendor: vendor,
        quantity: quantity,
        customizations: customizations,
        notes: notes,
      );

      // Show success message with cart action
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '${product.name} added to cart',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[600],
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'View Cart',
            textColor: Colors.white,
            onPressed: () => context.push('/customer/cart'),
          ),
        ),
      );

      _logger.info('✅ [RESTAURANT-DETAILS] Successfully added ${product.name} to cart');
    } catch (e) {
      _logger.error('❌ [RESTAURANT-DETAILS] Error adding item to cart', e);
      _showErrorSnackBar('Failed to add ${product.name} to cart: ${e.toString()}');
    }
  }

  void _showVendorConflictDialog(Product product, Vendor vendor, int quantity, Map<String, dynamic>? customizations, String? notes) {
    final currentCart = ref.read(customerCartProvider);
    final existingVendorName = currentCart.items.first.vendorName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        final theme = Theme.of(context);

        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: theme.colorScheme.error,
                size: 28,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Different Restaurant',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Your cart contains items from $existingVendorName. You can only order from one restaurant at a time.',
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                'What would you like to do?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/customer/cart');
              },
              child: const Text('View Cart'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Clear cart and add new item
                ref.read(customerCartProvider.notifier).clearCart();
                ref.read(customerCartProvider.notifier).addItem(
                  product: product,
                  vendor: vendor,
                  quantity: quantity,
                  customizations: customizations,
                  notes: notes,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Cart cleared and ${product.name} added'),
                    backgroundColor: Colors.green[600],
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
              ),
              child: const Text('Clear Cart & Add'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red[600],
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildFeatureChip(ThemeData theme, String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // TODO: This method is currently unused but preserved for future info card layout
  // ignore: unused_element
  Widget _buildInfoCard(ThemeData theme, IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleFavorite(Vendor vendor) {
    // TODO: Implement proper favorite functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added ${vendor.businessName} to favorites'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            // TODO: Implement undo functionality
          },
        ),
      ),
    );
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
