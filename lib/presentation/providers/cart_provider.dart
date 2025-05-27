import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../data/models/order.dart';
import '../../data/models/product.dart';
import '../../data/models/vendor.dart';

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

  CartState({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  // Getters
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get sstAmount => subtotal * 0.06; // 6% SST in Malaysia

  double get deliveryFee {
    if (subtotal >= 200) return 0.0; // Free delivery for orders above RM 200
    if (subtotal >= 100) return 5.0; // RM 5 for orders above RM 100
    return 10.0; // RM 10 for smaller orders
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

  CartNotifier() : super(CartState());

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
        description: product.description,
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
