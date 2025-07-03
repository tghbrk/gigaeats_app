// import 'package:flutter/foundation.dart'; // Unused
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/order.dart';
// TODO: Fix missing menu_item_repository import
// import '../../../menu/data/repositories/menu_item_repository.dart';
// TODO: Fix missing vendor_repository import
// import '../../../vendors/data/repositories/vendor_repository.dart';
// import '../../../presentation/providers/customer/customer_cart_provider.dart'; // Unused
// import '../../../../../presentation/providers/repository_providers.dart'; // Unused

/// Service for handling customer reorder functionality
class CustomerReorderService {
  // TODO: Restore repository dependencies when imports are fixed
  // final MenuItemRepository _menuItemRepository;
  // final VendorRepository _vendorRepository;

  CustomerReorderService(
    // this._menuItemRepository,
    // this._vendorRepository,
  );

  /// Reorder all items from a previous order
  /// Returns true if successful, false if some items couldn't be added
  Future<ReorderResult> reorderFromOrder(
    Order order,
    WidgetRef ref,
  ) async {
    // TODO: Restore when repository dependencies are fixed
    throw Exception('Reorder service temporarily disabled - repository dependencies missing');

    // try {
    //   debugPrint('CustomerReorderService: Starting reorder for order ${order.id}');
    //
    //   final customerCartNotifier = ref.read(customerCartProvider.notifier);
    //   final List<String> unavailableItems = [];
    //   final List<String> addedItems = [];
    //
    //   // Clear current cart first
    //   customerCartNotifier.clearCart();
    //
    //   // Get vendor information
    //   final vendor = await _vendorRepository.getVendorById(order.vendorId);
    //   if (vendor == null) {
    //     throw Exception('Restaurant is no longer available');
    //   }

      // Process each order item
      // for (final orderItem in order.items) {
      //   try {
      //     debugPrint('CustomerReorderService: Processing item ${orderItem.name}');
      //
      //     // Get current menu item to check availability and pricing
      //     final currentMenuItem = await _menuItemRepository.getMenuItemById(orderItem.menuItemId);
      //
      //     if (currentMenuItem == null) {
      //       debugPrint('CustomerReorderService: Menu item ${orderItem.name} no longer exists');
      //       unavailableItems.add('${orderItem.name} (no longer available)');
      //       continue;
      //     }

      //   // Check if item is still available
      //   if (currentMenuItem.isAvailable != true) {
      //     debugPrint('CustomerReorderService: Menu item ${orderItem.name} is not available');
      //     unavailableItems.add('${orderItem.name} (currently unavailable)');
      //     continue;
      //   }
      //
      //   // Add item to cart with original customizations and notes
      //   customerCartNotifier.addItem(
      //     product: currentMenuItem,
      //     vendor: vendor,
      //     quantity: orderItem.quantity,
      //     customizations: orderItem.customizations,
      //     notes: orderItem.notes?.isNotEmpty == true ? orderItem.notes : null,
      //   );
      //
      //   addedItems.add(orderItem.name);
      //   debugPrint('CustomerReorderService: Successfully added ${orderItem.name} to cart');
      //
      // } catch (e) {
      //   debugPrint('CustomerReorderService: Error processing item ${orderItem.name}: $e');
      //   unavailableItems.add('${orderItem.name} (error: ${e.toString()})');
      // }
      // }
      //
      // debugPrint('CustomerReorderService: Reorder completed. Added: ${addedItems.length}, Unavailable: ${unavailableItems.length}');
      //
      // return ReorderResult(
      //   success: addedItems.isNotEmpty,
      //   addedItems: addedItems,
      //   unavailableItems: unavailableItems,
      //   vendorName: vendor.businessName,
      // );
      //
    // } catch (e) {
    //   debugPrint('CustomerReorderService: Error during reorder: $e');
    //   return ReorderResult(
    //     success: false,
    //     addedItems: [],
    //     unavailableItems: [],
    //     error: e.toString(),
    //   );
    // }
  }

