import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/driver_withdrawal_request.dart';

import 'enhanced_withdrawal_notification_service.dart';

/// Service for tracking real-time balance changes related to withdrawals
class WithdrawalBalanceTracker {
  final SupabaseClient _supabase;
  final EnhancedWithdrawalNotificationService _notificationService;
  
  RealtimeChannel? _walletChannel;
  RealtimeChannel? _withdrawalChannel;
  
  // Track balance state
  double? _lastKnownBalance;
  Map<String, DriverWithdrawalRequest> _activeWithdrawals = {};
  
  WithdrawalBalanceTracker({
    required SupabaseClient supabase,
    required EnhancedWithdrawalNotificationService notificationService,
  })  : _supabase = supabase,
        _notificationService = notificationService;

  /// Start tracking balance changes for a specific driver
  Future<void> startTracking(String driverId) async {
    try {
      debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Starting balance tracking for driver: $driverId');
      
      // Load initial state
      await _loadInitialState(driverId);
      
      // Setup real-time subscriptions
      await _setupWalletSubscription(driverId);
      await _setupWithdrawalSubscription(driverId);
      
      debugPrint('✅ [WITHDRAWAL-BALANCE-TRACKER] Balance tracking started successfully');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error starting balance tracking: $e');
      rethrow;
    }
  }

  /// Stop tracking and cleanup subscriptions
  Future<void> stopTracking() async {
    try {
      debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Stopping balance tracking');
      
      if (_walletChannel != null) {
        await _walletChannel!.unsubscribe();
        _walletChannel = null;
      }
      
      if (_withdrawalChannel != null) {
        await _withdrawalChannel!.unsubscribe();
        _withdrawalChannel = null;
      }
      
      // Clear state
      _lastKnownBalance = null;
      _activeWithdrawals.clear();
      
      debugPrint('✅ [WITHDRAWAL-BALANCE-TRACKER] Balance tracking stopped');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error stopping balance tracking: $e');
    }
  }

  /// Load initial wallet and withdrawal state
  Future<void> _loadInitialState(String driverId) async {
    try {
      debugPrint('🔍 [WITHDRAWAL-BALANCE-TRACKER] Loading initial state');
      
      // Load current wallet balance
      final walletResponse = await _supabase
          .from('driver_wallets')
          .select('available_balance')
          .eq('driver_id', driverId)
          .single();
      
      _lastKnownBalance = (walletResponse['available_balance'] as num?)?.toDouble();
      debugPrint('🔍 [WITHDRAWAL-BALANCE-TRACKER] Initial balance: RM ${_lastKnownBalance?.toStringAsFixed(2) ?? 'N/A'}');
      
      // Load active withdrawal requests
      final withdrawalResponse = await _supabase
          .from('driver_withdrawal_requests')
          .select('*')
          .eq('driver_id', driverId)
          .inFilter('status', ['pending', 'processing']);
      
      _activeWithdrawals = {
        for (final data in withdrawalResponse)
          data['id'] as String: DriverWithdrawalRequest.fromJson(data)
      };
      
      debugPrint('🔍 [WITHDRAWAL-BALANCE-TRACKER] Active withdrawals: ${_activeWithdrawals.length}');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error loading initial state: $e');
      rethrow;
    }
  }

