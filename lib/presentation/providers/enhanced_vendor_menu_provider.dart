import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Product model not needed for menu provider
import '../../core/utils/debug_logger.dart';
import 'enhanced_order_provider.dart';

// Enhanced Vendor Menu Management with Versioning and Bulk Operations

// Menu Version Model
class MenuVersion {
  final String id;
  final String vendorId;
  final int versionNumber;
  final String name;
  final String? description;
  final bool isActive;
  final DateTime? publishedAt;
  final String? createdBy;
  final DateTime createdAt;

  MenuVersion({
    required this.id,
    required this.vendorId,
    required this.versionNumber,
    required this.name,
    this.description,
    required this.isActive,
    this.publishedAt,
    this.createdBy,
    required this.createdAt,
  });

  factory MenuVersion.fromJson(Map<String, dynamic> json) {
    return MenuVersion(
      id: json['id'],
      vendorId: json['vendor_id'],
      versionNumber: json['version_number'],
      name: json['name'],
      description: json['description'],
      isActive: json['is_active'] ?? false,
      publishedAt: json['published_at'] != null ? DateTime.parse(json['published_at']) : null,
      createdBy: json['created_by'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'vendor_id': vendorId,
    'version_number': versionNumber,
    'name': name,
    'description': description,
    'is_active': isActive,
    'published_at': publishedAt?.toIso8601String(),
    'created_by': createdBy,
    'created_at': createdAt.toIso8601String(),
  };
}

// Versioned Menu Item Model
class VersionedMenuItem {
  final String id;
  final String menuVersionId;
  final String name;
  final String? description;
  final double price;
  final String? category;
  final String? imageUrl;
  final String? imageAltText;
  final bool isAvailable;
  final int preparationTime;
  final Map<String, dynamic>? nutritionalInfo;
  final List<String> allergenInfo;
  final List<String> tags;
  final int sortOrder;
  final DateTime createdAt;

  VersionedMenuItem({
    required this.id,
    required this.menuVersionId,
    required this.name,
    this.description,
    required this.price,
    this.category,
    this.imageUrl,
    this.imageAltText,
    required this.isAvailable,
    required this.preparationTime,
    this.nutritionalInfo,
    required this.allergenInfo,
    required this.tags,
    required this.sortOrder,
    required this.createdAt,
  });

  factory VersionedMenuItem.fromJson(Map<String, dynamic> json) {
    return VersionedMenuItem(
      id: json['id'],
      menuVersionId: json['menu_version_id'],
      name: json['name'],
      description: json['description'],
      price: (json['price'] as num).toDouble(),
      category: json['category'],
      imageUrl: json['image_url'],
      imageAltText: json['image_alt_text'],
      isAvailable: json['is_available'] ?? true,
      preparationTime: json['preparation_time'] ?? 30,
      nutritionalInfo: json['nutritional_info'],
      allergenInfo: List<String>.from(json['allergen_info'] ?? []),
      tags: List<String>.from(json['tags'] ?? []),
      sortOrder: json['sort_order'] ?? 0,
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'menu_version_id': menuVersionId,
    'name': name,
    'description': description,
    'price': price,
    'category': category,
    'image_url': imageUrl,
    'image_alt_text': imageAltText,
    'is_available': isAvailable,
    'preparation_time': preparationTime,
    'nutritional_info': nutritionalInfo,
    'allergen_info': allergenInfo,
    'tags': tags,
    'sort_order': sortOrder,
    'created_at': createdAt.toIso8601String(),
  };
}

// Bulk Operation Request
class BulkMenuOperation {
  final String operation; // 'create', 'update', 'delete', 'price_update'
  final List<Map<String, dynamic>> items;
  final Map<String, dynamic>? metadata;

  BulkMenuOperation({
    required this.operation,
    required this.items,
    this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'operation': operation,
    'items': items,
    'metadata': metadata,
  };
}

// Menu Management State
class MenuManagementState {
  final List<MenuVersion> versions;
  final List<VersionedMenuItem> currentMenuItems;
  final MenuVersion? activeVersion;
  final bool isLoading;
  final String? errorMessage;
  final Map<String, List<VersionedMenuItem>> itemsByCategory;

  MenuManagementState({
    this.versions = const [],
    this.currentMenuItems = const [],
    this.activeVersion,
    this.isLoading = false,
    this.errorMessage,
    this.itemsByCategory = const {},
  });

  MenuManagementState copyWith({
    List<MenuVersion>? versions,
    List<VersionedMenuItem>? currentMenuItems,
    MenuVersion? activeVersion,
    bool? isLoading,
    String? errorMessage,
    Map<String, List<VersionedMenuItem>>? itemsByCategory,
  }) {
    return MenuManagementState(
      versions: versions ?? this.versions,
      currentMenuItems: currentMenuItems ?? this.currentMenuItems,
      activeVersion: activeVersion ?? this.activeVersion,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      itemsByCategory: itemsByCategory ?? this.itemsByCategory,
    );
  }
}

// Enhanced Menu Management Notifier
class EnhancedMenuManagementNotifier extends StateNotifier<MenuManagementState> {
  final SupabaseClient _supabase;
  final Ref _ref;

  EnhancedMenuManagementNotifier(this._supabase, this._ref) : super(MenuManagementState());

  // Load menu versions for vendor (using mock data)
  Future<void> loadMenuVersions(String vendorId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      DebugLogger.info('Loading menu versions for vendor: $vendorId (from database)', tag: 'EnhancedMenuManagementNotifier');

      // Load menu versions from database
      final versionsResponse = await _supabase
          .from('menu_versions')
          .select('*')
          .eq('vendor_id', vendorId)
          .order('version_number', ascending: false);

      final versions = (versionsResponse as List)
          .map((json) => MenuVersion.fromJson(json))
          .toList();

      // Find active version or create a default one if none exist
      MenuVersion? activeVersion;
      List<VersionedMenuItem> menuItems = [];
      Map<String, List<VersionedMenuItem>> itemsByCategory = {};

      if (versions.isNotEmpty) {
        activeVersion = versions.firstWhere(
          (v) => v.isActive,
          orElse: () => versions.first,
        );

        // Load menu items for active version
        await _loadMenuItemsForVersion(activeVersion.id);
        menuItems = state.currentMenuItems;
        itemsByCategory = state.itemsByCategory;
      } else {
        // Create a default menu version if none exist
        DebugLogger.info('No menu versions found, creating default version', tag: 'EnhancedMenuManagementNotifier');
        activeVersion = await _createDefaultMenuVersion(vendorId);
        if (activeVersion != null) {
          versions.add(activeVersion);
        }
      }

      state = state.copyWith(
        versions: versions,
        activeVersion: activeVersion,
        currentMenuItems: menuItems,
        itemsByCategory: itemsByCategory,
        isLoading: false,
      );

      DebugLogger.success('Menu versions loaded successfully: ${versions.length} versions', tag: 'EnhancedMenuManagementNotifier');

    } catch (e) {
      DebugLogger.error('Error loading menu versions: $e', tag: 'EnhancedMenuManagementNotifier');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  // Load menu items for specific version
  Future<void> _loadMenuItemsForVersion(String versionId) async {
    final itemsResponse = await _supabase
        .from('menu_items_versioned')
        .select('*')
        .eq('menu_version_id', versionId)
        .order('sort_order', ascending: true);

    final items = (itemsResponse as List)
        .map((json) => VersionedMenuItem.fromJson(json))
        .toList();

    // Group items by category
    final itemsByCategory = <String, List<VersionedMenuItem>>{};
    for (final item in items) {
      final category = item.category ?? 'Uncategorized';
      itemsByCategory.putIfAbsent(category, () => []).add(item);
    }

    state = state.copyWith(
      currentMenuItems: items,
      itemsByCategory: itemsByCategory,
    );
  }

  // Create default menu version for new vendors
  Future<MenuVersion?> _createDefaultMenuVersion(String vendorId) async {
    try {
      DebugLogger.info('Creating default menu version for vendor: $vendorId', tag: 'EnhancedMenuManagementNotifier');

      final versionData = {
        'vendor_id': vendorId,
        'version_number': 1,
        'name': 'Default Menu',
        'description': 'Initial menu version',
        'is_active': true,
        'created_by': 'system',
        'published_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('menu_versions')
          .insert(versionData)
          .select()
          .single();

      final version = MenuVersion.fromJson(response);
      DebugLogger.success('Default menu version created: ${version.id}', tag: 'EnhancedMenuManagementNotifier');
      return version;

    } catch (e) {
      DebugLogger.error('Error creating default menu version: $e', tag: 'EnhancedMenuManagementNotifier');
      return null;
    }
  }

  // Create new menu version (using real database)
  Future<MenuVersion?> createMenuVersion({
    required String vendorId,
    required String name,
    String? description,
    String? createdBy,
  }) async {
    try {
      DebugLogger.info('Creating new menu version: $name (in database)', tag: 'EnhancedMenuManagementNotifier');

      // Get next version number
      final nextVersionNumber = state.versions.isNotEmpty
          ? state.versions.map((v) => v.versionNumber).reduce((a, b) => a > b ? a : b) + 1
          : 1;

      // Prepare version data for database
      final versionData = {
        'vendor_id': vendorId,
        'version_number': nextVersionNumber,
        'name': name,
        'description': description,
        'is_active': false, // New versions start as inactive
        'created_by': createdBy ?? 'test-user',
      };

      // Insert into database
      final response = await _supabase
          .from('menu_versions')
          .insert(versionData)
          .select()
          .single();

      final version = MenuVersion.fromJson(response);

      // Update local state
      final updatedVersions = [version, ...state.versions];
      state = state.copyWith(versions: updatedVersions);

      DebugLogger.success('Menu version created successfully: ${version.id}', tag: 'EnhancedMenuManagementNotifier');
      return version;

    } catch (e) {
      DebugLogger.error('Error creating menu version: $e', tag: 'EnhancedMenuManagementNotifier');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  // Publish menu version (make it active)
  Future<bool> publishMenuVersion(String versionId) async {
    try {
      DebugLogger.info('Publishing menu version: $versionId', tag: 'EnhancedMenuManagementNotifier');

      // Deactivate all other versions first
      await _supabase
          .from('menu_versions')
          .update({
            'is_active': false,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('vendor_id', state.activeVersion?.vendorId ?? '');

      // Activate the selected version
      await _supabase
          .from('menu_versions')
          .update({
            'is_active': true,
            'published_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', versionId);

      // Reload versions to reflect changes
      if (state.activeVersion != null) {
        await loadMenuVersions(state.activeVersion!.vendorId);
      }

      DebugLogger.success('Menu version published successfully', tag: 'EnhancedMenuManagementNotifier');
      return true;

    } catch (e) {
      DebugLogger.error('Error publishing menu version: $e', tag: 'EnhancedMenuManagementNotifier');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  // Bulk operations for menu items
  Future<bool> performBulkOperation(BulkMenuOperation operation) async {
    try {
      DebugLogger.info('Performing bulk operation: ${operation.operation}', tag: 'EnhancedMenuManagementNotifier');

      switch (operation.operation) {
        case 'create':
          return await _bulkCreateItems(operation.items);
        case 'update':
          return await _bulkUpdateItems(operation.items);
        case 'delete':
          return await _bulkDeleteItems(operation.items);
        case 'price_update':
          return await _bulkUpdatePrices(operation.items);
        default:
          throw Exception('Unknown bulk operation: ${operation.operation}');
      }

    } catch (e) {
      DebugLogger.error('Error performing bulk operation: $e', tag: 'EnhancedMenuManagementNotifier');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> _bulkCreateItems(List<Map<String, dynamic>> items) async {
    await _supabase
        .from('menu_items_versioned')
        .insert(items);

    // Reload current menu items
    if (state.activeVersion != null) {
      await _loadMenuItemsForVersion(state.activeVersion!.id);
    }

    return true;
  }

  Future<bool> _bulkUpdateItems(List<Map<String, dynamic>> items) async {
    // Perform individual updates (Supabase doesn't support bulk updates directly)
    for (final item in items) {
      final id = item['id'];
      final updateData = Map<String, dynamic>.from(item)..remove('id');
      
      await _supabase
          .from('menu_items_versioned')
          .update(updateData)
          .eq('id', id);
    }

    // Reload current menu items
    if (state.activeVersion != null) {
      await _loadMenuItemsForVersion(state.activeVersion!.id);
    }

    return true;
  }

  Future<bool> _bulkDeleteItems(List<Map<String, dynamic>> items) async {
    final ids = items.map((item) => item['id']).toList();
    
    await _supabase
        .from('menu_items_versioned')
        .delete()
        .inFilter('id', ids);

    // Reload current menu items
    if (state.activeVersion != null) {
      await _loadMenuItemsForVersion(state.activeVersion!.id);
    }

    return true;
  }

  Future<bool> _bulkUpdatePrices(List<Map<String, dynamic>> items) async {
    try {
      DebugLogger.info('Starting bulk price update for ${items.length} items', tag: 'EnhancedMenuManagementNotifier');

      for (final item in items) {
        DebugLogger.info('Updating price for item ${item['id']} to ${item['price']}', tag: 'EnhancedMenuManagementNotifier');

        final response = await _supabase
            .from('menu_items_versioned')
            .update({'price': item['price']})
            .eq('id', item['id'])
            .select();

        DebugLogger.info('Update response: $response', tag: 'EnhancedMenuManagementNotifier');
      }

      // Reload current menu items
      if (state.activeVersion != null) {
        await _loadMenuItemsForVersion(state.activeVersion!.id);
      }

      DebugLogger.success('Bulk price update completed successfully', tag: 'EnhancedMenuManagementNotifier');
      return true;

    } catch (e) {
      DebugLogger.error('Error in bulk price update: $e', tag: 'EnhancedMenuManagementNotifier');
      rethrow;
    }
  }

  void clearError() {
    state = state.copyWith(errorMessage: null);
  }


}

// Enhanced Menu Management Provider
final enhancedMenuManagementProvider = StateNotifierProvider<EnhancedMenuManagementNotifier, MenuManagementState>((ref) {
  final supabase = ref.watch(supabaseProvider);
  return EnhancedMenuManagementNotifier(supabase, ref);
});

// Menu Versions Provider for specific vendor
final menuVersionsProvider = FutureProvider.family<List<MenuVersion>, String>((ref, vendorId) async {
  final supabase = ref.watch(supabaseProvider);
  
  final response = await supabase
      .from('menu_versions')
      .select('*')
      .eq('vendor_id', vendorId)
      .order('version_number', ascending: false);

  return (response as List)
      .map((json) => MenuVersion.fromJson(json))
      .toList();
});

// Active Menu Items Provider for specific vendor
final activeMenuItemsProvider = FutureProvider.family<List<VersionedMenuItem>, String>((ref, vendorId) async {
  final supabase = ref.watch(supabaseProvider);
  
  // Get active version
  final versionsResponse = await supabase
      .from('menu_versions')
      .select('*')
      .eq('vendor_id', vendorId)
      .eq('is_active', true)
      .single();

  final activeVersion = MenuVersion.fromJson(versionsResponse);

  // Get menu items for active version
  final itemsResponse = await supabase
      .from('menu_items_versioned')
      .select('*')
      .eq('menu_version_id', activeVersion.id)
      .order('sort_order', ascending: true);

  return (itemsResponse as List)
      .map((json) => VersionedMenuItem.fromJson(json))
      .toList();
});
