import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/menu_item.dart';
import '../../data/models/product.dart';
import '../../data/repositories/menu_category_repository.dart';

import '../../../../presentation/providers/repository_providers.dart';

// ==================== BASIC PROVIDERS ====================

/// Provider for vendor menu categories
final vendorMenuCategoriesProvider = FutureProvider.family<List<MenuCategory>, String>((ref, vendorId) async {
  debugPrint('🏷️ [CATEGORY-PROVIDER] Loading categories for vendor: $vendorId');
  final repository = ref.read(menuCategoryRepositoryProvider);
  try {
    final categories = await repository.getVendorCategories(vendorId);
    debugPrint('🏷️ [CATEGORY-PROVIDER] Successfully loaded ${categories.length} categories');
    return categories;
  } catch (e) {
    debugPrint('🏷️ [CATEGORY-PROVIDER] Error loading categories: $e');
    rethrow;
  }
});

/// Provider for categories with item counts
final vendorCategoriesWithCountsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, vendorId) async {
  debugPrint('🏷️ [CATEGORY-PROVIDER] Loading categories with counts for vendor: $vendorId');
  final repository = ref.read(menuCategoryRepositoryProvider);
  try {
    final categoriesWithCounts = await repository.getCategoriesWithItemCounts(vendorId);
    debugPrint('🏷️ [CATEGORY-PROVIDER] Successfully loaded categories with counts');
    return categoriesWithCounts;
  } catch (e) {
    debugPrint('🏷️ [CATEGORY-PROVIDER] Error loading categories with counts: $e');
    rethrow;
  }
});

/// Provider for single category by ID
final categoryByIdProvider = FutureProvider.family<MenuCategory?, String>((ref, categoryId) async {
  debugPrint('🏷️ [CATEGORY-PROVIDER] Loading category by ID: $categoryId');
  final repository = ref.read(menuCategoryRepositoryProvider);
  try {
    final category = await repository.getCategoryById(categoryId);
    debugPrint('🏷️ [CATEGORY-PROVIDER] Category loaded: ${category?.name ?? 'not found'}');
    return category;
  } catch (e) {
    debugPrint('🏷️ [CATEGORY-PROVIDER] Error loading category: $e');
    rethrow;
  }
});

/// Provider for menu items by category
final menuItemsByCategoryProvider = FutureProvider.family<List<Product>, ({String vendorId, String categoryId})>((ref, params) async {
  debugPrint('🍽️ [MENU-ITEMS-PROVIDER] Loading menu items for vendor: ${params.vendorId}, category: ${params.categoryId}');
  final repository = ref.read(menuItemRepositoryProvider);
  try {
    final items = await repository.getMenuItems(params.vendorId, category: params.categoryId);
    debugPrint('🍽️ [MENU-ITEMS-PROVIDER] Successfully loaded ${items.length} menu items');
    return items;
  } catch (e) {
    debugPrint('🍽️ [MENU-ITEMS-PROVIDER] Error loading menu items: $e');
    rethrow;
  }
});

// ==================== STATE MANAGEMENT ====================

/// State class for category management operations
class CategoryManagementState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;
  final bool isCreating;
  final bool isUpdating;
  final bool isDeleting;
  final bool isReordering;
  final Set<String> expandedCategories; // Track which categories are expanded

  const CategoryManagementState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
    this.isCreating = false,
    this.isUpdating = false,
    this.isDeleting = false,
    this.isReordering = false,
    this.expandedCategories = const {},
  });

  CategoryManagementState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool? isCreating,
    bool? isUpdating,
    bool? isDeleting,
    bool? isReordering,
    Set<String>? expandedCategories,
  }) {
    return CategoryManagementState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
      isCreating: isCreating ?? this.isCreating,
      isUpdating: isUpdating ?? this.isUpdating,
      isDeleting: isDeleting ?? this.isDeleting,
      isReordering: isReordering ?? this.isReordering,
      expandedCategories: expandedCategories ?? this.expandedCategories,
    );
  }

  bool get hasAnyOperation => isCreating || isUpdating || isDeleting || isReordering;
}

/// State notifier for category management operations
class CategoryManagementNotifier extends StateNotifier<CategoryManagementState> {
  final MenuCategoryRepository _repository;
  final Ref _ref;

  CategoryManagementNotifier(this._repository, this._ref) : super(const CategoryManagementState());

