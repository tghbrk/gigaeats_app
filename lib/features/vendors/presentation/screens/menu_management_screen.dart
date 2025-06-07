import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../menu/data/models/menu_item.dart';
import '../../../menu/data/models/product.dart';
import '../../../menu/data/services/menu_service.dart';
import '../../providers/repository_providers.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../widgets/custom_error_widget.dart';
// import 'menu_item_form_screen.dart'; // Disabled for now

// Provider for menu service (keeping for categories)
final menuServiceProvider = Provider<MenuService>((ref) => MenuService());

// Provider for vendor menu items using real Supabase repository
final vendorMenuItemsProvider = FutureProvider.family<List<Product>, String>((ref, vendorId) async {
  debugPrint('🍽️ [MENU-DEBUG] Loading menu items for vendor: $vendorId');
  final menuItemRepository = ref.read(menuItemRepositoryProvider);
  try {
    final items = await menuItemRepository.getMenuItems(vendorId);
    debugPrint('🍽️ [MENU-DEBUG] Successfully loaded ${items.length} menu items');
    return items;
  } catch (e) {
    debugPrint('🍽️ [MENU-DEBUG] Error loading menu items: $e');
    rethrow;
  }
});

// Provider for vendor menu categories
final vendorMenuCategoriesProvider = FutureProvider.family<List<MenuCategory>, String>((ref, vendorId) async {
  final menuService = ref.read(menuServiceProvider);
  return await menuService.getVendorCategories(vendorId);
});

// Provider for menu statistics
final vendorMenuStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, vendorId) async {
  final menuService = ref.read(menuServiceProvider);
  return await menuService.getVendorMenuStats(vendorId);
});

class MenuManagementScreen extends ConsumerStatefulWidget {
  final String vendorId;

  const MenuManagementScreen({
    super.key,
    required this.vendorId,
  });

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _selectedCategory;

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

