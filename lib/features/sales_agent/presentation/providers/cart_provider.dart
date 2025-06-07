import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../orders/data/models/order.dart';
import '../../../menu/data/models/product.dart';
import '../../../vendors/data/models/vendor.dart';
import '../../../menu/data/models/menu_item.dart';
import '../../../orders/data/models/delivery_method.dart';

// Cart Item class for managing items in cart
class CartItem {
  final String id;
  final String productId;
  final String name;
  final String description;
  final double unitPrice;
  final int quantity;
  final String? imageUrl;
  final Map<String, dynamic>? customizations;
  final String? notes;
  final String vendorId;
  final String vendorName;

  CartItem({
    required this.id,
    required this.productId,
    required this.name,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    this.imageUrl,
    this.customizations,
    this.notes,
    required this.vendorId,
    required this.vendorName,
  });

  double get totalPrice => unitPrice * quantity;

  CartItem copyWith({
    String? id,
    String? productId,
    String? name,
    String? description,
    double? unitPrice,
    int? quantity,
    String? imageUrl,
    Map<String, dynamic>? customizations,
    String? notes,
    String? vendorId,
    String? vendorName,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      name: name ?? this.name,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      customizations: customizations ?? this.customizations,
      notes: notes ?? this.notes,
      vendorId: vendorId ?? this.vendorId,
      vendorName: vendorName ?? this.vendorName,
    );
  }

  // Convert to OrderItem
  OrderItem toOrderItem() {
    return OrderItem(
      id: id,
      menuItemId: productId,
      name: name,
      description: description,
      unitPrice: unitPrice,
      quantity: quantity,
      totalPrice: totalPrice,
      imageUrl: imageUrl,
      customizations: customizations,
      notes: notes,
    );
  }
}

// Cart State
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? errorMessage;
  final DeliveryMethod? selectedDeliveryMethod;

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
    this.selectedDeliveryMethod = DeliveryMethod.ownFleet,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? errorMessage,
    DeliveryMethod? selectedDeliveryMethod,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      selectedDeliveryMethod: selectedDeliveryMethod ?? this.selectedDeliveryMethod,
    );
  }

  // Getters
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get sstAmount => subtotal * 0.06; // 6% SST in Malaysia

  double get deliveryFee {
    // Handle null case with default delivery method
    final deliveryMethod = selectedDeliveryMethod ?? DeliveryMethod.ownFleet;

    // Pickup methods have no delivery fee
    if (deliveryMethod.isPickup) return 0.0;

    switch (deliveryMethod) {
      case DeliveryMethod.lalamove:
        // Premium pricing for Lalamove
        if (subtotal >= 200) return 0.0; // Free delivery for large orders
        if (subtotal >= 100) return 15.0; // RM 15 for medium orders
        return 20.0; // RM 20 for smaller orders

      case DeliveryMethod.ownFleet:
        // Standard pricing for own fleet
        if (subtotal >= 200) return 0.0; // Free delivery for orders above RM 200
        if (subtotal >= 100) return 5.0; // RM 5 for orders above RM 100
        return 10.0; // RM 10 for smaller orders

      case DeliveryMethod.customerPickup:
      case DeliveryMethod.salesAgentPickup:
        return 0.0; // No delivery fee for pickup
    }
  }

  double get totalAmount => subtotal + sstAmount + deliveryFee;

  bool get isEmpty => items.isEmpty;

  // Group items by vendor
  Map<String, List<CartItem>> get itemsByVendor {
    final Map<String, List<CartItem>> grouped = {};
    for (final item in items) {
      if (!grouped.containsKey(item.vendorId)) {
        grouped[item.vendorId] = [];
      }
      grouped[item.vendorId]!.add(item);
    }
    return grouped;
  }

  List<String> get vendorIds => itemsByVendor.keys.toList();

  bool get hasMultipleVendors => vendorIds.length > 1;
}

// Cart Provider
class CartNotifier extends StateNotifier<CartState> {
  static const _uuid = Uuid();

  CartNotifier() : super(CartState(selectedDeliveryMethod: DeliveryMethod.ownFleet));

