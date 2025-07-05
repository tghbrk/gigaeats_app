import 'package:flutter/material.dart';
import '../../../data/models/product.dart';

/// Widget for selecting multiple menu items for bulk operations
class BulkMenuItemSelector extends StatefulWidget {
  final List<Product> menuItems;
  final List<String> selectedItemIds;
  final Function(List<String>) onSelectionChanged;

  const BulkMenuItemSelector({
    super.key,
    required this.menuItems,
    required this.selectedItemIds,
    required this.onSelectionChanged,
  });

  @override
  State<BulkMenuItemSelector> createState() => _BulkMenuItemSelectorState();
}

class _BulkMenuItemSelectorState extends State<BulkMenuItemSelector> {
  String? _searchQuery;
  String? _selectedCategory;
  bool _showOnlyAvailable = false;
  
  List<String> get _filteredCategories {
    final categories = widget.menuItems
        .map((item) => item.category)
        .toSet()
        .toList();
    categories.sort();
    return categories;
  }

  List<Product> get _filteredMenuItems {
    var items = widget.menuItems;

    // Apply search filter
    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      items = items.where((item) =>
          item.name.toLowerCase().contains(_searchQuery!.toLowerCase()) ||
          (item.description?.toLowerCase().contains(_searchQuery!.toLowerCase()) ?? false)
      ).toList();
    }

    // Apply category filter
    if (_selectedCategory != null) {
      items = items.where((item) => item.category == _selectedCategory).toList();
    }

    // Apply availability filter
    if (_showOnlyAvailable) {
      items = items.where((item) => item.isAvailable ?? false).toList();
    }

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredMenuItems;

    return Column(
      children: [
        // Filters Section
        _buildFiltersSection(),
        
        // Selection Actions
        _buildSelectionActions(filteredItems),
        
        // Menu Items List
        Expanded(
          child: filteredItems.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredItems.length,
                  itemBuilder: (context, index) {
                    final item = filteredItems[index];
                    final isSelected = widget.selectedItemIds.contains(item.id);
                    return _buildMenuItemCard(item, isSelected);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection() {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            decoration: InputDecoration(
              hintText: 'Search menu items...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: theme.colorScheme.surface,
            ),
            onChanged: (value) {
              setState(() {
                _searchQuery = value.isEmpty ? null : value;
              });
            },
          ),
          
          const SizedBox(height: 12),
          
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Category Filter
                if (_filteredCategories.isNotEmpty) ...[
                  DropdownButton<String?>(
                    value: _selectedCategory,
                    hint: const Text('All Categories'),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('All Categories'),
                      ),
                      ..._filteredCategories.map((category) =>
                          DropdownMenuItem<String?>(
                            value: category,
                            child: Text(category),
                          )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                  ),
                  const SizedBox(width: 12),
                ],
                
                // Availability Filter
                FilterChip(
                  label: const Text('Available Only'),
                  selected: _showOnlyAvailable,
                  onSelected: (selected) {
                    setState(() {
                      _showOnlyAvailable = selected;
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectionActions(List<Product> filteredItems) {
    final theme = Theme.of(context);
    final selectedCount = widget.selectedItemIds.length;
    final totalCount = filteredItems.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '$selectedCount of ${widget.menuItems.length} items selected',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Select All Filtered - Use shorter text and flexible layout
          Flexible(
            child: TextButton(
              onPressed: totalCount > 0 ? () => _selectAllFiltered(filteredItems) : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Select All',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),

          const SizedBox(width: 4),

          // Clear Selection - Use shorter text and flexible layout
          Flexible(
            child: TextButton(
              onPressed: selectedCount > 0 ? _clearSelection : null,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Clear',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItemCard(Product item, bool isSelected) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (selected) => _toggleItemSelection(item.id, selected ?? false),
        title: Text(
          item.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.description != null && item.description!.isNotEmpty)
              Text(
                item.description!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    item.category,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (item.isAvailable ?? false)
                        ? theme.colorScheme.secondaryContainer
                        : theme.colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    (item.isAvailable ?? false) ? 'Available' : 'Unavailable',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: (item.isAvailable ?? false)
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'RM ${item.basePrice.toStringAsFixed(2)}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
        secondary: (item.imageUrl != null && item.imageUrl!.isNotEmpty)
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.restaurant,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu_outlined,
              size: 64,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'No Menu Items Found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search or filter criteria.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItemSelection(String itemId, bool selected) {
    final updatedSelection = List<String>.from(widget.selectedItemIds);
    
    if (selected) {
      if (!updatedSelection.contains(itemId)) {
        updatedSelection.add(itemId);
      }
    } else {
      updatedSelection.remove(itemId);
    }
    
    widget.onSelectionChanged(updatedSelection);
  }

  void _selectAllFiltered(List<Product> filteredItems) {
    final updatedSelection = List<String>.from(widget.selectedItemIds);
    
    for (final item in filteredItems) {
      if (!updatedSelection.contains(item.id)) {
        updatedSelection.add(item.id);
      }
    }
    
    widget.onSelectionChanged(updatedSelection);
  }

  void _clearSelection() {
    widget.onSelectionChanged([]);
  }
}