  /// Setup real-time subscription for wallet balance changes
  Future<void> _setupWalletSubscription(String driverId) async {
    try {
      debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Setting up wallet subscription');
      
      _walletChannel = _supabase
          .channel('withdrawal_wallet_tracking_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.update,
            schema: 'public',
            table: 'driver_wallets',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'driver_id',
              value: driverId,
            ),
            callback: (payload) {
              debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Wallet balance update received');
              _handleWalletBalanceUpdate(driverId, payload);
            },
          )
          .subscribe();
      
      debugPrint('✅ [WITHDRAWAL-BALANCE-TRACKER] Wallet subscription established');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error setting up wallet subscription: $e');
      rethrow;
    }
  }

  /// Setup real-time subscription for withdrawal status changes
  Future<void> _setupWithdrawalSubscription(String driverId) async {
    try {
      debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Setting up withdrawal subscription');
      
      _withdrawalChannel = _supabase
          .channel('withdrawal_status_tracking_$driverId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'driver_withdrawal_requests',
            filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'driver_id',
              value: driverId,
            ),
            callback: (payload) {
              debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Withdrawal status update received');
              _handleWithdrawalStatusUpdate(driverId, payload);
            },
          )
          .subscribe();
      
      debugPrint('✅ [WITHDRAWAL-BALANCE-TRACKER] Withdrawal subscription established');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error setting up withdrawal subscription: $e');
      rethrow;
    }
  }

  /// Handle wallet balance updates and correlate with withdrawals
  void _handleWalletBalanceUpdate(String driverId, PostgresChangePayload payload) {
    try {
      final newRecord = payload.newRecord;
      final oldRecord = payload.oldRecord;
      
      final newBalance = (newRecord['available_balance'] as num?)?.toDouble();
      final oldBalance = (oldRecord['available_balance'] as num?)?.toDouble();
      
      if (newBalance == null || oldBalance == null) return;
      
      debugPrint('💰 [WITHDRAWAL-BALANCE-TRACKER] Balance change detected');
      debugPrint('💰 [WITHDRAWAL-BALANCE-TRACKER] Old: RM ${oldBalance.toStringAsFixed(2)}');
      debugPrint('💰 [WITHDRAWAL-BALANCE-TRACKER] New: RM ${newBalance.toStringAsFixed(2)}');
      
      final difference = newBalance - oldBalance;
      
      // Check if this balance change is related to a withdrawal
      final relatedWithdrawal = _findRelatedWithdrawal(difference.abs());
      
      if (relatedWithdrawal != null) {
        debugPrint('🔗 [WITHDRAWAL-BALANCE-TRACKER] Balance change linked to withdrawal: ${relatedWithdrawal.id}');
        
        // Send balance update notification
        _notificationService.sendBalanceUpdateNotification(
          driverId: driverId,
          previousBalance: oldBalance,
          newBalance: newBalance,
          request: relatedWithdrawal,
        );
      } else {
        debugPrint('🔍 [WITHDRAWAL-BALANCE-TRACKER] Balance change not linked to active withdrawals');
      }
      
      _lastKnownBalance = newBalance;
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error handling wallet balance update: $e');
    }
  }

  /// Handle withdrawal status updates and trigger notifications
  void _handleWithdrawalStatusUpdate(String driverId, PostgresChangePayload payload) {
    try {
      final eventType = payload.eventType;
      
      switch (eventType) {
        case PostgresChangeEvent.insert:
          _handleNewWithdrawal(driverId, payload);
          break;
        case PostgresChangeEvent.update:
          _handleWithdrawalUpdate(driverId, payload);
          break;
        case PostgresChangeEvent.delete:
          _handleWithdrawalDeletion(payload);
          break;
        default:
          debugPrint('🔍 [WITHDRAWAL-BALANCE-TRACKER] Unhandled event type: $eventType');
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error handling withdrawal status update: $e');
    }
  }

  /// Handle new withdrawal request
  void _handleNewWithdrawal(String driverId, PostgresChangePayload payload) {
    try {
      final newRequest = DriverWithdrawalRequest.fromJson(payload.newRecord);
      _activeWithdrawals[newRequest.id] = newRequest;
      
      debugPrint('➕ [WITHDRAWAL-BALANCE-TRACKER] New withdrawal added: ${newRequest.id}');
      
      // Send status notification
      _notificationService.sendWithdrawalStatusNotification(
        driverId: driverId,
        request: newRequest,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error handling new withdrawal: $e');
    }
  }

  /// Handle withdrawal status update
  void _handleWithdrawalUpdate(String driverId, PostgresChangePayload payload) {
    try {
      final updatedRequest = DriverWithdrawalRequest.fromJson(payload.newRecord);
      final oldRequest = _activeWithdrawals[updatedRequest.id];
      
      final previousStatus = oldRequest?.status.name;
      
      debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Withdrawal updated: ${updatedRequest.id}');
      debugPrint('🔄 [WITHDRAWAL-BALANCE-TRACKER] Status: $previousStatus → ${updatedRequest.status.name}');
      
      // Update active withdrawals
      if (updatedRequest.status == DriverWithdrawalStatus.pending ||
          updatedRequest.status == DriverWithdrawalStatus.processing) {
        _activeWithdrawals[updatedRequest.id] = updatedRequest;
      } else {
        _activeWithdrawals.remove(updatedRequest.id);
      }
      
      // Send status notification
      _notificationService.sendWithdrawalStatusNotification(
        driverId: driverId,
        request: updatedRequest,
        previousStatus: previousStatus,
      );
      
      // Send specific notifications based on status
      switch (updatedRequest.status) {
        case DriverWithdrawalStatus.completed:
          _handleWithdrawalCompletion(driverId, updatedRequest);
          break;
        case DriverWithdrawalStatus.failed:
          _handleWithdrawalFailure(driverId, updatedRequest);
          break;
        default:
          break;
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error handling withdrawal update: $e');
    }
  }

  /// Handle withdrawal deletion
  void _handleWithdrawalDeletion(PostgresChangePayload payload) {
    try {
      final deletedId = payload.oldRecord['id'] as String;
      _activeWithdrawals.remove(deletedId);
      
      debugPrint('➖ [WITHDRAWAL-BALANCE-TRACKER] Withdrawal removed: $deletedId');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error handling withdrawal deletion: $e');
    }
  }

  /// Handle withdrawal completion
  void _handleWithdrawalCompletion(String driverId, DriverWithdrawalRequest request) {
    try {
      debugPrint('✅ [WITHDRAWAL-BALANCE-TRACKER] Handling withdrawal completion: ${request.id}');
      
      // Send completion summary with current balance
      if (_lastKnownBalance != null) {
        _notificationService.sendWithdrawalCompletionSummary(
          driverId: driverId,
          request: request,
          finalBalance: _lastKnownBalance!,
        );
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error handling withdrawal completion: $e');
    }
  }

  /// Handle withdrawal failure
  void _handleWithdrawalFailure(String driverId, DriverWithdrawalRequest request) {
    try {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Handling withdrawal failure: ${request.id}');
      
      final failureReason = request.failureReason ?? 'Unknown error occurred';
      
      _notificationService.sendWithdrawalFailureNotification(
        driverId: driverId,
        request: request,
        failureReason: failureReason,
      );
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-BALANCE-TRACKER] Error handling withdrawal failure: $e');
    }
  }

  /// Find withdrawal request related to a balance change
  DriverWithdrawalRequest? _findRelatedWithdrawal(double changeAmount) {
    // Look for active withdrawals with matching amounts
    for (final withdrawal in _activeWithdrawals.values) {
      // Check if the change amount matches the withdrawal amount (considering processing fees)
      if ((withdrawal.amount - changeAmount).abs() < 0.01 ||
          (withdrawal.netAmount - changeAmount).abs() < 0.01) {
        return withdrawal;
      }
    }
    return null;
  }

  /// Get current tracking status
  Map<String, dynamic> getTrackingStatus() {
    return {
      'is_tracking': _walletChannel != null && _withdrawalChannel != null,
      'last_known_balance': _lastKnownBalance,
      'active_withdrawals_count': _activeWithdrawals.length,
      'active_withdrawal_ids': _activeWithdrawals.keys.toList(),
    };
  }
}