  /// Create a new category
  Future<MenuCategory?> createCategory({
    required String vendorId,
    required String name,
    String? description,
    String? imageUrl,
    int? sortOrder,
  }) async {
    debugPrint('🏷️ [CATEGORY-NOTIFIER] Creating category: $name');
    
    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      // Check if category name already exists
      final nameExists = await _repository.categoryNameExists(vendorId, name);
      if (nameExists) {
        throw Exception('A category with this name already exists');
      }

      final category = await _repository.createCategory(
        vendorId: vendorId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
      );

      state = state.copyWith(
        isCreating: false,
        successMessage: 'Category "$name" created successfully',
      );

      // Refresh the categories list
      _ref.invalidate(vendorMenuCategoriesProvider(vendorId));
      _ref.invalidate(vendorCategoriesWithCountsProvider(vendorId));

      debugPrint('🏷️ [CATEGORY-NOTIFIER] Category created successfully');
      return category;
    } catch (e) {
      debugPrint('🏷️ [CATEGORY-NOTIFIER] Error creating category: $e');
      state = state.copyWith(
        isCreating: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Update an existing category
  Future<MenuCategory?> updateCategory({
    required String vendorId,
    required String categoryId,
    String? name,
    String? description,
    String? imageUrl,
    int? sortOrder,
    bool? isActive,
  }) async {
    debugPrint('🏷️ [CATEGORY-NOTIFIER] Updating category: $categoryId');
    
    state = state.copyWith(
      isUpdating: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      // Check if new name already exists (excluding current category)
      if (name != null) {
        final nameExists = await _repository.categoryNameExists(vendorId, name, excludeCategoryId: categoryId);
        if (nameExists) {
          throw Exception('A category with this name already exists');
        }
      }

      final category = await _repository.updateCategory(
        categoryId: categoryId,
        name: name,
        description: description,
        imageUrl: imageUrl,
        sortOrder: sortOrder,
        isActive: isActive,
      );

      state = state.copyWith(
        isUpdating: false,
        successMessage: 'Category updated successfully',
      );

      // Refresh the categories list
      _ref.invalidate(vendorMenuCategoriesProvider(vendorId));
      _ref.invalidate(vendorCategoriesWithCountsProvider(vendorId));
      _ref.invalidate(categoryByIdProvider(categoryId));

      debugPrint('🏷️ [CATEGORY-NOTIFIER] Category updated successfully');
      return category;
    } catch (e) {
      debugPrint('🏷️ [CATEGORY-NOTIFIER] Error updating category: $e');
      state = state.copyWith(
        isUpdating: false,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Delete a category
  Future<bool> deleteCategory({
    required String vendorId,
    required String categoryId,
  }) async {
    debugPrint('🏷️ [CATEGORY-NOTIFIER] Deleting category: $categoryId');
    
    state = state.copyWith(
      isDeleting: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _repository.deleteCategory(categoryId);

      state = state.copyWith(
        isDeleting: false,
        successMessage: 'Category deleted successfully',
      );

      // Refresh the categories list
      _ref.invalidate(vendorMenuCategoriesProvider(vendorId));
      _ref.invalidate(vendorCategoriesWithCountsProvider(vendorId));

      debugPrint('🏷️ [CATEGORY-NOTIFIER] Category deleted successfully');
      return true;
    } catch (e) {
      debugPrint('🏷️ [CATEGORY-NOTIFIER] Error deleting category: $e');
      state = state.copyWith(
        isDeleting: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Reorder categories
  Future<bool> reorderCategories({
    required String vendorId,
    required List<String> categoryIds,
  }) async {
    debugPrint('🏷️ [CATEGORY-NOTIFIER] Reordering categories for vendor: $vendorId');
    
    state = state.copyWith(
      isReordering: true,
      errorMessage: null,
      successMessage: null,
    );

    try {
      await _repository.reorderCategories(vendorId, categoryIds);

      // Add a small delay to ensure database consistency
      await Future.delayed(const Duration(milliseconds: 100));

      state = state.copyWith(
        isReordering: false,
        successMessage: 'Categories reordered successfully',
      );

      // Refresh the categories list with aggressive cache clearing
      _ref.invalidate(vendorMenuCategoriesProvider(vendorId));
      _ref.invalidate(vendorCategoriesWithCountsProvider(vendorId));

      debugPrint('🏷️ [CATEGORY-NOTIFIER] Categories reordered successfully');
      return true;
    } catch (e) {
      debugPrint('🏷️ [CATEGORY-NOTIFIER] Error reordering categories: $e');
      state = state.copyWith(
        isReordering: false,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Clear success message
  void clearSuccess() {
    state = state.copyWith(successMessage: null);
  }

  /// Clear all messages
  void clearMessages() {
    state = state.copyWith(
      errorMessage: null,
      successMessage: null,
    );
  }

  /// Toggle category expansion for menu item management
  void toggleCategoryExpansion(String categoryId) {
    debugPrint('🏷️ [CATEGORY-NOTIFIER] Toggling expansion for category: $categoryId');
    final expandedCategories = Set<String>.from(state.expandedCategories);

    if (expandedCategories.contains(categoryId)) {
      expandedCategories.remove(categoryId);
      debugPrint('🏷️ [CATEGORY-NOTIFIER] Collapsed category: $categoryId');
    } else {
      expandedCategories.add(categoryId);
      debugPrint('🏷️ [CATEGORY-NOTIFIER] Expanded category: $categoryId');
    }

    state = state.copyWith(expandedCategories: expandedCategories);
  }

  /// Check if a category is expanded
  bool isCategoryExpanded(String categoryId) {
    return state.expandedCategories.contains(categoryId);
  }
}

/// Provider for category management state notifier
final categoryManagementProvider = StateNotifierProvider<CategoryManagementNotifier, CategoryManagementState>((ref) {
  final repository = ref.watch(menuCategoryRepositoryProvider);
  return CategoryManagementNotifier(repository, ref);
});

// ==================== UTILITY PROVIDERS ====================

/// Provider for checking if a category name exists
final categoryNameExistsProvider = FutureProvider.family<bool, Map<String, String>>((ref, params) async {
  final repository = ref.read(menuCategoryRepositoryProvider);
  final vendorId = params['vendorId']!;
  final name = params['name']!;
  final excludeCategoryId = params['excludeCategoryId'];
  
  return await repository.categoryNameExists(vendorId, name, excludeCategoryId: excludeCategoryId);
});

/// Provider for category loading state
final categoryLoadingProvider = StateProvider<bool>((ref) => false);

/// Provider for category error state
final categoryErrorProvider = StateProvider<String?>((ref) => null);

// ==================== FORM STATE PROVIDERS ====================

/// State class for category form
class CategoryFormState {
  final String name;
  final String description;
  final String? imageUrl;
  final bool isValid;
  final Map<String, String> errors;

  const CategoryFormState({
    this.name = '',
    this.description = '',
    this.imageUrl,
    this.isValid = false,
    this.errors = const {},
  });

  CategoryFormState copyWith({
    String? name,
    String? description,
    String? imageUrl,
    bool? isValid,
    Map<String, String>? errors,
  }) {
    return CategoryFormState(
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isValid: isValid ?? this.isValid,
      errors: errors ?? this.errors,
    );
  }
}

/// State notifier for category form
class CategoryFormNotifier extends StateNotifier<CategoryFormState> {
  CategoryFormNotifier() : super(const CategoryFormState());

  void updateName(String name) {
    state = state.copyWith(name: name);
    _validateForm();
  }

  void updateDescription(String description) {
    state = state.copyWith(description: description);
    _validateForm();
  }

  void updateImageUrl(String? imageUrl) {
    state = state.copyWith(imageUrl: imageUrl);
  }

  void _validateForm() {
    final errors = <String, String>{};

    if (state.name.trim().isEmpty) {
      errors['name'] = 'Category name is required';
    } else if (state.name.trim().length < 2) {
      errors['name'] = 'Category name must be at least 2 characters';
    } else if (state.name.trim().length > 50) {
      errors['name'] = 'Category name must be less than 50 characters';
    }

    if (state.description.length > 200) {
      errors['description'] = 'Description must be less than 200 characters';
    }

    state = state.copyWith(
      errors: errors,
      isValid: errors.isEmpty && state.name.trim().isNotEmpty,
    );
  }

  void reset() {
    state = const CategoryFormState();
  }

  void loadCategory(MenuCategory category) {
    state = CategoryFormState(
      name: category.name,
      description: category.description ?? '',
      imageUrl: category.imageUrl,
    );
    _validateForm();
  }
}

/// Provider for category form state
final categoryFormProvider = StateNotifierProvider<CategoryFormNotifier, CategoryFormState>((ref) {
  return CategoryFormNotifier();
});
