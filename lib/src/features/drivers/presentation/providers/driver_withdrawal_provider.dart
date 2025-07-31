import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/models/driver_withdrawal_request.dart';
import '../../data/models/driver_bank_account.dart';
import '../../data/models/driver_withdrawal_limits.dart';
import '../../data/repositories/driver_withdrawal_repository.dart';
import '../../../../presentation/providers/repository_providers.dart' show supabaseClientProvider, loggerProvider;

/// State class for driver withdrawal management
@immutable
class DriverWithdrawalState {
  final List<DriverWithdrawalRequest>? withdrawalRequests;
  final List<DriverBankAccount>? bankAccounts;
  final DriverWithdrawalLimits? limits;
  final Map<String, dynamic>? currentUsage;
  final bool isLoading;
  final String? errorMessage;

  const DriverWithdrawalState({
    this.withdrawalRequests,
    this.bankAccounts,
    this.limits,
    this.currentUsage,
    this.isLoading = false,
    this.errorMessage,
  });

  DriverWithdrawalState copyWith({
    List<DriverWithdrawalRequest>? withdrawalRequests,
    List<DriverBankAccount>? bankAccounts,
    DriverWithdrawalLimits? limits,
    Map<String, dynamic>? currentUsage,
    bool? isLoading,
    String? errorMessage,
  }) {
    return DriverWithdrawalState(
      withdrawalRequests: withdrawalRequests ?? this.withdrawalRequests,
      bankAccounts: bankAccounts ?? this.bankAccounts,
      limits: limits ?? this.limits,
      currentUsage: currentUsage ?? this.currentUsage,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

/// Repository provider for driver withdrawal operations
final driverWithdrawalRepositoryProvider = Provider<DriverWithdrawalRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final logger = ref.watch(loggerProvider);
  return DriverWithdrawalRepository(
    supabase: supabase,
    logger: logger,
  );
});

/// Provider for driver withdrawal management
final driverWithdrawalProvider = StateNotifierProvider<DriverWithdrawalNotifier, DriverWithdrawalState>((ref) {
  return DriverWithdrawalNotifier();
});

/// Notifier for managing driver withdrawal operations
class DriverWithdrawalNotifier extends StateNotifier<DriverWithdrawalState> {
  DriverWithdrawalNotifier() : super(const DriverWithdrawalState());

  final _supabase = Supabase.instance.client;
  RealtimeChannel? _withdrawalChannel;

