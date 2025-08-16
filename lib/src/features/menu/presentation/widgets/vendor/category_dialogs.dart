import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/menu_item.dart';
import '../../providers/menu_category_providers.dart';

// ==================== ADD/EDIT CATEGORY DIALOG ====================

/// Material Design 3 dialog for adding or editing categories
class CategoryFormDialog extends ConsumerStatefulWidget {
  final String vendorId;
  final MenuCategory? category; // null for add, non-null for edit
  final Function(MenuCategory)? onCategoryCreated;
  final Function(MenuCategory)? onCategoryUpdated;

  const CategoryFormDialog({
    super.key,
    required this.vendorId,
    this.category,
    this.onCategoryCreated,
    this.onCategoryUpdated,
  });

  @override
  ConsumerState<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends ConsumerState<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();

  bool get isEditing => widget.category != null;

  @override
  void initState() {
    super.initState();
    if (isEditing) {
      _nameController.text = widget.category!.name;
      _descriptionController.text = widget.category!.description ?? '';
      _imageUrlController.text = widget.category!.imageUrl ?? '';
      
      // Load category into form provider
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(categoryFormProvider.notifier).loadCategory(widget.category!);
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryManagement = ref.watch(categoryManagementProvider);
    final formState = ref.watch(categoryFormProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isEditing ? Icons.edit : Icons.add,
                    color: colorScheme.onPrimaryContainer,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Category' : 'Add New Category',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Form Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Category Name *',
                          hintText: 'e.g., Appetizers, Main Courses',
                          prefixIcon: const Icon(Icons.category),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          errorText: formState.errors['name'],
                        ),
                        textCapitalization: TextCapitalization.words,
                        onChanged: (value) {
                          ref.read(categoryFormProvider.notifier).updateName(value);
                        },
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Category name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Category name must be at least 2 characters';
                          }
                          if (value.trim().length > 50) {
                            return 'Category name must be less than 50 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Description
                      TextFormField(
                        controller: _descriptionController,
                        decoration: InputDecoration(
                          labelText: 'Description (Optional)',
                          hintText: 'Brief description of this category',
                          prefixIcon: const Icon(Icons.description),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          errorText: formState.errors['description'],
                        ),
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        onChanged: (value) {
                          ref.read(categoryFormProvider.notifier).updateDescription(value);
                        },
                        validator: (value) {
                          if (value != null && value.length > 200) {
                            return 'Description must be less than 200 characters';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // Image URL (Optional)
                      TextFormField(
                        controller: _imageUrlController,
                        decoration: InputDecoration(
                          labelText: 'Image URL (Optional)',
                          hintText: 'https://example.com/image.jpg',
                          prefixIcon: const Icon(Icons.image),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                        ),
                        keyboardType: TextInputType.url,
                        onChanged: (value) {
                          ref.read(categoryFormProvider.notifier).updateImageUrl(value.isEmpty ? null : value);
                        },
                      ),

                      const SizedBox(height: 24),

                      // Preview Section
                      if (_nameController.text.isNotEmpty) ...[
                        Text(
                          'Preview',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildPreviewCard(context, theme),
                      ],
                    ],
                  ),
                ),
              ),
            ),

            // Error Message
            if (categoryManagement.errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 24),
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
                        categoryManagement.errorMessage!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Container(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: categoryManagement.hasAnyOperation ? null : () {
                      Navigator.of(context).pop();
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(
                    onPressed: (formState.isValid && !categoryManagement.hasAnyOperation) 
                        ? _handleSubmit 
                        : null,
                    child: categoryManagement.isCreating || categoryManagement.isUpdating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Update' : 'Create'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewCard(BuildContext context, ThemeData theme) {
    final colorScheme = theme.colorScheme;
    
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: _imageUrlController.text.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        _imageUrlController.text,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.category,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                    )
                  : Icon(
                      Icons.category,
                      color: colorScheme.onPrimaryContainer,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nameController.text,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (_descriptionController.text.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      _descriptionController.text,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) {
      debugPrint('🏷️ [CATEGORY-DIALOG] Form validation failed');
      return;
    }

    final notifier = ref.read(categoryManagementProvider.notifier);
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();
    final imageUrl = _imageUrlController.text.trim();

    // Additional validation
    if (name.isEmpty) {
      debugPrint('🏷️ [CATEGORY-DIALOG] Category name is empty');
      return;
    }

    try {
      if (isEditing) {
        debugPrint('🏷️ [CATEGORY-DIALOG] Updating category: ${widget.category!.id}');
        final updatedCategory = await notifier.updateCategory(
          vendorId: widget.vendorId,
          categoryId: widget.category!.id,
          name: name,
          description: description.isEmpty ? null : description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        );

        if (updatedCategory != null) {
          debugPrint('🏷️ [CATEGORY-DIALOG] Category updated successfully: ${updatedCategory.name}');
          widget.onCategoryUpdated?.call(updatedCategory);
          if (mounted) {
            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category "${updatedCategory.name}" updated successfully'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          debugPrint('🏷️ [CATEGORY-DIALOG] Category update failed');
        }
      } else {
        debugPrint('🏷️ [CATEGORY-DIALOG] Creating new category: $name');
        final newCategory = await notifier.createCategory(
          vendorId: widget.vendorId,
          name: name,
          description: description.isEmpty ? null : description,
          imageUrl: imageUrl.isEmpty ? null : imageUrl,
        );

        if (newCategory != null) {
          debugPrint('🏷️ [CATEGORY-DIALOG] Category created successfully: ${newCategory.name}');
          widget.onCategoryCreated?.call(newCategory);
          if (mounted) {
            // Show success feedback
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Category "${newCategory.name}" created successfully'),
                backgroundColor: Theme.of(context).colorScheme.primary,
              ),
            );
            Navigator.of(context).pop();
          }
        } else {
          debugPrint('🏷️ [CATEGORY-DIALOG] Category creation failed');
        }
      }
    } catch (e) {
      debugPrint('🏷️ [CATEGORY-DIALOG] Error submitting form: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ==================== DELETE CONFIRMATION DIALOG ====================

/// Material Design 3 confirmation dialog for deleting categories
class CategoryDeleteDialog extends ConsumerWidget {
  final MenuCategory category;
  final int itemCount;
  final String vendorId;
  final Function()? onCategoryDeleted;

  const CategoryDeleteDialog({
    super.key,
    required this.category,
    required this.itemCount,
    required this.vendorId,
    this.onCategoryDeleted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoryManagement = ref.watch(categoryManagementProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.error,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Text('Delete Category'),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Are you sure you want to delete "${category.name}"?',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),

          if (itemCount > 0) ...[
            Container(
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
                      'This category contains $itemCount menu ${itemCount == 1 ? 'item' : 'items'}. Please move or delete the menu items first.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This action cannot be undone.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (categoryManagement.errorMessage != null) ...[
            const SizedBox(height: 16),
            Container(
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
                      categoryManagement.errorMessage!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: categoryManagement.isDeleting ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (itemCount == 0 && !categoryManagement.isDeleting)
              ? () => _handleDelete(context, ref)
              : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: categoryManagement.isDeleting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete'),
        ),
      ],
    );
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(categoryManagementProvider.notifier);

    debugPrint('🏷️ [DELETE-DIALOG] Attempting to delete category: ${category.name}');

    try {
      final success = await notifier.deleteCategory(
        vendorId: vendorId,
        categoryId: category.id,
      );

      if (success) {
        debugPrint('🏷️ [DELETE-DIALOG] Category deleted successfully: ${category.name}');
        onCategoryDeleted?.call();
        if (context.mounted) {
          // Show success feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Category "${category.name}" deleted successfully'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
          Navigator.of(context).pop();
        }
      } else {
        debugPrint('🏷️ [DELETE-DIALOG] Category deletion failed: ${category.name}');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Failed to delete category'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('🏷️ [DELETE-DIALOG] Error deleting category: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting category: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ==================== CATEGORY DROPDOWN SELECTOR ====================

/// Material Design 3 dropdown for selecting categories in menu item forms
class CategoryDropdownSelector extends ConsumerWidget {
  final String vendorId;
  final String? selectedCategoryId;
  final Function(String?)? onCategorySelected;
  final String? hintText;
  final bool enabled;
  final bool allowEmpty;

  const CategoryDropdownSelector({
    super.key,
    required this.vendorId,
    this.selectedCategoryId,
    this.onCategorySelected,
    this.hintText,
    this.enabled = true,
    this.allowEmpty = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final categoriesAsync = ref.watch(vendorMenuCategoriesProvider(vendorId));

    return categoriesAsync.when(
      data: (categories) {
        // Find selected category
        MenuCategory? selectedCategory;
        if (selectedCategoryId != null) {
          try {
            selectedCategory = categories.firstWhere((c) => c.id == selectedCategoryId);
          } catch (e) {
            // Category not found, reset selection
            WidgetsBinding.instance.addPostFrameCallback((_) {
              onCategorySelected?.call(null);
            });
          }
        }

        return DropdownButtonFormField<String>(
          initialValue: selectedCategory?.id,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Category',
            hintText: hintText ?? 'Select a category',
            prefixIcon: const Icon(Icons.category),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            filled: true,
            fillColor: colorScheme.surfaceContainerHighest,
          ),
          items: [
            if (allowEmpty)
              const DropdownMenuItem<String>(
                value: null,
                child: Text('No Category'),
              ),
            ...categories.map((category) {
              return DropdownMenuItem<String>(
                value: category.id,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: category.imageUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Image.network(
                                category.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Icon(
                                  Icons.category,
                                  size: 16,
                                  color: colorScheme.onPrimaryContainer,
                                ),
                              ),
                            )
                          : Icon(
                              Icons.category,
                              size: 16,
                              color: colorScheme.onPrimaryContainer,
                            ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(
                        category.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          onChanged: enabled ? onCategorySelected : null,
          validator: (value) {
            if (!allowEmpty && (value == null || value.isEmpty)) {
              return 'Please select a category';
            }
            return null;
          },
        );
      },
      loading: () => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Category',
          hintText: 'Loading categories...',
          prefixIcon: const Icon(Icons.category),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
        ),
        items: const [],
        onChanged: null,
      ),
      error: (error, stack) => DropdownButtonFormField<String>(
        decoration: InputDecoration(
          labelText: 'Category',
          hintText: 'Error loading categories',
          prefixIcon: const Icon(Icons.error),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.error),
          ),
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest,
        ),
        items: const [],
        onChanged: null,
      ),
    );
  }
}
