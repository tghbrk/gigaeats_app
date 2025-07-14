import 'package:flutter/foundation.dart';

import '../models/menu_item.dart';
import 'base_menu_repository.dart';

/// Repository for managing menu categories with Supabase integration
class MenuCategoryRepository extends BaseMenuRepository {

  MenuCategoryRepository({super.client});

  /// Get all categories for a vendor
  Future<List<MenuCategory>> getVendorCategories(String vendorId) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Getting categories for vendor: $vendorId');

      // First, let's see ALL categories in the table for debugging
      final allResponse = await supabase
          .from('menu_categories')
          .select('*');
      debugPrint('🏷️ [CATEGORY-REPO] Total categories in database: ${allResponse.length}');
      if (allResponse.isNotEmpty) {
        debugPrint('🏷️ [CATEGORY-REPO] Sample category: ${allResponse.first}');
      }

      final response = await supabase
          .from('menu_categories')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('sort_order');

      debugPrint('🏷️ [CATEGORY-REPO] Found ${response.length} categories for vendor $vendorId');

      // Debug: Print the first category response if any exist
      if (response.isNotEmpty) {
        debugPrint('🏷️ [CATEGORY-REPO] First category raw data: ${response.first}');
        debugPrint('🏷️ [CATEGORY-REPO] First category keys: ${response.first.keys.toList()}');
      }

      final categories = response.map((json) => MenuCategory.fromJson(json)).toList();

      // Debug: Print category order after parsing
      for (int i = 0; i < categories.length; i++) {
        debugPrint('🏷️ [CATEGORY-REPO] Category $i: ${categories[i].name} (ID: ${categories[i].id}, sort_order: ${categories[i].sortOrder})');
      }

