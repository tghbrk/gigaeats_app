import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/menu_organization.dart';
import '../../../data/models/menu_item.dart';
import '../../widgets/menu_organization_management.dart';

/// Demo screen showcasing menu organization capabilities
class MenuOrganizationDemoScreen extends ConsumerStatefulWidget {
  const MenuOrganizationDemoScreen({super.key});

  @override
  ConsumerState<MenuOrganizationDemoScreen> createState() => _MenuOrganizationDemoScreenState();
}

class _MenuOrganizationDemoScreenState extends ConsumerState<MenuOrganizationDemoScreen> {
  late MenuOrganizationConfig _organizationConfig;
  late List<MenuItem> _menuItems;

  @override
  void initState() {
    super.initState();
    _initializeDemoData();
  }

  void _initializeDemoData() {
    // Create sample categories
    final categories = [
      EnhancedMenuCategory(
        id: 'cat-1',
        vendorId: 'vendor-1',
        name: 'Rice Dishes',
        description: 'Traditional Malaysian rice dishes',
        iconName: 'rice_bowl',
        sortOrder: 0,
        isFeatured: true,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      ),
      EnhancedMenuCategory(
        id: 'cat-2',
        vendorId: 'vendor-1',
        name: 'Noodles',
        description: 'Various noodle dishes',
        iconName: 'ramen_dining',
        sortOrder: 1,
        createdAt: DateTime.now().subtract(const Duration(days: 25)),
        updatedAt: DateTime.now(),
      ),
      EnhancedMenuCategory(
        id: 'cat-3',
        vendorId: 'vendor-1',
        name: 'Beverages',
        description: 'Hot and cold drinks',
        iconName: 'local_drink',
        sortOrder: 2,
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      EnhancedMenuCategory(
        id: 'cat-4',
        vendorId: 'vendor-1',
        name: 'Desserts',
        description: 'Sweet treats and desserts',
        iconName: 'cake',
        sortOrder: 3,
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      // Subcategory example
      EnhancedMenuCategory(
        id: 'subcat-1',
        vendorId: 'vendor-1',
        name: 'Fried Rice',
        description: 'Various fried rice dishes',
        iconName: 'rice_bowl',
        sortOrder: 0,
        parentCategoryId: 'cat-1',
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
    ];

    // Create sample menu items
    _menuItems = [
      // Rice Dishes
      MenuItem(
        id: 'item-1',
        vendorId: 'vendor-1',
        name: 'Nasi Lemak Special',
        description: 'Traditional coconut rice with sambal, anchovies, peanuts, and egg',
        category: 'cat-1',
        basePrice: 15.00,
        imageUrls: ['https://example.com/nasi-lemak.jpg'],
        dietaryTypes: [DietaryType.halal],
        isHalalCertified: true,
        tags: ['popular', 'traditional'],
        createdAt: DateTime.now().subtract(const Duration(days: 20)),
        updatedAt: DateTime.now(),
      ),
      MenuItem(
        id: 'item-2',
        vendorId: 'vendor-1',
        name: 'Nasi Goreng Kampung',
        description: 'Village-style fried rice with anchovies and chili',
        category: 'cat-1',
        basePrice: 12.00,
        imageUrls: ['https://example.com/nasi-goreng.jpg'],
        dietaryTypes: [DietaryType.halal],
        isHalalCertified: true,
        tags: ['spicy'],
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
        updatedAt: DateTime.now(),
      ),
      MenuItem(
        id: 'item-3',
        vendorId: 'vendor-1',
        name: 'Nasi Kerabu',
        description: 'Blue rice with herbs and vegetables',
        category: 'cat-1',
        basePrice: 13.50,
        imageUrls: ['https://example.com/nasi-kerabu.jpg'],
        dietaryTypes: [DietaryType.halal, DietaryType.vegetarian],
        isHalalCertified: true,
        tags: ['healthy', 'colorful'],
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
        updatedAt: DateTime.now(),
      ),
      
      // Noodles
      MenuItem(
        id: 'item-4',
        vendorId: 'vendor-1',
        name: 'Mee Goreng Mamak',
        description: 'Indian-style fried noodles with vegetables and tofu',
        category: 'cat-2',
        basePrice: 10.00,
        imageUrls: ['https://example.com/mee-goreng.jpg'],
        dietaryTypes: [DietaryType.halal, DietaryType.vegetarian],
        isHalalCertified: true,
        tags: ['vegetarian', 'spicy'],
        createdAt: DateTime.now().subtract(const Duration(days: 12)),
        updatedAt: DateTime.now(),
      ),
      MenuItem(
        id: 'item-5',
        vendorId: 'vendor-1',
        name: 'Laksa Johor',
        description: 'Thick rice noodles in spicy coconut curry',
        category: 'cat-2',
        basePrice: 14.00,
        imageUrls: ['https://example.com/laksa.jpg'],
        dietaryTypes: [DietaryType.halal],
        isHalalCertified: true,
        tags: ['spicy', 'coconut'],
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        updatedAt: DateTime.now(),
      ),
      
      // Beverages
      MenuItem(
        id: 'item-6',
        vendorId: 'vendor-1',
        name: 'Teh Tarik',
        description: 'Pulled tea with condensed milk',
        category: 'cat-3',
        basePrice: 3.50,
        imageUrls: ['https://example.com/teh-tarik.jpg'],
        dietaryTypes: [DietaryType.halal],
        isHalalCertified: true,
        tags: ['hot', 'sweet'],
        createdAt: DateTime.now().subtract(const Duration(days: 8)),
        updatedAt: DateTime.now(),
      ),
      MenuItem(
        id: 'item-7',
        vendorId: 'vendor-1',
        name: 'Kopi O',
        description: 'Black coffee without milk',
        category: 'cat-3',
        basePrice: 2.50,
        imageUrls: ['https://example.com/kopi-o.jpg'],
        dietaryTypes: [DietaryType.halal, DietaryType.vegan],
        isHalalCertified: true,
        tags: ['hot', 'strong'],
        createdAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now(),
      ),
      
      // Desserts
      MenuItem(
        id: 'item-8',
        vendorId: 'vendor-1',
        name: 'Cendol',
        description: 'Shaved ice with green rice flour jelly and coconut milk',
        category: 'cat-4',
        basePrice: 5.00,
        imageUrls: ['https://example.com/cendol.jpg'],
        dietaryTypes: [DietaryType.halal, DietaryType.vegetarian],
        isHalalCertified: true,
        tags: ['cold', 'sweet', 'refreshing'],
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        updatedAt: DateTime.now(),
      ),
    ];

    // Create sample menu item positions
    final itemPositions = [
      MenuItemPosition(
        menuItemId: 'item-1',
        categoryId: 'cat-1',
        sortOrder: 0,
        isFeatured: true,
        isRecommended: true,
        isPopular: true,
        updatedAt: DateTime.now(),
      ),
      MenuItemPosition(
        menuItemId: 'item-2',
        categoryId: 'cat-1',
        sortOrder: 1,
        isRecommended: true,
        updatedAt: DateTime.now(),
      ),
      MenuItemPosition(
        menuItemId: 'item-3',
        categoryId: 'cat-1',
        sortOrder: 2,
        isNew: true,
        updatedAt: DateTime.now(),
      ),
      MenuItemPosition(
        menuItemId: 'item-4',
        categoryId: 'cat-2',
        sortOrder: 0,
        isFeatured: true,
        updatedAt: DateTime.now(),
      ),
      MenuItemPosition(
        menuItemId: 'item-5',
        categoryId: 'cat-2',
        sortOrder: 1,
        isPopular: true,
        updatedAt: DateTime.now(),
      ),
      MenuItemPosition(
        menuItemId: 'item-6',
        categoryId: 'cat-3',
        sortOrder: 0,
        isPopular: true,
        updatedAt: DateTime.now(),
      ),
      MenuItemPosition(
        menuItemId: 'item-7',
        categoryId: 'cat-3',
        sortOrder: 1,
        updatedAt: DateTime.now(),
      ),
      MenuItemPosition(
        menuItemId: 'item-8',
        categoryId: 'cat-4',
        sortOrder: 0,
        isFeatured: true,
        isNew: true,
        updatedAt: DateTime.now(),
      ),
    ];

    // Create organization configuration
    _organizationConfig = MenuOrganizationConfig(
      vendorId: 'vendor-1',
      categories: categories,
      itemPositions: itemPositions,
      displayStyle: MenuDisplayStyle.grid,
      enableCategoryImages: true,
      enableSubcategories: true,
      enableDragAndDrop: true,
      showItemCounts: true,
      groupByAvailability: false,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Menu Organization'),
            Text(
              'Demo: Drag & Drop Menu Management',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _showMenuPreview,
            icon: const Icon(Icons.preview),
            tooltip: 'Preview customer view',
          ),
          IconButton(
            onPressed: _showAnalytics,
            icon: const Icon(Icons.analytics),
            tooltip: 'View organization analytics',
          ),
        ],
      ),
      body: Column(
        children: [
          // Quick stats header
          _buildQuickStatsHeader(),
          
          // Main organization interface
          Expanded(
            child: MenuOrganizationManagement(
              organizationConfig: _organizationConfig,
              menuItems: _menuItems,
              onConfigChanged: (config) {
                setState(() {
                  _organizationConfig = config;
                });
              },
              enableDragAndDrop: true,
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomActions(),
    );
  }

  Widget _buildQuickStatsHeader() {
    final stats = _calculateOrganizationStats();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: Colors.grey[300]!),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              'Categories',
              '${_organizationConfig.categories.length}',
              Icons.category,
              Colors.blue,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Menu Items',
              '${_menuItems.length}',
              Icons.restaurant_menu,
              Colors.green,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Featured Items',
              '${stats.featuredItems}',
              Icons.star,
              Colors.orange,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildStatCard(
              'Organization Score',
              '${stats.organizationScore}%',
              Icons.trending_up,
              Colors.purple,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _exportMenuStructure,
              icon: const Icon(Icons.download),
              label: const Text('Export Structure'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _optimizeMenuLayout,
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Auto-Optimize'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _saveMenuOrganization,
              icon: const Icon(Icons.save),
              label: const Text('Save Organization'),
            ),
          ),
        ],
      ),
    );
  }

  OrganizationStats _calculateOrganizationStats() {
    final featuredItems = _organizationConfig.itemPositions
        .where((pos) => pos.isFeatured)
        .length;

    // Calculate organization score based on various factors
    int score = 70; // Base score
    
    // Bonus for having categories
    if (_organizationConfig.categories.length >= 3) score += 10;
    
    // Bonus for featured items
    if (featuredItems > 0) score += 10;
    
    // Bonus for using subcategories
    if (_organizationConfig.categories.any((cat) => cat.hasSubcategories)) score += 5;
    
    // Bonus for item positioning
    if (_organizationConfig.itemPositions.isNotEmpty) score += 5;
    
    return OrganizationStats(
      featuredItems: featuredItems,
      organizationScore: score.clamp(0, 100),
    );
  }

  void _showMenuPreview() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Customer Menu Preview',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _buildCustomerMenuPreview(),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomerMenuPreview() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _organizationConfig.rootCategories.length,
              itemBuilder: (context, index) {
                final category = _organizationConfig.rootCategories[index];
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category.name),
                    selected: index == 0,
                    onSelected: (selected) {},
                  ),
                );
              },
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Sample menu items for first category
          if (_organizationConfig.rootCategories.isNotEmpty) ...[
            Text(
              _organizationConfig.rootCategories.first.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            ..._getMenuItemsForCategory(_organizationConfig.rootCategories.first.id)
                .take(3)
                .map((item) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.restaurant),
                    ),
                    title: Text(item.name),
                    subtitle: Text('RM ${item.basePrice.toStringAsFixed(2)}'),
                    trailing: _buildItemBadges(item.id),
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _buildItemBadges(String itemId) {
    final position = _organizationConfig.getItemPosition(itemId);
    if (position == null) return const SizedBox.shrink();
    
    return Wrap(
      spacing: 4,
      children: [
        if (position.isFeatured)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Featured',
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        if (position.isNew)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'New',
              style: TextStyle(
                fontSize: 10,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  List<MenuItem> _getMenuItemsForCategory(String categoryId) {
    return _menuItems.where((item) => item.category == categoryId).toList();
  }

  void _showAnalytics() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Organization Analytics'),
        content: const Text('Detailed menu organization analytics and performance metrics would be displayed here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _exportMenuStructure() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu structure exported successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _optimizeMenuLayout() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu layout optimized based on analytics!'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _saveMenuOrganization() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Menu organization saved successfully!'),
        backgroundColor: Colors.green,
      ),
    );
  }
}

/// Helper class for organization statistics
class OrganizationStats {
  final int featuredItems;
  final int organizationScore;

  const OrganizationStats({
    required this.featuredItems,
    required this.organizationScore,
  });
}
