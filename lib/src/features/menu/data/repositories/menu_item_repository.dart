import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
// Removed unused import: supabase_config.dart
import '../../../../core/data/repositories/base_repository.dart';
import '../../../../core/services/file_upload_service.dart';

class MenuItemRepository extends BaseRepository {
  MenuItemRepository();

  /// Helper method to check if a string is a UUID
  bool _isUuid(String value) {
    final uuidRegex = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
    return uuidRegex.hasMatch(value);
  }

  /// Get menu items for a vendor
  Future<List<Product>> getMenuItems(
    String vendorId, {
    String? category,
    bool? isAvailable,
    bool? isVegetarian,
    bool? isHalal,
    double? maxPrice,
    int limit = 50,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('MenuItemRepository: Getting menu items for vendor $vendorId');
      debugPrint('MenuItemRepository: Platform is ${kIsWeb ? "web" : "mobile"}');

      // Use authenticated client for web platform
      final queryClient = kIsWeb ? await getAuthenticatedClient() : supabase;

      var query = queryClient
          .from('menu_items')
          .select('*')
          .eq('vendor_id', vendorId);

      // Apply filters
      if (category != null) {
        // Check if category is a UUID (category ID) or a category name
        if (_isUuid(category)) {
          // If it's a UUID, we need to get the category name first
          debugPrint('MenuItemRepository: Category appears to be a UUID: $category');
          final categoryResponse = await queryClient
              .from('menu_categories')
              .select('name')
              .eq('id', category)
              .eq('is_active', true)
              .maybeSingle();

          if (categoryResponse != null) {
            final categoryName = categoryResponse['name'] as String;
            debugPrint('MenuItemRepository: Found category name: $categoryName for ID: $category');
            query = query.eq('category', categoryName);
          } else {
            debugPrint('MenuItemRepository: Category not found for ID: $category');
            // Return empty result if category doesn't exist
            return [];
          }
        } else {
          // If it's not a UUID, assume it's a category name
          debugPrint('MenuItemRepository: Using category as name: $category');
          query = query.eq('category', category);
        }
      }

      if (isAvailable != null) {
        query = query.eq('is_available', isAvailable);
      }

      if (isVegetarian == true) {
        query = query.eq('is_vegetarian', true);
      }

      if (isHalal == true) {
        query = query.eq('is_halal', true);
      }

      if (maxPrice != null) {
        query = query.lte('base_price', maxPrice);
      }

      final response = await query
          .order('is_featured', ascending: false)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('MenuItemRepository: Found ${response.length} menu items');

      // Load customizations for each menu item
      final products = <Product>[];
      for (final json in response) {
        try {
          // Handle potential null values and type conversions
          final processedJson = Map<String, dynamic>.from(json);

          // Ensure required fields have default values
          processedJson['description'] = processedJson['description'] ?? '';
          processedJson['tags'] = processedJson['tags'] ?? [];
          processedJson['allergens'] = processedJson['allergens'] ?? [];
          processedJson['gallery_images'] = processedJson['gallery_images'] ?? [];
          processedJson['currency'] = processedJson['currency'] ?? 'MYR';

          // Ensure numeric fields are properly typed
          if (processedJson['base_price'] != null) {
            processedJson['base_price'] = double.tryParse(processedJson['base_price'].toString()) ?? 0.0;
          }
          if (processedJson['bulk_price'] != null) {
            processedJson['bulk_price'] = double.tryParse(processedJson['bulk_price'].toString());
          }
          if (processedJson['rating'] != null) {
            processedJson['rating'] = double.tryParse(processedJson['rating'].toString()) ?? 0.0;
          }

          final product = Product.fromJson(processedJson);

          // Load customizations for this menu item
          final customizations = await getMenuItemCustomizations(product.id);

          // Create product with customizations
          final productWithCustomizations = product.copyWith(customizations: customizations);
          products.add(productWithCustomizations);

          debugPrint('MenuItemRepository: Loaded ${customizations.length} customizations for ${product.name}');
        } catch (e) {
          debugPrint('Error parsing menu item JSON: $e');
          debugPrint('JSON: $json');
          rethrow;
        }
      }

      debugPrint('MenuItemRepository: Returning ${products.length} products with customizations');
      return products;
    });
  }

  /// Get menu items stream for real-time updates
  Stream<List<Product>> getMenuItemsStream(String vendorId) {
    print('🚨🚨🚨 MenuItemRepository: ===== getMenuItemsStream CALLED for vendor: $vendorId =====');
    debugPrint('MenuItemRepository: ===== getMenuItemsStream CALLED for vendor: $vendorId =====');
    return executeStreamQuery(() {
      return supabase
          .from('menu_items')
          .stream(primaryKey: ['id'])
          .asyncMap((data) async {
            debugPrint('MenuItemRepository: Stream received ${data.length} raw menu items');

            final filteredData = data
                .where((item) => item['vendor_id'] == vendorId && item['is_available'] == true)
                .toList();

            debugPrint('MenuItemRepository: After filtering: ${filteredData.length} items for vendor $vendorId');

            final products = <Product>[];

            for (final json in filteredData) {
              debugPrint('MenuItemRepository: Processing menu item: ${json['name']} (ID: ${json['id']})');

              try {
                // Handle potential null values and type conversions (same as getMenuItems)
                final processedJson = Map<String, dynamic>.from(json);

                // Ensure required fields have default values
                processedJson['description'] = processedJson['description'] ?? '';
                processedJson['tags'] = processedJson['tags'] ?? [];
                processedJson['allergens'] = processedJson['allergens'] ?? [];
                processedJson['gallery_images'] = processedJson['gallery_images'] ?? [];
                processedJson['currency'] = processedJson['currency'] ?? 'MYR';

                // Ensure numeric fields are properly typed
                if (processedJson['base_price'] != null) {
                  processedJson['base_price'] = double.tryParse(processedJson['base_price'].toString()) ?? 0.0;
                }
                if (processedJson['bulk_price'] != null) {
                  processedJson['bulk_price'] = double.tryParse(processedJson['bulk_price'].toString());
                }
                if (processedJson['rating'] != null) {
                  processedJson['rating'] = double.tryParse(processedJson['rating'].toString()) ?? 0.0;
                }

                final product = Product.fromJson(processedJson);

                // Load customizations for this menu item
                final customizations = await getMenuItemCustomizations(product.id);
                debugPrint('MenuItemRepository: Loaded ${customizations.length} customizations for ${product.name}');

                // Create product with customizations
                final productWithCustomizations = product.copyWith(customizations: customizations);
                products.add(productWithCustomizations);

                debugPrint('MenuItemRepository: Added product ${productWithCustomizations.name} with ${productWithCustomizations.customizations.length} customizations');
              } catch (e) {
                debugPrint('MenuItemRepository: Error processing menu item: $e');
                debugPrint('MenuItemRepository: JSON: $json');
                // Continue with next item instead of failing the entire stream
              }
            }

            debugPrint('MenuItemRepository: ===== getMenuItemsStream COMPLETED - returning ${products.length} products =====');
            return products;
          });
    });
  }

  /// Get menu item by ID
  Future<Product?> getMenuItemById(String menuItemId) async {
    return executeQuery(() async {
      final response = await supabase
          .from('menu_items')
          .select('*')
          .eq('id', menuItemId)
          .maybeSingle();

      if (response == null) return null;

      // Load customizations separately
      final customizations = await getMenuItemCustomizations(menuItemId);

      // Create product with customizations
      final product = Product.fromJson(response);
      final productWithCustomizations = product.copyWith(customizations: customizations);

      return productWithCustomizations;
    });
  }

  /// Create new menu item (vendor only)
  Future<Product> createMenuItem(Product menuItem) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Create JSON data from Product model and remove fields that should be auto-generated
      final menuItemData = menuItem.toJson();

      // Remove fields that should be auto-generated by database
      menuItemData.remove('id'); // Let database generate UUID
      menuItemData.remove('customizations'); // Handle separately

      // Override vendor_id to ensure it's correct
      menuItemData['vendor_id'] = vendorId;

      // Set timestamps
      menuItemData['created_at'] = DateTime.now().toIso8601String();
      menuItemData['updated_at'] = DateTime.now().toIso8601String();

      debugPrint('MenuItemRepository: Creating menu item with data: $menuItemData');

      final response = await supabase
          .from('menu_items')
          .insert(menuItemData)
          .select()
          .single();

      final createdProduct = Product.fromJson(response);

      // Handle customizations separately if they exist
      if (menuItem.customizations.isNotEmpty) {
        await _saveMenuItemCustomizations(createdProduct.id, menuItem.customizations);
      }

      return createdProduct;
    });
  }

  /// Update menu item (vendor only)
  Future<Product> updateMenuItem(Product menuItem) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Verify ownership
      final existingItem = await getMenuItemById(menuItem.id);
      if (existingItem == null || existingItem.vendorId != vendorId) {
        throw Exception('Menu item not found or access denied');
      }

      // Prepare menu item data excluding customizations (handled separately)
      final menuItemData = menuItem.toJson();
      menuItemData.remove('customizations'); // Remove customizations field
      menuItemData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabase
          .from('menu_items')
          .update(menuItemData)
          .eq('id', menuItem.id)
          .select()
          .single();

      final updatedProduct = Product.fromJson(response);

      // Handle customizations separately
      await _saveMenuItemCustomizations(menuItem.id, menuItem.customizations);

      return updatedProduct;
    });
  }

  /// Delete menu item (vendor only)
  Future<void> deleteMenuItem(String menuItemId) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Verify ownership
      final existingItem = await getMenuItemById(menuItemId);
      if (existingItem == null || existingItem.vendorId != vendorId) {
        throw Exception('Menu item not found or access denied');
      }

      await supabase
          .from('menu_items')
          .delete()
          .eq('id', menuItemId);
    });
  }

  /// Toggle menu item availability
  Future<Product> toggleAvailability(String menuItemId) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      final existingItem = await getMenuItemById(menuItemId);
      if (existingItem == null || existingItem.vendorId != vendorId) {
        throw Exception('Menu item not found or access denied');
      }

      final response = await supabase
          .from('menu_items')
          .update({
            'is_available': !(existingItem.isAvailable ?? true),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', menuItemId)
          .select()
          .single();

      return Product.fromJson(response);
    });
  }

  /// Upload menu item image using FileUploadService
  Future<String> uploadMenuItemImage(XFile image, String menuItemId) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Use the FileUploadService for proper image upload
      final fileUploadService = FileUploadService();
      final publicUrl = await fileUploadService.uploadMenuItemImage(vendorId, menuItemId, image);

      // Update menu item with new image URL
      await supabase
          .from('menu_items')
          .update({
            'image_url': publicUrl,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', menuItemId);

      return publicUrl;
    });
  }

  /// Add image to gallery
  Future<List<String>> addGalleryImage(File image, String menuItemId) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Storage upload temporarily disabled for quick launch
      // await supabase.storage
      //     .from('menu-images')
      //     .upload(filePath, image);

      // final publicUrl = supabase.storage
      //     .from('menu-images')
      //     .getPublicUrl(filePath);
      final publicUrl = 'https://placeholder.com/300x200'; // Temporary placeholder

      // Get current gallery images
      final currentItem = await getMenuItemById(menuItemId);
      if (currentItem == null) throw Exception('Menu item not found');

      final galleryImages = List<String>.from(currentItem.galleryImages);
      galleryImages.add(publicUrl);

      // Update menu item with new gallery
      await supabase
          .from('menu_items')
          .update({
            'gallery_images': galleryImages,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', menuItemId);

      return galleryImages;
    });
  }

  /// Get menu categories for a vendor
  Future<List<String>> getMenuCategories(String vendorId) async {
    return executeQuery(() async {
      final response = await supabase
          .from('menu_items')
          .select('category')
          .eq('vendor_id', vendorId)
          .eq('is_available', true);

      final categories = response
          .map((item) => item['category'] as String)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    });
  }

  /// Get featured menu items for a vendor
  Future<List<Product>> getFeaturedMenuItems(String vendorId, {int limit = 5}) async {
    return executeQuery(() async {
      debugPrint('MenuItemRepository: Getting featured menu items for vendor $vendorId');

      // Use authenticated client for web platform
      final queryClient = kIsWeb ? await getAuthenticatedClient() : supabase;

      final response = await queryClient
          .from('menu_items')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_featured', true)
          .eq('is_available', true)
          .order('rating', ascending: false)
          .limit(limit);

      debugPrint('MenuItemRepository: Found ${response.length} featured menu items');

      return response.map((json) => Product.fromJson(json)).toList();
    });
  }

  /// Search menu items
  Future<List<Product>> searchMenuItems(
    String vendorId,
    String query, {
    int limit = 20,
  }) async {
    return executeQuery(() async {
      final response = await supabase
          .from('menu_items')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_available', true)
          .or(
            'name.ilike.%$query%,'
            'description.ilike.%$query%,'
            'tags.cs.{$query}'
          )
          .order('rating', ascending: false)
          .limit(limit);

      return response.map((json) => Product.fromJson(json)).toList();
    });
  }

  /// Update menu item rating (called after order review)
  Future<void> updateMenuItemRating(String menuItemId, double newRating) async {
    return executeQuery(() async {
      await supabase.rpc('update_menu_item_rating', params: {
        'menu_item_id': menuItemId,
        'new_rating': newRating,
      });
    });
  }

  /// Get menu item statistics for vendor dashboard
  Future<Map<String, dynamic>> getMenuItemStatistics() async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      final response = await supabase.rpc('get_menu_item_statistics', params: {
        'vendor_id': vendorId,
      });

      return response as Map<String, dynamic>;
    });
  }

  /// Get popular menu items
  Future<List<Product>> getPopularMenuItems(String vendorId, {int limit = 10}) async {
    return executeQuery(() async {
      final response = await supabase
          .from('menu_items')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_available', true)
          .order('total_reviews', ascending: false)
          .order('rating', ascending: false)
          .limit(limit);

      return response.map((json) => Product.fromJson(json)).toList();
    });
  }

  /// Bulk update menu item availability
  Future<void> bulkUpdateAvailability(
    List<String> menuItemIds,
    bool isAvailable,
  ) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      await supabase
          .from('menu_items')
          .update({
            'is_available': isAvailable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .inFilter('id', menuItemIds)
          .eq('vendor_id', vendorId);
    });
  }

  /// Add customization to menu item
  Future<void> addCustomizationToMenuItem(String menuItemId, MenuItemCustomization customization) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Verify ownership
      final existingItem = await getMenuItemById(menuItemId);
      if (existingItem == null || existingItem.vendorId != vendorId) {
        throw Exception('Menu item not found or access denied');
      }

      // Insert customization and get the generated ID
      final customizationResponse = await supabase.from('menu_item_customizations').insert({
        'menu_item_id': menuItemId,
        'name': customization.name,
        'type': customization.type,
        'is_required': customization.isRequired,
        'display_order': 0, // Will be updated based on existing customizations
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      }).select().single();

      final customizationId = customizationResponse['id'];

      // Insert customization options
      for (int i = 0; i < customization.options.length; i++) {
        final option = customization.options[i];
        await supabase.from('customization_options').insert({
          'customization_id': customizationId,
          'name': option.name,
          'additional_price': option.additionalPrice,
          'is_default': option.isDefault,
          'display_order': i,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    });
  }

  /// Remove customization from menu item
  Future<void> removeCustomizationFromMenuItem(String menuItemId, String customizationId) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Verify ownership
      final existingItem = await getMenuItemById(menuItemId);
      if (existingItem == null || existingItem.vendorId != vendorId) {
        throw Exception('Menu item not found or access denied');
      }

      // Delete customization options first (foreign key constraint)
      await supabase
          .from('customization_options')
          .delete()
          .eq('customization_id', customizationId);

      // Delete customization
      await supabase
          .from('menu_item_customizations')
          .delete()
          .eq('id', customizationId)
          .eq('menu_item_id', menuItemId);
    });
  }

  /// Get customizations for a menu item (including template-based customizations)
  Future<List<MenuItemCustomization>> getMenuItemCustomizations(String menuItemId) async {
    return executeQuery(() async {
      // Get direct customizations
      final customizationsResponse = await supabase
          .from('menu_item_customizations')
          .select('*')
          .eq('menu_item_id', menuItemId)
          .order('display_order');

      final customizations = <MenuItemCustomization>[];

      // Process direct customizations
      for (final customizationData in customizationsResponse) {
        final optionsResponse = await supabase
            .from('customization_options')
            .select('*')
            .eq('customization_id', customizationData['id'])
            .order('display_order');

        final options = optionsResponse.map((optionData) => CustomizationOption(
          id: optionData['id'],
          name: optionData['name'],
          additionalPrice: (optionData['additional_price'] ?? 0.0).toDouble(),
          isDefault: optionData['is_default'] ?? false,
        )).toList();

        final customization = MenuItemCustomization(
          id: customizationData['id'],
          name: customizationData['name'],
          type: customizationData['type'] ?? 'single',
          isRequired: customizationData['is_required'] ?? false,
          options: options,
        );

        customizations.add(customization);
      }

      // Get template-based customizations

      final templateLinksResponse = await supabase
          .from('menu_item_template_links')
          .select('''
            display_order,
            is_active,
            customization_templates (
              id,
              name,
              type,
              is_required,
              template_options (
                id,
                name,
                additional_price,
                is_default,
                is_available,
                display_order
              )
            )
          ''')
          .eq('menu_item_id', menuItemId)
          .eq('is_active', true)
          .order('display_order');

      // Process template-based customizations
      for (final linkData in templateLinksResponse) {
        final templateData = linkData['customization_templates'];
        if (templateData == null) continue;

        final templateOptions = (templateData['template_options'] as List?)
            ?.where((option) => option['is_available'] == true)
            .map((optionData) => CustomizationOption(
              id: optionData['id'],
              name: optionData['name'],
              additionalPrice: (optionData['additional_price'] ?? 0.0).toDouble(),
              isDefault: optionData['is_default'] ?? false,
            )).toList() ?? [];

        final templateCustomization = MenuItemCustomization(
          id: templateData['id'],
          name: templateData['name'],
          type: templateData['type'] ?? 'single',
          isRequired: templateData['is_required'] ?? false,
          options: templateOptions,
        );

        customizations.add(templateCustomization);
      }

      return customizations;
    });
  }

  /// Duplicate menu item
  Future<Product> duplicateMenuItem(String menuItemId, {String? newName}) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Get original item
      final originalItem = await getMenuItemById(menuItemId);
      if (originalItem == null || originalItem.vendorId != vendorId) {
        throw Exception('Menu item not found or access denied');
      }

      // Create new item with modified name
      final duplicatedItem = originalItem.copyWith(
        // Don't set id - let database generate it
        name: newName ?? '${originalItem.name} (Copy)',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      return await createMenuItem(duplicatedItem);
    });
  }

  /// Helper method to save menu item customizations
  Future<void> _saveMenuItemCustomizations(String menuItemId, List<MenuItemCustomization> customizations) async {
    // First, remove existing customizations for this menu item
    await _clearMenuItemCustomizations(menuItemId);

    // Add new customizations
    for (int i = 0; i < customizations.length; i++) {
      final customization = customizations[i];

      // Insert customization and get the generated ID
      final customizationData = {
        'menu_item_id': menuItemId,
        'name': customization.name,
        'type': customization.type,
        'is_required': customization.isRequired,
        'display_order': i,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final customizationResponse = await supabase.from('menu_item_customizations').insert(customizationData).select().single();

      final customizationId = customizationResponse['id'];

      // Insert customization options
      for (int j = 0; j < customization.options.length; j++) {
        final option = customization.options[j];

        final optionData = {
          'customization_id': customizationId,
          'name': option.name,
          'additional_price': option.additionalPrice,
          'is_default': option.isDefault,
          'display_order': j,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await supabase.from('customization_options').insert(optionData);
      }
    }
  }

  /// Helper method to clear existing customizations for a menu item
  Future<void> _clearMenuItemCustomizations(String menuItemId) async {
    // Get existing customizations
    final existingCustomizations = await supabase
        .from('menu_item_customizations')
        .select('id')
        .eq('menu_item_id', menuItemId);

    // Delete options for each customization
    for (final customization in existingCustomizations) {
      await supabase
          .from('customization_options')
          .delete()
          .eq('customization_id', customization['id']);
    }

    // Delete customizations
    await supabase
        .from('menu_item_customizations')
        .delete()
        .eq('menu_item_id', menuItemId);
  }

  /// Helper method to get current vendor ID
  Future<String?> _getCurrentVendorId() async {
    if (currentUserId == null) return null;

    final response = await supabase
        .from('vendors')
        .select('id')
        .eq('user_id', currentUserId!)
        .maybeSingle();

    return response?['id'];
  }
}
