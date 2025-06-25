import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_transfer.dart';
import '../models/transfer_limits.dart';
import '../models/transfer_fees.dart';

/// Service for managing wallet-to-wallet transfers
class WalletTransferService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Validate a transfer recipient by email, phone, or user ID
  Future<TransferRecipient> validateRecipient(String recipientIdentifier) async {
    try {
      debugPrint('🔍 [WALLET-TRANSFER] Validating recipient: $recipientIdentifier');

      final response = await _supabase.functions.invoke(
        'wallet-transfer',
        body: {
          'action': 'validate_recipient',
          'recipient_identifier': recipientIdentifier,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to validate recipient');
      }

      final recipient = TransferRecipient.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [WALLET-TRANSFER] Recipient validated: ${recipient.name}');
      return recipient;
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error validating recipient: $e');
      throw Exception('Failed to validate recipient: $e');
    }
  }

  /// Get transfer limits and current usage for the user
  Future<TransferLimitsWithUsage> getTransferLimits() async {
    try {
      debugPrint('🔍 [WALLET-TRANSFER] Fetching transfer limits');

      final response = await _supabase.functions.invoke(
        'wallet-transfer',
        body: {
          'action': 'get_limits',
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to fetch transfer limits');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      final limits = TransferLimits.fromJson(data['limits'] as Map<String, dynamic>);
      final usage = TransferUsage.fromJson(data['usage'] as Map<String, dynamic>);

      final limitsWithUsage = TransferLimitsWithUsage(limits: limits, usage: usage);

      debugPrint('✅ [WALLET-TRANSFER] Transfer limits fetched successfully');
      return limitsWithUsage;
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error fetching transfer limits: $e');
      throw Exception('Failed to fetch transfer limits: $e');
    }
  }

  /// Calculate transfer fees for a given amount
  Future<TransferFeeCalculation> calculateTransferFees(double amount) async {
    try {
      debugPrint('🔍 [WALLET-TRANSFER] Calculating fees for amount: $amount');

      final response = await _supabase.functions.invoke(
        'wallet-transfer',
        body: {
          'action': 'get_fees',
          'amount': amount,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to calculate transfer fees');
      }

      final feeCalculation = TransferFeeCalculation.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [WALLET-TRANSFER] Fees calculated: ${feeCalculation.formattedTransferFee}');
      return feeCalculation;
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error calculating fees: $e');
      throw Exception('Failed to calculate transfer fees: $e');
    }
  }

  /// Initiate a wallet transfer
  Future<WalletTransfer> initiateTransfer({
    required String recipientIdentifier,
    required double amount,
    String? description,
  }) async {
    try {
      debugPrint('🔍 [WALLET-TRANSFER] Initiating transfer: $amount to $recipientIdentifier');

      final response = await _supabase.functions.invoke(
        'wallet-transfer',
        body: {
          'action': 'initiate',
          'recipient_identifier': recipientIdentifier,
          'amount': amount,
          'description': description,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to initiate transfer');
      }

      final transfer = WalletTransfer.fromJson(
        response.data['data'] as Map<String, dynamic>,
      );

      debugPrint('✅ [WALLET-TRANSFER] Transfer initiated: ${transfer.referenceNumber}');
      return transfer;
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error initiating transfer: $e');
      throw Exception('Failed to initiate transfer: $e');
    }
  }

  /// Get transfer history with pagination
  Future<List<WalletTransfer>> getTransferHistory({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      debugPrint('🔍 [WALLET-TRANSFER] Fetching transfer history (page: $page, limit: $limit)');

      final response = await _supabase.functions.invoke(
        'wallet-transfer',
        body: {
          'action': 'get_history',
          'page': page,
          'limit': limit,
        },
      );

      if (response.data['success'] != true) {
        throw Exception(response.data['error'] ?? 'Failed to fetch transfer history');
      }

      final data = response.data['data'] as Map<String, dynamic>;
      final transfersData = data['transfers'] as List<dynamic>;
      
      final transfers = transfersData
          .map((json) => WalletTransfer.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [WALLET-TRANSFER] Found ${transfers.length} transfers');
      return transfers;
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error fetching transfer history: $e');
      throw Exception('Failed to fetch transfer history: $e');
    }
  }

  /// Get transfer by ID
  Future<WalletTransfer?> getTransferById(String transferId) async {
    try {
      final transfers = await getTransferHistory(limit: 100);
      return transfers.where((transfer) => transfer.id == transferId).firstOrNull;
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error getting transfer by ID: $e');
      return null;
    }
  }

  /// Get recent transfers (last 10)
  Future<List<WalletTransfer>> getRecentTransfers() async {
    try {
      return await getTransferHistory(page: 0, limit: 10);
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error getting recent transfers: $e');
      return [];
    }
  }

  /// Get pending transfers
  Future<List<WalletTransfer>> getPendingTransfers() async {
    try {
      final allTransfers = await getTransferHistory(limit: 50);
      return allTransfers.where((transfer) => transfer.isInProgress).toList();
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error getting pending transfers: $e');
      return [];
    }
  }

  /// Get completed transfers
  Future<List<WalletTransfer>> getCompletedTransfers({
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final allTransfers = await getTransferHistory(page: page, limit: limit);
      return allTransfers.where((transfer) => transfer.isCompleted).toList();
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error getting completed transfers: $e');
      return [];
    }
  }

  /// Get failed transfers
  Future<List<WalletTransfer>> getFailedTransfers() async {
    try {
      final allTransfers = await getTransferHistory(limit: 50);
      return allTransfers.where((transfer) => transfer.hasFailed).toList();
    } catch (e) {
      debugPrint('❌ [WALLET-TRANSFER] Error getting failed transfers: $e');
      return [];
    }
  }

  /// Validate transfer amount against limits
  Future<String?> validateTransferAmount(double amount) async {
    try {
      final limitsWithUsage = await getTransferLimits();
      return limitsWithUsage.getTransferValidationMessage(amount);
    } catch (e) {
      return 'Unable to validate transfer amount. Please try again.';
    }
  }

  /// Check if user can make a transfer
  Future<bool> canMakeTransfer(double amount) async {
    try {
      final limitsWithUsage = await getTransferLimits();
      return limitsWithUsage.canTransfer(amount);
    } catch (e) {
      return false;
    }
  }

  /// Get user-friendly error message
  String getErrorMessage(String error) {
    if (error.contains('Recipient not found')) {
      return 'Recipient not found. Please check the email, phone number, or user ID.';
    } else if (error.contains('Cannot transfer to yourself')) {
      return 'You cannot transfer money to yourself.';
    } else if (error.contains('Insufficient balance')) {
      return 'Insufficient wallet balance for this transfer.';
    } else if (error.contains('limit exceeded')) {
      return error; // Already user-friendly from backend
    } else if (error.contains('Minimum transfer amount')) {
      return error; // Already user-friendly from backend
    } else if (error.contains('Maximum transfer amount')) {
      return error; // Already user-friendly from backend
    } else if (error.contains('wallet is not active')) {
      return 'The recipient\'s wallet is not active. Please contact support.';
    } else if (error.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (error.contains('unauthorized')) {
      return 'You are not authorized to perform this action.';
    } else {
      return 'An unexpected error occurred. Please try again.';
    }
  }

  /// Format transfer amount for display
  String formatTransferAmount(double amount) {
    return 'RM ${amount.toStringAsFixed(2)}';
  }

  /// Get transfer status color for UI
  String getTransferStatusColor(TransferStatus status) {
    switch (status) {
      case TransferStatus.pending:
        return 'orange';
      case TransferStatus.processing:
        return 'blue';
      case TransferStatus.completed:
        return 'green';
      case TransferStatus.failed:
        return 'red';
      case TransferStatus.cancelled:
        return 'grey';
      case TransferStatus.reversed:
        return 'purple';
    }
  }

  /// Check if recipient identifier is valid format
  bool isValidRecipientIdentifier(String identifier) {
    if (identifier.trim().isEmpty) return false;

    // Check if it's an email
    if (identifier.contains('@')) {
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
      return emailRegex.hasMatch(identifier);
    }

    // Check if it's a phone number
    if (identifier.startsWith('+') || RegExp(r'^\d+$').hasMatch(identifier)) {
      return identifier.length >= 8; // Minimum phone number length
    }

    // Check if it's a user ID (UUID format)
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
    );
    return uuidRegex.hasMatch(identifier);
  }
}
