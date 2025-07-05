import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/enhanced_cart_models.dart';
import '../../data/models/customer_delivery_method.dart';
import '../../../menu/data/models/menu_item.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import '../../../core/constants/app_constants.dart';
import '../../data/services/delivery_fee_service.dart';
import '../../data/services/cart_persistence_service.dart';

/// Enhanced cart state notifier with comprehensive ordering workflow support
class EnhancedCartNotifier extends StateNotifier<EnhancedCartState> {
  final AppLogger _logger = AppLogger();
  final DeliveryFeeService _deliveryFeeService = DeliveryFeeService();
  final CartPersistenceService _persistenceService;

  EnhancedCartNotifier(this._persistenceService) : super(EnhancedCartState.empty()) {
    _loadPersistedCart();
  }

  /// Add menu item to cart with customizations
  Future<void> addMenuItem({
    required MenuItem menuItem,
    required String vendorName,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
  }) async {
    try {
      _logger.info('🛒 [ENHANCED-CART] Adding menu item: ${menuItem.name} (qty: $quantity)');

      // Calculate customization cost
      final customizationCost = _calculateCustomizationCost(menuItem, customizations);
      final unitPrice = menuItem.basePrice + customizationCost;

      // Generate unique ID based on product and customizations
      final cartItemId = _generateCartItemId(menuItem.id, customizations);

      // Check if item already exists
      final existingItemIndex = state.items.indexWhere((item) => item.id == cartItemId);

      List<EnhancedCartItem> updatedItems;

      if (existingItemIndex >= 0) {
        // Update existing item quantity
        final existingItem = state.items[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;

        // Validate quantity limits
        if (existingItem.maxQuantity != null && newQuantity > existingItem.maxQuantity!) {
          throw Exception('Maximum quantity (${existingItem.maxQuantity}) exceeded for ${menuItem.name}');
        }

        final updatedItem = existingItem.copyWith(quantity: newQuantity);
        updatedItems = List<EnhancedCartItem>.from(state.items);
        updatedItems[existingItemIndex] = updatedItem;

        _logger.info('✅ [ENHANCED-CART] Updated existing item quantity to $newQuantity');
      } else {
        // Add new item
        final newItem = EnhancedCartItem(
          id: cartItemId,
          productId: menuItem.id,
          name: menuItem.name,
          description: menuItem.description,
          basePrice: menuItem.basePrice,
          unitPrice: unitPrice,
          quantity: quantity,
          imageUrl: menuItem.imageUrls.isNotEmpty ? menuItem.imageUrls.first : null,
          customizations: customizations,
          customizationCost: customizationCost,
          notes: notes,
          vendorId: menuItem.vendorId,
          vendorName: vendorName,
          addedAt: DateTime.now(),
          isAvailable: menuItem.status == MenuItemStatus.available,
          maxQuantity: menuItem.maximumOrderQuantity,
          minQuantity: menuItem.minimumOrderQuantity,
        );

        updatedItems = [...state.items, newItem];
        _logger.info('✅ [ENHANCED-CART] Added new item to cart');
      }

      // Update state and recalculate
      await _updateCartState(updatedItems);

    } catch (e) {
      _logger.error('❌ [ENHANCED-CART] Error adding menu item', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove item from cart
  Future<void> removeItem(String itemId) async {
    try {
      _logger.info('🗑️ [ENHANCED-CART] Removing item: $itemId');

      final updatedItems = state.items.where((item) => item.id != itemId).toList();
      await _updateCartState(updatedItems);

      _logger.info('✅ [ENHANCED-CART] Item removed successfully');
    } catch (e) {
      _logger.error('❌ [ENHANCED-CART] Error removing item', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update item quantity
  Future<void> updateItemQuantity(String itemId, int quantity) async {
    try {
      if (quantity <= 0) {
        await removeItem(itemId);
        return;
      }

      _logger.info('📝 [ENHANCED-CART] Updating item quantity: $itemId to $quantity');

      final itemIndex = state.items.indexWhere((item) => item.id == itemId);
      if (itemIndex < 0) {
        throw Exception('Item not found in cart');
      }

      final item = state.items[itemIndex];

      // Validate quantity limits
      if (quantity < item.minQuantity) {
        throw Exception('Minimum quantity is ${item.minQuantity}');
      }
      if (item.maxQuantity != null && quantity > item.maxQuantity!) {
        throw Exception('Maximum quantity is ${item.maxQuantity}');
      }

      final updatedItem = item.copyWith(quantity: quantity);
      final updatedItems = List<EnhancedCartItem>.from(state.items);
      updatedItems[itemIndex] = updatedItem;

      await _updateCartState(updatedItems);

      _logger.info('✅ [ENHANCED-CART] Quantity updated successfully');
    } catch (e) {
      _logger.error('❌ [ENHANCED-CART] Error updating quantity', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear entire cart
  Future<void> clearCart() async {
    try {
      _logger.info('🧹 [ENHANCED-CART] Clearing cart');
      await _updateCartState([]);
      _logger.info('✅ [ENHANCED-CART] Cart cleared successfully');
    } catch (e) {
      _logger.error('❌ [ENHANCED-CART] Error clearing cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set delivery method
  Future<void> setDeliveryMethod(CustomerDeliveryMethod method) async {
    try {
      _logger.info('🚚 [ENHANCED-CART] Setting delivery method: ${method.value}');
      
      state = state.copyWith(deliveryMethod: method);
      await _recalculateCartSummary();
      await _persistCart();

      _logger.info('✅ [ENHANCED-CART] Delivery method updated');
    } catch (e) {
      _logger.error('❌ [ENHANCED-CART] Error setting delivery method', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set delivery address
  void setDeliveryAddress(CustomerAddress address) {
    _logger.info('📍 [ENHANCED-CART] Setting delivery address');
    state = state.copyWith(selectedAddress: address);
    _persistCart();
  }

  /// Set scheduled delivery time
  void setScheduledDeliveryTime(DateTime? dateTime) {
    _logger.info('⏰ [ENHANCED-CART] Setting scheduled delivery time: $dateTime');
    state = state.copyWith(scheduledDeliveryTime: dateTime);
    _persistCart();
  }

  /// Set special instructions
  void setSpecialInstructions(String? instructions) {
    _logger.info('📝 [ENHANCED-CART] Setting special instructions');
    state = state.copyWith(specialInstructions: instructions);
    _persistCart();
  }

  /// Set payment method
  void setPaymentMethod(String? paymentMethod) {
    _logger.info('💳 [ENHANCED-CART] Setting payment method: $paymentMethod');
    state = state.copyWith(selectedPaymentMethod: paymentMethod);
    _persistCart();
  }

  /// Validate cart for checkout
  Future<CartValidationResult> validateCart() async {
    try {
      _logger.info('✅ [ENHANCED-CART] Validating cart for checkout');

      final errors = <String>[];
      final warnings = <String>[];

      // Basic validation
      if (state.isEmpty) {
        errors.add('Cart is empty');
      }

      // Multi-vendor validation
      if (state.hasMultipleVendors) {
        errors.add('Cart contains items from multiple vendors. Please checkout separately.');
      }

      // Minimum order amount validation
      if (state.subtotal < AppConstants.minOrderAmount) {
        errors.add('Minimum order amount is RM ${AppConstants.minOrderAmount.toStringAsFixed(2)}');
      }

      // Delivery method validation
      if (state.deliveryMethod.requiresDriver && state.selectedAddress == null) {
        errors.add('Delivery address is required');
      }

      // Payment method validation
      if (state.selectedPaymentMethod == null) {
        errors.add('Payment method is required');
      }

      // Item availability validation
      final unavailableItems = state.items.where((item) => !item.isAvailable).toList();
      if (unavailableItems.isNotEmpty) {
        errors.add('Some items are no longer available');
      }

      // Scheduled delivery validation
      if (state.deliveryMethod == CustomerDeliveryMethod.scheduled) {
        if (state.scheduledDeliveryTime == null) {
          errors.add('Scheduled delivery time is required');
        } else if (state.scheduledDeliveryTime!.isBefore(DateTime.now().add(const Duration(hours: 2)))) {
          errors.add('Scheduled delivery must be at least 2 hours in advance');
        }
      }

      final result = errors.isEmpty 
          ? CartValidationResult.valid()
          : CartValidationResult.invalid(errors, warnings: warnings);

      state = state.copyWith(validationResult: result);
      return result;

    } catch (e) {
      _logger.error('❌ [ENHANCED-CART] Error validating cart', e);
      final result = CartValidationResult.invalid(['Validation error: ${e.toString()}']);
      state = state.copyWith(validationResult: result);
      return result;
    }
  }

  /// Calculate customization cost for menu item including template-based customizations
  double _calculateCustomizationCost(MenuItem menuItem, Map<String, dynamic>? customizations) {
    if (customizations == null || customizations.isEmpty) return 0.0;

    double totalCost = 0.0;

    // Calculate cost from direct customizations
    for (final customization in menuItem.customizations) {
      final selectedValue = customizations[customization.id];
      if (selectedValue != null) {
        // Add customization cost if any
        if (customization.additionalCost != null) {
          totalCost += customization.additionalCost!;
        }

        // Add option costs
        for (final option in customization.options) {
          if (selectedValue is List && selectedValue.contains(option.id)) {
            totalCost += option.additionalCost;
          } else if (selectedValue == option.id) {
            totalCost += option.additionalCost;
          }
        }
      }
    }

    // Calculate cost from template-based customizations
    for (final template in menuItem.linkedTemplates) {
      final selectedValue = customizations[template.id];
      if (selectedValue != null) {
        totalCost += _calculateSelectionCost(selectedValue);
      }
    }

    return totalCost;
  }

  /// Helper method to calculate cost from a selection value
  double _calculateSelectionCost(dynamic selectedValue) {
    double cost = 0.0;

    if (selectedValue is Map<String, dynamic>) {
      // Single selection
      final price = selectedValue['price'];
      if (price is num) {
        cost += price.toDouble();
      }
    } else if (selectedValue is List) {
      // Multiple selections
      for (final item in selectedValue) {
        if (item is Map<String, dynamic>) {
          final price = item['price'];
          if (price is num) {
            cost += price.toDouble();
          }
        }
      }
    }

    return cost;
  }

  /// Generate unique cart item ID
  String _generateCartItemId(String productId, Map<String, dynamic>? customizations) {
    final customizationHash = customizations?.toString().hashCode ?? 0;
    return '${productId}_$customizationHash';
  }

  /// Update cart state and recalculate
  Future<void> _updateCartState(List<EnhancedCartItem> items) async {
    state = state.copyWith(items: items, isLoading: true);
    await _recalculateCartSummary();
    await _persistCart();
    state = state.copyWith(isLoading: false);
  }

  /// Recalculate cart summary with delivery fees
  Future<void> _recalculateCartSummary() async {
    try {
      if (state.isEmpty) {
        state = state.copyWith(summary: null);
        return;
      }

      final subtotal = state.subtotal;
      final customizationTotal = state.customizationTotal;
      
      // Calculate delivery fee
      double deliveryFee = 0.0;
      if (state.items.isNotEmpty) {
        final primaryVendorId = state.primaryVendorId!;
        
        try {
          final deliveryFeeResult = await _deliveryFeeService.calculateDeliveryFee(
            deliveryMethod: _mapToDeliveryMethod(state.deliveryMethod),
            vendorId: primaryVendorId,
            subtotal: subtotal,
            deliveryLatitude: state.selectedAddress?.latitude,
            deliveryLongitude: state.selectedAddress?.longitude,
            deliveryTime: state.scheduledDeliveryTime,
          );
          deliveryFee = deliveryFeeResult.finalFee;
        } catch (e) {
          _logger.warning('Failed to calculate delivery fee, using default: $e');
          deliveryFee = _calculateDefaultDeliveryFee(state.deliveryMethod);
        }
      }

      final sstAmount = (subtotal + deliveryFee) * AppConstants.sstRate;
      final totalAmount = subtotal + deliveryFee + sstAmount;

      // Calculate vendor subtotals
      final vendorSubtotals = <String, double>{};
      for (final entry in state.itemsByVendor.entries) {
        vendorSubtotals[entry.key] = entry.value.fold(0.0, (sum, item) => sum + item.totalPrice);
      }

      final summary = CartSummary(
        subtotal: subtotal,
        customizationTotal: customizationTotal,
        deliveryFee: deliveryFee,
        sstAmount: sstAmount,
        discountAmount: 0.0, // TODO: Implement discount logic
        totalAmount: totalAmount,
        totalItems: state.totalItems,
        totalQuantity: state.totalQuantity,
        vendorSubtotals: vendorSubtotals,
        calculatedAt: DateTime.now(),
      );

      state = state.copyWith(summary: summary);

    } catch (e) {
      _logger.error('❌ [ENHANCED-CART] Error recalculating summary', e);
    }
  }

  /// Map CustomerDeliveryMethod to DeliveryMethod for service calls
  dynamic _mapToDeliveryMethod(CustomerDeliveryMethod method) {
    // This is a temporary mapping - in a real implementation, 
    // you'd want to use a proper enum mapping
    switch (method) {
      case CustomerDeliveryMethod.customerPickup:
      case CustomerDeliveryMethod.pickup:
        return 'customer_pickup';
      case CustomerDeliveryMethod.salesAgentPickup:
        return 'sales_agent_pickup';
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.delivery:
        return 'own_fleet';
      default:
        return 'own_fleet';
    }
  }

  /// Load persisted cart from storage
  Future<void> _loadPersistedCart() async {
    try {
      final loadResult = await _persistenceService.loadCart();

      if (loadResult.isSuccess && loadResult.cartState != null) {
        state = loadResult.cartState!;
        _logger.info('📱 [ENHANCED-CART] Loaded persisted cart with ${state.items.length} items');
      } else if (loadResult.error != null) {
        _logger.warning('Failed to load persisted cart: ${loadResult.error}');
      }
    } catch (e) {
      _logger.warning('Failed to load persisted cart: $e');
    }
  }

  /// Persist cart to storage
  Future<void> _persistCart() async {
    try {
      final saveResult = await _persistenceService.saveCart(state);

      if (saveResult.isSuccess) {
        _logger.debug('💾 [ENHANCED-CART] Cart persisted to storage');
      } else {
        _logger.warning('Failed to persist cart: ${saveResult.error}');
      }
    } catch (e) {
      _logger.warning('Failed to persist cart: $e');
    }
  }

  /// Calculate default delivery fee based on delivery method
  double _calculateDefaultDeliveryFee(CustomerDeliveryMethod method) {
    switch (method) {
      case CustomerDeliveryMethod.pickup:
      case CustomerDeliveryMethod.customerPickup:
        return 0.0;
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.ownFleet:
      case CustomerDeliveryMethod.lalamove:
      case CustomerDeliveryMethod.thirdParty:
        return 5.0; // Default delivery fee
      case CustomerDeliveryMethod.scheduled:
        return 7.0; // Slightly higher for scheduled delivery
      case CustomerDeliveryMethod.salesAgentPickup:
        return 3.0; // Reduced fee for sales agent pickup
    }
  }
}

/// Enhanced cart provider
final enhancedCartProvider = StateNotifierProvider<EnhancedCartNotifier, EnhancedCartState>((ref) {
  final persistenceService = ref.watch(cartPersistenceServiceProvider);
  return EnhancedCartNotifier(persistenceService);
});

/// Convenience providers for cart data
final cartItemsProvider = Provider<List<EnhancedCartItem>>((ref) {
  return ref.watch(enhancedCartProvider).items;
});

final cartSummaryProvider = Provider<CartSummary?>((ref) {
  return ref.watch(enhancedCartProvider).summary;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(enhancedCartProvider).totalAmount;
});

final cartItemCountProvider = Provider<int>((ref) {
  return ref.watch(enhancedCartProvider).totalItems;
});

final cartValidationProvider = Provider<CartValidationResult?>((ref) {
  return ref.watch(enhancedCartProvider).validationResult;
});

final isCartEmptyProvider = Provider<bool>((ref) {
  return ref.watch(enhancedCartProvider).isEmpty;
});

final isCartReadyForCheckoutProvider = Provider<bool>((ref) {
  return ref.watch(enhancedCartProvider).isReadyForCheckout;
});
