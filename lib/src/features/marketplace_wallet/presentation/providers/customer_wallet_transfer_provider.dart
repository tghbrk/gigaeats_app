import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/customer_wallet_transfer.dart';
import '../../data/services/customer_wallet_transfer_service.dart';
import 'customer_wallet_provider.dart';

/// Provider for customer wallet transfer service
final customerWalletTransferServiceProvider = Provider<CustomerWalletTransferService>((ref) {
  return CustomerWalletTransferService();
});

/// State class for wallet transfer operations
class CustomerWalletTransferState {
  final bool isLoading;
  final String? errorMessage;
  final CustomerWalletTransfer? lastTransfer;
  final List<CustomerWalletTransfer> recentTransfers;

  const CustomerWalletTransferState({
    this.isLoading = false,
    this.errorMessage,
    this.lastTransfer,
    this.recentTransfers = const [],
  });

  CustomerWalletTransferState copyWith({
    bool? isLoading,
    String? errorMessage,
    CustomerWalletTransfer? lastTransfer,
    List<CustomerWalletTransfer>? recentTransfers,
  }) {
    return CustomerWalletTransferState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      lastTransfer: lastTransfer ?? this.lastTransfer,
      recentTransfers: recentTransfers ?? this.recentTransfers,
    );
  }
}

/// Notifier for managing wallet transfer operations
class CustomerWalletTransferNotifier extends StateNotifier<CustomerWalletTransferState> {
  final CustomerWalletTransferService _transferService;
  final Ref _ref;

  CustomerWalletTransferNotifier(this._transferService, this._ref) 
      : super(const CustomerWalletTransferState());

  /// Process a wallet-to-wallet transfer
  Future<void> processTransfer({
    required String recipientIdentifier,
    required double amount,
    String? note,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);

    try {
      // Get current user
      final authState = _ref.read(authStateProvider);
      final user = authState.user;
      
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Validate transfer parameters
      if (amount <= 0) {
        throw Exception('Transfer amount must be greater than zero');
      }

      if (amount < 1.0) {
        throw Exception('Minimum transfer amount is RM 1.00');
      }

      if (recipientIdentifier.trim().isEmpty) {
        throw Exception('Recipient information is required');
      }

      // Process the transfer
      final transfer = await _transferService.processTransfer(
        senderUserId: user.id,
        recipientIdentifier: recipientIdentifier,
        amount: amount,
        note: note,
      );

      // Update state with successful transfer
      state = state.copyWith(
        isLoading: false,
        lastTransfer: transfer,
        recentTransfers: [transfer, ...state.recentTransfers.take(9)],
      );

      // Refresh wallet balance after successful transfer
      _ref.read(customerWalletProvider.notifier).refreshWallet();

    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }

  /// Load recent transfers for the current user
  Future<void> loadRecentTransfers() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final transfers = await _transferService.getRecentTransfers(user.id);
      
      state = state.copyWith(
        recentTransfers: transfers,
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: e.toString(),
      );
    }
  }

  /// Validate recipient before transfer
  Future<bool> validateRecipient(String recipientIdentifier) async {
    try {
      return await _transferService.validateRecipient(recipientIdentifier);
    } catch (e) {
      return false;
    }
  }

  /// Get transfer limits for the current user
  Future<Map<String, double>> getTransferLimits() async {
    try {
      final authState = _ref.read(authStateProvider);
      final user = authState.user;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      return await _transferService.getTransferLimits(user.id);
    } catch (e) {
      // Return default limits if service call fails
      return {
        'daily_limit': 1000.0,
        'weekly_limit': 5000.0,
        'monthly_limit': 20000.0,
        'per_transaction_limit': 500.0,
      };
    }
  }

  /// Clear error message
  void clearError() {
    state = state.copyWith(errorMessage: null);
  }

  /// Reset transfer state
  void reset() {
    state = const CustomerWalletTransferState();
  }
}

/// Provider for wallet transfer state management
final customerWalletTransferProvider = StateNotifierProvider<CustomerWalletTransferNotifier, CustomerWalletTransferState>((ref) {
  final transferService = ref.watch(customerWalletTransferServiceProvider);
  return CustomerWalletTransferNotifier(transferService, ref);
});

/// Provider for recent transfers
final recentTransfersProvider = FutureProvider<List<CustomerWalletTransfer>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return [];
  }

  final transferService = ref.watch(customerWalletTransferServiceProvider);
  return transferService.getRecentTransfers(user.id);
});

/// Provider for transfer limits
final transferLimitsProvider = FutureProvider<Map<String, double>>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.user;

  if (user == null) {
    return {};
  }

  final transferService = ref.watch(customerWalletTransferServiceProvider);
  return transferService.getTransferLimits(user.id);
});

/// Provider for validating recipient
final recipientValidationProvider = FutureProvider.family<bool, String>((ref, recipientIdentifier) async {
  if (recipientIdentifier.trim().isEmpty) {
    return false;
  }

  final transferService = ref.watch(customerWalletTransferServiceProvider);
  return transferService.validateRecipient(recipientIdentifier);
});
