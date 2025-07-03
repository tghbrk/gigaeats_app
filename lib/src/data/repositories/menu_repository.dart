import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/menu/data/models/menu_item.dart';
import '../../features/menu/data/models/product.dart';

/// Repository for menu-related operations
class MenuRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get menu items for a vendor
  Future<List<MenuItem>> getMenuItems(String vendorId) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('category');

      return response.map((json) => MenuItem.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu items: $e');
    }
  }

  /// Get products for a vendor
  Future<List<Product>> getProducts(String vendorId) async {
    try {
      final response = await _supabase
          .from('products')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_available', true)
          .order('category');

      return response.map((json) => Product.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get menu categories for a vendor
  Future<List<MenuCategory>> getMenuCategories(String vendorId) async {
    try {
      final response = await _supabase
          .from('menu_categories')
          .select('*')
          .eq('vendor_id', vendorId)
          .eq('is_active', true)
          .order('sort_order');

      return response.map((json) => MenuCategory.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch menu categories: $e');
    }
  }

  /// Create a new menu item
  Future<MenuItem> createMenuItem(MenuItem menuItem) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .insert(menuItem.toJson())
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create menu item: $e');
    }
  }

  /// Update a menu item
  Future<MenuItem> updateMenuItem(MenuItem menuItem) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .update(menuItem.toJson())
          .eq('id', menuItem.id)
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update menu item: $e');
    }
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      await _supabase
          .from('menu_items')
          .delete()
          .eq('id', menuItemId);
    } catch (e) {
      throw Exception('Failed to delete menu item: $e');
    }
  }
}
