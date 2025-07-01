import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';
import '../cart_provider.dart';
import '../../../../menu/data/models/product.dart';
import '../../../../vendors/data/models/vendor.dart';
import '../../../../menu/data/models/menu_item.dart';
import '../../../../user_management/domain/customer_profile.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../data/models/customer_delivery_method.dart';



/// Customer-specific cart provider that extends the base cart functionality
/// with customer-specific features like address selection and payment methods

// Customer cart state that extends the base cart state
class CustomerCartState {
  final CartState baseCart;
  final CustomerAddress? selectedAddress;
  final CustomerDeliveryMethod deliveryMethod;
  final DateTime? scheduledDeliveryTime;
  final String? specialInstructions;
  final String? selectedPaymentMethod;
  final bool isLoading;
  final String? error;
  final bool isAutoPopulating;
  final bool hasAutoPopulated;

  const CustomerCartState({
    required this.baseCart,
    this.selectedAddress,
    this.deliveryMethod = CustomerDeliveryMethod.customerPickup,
    this.scheduledDeliveryTime,
    this.specialInstructions,
    this.selectedPaymentMethod,
    this.isLoading = false,
    this.error,
    this.isAutoPopulating = false,
    this.hasAutoPopulated = false,
  });

  CustomerCartState copyWith({
    CartState? baseCart,
    CustomerAddress? selectedAddress,
    CustomerDeliveryMethod? deliveryMethod,
    DateTime? scheduledDeliveryTime,
    String? specialInstructions,
    String? selectedPaymentMethod,
    bool? isLoading,
    String? error,
    bool? isAutoPopulating,
    bool? hasAutoPopulated,
  }) {
    return CustomerCartState(
      baseCart: baseCart ?? this.baseCart,
      selectedAddress: selectedAddress ?? this.selectedAddress,
      deliveryMethod: deliveryMethod ?? this.deliveryMethod,
      scheduledDeliveryTime: scheduledDeliveryTime ?? this.scheduledDeliveryTime,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedPaymentMethod: selectedPaymentMethod ?? this.selectedPaymentMethod,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAutoPopulating: isAutoPopulating ?? this.isAutoPopulating,
      hasAutoPopulated: hasAutoPopulated ?? this.hasAutoPopulated,
    );
  }

  // Convenience getters
  List<CartItem> get items => baseCart.items;
  bool get isEmpty => baseCart.isEmpty;
  int get totalItems => baseCart.totalItems;
  double get subtotal => baseCart.subtotal;
  double get sstAmount => baseCart.sstAmount;
  Map<String, List<CartItem>> get itemsByVendor => baseCart.itemsByVendor;
  
  double get deliveryFee {
    // Use the feeMultiplier from the comprehensive enum
    const baseFee = 5.0;
    return baseFee * deliveryMethod.feeMultiplier;
  }
  
  double get totalAmount => subtotal + sstAmount + deliveryFee;
  
  bool get canCheckout {
    if (isEmpty) return false;
    if (deliveryMethod.requiresDriver && selectedAddress == null) return false;
    if (deliveryMethod == CustomerDeliveryMethod.scheduled && scheduledDeliveryTime == null) return false;
    return true;
  }
}

// Customer cart notifier
class CustomerCartNotifier extends StateNotifier<CustomerCartState> {
  final CartNotifier _baseCartNotifier;
  final AppLogger _logger = AppLogger();
  static const String _cartCacheKey = 'customer_cart_cache';

  CustomerCartNotifier(this._baseCartNotifier)
      : super(CustomerCartState(baseCart: _baseCartNotifier.state)) {
    // Listen to base cart changes
    _baseCartNotifier.addListener((baseCart) {
      state = state.copyWith(baseCart: baseCart);
      _persistCart(); // Persist cart changes
    });

    // Load persisted cart on initialization
    _loadPersistedCart();
  }

