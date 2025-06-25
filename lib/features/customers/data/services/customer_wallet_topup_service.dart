import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for handling wallet top-up operations with Supabase Edge Functions
class CustomerWalletTopupService {
  final SupabaseClient _client = Supabase.instance.client;

  /// Create a payment intent for wallet top-up
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    String currency = 'myr',
    bool savePaymentMethod = false,
  }) async {
    try {
      debugPrint('🔍 [WALLET-TOPUP-SERVICE] Creating payment intent for RM $amount');

      // Validate amount
      if (amount < 1 || amount > 10000) {
        throw Exception('Amount must be between RM 1.00 and RM 10,000.00');
      }

      // Get current user
      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call the wallet-topup Edge Function
      final response = await _client.functions.invoke(
        'wallet-topup',
        body: {
          'amount': amount,
          'currency': currency,
          'save_payment_method': savePaymentMethod,
        },
      );

      debugPrint('🔍 [WALLET-TOPUP-SERVICE] Edge Function response status: ${response.status}');

      if (response.status != 200) {
        final errorData = response.data as Map<String, dynamic>?;
        final errorMessage = errorData?['error'] ?? 'Unknown error occurred';
        throw Exception('Payment intent creation failed: $errorMessage');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['success'] != true) {
        final errorMessage = data['error'] ?? 'Unknown error occurred';
        throw Exception(errorMessage);
      }

      debugPrint('✅ [WALLET-TOPUP-SERVICE] Payment intent created successfully');
      
      return {
        'client_secret': data['client_secret'],
        'transaction_id': data['transaction_id'],
        'requires_action': data['requires_action'] ?? false,
      };
    } catch (e) {
      debugPrint('❌ [WALLET-TOPUP-SERVICE] Service error: $e');

      // Handle specific function errors
      if (e.toString().contains('FunctionsException')) {
        throw Exception('Service temporarily unavailable. Please try again later.');
      }

      // Handle other errors
      debugPrint('❌ [WALLET-TOPUP-SERVICE] Unexpected error: $e');
      rethrow;
    }
  }

  /// Get wallet top-up history
  Future<List<Map<String, dynamic>>> getTopupHistory({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 [WALLET-TOPUP-SERVICE] Getting top-up history');

      final user = _client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Call the database function to get top-up history
      final response = await _client.rpc(
        'get_wallet_topup_history',
        params: {
          'user_id_param': user.id,
          'limit_param': limit,
          'offset_param': offset,
        },
      );

      debugPrint('✅ [WALLET-TOPUP-SERVICE] Retrieved ${response.length} top-up records');
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('❌ [WALLET-TOPUP-SERVICE] Error getting top-up history: $e');
      rethrow;
    }
  }

  /// Validate top-up amount
  bool isValidAmount(double amount) {
    return amount >= 1.0 && amount <= 10000.0;
  }

  /// Get formatted amount string
  String formatAmount(double amount) {
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  /// Get minimum top-up amount
  double get minAmount => 1.0;

  /// Get maximum top-up amount
  double get maxAmount => 10000.0;
}
