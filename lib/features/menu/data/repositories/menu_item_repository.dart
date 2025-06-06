import 'dart:io';
import 'package:flutter/foundation.dart';

import '../models/product.dart';
// Removed unused import: supabase_config.dart
import 'base_repository.dart';

class MenuItemRepository extends BaseRepository {
  MenuItemRepository();

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
        query = query.eq('category', category);
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

      return response.map((json) {
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

          return Product.fromJson(processedJson);
        } catch (e) {
          debugPrint('Error parsing menu item JSON: $e');
          debugPrint('JSON: $json');
          rethrow;
        }
      }).toList();
    });
  }

  /// Get menu items stream for real-time updates
  Stream<List<Product>> getMenuItemsStream(String vendorId) {
    return executeStreamQuery(() {
      return supabase
          .from('menu_items')
          .stream(primaryKey: ['id'])
          .map((data) => data
              .where((item) => item['vendor_id'] == vendorId && item['is_available'] == true)
              .map((json) => Product.fromJson(json))
              .toList());
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

      return response != null ? Product.fromJson(response) : null;
    });
  }

  /// Create new menu item (vendor only)
  Future<Product> createMenuItem(Product menuItem) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      // Create JSON data manually without the id field
      final menuItemData = <String, dynamic>{
        'vendor_id': vendorId,
        'name': menuItem.name,
        'description': menuItem.description,
        'category': menuItem.category,
        'tags': menuItem.tags,
        'base_price': menuItem.basePrice,
        'bulk_price': menuItem.bulkPrice,
        'bulk_min_quantity': menuItem.bulkMinQuantity,
        'currency': menuItem.currency,
        'includes_sst': menuItem.includesSst,
        'is_available': menuItem.isAvailable,
        'min_order_quantity': menuItem.minOrderQuantity,
        'max_order_quantity': menuItem.maxOrderQuantity,
        'preparation_time_minutes': menuItem.preparationTimeMinutes,
        'allergens': menuItem.allergens,
        'is_halal': menuItem.isHalal,
        'is_vegetarian': menuItem.isVegetarian,
        'is_vegan': menuItem.isVegan,
        'is_spicy': menuItem.isSpicy,
        'spicy_level': menuItem.spicyLevel,
        'image_url': menuItem.imageUrl,
        'gallery_images': menuItem.galleryImages,
        'nutrition_info': menuItem.nutritionInfo,
        'rating': menuItem.rating,
        'total_reviews': menuItem.totalReviews,
        'is_featured': menuItem.isFeatured,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      debugPrint('MenuItemRepository: Creating menu item with data: $menuItemData');

      final response = await supabase
          .from('menu_items')
          .insert(menuItemData)
          .select()
          .single();

      return Product.fromJson(response);
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

      final menuItemData = menuItem.toJson();
      menuItemData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabase
          .from('menu_items')
          .update(menuItemData)
          .eq('id', menuItem.id)
          .select()
          .single();

      return Product.fromJson(response);
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

  /// Upload menu item image
  Future<String> uploadMenuItemImage(File image, String menuItemId) async {
    return executeQuery(() async {
      final vendorId = await _getCurrentVendorId();
      if (vendorId == null) throw Exception('Vendor not found');

      final fileName = '${vendorId}_${menuItemId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'menu_items/$fileName';

      // Storage upload temporarily disabled for quick launch
      // await supabase.storage
      //     .from('menu-images')
      //     .upload(filePath, image);

      // final publicUrl = supabase.storage
      //     .from('menu-images')
      //     .getPublicUrl(filePath);
      final publicUrl = 'https://placeholder.com/300x200'; // Temporary placeholder

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

      final fileName = '${vendorId}_${menuItemId}_gallery_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'menu_items/gallery/$fileName';

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
