import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/order.dart';
import '../models/enhanced_cart_models.dart';
import '../models/enhanced_payment_models.dart';
import '../models/customer_delivery_method.dart';
import '../../../user_management/domain/customer_profile.dart';
import '../../../core/utils/logger.dart';
import 'enhanced_payment_service.dart';
import '../../presentation/providers/enhanced_payment_provider.dart';

/// Enhanced order placement service with comprehensive validation and confirmation
class EnhancedOrderPlacementService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final EnhancedPaymentService _paymentService = EnhancedPaymentService();
  final AppLogger _logger = AppLogger();
  final Uuid _uuid = const Uuid();

  /// Place order with comprehensive validation and processing
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
      _logger.info('📋 [ORDER-PLACEMENT] Starting order placement process');

      // Step 1: Validate order data
      final validationResult = await _validateOrderData(
        cartState: cartState,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        scheduledDeliveryTime: scheduledDeliveryTime,
        paymentMethod: paymentMethod,
      );

      if (!validationResult.isValid) {
        return OrderPlacementResult.failed(
          error: validationResult.errors.join(', '),
          validationErrors: validationResult.errors,
        );
      }

      // Step 2: Calculate final totals
      final totals = await _calculateOrderTotals(
        cartState: cartState,
        deliveryMethod: deliveryMethod,
        promoCode: promoCode,
      );

      // Step 3: Create order in database
      final order = await _createOrderInDatabase(
        cartState: cartState,
        deliveryMethod: deliveryMethod,
        deliveryAddress: deliveryAddress,
        scheduledDeliveryTime: scheduledDeliveryTime,
        specialInstructions: specialInstructions,
        totals: totals,
      );

      // Step 4: Process payment
      final paymentResult = await _processOrderPayment(
        order: order,
        paymentMethod: paymentMethod,
        paymentDetails: paymentDetails,
        amount: totals.totalAmount,
      );

      if (!paymentResult.success) {
        // Rollback order creation if payment fails
        await _rollbackOrder(order.id);
        
        return OrderPlacementResult.failed(
          error: paymentResult.errorMessage ?? 'Payment processing failed',
          paymentError: paymentResult.errorMessage,
        );
      }

      // Step 5: Update order with payment information
      final finalOrder = await _updateOrderWithPayment(order, paymentResult);

      // Step 6: Generate order confirmation
      final confirmation = await _generateOrderConfirmation(finalOrder);

      // Step 7: Send notifications
      await _sendOrderNotifications(finalOrder);

      _logger.info('✅ [ORDER-PLACEMENT] Order placed successfully: ${finalOrder.orderNumber}');

      return OrderPlacementResult.success(
        order: finalOrder,
        confirmation: confirmation,
        paymentResult: paymentResult,
      );

    } catch (e, stackTrace) {
      _logger.error('❌ [ORDER-PLACEMENT] Order placement failed', e, stackTrace);
      
      return OrderPlacementResult.failed(
        error: 'Order placement failed: ${e.toString()}',
      );
    }
  }

  /// Validate order data before processing
  Future<OrderValidationResult> _validateOrderData({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledDeliveryTime,
    required PaymentMethodType paymentMethod,
  }) async {
    final errors = <String>[];
    final warnings = <String>[];

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

    // Validate payment method
    if (paymentMethod == PaymentMethodType.wallet) {
      final walletBalance = await _paymentService.getWalletBalance();
      if (walletBalance < cartState.totalAmount) {
        errors.add('Insufficient wallet balance');
      }
    }

    // Validate user authentication
    final user = _supabase.auth.currentUser;
    if (user == null) {
      errors.add('User not authenticated');
    }

    return OrderValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Calculate order totals with fees and discounts
  Future<OrderTotals> _calculateOrderTotals({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    String? promoCode,
  }) async {
    double subtotal = cartState.subtotal;
    double deliveryFee = cartState.deliveryFee;
    double sstAmount = cartState.sstAmount;
    double discountAmount = 0.0;
    double commissionAmount = 0.0;

    // Apply promo code discount
    if (promoCode != null && promoCode.isNotEmpty) {
      discountAmount = await _calculatePromoDiscount(promoCode, subtotal);
    }

    // Calculate commission (for sales agents)
    final user = _supabase.auth.currentUser;
    if (user != null) {
      final userProfile = await _getUserProfile(user.id);
      if (userProfile?['role'] == 'sales_agent') {
        commissionAmount = subtotal * 0.05; // 5% commission
      }
    }

    final totalAmount = subtotal + deliveryFee + sstAmount - discountAmount;

    return OrderTotals(
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      sstAmount: sstAmount,
      discountAmount: discountAmount,
      commissionAmount: commissionAmount,
      totalAmount: totalAmount,
    );
  }

  /// Create order in database with proper RLS
  Future<Order> _createOrderInDatabase({
    required EnhancedCartState cartState,
    required CustomerDeliveryMethod deliveryMethod,
    CustomerAddress? deliveryAddress,
    DateTime? scheduledDeliveryTime,
    String? specialInstructions,
    required OrderTotals totals,
  }) async {
    final user = _supabase.auth.currentUser!;
    final orderNumber = _generateOrderNumber();
    final orderId = _uuid.v4();

    // Get user profile for role information
    final userProfile = await _getUserProfile(user.id);
    final userRole = userProfile?['role'] as String?;

    // Determine customer and sales agent IDs
    String customerId = user.id;
    String? salesAgentId;

    if (userRole == 'sales_agent') {
      // Sales agent placing order for customer
      salesAgentId = user.id;
      // TODO: Get actual customer ID from cart or selection
      customerId = cartState.customerId ?? user.id;
    }

    // Create order data
    final orderData = {
      'id': orderId,
      'order_number': orderNumber,
      'customer_id': customerId,
      'vendor_id': cartState.primaryVendorId,
      'sales_agent_id': salesAgentId,
      'status': 'pending',
      'delivery_method': deliveryMethod.value,
      'delivery_address': deliveryAddress?.toJson(),
      'scheduled_delivery_time': scheduledDeliveryTime?.toIso8601String(),
      'special_instructions': specialInstructions,
      'subtotal': totals.subtotal,
      'delivery_fee': totals.deliveryFee,
      'sst_amount': totals.sstAmount,
      'discount_amount': totals.discountAmount,
      'total_amount': totals.totalAmount,
      'commission_amount': totals.commissionAmount,
      'payment_status': 'pending',
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    // Insert order
    final orderResponse = await _supabase
        .from('orders')
        .insert(orderData)
        .select()
        .single();

    // Insert order items
    final orderItems = cartState.items.map((cartItem) => {
      'id': _uuid.v4(),
      'order_id': orderId,
      'menu_item_id': cartItem.menuItemId,
      'name': cartItem.name,
      'description': cartItem.description,
      'price': cartItem.basePrice,
      'quantity': cartItem.quantity,
      'customizations': cartItem.customizations,
      'notes': cartItem.notes,
      'total_price': cartItem.totalPrice,
      'created_at': DateTime.now().toIso8601String(),
    }).toList();

    await _supabase.from('order_items').insert(orderItems);

    _logger.info('✅ [ORDER-PLACEMENT] Order created in database: $orderNumber');

    return Order.fromJson(orderResponse);
  }

  /// Process payment for the order
  Future<EnhancedPaymentResult> _processOrderPayment({
    required Order order,
    required PaymentMethodType paymentMethod,
    dynamic paymentDetails,
    required double amount,
  }) async {
    _logger.info('💳 [ORDER-PLACEMENT] Processing payment: ${paymentMethod.value}');

    return await _paymentService.processPayment(
      orderId: order.id,
      paymentMethod: paymentMethod,
      amount: amount,
      cardDetails: paymentDetails,
      metadata: {
        'order_number': order.orderNumber,
        'vendor_id': order.vendorId,
        'customer_id': order.customerId,
      },
    );
  }

  /// Update order with payment information
  Future<Order> _updateOrderWithPayment(Order order, EnhancedPaymentResult paymentResult) async {
    final updateData = {
      'payment_method': paymentResult.success ? 'completed' : 'failed',
      'payment_status': paymentResult.status.value,
      'payment_reference': paymentResult.transactionId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    final updatedOrderResponse = await _supabase
        .from('orders')
        .update(updateData)
        .eq('id', order.id)
        .select()
        .single();

    return Order.fromJson(updatedOrderResponse);
  }

  /// Generate order confirmation
  Future<OrderConfirmation> _generateOrderConfirmation(Order order) async {
    _logger.info('📄 [ORDER-PLACEMENT] Generating order confirmation');

    return OrderConfirmation(
      orderNumber: order.orderNumber,
      orderId: order.id,
      customerName: order.customerName,
      vendorName: order.vendorName,
      totalAmount: order.totalAmount,
      estimatedDeliveryTime: _calculateEstimatedDeliveryTime(order),
      confirmationMessage: _generateConfirmationMessage(order),
      trackingUrl: _generateTrackingUrl(order.id),
      createdAt: DateTime.now(),
    );
  }

  /// Send order notifications
  Future<void> _sendOrderNotifications(Order order) async {
    try {
      _logger.info('📧 [ORDER-PLACEMENT] Sending order notifications');

      // Send notification to customer
      await _supabase.functions.invoke('send-order-notification', body: {
        'type': 'order_placed',
        'order_id': order.id,
        'recipient_type': 'customer',
        'recipient_id': order.customerId,
      });

      // Send notification to vendor
      await _supabase.functions.invoke('send-order-notification', body: {
        'type': 'new_order',
        'order_id': order.id,
        'recipient_type': 'vendor',
        'recipient_id': order.vendorId,
      });

      // Send notification to sales agent if applicable
      if (order.salesAgentId != null) {
        await _supabase.functions.invoke('send-order-notification', body: {
          'type': 'order_placed',
          'order_id': order.id,
          'recipient_type': 'sales_agent',
          'recipient_id': order.salesAgentId,
        });
      }

      _logger.info('✅ [ORDER-PLACEMENT] Notifications sent successfully');
    } catch (e) {
      _logger.warning('⚠️ [ORDER-PLACEMENT] Failed to send notifications: $e');
      // Don't fail the order placement if notifications fail
    }
  }

  /// Rollback order creation
  Future<void> _rollbackOrder(String orderId) async {
    try {
      _logger.info('🔄 [ORDER-PLACEMENT] Rolling back order: $orderId');

      // Delete order items first (foreign key constraint)
      await _supabase.from('order_items').delete().eq('order_id', orderId);

      // Delete order
      await _supabase.from('orders').delete().eq('id', orderId);

      _logger.info('✅ [ORDER-PLACEMENT] Order rollback completed');
    } catch (e) {
      _logger.error('❌ [ORDER-PLACEMENT] Failed to rollback order', e);
    }
  }

  /// Helper methods
  String _generateOrderNumber() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (DateTime.now().microsecond % 100).toString().padLeft(2, '0');
    return 'GE${timestamp.substring(timestamp.length - 8)}$random';
  }

  Future<Map<String, dynamic>?> _getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('user_profiles')
          .select()
          .eq('user_id', userId)
          .single();
      return response;
    } catch (e) {
      return null;
    }
  }

  Future<double> _calculatePromoDiscount(String promoCode, double subtotal) async {
    // Mock promo code validation - in real implementation, check database
    if (promoCode.toUpperCase() == 'SAVE10') {
      return 10.0;
    } else if (promoCode.toUpperCase() == 'PERCENT5') {
      return subtotal * 0.05;
    }
    return 0.0;
  }

  DateTime _calculateEstimatedDeliveryTime(Order order) {
    // Base preparation time
    int preparationMinutes = 30;
    
    // Add time based on number of items
    preparationMinutes += (order.items.length * 2);
    
    // Add delivery time (delivery address is always present)
    preparationMinutes += 30; // Delivery time
    
    return DateTime.now().add(Duration(minutes: preparationMinutes));
  }

  String _generateConfirmationMessage(Order order) {
    return 'Thank you for your order! Your order ${order.orderNumber} has been placed successfully and is being prepared. You will receive updates on the order status.';
  }

  String _generateTrackingUrl(String orderId) {
    return 'gigaeats://orders/$orderId/track';
  }
}