  /// Add item to cart
  void addItem({
    required Product product,
    required Vendor vendor,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
  }) {
    try {
      _logger.info('🛒 [CART] Adding item to cart: ${product.name} (qty: $quantity) from ${vendor.businessName}');
      _baseCartNotifier.addItem(
        product: product,
        vendor: vendor,
        quantity: quantity,
        customizations: customizations,
        notes: notes,
      );
      _logger.info('✅ [CART] Item added successfully. Cart now has ${state.totalItems} items');
    } catch (e) {
      _logger.error('❌ [CART] Error adding item to customer cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Add menu item to cart
  void addMenuItem({
    required MenuItem menuItem,
    required String vendorName,
    int quantity = 1,
    Map<String, dynamic>? customizations,
    String? notes,
  }) {
    try {
      _logger.info('🛒 [CART] Adding menu item to cart: ${menuItem.name} (qty: $quantity) from $vendorName');
      _baseCartNotifier.addMenuItem(
        menuItem: menuItem,
        vendorName: vendorName,
        quantity: quantity,
        customizations: customizations,
        notes: notes,
      );
      _logger.info('✅ [CART] Menu item added successfully. Cart now has ${state.totalItems} items');
    } catch (e) {
      _logger.error('❌ [CART] Error adding menu item to customer cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update item quantity
  void updateItemQuantity(String itemId, int quantity) {
    try {
      _logger.info('🔄 [CART] Updating item quantity: $itemId to $quantity');
      _baseCartNotifier.updateItemQuantity(itemId, quantity);
      _logger.info('✅ [CART] Item quantity updated. Cart now has ${state.totalItems} items');
    } catch (e) {
      _logger.error('❌ [CART] Error updating item quantity', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    try {
      _logger.info('🗑️ [CART] Removing item from cart: $itemId');
      _baseCartNotifier.removeItem(itemId);
      _logger.info('✅ [CART] Item removed. Cart now has ${state.totalItems} items');
    } catch (e) {
      _logger.error('❌ [CART] Error removing item from cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear cart
  void clearCart() {
    try {
      _logger.info('🧹 [CART] Clearing entire cart');
      _baseCartNotifier.clearCart();
      state = state.copyWith(
        selectedAddress: null,
        scheduledDeliveryTime: null,
        specialInstructions: null,
        selectedPaymentMethod: null,
      );
      _logger.info('✅ [CART] Cart cleared successfully');
    } catch (e) {
      _logger.error('❌ [CART] Error clearing cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set delivery address
  void setDeliveryAddress(CustomerAddress address) {
    debugPrint('🔄 [CART-PROVIDER] ===== SET DELIVERY ADDRESS START =====');
    debugPrint('🔍 [CART-PROVIDER] Current state before setting address:');
    debugPrint('🔍 [CART-PROVIDER] - Current address: ${state.selectedAddress?.label ?? 'null'}');
    debugPrint('🔍 [CART-PROVIDER] - Items count: ${state.items.length}');
    debugPrint('🔍 [CART-PROVIDER] - Delivery method: ${state.deliveryMethod.name}');

    debugPrint('🔍 [CART-PROVIDER] Address to set:');
    debugPrint('🔍 [CART-PROVIDER] - ID: ${address.id}');
    debugPrint('🔍 [CART-PROVIDER] - Label: ${address.label}');
    debugPrint('🔍 [CART-PROVIDER] - Address Line 1: ${address.addressLine1}');
    debugPrint('🔍 [CART-PROVIDER] - City: ${address.city}');
    debugPrint('🔍 [CART-PROVIDER] - Is Default: ${address.isDefault}');

    try {
      state = state.copyWith(selectedAddress: address);

      debugPrint('🔍 [CART-PROVIDER] State updated successfully');
      debugPrint('🔍 [CART-PROVIDER] New state after setting address:');
      debugPrint('🔍 [CART-PROVIDER] - New address: ${state.selectedAddress?.label ?? 'null'}');
      debugPrint('🔍 [CART-PROVIDER] - Address ID: ${state.selectedAddress?.id ?? 'null'}');
      debugPrint('🔍 [CART-PROVIDER] - Items count: ${state.items.length}');

      // Verify the address was actually set
      if (state.selectedAddress != null && state.selectedAddress!.id == address.id) {
        debugPrint('✅ [CART-PROVIDER] Address successfully set and verified');
      } else {
        debugPrint('❌ [CART-PROVIDER] Address setting failed - verification failed');
        debugPrint('❌ [CART-PROVIDER] Expected ID: ${address.id}');
        debugPrint('❌ [CART-PROVIDER] Actual ID: ${state.selectedAddress?.id ?? 'null'}');
      }
    } catch (e, stack) {
      debugPrint('❌ [CART-PROVIDER] Error setting delivery address: $e');
      debugPrint('❌ [CART-PROVIDER] Stack trace: $stack');
    }

    debugPrint('🔄 [CART-PROVIDER] ===== SET DELIVERY ADDRESS END =====');
  }

  /// Clear delivery address (for pickup methods)
  void clearDeliveryAddress() {
    state = state.copyWith(selectedAddress: null);
  }

  /// Set delivery method
  void setDeliveryMethod(CustomerDeliveryMethod method) {
    state = state.copyWith(
      deliveryMethod: method,
      // Clear scheduled time if not scheduled delivery
      scheduledDeliveryTime: method == CustomerDeliveryMethod.scheduled
          ? state.scheduledDeliveryTime
          : null,
    );

    // If the new method requires a driver and we don't have an address,
    // trigger auto-population
    if (method.requiresDriver && state.selectedAddress == null) {
      _autoPopulateAddressForDeliveryMethod(method);
    }
  }

  /// Auto-populate address when delivery method changes to one that requires it
  Future<void> _autoPopulateAddressForDeliveryMethod(CustomerDeliveryMethod method) async {
    try {
      debugPrint('🔄 [CART-PROVIDER] ===== AUTO-POPULATE FOR DELIVERY METHOD START =====');
      debugPrint('🔄 [CART-PROVIDER] Auto-populating address for delivery method: ${method.value}');
      debugPrint('🔄 [CART-PROVIDER] Delivery method changed to: ${method.name}');
      debugPrint('🔄 [CART-PROVIDER] Requires driver: ${method.requiresDriver}');
      debugPrint('🔄 [CART-PROVIDER] Current address: ${state.selectedAddress?.label ?? 'null'}');

      // Set auto-populating state
      setAutoPopulatingState(true);

      // Since we can't access providers directly from a notifier due to circular dependencies,
      // we'll use a simple approach: create mock addresses for testing
      // In a real implementation, this would be handled by the cart screen listening to delivery method changes

      debugPrint('🔄 [CART-PROVIDER] Creating mock address for testing...');

      // Create a mock default address for testing
      final mockAddress = CustomerAddress(
        id: 'mock-default-address',
        label: 'Home (Auto-populated)',
        addressLine1: '123 Main Street',
        city: 'Kuala Lumpur',
        state: 'Selangor',
        postalCode: '50000',
        country: 'Malaysia',
        latitude: 3.1390,
        longitude: 101.6869,
        isDefault: true,
      );

      debugPrint('🔍 [CART-PROVIDER] Mock address to set:');
      debugPrint('🔍 [CART-PROVIDER]   - ID: ${mockAddress.id}');
      debugPrint('🔍 [CART-PROVIDER]   - Label: ${mockAddress.label}');
      debugPrint('🔍 [CART-PROVIDER]   - Address Line 1: ${mockAddress.addressLine1}');
      debugPrint('🔍 [CART-PROVIDER]   - City: ${mockAddress.city}');

      // Set the address in the cart
      debugPrint('🔄 [CART-PROVIDER] Setting mock address in cart...');
      setDeliveryAddress(mockAddress);

      // Verify the address was set
      if (state.selectedAddress != null && state.selectedAddress!.id == mockAddress.id) {
        debugPrint('✅ [CART-PROVIDER] Successfully auto-populated mock address: ${state.selectedAddress!.label}');
        _logger.info('✅ [CART-PROVIDER] Auto-populated mock address for delivery method: ${mockAddress.label}');
      } else {
        debugPrint('❌ [CART-PROVIDER] Failed to set mock address - verification failed');
        debugPrint('❌ [CART-PROVIDER] Expected ID: ${mockAddress.id}');
        debugPrint('❌ [CART-PROVIDER] Actual ID: ${state.selectedAddress?.id ?? 'null'}');
      }

      debugPrint('🔄 [CART-PROVIDER] ===== AUTO-POPULATE FOR DELIVERY METHOD END =====');

    } catch (e, stack) {
      debugPrint('❌ [CART-PROVIDER] Error auto-populating address for delivery method: $e');
      debugPrint('❌ [CART-PROVIDER] Stack trace: $stack');
      _logger.error('❌ [CART-PROVIDER] Error auto-populating address for delivery method', e, stack);
    } finally {
      setAutoPopulatingState(false);
    }
  }

  /// Set scheduled delivery time
  void setScheduledDeliveryTime(DateTime? dateTime) {
    state = state.copyWith(scheduledDeliveryTime: dateTime);
  }

  /// Set special instructions
  void setSpecialInstructions(String? instructions) {
    state = state.copyWith(specialInstructions: instructions);
  }

  /// Set payment method
  void setPaymentMethod(String? paymentMethod) {
    state = state.copyWith(selectedPaymentMethod: paymentMethod);
  }

  /// Set auto-population state
  void setAutoPopulatingState(bool isAutoPopulating) {
    state = state.copyWith(isAutoPopulating: isAutoPopulating);
  }

  /// Mark auto-population as completed
  void markAutoPopulationCompleted() {
    state = state.copyWith(
      isAutoPopulating: false,
      hasAutoPopulated: true,
    );
  }

  /// Reset auto-population state
  void resetAutoPopulationState() {
    state = state.copyWith(
      isAutoPopulating: false,
      hasAutoPopulated: false,
    );
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }



  /// Persist cart to local storage
  Future<void> _persistCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = {
        'items': state.items.map((item) => {
          'id': item.id,
          'productId': item.productId,
          'name': item.name,
          'description': item.description,
          'unitPrice': item.unitPrice,
          'quantity': item.quantity,
          'imageUrl': item.imageUrl,
          'customizations': item.customizations,
          'notes': item.notes,
          'vendorId': item.vendorId,
          'vendorName': item.vendorName,
        }).toList(),
        'selectedAddress': state.selectedAddress?.toJson(),
        'deliveryMethod': state.deliveryMethod.value,
        'scheduledDeliveryTime': state.scheduledDeliveryTime?.toIso8601String(),
        'specialInstructions': state.specialInstructions,
        'selectedPaymentMethod': state.selectedPaymentMethod,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await prefs.setString(_cartCacheKey, jsonEncode(cartData));
      _logger.debug('💾 [CART] Cart persisted to local storage');
    } catch (e) {
      _logger.error('❌ [CART] Error persisting cart', e);
    }
  }

  /// Load persisted cart from local storage
  Future<void> _loadPersistedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartDataString = prefs.getString(_cartCacheKey);

      if (cartDataString != null) {
        final cartData = jsonDecode(cartDataString) as Map<String, dynamic>;
        final timestamp = DateTime.parse(cartData['timestamp'] as String);

        // Only restore cart if it's less than 24 hours old
        if (DateTime.now().difference(timestamp).inHours < 24) {
          // Restore customer-specific cart state
          CustomerAddress? address;
          if (cartData['selectedAddress'] != null) {
            address = CustomerAddress.fromJson(cartData['selectedAddress']);
          }

          DateTime? scheduledTime;
          if (cartData['scheduledDeliveryTime'] != null) {
            scheduledTime = DateTime.parse(cartData['scheduledDeliveryTime']);
          }

          state = state.copyWith(
            selectedAddress: address,
            deliveryMethod: CustomerDeliveryMethod.values.firstWhere(
              (method) => method.value == cartData['deliveryMethod'],
              orElse: () => CustomerDeliveryMethod.delivery,
            ),
            scheduledDeliveryTime: scheduledTime,
            specialInstructions: cartData['specialInstructions'],
            selectedPaymentMethod: cartData['selectedPaymentMethod'],
          );

          _logger.info('✅ [CART] Cart restored from local storage');
        } else {
          // Clear old cart data
          await prefs.remove(_cartCacheKey);
          _logger.info('🧹 [CART] Cleared expired cart data');
        }
      }
    } catch (e) {
      _logger.error('❌ [CART] Error loading persisted cart', e);
    }
  }

  /// Validate cart before checkout
  List<String> validateCart() {
    final errors = <String>[];

    AppLogger().debug('🔍 [CART-VALIDATION] ===== VALIDATION START =====');
    AppLogger().debug('🔍 [CART-VALIDATION] Current state: ${state.toString()}');
    AppLogger().debug('🔍 [CART-VALIDATION] Items count: ${state.items.length}');
    AppLogger().debug('🔍 [CART-VALIDATION] Subtotal: ${state.subtotal}');
    AppLogger().debug('🔍 [CART-VALIDATION] Total amount: ${state.totalAmount}');

    if (state.isEmpty) {
      errors.add('Cart is empty');
      AppLogger().debug('🔍 [CART-VALIDATION] Added empty cart error');
    }

    if (state.deliveryMethod.requiresDriver && state.selectedAddress == null) {
      errors.add('Delivery address is required');
      AppLogger().debug('🔍 [CART-VALIDATION] Added delivery address error');
    }

    if (state.deliveryMethod == CustomerDeliveryMethod.scheduled && state.scheduledDeliveryTime == null) {
      errors.add('Scheduled delivery time is required');
      AppLogger().debug('🔍 [CART-VALIDATION] Added scheduled delivery time error');
    }

    // Check if cart has items from multiple vendors
    final vendorIds = state.items.map((item) => item.vendorId).toSet();
    if (vendorIds.length > 1) {
      errors.add('Cart contains items from multiple vendors. Please order from one vendor at a time.');
      AppLogger().debug('🔍 [CART-VALIDATION] Added multiple vendors error');
    }

    // Check minimum order amount using app constants
    AppLogger().debug('🔍 [CART-VALIDATION] Checking minimum order: subtotal=${state.subtotal}, minAmount=${AppConstants.minOrderAmount}');
    AppLogger().debug('🔍 [CART-VALIDATION] Comparison result: ${state.subtotal < AppConstants.minOrderAmount}');
    if (state.subtotal < AppConstants.minOrderAmount) {
      errors.add('Minimum order amount is RM ${AppConstants.minOrderAmount.toStringAsFixed(2)}');
      AppLogger().debug('🔍 [CART-VALIDATION] Added minimum order error');
    } else {
      AppLogger().debug('🔍 [CART-VALIDATION] Minimum order check passed');
    }

    AppLogger().debug('🔍 [CART-VALIDATION] Final errors: $errors');
    AppLogger().debug('🔍 [CART-VALIDATION] ===== VALIDATION END =====');

    return errors;
  }

  /// Auto-populate delivery address from customer profile
  // TODO: Restore when CustomerProfile class is implemented
  void autoPopulateAddress(dynamic profile) {
    // if (profile?.addresses.isNotEmpty == true && state.selectedAddress == null) {
    //   final defaultAddress = profile!.addresses.where((addr) => addr.isDefault).firstOrNull;
    //   if (defaultAddress != null) {
    //     setDeliveryAddress(defaultAddress);
    //   }
    // }
  }
}

// Customer cart provider
final customerCartProvider = StateNotifierProvider<CustomerCartNotifier, CustomerCartState>((ref) {
  final baseCartNotifier = ref.watch(cartProvider.notifier);
  return CustomerCartNotifier(baseCartNotifier);
});

// Convenience providers
final customerCartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(customerCartProvider).items;
});

final customerCartTotalProvider = Provider<double>((ref) {
  return ref.watch(customerCartProvider).totalAmount;
});

final customerCartSummaryProvider = Provider<Map<String, dynamic>>((ref) {
  final cart = ref.watch(customerCartProvider);

  return {
    'itemCount': cart.totalItems,
    'subtotal': cart.subtotal,
    'sstAmount': cart.sstAmount,
    'deliveryFee': cart.deliveryFee,
    'totalAmount': cart.totalAmount,
    'deliveryMethod': cart.deliveryMethod.displayName,
    'hasAddress': cart.selectedAddress != null,
    'canCheckout': cart.canCheckout,
  };
});

/// Smart validation provider that handles delivery method changes and auto-population
final customerCartValidationProvider = Provider<List<String>>((ref) {
  final cart = ref.watch(customerCartProvider);
  final cartNotifier = ref.read(customerCartProvider.notifier);

  // If auto-population is in progress, return empty errors to prevent premature validation
  if (cart.isAutoPopulating) {
    return <String>[];
  }

  // Note: Address auto-population is now handled by the cart screen initialization
  // to avoid Riverpod circular dependency issues. The validation provider should
  // only validate the current state without trying to modify it.

  return cartNotifier.validateCart();
});

final customerCartCanCheckoutProvider = Provider<bool>((ref) {
  final validationErrors = ref.watch(customerCartValidationProvider);
  return validationErrors.isEmpty;
});

// Helper method to check if auto-population is needed
// TODO: Restore when CustomerProfile class is implemented
bool shouldAutoPopulateAddress(CustomerCartState cart, dynamic profile) {
  // Should auto-populate if:
  // 1. Profile exists and has addresses
  // 2. Cart doesn't have a selected address
  // 3. Delivery method requires an address
  return false; // Temporarily disabled until CustomerProfile is implemented
  // return profile?.addresses.isNotEmpty == true &&
  //        cart.selectedAddress == null &&
  //        cart.deliveryMethod != CustomerDeliveryMethod.pickup;
}
