import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:cached_network_image/cached_network_image.dart';

import '../../../data/models/product.dart';

import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../../../../presentation/providers/repository_providers.dart';
import '../../../../../shared/widgets/loading_widget.dart';
import 'menu_item_form_screen.dart';
import 'menu_management_screen.dart';
import 'template_management_screen.dart';
import 'bulk_template_application_screen.dart';
import '../../widgets/vendor/menu_export_dialog.dart';
import '../../widgets/vendor/menu_import_dialog.dart';
import '../../providers/menu_import_export_providers.dart';
import '../../../data/models/menu_export_import.dart';


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
            onPressed: () => _navigateToAddProduct(),
            icon: const Icon(Icons.add),
            tooltip: 'Add Item',
          ),
          IconButton(
            onPressed: () => _loadProducts(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh menu',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'import_menu':
                  _showImportMenuDialog();
                  break;
                case 'export_menu':
                  _showExportMenuDialog();
                  break;
                case 'manage_categories':
                  _navigateToCategoryManagement();
                  break;
                case 'bulk_availability':
                  _showComingSoon('Bulk availability toggle');
                  break;
                case 'template_management':
                  _navigateToTemplateManagement();
                  break;
                case 'bulk_templates':
                  _navigateToBulkTemplateApplication();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'import_menu',
                child: ListTile(
                  leading: Icon(Icons.upload_file_rounded, color: Colors.blue),
                  title: Text('Import Menu'),
                  subtitle: Text('Upload menu items from CSV or Excel'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'export_menu',
                child: ListTile(
                  leading: Icon(Icons.download_rounded, color: Colors.green),
                  title: Text('Export Menu'),
                  subtitle: Text('Download your menu as CSV or PDF'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'manage_categories',
                child: ListTile(
                  leading: Icon(Icons.category_rounded, color: Colors.purple),
                  title: Text('Manage Categories'),
                  subtitle: Text('Add, edit, or organize menu categories'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_availability',
                child: ListTile(
                  leading: Icon(Icons.visibility_off_rounded, color: Colors.orange),
                  title: Text('Bulk Availability'),
                  subtitle: Text('Toggle availability for multiple items'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'template_management',
                child: ListTile(
                  leading: Icon(Icons.layers_rounded, color: Colors.indigo),
                  title: Text('Template Management'),
                  subtitle: Text('Create and manage customization templates'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'bulk_templates',
                child: ListTile(
                  leading: Icon(Icons.auto_awesome_rounded, color: Colors.teal),
                  title: Text('Bulk Templates'),
                  subtitle: Text('Apply templates to multiple menu items'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
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
                    onPressed: () => _showImportMenuDialog(),
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

  Future<void> _navigateToCategoryManagement() async {
    // Get current vendor ID
    final authState = ref.read(authStateProvider);
    if (authState.user == null) return;

    try {
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(authState.user!.id);

      if (vendor != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MenuManagementScreen(
              vendorId: vendor.id,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('🏷️ [VENDOR-MENU] Error navigating to category management: $e');
      _showComingSoon('Category management');
    }
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
    print('🍽️ [VENDOR-MENU-DEBUG] Navigating to add menu item screen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MenuItemFormScreen(
          menuItemId: null, // null for create mode
          preSelectedCategoryId: null, // no pre-selected category
          preSelectedCategoryName: null,
        ),
      ),
    ).then((result) {
      // Refresh the products after adding
      if (result == true) {
        print('🍽️ [VENDOR-MENU-DEBUG] Returned from add menu item screen, refreshing...');
        _loadProducts();
      }
    });
  }

  void _navigateToEditProduct(String productId) {
    print('🍽️ [VENDOR-MENU-DEBUG] Navigating to edit product screen');
    print('🍽️ [VENDOR-MENU-DEBUG] Product ID: $productId');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuItemFormScreen(menuItemId: productId),
      ),
    ).then((result) {
      print('🍽️ [VENDOR-MENU-DEBUG] Returned from edit screen with result: $result');
      // Refresh the products after editing
      if (result == true) {
        _loadProducts();
      }
    });
  }

  Future<void> _showExportMenuDialog() async {
    debugPrint('🍽️ [VENDOR-MENU] Opening export menu dialog');

    // Get current vendor ID
    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      _showComingSoon('Menu export (user not authenticated)');
      return;
    }

    try {
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(authState.user!.id);

      if (vendor == null) {
        _showComingSoon('Menu export (vendor not found)');
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => MenuExportDialog(
            vendorId: vendor.id,
            vendorName: vendor.businessName,
            onExportComplete: (result) {
              debugPrint('🍽️ [VENDOR-MENU] Export completed: ${result.fileName}');

              if (mounted) {
                // Automatically share the file after successful export
                if (result.isSuccessful) {
                  _autoShareExportedFile(result);
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.isSuccessful
                        ? 'Menu exported successfully! ${result.totalItems} items exported.'
                        : 'Export failed: ${result.errorMessage}',
                    ),
                    backgroundColor: result.isSuccessful ? Colors.green : Colors.red,
                    action: result.isSuccessful ? SnackBarAction(
                      label: 'Share Again',
                      onPressed: () async {
                        try {
                          final exportService = ref.read(menuExportServiceProvider);
                          await exportService.shareExportedFile(result);
                        } catch (e) {
                          debugPrint('❌ [VENDOR-MENU] Failed to share file: $e');
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to share file: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                    ) : null,
                  ),
                );
              }
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('🍽️ [VENDOR-MENU] Error opening export dialog: $e');
      _showComingSoon('Menu export (error occurred)');
    }
  }

  Future<void> _autoShareExportedFile(MenuExportResult result) async {
    try {
      debugPrint('🍽️ [VENDOR-MENU] Auto-sharing exported file: ${result.fileName}');

      final exportService = ref.read(menuExportServiceProvider);
      await exportService.shareExportedFile(result);

      debugPrint('🍽️ [VENDOR-MENU] Auto-share completed successfully');
    } catch (e) {
      debugPrint('⚠️ [VENDOR-MENU] Auto-share failed: $e');
      // Don't show error to user for auto-share failure, they can still use "Share Again" button
    }
  }

  Future<void> _showImportMenuDialog() async {
    debugPrint('🍽️ [VENDOR-MENU] Opening import menu dialog');

    // Get current vendor ID
    final authState = ref.read(authStateProvider);
    if (authState.user == null) {
      _showComingSoon('Menu import (user not authenticated)');
      return;
    }

    try {
      final vendorRepository = ref.read(vendorRepositoryProvider);
      final vendor = await vendorRepository.getVendorByUserId(authState.user!.id);

      if (vendor == null) {
        _showComingSoon('Menu import (vendor not found)');
        return;
      }

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => MenuImportDialog(
            vendorId: vendor.id,
            onImportComplete: (result) {
              debugPrint('🍽️ [VENDOR-MENU] Import completed: ${result.fileName}');

              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      result.isSuccessful
                        ? 'Menu imported successfully! ${result.importedRows} items imported.'
                        : 'Import failed: ${result.errorMessage}',
                    ),
                    backgroundColor: result.isSuccessful ? Colors.green : Colors.red,
                  ),
                );

                // Refresh menu data after successful import
                if (result.isSuccessful) {
                  _loadProducts();
                }
              }
            },
          ),
        );
      }
    } catch (e) {
      debugPrint('🍽️ [VENDOR-MENU] Error opening import dialog: $e');
      _showComingSoon('Menu import (error occurred)');
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.orange,
      ),
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
