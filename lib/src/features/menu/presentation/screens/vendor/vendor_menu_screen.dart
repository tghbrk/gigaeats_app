import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/product.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import 'product_form_screen.dart';
import 'template_management_screen.dart';
import 'bulk_template_application_screen.dart';


class VendorMenuScreen extends ConsumerStatefulWidget {
  const VendorMenuScreen({super.key});

  @override
  ConsumerState<VendorMenuScreen> createState() => _VendorMenuScreenState();
}

class _VendorMenuScreenState extends ConsumerState<VendorMenuScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  bool _isLoading = false;
  String? _errorMessage;
  List<Product> _products = [];
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    print('🍽️ [VENDOR-MENU-DEBUG] Loading products...');
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authState = ref.read(authStateProvider);
      final userId = authState.user?.id;
      print('🍽️ [VENDOR-MENU-DEBUG] Current user ID: $userId');

      if (userId == null) {
        print('🍽️ [VENDOR-MENU-DEBUG] No user ID found, using mock data');
        // Fallback to mock data if no user
        final products = <Product>[]; // Temporarily simplified for quick launch
        final categories = products.map((p) => p.category).toSet().toList();
        categories.sort();

        setState(() {
          _products = products;
          _categories = categories;
          _isLoading = false;
        });
        return;
      }

      // Get vendor ID from user ID
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(userId);

      if (vendor == null) {
        print('🍽️ [VENDOR-MENU-DEBUG] No vendor found for user, using mock data');
        // Fallback to mock data if no vendor found
        final products = <Product>[]; // Temporarily simplified for quick launch
        final categories = products.map((p) => p.category).toSet().toList();
        categories.sort();

        setState(() {
          _products = products;
          _categories = categories;
          _isLoading = false;
        });
        return;
      }

      print('🍽️ [VENDOR-MENU-DEBUG] Vendor found: ${vendor.id}');

      // Get products for this vendor from Supabase
      final menuItemRepository = ref.read(menuItemRepositoryProvider);
      final products = await menuItemRepository.getMenuItems(vendor.id);
      print('🍽️ [VENDOR-MENU-DEBUG] Loaded ${products.length} products from Supabase');

      final categories = products.map((p) => p.category).toSet().toList();
      categories.sort();

      setState(() {
        _products = products;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('🍽️ [VENDOR-MENU-DEBUG] Error loading products: $e');
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load menu items. Please try again.';
      });
    }
  }

  List<Product> get _filteredProducts {
    var filtered = _products;

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
            product.safeDescription.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    if (_selectedCategory != null) {
      filtered = filtered.where((product) => product.category == _selectedCategory).toList();
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _loadProducts(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh menu',
          ),
          IconButton(
            onPressed: () => _showBulkActions(),
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingWidget(message: 'Loading menu items...')
          : _errorMessage != null
              ? _buildErrorState()
              : Column(
              children: [
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.shadow.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Search Bar
                      SearchBar(
                        controller: _searchController,
                        hintText: 'Search menu items...',
                        leading: Icon(
                          Icons.search_rounded,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        trailing: _searchQuery.isNotEmpty
                            ? [
                                IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: Icon(
                                    Icons.clear_rounded,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  tooltip: 'Clear search',
                                ),
                              ]
                            : null,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        backgroundColor: WidgetStateProperty.all(
                          theme.colorScheme.surfaceContainerHigh,
                        ),
                        elevation: WidgetStateProperty.all(0),
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Filter Section Header
                      Row(
                        children: [
                          Icon(
                            Icons.filter_list_rounded,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Filter by Category',
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (_selectedCategory != null)
                            TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                              icon: Icon(
                                Icons.clear_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              label: Text(
                                'Clear',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Category Filter Chips
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // All Categories Chip
                            FilterChip(
                              label: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.apps_rounded,
                                    size: 16,
                                    color: _selectedCategory == null
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'All Items',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: _selectedCategory == null
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                              selected: _selectedCategory == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                              backgroundColor: theme.colorScheme.surfaceContainerHigh,
                              selectedColor: theme.colorScheme.primary,
                              checkmarkColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Category Chips
                            ..._categories.map((category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getCategoryIcon(category),
                                      size: 16,
                                      color: _selectedCategory == category
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      category,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: _selectedCategory == category
                                            ? theme.colorScheme.onPrimary
                                            : theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                                selected: _selectedCategory == category,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? category : null;
                                  });
                                },
                                backgroundColor: theme.colorScheme.surfaceContainerHigh,
                                selectedColor: theme.colorScheme.primary,
                                checkmarkColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            )),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Products List
                Expanded(
                  child: _buildProductsList(),
                ),
              ],
            ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildProductsList() {
    final filteredProducts = _filteredProducts;

    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredProducts.length,
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _navigateToEditProduct(product.id),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: product.imageUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 80,
                          height: 80,
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.fastfood,
                            color: theme.colorScheme.onSurfaceVariant,
                            size: 32,
                          ),
                        ),
                        errorWidget: (context, url, error) {
                          debugPrint('🖼️ [MENU-IMAGE-ERROR] Failed to load image for ${product.name}: $error');
                          debugPrint('🖼️ [MENU-IMAGE-ERROR] Failed URL: $url');
                          return Container(
                            width: 80,
                            height: 80,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.broken_image,
                              color: theme.colorScheme.onSurfaceVariant,
                              size: 32,
                            ),
                          );
                        },
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fastfood,
                          color: theme.colorScheme.onSurfaceVariant,
                          size: 32,
                        ),
                      ),
              ),

              const SizedBox(width: 16),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name and Availability
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: product.availability.isAvailable
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                product.availability.isAvailable
                                    ? Icons.check_circle_rounded
                                    : Icons.cancel_rounded,
                                size: 14,
                                color: product.availability.isAvailable
                                    ? theme.colorScheme.onPrimaryContainer
                                    : theme.colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.availability.isAvailable ? 'Available' : 'Out of Stock',
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: product.availability.isAvailable
                                      ? theme.colorScheme.onPrimaryContainer
                                      : theme.colorScheme.onErrorContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Description
                    if (product.safeDescription.isNotEmpty) ...[
                      Text(
                        product.safeDescription,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Category and Tags
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        // Category chip
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.secondaryContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.category_rounded,
                                size: 12,
                                color: theme.colorScheme.onSecondaryContainer,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                product.category,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Vegetarian tag
                        if (product.safeIsVegetarian)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.eco_rounded,
                                  size: 12,
                                  color: Colors.green.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Vegetarian',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.green.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        // Halal tag
                        if (product.safeIsHalal)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.verified_rounded,
                                  size: 12,
                                  color: Colors.blue.shade700,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Halal',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Price and Actions Row
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RM ${product.pricing.effectivePrice.toStringAsFixed(2)}',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              if (product.bulkPrice != null && product.bulkMinQuantity != null)
                                Text(
                                  'Bulk: RM ${product.bulkPrice!.toStringAsFixed(2)} (${product.bulkMinQuantity}+ items)',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHigh,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: PopupMenuButton<String>(
                            onSelected: (value) => _handleProductAction(value, product),
                            icon: Icon(
                              Icons.more_vert_rounded,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.edit_rounded,
                                      color: theme.colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Edit Item',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'toggle_availability',
                                child: Row(
                                  children: [
                                    Icon(
                                      product.availability.isAvailable
                                          ? Icons.visibility_off_rounded
                                          : Icons.visibility_rounded,
                                      color: product.availability.isAvailable
                                          ? Colors.orange.shade600
                                          : Colors.green.shade600,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      product.availability.isAvailable
                                          ? 'Mark Unavailable'
                                          : 'Mark Available',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'duplicate',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.content_copy_rounded,
                                      color: theme.colorScheme.secondary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Duplicate Item',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_rounded,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      'Delete Item',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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

  Widget _buildErrorState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error Icon Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: theme.colorScheme.error,
              ),
            ),

            const SizedBox(height: 24),

            // Error Title
            Text(
              'Oops! Something went wrong',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Error Message
            Text(
              _errorMessage ?? 'An unexpected error occurred',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _loadProducts(),
                  icon: Icon(
                    Icons.refresh_rounded,
                    size: 18,
                  ),
                  label: Text('Try Again'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: () => _navigateToAddProduct(),
                  icon: Icon(
                    Icons.add_rounded,
                    size: 18,
                  ),
                  label: Text('Add Item'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final isFiltered = _searchQuery.isNotEmpty || _selectedCategory != null;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration Container
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                isFiltered ? Icons.search_off_rounded : Icons.restaurant_menu_rounded,
                size: 64,
                color: theme.colorScheme.primary,
              ),
            ),

            const SizedBox(height: 24),

            // Title
            Text(
              isFiltered ? 'No items found' : 'No menu items yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            // Subtitle
            Text(
              isFiltered
                  ? 'Try adjusting your search terms or category filters to find what you\'re looking for.'
                  : 'Start building your menu by adding your first delicious item. Your customers are waiting!',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Action Buttons
            if (isFiltered) ...[
              // Clear Filters Button
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        _searchQuery = '';
                        _selectedCategory = null;
                        _searchController.clear();
                      });
                    },
                    icon: Icon(
                      Icons.clear_all_rounded,
                      size: 18,
                    ),
                    label: Text('Clear Filters'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                  const SizedBox(width: 16),
                  FilledButton.icon(
                    onPressed: () => _navigateToAddProduct(),
                    icon: Icon(
                      Icons.add_rounded,
                      size: 18,
                    ),
                    label: Text('Add Item'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Add First Item Button
              FilledButton.icon(
                onPressed: () => _navigateToAddProduct(),
                icon: Icon(
                  Icons.add_rounded,
                  size: 20,
                ),
                label: Text('Add Your First Menu Item'),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Secondary Actions
              Wrap(
                spacing: 12,
                children: [
                  TextButton.icon(
                    onPressed: () => _showBulkActions(),
                    icon: Icon(
                      Icons.upload_file_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'Import Menu',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _showComingSoon('Menu templates'),
                    icon: Icon(
                      Icons.description_rounded,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                    label: Text(
                      'Use Template',
                      style: TextStyle(color: theme.colorScheme.primary),
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

  void _showBulkActions() {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.settings_rounded,
                    color: theme.colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menu Actions',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Manage your menu items in bulk',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Action Items - Wrapped in Flexible to prevent overflow
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildBulkActionTile(
                      icon: Icons.upload_file_rounded,
                      iconColor: Colors.blue,
                      title: 'Import Menu',
                      subtitle: 'Upload menu items from CSV or Excel',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Menu import');
                      },
                    ),

                    _buildBulkActionTile(
                      icon: Icons.download_rounded,
                      iconColor: Colors.green,
                      title: 'Export Menu',
                      subtitle: 'Download your menu as CSV or PDF',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Menu export');
                      },
                    ),

                    _buildBulkActionTile(
                      icon: Icons.category_rounded,
                      iconColor: Colors.purple,
                      title: 'Manage Categories',
                      subtitle: 'Add, edit, or organize menu categories',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Category management');
                      },
                    ),

                    _buildBulkActionTile(
                      icon: Icons.visibility_off_rounded,
                      iconColor: Colors.orange,
                      title: 'Bulk Availability',
                      subtitle: 'Toggle availability for multiple items',
                      onTap: () {
                        Navigator.pop(context);
                        _showComingSoon('Bulk availability toggle');
                      },
                    ),

                    _buildBulkActionTile(
                      icon: Icons.layers_rounded,
                      iconColor: Colors.indigo,
                      title: 'Template Management',
                      subtitle: 'Create and manage customization templates',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToTemplateManagement();
                      },
                    ),

                    _buildBulkActionTile(
                      icon: Icons.auto_awesome_rounded,
                      iconColor: Colors.teal,
                      title: 'Bulk Templates',
                      subtitle: 'Apply templates to multiple menu items',
                      onTap: () {
                        Navigator.pop(context);
                        _navigateToBulkTemplateApplication();
                      },
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBulkActionTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _handleProductAction(String action, Product product) {
    switch (action) {
      case 'edit':
        _navigateToEditProduct(product.id);
        break;
      case 'toggle_availability':
        _toggleProductAvailability(product);
        break;
      case 'duplicate':
        _duplicateProduct(product);
        break;
      case 'delete':
        _deleteProduct(product);
        break;
    }
  }

  void _toggleProductAvailability(Product product) {
    // TODO: Implement availability toggle
    _showComingSoon('Toggle availability functionality');
  }

  void _duplicateProduct(Product product) {
    // TODO: Implement product duplication
    _showComingSoon('Duplicate product functionality');
  }

  Future<void> _navigateToTemplateManagement() async {
    // Get current vendor ID
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    try {
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(authState.user!.id);

      if (vendor != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TemplateManagementScreen(vendorId: vendor.id),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔧 [VENDOR-MENU] Error navigating to template management: $e');
      _showComingSoon('Template management');
    }
  }

  Future<void> _navigateToBulkTemplateApplication() async {
    // Get current vendor ID
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    try {
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(authState.user!.id);

      if (vendor != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => BulkTemplateApplicationScreen(vendorId: vendor.id),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔧 [VENDOR-MENU] Error navigating to bulk template application: $e');
      _showComingSoon('Bulk template application');
    }
  }

  void _deleteProduct(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${product.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showComingSoon('Delete product functionality');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _navigateToAddProduct() {
    print('🍽️ [VENDOR-MENU-DEBUG] Navigating to add product screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const ProductFormScreen(),
      ),
    ).then((result) {
      // Refresh the products after adding
      if (result == true) {
        print('🍽️ [VENDOR-MENU-DEBUG] Returned from add product screen, refreshing...');
        _loadProducts();
      }
    });
  }

  void _navigateToEditProduct(String productId) {
    print('🍽️ [VENDOR-MENU-DEBUG] Navigating to edit product screen');
    print('🍽️ [VENDOR-MENU-DEBUG] Product ID: $productId');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(productId: productId),
      ),
    ).then((result) {
      print('🍽️ [VENDOR-MENU-DEBUG] Returned from edit screen with result: $result');
      // Refresh the products after editing
      if (result == true) {
        _loadProducts();
      }
    });
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildEnhancedFAB() {
    final theme = Theme.of(context);
    final hasItems = _products.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Secondary FAB for bulk actions (only show if there are items)
        if (hasItems) ...[
          FloatingActionButton(
            heroTag: 'vendor_menu_bulk_actions_fab',
            onPressed: () => _showBulkActions(),
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
            elevation: 2,
            tooltip: 'More Actions',
            child: Icon(
              Icons.more_horiz_rounded,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Primary FAB for adding items
        FloatingActionButton.extended(
          heroTag: 'vendor_menu_add_item_fab',
          onPressed: () => _navigateToAddProduct(),
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          elevation: 6,
          icon: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.add_rounded,
              size: 20,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          label: Text(
            hasItems ? 'Add Item' : 'Add First Item',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onPrimary,
            ),
          ),
          extendedPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
      ],
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'appetizers':
      case 'appetizer':
        return Icons.restaurant_rounded;
      case 'beverages':
      case 'beverage':
      case 'drinks':
        return Icons.local_drink_rounded;
      case 'main course':
      case 'main':
      case 'mains':
        return Icons.dinner_dining_rounded;
      case 'desserts':
      case 'dessert':
        return Icons.cake_rounded;
      case 'breakfast':
        return Icons.breakfast_dining_rounded;
      case 'lunch':
        return Icons.lunch_dining_rounded;
      case 'dinner':
        return Icons.dinner_dining_rounded;
      case 'snacks':
      case 'snack':
        return Icons.fastfood_rounded;
      case 'salads':
      case 'salad':
        return Icons.eco_rounded;
      case 'soups':
      case 'soup':
        return Icons.soup_kitchen_rounded;
      default:
        return Icons.restaurant_menu_rounded;
    }
  }


}