  /// Check if an order can be reordered (vendor still exists and has menu items)
  Future<bool> canReorderOrder(Order order) async {
    // TODO: Restore when repository dependencies are fixed
    return false;

    // try {
    //   // Check if vendor still exists
    //   final vendor = await _vendorRepository.getVendorById(order.vendorId);
    //   if (vendor == null) return false;
    //
    //   // Check if at least one menu item is still available
    //   for (final orderItem in order.items) {
    //     final menuItem = await _menuItemRepository.getMenuItemById(orderItem.menuItemId);
    //     if (menuItem != null && menuItem.isAvailable == true) {
    //       return true; // At least one item is available
    //     }
    //   }
    //
    //   return false; // No items are available
    // } catch (e) {
    //   debugPrint('CustomerReorderService: Error checking reorder availability: $e');
    //   return false;
    // }
  }

  /// Get reorder preview - shows what items are available vs unavailable
  Future<ReorderPreview> getReorderPreview(Order order) async {
    // TODO: Restore when repository dependencies are fixed
    return ReorderPreview(
      canReorder: false,
      availableItems: [],
      unavailableItems: order.items.map((item) => item.name).toList(),
      vendorName: order.vendorName,
      error: 'Reorder service temporarily disabled - repository dependencies missing',
    );

    // try {
    //   final vendor = await _vendorRepository.getVendorById(order.vendorId);
    //   if (vendor == null) {
    //     return ReorderPreview(
    //       canReorder: false,
    //       availableItems: [],
    //       unavailableItems: order.items.map((item) => item.name).toList(),
    //       vendorName: order.vendorName,
    //       error: 'Restaurant is no longer available',
    //     );
    //   }
    //
    //   final List<String> availableItems = [];
    //   final List<String> unavailableItems = [];
    //
    //   for (final orderItem in order.items) {
    //     final menuItem = await _menuItemRepository.getMenuItemById(orderItem.menuItemId);
    //
    //     if (menuItem != null && menuItem.isAvailable == true) {
    //       availableItems.add(orderItem.name);
    //     } else {
    //       unavailableItems.add(orderItem.name);
    //     }
    //   }
    //
    //   return ReorderPreview(
    //     canReorder: availableItems.isNotEmpty,
    //     availableItems: availableItems,
    //     unavailableItems: unavailableItems,
    //     vendorName: vendor.businessName,
    //   );
    //
    // } catch (e) {
    //   debugPrint('CustomerReorderService: Error getting reorder preview: $e');
    //   return ReorderPreview(
    //     canReorder: false,
    //     availableItems: [],
    //     unavailableItems: order.items.map((item) => item.name).toList(),
    //     vendorName: order.vendorName,
    //     error: e.toString(),
    //   );
    // }
  }
}

/// Result of a reorder operation
class ReorderResult {
  final bool success;
  final List<String> addedItems;
  final List<String> unavailableItems;
  final String? vendorName;
  final String? error;

  ReorderResult({
    required this.success,
    required this.addedItems,
    required this.unavailableItems,
    this.vendorName,
    this.error,
  });

  bool get hasUnavailableItems => unavailableItems.isNotEmpty;
  bool get hasAddedItems => addedItems.isNotEmpty;
  int get totalItemsProcessed => addedItems.length + unavailableItems.length;
}

/// Preview of what would happen during a reorder
class ReorderPreview {
  final bool canReorder;
  final List<String> availableItems;
  final List<String> unavailableItems;
  final String vendorName;
  final String? error;

  ReorderPreview({
    required this.canReorder,
    required this.availableItems,
    required this.unavailableItems,
    required this.vendorName,
    this.error,
  });

  bool get hasUnavailableItems => unavailableItems.isNotEmpty;
  int get totalItems => availableItems.length + unavailableItems.length;
  double get availabilityPercentage => 
      totalItems > 0 ? (availableItems.length / totalItems) * 100 : 0;
}

/// Provider for customer reorder service
final customerReorderServiceProvider = Provider<CustomerReorderService>((ref) {
  // TODO: Restore when repository dependencies are fixed
  // final menuItemRepository = ref.watch(menuItemRepositoryProvider);
  // final vendorRepository = ref.watch(vendorRepositoryProvider);
  
  return CustomerReorderService(
    // menuItemRepository,
    // vendorRepository,
  );
});

/// Provider for checking if an order can be reordered
final canReorderOrderProvider = FutureProvider.family<bool, Order>((ref, order) async {
  final reorderService = ref.watch(customerReorderServiceProvider);
  return await reorderService.canReorderOrder(order);
});

/// Provider for getting reorder preview
final reorderPreviewProvider = FutureProvider.family<ReorderPreview, Order>((ref, order) async {
  final reorderService = ref.watch(customerReorderServiceProvider);
  return await reorderService.getReorderPreview(order);
});
