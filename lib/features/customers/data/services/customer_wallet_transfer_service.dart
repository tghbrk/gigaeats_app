import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/customer_wallet_transfer.dart';

/// Service for handling wallet-to-wallet transfers
class CustomerWalletTransferService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Process a wallet-to-wallet transfer
  Future<CustomerWalletTransfer> processTransfer({
    required String senderUserId,
    required String recipientIdentifier,
    required double amount,
    String? note,
  }) async {
    try {
      // Call the wallet transfer Edge Function
      final response = await _supabase.functions.invoke(
        'wallet-transfer',
        body: {
          'sender_user_id': senderUserId,
          'recipient_identifier': recipientIdentifier,
          'amount': amount,
          'note': note,
        },
      );

      if (response.data == null) {
        throw Exception('Transfer failed: No response data');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Transfer failed: ${data['error']}');
      }

      if (data['transfer'] == null) {
        throw Exception('Transfer failed: Invalid response format');
      }

      return CustomerWalletTransfer.fromJson(data['transfer'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Transfer failed: ${e.details}');
    } catch (e) {
      throw Exception('Transfer failed: ${e.toString()}');
    }
  }

  /// Get recent transfers for a user
  Future<List<CustomerWalletTransfer>> getRecentTransfers(String userId, {int limit = 10}) async {
    try {
      final response = await _supabase
          .from('wallet_transfers')
          .select('*')
          .or('sender_user_id.eq.$userId,recipient_user_id.eq.$userId')
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) => CustomerWalletTransfer.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to load transfers: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load transfers: ${e.toString()}');
    }
  }

  /// Validate if a recipient exists and can receive transfers
  Future<bool> validateRecipient(String recipientIdentifier) async {
    try {
      final response = await _supabase.functions.invoke(
        'validate-transfer-recipient',
        body: {
          'recipient_identifier': recipientIdentifier,
        },
      );

      if (response.data == null) {
        return false;
      }

      final data = response.data as Map<String, dynamic>;
      return data['valid'] == true;
    } catch (e) {
      // If validation service fails, assume invalid for safety
      return false;
    }
  }

  /// Get transfer limits for a user
  Future<Map<String, double>> getTransferLimits(String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-transfer-limits',
        body: {
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to get transfer limits');
      }

      final data = response.data as Map<String, dynamic>;
      
      if (data['error'] != null) {
        throw Exception('Failed to get transfer limits: ${data['error']}');
      }

      return {
        'daily_limit': (data['daily_limit'] as num).toDouble(),
        'weekly_limit': (data['weekly_limit'] as num).toDouble(),
        'monthly_limit': (data['monthly_limit'] as num).toDouble(),
        'per_transaction_limit': (data['per_transaction_limit'] as num).toDouble(),
        'remaining_daily': (data['remaining_daily'] as num).toDouble(),
        'remaining_weekly': (data['remaining_weekly'] as num).toDouble(),
        'remaining_monthly': (data['remaining_monthly'] as num).toDouble(),
      };
    } on FunctionException catch (e) {
      throw Exception('Failed to get transfer limits: ${e.details}');
    } catch (e) {
      throw Exception('Failed to get transfer limits: ${e.toString()}');
    }
  }

  /// Get transfer history with filters
  Future<List<CustomerWalletTransfer>> getTransferHistory({
    required String userId,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
    int? limit,
    int? offset,
  }) async {
    try {
      var query = _supabase
          .from('wallet_transfers')
          .select('*')
          .or('sender_user_id.eq.$userId,recipient_user_id.eq.$userId');

      if (status != null) {
        query = query.eq('status', status);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      var finalQuery = query.order('created_at', ascending: false);

      if (limit != null) {
        finalQuery = finalQuery.limit(limit);
      }

      if (offset != null) {
        finalQuery = finalQuery.range(offset, offset + (limit ?? 10) - 1);
      }

      final response = await finalQuery;

      return (response as List<dynamic>)
          .map((json) => CustomerWalletTransfer.fromJson(json as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      throw Exception('Failed to load transfer history: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load transfer history: ${e.toString()}');
    }
  }

  /// Cancel a pending transfer
  Future<CustomerWalletTransfer> cancelTransfer(String transferId, String userId) async {
    try {
      final response = await _supabase.functions.invoke(
        'cancel-transfer',
        body: {
          'transfer_id': transferId,
          'user_id': userId,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to cancel transfer');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to cancel transfer: ${data['error']}');
      }

      return CustomerWalletTransfer.fromJson(data['transfer'] as Map<String, dynamic>);
    } on FunctionException catch (e) {
      throw Exception('Failed to cancel transfer: ${e.details}');
    } catch (e) {
      throw Exception('Failed to cancel transfer: ${e.toString()}');
    }
  }

  /// Get transfer details by ID
  Future<CustomerWalletTransfer> getTransferById(String transferId, String userId) async {
    try {
      final response = await _supabase
          .from('wallet_transfers')
          .select('*')
          .eq('id', transferId)
          .or('sender_user_id.eq.$userId,recipient_user_id.eq.$userId')
          .single();

      return CustomerWalletTransfer.fromJson(response);
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        throw Exception('Transfer not found');
      }
      throw Exception('Failed to load transfer: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load transfer: ${e.toString()}');
    }
  }

  /// Get transfer statistics for a user
  Future<Map<String, dynamic>> getTransferStatistics(String userId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'get-transfer-statistics',
        body: {
          'user_id': userId,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      if (response.data == null) {
        throw Exception('Failed to get transfer statistics');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to get transfer statistics: ${data['error']}');
      }

      return {
        'total_sent': (data['total_sent'] as num).toDouble(),
        'total_received': (data['total_received'] as num).toDouble(),
        'total_transfers': data['total_transfers'] as int,
        'sent_count': data['sent_count'] as int,
        'received_count': data['received_count'] as int,
        'average_amount': (data['average_amount'] as num).toDouble(),
        'largest_transfer': (data['largest_transfer'] as num).toDouble(),
        'most_frequent_recipient': data['most_frequent_recipient'] as String?,
      };
    } on FunctionException catch (e) {
      throw Exception('Failed to get transfer statistics: ${e.details}');
    } catch (e) {
      throw Exception('Failed to get transfer statistics: ${e.toString()}');
    }
  }

  /// Search for potential recipients
  Future<List<Map<String, dynamic>>> searchRecipients(String query, String currentUserId) async {
    try {
      final response = await _supabase.functions.invoke(
        'search-transfer-recipients',
        body: {
          'query': query,
          'current_user_id': currentUserId,
        },
      );

      if (response.data == null) {
        return [];
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to search recipients: ${data['error']}');
      }

      return List<Map<String, dynamic>>.from(data['recipients'] ?? []);
    } catch (e) {
      // Return empty list if search fails
      return [];
    }
  }

  /// Get recent recipients for quick selection
  Future<List<Map<String, dynamic>>> getRecentRecipients(String userId, {int limit = 5}) async {
    try {
      final response = await _supabase
          .from('wallet_transfers')
          .select('recipient_identifier, recipient_user_id')
          .eq('sender_user_id', userId)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(limit);

      // Remove duplicates and return unique recipients
      final seen = <String>{};
      final uniqueRecipients = <Map<String, dynamic>>[];

      for (final transfer in response as List<dynamic>) {
        final identifier = transfer['recipient_identifier'] as String;
        if (!seen.contains(identifier)) {
          seen.add(identifier);
          uniqueRecipients.add({
            'identifier': identifier,
            'user_id': transfer['recipient_user_id'],
          });
        }
      }

      return uniqueRecipients;
    } on PostgrestException catch (e) {
      throw Exception('Failed to load recent recipients: ${e.message}');
    } catch (e) {
      throw Exception('Failed to load recent recipients: ${e.toString()}');
    }
  }
}
