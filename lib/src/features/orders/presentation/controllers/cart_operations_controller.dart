import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enhanced_cart_models.dart';

import '../../../menu/data/models/menu_item.dart';

import '../../../core/utils/logger.dart';
import '../../data/services/cart_management_service.dart';
import '../providers/enhanced_cart_provider.dart';

/// Cart operations controller for managing cart state and operations
class CartOperationsController extends StateNotifier<CartOperationsState> {
  final CartManagementService _cartManagementService;
  final EnhancedCartNotifier _cartNotifier;
  final AppLogger _logger = AppLogger();

  StreamSubscription<CartOperationEvent>? _operationSubscription;
  StreamSubscription<CartPricingEvent>? _pricingSubscription;

  CartOperationsController(this._cartManagementService, this._cartNotifier) 
      : super(const CartOperationsState()) {
    _initializeSubscriptions();
  }

  /// Initialize event subscriptions
  void _initializeSubscriptions() {
    // Listen to cart operation events
    _operationSubscription = _cartManagementService.operationEvents.listen(
      (event) => _handleOperationEvent(event),
      onError: (error) => _logger.error('Cart operation event error', error),
    );

    // Listen to pricing events
    _pricingSubscription = _cartManagementService.pricingEvents.listen(
      (event) => _handlePricingEvent(event),
      onError: (error) => _logger.error('Cart pricing event error', error),
    );
  }

  /// Add menu item to cart with validation
  Future<void> addMenuItem({
    required MenuItem menuItem,
    required String vendorName,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🛒 [CART-OPS] Adding menu item: ${menuItem.name}');

      final result = await _cartManagementService.addMenuItem(
        menuItem: menuItem,
        vendorName: vendorName,
        quantity: quantity,
        customizations: customizations,
        notes: notes,
      );

      if (result.isSuccess && result.cartState != null) {
        // Update the cart notifier with the new state
        _cartNotifier.state = result.cartState!;
        
        state = state.copyWith(
          isLoading: false,
          lastOperation: CartOperation.add,
          lastOperationSuccess: true,
        );

        _logger.info('✅ [CART-OPS] Menu item added successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          lastOperation: CartOperation.add,
          lastOperationSuccess: false,
        );

        _logger.error('❌ [CART-OPS] Failed to add menu item: ${result.error}');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastOperation: CartOperation.add,
        lastOperationSuccess: false,
      );

      _logger.error('❌ [CART-OPS] Exception adding menu item', e);
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🗑️ [CART-OPS] Removing item: $itemId');

      final result = await _cartManagementService.removeItem(itemId);

      if (result.isSuccess && result.cartState != null) {
        _cartNotifier.state = result.cartState!;
        
        state = state.copyWith(
          isLoading: false,
          lastOperation: CartOperation.remove,
          lastOperationSuccess: true,
        );

        _logger.info('✅ [CART-OPS] Item removed successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          lastOperation: CartOperation.remove,
          lastOperationSuccess: false,
        );

        _logger.error('❌ [CART-OPS] Failed to remove item: ${result.error}');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastOperation: CartOperation.remove,
        lastOperationSuccess: false,
      );

      _logger.error('❌ [CART-OPS] Exception removing item', e);
    }
  }

  /// Update item quantity
  Future<void> updateItemQuantity(String itemId, int newQuantity) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('📝 [CART-OPS] Updating quantity: $itemId to $newQuantity');

      final result = await _cartManagementService.updateItemQuantity(itemId, newQuantity);

      if (result.isSuccess && result.cartState != null) {
        _cartNotifier.state = result.cartState!;
        
        state = state.copyWith(
          isLoading: false,
          lastOperation: CartOperation.updateQuantity,
          lastOperationSuccess: true,
        );

        _logger.info('✅ [CART-OPS] Quantity updated successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          lastOperation: CartOperation.updateQuantity,
          lastOperationSuccess: false,
        );

        _logger.error('❌ [CART-OPS] Failed to update quantity: ${result.error}');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastOperation: CartOperation.updateQuantity,
        lastOperationSuccess: false,
      );

