import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'menu_item_form_screen.dart';



class VendorMenuManagementScreen extends ConsumerStatefulWidget {
  const VendorMenuManagementScreen({super.key});

  @override
  ConsumerState<VendorMenuManagementScreen> createState() => _VendorMenuManagementScreenState();
}

class _VendorMenuManagementScreenState extends ConsumerState<VendorMenuManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;

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
            onPressed: _showAddMenuDialog,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildMenuItemsTab(),
          _buildCategoriesTab(),
          _buildAnalyticsTab(),
        ],
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard('Total Items', '24', Icons.restaurant_menu, Colors.blue),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Available', '20', Icons.check_circle, Colors.green),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildStatCard('Out of Stock', '4', Icons.cancel, Colors.red),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Sample Menu Items
        _buildMenuItemCard('Nasi Lemak Special', 'RM 12.50', 'Main Course', true),
        _buildMenuItemCard('Teh Tarik', 'RM 3.50', 'Beverages', true),
        _buildMenuItemCard('Roti Canai', 'RM 2.00', 'Breakfast', false),
        _buildMenuItemCard('Mee Goreng', 'RM 8.00', 'Main Course', true),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildCategoryCard('Main Course', '12 items', Icons.restaurant),
        _buildCategoryCard('Beverages', '8 items', Icons.local_drink),
        _buildCategoryCard('Breakfast', '6 items', Icons.breakfast_dining),
        _buildCategoryCard('Desserts', '4 items', Icons.cake),
      ],
    );
  }

  Widget _buildAnalyticsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Performance Cards
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Best Seller', 'Nasi Lemak', Icons.star, Colors.orange),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStatCard('Avg Rating', '4.5', Icons.thumb_up, Colors.green),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Popular Items This Week',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildPopularItemRow('Nasi Lemak Special', '45 orders'),
                _buildPopularItemRow('Teh Tarik', '38 orders'),
                _buildPopularItemRow('Mee Goreng', '32 orders'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Colors.grey[600],
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMenuItemCard(String name, String price, String category, bool isAvailable) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isAvailable ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
          child: Icon(
            Icons.restaurant_menu,
            color: isAvailable ? Colors.green : Colors.red,
          ),
        ),
        title: Text(name),
        subtitle: Text('$category • $price'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isAvailable ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isAvailable ? 'Available' : 'Out of Stock',
                style: TextStyle(
                  color: isAvailable ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, name),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                const PopupMenuItem(value: 'toggle', child: Text('Toggle Availability')),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(String name, String itemCount, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withValues(alpha: 0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(name),
        subtitle: Text(itemCount),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleCategoryAction(value, name),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularItemRow(String name, String orders) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(name)),
          Text(
            orders,
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showAddMenuDialog() {
    debugPrint('🍽️ [VENDOR-MENU-MANAGEMENT] Navigating to add menu item screen');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const MenuItemFormScreen(
          menuItemId: null, // null for create mode
          preSelectedCategoryId: null, // no pre-selected category
          preSelectedCategoryName: null,
        ),
      ),
    ).then((result) {
      debugPrint('🍽️ [VENDOR-MENU-MANAGEMENT] Returned from add menu item screen with result: $result');
      // Refresh the menu items if a new item was created
      if (result == true) {
        // The parent widgets will handle refresh through their providers
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Menu item created successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _handleMenuAction(String action, String itemName) {
    switch (action) {
      case 'edit':
        // Navigate to edit form - for demo purposes, we'll show a message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Edit $itemName - Navigate to MenuItemFormScreen with item ID')),
        );
        break;
      case 'duplicate':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Duplicate $itemName functionality available in real implementation')),
        );
        break;
      case 'toggle':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Toggle availability for $itemName functionality available in real implementation')),
        );
        break;
      case 'delete':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete $itemName functionality available in real implementation')),
        );
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unknown action')),
        );
    }
  }

  void _handleCategoryAction(String action, String categoryName) {
    String message;
    switch (action) {
      case 'edit':
        message = 'Edit $categoryName category functionality will be implemented here.';
        break;
      case 'delete':
        message = 'Delete $categoryName category functionality will be implemented here.';
        break;
      default:
        message = 'Unknown action';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}
