import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/logger.dart';
import '../models/driver_withdrawal_request.dart';


/// Repository for managing driver withdrawal operations
class DriverWithdrawalRepository {
  final SupabaseClient _supabase;
  final AppLogger _logger;

  DriverWithdrawalRepository({
    required SupabaseClient supabase,
    required AppLogger logger,
  }) : _supabase = supabase,
       _logger = logger;

  /// Create a new withdrawal request
  Future<DriverWithdrawalRequest> createWithdrawalRequest({
    required String driverId,
    required String walletId,
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> destinationDetails,
    String? notes,
  }) async {
    try {
      debugPrint('🔍 [DRIVER-WITHDRAWAL-REPO] Creating withdrawal request');
      
      final requestData = {
        'driver_id': driverId,
        'wallet_id': walletId,
        'amount': amount,
        'withdrawal_method': withdrawalMethod,
        'destination_details': destinationDetails,
        'status': 'pending',
        'processing_fee': 0.00,
        'net_amount': amount,
        'notes': notes,
        'requested_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('driver_withdrawal_requests')
          .insert(requestData)
          .select()
          .single();

      final request = DriverWithdrawalRequest.fromJson(response);
      debugPrint('✅ [DRIVER-WITHDRAWAL-REPO] Withdrawal request created: ${request.id}');
      
      return request;
    } catch (e) {
      _logger.error('Failed to create withdrawal request', e);
      rethrow;
    }
  }

  /// Get withdrawal request by ID
  Future<DriverWithdrawalRequest?> getWithdrawalRequestById(String requestId) async {
    try {
      debugPrint('🔍 [DRIVER-WITHDRAWAL-REPO] Getting withdrawal request: $requestId');
      
      final response = await _supabase
          .from('driver_withdrawal_requests')
          .select('*')
          .eq('id', requestId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ [DRIVER-WITHDRAWAL-REPO] Withdrawal request not found: $requestId');
        return null;
      }

      return DriverWithdrawalRequest.fromJson(response);
    } catch (e) {
      _logger.error('Failed to get withdrawal request', e);
      rethrow;
    }
  }

  /// Get withdrawal requests for a driver
  Future<List<DriverWithdrawalRequest>> getDriverWithdrawalRequests({
    required String driverId,
    int limit = 50,
    int offset = 0,
    String? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 [DRIVER-WITHDRAWAL-REPO] Getting driver withdrawal requests');
      
      var queryBuilder = _supabase
          .from('driver_withdrawal_requests')
          .select('*')
          .eq('driver_id', driverId);

      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      final response = await queryBuilder
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map((data) => DriverWithdrawalRequest.fromJson(data)).toList();
    } catch (e) {
      _logger.error('Failed to get driver withdrawal requests', e);
      rethrow;
    }
  }

  /// Update withdrawal request status
  Future<DriverWithdrawalRequest> updateWithdrawalStatus({
    required String requestId,
    required String status,
    String? notes,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('🔍 [DRIVER-WITHDRAWAL-REPO] Updating withdrawal status: $requestId -> $status');
      
      final updateData = <String, dynamic>{
        'status': status,
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (notes != null) {
        updateData['notes'] = notes;
      }

      if (additionalData != null) {
        updateData.addAll(additionalData);
      }

      final response = await _supabase
          .from('driver_withdrawal_requests')
          .update(updateData)
          .eq('id', requestId)
          .select()
          .single();

      final request = DriverWithdrawalRequest.fromJson(response);
      debugPrint('✅ [DRIVER-WITHDRAWAL-REPO] Withdrawal status updated: ${request.id} -> ${request.status}');
      
      return request;
    } catch (e) {
      _logger.error('Failed to update withdrawal status', e);
      rethrow;
    }
  }

  /// Cancel withdrawal request
  Future<DriverWithdrawalRequest> cancelWithdrawalRequest({
    required String requestId,
    String? reason,
  }) async {
    try {
      debugPrint('🔍 [DRIVER-WITHDRAWAL-REPO] Cancelling withdrawal request: $requestId');
      
      return await updateWithdrawalStatus(
        requestId: requestId,
        status: 'cancelled',
        notes: reason,
        additionalData: {
          'cancelled_at': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      _logger.error('Failed to cancel withdrawal request', e);
      rethrow;
    }
  }

  /// Get withdrawal statistics for a driver
  Future<Map<String, dynamic>> getWithdrawalStatistics({
    required String driverId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      debugPrint('🔍 [DRIVER-WITHDRAWAL-REPO] Getting withdrawal statistics');
      
      var queryBuilder = _supabase
          .from('driver_withdrawal_requests')
          .select('status, amount, processing_fee, net_amount')
          .eq('driver_id', driverId);

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      final response = await queryBuilder;

      // Calculate statistics
      double totalRequested = 0.0;
      double totalProcessed = 0.0;
      double totalFees = 0.0;
      int totalCount = response.length;
      int pendingCount = 0;
      int completedCount = 0;
      int cancelledCount = 0;

      for (final record in response) {
        final amount = (record['amount'] as num?)?.toDouble() ?? 0.0;
        final fee = (record['processing_fee'] as num?)?.toDouble() ?? 0.0;
        final status = record['status'] as String?;

        totalRequested += amount;
        totalFees += fee;

        switch (status) {
          case 'completed':
            totalProcessed += amount;
            completedCount++;
            break;
          case 'pending':
          case 'processing':
            pendingCount++;
            break;
          case 'cancelled':
          case 'rejected':
            cancelledCount++;
            break;
        }
      }

      return {
        'total_count': totalCount,
        'pending_count': pendingCount,
        'completed_count': completedCount,
        'cancelled_count': cancelledCount,
        'total_requested': totalRequested,
        'total_processed': totalProcessed,
        'total_fees': totalFees,
        'average_amount': totalCount > 0 ? totalRequested / totalCount : 0.0,
      };
    } catch (e) {
      _logger.error('Failed to get withdrawal statistics', e);
      rethrow;
    }
  }
}