  /// Load withdrawal limits and current usage
  Future<void> loadWithdrawalLimits() async {
    try {
      debugPrint('🔍 [WITHDRAWAL-PROVIDER] Loading withdrawal limits');
      
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _supabase.functions.invoke(
        'withdrawal-request-management',
        body: {
          'action': 'get_limits',
        },
      );

      if (response.data['success'] == true) {
        final data = response.data['data'];
        
        state = state.copyWith(
          limits: DriverWithdrawalLimits.fromJson(data['limits']),
          currentUsage: Map<String, dynamic>.from(data['current_usage']),
          isLoading: false,
        );
        
        debugPrint('✅ [WITHDRAWAL-PROVIDER] Withdrawal limits loaded successfully');
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load withdrawal limits');
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error loading withdrawal limits: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load bank accounts
  Future<void> loadBankAccounts() async {
    try {
      debugPrint('🔍 [WITHDRAWAL-PROVIDER] Loading bank accounts');
      
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _supabase.functions.invoke(
        'driver-wallet-operations',
        body: {
          'action': 'get_bank_accounts',
        },
      );

      if (response.data['success'] == true) {
        final accountsData = response.data['data'] as List;
        final bankAccounts = accountsData
            .map((account) => DriverBankAccount.fromJson(account))
            .toList();
        
        state = state.copyWith(
          bankAccounts: bankAccounts,
          isLoading: false,
        );
        
        debugPrint('✅ [WITHDRAWAL-PROVIDER] Bank accounts loaded successfully');
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load bank accounts');
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error loading bank accounts: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Create withdrawal request
  Future<String> createWithdrawalRequest({
    required double amount,
    required String withdrawalMethod,
    String? bankAccountId,
    String? notes,
  }) async {
    try {
      debugPrint('🔍 [WITHDRAWAL-PROVIDER] Creating withdrawal request: RM ${amount.toStringAsFixed(2)}');
      
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _supabase.functions.invoke(
        'withdrawal-request-management',
        body: {
          'action': 'create_request',
          'amount': amount,
          'withdrawal_method': withdrawalMethod,
          'bank_account_id': bankAccountId,
          'notes': notes,
        },
      );

      if (response.data['success'] == true) {
        final requestId = response.data['data']['request_id'];
        
        // Refresh withdrawal requests and limits
        await Future.wait([
          loadWithdrawalRequests(),
          loadWithdrawalLimits(),
        ]);
        
        debugPrint('✅ [WITHDRAWAL-PROVIDER] Withdrawal request created successfully');
        return requestId;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to create withdrawal request');
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error creating withdrawal request: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Check fraud score for withdrawal amount
  Future<Map<String, dynamic>> checkFraudScore({
    required double amount,
    required String withdrawalMethod,
  }) async {
    try {
      debugPrint('🔍 [WITHDRAWAL-PROVIDER] Checking fraud score for amount: RM ${amount.toStringAsFixed(2)}');

      final response = await _supabase.functions.invoke(
        'withdrawal-request-management',
        body: {
          'action': 'check_fraud_score',
          'amount': amount,
          'withdrawal_method': withdrawalMethod,
        },
      );

      if (response.data['success'] == true) {
        final fraudScore = Map<String, dynamic>.from(response.data['data']);
        debugPrint('✅ [WITHDRAWAL-PROVIDER] Fraud score checked: ${fraudScore['risk_level']}');
        return fraudScore;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to check fraud score');
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error checking fraud score: $e');
      rethrow;
    }
  }

  /// Load withdrawal requests
  Future<void> loadWithdrawalRequests({
    Map<String, dynamic>? filters,
    Map<String, dynamic>? pagination,
  }) async {
    try {
      debugPrint('🔍 [WITHDRAWAL-PROVIDER] Loading withdrawal requests');
      
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _supabase.functions.invoke(
        'withdrawal-request-management',
        body: {
          'action': 'get_requests',
          'filters': filters ?? {},
          'pagination': pagination ?? {'page': 1, 'limit': 20},
        },
      );

      if (response.data['success'] == true) {
        final requestsData = response.data['data']['requests'] as List;
        final withdrawalRequests = requestsData
            .map((request) => DriverWithdrawalRequest.fromJson(request))
            .toList();
        
        state = state.copyWith(
          withdrawalRequests: withdrawalRequests,
          isLoading: false,
        );
        
        debugPrint('✅ [WITHDRAWAL-PROVIDER] Withdrawal requests loaded successfully');
      } else {
        throw Exception(response.data['error'] ?? 'Failed to load withdrawal requests');
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error loading withdrawal requests: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Cancel withdrawal request
  Future<void> cancelWithdrawalRequest(String requestId, {String? reason}) async {
    try {
      debugPrint('🔍 [WITHDRAWAL-PROVIDER] Cancelling withdrawal request: $requestId');
      
      state = state.copyWith(isLoading: true, errorMessage: null);

      final response = await _supabase.functions.invoke(
        'withdrawal-request-management',
        body: {
          'action': 'cancel_request',
          'request_id': requestId,
          'notes': reason,
        },
      );

      if (response.data['success'] == true) {
        // Refresh withdrawal requests and limits
        await Future.wait([
          loadWithdrawalRequests(),
          loadWithdrawalLimits(),
        ]);
        
        debugPrint('✅ [WITHDRAWAL-PROVIDER] Withdrawal request cancelled successfully');
      } else {
        throw Exception(response.data['error'] ?? 'Failed to cancel withdrawal request');
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error cancelling withdrawal request: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset state
  void reset() {
    state = const DriverWithdrawalState();
  }

  /// Setup real-time subscription for withdrawal status updates
  void setupRealtimeSubscription(String driverId) {
    try {
      debugPrint('🔄 [WITHDRAWAL-PROVIDER] Setting up real-time subscription for driver: $driverId');

      _withdrawalChannel = _supabase
          .channel('driver_withdrawals_$driverId')
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
              debugPrint('🔄 [WITHDRAWAL-PROVIDER] Real-time update received: ${payload.eventType}');
              _handleRealtimeUpdate(payload);
            },
          )
          .subscribe();

      debugPrint('✅ [WITHDRAWAL-PROVIDER] Real-time subscription established');
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error setting up real-time subscription: $e');
    }
  }

  /// Handle real-time updates for withdrawal requests
  void _handleRealtimeUpdate(PostgresChangePayload payload) {
    try {
      final currentRequests = List<DriverWithdrawalRequest>.from(state.withdrawalRequests ?? []);

      switch (payload.eventType) {
        case PostgresChangeEvent.insert:
          debugPrint('🔄 [WITHDRAWAL-PROVIDER] New withdrawal request created');
          final newRequest = DriverWithdrawalRequest.fromJson(payload.newRecord);
          currentRequests.insert(0, newRequest);

          // Trigger notification for new request
          _triggerWithdrawalNotification(newRequest, null);
          break;

        case PostgresChangeEvent.update:
          debugPrint('🔄 [WITHDRAWAL-PROVIDER] Withdrawal request updated');
          final updatedRequest = DriverWithdrawalRequest.fromJson(payload.newRecord);
          final index = currentRequests.indexWhere((r) => r.id == updatedRequest.id);

          DriverWithdrawalRequest? previousRequest;
          if (index != -1) {
            previousRequest = currentRequests[index];
            currentRequests[index] = updatedRequest;

            // Trigger notification for status change
            if (previousRequest.status != updatedRequest.status) {
              _triggerWithdrawalNotification(updatedRequest, previousRequest);
            }
          }
          break;

        case PostgresChangeEvent.delete:
          debugPrint('🔄 [WITHDRAWAL-PROVIDER] Withdrawal request deleted');
          final deletedId = payload.oldRecord['id'] as String;
          currentRequests.removeWhere((r) => r.id == deletedId);
          break;

        default:
          debugPrint('🔄 [WITHDRAWAL-PROVIDER] Unhandled event type: ${payload.eventType}');
          break;
      }

      state = state.copyWith(withdrawalRequests: currentRequests);
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error handling real-time update: $e');
    }
  }

  /// Trigger withdrawal notification for status changes
  void _triggerWithdrawalNotification(
    DriverWithdrawalRequest currentRequest,
    DriverWithdrawalRequest? previousRequest,
  ) {
    try {
      debugPrint('🔔 [WITHDRAWAL-PROVIDER] Triggering withdrawal notification');
      debugPrint('🔔 [WITHDRAWAL-PROVIDER] Current status: ${currentRequest.status.name}');
      debugPrint('🔔 [WITHDRAWAL-PROVIDER] Previous status: ${previousRequest?.status.name ?? 'none'}');

      // The real-time notification system will handle the actual notification sending
      // This is just for logging and potential future enhancements
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error triggering withdrawal notification: $e');
    }
  }

  /// Dispose real-time subscription
  void disposeRealtimeSubscription() {
    try {
      if (_withdrawalChannel != null) {
        debugPrint('🔄 [WITHDRAWAL-PROVIDER] Disposing real-time subscription');
        _withdrawalChannel!.unsubscribe();
        _withdrawalChannel = null;
      }
    } catch (e) {
      debugPrint('❌ [WITHDRAWAL-PROVIDER] Error disposing real-time subscription: $e');
    }
  }

  @override
  void dispose() {
    disposeRealtimeSubscription();
    super.dispose();
  }
}
