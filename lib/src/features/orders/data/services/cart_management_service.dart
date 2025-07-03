import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/enhanced_cart_models.dart';
import '../../../menu/data/models/menu_item.dart';
import '../../../core/utils/logger.dart';
import 'cart_persistence_service.dart';
import 'enhanced_cart_service.dart';

/// Comprehensive cart management service with advanced operations
class CartManagementService {
  final CartPersistenceService _persistenceService;
  final EnhancedCartService _cartService;
  final AppLogger _logger = AppLogger();

  // Stream controllers for real-time updates
  final StreamController<CartOperationEvent> _operationController = 
      StreamController<CartOperationEvent>.broadcast();
  final StreamController<CartPricingEvent> _pricingController = 
      StreamController<CartPricingEvent>.broadcast();

  CartManagementService(this._persistenceService, this._cartService);

  /// Stream of cart operation events
  Stream<CartOperationEvent> get operationEvents => _operationController.stream;

  /// Stream of cart pricing events
  Stream<CartPricingEvent> get pricingEvents => _pricingController.stream;

  /// Add menu item to cart with comprehensive validation and pricing
  Future<CartOperationResult> addMenuItem({
    required MenuItem menuItem,
    required String vendorName,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
    bool validateOnly = false,
  }) async {
    try {
      _logger.info('🛒 [CART-MGMT] Adding menu item: ${menuItem.name} (qty: $quantity)');

      // Validate menu item
      final validationResult = await _validateMenuItem(menuItem, quantity, customizations);
      if (!validationResult.isValid) {
        return CartOperationResult.failure(validationResult.errors.join(', '));
      }

      // Calculate pricing
      final pricingResult = await _calculateItemPricing(menuItem, quantity, customizations);
      
      if (validateOnly) {
        return CartOperationResult.validation(pricingResult);
      }

      // Load current cart
      final loadResult = await _persistenceService.loadCart();
      final currentCart = loadResult.cartState ?? EnhancedCartState.empty();

      // Check for conflicts (multi-vendor, etc.)
      final conflictResult = await _checkCartConflicts(currentCart, menuItem);
      if (!conflictResult.isValid) {
        return CartOperationResult.conflict(conflictResult.errors);
      }

      // Generate unique cart item ID
      final cartItemId = _generateCartItemId(menuItem.id, customizations);

      // Check if item already exists
      final existingItemIndex = currentCart.items.indexWhere((item) => item.id == cartItemId);

      List<EnhancedCartItem> updatedItems;
      EnhancedCartItem? newItem;

      if (existingItemIndex >= 0) {
        // Update existing item
        final existingItem = currentCart.items[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;

        // Validate new quantity
        final quantityValidation = await _validateQuantity(menuItem, newQuantity);
        if (!quantityValidation.isValid) {
          return CartOperationResult.failure(quantityValidation.errors.join(', '));
        }

        final updatedItem = existingItem.copyWith(quantity: newQuantity);
        updatedItems = List<EnhancedCartItem>.from(currentCart.items);
        updatedItems[existingItemIndex] = updatedItem;

        _logger.info('✅ [CART-MGMT] Updated existing item quantity to $newQuantity');
      } else {
        // Add new item
        newItem = EnhancedCartItem(
          id: cartItemId,
          productId: menuItem.id,
          name: menuItem.name,
          description: menuItem.description,
          basePrice: menuItem.basePrice,
          unitPrice: pricingResult.unitPrice,
          quantity: quantity,
          imageUrl: menuItem.imageUrls.isNotEmpty ? menuItem.imageUrls.first : null,
          customizations: customizations,
          customizationCost: pricingResult.customizationCost,
          notes: notes,
          vendorId: menuItem.vendorId,
          vendorName: vendorName,
          addedAt: DateTime.now(),
          isAvailable: menuItem.status == MenuItemStatus.available,
          maxQuantity: menuItem.maximumOrderQuantity,
          minQuantity: menuItem.minimumOrderQuantity,
        );

        updatedItems = [...currentCart.items, newItem];
        _logger.info('✅ [CART-MGMT] Added new item to cart');
      }

      // Create updated cart state
      final updatedCart = currentCart.copyWith(items: updatedItems);

      // Recalculate cart summary
      final summary = await _cartService.calculateCartSummary(
        items: updatedItems,
        deliveryMethod: currentCart.deliveryMethod,
        deliveryAddress: currentCart.selectedAddress,
        scheduledTime: currentCart.scheduledDeliveryTime,
      );

      final finalCart = updatedCart.copyWith(summary: summary);

      // Save cart
      final saveResult = await _persistenceService.saveCart(finalCart);
      if (!saveResult.isSuccess) {
        return CartOperationResult.failure('Failed to save cart: ${saveResult.error}');
      }

      // Emit events
      _operationController.add(CartOperationEvent.itemAdded(newItem ?? updatedItems[existingItemIndex]));
      _pricingController.add(CartPricingEvent.updated(summary));

      return CartOperationResult.success(finalCart);

    } catch (e) {
      _logger.error('❌ [CART-MGMT] Failed to add menu item', e);
      return CartOperationResult.failure('Failed to add item: $e');
    }
  }

  /// Remove item from cart
  Future<CartOperationResult> removeItem(String itemId) async {
    try {
      _logger.info('🗑️ [CART-MGMT] Removing item: $itemId');

      // Load current cart
      final loadResult = await _persistenceService.loadCart();
      if (!loadResult.isSuccess || loadResult.cartState == null) {
        return CartOperationResult.failure('Cart not found');
      }

      final currentCart = loadResult.cartState!;
      final itemToRemove = currentCart.items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => throw Exception('Item not found'),
      );

      // Remove item
      final updatedItems = currentCart.items.where((item) => item.id != itemId).toList();
      final updatedCart = currentCart.copyWith(items: updatedItems);

      // Recalculate summary
      final summary = await _cartService.calculateCartSummary(
        items: updatedItems,
        deliveryMethod: currentCart.deliveryMethod,
        deliveryAddress: currentCart.selectedAddress,
        scheduledTime: currentCart.scheduledDeliveryTime,
      );

      final finalCart = updatedCart.copyWith(summary: summary);

      // Save cart
      final saveResult = await _persistenceService.saveCart(finalCart);
      if (!saveResult.isSuccess) {
        return CartOperationResult.failure('Failed to save cart: ${saveResult.error}');
      }

      // Emit events
      _operationController.add(CartOperationEvent.itemRemoved(itemToRemove));
      _pricingController.add(CartPricingEvent.updated(summary));

      _logger.info('✅ [CART-MGMT] Item removed successfully');
      return CartOperationResult.success(finalCart);

    } catch (e) {
      _logger.error('❌ [CART-MGMT] Failed to remove item', e);
      return CartOperationResult.failure('Failed to remove item: $e');
    }
  }

