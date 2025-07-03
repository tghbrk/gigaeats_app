import 'package:flutter/foundation.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../data/repositories/base_repository.dart';
import '../models/customer_wallet.dart';

/// Enhanced customer wallet service with comprehensive functionality
class EnhancedCustomerWalletService extends BaseRepository {
  EnhancedCustomerWalletService({super.client});

  /// Get customer wallet with enhanced error handling
  Future<Either<Failure, CustomerWallet?>> getCustomerWallet() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Getting customer wallet');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from('stakeholder_wallets')
          .select('*')
          .eq('user_id', currentUser.id)
          .eq('user_role', 'customer')
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [ENHANCED-WALLET-SERVICE] No wallet found for customer');
        return null;
      }

      final customerWallet = CustomerWallet.fromStakeholderWallet(response);
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Customer wallet found: ${customerWallet.formattedAvailableBalance}');
      return customerWallet;
    });
  }

  /// Create customer wallet if it doesn't exist
  Future<Either<Failure, CustomerWallet>> createCustomerWallet() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Creating customer wallet');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if wallet already exists
      final existingWalletResult = await getCustomerWallet();
      return existingWalletResult.fold(
        (failure) => throw Exception('Failed to check existing wallet: ${failure.message}'),
        (existingWallet) async {
          if (existingWallet != null) {
            debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Wallet already exists');
            return existingWallet;
          }

          // Create new wallet
          final response = await client
              .from('stakeholder_wallets')
              .insert({
                'user_id': currentUser.id,
                'user_role': 'customer',
                'currency': 'MYR',
                'is_active': true,
                'is_verified': true,
              })
              .select()
              .single();

          final newWallet = CustomerWallet.fromStakeholderWallet(response);
          debugPrint('✅ [ENHANCED-WALLET-SERVICE] Customer wallet created: ${newWallet.id}');
          return newWallet;
        },
      );
    });
  }

  /// Get or create customer wallet
  Future<Either<Failure, CustomerWallet>> getOrCreateCustomerWallet() async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Getting or creating customer wallet');

      final walletResult = await getCustomerWallet();
      return walletResult.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (wallet) async {
          if (wallet != null) {
            return wallet;
          }

          // Create wallet if it doesn't exist
          final createResult = await createCustomerWallet();
          return createResult.fold(
            (failure) => throw Exception('Failed to create wallet: ${failure.message}'),
            (newWallet) => newWallet,
          );
        },
      );
    });
  }

  /// Check if customer has sufficient balance
  Future<Either<Failure, bool>> hasSufficientBalance(double amount) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Checking sufficient balance for amount: $amount');

      final walletResult = await getCustomerWallet();
      return walletResult.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (wallet) {
          if (wallet == null) {
            return false;
          }

          final hasSufficient = wallet.hasSufficientBalance(amount);
          debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Sufficient balance check: $hasSufficient');
          return hasSufficient;
        },
      );
    });
  }

  /// Get split payment calculation
  Future<Either<Failure, SplitPaymentCalculation>> calculateSplitPayment(double requestedAmount) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Calculating split payment for amount: $requestedAmount');

      final walletResult = await getCustomerWallet();
      return walletResult.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (wallet) {
          if (wallet == null) {
            return SplitPaymentCalculation(
              requestedAmount: requestedAmount,
              walletAmount: 0.0,
              remainingAmount: requestedAmount,
              canPayFully: false,
              needsTopUp: true,
              suggestedTopUp: requestedAmount,
            );
          }

          final walletAmount = wallet.getPayableAmount(requestedAmount);
          final remainingAmount = wallet.getRemainingAmount(requestedAmount);
          final canPayFully = wallet.hasSufficientBalance(requestedAmount);
          final needsTopUp = wallet.needsTopUp(requestedAmount);
          final suggestedTopUp = wallet.getSuggestedTopUpAmount(requestedAmount);

          return SplitPaymentCalculation(
            requestedAmount: requestedAmount,
            walletAmount: walletAmount,
            remainingAmount: remainingAmount,
            canPayFully: canPayFully,
            needsTopUp: needsTopUp,
            suggestedTopUp: suggestedTopUp,
          );
        },
      );
    });
  }

  /// Get customer wallet stream for real-time updates
  Stream<Either<Failure, CustomerWallet?>> getCustomerWalletStream() {
    return executeStreamQuery(() {
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Setting up customer wallet stream');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        return Stream.error(Exception('User not authenticated'));
      }

      return client
          .from('stakeholder_wallets')
          .stream(primaryKey: ['id'])
          .map((data) {
            try {
              // Filter for current user and customer role
              final filtered = data.where((item) =>
                  item['user_id'] == currentUser.id &&
                  item['user_role'] == 'customer').toList();

              if (filtered.isEmpty) {
                return const Right(null);
              }

              final response = filtered.first;
              final wallet = CustomerWallet.fromStakeholderWallet(response);
              return Right(wallet);
            } catch (e) {
              debugPrint('❌ [ENHANCED-WALLET-SERVICE] Stream error: $e');
              return Left(UnexpectedFailure(message: e.toString()));
            }
          });
    });
  }

  /// Validate wallet for transaction
  Future<Either<Failure, WalletValidationResult>> validateWalletForTransaction({
    required double amount,
    required String transactionType,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [ENHANCED-WALLET-SERVICE] Validating wallet for transaction: $amount');

      final walletResult = await getCustomerWallet();
      return walletResult.fold(
        (failure) => throw Exception('Failed to get wallet: ${failure.message}'),
        (wallet) {
          if (wallet == null) {
            return WalletValidationResult(
              isValid: false,
              errorMessage: 'Customer wallet not found',
              errorCode: 'WALLET_NOT_FOUND',
            );
          }

          if (!wallet.isActive) {
            return WalletValidationResult(
              isValid: false,
              errorMessage: 'Wallet is inactive',
              errorCode: 'WALLET_INACTIVE',
            );
          }

          if (!wallet.isVerified) {
            return WalletValidationResult(
              isValid: false,
              errorMessage: 'Wallet verification is pending',
              errorCode: 'WALLET_UNVERIFIED',
            );
          }

          if (amount <= 0) {
            return WalletValidationResult(
              isValid: false,
              errorMessage: 'Invalid transaction amount',
              errorCode: 'INVALID_AMOUNT',
            );
          }

          if (!wallet.hasSufficientBalance(amount)) {
            return WalletValidationResult(
              isValid: false,
              errorMessage: 'Insufficient wallet balance',
              errorCode: 'INSUFFICIENT_BALANCE',
              availableBalance: wallet.availableBalance,
              requiredAmount: amount,
            );
          }

          return WalletValidationResult(
            isValid: true,
            wallet: wallet,
          );
        },
      );
    });
  }
}

