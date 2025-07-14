import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/menu_item.dart';
import '../../providers/menu_category_providers.dart';
import 'category_management_widgets.dart';
import 'category_dialogs.dart';

/// Complete Material Design 3 category management interface
class CategoryManagementInterface extends ConsumerStatefulWidget {
  final String vendorId;
  final VoidCallback? onAddCategory;

  const CategoryManagementInterface({
    super.key,
    required this.vendorId,
    this.onAddCategory,
  });

  @override
  ConsumerState<CategoryManagementInterface> createState() => _CategoryManagementInterfaceState();
}

class _CategoryManagementInterfaceState extends ConsumerState<CategoryManagementInterface> {
  @override
  void initState() {
    super.initState();
    // Clear any previous messages when entering the screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(categoryManagementProvider.notifier).clearMessages();
    });
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoryManagement = ref.watch(categoryManagementProvider);

    // Listen for reordering success messages
    ref.listen<CategoryManagementState>(categoryManagementProvider, (previous, next) {
      debugPrint('🏷️ [CATEGORY-INTERFACE] State changed - isReordering: ${next.isReordering}, success: ${next.successMessage}, error: ${next.errorMessage}');

      if (previous?.successMessage != next.successMessage &&
          next.successMessage != null &&
          next.successMessage!.contains('reordered')) {
        debugPrint('🏷️ [CATEGORY-INTERFACE] Showing reorder success message');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(next.successMessage!),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }

      if (previous?.errorMessage != next.errorMessage &&
          next.errorMessage != null) {
        debugPrint('🏷️ [CATEGORY-INTERFACE] Showing reorder error message: ${next.errorMessage}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text(next.errorMessage!)),
              ],
            ),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    });

    return Column(
      children: [
        // Header Section
        _buildHeader(context, theme),

        // Success/Error Messages
        if (categoryManagement.successMessage != null || categoryManagement.errorMessage != null)
          _buildMessageBanner(context, theme, categoryManagement),

        // Content
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vendorMenuCategoriesProvider(widget.vendorId));
              ref.invalidate(vendorCategoriesWithCountsProvider(widget.vendorId));
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Instructions Card
                    _buildInstructionsCard(context, theme),

                    const SizedBox(height: 24),

                    // Categories List
                    CategoryListView(
                      vendorId: widget.vendorId,
                      onCategoryTap: _handleCategoryTap,
                      onCategoryEdit: _handleCategoryEdit,
                      onCategoryDelete: _handleCategoryDelete,
                      enableReordering: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.category,
                  color: colorScheme.primary,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Category Management',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Organize your menu items into categories for better customer experience',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBanner(BuildContext context, ThemeData theme, CategoryManagementState state) {
    final colorScheme = theme.colorScheme;
    
    if (state.successMessage != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.check_circle_outline,
              color: colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.successMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(categoryManagementProvider.notifier).clearSuccess();
              },
              icon: Icon(
                Icons.close,
                color: colorScheme.onPrimaryContainer,
                size: 18,
              ),
            ),
          ],
        ),
      );
    }
    
    if (state.errorMessage != null) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: colorScheme.onErrorContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                state.errorMessage!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(
              onPressed: () {
                ref.read(categoryManagementProvider.notifier).clearError();
              },
              icon: Icon(
                Icons.close,
                color: colorScheme.onErrorContainer,
                size: 18,
              ),
            ),
          ],
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  Widget _buildInstructionsCard(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  color: colorScheme.primary,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Quick Tips',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTipItem(
              context,
              '• Tap categories to expand and view menu items',
              Icons.expand_more,
            ),
            _buildTipItem(
              context,
              '• Add, edit, and manage menu items within each category',
              Icons.restaurant_menu,
            ),
            _buildTipItem(
              context,
              '• Drag and drop categories to reorder them',
              Icons.drag_handle,
            ),
            _buildTipItem(
              context,
              '• Categories help customers find menu items faster',
              Icons.search,
            ),
            _buildTipItem(
              context,
              '• Categories with menu items cannot be deleted',
              Icons.warning_amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTipItem(BuildContext context, String text, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 16,
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleCategoryTap(MenuCategory category) {
    debugPrint('🏷️ [CATEGORY-INTERFACE] Category tapped: ${category.name}');
    // Toggle expansion to show/hide menu items
    ref.read(categoryManagementProvider.notifier).toggleCategoryExpansion(category.id);
  }

  void _handleCategoryEdit(MenuCategory category) {
    debugPrint('🏷️ [CATEGORY-INTERFACE] Editing category: ${category.name}');
    showDialog(
      context: context,
      builder: (context) => CategoryFormDialog(
        vendorId: widget.vendorId,
        category: category,
        onCategoryUpdated: (updatedCategory) {
          debugPrint('🏷️ [CATEGORY-INTERFACE] Category updated: ${updatedCategory.name}');
        },
      ),
    );
  }

  Future<void> _handleCategoryDelete(MenuCategory category) async {
    debugPrint('🏷️ [CATEGORY-INTERFACE] Deleting category: ${category.name}');
    
    // Get item count for this category
    final categoriesWithCounts = await ref.read(vendorCategoriesWithCountsProvider(widget.vendorId).future);
    final categoryData = categoriesWithCounts.firstWhere(
      (item) => (item['category'] as MenuCategory).id == category.id,
      orElse: () => {'category': category, 'itemCount': 0},
    );
    final itemCount = categoryData['itemCount'] as int;
    
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => CategoryDeleteDialog(
          category: category,
          itemCount: itemCount,
          vendorId: widget.vendorId,
          onCategoryDeleted: () {
            debugPrint('🏷️ [CATEGORY-INTERFACE] Category deleted: ${category.name}');
          },
        ),
      );
    }
  }


}