  /// Update item quantity with validation
  Future<CartOperationResult> updateItemQuantity(String itemId, int newQuantity) async {
    try {
      _logger.info('📝 [CART-MGMT] Updating item quantity: $itemId to $newQuantity');

      if (newQuantity <= 0) {
        return await removeItem(itemId);
      }

      // Load current cart
      final loadResult = await _persistenceService.loadCart();
      if (!loadResult.isSuccess || loadResult.cartState == null) {
        return CartOperationResult.failure('Cart not found');
      }

      final currentCart = loadResult.cartState!;
      final itemIndex = currentCart.items.indexWhere((item) => item.id == itemId);
      
      if (itemIndex < 0) {
        return CartOperationResult.failure('Item not found in cart');
      }

      final item = currentCart.items[itemIndex];

      // Validate new quantity
      if (newQuantity < item.minQuantity) {
        return CartOperationResult.failure('Minimum quantity is ${item.minQuantity}');
      }
      if (item.maxQuantity != null && newQuantity > item.maxQuantity!) {
        return CartOperationResult.failure('Maximum quantity is ${item.maxQuantity}');
      }

      // Update item
      final updatedItem = item.copyWith(quantity: newQuantity);
      final updatedItems = List<EnhancedCartItem>.from(currentCart.items);
      updatedItems[itemIndex] = updatedItem;

      final updatedCart = currentCart.copyWith(items: updatedItems);

      // Recalculate summary
      final summary = await _cartService.calculateCartSummary(
        items: updatedItems,
        deliveryMethod: currentCart.deliveryMethod,
        deliveryAddress: currentCart.selectedAddress,
        scheduledTime: currentCart.scheduledDeliveryTime,
      );

      final finalCart = updatedCart.copyWith(summary: summary);

      // Save cart
      final saveResult = await _persistenceService.saveCart(finalCart);
      if (!saveResult.isSuccess) {
        return CartOperationResult.failure('Failed to save cart: ${saveResult.error}');
      }

      // Emit events
      _operationController.add(CartOperationEvent.itemUpdated(updatedItem));
      _pricingController.add(CartPricingEvent.updated(summary));

      _logger.info('✅ [CART-MGMT] Quantity updated successfully');
      return CartOperationResult.success(finalCart);

    } catch (e) {
      _logger.error('❌ [CART-MGMT] Failed to update quantity', e);
      return CartOperationResult.failure('Failed to update quantity: $e');
    }
  }