      _logger.error('❌ [CART-OPS] Exception updating quantity', e);
    }
  }

  /// Update item customizations
  Future<void> updateItemCustomizations(
    String itemId,
    Map<String, dynamic> newCustomizations,
  ) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🎨 [CART-OPS] Updating customizations: $itemId');

      final result = await _cartManagementService.updateItemCustomizations(
        itemId,
        newCustomizations,
      );

      if (result.isSuccess && result.cartState != null) {
        _cartNotifier.state = result.cartState!;
        
        state = state.copyWith(
          isLoading: false,
          lastOperation: CartOperation.updateCustomizations,
          lastOperationSuccess: true,
        );

        _logger.info('✅ [CART-OPS] Customizations updated successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          lastOperation: CartOperation.updateCustomizations,
          lastOperationSuccess: false,
        );

        _logger.error('❌ [CART-OPS] Failed to update customizations: ${result.error}');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastOperation: CartOperation.updateCustomizations,
        lastOperationSuccess: false,
      );

      _logger.error('❌ [CART-OPS] Exception updating customizations', e);
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🧹 [CART-OPS] Clearing cart');

      final result = await _cartManagementService.clearCart();

      if (result.isSuccess && result.cartState != null) {
        _cartNotifier.state = result.cartState!;
        
        state = state.copyWith(
          isLoading: false,
          lastOperation: CartOperation.clear,
          lastOperationSuccess: true,
        );

        _logger.info('✅ [CART-OPS] Cart cleared successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          lastOperation: CartOperation.clear,
          lastOperationSuccess: false,
        );

        _logger.error('❌ [CART-OPS] Failed to clear cart: ${result.error}');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastOperation: CartOperation.clear,
        lastOperationSuccess: false,
      );

      _logger.error('❌ [CART-OPS] Exception clearing cart', e);
    }
  }

  /// Apply promo code
  Future<void> applyPromoCode(String promoCode) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      _logger.info('🎫 [CART-OPS] Applying promo code: $promoCode');

      final result = await _cartManagementService.applyPromoCode(promoCode);

      if (result.isSuccess && result.cartState != null) {
        _cartNotifier.state = result.cartState!;
        
        state = state.copyWith(
          isLoading: false,
          lastOperation: CartOperation.applyPromo,
          lastOperationSuccess: true,
          appliedPromoCode: promoCode,
        );

        _logger.info('✅ [CART-OPS] Promo code applied successfully');
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.error,
          lastOperation: CartOperation.applyPromo,
          lastOperationSuccess: false,
        );

        _logger.error('❌ [CART-OPS] Failed to apply promo code: ${result.error}');
      }

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        lastOperation: CartOperation.applyPromo,
        lastOperationSuccess: false,
      );

      _logger.error('❌ [CART-OPS] Exception applying promo code', e);
    }
  }

  /// Validate cart item before adding
  Future<ItemPricingResult?> validateMenuItem({
    required MenuItem menuItem,
    int quantity = 1,
    Map<String, dynamic>? customizations,
  }) async {
    try {
      _logger.info('✅ [CART-OPS] Validating menu item: ${menuItem.name}');

      final result = await _cartManagementService.addMenuItem(
        menuItem: menuItem,
        vendorName: '', // Not needed for validation
        quantity: quantity,
        customizations: customizations,
        validateOnly: true,
      );

      if (result.isSuccess && result.pricingResult != null) {
        _logger.info('✅ [CART-OPS] Menu item validation successful');
        return result.pricingResult;
      } else {
        _logger.warning('⚠️ [CART-OPS] Menu item validation failed: ${result.error}');
        return null;
      }

    } catch (e) {
      _logger.error('❌ [CART-OPS] Exception validating menu item', e);
      return null;
    }
  }

  /// Handle cart operation events
  void _handleOperationEvent(CartOperationEvent event) {
    switch (event.runtimeType) {
      case CartItemAddedEvent _:
        final addedEvent = event as CartItemAddedEvent;
        state = state.copyWith(
          lastAddedItem: addedEvent.item,
          operationHistory: [...state.operationHistory, event],
        );
        break;
      
      case CartItemRemovedEvent _:
        final removedEvent = event as CartItemRemovedEvent;
        state = state.copyWith(
          lastRemovedItem: removedEvent.item,
          operationHistory: [...state.operationHistory, event],
        );
        break;
      
      case CartItemUpdatedEvent _:
        final updatedEvent = event as CartItemUpdatedEvent;
        state = state.copyWith(
          lastUpdatedItem: updatedEvent.item,
          operationHistory: [...state.operationHistory, event],
        );
        break;
      
      case CartClearedEvent _:
        state = state.copyWith(
          lastAddedItem: null,
          lastRemovedItem: null,
          lastUpdatedItem: null,
          appliedPromoCode: null,
          operationHistory: [...state.operationHistory, event],
        );
        break;
      
      case CartPromoAppliedEvent _:
        final promoEvent = event as CartPromoAppliedEvent;
        state = state.copyWith(
          appliedPromoCode: promoEvent.promoCode,
          operationHistory: [...state.operationHistory, event],
        );
        break;
    }
  }

  /// Handle cart pricing events
  void _handlePricingEvent(CartPricingEvent event) {
    switch (event.runtimeType) {
      case CartPricingUpdatedEvent _:
        final updatedEvent = event as CartPricingUpdatedEvent;
        state = state.copyWith(lastPricingUpdate: updatedEvent.summary);
        break;
      
      case CartPricingClearedEvent _:
        state = state.copyWith(lastPricingUpdate: null);
        break;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear operation history
  void clearOperationHistory() {
    state = state.copyWith(operationHistory: []);
  }

  @override
  void dispose() {
    _operationSubscription?.cancel();
    _pricingSubscription?.cancel();
    super.dispose();
  }
}

/// Cart operations state
class CartOperationsState {
  final bool isLoading;
  final String? error;
  final CartOperation? lastOperation;
  final bool lastOperationSuccess;
  final EnhancedCartItem? lastAddedItem;
  final EnhancedCartItem? lastRemovedItem;
  final EnhancedCartItem? lastUpdatedItem;
  final String? appliedPromoCode;
  final CartSummary? lastPricingUpdate;
  final List<CartOperationEvent> operationHistory;

  const CartOperationsState({
    this.isLoading = false,
    this.error,
    this.lastOperation,
    this.lastOperationSuccess = false,
    this.lastAddedItem,
    this.lastRemovedItem,
    this.lastUpdatedItem,
    this.appliedPromoCode,
    this.lastPricingUpdate,
    this.operationHistory = const [],
  });

  CartOperationsState copyWith({
    bool? isLoading,
    String? error,
    CartOperation? lastOperation,
    bool? lastOperationSuccess,
    EnhancedCartItem? lastAddedItem,
    EnhancedCartItem? lastRemovedItem,
    EnhancedCartItem? lastUpdatedItem,
    String? appliedPromoCode,
    CartSummary? lastPricingUpdate,
    List<CartOperationEvent>? operationHistory,
  }) {
    return CartOperationsState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastOperation: lastOperation ?? this.lastOperation,
      lastOperationSuccess: lastOperationSuccess ?? this.lastOperationSuccess,
      lastAddedItem: lastAddedItem ?? this.lastAddedItem,
      lastRemovedItem: lastRemovedItem ?? this.lastRemovedItem,
      lastUpdatedItem: lastUpdatedItem ?? this.lastUpdatedItem,
      appliedPromoCode: appliedPromoCode ?? this.appliedPromoCode,
      lastPricingUpdate: lastPricingUpdate ?? this.lastPricingUpdate,
      operationHistory: operationHistory ?? this.operationHistory,
    );
  }
}

/// Cart operation types
enum CartOperation {
  add,
  remove,
  updateQuantity,
  updateCustomizations,
  clear,
  applyPromo,
}

/// Cart operations controller provider
final cartOperationsControllerProvider = StateNotifierProvider<CartOperationsController, CartOperationsState>((ref) {
  final cartManagementService = ref.watch(cartManagementServiceProvider);
  final cartNotifier = ref.read(enhancedCartProvider.notifier);
  return CartOperationsController(cartManagementService, cartNotifier);
});

/// Convenience providers for cart operations
final isCartOperationLoadingProvider = Provider<bool>((ref) {
  return ref.watch(cartOperationsControllerProvider).isLoading;
});

final cartOperationErrorProvider = Provider<String?>((ref) {
  return ref.watch(cartOperationsControllerProvider).error;
});

final lastCartOperationProvider = Provider<CartOperation?>((ref) {
  return ref.watch(cartOperationsControllerProvider).lastOperation;
});

final appliedPromoCodeProvider = Provider<String?>((ref) {
  return ref.watch(cartOperationsControllerProvider).appliedPromoCode;
});
