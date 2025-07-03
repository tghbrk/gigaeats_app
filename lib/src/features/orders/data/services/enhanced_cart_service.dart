import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/enhanced_cart_models.dart';
import '../models/customer_delivery_method.dart';

import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import '../../../../core/constants/app_constants.dart';

/// Service for enhanced cart operations and business logic
class EnhancedCartService {
  static const String _cartCacheKey = 'enhanced_cart_cache_v2';
  static const String _cartHistoryKey = 'cart_history';
  final AppLogger _logger = AppLogger();

  /// Save cart to persistent storage
  Future<void> saveCart(EnhancedCartState cartState) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = json.encode(cartState.toJson());
      await prefs.setString(_cartCacheKey, cartJson);
      
      // Also save to history for analytics
      await _saveToHistory(cartState);
      
      _logger.debug('💾 [CART-SERVICE] Cart saved to storage');
    } catch (e) {
      _logger.error('❌ [CART-SERVICE] Failed to save cart', e);
      throw Exception('Failed to save cart: $e');
    }
  }

  /// Load cart from persistent storage
  Future<EnhancedCartState?> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString(_cartCacheKey);
      
      if (cartJson == null) {
        _logger.info('📱 [CART-SERVICE] No persisted cart found');
        return null;
      }

      final cartData = json.decode(cartJson) as Map<String, dynamic>;
      final cartState = EnhancedCartState.fromJson(cartData);
      
      // Validate cart items are still available
      final validatedState = await _validateCartItems(cartState);
      
      _logger.info('📱 [CART-SERVICE] Loaded cart with ${validatedState.items.length} items');
      return validatedState;
      
    } catch (e) {
      _logger.error('❌ [CART-SERVICE] Failed to load cart', e);
      // Return empty cart on error to prevent app crashes
      return EnhancedCartState.empty();
    }
  }

  /// Clear persisted cart
  Future<void> clearPersistedCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cartCacheKey);
      _logger.info('🧹 [CART-SERVICE] Persisted cart cleared');
    } catch (e) {
      _logger.error('❌ [CART-SERVICE] Failed to clear persisted cart', e);
    }
  }

  /// Calculate comprehensive cart pricing
  Future<CartSummary> calculateCartSummary({
    required List<EnhancedCartItem> items,
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledTime,
    String? promoCode,
  }) async {
    try {
      if (items.isEmpty) {
        return CartSummary(
          subtotal: 0.0,
          customizationTotal: 0.0,
          deliveryFee: 0.0,
          sstAmount: 0.0,
          discountAmount: 0.0,
          totalAmount: 0.0,
          totalItems: 0,
          totalQuantity: 0,
          vendorSubtotals: {},
          calculatedAt: DateTime.now(),
        );
      }

      // Calculate subtotals
      final subtotal = items.fold(0.0, (sum, item) => sum + (item.basePrice * item.quantity));
      final customizationTotal = items.fold(0.0, (sum, item) => sum + item.totalCustomizationCost);
      
      // Calculate vendor subtotals
      final vendorSubtotals = <String, double>{};
      for (final item in items) {
        vendorSubtotals[item.vendorId] = (vendorSubtotals[item.vendorId] ?? 0.0) + item.totalPrice;
      }

      // Calculate delivery fee
      final deliveryFee = await _calculateDeliveryFee(
        deliveryMethod: deliveryMethod,
        vendorId: items.first.vendorId,
        subtotal: subtotal + customizationTotal,
        deliveryAddress: deliveryAddress,
        scheduledTime: scheduledTime,
      );

      // Calculate discount
      final discountAmount = await _calculateDiscount(
        subtotal: subtotal + customizationTotal,
        promoCode: promoCode,
        deliveryMethod: deliveryMethod,
      );

      // Calculate SST (6% on subtotal + delivery fee - discount)
      final taxableAmount = subtotal + customizationTotal + deliveryFee - discountAmount;
      final sstAmount = taxableAmount * AppConstants.sstRate;

      // Calculate total
      final totalAmount = subtotal + customizationTotal + deliveryFee + sstAmount - discountAmount;

      return CartSummary(
        subtotal: subtotal,
        customizationTotal: customizationTotal,
        deliveryFee: deliveryFee,
        sstAmount: sstAmount,
        discountAmount: discountAmount,
        totalAmount: totalAmount,
        totalItems: items.length,
        totalQuantity: items.fold(0, (sum, item) => sum + item.quantity),
        vendorSubtotals: vendorSubtotals,
        calculatedAt: DateTime.now(),
      );

    } catch (e) {
      _logger.error('❌ [CART-SERVICE] Failed to calculate cart summary', e);
      rethrow;
    }
  }

  /// Validate cart for checkout readiness
  Future<CartValidationResult> validateCartForCheckout(EnhancedCartState cartState) async {
    try {
      final errors = <String>[];
      final warnings = <String>[];

      // Basic validations
      if (cartState.isEmpty) {
        errors.add('Cart is empty');
        return CartValidationResult.invalid(errors);
      }

      // Multi-vendor validation
      final vendorIds = cartState.items.map((item) => item.vendorId).toSet();
      if (vendorIds.length > 1) {
        errors.add('Cart contains items from multiple vendors. Please checkout separately.');
      }

      // Minimum order validation
      if (cartState.subtotal < AppConstants.minOrderAmount) {
        errors.add('Minimum order amount is RM ${AppConstants.minOrderAmount.toStringAsFixed(2)}');
      }

      // Maximum order validation
      if (cartState.subtotal > AppConstants.maxOrderAmount) {
        errors.add('Maximum order amount is RM ${AppConstants.maxOrderAmount.toStringAsFixed(2)}');
      }

      // Item availability validation
      final unavailableItems = cartState.items.where((item) => !item.isAvailable).toList();
      if (unavailableItems.isNotEmpty) {
        errors.add('${unavailableItems.length} item(s) are no longer available');
        for (final item in unavailableItems) {
          warnings.add('${item.name} is currently unavailable');
        }
      }

      // Delivery method specific validations
      await _validateDeliveryMethod(cartState, errors, warnings);

      // Payment method validation
      if (cartState.selectedPaymentMethod == null) {
        errors.add('Please select a payment method');
      }

      // Business hours validation
      await _validateBusinessHours(cartState, errors, warnings);

      return errors.isEmpty 
          ? CartValidationResult.valid()
          : CartValidationResult.invalid(errors, warnings: warnings);

    } catch (e) {
      _logger.error('❌ [CART-SERVICE] Failed to validate cart', e);
      return CartValidationResult.invalid(['Validation error: ${e.toString()}']);
    }
  }

  /// Merge cart items (useful for handling conflicts)
  List<EnhancedCartItem> mergeCartItems(
    List<EnhancedCartItem> existingItems,
    List<EnhancedCartItem> newItems,
  ) {
    final mergedItems = <String, EnhancedCartItem>{};

    // Add existing items
    for (final item in existingItems) {
      mergedItems[item.id] = item;
    }

    // Merge new items
    for (final newItem in newItems) {
      if (mergedItems.containsKey(newItem.id)) {
        // Merge quantities
        final existingItem = mergedItems[newItem.id]!;
        final mergedQuantity = existingItem.quantity + newItem.quantity;
        
        // Respect max quantity limits
        final finalQuantity = existingItem.maxQuantity != null
            ? mergedQuantity.clamp(existingItem.minQuantity, existingItem.maxQuantity!)
            : mergedQuantity.clamp(existingItem.minQuantity, double.infinity).toInt();

        mergedItems[newItem.id] = existingItem.copyWith(quantity: finalQuantity);
      } else {
        mergedItems[newItem.id] = newItem;
      }
    }

    return mergedItems.values.toList();
  }

  /// Calculate delivery fee based on method and location
  Future<double> _calculateDeliveryFee({
    required CustomerDeliveryMethod deliveryMethod,
    required String vendorId,
    required double subtotal,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledTime,
  }) async {
    try {
      // Use delivery method's fee multiplier
      final baseFee = 5.0; // Base delivery fee
      return baseFee * deliveryMethod.feeMultiplier;
    } catch (e) {
      _logger.warning('Failed to calculate delivery fee, using default: $e');
      return 5.0; // Default fallback
    }
  }

  /// Calculate discount amount
  Future<double> _calculateDiscount({
    required double subtotal,
    String? promoCode,
    required CustomerDeliveryMethod deliveryMethod,
  }) async {
    // TODO: Implement promo code and discount logic
    return 0.0;
  }

  /// Validate delivery method specific requirements
  Future<void> _validateDeliveryMethod(
    EnhancedCartState cartState,
    List<String> errors,
    List<String> warnings,
  ) async {
    final method = cartState.deliveryMethod;

    // Address validation for delivery methods
    if (method.requiresDriver && cartState.selectedAddress == null) {
      errors.add('Delivery address is required for ${method.displayName}');
    }

    // Scheduled delivery validation
    if (method == CustomerDeliveryMethod.scheduled) {
      if (cartState.scheduledDeliveryTime == null) {
        errors.add('Please select a delivery time for scheduled orders');
      } else {
        final now = DateTime.now();
        final scheduledTime = cartState.scheduledDeliveryTime!;
        
        if (scheduledTime.isBefore(now.add(const Duration(hours: 2)))) {
          errors.add('Scheduled delivery must be at least 2 hours in advance');
        }
        
        if (scheduledTime.isAfter(now.add(const Duration(days: 7)))) {
          warnings.add('Scheduled delivery is more than 7 days away');
        }
      }
    }

    // Distance validation for own fleet
    if (method == CustomerDeliveryMethod.ownFleet && cartState.selectedAddress != null) {
      // TODO: Implement distance calculation and validation
      // For now, we'll skip this validation
    }
  }

  /// Validate business hours
  Future<void> _validateBusinessHours(
    EnhancedCartState cartState,
    List<String> errors,
    List<String> warnings,
  ) async {
    // TODO: Implement business hours validation
    // This would check if the vendor is open for the selected delivery time
  }

  /// Validate cart items availability and pricing
  Future<EnhancedCartState> _validateCartItems(EnhancedCartState cartState) async {
    // TODO: Implement real-time item validation against database
    // For now, return the cart as-is
    return cartState;
  }

  /// Save cart to history for analytics
  Future<void> _saveToHistory(EnhancedCartState cartState) async {
    try {
      if (cartState.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();
      final historyJson = prefs.getString(_cartHistoryKey);
      
      List<Map<String, dynamic>> history = [];
      if (historyJson != null) {
        history = List<Map<String, dynamic>>.from(json.decode(historyJson));
      }

      // Add current cart to history
      history.add({
        'timestamp': DateTime.now().toIso8601String(),
        'itemCount': cartState.totalItems,
        'totalAmount': cartState.totalAmount,
        'vendorIds': cartState.itemsByVendor.keys.toList(),
      });

      // Keep only last 50 entries
      if (history.length > 50) {
        history = history.sublist(history.length - 50);
      }

      await prefs.setString(_cartHistoryKey, json.encode(history));
    } catch (e) {
      _logger.warning('Failed to save cart history: $e');
    }
  }
}
