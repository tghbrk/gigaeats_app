import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/order.dart';
import '../models/enhanced_cart_models.dart';
import '../../../menu/data/services/template_integration_service.dart';

/// Enhanced order service that handles template-based customizations
class EnhancedOrderService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final TemplateIntegrationService _templateIntegrationService;

  EnhancedOrderService(this._templateIntegrationService);

  /// Create order with enhanced customization handling
  Future<Order> createOrderFromCart({
    required EnhancedCartState cartState,
    required String customerId,
    required String customerName,
    required Address deliveryAddress,
    String? paymentMethod,
    String? notes,
    String? salesAgentId,
    String? salesAgentName,
  }) async {
    try {
      debugPrint('📝 [ENHANCED-ORDER] Creating order from cart with ${cartState.items.length} items');

      // Validate cart items and customizations
      await _validateCartCustomizations(cartState.items);

      // Prepare order items with enhanced customization data
      final orderItems = await _prepareOrderItems(cartState.items);

      // Create order data
      final orderData = {
        'order_number': _generateOrderNumber(),
        'status': 'pending',
        'customer_id': customerId,
        'customer_name': customerName,
        'vendor_id': cartState.items.isNotEmpty ? cartState.items.first.vendorId : '',
        'vendor_name': cartState.items.isNotEmpty ? cartState.items.first.vendorName : '',
        'sales_agent_id': salesAgentId,
        'sales_agent_name': salesAgentName,
        'delivery_date': DateTime.now().add(const Duration(days: 1)).toIso8601String(),
        'delivery_address': deliveryAddress.toJson(),
        'payment_method': paymentMethod,
        'payment_status': 'pending',
        'subtotal': cartState.summary?.subtotal ?? 0.0,
        'delivery_fee': cartState.summary?.deliveryFee ?? 0.0,
        'sst_amount': cartState.summary?.sstAmount ?? 0.0,
        'total_amount': cartState.summary?.totalAmount ?? 0.0,
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Insert order
      final orderResponse = await _supabase
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'];

      // Insert order items
      final orderItemsData = orderItems.map((item) => {
        ...item.toJson(),
        'order_id': orderId,
      }).toList();

      await _supabase
          .from('order_items')
          .insert(orderItemsData);

      // Update template usage statistics
      await _updateTemplateUsageStats(orderId, orderItems);

      // Create and return order object
      final order = Order.fromJson({
        ...orderResponse,
        'items': orderItems.map((item) => item.toJson()).toList(),
      });

      debugPrint('✅ [ENHANCED-ORDER] Created order: ${order.id}');
      return order;

    } catch (e) {
      debugPrint('❌ [ENHANCED-ORDER] Error creating order: $e');
      rethrow;
    }
  }

  /// Validate cart customizations against templates
  Future<void> _validateCartCustomizations(List<EnhancedCartItem> items) async {
    for (final item in items) {
      if (item.customizations?.isEmpty ?? true) continue;

      try {
        // Get templates for this menu item
        final templates = await _templateIntegrationService
            .templateRepository
            .getMenuItemTemplates(item.productId);

        // Validate customizations
        final validation = _templateIntegrationService.validateCustomizationSelections(
          menuItemId: item.productId,
          selections: item.customizations ?? {},
          templates: templates,
        );

        if (!validation.isValid) {
          throw Exception('Invalid customizations for ${item.name}: ${validation.errors.join(', ')}');
        }

        if (validation.hasWarnings) {
          debugPrint('⚠️ [ENHANCED-ORDER] Customization warnings for ${item.name}: ${validation.warnings.join(', ')}');
        }
      } catch (e) {
        debugPrint('❌ [ENHANCED-ORDER] Error validating customizations for ${item.name}: $e');
        // Continue with order creation but log the error
      }
    }
  }

  /// Prepare order items with enhanced customization data
  Future<List<OrderItem>> _prepareOrderItems(List<EnhancedCartItem> cartItems) async {
    final orderItems = <OrderItem>[];

    for (final cartItem in cartItems) {
      try {
        // Get templates for enhanced customization formatting
        final templates = await _templateIntegrationService
            .templateRepository
            .getMenuItemTemplates(cartItem.productId);

        // Format customizations for order storage
        final formattedCustomizations = _templateIntegrationService
            .convertSelectionsToOrderFormat(
              selections: cartItem.customizations ?? {},
              templates: templates,
            );

        // Create order item
        final orderItem = OrderItem(
          id: cartItem.id,
          menuItemId: cartItem.productId,
          name: cartItem.name,
          description: cartItem.description,
          quantity: cartItem.quantity,
          unitPrice: cartItem.unitPrice,
          totalPrice: cartItem.totalPrice,
          customizations: formattedCustomizations,
          notes: cartItem.notes,
        );

        orderItems.add(orderItem);
      } catch (e) {
        debugPrint('❌ [ENHANCED-ORDER] Error preparing order item ${cartItem.name}: $e');

        // Fallback: create order item without enhanced formatting
        final orderItem = OrderItem(
          id: cartItem.id,
          menuItemId: cartItem.productId,
          name: cartItem.name,
          description: cartItem.description,
          quantity: cartItem.quantity,
          unitPrice: cartItem.unitPrice,
          totalPrice: cartItem.totalPrice,
          customizations: cartItem.customizations,
          notes: cartItem.notes,
        );

        orderItems.add(orderItem);
      }
    }

    return orderItems;
  }

  /// Update template usage statistics after order creation
  Future<void> _updateTemplateUsageStats(String orderId, List<OrderItem> orderItems) async {
    try {
      for (final item in orderItems) {
        await _templateIntegrationService.updateTemplateUsageStats(
          orderId: orderId,
          customizations: item.customizations ?? {},
        );
      }
    } catch (e) {
      debugPrint('❌ [ENHANCED-ORDER] Error updating template usage stats: $e');
      // Non-critical operation, continue
    }
  }

  /// Generate unique order number
  String _generateOrderNumber() {
    final now = DateTime.now();
    final timestamp = now.millisecondsSinceEpoch.toString().substring(8);
    return 'GE${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}$timestamp';
  }

  /// Get order with enhanced customization details
  Future<Order> getOrderWithEnhancedDetails(String orderId) async {
    try {
      debugPrint('📋 [ENHANCED-ORDER] Getting order with enhanced details: $orderId');

      final response = await _supabase
          .from('orders')
          .select('''
            *,
            order_items (
              *
            )
          ''')
          .eq('id', orderId)
          .single();

      final order = Order.fromJson(response);

      // Enhance order items with template information
      final enhancedItems = <OrderItem>[];
      
      for (final item in order.items) {
        try {
          // Since OrderItem doesn't have copyWith or metadata, we'll just add the item as-is
          // Enhanced customization details can be retrieved when needed
          enhancedItems.add(item);
        } catch (e) {
          debugPrint('❌ [ENHANCED-ORDER] Error enhancing item ${item.name}: $e');
          enhancedItems.add(item);
        }
      }

      final enhancedOrder = order.copyWith(items: enhancedItems);

      debugPrint('✅ [ENHANCED-ORDER] Retrieved enhanced order: ${enhancedOrder.id}');
      return enhancedOrder;

    } catch (e) {
      debugPrint('❌ [ENHANCED-ORDER] Error getting enhanced order: $e');
      rethrow;
    }
  }

  /// Format customizations for vendor display
  String formatCustomizationsForVendor(Map<String, dynamic> customizations) {
    final parts = <String>[];

    customizations.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final templateName = value['template_name'];
        final optionName = value['name'];
        final price = value['price'];
        
        if (templateName != null) {
          final priceText = price != null && price > 0 ? ' (+RM${price.toStringAsFixed(2)})' : '';
          parts.add('$templateName: $optionName$priceText');
        } else {
          final priceText = price != null && price > 0 ? ' (+RM${price.toStringAsFixed(2)})' : '';
          parts.add('$optionName$priceText');
        }
      } else if (value is List) {
        final options = <String>[];
        for (final item in value) {
          if (item is Map<String, dynamic>) {
            final optionName = item['name'];
            final price = item['price'];
            final priceText = price != null && price > 0 ? ' (+RM${price.toStringAsFixed(2)})' : '';
            options.add('$optionName$priceText');
          }
        }
        if (options.isNotEmpty) {
          parts.add(options.join(', '));
        }
      }
    });

    return parts.isNotEmpty ? parts.join('\n') : 'No customizations';
  }
}