    final menuStatsAsync = ref.watch(vendorMenuStatsProvider(widget.vendorId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Menu Items', icon: Icon(Icons.restaurant_menu)),
            Tab(text: 'Categories', icon: Icon(Icons.category)),
            Tab(text: 'Analytics', icon: Icon(Icons.analytics)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddMenuDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Summary Card
          menuStatsAsync.when(
            data: (stats) => _buildStatsCard(stats),
            loading: () => const SizedBox.shrink(),
            error: (error, stack) => const SizedBox.shrink(),
          ),
          
          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMenuItemsTab(),
                _buildCategoriesTab(),
                _buildAnalyticsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard(Map<String, dynamic> stats) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(
              'Total Items',
              '${stats['totalItems']}',
              Icons.restaurant_menu,
              Colors.blue,
            ),
            _buildStatItem(
              'Categories',
              '${stats['totalCategories']}',
              Icons.category,
              Colors.green,
            ),
            _buildStatItem(
              'Available',
              '${stats['availableItems']}',
              Icons.check_circle,
              Colors.orange,
            ),
            _buildStatItem(
              'Halal Items',
              '${stats['halalItems']}',
              Icons.verified,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMenuItemsTab() {
    final menuItemsAsync = ref.watch(vendorMenuItemsProvider(widget.vendorId));
    final categoriesAsync = ref.watch(vendorMenuCategoriesProvider(widget.vendorId));

    return Column(
      children: [
        // Category Filter
        categoriesAsync.when(
          data: (categories) => _buildCategoryFilter(categories),
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
        ),
        
        // Menu Items List
        Expanded(
          child: menuItemsAsync.when(
            data: (items) {
              final filteredItems = _selectedCategory != null
                  ? items.where((item) => item.category == _selectedCategory).toList()
                  : items;

              if (filteredItems.isEmpty) {
                return _buildEmptyState();
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredItems.length,
                itemBuilder: (context, index) {
                  final item = filteredItems[index];
                  return _buildMenuItemCard(item);
                },
              );
            },
            loading: () => const LoadingWidget(message: 'Loading menu items...'),
            error: (error, stack) => CustomErrorWidget(
              message: 'Failed to load menu items: $error',
              onRetry: () => ref.refresh(vendorMenuItemsProvider(widget.vendorId)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilter(List<MenuCategory> categories) {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        scrollDirection: Axis.horizontal,
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
          ...categories.map((category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(category.name),
                  selected: _selectedCategory == category.id,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategory = selected ? category.id : null;
                    });
                  },
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(Product item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.fastfood, size: 60),
                ),
              )
            : const Icon(Icons.fastfood, size: 60),
        title: Row(
          children: [
            Expanded(child: Text(item.name)),
            if (item.isHalal == true)
              const Icon(Icons.verified, color: Colors.green, size: 16),
            const SizedBox(width: 4),
            _buildAvailabilityChip(item.isAvailable ?? false),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.description ?? 'No description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  'RM ${item.basePrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if ((item.rating ?? 0) > 0) ...[
                  Icon(Icons.star, size: 16, color: Colors.amber),
                  Text(' ${(item.rating ?? 0).toStringAsFixed(1)}'),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuAction(value, item),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
            const PopupMenuItem(value: 'availability', child: Text('Update Availability')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityChip(bool isAvailable) {
    return Chip(
      label: Text(
        isAvailable ? 'Available' : 'Unavailable',
        style: const TextStyle(fontSize: 10),
      ),
      backgroundColor: isAvailable
          ? Colors.green.withValues(alpha: 0.1)
          : Colors.red.withValues(alpha: 0.1),
      side: BorderSide(color: isAvailable ? Colors.green : Colors.red),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  Widget _buildCategoriesTab() {
    final categoriesAsync = ref.watch(vendorMenuCategoriesProvider(widget.vendorId));

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return _buildEmptyState(message: 'No categories found');
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: category.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          category.imageUrl!,
                          width: 50,
                          height: 50,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.category),
                        ),
                      )
                    : const Icon(Icons.category),
                title: Text(category.name),
                subtitle: category.description != null
                    ? Text(category.description!)
                    : null,
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Order: ${category.sortOrder}'),
                    PopupMenuButton<String>(
                      onSelected: (value) => _handleCategoryAction(value, category),
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const LoadingWidget(message: 'Loading categories...'),
      error: (error, stack) => CustomErrorWidget(
        message: 'Failed to load categories: $error',
        onRetry: () => ref.refresh(vendorMenuCategoriesProvider(widget.vendorId)),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    return const Center(
      child: Text('Analytics coming soon...'),
    );
  }

  Widget _buildEmptyState({String? message}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.restaurant_menu,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message ?? 'No menu items found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first menu item to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Add Menu Item',
            onPressed: () => _showAddMenuDialog(),
          ),
        ],
      ),
    );
  }

  void _showAddMenuDialog() {
    // Show a placeholder dialog since MenuItemFormScreen is disabled
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Menu Item'),
        content: const Text('Menu item creation functionality is currently under development. Please check back later.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );

    // TODO: Uncomment when MenuItemFormScreen is ready
    // Navigator.of(context).push(
    //   MaterialPageRoute(
    //     builder: (context) => const MenuItemFormScreen(),
    //   ),
    // ).then((_) {
    //   // Refresh the menu items after adding/editing
    //   ref.invalidate(vendorMenuItemsProvider(widget.vendorId));
    //   ref.invalidate(vendorMenuStatsProvider(widget.vendorId));
    // });
  }

  void _handleMenuAction(String action, Product item) {
    switch (action) {
      case 'edit':
        // Show placeholder dialog since MenuItemFormScreen is disabled
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Edit Menu Item'),
            content: Text('Edit functionality for "${item.name}" is currently under development. Please check back later.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        // TODO: Uncomment when MenuItemFormScreen is ready
        // Navigator.of(context).push(
        //   MaterialPageRoute(
        //     builder: (context) => MenuItemFormScreen(menuItemId: item.id),
        //   ),
        // ).then((_) {
        //   // Refresh the menu items after editing
        //   ref.invalidate(vendorMenuItemsProvider(widget.vendorId));
        //   ref.invalidate(vendorMenuStatsProvider(widget.vendorId));
        // });
        break;
      case 'duplicate':
        _duplicateMenuItem(item);
        break;
      case 'availability':
        _showAvailabilityDialog(item);
        break;
      case 'delete':
        _showDeleteConfirmation(item);
        break;
    }
  }

  void _handleCategoryAction(String action, MenuCategory category) {
    switch (action) {
      case 'edit':
        // Edit category
        break;
      case 'delete':
        // Delete category
        break;
    }
  }

  void _showAvailabilityDialog(Product item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update ${item.name} Availability'),
        content: const Text('Availability update form will be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Product item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Delete item
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _duplicateMenuItem(Product item) async {
    try {
      final menuItemRepository = ref.read(menuItemRepositoryProvider);
      final duplicatedItem = Product(
        id: '', // Will be generated by the database
        vendorId: item.vendorId,
        name: '${item.name} (Copy)',
        description: item.description,
        category: item.category,
        basePrice: item.basePrice,
        imageUrl: item.imageUrl,
        isAvailable: item.isAvailable,
        isVegetarian: item.isVegetarian,
        isHalal: item.isHalal,
        tags: item.tags,
        rating: 0.0, // Reset rating for duplicated item
        totalReviews: 0, // Reset reviews for duplicated item
        createdAt: DateTime.now(),
      );

      await menuItemRepository.createMenuItem(duplicatedItem);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu item duplicated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.invalidate(vendorMenuItemsProvider(widget.vendorId));
        ref.invalidate(vendorMenuStatsProvider(widget.vendorId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to duplicate item: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