      return categories;
    });
  }

  /// Create a new category
  Future<MenuCategory> createCategory({
    required String vendorId,
    required String name,
    String? description,
    String? imageUrl,
    int? sortOrder,
  }) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Creating category: $name for vendor: $vendorId');

      // Validate input parameters
      if (vendorId.trim().isEmpty) {
        throw Exception('Vendor ID cannot be empty');
      }
      if (name.trim().isEmpty) {
        throw Exception('Category name cannot be empty');
      }
      if (name.trim().length > 50) {
        throw Exception('Category name cannot exceed 50 characters');
      }
      if (description != null && description.length > 200) {
        throw Exception('Category description cannot exceed 200 characters');
      }

      // Check if category name already exists for this vendor
      final existingCategory = await categoryNameExists(vendorId, name.trim());
      if (existingCategory) {
        throw Exception('A category with this name already exists');
      }

      // Get current max sort order if not provided
      final currentSortOrder = sortOrder ?? await _getNextSortOrder(vendorId);

      final categoryData = {
        'vendor_id': vendorId,
        'name': name.trim(),
        'description': description?.trim(),
        'image_url': imageUrl?.trim(),
        'sort_order': currentSortOrder,
        'is_active': true,
      };

      final response = await supabase
          .from('menu_categories')
          .insert(categoryData)
          .select()
          .single();

      debugPrint('🏷️ [CATEGORY-REPO] Category created successfully: ${response['id']}');
      debugPrint('🏷️ [CATEGORY-REPO] Full response data: $response');
      debugPrint('🏷️ [CATEGORY-REPO] Response keys: ${response.keys.toList()}');

      // Immediately verify the category exists in the database
      final verifyResponse = await supabase
          .from('menu_categories')
          .select('*')
          .eq('id', response['id']);
      debugPrint('🏷️ [CATEGORY-REPO] Verification query result: ${verifyResponse.length} categories found');
      if (verifyResponse.isNotEmpty) {
        debugPrint('🏷️ [CATEGORY-REPO] Verified category exists: ${verifyResponse.first}');
      }

      return MenuCategory.fromJson(response);
    });
  }

  /// Update an existing category
  Future<MenuCategory> updateCategory({
    required String categoryId,
    String? name,
    String? description,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Updating category: $categoryId');

      // Validate input parameters
      if (categoryId.trim().isEmpty) {
        throw Exception('Category ID cannot be empty');
      }
      if (name != null && name.trim().isEmpty) {
        throw Exception('Category name cannot be empty');
      }
      if (name != null && name.trim().length > 50) {
        throw Exception('Category name cannot exceed 50 characters');
      }
      if (description != null && description.length > 200) {
        throw Exception('Category description cannot exceed 200 characters');
      }

      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name.trim();
      if (description != null) updateData['description'] = description.trim();
      if (imageUrl != null) updateData['image_url'] = imageUrl.trim();
      if (sortOrder != null) updateData['sort_order'] = sortOrder;
      if (isActive != null) updateData['is_active'] = isActive;

      if (updateData.isEmpty) {
        throw Exception('No fields to update');
      }

      // If updating name, check for conflicts
      if (name != null) {
        // Get current category to check vendor_id
        final currentCategory = await getCategoryById(categoryId);
        if (currentCategory == null) {
          throw Exception('Category not found');
        }

        final nameExists = await categoryNameExists(
          currentCategory.vendorId,
          name.trim(),
          excludeCategoryId: categoryId,
        );
        if (nameExists) {
          throw Exception('A category with this name already exists');
        }
      }

      final response = await supabase
          .from('menu_categories')
          .update(updateData)
          .eq('id', categoryId)
          .select()
          .single();

      debugPrint('🏷️ [CATEGORY-REPO] Category updated successfully');

      return MenuCategory.fromJson(response);
    });
  }

  /// Delete a category (soft delete by setting is_active to false)
  Future<void> deleteCategory(String categoryId) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Deleting category: $categoryId');

      // Validate input parameters
      if (categoryId.trim().isEmpty) {
        throw Exception('Category ID cannot be empty');
      }

      // Check if category exists
      final category = await getCategoryById(categoryId);
      if (category == null) {
        throw Exception('Category not found');
      }

      // Check if category has menu items
      final hasMenuItems = await _categoryHasMenuItems(categoryId);
      if (hasMenuItems) {
        throw Exception('Cannot delete category that contains menu items. Please move or delete the menu items first.');
      }

      final response = await supabase
          .from('menu_categories')
          .update({'is_active': false})
          .eq('id', categoryId)
          .select();

      if (response.isEmpty) {
        throw Exception('Failed to delete category - category may not exist or you may not have permission');
      }

      debugPrint('🏷️ [CATEGORY-REPO] Category deleted successfully');
    });
  }

  /// Reorder categories by updating sort_order
  Future<void> reorderCategories(String vendorId, List<String> categoryIds) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Reordering categories for vendor: $vendorId');
      debugPrint('🏷️ [CATEGORY-REPO] New order: ${categoryIds.join(', ')}');

      // Validate input parameters
      if (vendorId.trim().isEmpty) {
        throw Exception('Vendor ID cannot be empty');
      }
      if (categoryIds.isEmpty) {
        throw Exception('Category IDs list cannot be empty');
      }

      // Verify all categories belong to the vendor
      final existingCategories = await getVendorCategories(vendorId);
      final existingCategoryIds = existingCategories.map((c) => c.id).toSet();

      for (final categoryId in categoryIds) {
        if (!existingCategoryIds.contains(categoryId)) {
          throw Exception('Category $categoryId does not belong to vendor $vendorId');
        }
      }

      // Check if all vendor categories are included in the reorder
      if (categoryIds.length != existingCategories.length) {
        throw Exception('Reorder must include all categories (expected ${existingCategories.length}, got ${categoryIds.length})');
      }

      // Update sort order for each category sequentially to ensure consistency
      for (int i = 0; i < categoryIds.length; i++) {
        debugPrint('🏷️ [CATEGORY-REPO] Updating category ${categoryIds[i]} to sort_order: $i');

        final response = await supabase
            .from('menu_categories')
            .update({'sort_order': i})
            .eq('id', categoryIds[i])
            .eq('vendor_id', vendorId); // Ensure vendor ownership

        debugPrint('🏷️ [CATEGORY-REPO] Update response for ${categoryIds[i]}: $response');
      }

      debugPrint('🏷️ [CATEGORY-REPO] Categories reordered successfully');
    });
  }

  /// Get category by ID
  Future<MenuCategory?> getCategoryById(String categoryId) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Getting category by ID: $categoryId');
      
      final response = await supabase
          .from('menu_categories')
          .select('*')
          .eq('id', categoryId)
          .eq('is_active', true)
          .maybeSingle();

      if (response == null) {
        debugPrint('🏷️ [CATEGORY-REPO] Category not found');
        return null;
      }
      
      return MenuCategory.fromJson(response);
    });
  }

  /// Check if a category name already exists for a vendor
  Future<bool> categoryNameExists(String vendorId, String name, {String? excludeCategoryId}) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Checking if category name exists: $name');
      
      var query = supabase
          .from('menu_categories')
          .select('id')
          .eq('vendor_id', vendorId)
          .eq('name', name)
          .eq('is_active', true);
      
      if (excludeCategoryId != null) {
        query = query.neq('id', excludeCategoryId);
      }
      
      final response = await query;
      
      return response.isNotEmpty;
    });
  }

  /// Get the next sort order for a new category
  Future<int> _getNextSortOrder(String vendorId) async {
    final response = await supabase
        .from('menu_categories')
        .select('sort_order')
        .eq('vendor_id', vendorId)
        .eq('is_active', true)
        .order('sort_order', ascending: false)
        .limit(1);

    if (response.isEmpty) {
      return 0;
    }

    return (response.first['sort_order'] as int) + 1;
  }

  /// Check if a category has menu items
  Future<bool> _categoryHasMenuItems(String categoryId) async {
    // Get category details first to get the name
    final category = await getCategoryById(categoryId);
    if (category == null) return false;

    // Check if any menu items use this category name
    final response = await supabase
        .from('menu_items')
        .select('id')
        .eq('category', category.name)
        .eq('vendor_id', category.vendorId)
        .limit(1);

    return response.isNotEmpty;
  }

  /// Get categories with item counts
  Future<List<Map<String, dynamic>>> getCategoriesWithItemCounts(String vendorId) async {
    return executeQuery(() async {
      debugPrint('🏷️ [CATEGORY-REPO] Getting categories with item counts for vendor: $vendorId');
      
      // Get all categories
      final categories = await getVendorCategories(vendorId);
      
      // Get item counts for each category
      final categoriesWithCounts = <Map<String, dynamic>>[];
      
      for (final category in categories) {
        final itemCount = await _getMenuItemCountForCategory(vendorId, category.name);
        categoriesWithCounts.add({
          'category': category,
          'itemCount': itemCount,
        });
      }
      
      return categoriesWithCounts;
    });
  }

  /// Get menu item count for a specific category
  Future<int> _getMenuItemCountForCategory(String vendorId, String categoryName) async {
    final response = await supabase
        .from('menu_items')
        .select('id')
        .eq('vendor_id', vendorId)
        .eq('category', categoryName)
        .eq('is_available', true);

    return response.length;
  }
}
