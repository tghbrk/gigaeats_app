import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../data/models/user_role.dart';
import '../../data/models/driver_wallet.dart';
// Removed unused import
import '../../data/repositories/driver_wallet_repository.dart';
import 'driver_wallet_notification_provider.dart';
import '../../data/services/enhanced_driver_wallet_service.dart';

/// Repository provider for driver wallet operations
final driverWalletRepositoryProvider = Provider<DriverWalletRepository>((ref) {
  return DriverWalletRepository();
});

/// Service provider for enhanced driver wallet operations
final enhancedDriverWalletServiceProvider = Provider<EnhancedDriverWalletService>((ref) {
  final repository = ref.watch(driverWalletRepositoryProvider);
  return EnhancedDriverWalletService(repository);
});

/// Driver wallet state class
class DriverWalletState {
  final DriverWallet? wallet;
  final bool isLoading;
  final String? errorMessage;
  final bool isRefreshing;
  final DateTime? lastUpdated;
  final bool hasRealtimeConnection;

  const DriverWalletState({
    this.wallet,
    this.isLoading = false,
    this.errorMessage,
    this.isRefreshing = false,
    this.lastUpdated,
    this.hasRealtimeConnection = false,
  });

  DriverWalletState copyWith({
    DriverWallet? wallet,
    bool? isLoading,
    String? errorMessage,
    bool? isRefreshing,
    DateTime? lastUpdated,
    bool? hasRealtimeConnection,
  }) {
    return DriverWalletState(
      wallet: wallet ?? this.wallet,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      hasRealtimeConnection: hasRealtimeConnection ?? this.hasRealtimeConnection,
    );
  }

  /// Get available balance safely
  double get availableBalance => wallet?.availableBalance ?? 0.0;

  /// Get formatted available balance
  String get formattedAvailableBalance => wallet?.formattedAvailableBalance ?? 'RM 0.00';

  /// Check if wallet is active and verified
  bool get isWalletActive => wallet?.isActive == true;
  bool get isWalletVerified => wallet?.isVerified == true;

  @override
  String toString() {
    return 'DriverWalletState(wallet: ${wallet?.id}, isLoading: $isLoading, error: $errorMessage, hasRealtime: $hasRealtimeConnection)';
  }
}

/// Driver wallet state notifier
class DriverWalletNotifier extends StateNotifier<DriverWalletState> {
  final EnhancedDriverWalletService _service;
  final Ref _ref;

  DriverWalletNotifier(this._service, this._ref) : super(const DriverWalletState()) {
    _initializeWallet();
  }

  /// Initialize wallet on provider creation
  Future<void> _initializeWallet() async {
    final authState = _ref.read(authStateProvider);
    if (authState.user?.role == UserRole.driver) {
      await loadWallet();
    }
  }

