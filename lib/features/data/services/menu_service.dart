import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/menu_item.dart';

/// Temporary stub for MenuService - to be implemented later
class MenuService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get menu items for a vendor
  Future<List<MenuItem>> getMenuItems(String vendorId) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .select()
          .eq('vendor_id', vendorId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((item) => MenuItem.fromJson(item))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch menu items: $error');
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
    } catch (error) {
      throw Exception('Failed to create menu item: $error');
    }
  }

  /// Update an existing menu item
  Future<MenuItem> updateMenuItem(MenuItem menuItem) async {
    try {
      final response = await _supabase
          .from('menu_items')
          .update(menuItem.toJson())
          .eq('id', menuItem.id)
          .select()
          .single();

      return MenuItem.fromJson(response);
    } catch (error) {
      throw Exception('Failed to update menu item: $error');
    }
  }

  /// Delete a menu item
  Future<void> deleteMenuItem(String menuItemId) async {
    try {
      await _supabase
          .from('menu_items')
          .delete()
          .eq('id', menuItemId);
    } catch (error) {
      throw Exception('Failed to delete menu item: $error');
    }
  }

  /// Get menu categories
  Future<List<MenuCategory>> getMenuCategories() async {
    try {
      final response = await _supabase
          .from('menu_categories')
          .select()
          .order('sort_order', ascending: true);

      return (response as List)
          .map((item) => MenuCategory.fromJson(item))
          .toList();
    } catch (error) {
      throw Exception('Failed to fetch menu categories: $error');
    }
  }
}
