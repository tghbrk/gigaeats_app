import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/sales_agent/presentation/providers/cart_provider.dart';
import '../../../../features/menu/data/models/product.dart';
import '../../../../features/vendors/data/models/vendor.dart';
import '../../../../features/menu/data/models/menu_item.dart';
import '../../../customers/data/models/customer_profile.dart';
import '../../../../core/utils/logger.dart';

/// Customer-specific cart provider that extends the base cart functionality
/// with customer-specific features like address selection and payment methods

// Delivery method for customers
enum CustomerDeliveryMethod {
  pickup('pickup', 'Pickup', 'Collect from restaurant'),
  delivery('delivery', 'Delivery', 'Delivered to your address'),
  scheduled('scheduled', 'Scheduled', 'Schedule for later');

  const CustomerDeliveryMethod(this.value, this.displayName, this.description);
  
  final String value;
  final String displayName;
  final String description;
}

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

  const CustomerCartState({
    required this.baseCart,
    this.selectedAddress,
    this.deliveryMethod = CustomerDeliveryMethod.delivery,
    this.scheduledDeliveryTime,
    this.specialInstructions,
    this.selectedPaymentMethod,
    this.isLoading = false,
    this.error,
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
    );
  }

  // Convenience getters
  List<CartItem> get items => baseCart.items;
  bool get isEmpty => baseCart.isEmpty;
  int get totalItems => baseCart.totalItems;
  double get subtotal => baseCart.subtotal;
  double get sstAmount => baseCart.sstAmount;
  
  double get deliveryFee {
    switch (deliveryMethod) {
      case CustomerDeliveryMethod.pickup:
        return 0.0;
      case CustomerDeliveryMethod.delivery:
      case CustomerDeliveryMethod.scheduled:
        // TODO: Calculate delivery fee based on distance and vendor
        return 5.0; // Default delivery fee
    }
  }
  
  double get totalAmount => subtotal + sstAmount + deliveryFee;
  
  bool get canCheckout {
    if (isEmpty) return false;
    if (deliveryMethod != CustomerDeliveryMethod.pickup && selectedAddress == null) return false;
    if (deliveryMethod == CustomerDeliveryMethod.scheduled && scheduledDeliveryTime == null) return false;
    return true;
  }
}

// Customer cart notifier
class CustomerCartNotifier extends StateNotifier<CustomerCartState> {
  final CartNotifier _baseCartNotifier;
  final AppLogger _logger = AppLogger();

  CustomerCartNotifier(this._baseCartNotifier) 
      : super(CustomerCartState(baseCart: _baseCartNotifier.state)) {
    // Listen to base cart changes
    _baseCartNotifier.addListener((baseCart) {
      state = state.copyWith(baseCart: baseCart);
    });
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
      _baseCartNotifier.addItem(
        product: product,
        vendor: vendor,
        quantity: quantity,
        customizations: customizations,
        notes: notes,
      );
    } catch (e) {
      _logger.error('Error adding item to customer cart', e);
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
      _baseCartNotifier.addMenuItem(
        menuItem: menuItem,
        vendorName: vendorName,
        quantity: quantity,
        customizations: customizations,
        notes: notes,
      );
    } catch (e) {
      _logger.error('Error adding menu item to customer cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Update item quantity
  void updateItemQuantity(String itemId, int quantity) {
    try {
      _baseCartNotifier.updateItemQuantity(itemId, quantity);
    } catch (e) {
      _logger.error('Error updating item quantity', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Remove item from cart
  void removeItem(String itemId) {
    try {
      _baseCartNotifier.removeItem(itemId);
    } catch (e) {
      _logger.error('Error removing item from cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Clear cart
  void clearCart() {
    try {
      _baseCartNotifier.clearCart();
      state = state.copyWith(
        selectedAddress: null,
        scheduledDeliveryTime: null,
        specialInstructions: null,
        selectedPaymentMethod: null,
      );
    } catch (e) {
      _logger.error('Error clearing cart', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Set delivery address
  void setDeliveryAddress(CustomerAddress address) {
    state = state.copyWith(selectedAddress: address);
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

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Auto-populate delivery address from customer profile
  void autoPopulateAddress(CustomerProfile? profile) {
    if (profile?.addresses.isNotEmpty == true && state.selectedAddress == null) {
      final defaultAddress = profile!.addresses.where((addr) => addr.isDefault).firstOrNull;
      if (defaultAddress != null) {
        setDeliveryAddress(defaultAddress);
      }
    }
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

final customerCartCanCheckoutProvider = Provider<bool>((ref) {
  return ref.watch(customerCartProvider).canCheckout;
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

// Helper method to check if auto-population is needed
bool shouldAutoPopulateAddress(CustomerCartState cart, CustomerProfile? profile) {
  // Should auto-populate if:
  // 1. Profile exists and has addresses
  // 2. Cart doesn't have a selected address
  // 3. Delivery method requires an address
  return profile?.addresses.isNotEmpty == true &&
         cart.selectedAddress == null &&
         cart.deliveryMethod != CustomerDeliveryMethod.pickup;
}
