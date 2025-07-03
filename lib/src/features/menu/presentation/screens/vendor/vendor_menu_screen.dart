import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/product.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import '../../../../vendors/presentation/screens/product_form_screen.dart';


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
      });

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load menu items: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
          : Column(
              children: [
                // Search and Filter Bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: theme.colorScheme.surface,
                  child: Column(
                    children: [
                      // Search Bar
                      TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Search menu items...',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {
                                      _searchQuery = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                )
                              : null,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                      ),

                      const SizedBox(height: 12),

                      // Category Filter
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            FilterChip(
                              label: const Text('All'),
                              selected: _selectedCategory == null,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = null;
                                });
                              },
                            ),
                            const SizedBox(width: 8),
                            ..._categories.map((category) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(category),
                                selected: _selectedCategory == category,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedCategory = selected ? category : null;
                                  });
                                },
                              ),
                            )),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Products List
                Expanded(
                  child: _buildProductsList(),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'vendor_menu_add_item_fab',
        onPressed: () => _navigateToAddProduct(),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
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
      child: InkWell(
        onTap: () => _navigateToEditProduct(product.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrl ?? '',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.image, color: Colors.grey),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),

              const SizedBox(width: 16),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: product.availability.isAvailable
                                ? Colors.green.withValues(alpha: 0.1)
                                : Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.availability.isAvailable ? 'Available' : 'Unavailable',
                            style: TextStyle(
                              color: product.availability.isAvailable ? Colors.green : Colors.red,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),

                    Text(
                      product.safeDescription,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            product.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (product.safeIsVegetarian)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Veg',
                              style: TextStyle(
                                color: Colors.green,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        if (product.safeIsHalal) ...[
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Halal',
                              style: TextStyle(
                                color: Colors.blue,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'RM ${product.pricing.effectivePrice.toStringAsFixed(2)}',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          onSelected: (value) => _handleProductAction(value, product),
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'edit',
                              child: Row(
                                children: [
                                  Icon(Icons.edit),
                                  SizedBox(width: 8),
                                  Text('Edit'),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 'toggle_availability',
                              child: Row(
                                children: [
                                  Icon(product.availability.isAvailable ? Icons.visibility_off : Icons.visibility),
                                  const SizedBox(width: 8),
                                  Text(product.availability.isAvailable ? 'Make Unavailable' : 'Make Available'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'duplicate',
                              child: Row(
                                children: [
                                  Icon(Icons.copy),
                                  SizedBox(width: 8),
                                  Text('Duplicate'),
                                ],
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 80,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'No items found'
                  : 'No menu items yet',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty || _selectedCategory != null
                  ? 'Try adjusting your search or filters'
                  : 'Start by adding your first menu item',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            if (_searchQuery.isEmpty && _selectedCategory == null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _navigateToAddProduct(),
                icon: const Icon(Icons.add),
                label: const Text('Add Menu Item'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showBulkActions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.file_upload),
              title: const Text('Import Menu'),
              subtitle: const Text('Import items from CSV file'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Import menu functionality');
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download),
              title: const Text('Export Menu'),
              subtitle: const Text('Export current menu to CSV'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Export menu functionality');
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off),
              title: const Text('Bulk Hide Items'),
              subtitle: const Text('Hide multiple items at once'),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Bulk actions');
              },
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
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductFormScreen(productId: productId),
      ),
    ).then((result) {
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
}
