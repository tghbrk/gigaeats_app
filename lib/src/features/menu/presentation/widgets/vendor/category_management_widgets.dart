import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/menu_item.dart';
import '../../../data/models/product.dart';
import '../../providers/menu_category_providers.dart';
import '../../screens/vendor/menu_item_form_screen.dart';

// ==================== CATEGORY LIST VIEW ====================

/// Material Design 3 category list view with drag-and-drop support
class CategoryListView extends ConsumerWidget {
  final String vendorId;
  final Function(MenuCategory)? onCategoryTap;
  final Function(MenuCategory)? onCategoryEdit;
  final Function(MenuCategory)? onCategoryDelete;
  final bool enableReordering;

  const CategoryListView({
    super.key,
    required this.vendorId,
    this.onCategoryTap,
    this.onCategoryEdit,
    this.onCategoryDelete,
    this.enableReordering = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(vendorCategoriesWithCountsProvider(vendorId));

    return categoriesAsync.when(
      data: (categoriesWithCounts) {
        if (categoriesWithCounts.isEmpty) {
          return const CategoryEmptyState();
        }

        if (enableReordering) {
          return _buildReorderableList(context, ref, categoriesWithCounts);
        } else {
          return _buildStaticList(context, categoriesWithCounts);
        }
      },
      loading: () => const CategoryLoadingState(),
      error: (error, stack) => CategoryErrorState(
        error: error.toString(),
        onRetry: () => ref.invalidate(vendorCategoriesWithCountsProvider(vendorId)),
      ),
    );
  }

  Widget _buildReorderableList(
    BuildContext context,
    WidgetRef ref,
    List<Map<String, dynamic>> categoriesWithCounts,
  ) {
    final theme = Theme.of(context);
    final categoryManagement = ref.watch(categoryManagementProvider);

    return Stack(
      children: [
        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) => _handleReorder(ref, categoriesWithCounts, oldIndex, newIndex),
          proxyDecorator: (child, index, animation) => _buildDragProxy(child, animation, theme),
          itemCount: categoriesWithCounts.length,
          itemBuilder: (context, index) {
            final item = categoriesWithCounts[index];
            final category = item['category'] as MenuCategory;
            final itemCount = item['itemCount'] as int;

            return CategoryCard(
              key: ValueKey(category.id),
              category: category,
              itemCount: itemCount,
              vendorId: vendorId,
              showDragHandle: true,
              isReordering: categoryManagement.isReordering,
              onTap: () => onCategoryTap?.call(category),
              onEdit: () => onCategoryEdit?.call(category),
              onDelete: () => onCategoryDelete?.call(category),
            );
          },
        ),

        // Reordering overlay
        if (categoryManagement.isReordering)
          _buildReorderingOverlay(context, theme),
      ],
    );
  }

  Widget _buildDragProxy(Widget child, Animation<double> animation, ThemeData theme) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.scale(
          scale: 1.05,
          child: Transform.rotate(
            angle: 0.02,
            child: Material(
              elevation: 8,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary,
                    width: 2,
                  ),
                ),
                child: child,
              ),
            ),
          ),
        );
      },
      child: child,
    );
  }

  Widget _buildReorderingOverlay(BuildContext context, ThemeData theme) {
    return Positioned.fill(
      child: Container(
        color: theme.colorScheme.surface.withValues(alpha: 0.8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Updating category order...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStaticList(BuildContext context, List<Map<String, dynamic>> categoriesWithCounts) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: categoriesWithCounts.length,
      itemBuilder: (context, index) {
        final item = categoriesWithCounts[index];
        final category = item['category'] as MenuCategory;
        final itemCount = item['itemCount'] as int;

        return CategoryCard(
          category: category,
          itemCount: itemCount,
          vendorId: vendorId,
          showDragHandle: false,
          isReordering: false,
          onTap: () => onCategoryTap?.call(category),
          onEdit: () => onCategoryEdit?.call(category),
          onDelete: () => onCategoryDelete?.call(category),
        );
      },
    );
  }

  void _handleReorder(
    WidgetRef ref,
    List<Map<String, dynamic>> categoriesWithCounts,
    int oldIndex,
    int newIndex,
  ) {
    debugPrint('🏷️ [CATEGORY-LIST] Reordering categories: $oldIndex -> $newIndex');

    // Prevent reordering if already in progress
    final categoryManagement = ref.read(categoryManagementProvider);
    if (categoryManagement.isReordering) {
      debugPrint('🏷️ [CATEGORY-LIST] Reordering already in progress, ignoring');
      return;
    }

    // Validate indices
    if (oldIndex < 0 || oldIndex >= categoriesWithCounts.length ||
        newIndex < 0 || newIndex >= categoriesWithCounts.length) {
      debugPrint('🏷️ [CATEGORY-LIST] Invalid reorder indices: $oldIndex, $newIndex');
      return;
    }

    // No change needed
    if (oldIndex == newIndex) {
      debugPrint('🏷️ [CATEGORY-LIST] No reorder needed, same position');
      return;
    }

    // Adjust newIndex for ReorderableListView behavior
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    try {
      final categories = categoriesWithCounts.map((item) => item['category'] as MenuCategory).toList();

      debugPrint('🏷️ [CATEGORY-LIST] Original order:');
      for (int i = 0; i < categories.length; i++) {
        debugPrint('🏷️ [CATEGORY-LIST]   $i: ${categories[i].name} (ID: ${categories[i].id}, sort_order: ${categories[i].sortOrder})');
      }

      final category = categories.removeAt(oldIndex);
      categories.insert(newIndex, category);

      final categoryIds = categories.map((c) => c.id).toList();

      debugPrint('🏷️ [CATEGORY-LIST] New category order:');
      for (int i = 0; i < categories.length; i++) {
        debugPrint('🏷️ [CATEGORY-LIST]   $i: ${categories[i].name} (ID: ${categories[i].id}) -> will be sort_order: $i');
      }
      debugPrint('🏷️ [CATEGORY-LIST] Category IDs to send: ${categoryIds.join(', ')}');

      ref.read(categoryManagementProvider.notifier).reorderCategories(
        vendorId: vendorId,
        categoryIds: categoryIds,
      );
    } catch (e) {
      debugPrint('🏷️ [CATEGORY-LIST] Error during reorder: $e');
    }
  }
}

// ==================== CATEGORY CARD ====================

/// Material Design 3 category card component with expandable menu items
class CategoryCard extends ConsumerWidget {
  final MenuCategory category;
  final int itemCount;
  final bool showDragHandle;
  final bool isReordering;
  final String vendorId;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const CategoryCard({
    super.key,
    required this.category,
    required this.itemCount,
    required this.vendorId,
    this.showDragHandle = false,
    this.isReordering = false,
    this.onTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryManagement = ref.watch(categoryManagementProvider);
    final isExpanded = categoryManagement.expandedCategories.contains(category.id);



    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Card(
        elevation: isReordering ? 1 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: showDragHandle ? BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ) : BorderSide.none,
        ),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: isReordering ? 0.7 : 1.0,
          child: Column(
            children: [
              // Category Header
              InkWell(
                onTap: isReordering ? null : () {
                  // Toggle expansion when tapped
                  ref.read(categoryManagementProvider.notifier).toggleCategoryExpansion(category.id);
                  onTap?.call();
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
              // Category Icon/Image
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: category.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          category.imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(colorScheme),
                        ),
                      )
                    : _buildDefaultIcon(colorScheme),
              ),
              
              const SizedBox(width: 16),
              
              // Category Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (category.description?.isNotEmpty == true) ...[
                      const SizedBox(height: 4),
                      Text(
                        category.description!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_menu,
                          size: 16,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$itemCount ${itemCount == 1 ? 'item' : 'items'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Action Buttons - Compact Layout
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Expand/Collapse Button
                  IconButton(
                    onPressed: isReordering ? null : () {
                      ref.read(categoryManagementProvider.notifier).toggleCategoryExpansion(category.id);
                    },
                    icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                    tooltip: isExpanded ? 'Collapse' : 'Expand',
                    iconSize: 20,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: const EdgeInsets.all(4),
                  ),
                  // Actions Menu
                  PopupMenuButton<String>(
                    onSelected: (value) => _handleCategoryAction(context, ref, value),
                    enabled: !isReordering,
                    icon: const Icon(Icons.more_vert),
                    iconSize: 20,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    padding: const EdgeInsets.all(4),
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined),
                          title: Text('Edit Category'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline),
                          title: Text('Delete Category'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  if (showDragHandle) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.drag_handle,
                      color: isReordering
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                  ],
                ],
              ),
                    ],
                  ),
                ),
              ),

              // Expandable Menu Items Section
              if (isExpanded) _buildMenuItemsSection(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDefaultIcon(ColorScheme colorScheme) {
    return Icon(
      Icons.category,
      size: 28,
      color: colorScheme.onPrimaryContainer,
    );
  }

  /// Handle category action from popup menu
  void _handleCategoryAction(BuildContext context, WidgetRef ref, String action) {
    switch (action) {
      case 'edit':
        onEdit?.call();
        break;
      case 'delete':
        onDelete?.call();
        break;
    }
  }

  /// Build the expandable menu items section
  Widget _buildMenuItemsSection(BuildContext context, WidgetRef ref) {
    debugPrint('🏷️ [CATEGORY-CARD] Building menu items section for category: ${category.name} (ID: ${category.id})');
    final menuItemsAsync = ref.watch(menuItemsByCategoryProvider((vendorId: vendorId, categoryId: category.id)));

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Menu Items Header
            Row(
              children: [
                Icon(
                  Icons.restaurant_menu,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Menu Items',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                // Add Menu Item Button
                IconButton(
                  onPressed: () => _showAddMenuItemDialog(context),
                  icon: const Icon(Icons.add),
                  tooltip: 'Add Menu Item',
                  iconSize: 20,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Menu Items List
            menuItemsAsync.when(
              data: (menuItems) {
                if (menuItems.isEmpty) {
                  return _buildEmptyMenuItems(context);
                }

                return Column(
                  children: menuItems.map((item) => _buildMenuItemTile(context, item)).toList(),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, stack) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Error loading menu items: $error',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build empty menu items state
  Widget _buildEmptyMenuItems(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            Icons.restaurant_menu_outlined,
            size: 48,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 12),
          Text(
            'No menu items in this category',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showAddMenuItemDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add First Item'),
          ),
        ],
      ),
    );
  }

  /// Build individual menu item tile
  Widget _buildMenuItemTile(BuildContext context, Product item) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        dense: true,
        leading: item.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  item.imageUrl!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.fastfood,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              )
            : Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.fastfood,
                  size: 20,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
        title: Text(
          item.name,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          'RM ${item.basePrice.toStringAsFixed(2)}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleMenuItemAction(context, value, item),
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'edit', child: Text('Edit')),
            const PopupMenuItem(value: 'move', child: Text('Move to Category')),
            const PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }

  /// Show add menu item dialog
  void _showAddMenuItemDialog(BuildContext context) {
    debugPrint('🍽️ [CATEGORY-CARD] Navigating to add menu item for category: ${category.name}');
    debugPrint('🍽️ [CATEGORY-CARD] Category ID: ${category.id}');

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => MenuItemFormScreen(
          menuItemId: null, // null for create mode
          preSelectedCategoryId: category.id,
          preSelectedCategoryName: category.name,
        ),
      ),
    ).then((result) {
      debugPrint('🍽️ [CATEGORY-CARD] Returned from add menu item screen with result: $result');
      // Refresh the menu items if a new item was created
      if (result == true) {
        // Invalidate the menu items provider to refresh the list
        // This will be handled by the parent widget's refresh mechanism
      }
    });
  }

  /// Handle menu item actions
  void _handleMenuItemAction(BuildContext context, String action, Product item) {
    switch (action) {
      case 'edit':
        debugPrint('🍽️ [CATEGORY-CARD] Navigating to edit menu item: ${item.name}');
        debugPrint('🍽️ [CATEGORY-CARD] Menu item ID: ${item.id}');

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => MenuItemFormScreen(
              menuItemId: item.id, // Pass item ID for edit mode
            ),
          ),
        ).then((result) {
          debugPrint('🍽️ [CATEGORY-CARD] Returned from edit menu item screen with result: $result');
          // Refresh the menu items if changes were made
          if (result == true) {
            // This will be handled by the parent widget's refresh mechanism
          }
        });
        break;
      case 'move':
        // TODO: Show move to category dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Move ${item.name} - Coming soon')),
        );
        break;
      case 'delete':
        // TODO: Show delete confirmation dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Delete ${item.name} - Coming soon')),
        );
        break;
    }
  }
}

// ==================== STATE WIDGETS ====================

/// Empty state for categories
class CategoryEmptyState extends StatelessWidget {
  const CategoryEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.category_outlined,
                size: 40,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Categories Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first category to organize your menu items',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading state for categories
class CategoryLoadingState extends StatelessWidget {
  const CategoryLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: CircularProgressIndicator(),
      ),
    );
  }
}

/// Error state for categories
class CategoryErrorState extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;

  const CategoryErrorState({
    super.key,
    required this.error,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading Categories',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