/// Order placement result
class OrderPlacementResult {
  final bool success;
  final Order? order;
  final OrderConfirmation? confirmation;
  final EnhancedPaymentResult? paymentResult;
  final String? error;
  final List<String>? validationErrors;
  final String? paymentError;

  const OrderPlacementResult({
    required this.success,
    this.order,
    this.confirmation,
    this.paymentResult,
    this.error,
    this.validationErrors,
    this.paymentError,
  });

  factory OrderPlacementResult.success({
    required Order order,
    required OrderConfirmation confirmation,
    required EnhancedPaymentResult paymentResult,
  }) {
    return OrderPlacementResult(
      success: true,
      order: order,
      confirmation: confirmation,
      paymentResult: paymentResult,
    );
  }

  factory OrderPlacementResult.failed({
    required String error,
    List<String>? validationErrors,
    String? paymentError,
  }) {
    return OrderPlacementResult(
      success: false,
      error: error,
      validationErrors: validationErrors,
      paymentError: paymentError,
    );
  }
}

/// Order validation result
class OrderValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const OrderValidationResult({
    required this.isValid,
    required this.errors,
    required this.warnings,
  });
}

/// Order totals calculation
class OrderTotals {
  final double subtotal;
  final double deliveryFee;
  final double sstAmount;
  final double discountAmount;
  final double commissionAmount;
  final double totalAmount;

  const OrderTotals({
    required this.subtotal,
    required this.deliveryFee,
    required this.sstAmount,
    required this.discountAmount,
    required this.commissionAmount,
    required this.totalAmount,
  });
}

/// Order confirmation
class OrderConfirmation {
  final String orderNumber;
  final String orderId;
  final String customerName;
  final String vendorName;
  final double totalAmount;
  final DateTime estimatedDeliveryTime;
  final String confirmationMessage;
  final String trackingUrl;
  final DateTime createdAt;

  const OrderConfirmation({
    required this.orderNumber,
    required this.orderId,
    required this.customerName,
    required this.vendorName,
    required this.totalAmount,
    required this.estimatedDeliveryTime,
    required this.confirmationMessage,
    required this.trackingUrl,
    required this.createdAt,
  });
}
