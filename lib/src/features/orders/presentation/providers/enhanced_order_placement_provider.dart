import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/enhanced_order_placement_service.dart';
import '../../data/models/enhanced_cart_models.dart';

import '../../data/models/customer_delivery_method.dart';
import '../../data/models/order.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import 'enhanced_payment_provider.dart';

/// Enhanced order placement state
class EnhancedOrderPlacementState {
  final bool isPlacingOrder;
  final OrderPlacementResult? lastResult;
  final String? error;
  final List<String>? validationErrors;
  final OrderConfirmation? lastConfirmation;
  final DateTime lastUpdated;

  const EnhancedOrderPlacementState({
    this.isPlacingOrder = false,
    this.lastResult,
    this.error,
    this.validationErrors,
    this.lastConfirmation,
    required this.lastUpdated,
  });

  EnhancedOrderPlacementState copyWith({
    bool? isPlacingOrder,
    OrderPlacementResult? lastResult,
    String? error,
    List<String>? validationErrors,
    OrderConfirmation? lastConfirmation,
    DateTime? lastUpdated,
  }) {
    return EnhancedOrderPlacementState(
      isPlacingOrder: isPlacingOrder ?? this.isPlacingOrder,
      lastResult: lastResult ?? this.lastResult,
      error: error,
      validationErrors: validationErrors,
      lastConfirmation: lastConfirmation ?? this.lastConfirmation,
      lastUpdated: lastUpdated ?? DateTime.now(),
    );
  }

  bool get hasError => error != null;
  bool get hasValidationErrors => validationErrors != null && validationErrors!.isNotEmpty;
  bool get lastOrderSuccessful => lastResult?.success == true;
  Order? get lastOrder => lastResult?.order;
}

/// Enhanced order placement notifier
class EnhancedOrderPlacementNotifier extends StateNotifier<EnhancedOrderPlacementState> {
  final EnhancedOrderPlacementService _orderPlacementService;
  final AppLogger _logger = AppLogger();

  EnhancedOrderPlacementNotifier(this._orderPlacementService)
      : super(EnhancedOrderPlacementState(lastUpdated: DateTime.now()));

  /// Place order with comprehensive processing
  Future<OrderPlacementResult> placeOrder({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledDeliveryTime,
    String? specialInstructions,
    required PaymentMethodType paymentMethod,
    dynamic paymentDetails,
    String? promoCode,
  }) async {
    try {
      state = state.copyWith(
        isPlacingOrder: true,
        error: null,
        validationErrors: null,
      );

      _logger.info('📋 [ORDER-PLACEMENT-PROVIDER] Starting order placement');

      final result = await _orderPlacementService.placeOrder(
        cartState: cartState,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        scheduledDeliveryTime: scheduledDeliveryTime,
        specialInstructions: specialInstructions,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
        promoCode: promoCode,
      );

      if (result.success) {
        state = state.copyWith(
          isPlacingOrder: false,
          lastResult: result,
          lastConfirmation: result.confirmation,
        );

        _logger.info('✅ [ORDER-PLACEMENT-PROVIDER] Order placed successfully: ${result.order?.orderNumber}');
      } else {
        state = state.copyWith(
          isPlacingOrder: false,
          lastResult: result,
          error: result.error,
          validationErrors: result.validationErrors,
        );

        _logger.error('❌ [ORDER-PLACEMENT-PROVIDER] Order placement failed: ${result.error}');
      }

      return result;

    } catch (e, stackTrace) {
      _logger.error('❌ [ORDER-PLACEMENT-PROVIDER] Order placement exception', e, stackTrace);

      final failedResult = OrderPlacementResult.failed(
        error: 'Order placement failed: ${e.toString()}',
      );

      state = state.copyWith(
        isPlacingOrder: false,
        lastResult: failedResult,
        error: failedResult.error,
      );

      return failedResult;
    }
  }

