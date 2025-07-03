import 'dart:convert';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Repository for payment-related operations
class PaymentRepository {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Create a payment record
  Future<Map<String, dynamic>> createPayment({
    required String orderId,
    required String paymentMethod,
    required double amount,
    required String currency,
    String? transactionId,
    String? referenceNumber,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase
          .from('payments')
          .insert({
            'order_id': orderId,
            'payment_method': paymentMethod,
            'amount': amount,
            'currency': currency,
            'transaction_id': transactionId,
            'reference_number': referenceNumber,
            'status': 'pending',
            'metadata': metadata,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  /// Update payment status
  Future<Map<String, dynamic>> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? transactionId,
    DateTime? paidAt,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final updateData = {
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (transactionId != null) updateData['transaction_id'] = transactionId;
      if (paidAt != null) updateData['paid_at'] = paidAt.toIso8601String();
      if (metadata != null) updateData['metadata'] = jsonEncode(metadata);

      final response = await _supabase
          .from('payments')
          .update(updateData)
          .eq('id', paymentId)
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  /// Get payment by order ID
  Future<Map<String, dynamic>?> getPaymentByOrderId(String orderId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*')
          .eq('order_id', orderId)
          .maybeSingle();

      return response;
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  /// Get payment history for a user
  Future<List<Map<String, dynamic>>> getPaymentHistory({
    required String userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('payments')
          .select('*, orders!inner(customer_id)')
          .eq('orders.customer_id', userId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch payment history: $e');
    }
  }

  /// Process refund
  Future<Map<String, dynamic>> processRefund({
    required String paymentId,
    required double refundAmount,
    String? reason,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await _supabase
          .from('refunds')
          .insert({
            'payment_id': paymentId,
            'refund_amount': refundAmount,
            'reason': reason,
            'status': 'pending',
            'metadata': metadata,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();

      return response;
    } catch (e) {
      throw Exception('Failed to process refund: $e');
    }
  }
}