  /// Update item customizations
  Future<CartOperationResult> updateItemCustomizations(
    String itemId,
    Map<String, dynamic> newCustomizations,
  ) async {
    try {
      _logger.info('🎨 [CART-MGMT] Updating item customizations: $itemId');

      // Load current cart
      final loadResult = await _persistenceService.loadCart();
      if (!loadResult.isSuccess || loadResult.cartState == null) {
        return CartOperationResult.failure('Cart not found');
      }

      final currentCart = loadResult.cartState!;
      final itemIndex = currentCart.items.indexWhere((item) => item.id == itemId);
      
      if (itemIndex < 0) {
        return CartOperationResult.failure('Item not found in cart');
      }

      final item = currentCart.items[itemIndex];

      // Calculate new pricing with updated customizations
      // Note: We would need the original MenuItem to recalculate properly
      // For now, we'll update the customizations and recalculate the cart
      
      final updatedItem = item.copyWith(customizations: newCustomizations);
      final updatedItems = List<EnhancedCartItem>.from(currentCart.items);
      updatedItems[itemIndex] = updatedItem;

      final updatedCart = currentCart.copyWith(items: updatedItems);

      // Recalculate summary
      final summary = await _cartService.calculateCartSummary(
        items: updatedItems,
        deliveryMethod: currentCart.deliveryMethod,
        deliveryAddress: currentCart.selectedAddress,
        scheduledTime: currentCart.scheduledDeliveryTime,
      );

      final finalCart = updatedCart.copyWith(summary: summary);

      // Save cart
      final saveResult = await _persistenceService.saveCart(finalCart);
      if (!saveResult.isSuccess) {
        return CartOperationResult.failure('Failed to save cart: ${saveResult.error}');
      }

      // Emit events
      _operationController.add(CartOperationEvent.itemUpdated(updatedItem));
      _pricingController.add(CartPricingEvent.updated(summary));

      _logger.info('✅ [CART-MGMT] Customizations updated successfully');
      return CartOperationResult.success(finalCart);

    } catch (e) {
      _logger.error('❌ [CART-MGMT] Failed to update customizations', e);
      return CartOperationResult.failure('Failed to update customizations: $e');
    }
  }

  /// Clear entire cart
  Future<CartOperationResult> clearCart() async {
    try {
      _logger.info('🧹 [CART-MGMT] Clearing cart');

      await _persistenceService.clearCart();

      // Emit events
      _operationController.add(CartOperationEvent.cartCleared());
      _pricingController.add(CartPricingEvent.cleared());

      _logger.info('✅ [CART-MGMT] Cart cleared successfully');
      return CartOperationResult.success(EnhancedCartState.empty());

    } catch (e) {
      _logger.error('❌ [CART-MGMT] Failed to clear cart', e);
      return CartOperationResult.failure('Failed to clear cart: $e');
    }
  }