  /// Validate order before placement
  Future<bool> validateOrder({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledDeliveryTime,
    required PaymentMethodType paymentMethod,
  }) async {
    try {
      _logger.info('✅ [ORDER-PLACEMENT-PROVIDER] Validating order');

      // Use the private validation method from the service
      // For now, we'll do basic validation here
      final errors = <String>[];

      // Validate cart
      if (cartState.isEmpty) {
        errors.add('Cart is empty');
      }

      if (cartState.hasMultipleVendors) {
        errors.add('Cart contains items from multiple vendors');
      }

      // Validate delivery method and address
      if (deliveryMethod.requiresDriver && deliveryAddress == null) {
        errors.add('Delivery address is required for ${deliveryMethod.displayName}');
      }

      // Validate scheduled delivery
      if (scheduledDeliveryTime != null) {
        final now = DateTime.now();
        if (scheduledDeliveryTime.isBefore(now.add(const Duration(hours: 2)))) {
          errors.add('Scheduled delivery time must be at least 2 hours in advance');
        }
      }

      final isValid = errors.isEmpty;

      if (!isValid) {
        state = state.copyWith(
          validationErrors: errors,
          error: 'Order validation failed',
        );
      } else {
        state = state.copyWith(
          validationErrors: null,
          error: null,
        );
      }

      _logger.info('✅ [ORDER-PLACEMENT-PROVIDER] Order validation result: $isValid');
      return isValid;

    } catch (e) {
      _logger.error('❌ [ORDER-PLACEMENT-PROVIDER] Order validation failed', e);
      
      state = state.copyWith(
        validationErrors: ['Validation failed: ${e.toString()}'],
        error: 'Order validation failed',
      );

      return false;
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(
      error: null,
      validationErrors: null,
    );
  }

  /// Clear last result
  void clearLastResult() {
    state = state.copyWith(
      lastResult: null,
      lastConfirmation: null,
      error: null,
      validationErrors: null,
    );
  }

  /// Get order placement summary
  OrderPlacementSummary? getOrderPlacementSummary() {
    final result = state.lastResult;
    if (result == null) return null;

    return OrderPlacementSummary(
      success: result.success,
      orderNumber: result.order?.orderNumber,
      totalAmount: result.order?.totalAmount,
      paymentMethod: result.paymentResult?.status.displayName,
      estimatedDeliveryTime: state.lastConfirmation?.estimatedDeliveryTime,
      trackingUrl: state.lastConfirmation?.trackingUrl,
      error: result.error,
    );
  }

  /// Check if order can be placed
  bool canPlaceOrder({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    required PaymentMethodType paymentMethod,
  }) {
    // Basic checks
    if (cartState.isEmpty) return false;
    if (cartState.hasMultipleVendors) return false;
    if (deliveryMethod.requiresDriver && deliveryAddress == null) return false;
    if (state.isPlacingOrder) return false;

    return true;
  }

  /// Get estimated order total
  double getEstimatedTotal(EnhancedCartState cartState) {
    return cartState.totalAmount;
  }

  /// Get order placement status message
  String? getStatusMessage() {
    if (state.isPlacingOrder) {
      return 'Placing your order...';
    }

    if (state.hasError) {
      return state.error;
    }

    if (state.lastOrderSuccessful) {
      return 'Order placed successfully!';
    }

    return null;
  }
}

/// Order placement summary
class OrderPlacementSummary {
  final bool success;
  final String? orderNumber;
  final double? totalAmount;
  final String? paymentMethod;
  final DateTime? estimatedDeliveryTime;
  final String? trackingUrl;
  final String? error;

  const OrderPlacementSummary({
    required this.success,
    this.orderNumber,
    this.totalAmount,
    this.paymentMethod,
    this.estimatedDeliveryTime,
    this.trackingUrl,
    this.error,
  });
}

/// Enhanced order placement provider
final enhancedOrderPlacementProvider = StateNotifierProvider<EnhancedOrderPlacementNotifier, EnhancedOrderPlacementState>((ref) {
  final orderPlacementService = ref.watch(enhancedOrderPlacementServiceProvider);
  return EnhancedOrderPlacementNotifier(orderPlacementService);
});

/// Enhanced order placement service provider
final enhancedOrderPlacementServiceProvider = Provider<EnhancedOrderPlacementService>((ref) {
  return EnhancedOrderPlacementService();
});

/// Convenience providers
final isPlacingOrderProvider = Provider<bool>((ref) {
  return ref.watch(enhancedOrderPlacementProvider).isPlacingOrder;
});

final lastOrderProvider = Provider<Order?>((ref) {
  return ref.watch(enhancedOrderPlacementProvider).lastOrder;
});

final lastOrderConfirmationProvider = Provider<OrderConfirmation?>((ref) {
  return ref.watch(enhancedOrderPlacementProvider).lastConfirmation;
});

final orderPlacementErrorProvider = Provider<String?>((ref) {
  return ref.watch(enhancedOrderPlacementProvider).error;
});

final orderValidationErrorsProvider = Provider<List<String>?>((ref) {
  return ref.watch(enhancedOrderPlacementProvider).validationErrors;
});

final orderPlacementSummaryProvider = Provider<OrderPlacementSummary?>((ref) {
  return ref.watch(enhancedOrderPlacementProvider.notifier).getOrderPlacementSummary();
});

/// Order placement status provider
final orderPlacementStatusProvider = Provider<String?>((ref) {
  return ref.watch(enhancedOrderPlacementProvider.notifier).getStatusMessage();
});

/// Can place order provider
final canPlaceOrderProvider = Provider.family<bool, OrderPlacementParams>((ref, params) {
  return ref.watch(enhancedOrderPlacementProvider.notifier).canPlaceOrder(
    cartState: params.cartState,
    deliveryMethod: params.deliveryMethod,
    deliveryAddress: params.deliveryAddress,
    paymentMethod: params.paymentMethod,
  );
});

/// Order placement parameters
class OrderPlacementParams {
  final EnhancedCartState cartState;
  final CustomerDeliveryMethod deliveryMethod;
  final CustomerAddress? deliveryAddress;
  final PaymentMethodType paymentMethod;

  const OrderPlacementParams({
    required this.cartState,
    required this.deliveryMethod,
    this.deliveryAddress,
    required this.paymentMethod,
  });
}