  void addItem({
    required Product product,
    required Vendor vendor,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
  }) {
    final existingItemIndex = state.items.indexWhere(
      (item) =>
        item.productId == product.id &&
        _areCustomizationsEqual(item.customizations, customizations),
    );

    if (existingItemIndex >= 0) {
      // Update existing item quantity
      final existingItem = state.items[existingItemIndex];
      final updatedItem = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );

      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingItemIndex] = updatedItem;

      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        id: _uuid.v4(),
        productId: product.id,
        name: product.name,
        description: product.safeDescription,
        unitPrice: product.pricing.effectivePrice,
        quantity: quantity,
        imageUrl: product.imageUrl ?? (product.galleryImages.isNotEmpty ? product.galleryImages.first : null),
        customizations: customizations,
        notes: notes,
        vendorId: vendor.id,
        vendorName: vendor.businessName,
      );

      state = state.copyWith(
        items: [...state.items, newItem],
      );
    }
  }

  void addMenuItem({
    required MenuItem menuItem,
    required String vendorName,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
  }) {
    // Check if quantity is valid for this menu item
    if (!menuItem.isValidQuantity(quantity)) {
      throw Exception('Invalid quantity for ${menuItem.name}. Min: ${menuItem.minimumOrderQuantity}');
    }

    final effectivePrice = menuItem.getEffectivePrice(quantity);

    final existingItemIndex = state.items.indexWhere(
      (item) =>
        item.productId == menuItem.id &&
        _areCustomizationsEqual(item.customizations, customizations),
    );

    if (existingItemIndex >= 0) {
      // Update existing item quantity
      final existingItem = state.items[existingItemIndex];
      final newQuantity = existingItem.quantity + quantity;

      // Check if new quantity is valid
      if (!menuItem.isValidQuantity(newQuantity)) {
        throw Exception('Cannot add more. Maximum quantity exceeded.');
      }

      final updatedItem = existingItem.copyWith(
        quantity: newQuantity,
        unitPrice: menuItem.getEffectivePrice(newQuantity), // Update price based on new quantity
      );

      final updatedItems = List<CartItem>.from(state.items);
      updatedItems[existingItemIndex] = updatedItem;

      state = state.copyWith(items: updatedItems);
    } else {
      // Add new item
      final newItem = CartItem(
        id: _uuid.v4(),
        productId: menuItem.id,
        name: menuItem.name,
        description: menuItem.description,
        unitPrice: effectivePrice,
        quantity: quantity,
        imageUrl: menuItem.imageUrls.isNotEmpty ? menuItem.imageUrls.first : null,
        customizations: customizations,
        notes: notes,
        vendorId: menuItem.vendorId,
        vendorName: vendorName,
      );

      state = state.copyWith(
        items: [...state.items, newItem],
      );
    }
  }

  void updateItemQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.id == itemId) {
        return item.copyWith(quantity: newQuantity);
      }
      return item;
    }).toList();

    state = state.copyWith(items: updatedItems);
  }

  void incrementItem(String itemId) {
    final item = state.items.firstWhere((item) => item.id == itemId);
    updateItemQuantity(itemId, item.quantity + 1);
  }

  void decrementItem(String itemId) {
    final item = state.items.firstWhere((item) => item.id == itemId);
    updateItemQuantity(itemId, item.quantity - 1);
  }

  void removeItem(String itemId) {
    final updatedItems = state.items.where((item) => item.id != itemId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void clearCart() {
    state = state.copyWith(items: []);
  }

  void clearVendorItems(String vendorId) {
    final updatedItems = state.items.where((item) => item.vendorId != vendorId).toList();
    state = state.copyWith(items: updatedItems);
  }

  void updateDeliveryMethod(DeliveryMethod deliveryMethod) {
    state = state.copyWith(selectedDeliveryMethod: deliveryMethod);
  }

  // Helper method to compare customizations
  bool _areCustomizationsEqual(
    Map<String, dynamic>? customizations1,
    Map<String, dynamic>? customizations2,
  ) {
    if (customizations1 == null && customizations2 == null) return true;
    if (customizations1 == null || customizations2 == null) return false;

    if (customizations1.length != customizations2.length) return false;

    for (final key in customizations1.keys) {
      if (!customizations2.containsKey(key) ||
          customizations1[key] != customizations2[key]) {
        return false;
      }
    }

    return true;
  }
}

// Provider
final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});

// Computed providers
final cartItemCountProvider = Provider<int>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.totalItems;
});

final cartTotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.totalAmount;
});

final cartSubtotalProvider = Provider<double>((ref) {
  final cart = ref.watch(cartProvider);
  return cart.subtotal;
});