  /// Apply promo code
  Future<CartOperationResult> applyPromoCode(String promoCode) async {
    try {
      _logger.info('🎫 [CART-MGMT] Applying promo code: $promoCode');

      // Load current cart
      final loadResult = await _persistenceService.loadCart();
      if (!loadResult.isSuccess || loadResult.cartState == null) {
        return CartOperationResult.failure('Cart not found');
      }

      final currentCart = loadResult.cartState!;

      // TODO: Implement promo code validation and discount calculation
      // For now, we'll just recalculate the cart with the promo code

      // Recalculate summary with promo code
      final summary = await _cartService.calculateCartSummary(
        items: currentCart.items,
        deliveryMethod: currentCart.deliveryMethod,
        deliveryAddress: currentCart.selectedAddress,
        scheduledTime: currentCart.scheduledDeliveryTime,
        promoCode: promoCode,
      );

      final updatedCart = currentCart.copyWith(
        summary: summary,
        metadata: {...(currentCart.metadata ?? {}), 'promoCode': promoCode},
      );

      // Save cart
      final saveResult = await _persistenceService.saveCart(updatedCart);
      if (!saveResult.isSuccess) {
        return CartOperationResult.failure('Failed to save cart: ${saveResult.error}');
      }

      // Emit events
      _operationController.add(CartOperationEvent.promoApplied(promoCode));
      _pricingController.add(CartPricingEvent.updated(summary));

      _logger.info('✅ [CART-MGMT] Promo code applied successfully');
      return CartOperationResult.success(updatedCart);

    } catch (e) {
      _logger.error('❌ [CART-MGMT] Failed to apply promo code', e);
      return CartOperationResult.failure('Failed to apply promo code: $e');
    }
  }

  /// Validate menu item for cart addition
  Future<CartValidationResult> _validateMenuItem(
    MenuItem menuItem,
    int quantity,
    Map<String, dynamic>? customizations,
  ) async {
    final errors = <String>[];

    // Check if item is available
    if (menuItem.status != MenuItemStatus.available) {
      errors.add('${menuItem.name} is currently unavailable');
    }

    // Check quantity limits
    if (!menuItem.isValidQuantity(quantity)) {
      errors.add('Invalid quantity for ${menuItem.name}. Min: ${menuItem.minimumOrderQuantity}');
    }

    // Validate required customizations
    for (final customization in menuItem.customizations) {
      if (customization.isRequired) {
        final selectedValue = customizations?[customization.id];
        if (selectedValue == null || 
            (selectedValue is String && selectedValue.isEmpty) ||
            (selectedValue is List && selectedValue.isEmpty)) {
          errors.add('${customization.name} is required');
        }
      }
    }

    return errors.isEmpty
        ? CartValidationResult.valid()
        : CartValidationResult.invalid(errors);
  }

  /// Calculate item pricing with customizations
  Future<ItemPricingResult> _calculateItemPricing(
    MenuItem menuItem,
    int quantity,
    Map<String, dynamic>? customizations,
  ) async {
    // Get base price for quantity (considering bulk pricing)
    final basePrice = menuItem.getEffectivePrice(quantity);

    // Calculate customization cost
    double customizationCost = 0.0;
    if (customizations != null) {
      for (final customization in menuItem.customizations) {
        final selectedValue = customizations[customization.id];
        if (selectedValue != null) {
          // Add customization base cost
          if (customization.additionalCost != null) {
            customizationCost += customization.additionalCost!;
          }

          // Add option costs
          for (final option in customization.options) {
            if (selectedValue is List && selectedValue.contains(option.id)) {
              customizationCost += option.additionalCost;
            } else if (selectedValue == option.id) {
              customizationCost += option.additionalCost;
            }
          }
        }
      }
    }

    final unitPrice = basePrice + customizationCost;
    final totalPrice = unitPrice * quantity;

    return ItemPricingResult(
      basePrice: basePrice,
      customizationCost: customizationCost,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
    );
  }

  /// Check for cart conflicts
  Future<CartValidationResult> _checkCartConflicts(
    EnhancedCartState currentCart,
    MenuItem newItem,
  ) async {
    final errors = <String>[];

    // Check for multi-vendor conflict
    if (currentCart.isNotEmpty && currentCart.hasMultipleVendors) {
      final existingVendorIds = currentCart.itemsByVendor.keys.toSet();
      if (!existingVendorIds.contains(newItem.vendorId)) {
        errors.add('Cannot add items from different vendors. Please checkout current items first.');
      }
    }

    return errors.isEmpty
        ? CartValidationResult.valid()
        : CartValidationResult.invalid(errors);
  }