/// Split payment calculation result
class SplitPaymentCalculation {
  final double requestedAmount;
  final double walletAmount;
  final double remainingAmount;
  final bool canPayFully;
  final bool needsTopUp;
  final double suggestedTopUp;

  const SplitPaymentCalculation({
    required this.requestedAmount,
    required this.walletAmount,
    required this.remainingAmount,
    required this.canPayFully,
    required this.needsTopUp,
    required this.suggestedTopUp,
  });

  String get formattedWalletAmount => 'RM ${walletAmount.toStringAsFixed(2)}';
  String get formattedRemainingAmount => 'RM ${remainingAmount.toStringAsFixed(2)}';
  String get formattedSuggestedTopUp => 'RM ${suggestedTopUp.toStringAsFixed(2)}';
}

/// Wallet validation result
class WalletValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;
  final CustomerWallet? wallet;
  final double? availableBalance;
  final double? requiredAmount;

  const WalletValidationResult({
    required this.isValid,
    this.errorMessage,
    this.errorCode,
    this.wallet,
    this.availableBalance,
    this.requiredAmount,
  });

  double get shortfall => (requiredAmount ?? 0.0) - (availableBalance ?? 0.0);
  String get formattedShortfall => 'RM ${shortfall.toStringAsFixed(2)}';
}
