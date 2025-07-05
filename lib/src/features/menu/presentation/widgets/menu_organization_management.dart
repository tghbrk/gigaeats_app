import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/menu_organization.dart';
import '../../data/models/menu_item.dart';

/// Menu organization management widget with drag-and-drop and hierarchical structure
class MenuOrganizationManagement extends ConsumerStatefulWidget {
  final MenuOrganizationConfig organizationConfig;
  final List<MenuItem> menuItems;
  final Function(MenuOrganizationConfig) onConfigChanged;
  final bool enableDragAndDrop;

  const MenuOrganizationManagement({
    super.key,
    required this.organizationConfig,
    required this.menuItems,
    required this.onConfigChanged,
    this.enableDragAndDrop = true,
  });

  @override
  ConsumerState<MenuOrganizationManagement> createState() => _MenuOrganizationManagementState();
}

class _MenuOrganizationManagementState extends ConsumerState<MenuOrganizationManagement>
    with TickerProviderStateMixin {
  
  late TabController _tabController;
  late MenuOrganizationConfig _config;
  String? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _config = widget.organizationConfig;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(MenuOrganizationManagement oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.organizationConfig != widget.organizationConfig) {
      _config = widget.organizationConfig;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 16),
        _buildTabBar(),
        const SizedBox(height: 16),
        Expanded(
          child: _buildTabContent(),
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Menu Organization',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Organize categories and menu items with drag-and-drop',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        _buildQuickActions(),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: _previewMenuLayout,
          icon: const Icon(Icons.preview),
          tooltip: 'Preview menu layout',
        ),
        IconButton(
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.refresh),
          tooltip: 'Reset to defaults',
        ),
        PopupMenuButton<String>(
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'import', child: Text('Import Layout')),
            const PopupMenuItem(value: 'export', child: Text('Export Layout')),
            const PopupMenuItem(value: 'templates', child: Text('Use Template')),
          ],
          child: const Icon(Icons.more_vert),
        ),
      ],
    );
  }

  Widget _buildTabBar() {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(icon: Icon(Icons.category), text: 'Categories'),
        Tab(icon: Icon(Icons.reorder), text: 'Menu Items'),
        Tab(icon: Icon(Icons.settings), text: 'Settings'),
      ],
    );
  }

  Widget _buildTabContent() {
    return TabBarView(
      controller: _tabController,
      children: [
        _buildCategoriesTab(),
        _buildMenuItemsTab(),
        _buildSettingsTab(),
      ],
    );
  }

  Widget _buildCategoriesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Category Management',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _addCategory,
                icon: const Icon(Icons.add),
                label: const Text('Add Category'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          if (_config.categories.isEmpty)
            _buildEmptyCategoriesState()
          else
            _buildCategoriesList(),
        ],
      ),
    );
  }

  Widget _buildEmptyCategoriesState() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.category, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'No Categories Yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create categories to organize your menu items',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add),
              label: const Text('Create First Category'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesList() {
    final rootCategories = _config.rootCategories;
    
    if (!widget.enableDragAndDrop) {
      return Column(
        children: rootCategories.map((category) => 
          _buildCategoryCard(category)
        ).toList(),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rootCategories.length,
      onReorder: _onReorderCategories,
      itemBuilder: (context, index) {
        final category = rootCategories[index];
        return _buildCategoryCard(category, key: ValueKey(category.id));
      },
    );
  }

  Widget _buildCategoryCard(EnhancedMenuCategory category, {Key? key}) {
    final itemCount = _getItemCountForCategory(category.id);
    final subcategories = _config.getSubcategories(category.id);
    
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enableDragAndDrop)
              Icon(Icons.drag_handle, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                _getCategoryIcon(category.displayIcon),
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
          ],
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (category.description != null)
              Text(category.description!),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildCategoryBadge('$itemCount items', Colors.blue),
                if (subcategories.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  _buildCategoryBadge('${subcategories.length} subcategories', Colors.green),
                ],
                if (category.isFeatured) ...[
                  const SizedBox(width: 8),
                  _buildCategoryBadge('Featured', Colors.orange),
                ],
                if (!category.isVisible) ...[
                  const SizedBox(width: 8),
                  _buildCategoryBadge('Hidden', Colors.grey),
                ],
              ],
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editCategory(category),
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit category',
            ),
            PopupMenuButton<String>(
              onSelected: (value) => _handleCategoryAction(value, category),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                const PopupMenuItem(value: 'addSubcategory', child: Text('Add Subcategory')),
                PopupMenuItem(
                  value: category.isVisible ? 'hide' : 'show',
                  child: Text(category.isVisible ? 'Hide' : 'Show'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        children: [
          if (subcategories.isNotEmpty)
            ...subcategories.map((subcat) => 
              Padding(
                padding: const EdgeInsets.only(left: 32, right: 16, bottom: 8),
                child: _buildSubcategoryCard(subcat),
              )
            ),
        ],
      ),
    );
  }

  Widget _buildSubcategoryCard(EnhancedMenuCategory subcategory) {
    final itemCount = _getItemCountForCategory(subcategory.id);
    
    return Card(
      elevation: 1,
      child: ListTile(
        leading: Icon(
          _getCategoryIcon(subcategory.displayIcon),
          color: Colors.grey[600],
          size: 20,
        ),
        title: Text(subcategory.name),
        subtitle: Text('$itemCount items'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _editCategory(subcategory),
              icon: const Icon(Icons.edit_outlined, size: 20),
            ),
            IconButton(
              onPressed: () => _deleteCategory(subcategory),
              icon: const Icon(Icons.delete_outline, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildMenuItemsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCategorySelector(),
          const SizedBox(height: 16),
          
          if (_selectedCategoryId == null)
            _buildSelectCategoryPrompt()
          else
            _buildMenuItemsList(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Category to Organize',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _config.categories.map((category) => 
                FilterChip(
                  label: Text(category.name),
                  selected: _selectedCategoryId == category.id,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategoryId = selected ? category.id : null;
                    });
                  },
                )
              ).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectCategoryPrompt() {
    return Card(
      child: Container(
        padding: const EdgeInsets.all(32),
        width: double.infinity,
        child: Column(
          children: [
            Icon(Icons.reorder, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Select a Category',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choose a category above to organize its menu items',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItemsList() {
    final categoryItems = _getMenuItemsForCategory(_selectedCategoryId!);
    
    if (categoryItems.isEmpty) {
      return Card(
        child: Container(
          padding: const EdgeInsets.all(32),
          width: double.infinity,
          child: Column(
            children: [
              Icon(Icons.restaurant_menu, size: 64, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'No Items in This Category',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Add menu items to this category to organize them',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (!widget.enableDragAndDrop) {
      return Column(
        children: categoryItems.map((item) => 
          _buildMenuItemCard(item)
        ).toList(),
      );
    }

    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categoryItems.length,
      onReorder: (oldIndex, newIndex) => _onReorderMenuItems(oldIndex, newIndex, categoryItems),
      itemBuilder: (context, index) {
        final item = categoryItems[index];
        return _buildMenuItemCard(item, key: ValueKey(item.id));
      },
    );
  }

  Widget _buildMenuItemCard(MenuItem item, {Key? key}) {
    final position = _config.getItemPosition(item.id);
    
    return Card(
      key: key,
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.enableDragAndDrop)
              Icon(Icons.drag_handle, color: Colors.grey[400], size: 20),
            const SizedBox(width: 8),
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(8),
              ),
              child: item.imageUrls.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        item.imageUrls.first,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => 
                            const Icon(Icons.restaurant),
                      ),
                    )
                  : const Icon(Icons.restaurant),
            ),
          ],
        ),
        title: Text(
          item.name,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('RM ${item.basePrice.toStringAsFixed(2)}'),
            const SizedBox(height: 4),
            Row(
              children: [
                if (position?.isFeatured == true)
                  _buildItemBadge('Featured', Colors.orange),
                if (position?.isRecommended == true) ...[
                  if (position?.isFeatured == true) const SizedBox(width: 4),
                  _buildItemBadge('Recommended', Colors.green),
                ],
                if (position?.isNew == true) ...[
                  if ((position?.isFeatured == true) || (position?.isRecommended == true)) 
                    const SizedBox(width: 4),
                  _buildItemBadge('New', Colors.blue),
                ],
                if (position?.isPopular == true) ...[
                  if ((position?.isFeatured == true) || (position?.isRecommended == true) || (position?.isNew == true)) 
                    const SizedBox(width: 4),
                  _buildItemBadge('Popular', Colors.purple),
                ],
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuItemAction(value, item),
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'featured',
              child: Text(position?.isFeatured == true ? 'Remove Featured' : 'Mark Featured'),
            ),
            PopupMenuItem(
              value: 'recommended',
              child: Text(position?.isRecommended == true ? 'Remove Recommended' : 'Mark Recommended'),
            ),
            PopupMenuItem(
              value: 'new',
              child: Text(position?.isNew == true ? 'Remove New' : 'Mark New'),
            ),
            PopupMenuItem(
              value: 'popular',
              child: Text(position?.isPopular == true ? 'Remove Popular' : 'Mark Popular'),
            ),
            const PopupMenuItem(value: 'move', child: Text('Move to Category')),
          ],
        ),
      ),
    );
  }

  Widget _buildItemBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 8,
          color: color.withValues(alpha: 0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Display Settings',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          SwitchListTile(
            title: const Text('Enable Category Images'),
            subtitle: const Text('Show images for categories'),
            value: _config.enableCategoryImages,
            onChanged: (value) {
              _updateConfig(_config.copyWith(enableCategoryImages: value));
            },
          ),
          
          SwitchListTile(
            title: const Text('Enable Subcategories'),
            subtitle: const Text('Allow nested category structure'),
            value: _config.enableSubcategories,
            onChanged: (value) {
              _updateConfig(_config.copyWith(enableSubcategories: value));
            },
          ),
          
          SwitchListTile(
            title: const Text('Show Item Counts'),
            subtitle: const Text('Display number of items in each category'),
            value: _config.showItemCounts,
            onChanged: (value) {
              _updateConfig(_config.copyWith(showItemCounts: value));
            },
          ),
          
          SwitchListTile(
            title: const Text('Group by Availability'),
            subtitle: const Text('Show available items first'),
            value: _config.groupByAvailability,
            onChanged: (value) {
              _updateConfig(_config.copyWith(groupByAvailability: value));
            },
          ),
          
          const SizedBox(height: 24),
          
          Text(
            'Display Style',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          ...MenuDisplayStyle.values.map((style) => 
            RadioListTile<MenuDisplayStyle>(
              title: Text(_getDisplayStyleLabel(style)),
              subtitle: Text(_getDisplayStyleDescription(style)),
              value: style,
              groupValue: _config.displayStyle,
              onChanged: (value) {
                if (value != null) {
                  _updateConfig(_config.copyWith(displayStyle: value));
                }
              },
            )
          ),
        ],
      ),
    );
  }

  // Helper methods
  IconData _getCategoryIcon(String iconName) {
    switch (iconName) {
      case 'rice_bowl': return Icons.rice_bowl;
      case 'ramen_dining': return Icons.ramen_dining;
      case 'local_drink': return Icons.local_drink;
      case 'cake': return Icons.cake;
      case 'restaurant': return Icons.restaurant;
      case 'dinner_dining': return Icons.dinner_dining;
      case 'eco': return Icons.eco;
      case 'set_meal': return Icons.set_meal;
      default: return Icons.restaurant_menu;
    }
  }

  int _getItemCountForCategory(String categoryId) {
    return widget.menuItems.where((item) => item.category == categoryId).length;
  }

  List<MenuItem> _getMenuItemsForCategory(String categoryId) {
    final items = widget.menuItems.where((item) => item.category == categoryId).toList();
    final positions = _config.getItemsInCategory(categoryId);
    
    // Sort items by their position order
    items.sort((a, b) {
      final posA = positions.cast<MenuItemPosition?>().firstWhere(
        (pos) => pos?.menuItemId == a.id,
        orElse: () => null,
      );
      final posB = positions.cast<MenuItemPosition?>().firstWhere(
        (pos) => pos?.menuItemId == b.id,
        orElse: () => null,
      );
      
      final orderA = posA?.sortOrder ?? 999;
      final orderB = posB?.sortOrder ?? 999;
      
      return orderA.compareTo(orderB);
    });
    
    return items;
  }

  String _getDisplayStyleLabel(MenuDisplayStyle style) {
    switch (style) {
      case MenuDisplayStyle.list: return 'List View';
      case MenuDisplayStyle.grid: return 'Grid View';
      case MenuDisplayStyle.card: return 'Card View';
      case MenuDisplayStyle.compact: return 'Compact View';
    }
  }

  String _getDisplayStyleDescription(MenuDisplayStyle style) {
    switch (style) {
      case MenuDisplayStyle.list: return 'Simple list layout';
      case MenuDisplayStyle.grid: return 'Grid layout with images';
      case MenuDisplayStyle.card: return 'Card-based layout';
      case MenuDisplayStyle.compact: return 'Compact list layout';
    }
  }

  void _updateConfig(MenuOrganizationConfig newConfig) {
    setState(() {
      _config = newConfig;
    });
    widget.onConfigChanged(newConfig);
  }

  // Event handlers
  void _onReorderCategories(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final categories = List<EnhancedMenuCategory>.from(_config.rootCategories);
      final item = categories.removeAt(oldIndex);
      categories.insert(newIndex, item);
      
      _config = _config.updateCategoryOrder(categories);
      widget.onConfigChanged(_config);
    });
  }

  void _onReorderMenuItems(int oldIndex, int newIndex, List<MenuItem> items) {
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    
    final reorderedItems = List<MenuItem>.from(items);
    final item = reorderedItems.removeAt(oldIndex);
    reorderedItems.insert(newIndex, item);
    
    final itemIds = reorderedItems.map((item) => item.id).toList();
    
    setState(() {
      _config = _config.updateItemPositions(_selectedCategoryId!, itemIds);
      widget.onConfigChanged(_config);
    });
  }

  void _addCategory() {
    // TODO: Show add category dialog
  }

  void _editCategory(EnhancedMenuCategory category) {
    // TODO: Show edit category dialog
  }

  void _deleteCategory(EnhancedMenuCategory category) {
    // TODO: Show delete confirmation dialog
  }

  void _handleCategoryAction(String action, EnhancedMenuCategory category) {
    switch (action) {
      case 'duplicate':
        // TODO: Duplicate category
        break;
      case 'addSubcategory':
        // TODO: Add subcategory
        break;
      case 'hide':
      case 'show':
        // TODO: Toggle visibility
        break;
      case 'delete':
        _deleteCategory(category);
        break;
    }
  }

  void _handleMenuItemAction(String action, MenuItem item) {
    final currentPosition = _config.getItemPosition(item.id);
    
    switch (action) {
      case 'featured':
        _toggleItemFlag(item.id, 'featured', !(currentPosition?.isFeatured ?? false));
        break;
      case 'recommended':
        _toggleItemFlag(item.id, 'recommended', !(currentPosition?.isRecommended ?? false));
        break;
      case 'new':
        _toggleItemFlag(item.id, 'new', !(currentPosition?.isNew ?? false));
        break;
      case 'popular':
        _toggleItemFlag(item.id, 'popular', !(currentPosition?.isPopular ?? false));
        break;
      case 'move':
        // TODO: Show move to category dialog
        break;
    }
  }

  void _toggleItemFlag(String itemId, String flag, bool value) {
    final currentPosition = _config.getItemPosition(itemId);
    MenuItemPosition newPosition;
    
    if (currentPosition != null) {
      switch (flag) {
        case 'featured':
          newPosition = currentPosition.copyWith(isFeatured: value);
          break;
        case 'recommended':
          newPosition = currentPosition.copyWith(isRecommended: value);
          break;
        case 'new':
          newPosition = currentPosition.copyWith(isNew: value);
          break;
        case 'popular':
          newPosition = currentPosition.copyWith(isPopular: value);
          break;
        default:
          return;
      }
    } else {
      // Create new position
      newPosition = MenuItemPosition(
        menuItemId: itemId,
        categoryId: _selectedCategoryId!,
        sortOrder: 0,
        isFeatured: flag == 'featured' ? value : false,
        isRecommended: flag == 'recommended' ? value : false,
        isNew: flag == 'new' ? value : false,
        isPopular: flag == 'popular' ? value : false,
        updatedAt: DateTime.now(),
      );
    }
    
    final updatedPositions = List<MenuItemPosition>.from(_config.itemPositions);
    final existingIndex = updatedPositions.indexWhere((pos) => pos.menuItemId == itemId);
    
    if (existingIndex >= 0) {
      updatedPositions[existingIndex] = newPosition;
    } else {
      updatedPositions.add(newPosition);
    }
    
    setState(() {
      _config = _config.copyWith(itemPositions: updatedPositions);
      widget.onConfigChanged(_config);
    });
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'import':
        // TODO: Import layout
        break;
      case 'export':
        // TODO: Export layout
        break;
      case 'templates':
        // TODO: Show templates
        break;
    }
  }

  void _previewMenuLayout() {
    // TODO: Show preview dialog
  }

  void _resetToDefaults() {
    // TODO: Reset to default configuration
  }
}