  /// Validate quantity limits
  Future<CartValidationResult> _validateQuantity(MenuItem menuItem, int quantity) async {
    final errors = <String>[];

    if (!menuItem.isValidQuantity(quantity)) {
      if (quantity < menuItem.minimumOrderQuantity) {
        errors.add('Minimum quantity is ${menuItem.minimumOrderQuantity}');
      }
      if (menuItem.maximumOrderQuantity != null && quantity > menuItem.maximumOrderQuantity!) {
        errors.add('Maximum quantity is ${menuItem.maximumOrderQuantity}');
      }
      if (menuItem.availableQuantity != null && quantity > menuItem.availableQuantity!) {
        errors.add('Only ${menuItem.availableQuantity} items available');
      }
    }

    return errors.isEmpty
        ? CartValidationResult.valid()
        : CartValidationResult.invalid(errors);
  }

  /// Generate unique cart item ID
  String _generateCartItemId(String productId, Map<String, dynamic>? customizations) {
    final customizationHash = customizations?.toString().hashCode ?? 0;
    return '${productId}_$customizationHash';
  }

  /// Dispose resources
  void dispose() {
    _operationController.close();
    _pricingController.close();
  }
}

/// Item pricing result
class ItemPricingResult {
  final double basePrice;
  final double customizationCost;
  final double unitPrice;
  final double totalPrice;

  ItemPricingResult({
    required this.basePrice,
    required this.customizationCost,
    required this.unitPrice,
    required this.totalPrice,
  });
}

/// Cart operation result
class CartOperationResult {
  final bool isSuccess;
  final String? error;
  final EnhancedCartState? cartState;
  final ItemPricingResult? pricingResult;
  final List<String>? conflicts;

  CartOperationResult._(this.isSuccess, this.error, this.cartState, this.pricingResult, this.conflicts);

  factory CartOperationResult.success(EnhancedCartState cartState) =>
      CartOperationResult._(true, null, cartState, null, null);
  
  factory CartOperationResult.failure(String error) =>
      CartOperationResult._(false, error, null, null, null);
  
  factory CartOperationResult.validation(ItemPricingResult pricingResult) =>
      CartOperationResult._(true, null, null, pricingResult, null);
  
  factory CartOperationResult.conflict(List<String> conflicts) =>
      CartOperationResult._(false, 'Conflicts detected', null, null, conflicts);
}

/// Cart operation events
abstract class CartOperationEvent {
  const CartOperationEvent();

  factory CartOperationEvent.itemAdded(EnhancedCartItem item) = CartItemAddedEvent;
  factory CartOperationEvent.itemRemoved(EnhancedCartItem item) = CartItemRemovedEvent;
  factory CartOperationEvent.itemUpdated(EnhancedCartItem item) = CartItemUpdatedEvent;
  factory CartOperationEvent.cartCleared() = CartClearedEvent;
  factory CartOperationEvent.promoApplied(String promoCode) = CartPromoAppliedEvent;
}

class CartItemAddedEvent extends CartOperationEvent {
  final EnhancedCartItem item;
  const CartItemAddedEvent(this.item);
}

class CartItemRemovedEvent extends CartOperationEvent {
  final EnhancedCartItem item;
  const CartItemRemovedEvent(this.item);
}

class CartItemUpdatedEvent extends CartOperationEvent {
  final EnhancedCartItem item;
  const CartItemUpdatedEvent(this.item);
}

class CartClearedEvent extends CartOperationEvent {
  const CartClearedEvent();
}

class CartPromoAppliedEvent extends CartOperationEvent {
  final String promoCode;
  const CartPromoAppliedEvent(this.promoCode);
}

/// Cart pricing events
abstract class CartPricingEvent {
  const CartPricingEvent();

  factory CartPricingEvent.updated(CartSummary summary) = CartPricingUpdatedEvent;
  factory CartPricingEvent.cleared() = CartPricingClearedEvent;
}

class CartPricingUpdatedEvent extends CartPricingEvent {
  final CartSummary summary;
  const CartPricingUpdatedEvent(this.summary);
}

class CartPricingClearedEvent extends CartPricingEvent {
  const CartPricingClearedEvent();
}

/// Cart management service provider
final cartManagementServiceProvider = Provider<CartManagementService>((ref) {
  final persistenceService = ref.watch(cartPersistenceServiceProvider);
  final cartService = ref.watch(enhancedCartServiceProvider);
  return CartManagementService(persistenceService, cartService);
});

/// Enhanced cart service provider
final enhancedCartServiceProvider = Provider<EnhancedCartService>((ref) {
  return EnhancedCartService();
});