  /// Load driver wallet
  Future<void> loadWallet({bool refresh = false}) async {
    if (state.isLoading && !refresh) return;

    debugPrint('🔍 [DRIVER-WALLET-PROVIDER] ========== STARTING WALLET LOAD ==========');
    debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Refresh: $refresh');
    debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Current state: isLoading=${state.isLoading}, hasWallet=${state.wallet != null}, errorMessage=${state.errorMessage}');

    state = state.copyWith(
      isLoading: true,
      isRefreshing: refresh,
      errorMessage: null,
    );

    debugPrint('🔍 [DRIVER-WALLET-PROVIDER] State updated to loading');

    try {
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] About to call _service.getOrCreateDriverWallet()...');

      final wallet = await _service.getOrCreateDriverWallet();

      debugPrint('✅ [DRIVER-WALLET-PROVIDER] SUCCESS: Wallet received from service');
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Wallet balance: ${wallet.formattedAvailableBalance}');
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Wallet details: ID=${wallet.id}, Active=${wallet.isActive}, Verified=${wallet.isVerified}');
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Wallet currency: ${wallet.currency}');

      state = state.copyWith(
        wallet: wallet,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
        errorMessage: null,
      );

      debugPrint('✅ [DRIVER-WALLET-PROVIDER] State updated successfully with wallet data');
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Final state: isLoading=${state.isLoading}, hasWallet=${state.wallet != null}');
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] ========== WALLET LOAD COMPLETED ==========');
    } catch (e, stackTrace) {
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] ========== WALLET LOAD FAILED ==========');
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] Error type: ${e.runtimeType}');
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] Error message: $e');
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] Stack trace: $stackTrace');

      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      );

      debugPrint('❌ [DRIVER-WALLET-PROVIDER] Error state set: ${state.errorMessage}');
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] ========== ERROR HANDLING COMPLETED ==========');
    }
  }

  /// Process earnings deposit
  Future<void> processEarningsDeposit({
    required String orderId,
    required double grossEarnings,
    required double netEarnings,
    required Map<String, dynamic> earningsBreakdown,
  }) async {
    try {
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Processing earnings deposit for order: $orderId');

      await _service.processEarningsDeposit(
        orderId: orderId,
        grossEarnings: grossEarnings,
        netEarnings: netEarnings,
        earningsBreakdown: earningsBreakdown,
      );

      // Refresh wallet after deposit
      await loadWallet(refresh: true);

      // Send earnings notification
      try {
        final notificationNotifier = _ref.read(driverWalletNotificationProvider.notifier);
        await notificationNotifier.sendEarningsNotification(
          orderId: orderId,
          earningsAmount: netEarnings,
          newBalance: state.wallet?.availableBalance ?? 0.0,
          earningsBreakdown: earningsBreakdown,
        );
      } catch (notificationError) {
        debugPrint('⚠️ [DRIVER-WALLET-PROVIDER] Failed to send earnings notification: $notificationError');
        // Don't fail the entire operation for notification errors
      }

      debugPrint('✅ [DRIVER-WALLET-PROVIDER] Earnings deposited successfully');
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] Error processing earnings deposit: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Process withdrawal request
  Future<String?> processWithdrawalRequest({
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> destinationDetails,
  }) async {
    try {
      debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Processing withdrawal request: RM ${amount.toStringAsFixed(2)}');

      final requestId = await _service.processWithdrawalRequest(
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        destinationDetails: destinationDetails,
      );

      // Refresh wallet after withdrawal request
      await loadWallet(refresh: true);

      // Send withdrawal notification
      try {
        final notificationNotifier = _ref.read(driverWalletNotificationProvider.notifier);
        await notificationNotifier.sendWithdrawalNotification(
          withdrawalId: requestId,
          amount: amount,
          status: 'processing',
          withdrawalMethod: withdrawalMethod,
        );
      } catch (notificationError) {
        debugPrint('⚠️ [DRIVER-WALLET-PROVIDER] Failed to send withdrawal notification: $notificationError');
        // Don't fail the entire operation for notification errors
      }

      debugPrint('✅ [DRIVER-WALLET-PROVIDER] Withdrawal request created: $requestId');
      return requestId;
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] Error processing withdrawal: $e');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Handle real-time wallet updates
  void handleRealtimeUpdate(DriverWallet updatedWallet) {
    debugPrint('🔄 [DRIVER-WALLET-PROVIDER] Real-time wallet update: ${updatedWallet.formattedAvailableBalance}');
    
    state = state.copyWith(
      wallet: updatedWallet,
      hasRealtimeConnection: true,
      lastUpdated: DateTime.now(),
    );
  }

  /// Set real-time connection status
  void setRealtimeConnection(bool connected) {
    state = state.copyWith(hasRealtimeConnection: connected);
  }

  /// Add bank account for withdrawals
  Future<bool> addBankAccount({
    required String bankCode,
    required String accountNumber,
    required String accountHolderName,
    String? icNumber,
  }) async {
    try {
      debugPrint('🏦 [DRIVER-WALLET-PROVIDER] Adding bank account');

      final response = await _service.supabase.functions.invoke(
        'driver-wallet-operations',
        body: {
          'action': 'add_bank_account',
          'bank_details': {
            'bank_code': bankCode,
            'account_number': accountNumber,
            'account_holder_name': accountHolderName,
            if (icNumber != null) 'ic_number': icNumber,
          },
        },
      );

      if (response.data['success'] == true) {
        debugPrint('✅ [DRIVER-WALLET-PROVIDER] Bank account added successfully');

        // Refresh wallet data to get updated bank accounts
        await loadWallet(refresh: true);

        return true;
      } else {
        throw Exception(response.data['error'] ?? 'Failed to add bank account');
      }
    } catch (e) {
      debugPrint('❌ [DRIVER-WALLET-PROVIDER] Error adding bank account: $e');
      state = state.copyWith(errorMessage: e.toString());
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  @override
  void dispose() {
    debugPrint('🔍 [DRIVER-WALLET-PROVIDER] Disposing driver wallet notifier');
    super.dispose();
  }
}

/// Main driver wallet provider
final driverWalletProvider = StateNotifierProvider<DriverWalletNotifier, DriverWalletState>((ref) {
  final service = ref.watch(enhancedDriverWalletServiceProvider);
  return DriverWalletNotifier(service, ref);
});

/// Driver wallet stream provider for real-time updates
final driverWalletStreamProvider = StreamProvider<DriverWallet?>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState.user?.role != UserRole.driver) {
    return Stream.value(null);
  }

  final service = ref.watch(enhancedDriverWalletServiceProvider);
  return service.streamDriverWallet();
});

/// Driver wallet balance provider (for quick access)
final driverWalletBalanceProvider = Provider<double>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  return walletState.availableBalance;
});

/// Driver wallet loading state provider
final driverWalletLoadingProvider = Provider<bool>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  return walletState.isLoading;
});

/// Driver wallet error provider
final driverWalletErrorProvider = Provider<String?>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  return walletState.errorMessage;
});

/// Driver wallet real-time connection status provider
final driverWalletConnectionProvider = Provider<bool>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  return walletState.hasRealtimeConnection;
});

/// Driver wallet formatted balance provider
final driverWalletFormattedBalanceProvider = Provider<String>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  return walletState.formattedAvailableBalance;
});

/// Driver wallet verification status provider
final driverWalletVerificationProvider = Provider<bool>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  return walletState.isWalletVerified;
});

/// Driver wallet active status provider
final driverWalletActiveProvider = Provider<bool>((ref) {
  final walletState = ref.watch(driverWalletProvider);
  return walletState.isWalletActive;
});
