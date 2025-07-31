import 'package:flutter/foundation.dart';
// Removed unused import

import '../../../../core/data/repositories/base_repository.dart';
import '../models/driver_wallet.dart';
import '../models/driver_wallet_settings.dart';
import '../models/driver_withdrawal_request.dart';
import '../repositories/driver_wallet_repository.dart';

/// Enhanced driver wallet service following CustomerWalletService patterns
/// Provides high-level wallet operations with enhanced error handling
class EnhancedDriverWalletService extends BaseRepository {
  final DriverWalletRepository _repository;

  EnhancedDriverWalletService(this._repository);

  /// Get driver wallet with enhanced error handling
  Future<DriverWallet?> getDriverWallet() async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Getting driver wallet');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Current user: ${currentUser.id} (${currentUser.email})');

      final wallet = await _repository.getDriverWallet();
      if (wallet != null) {
        debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Driver wallet found: ${wallet.formattedAvailableBalance}');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet ID: ${wallet.id}, Active: ${wallet.isActive}');
      } else {
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] No wallet found for driver');
      }

      return wallet;
    });
  }

  /// Create driver wallet if it doesn't exist
  Future<DriverWallet> createDriverWallet() async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Creating driver wallet');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if wallet already exists
      final existingWallet = await _repository.getDriverWallet();
      if (existingWallet != null) {
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet already exists');
        return existingWallet;
      }

      // Use database function to create wallet and settings
      final response = await supabase.rpc('get_or_create_driver_wallet', params: {
        'p_user_id': currentUser.id,
      });

      if (response == null) {
        throw Exception('Failed to create driver wallet');
      }

      // Fetch the created wallet
      final newWallet = await _repository.getDriverWallet();
      if (newWallet == null) {
        throw Exception('Wallet creation failed');
      }

      debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Driver wallet created: ${newWallet.id}');
      return newWallet;
    });
  }

  /// Get or create driver wallet using database function
  Future<DriverWallet> getOrCreateDriverWallet() async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] ========== SERVICE WALLET OPERATION START ==========');
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Operation: getOrCreateDriverWallet using RPC function');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] CRITICAL ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Auth user found: ${currentUser.id}');
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Auth user email: ${currentUser.email}');
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Auth user role: ${currentUser.userMetadata?['role']}');

      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Calling Supabase RPC: get_or_create_driver_wallet');
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] RPC parameters: p_user_id = ${currentUser.id}');

      try {
        // Use the database function to get or create wallet
        final response = await supabase
            .rpc('get_or_create_driver_wallet', params: {
              'p_user_id': currentUser.id,
            });

        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] RPC call completed');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] RPC response type: ${response.runtimeType}');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] RPC response: $response');

        if (response == null) {
          debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] CRITICAL ERROR: RPC response is null');
          throw Exception('Database function returned null response');
        }

        if (response is! List) {
          debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] CRITICAL ERROR: RPC response is not a List');
          debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] Response type: ${response.runtimeType}');
          throw Exception('Database function returned unexpected response type: ${response.runtimeType}');
        }

        if (response.isEmpty) {
          debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] CRITICAL ERROR: RPC response is empty list');
          throw Exception('Database function returned empty response');
        }

        // RPC function returns an array, get the first item
        final walletData = response[0];
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet data from RPC: $walletData');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet data type: ${walletData.runtimeType}');

        // Get driver ID for the wallet creation
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Getting driver ID for user: ${currentUser.id}');
        final driverResponse = await supabase
            .from('drivers')
            .select('id')
            .eq('user_id', currentUser.id)
            .single();

        final driverId = driverResponse['id'] as String;
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Driver ID found: $driverId');

        // Use fromStakeholderWallet since data comes from stakeholder_wallets table
        final wallet = DriverWallet.fromStakeholderWallet(walletData, driverId);

        debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] SUCCESS: Wallet object created');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet ID: ${wallet.id}');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet balance: ${wallet.formattedAvailableBalance}');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Wallet active: ${wallet.isActive}');
        debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] ========== SERVICE WALLET OPERATION SUCCESS ==========');

        return wallet;
      } catch (e, stackTrace) {
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] ========== SERVICE WALLET OPERATION FAILED ==========');
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] Exception type: ${e.runtimeType}');
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] Exception message: $e');
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] Stack trace: $stackTrace');
        debugPrint('❌ [ENHANCED-DRIVER-WALLET-SERVICE] ========== SERVICE ERROR END ==========');
        rethrow;
      }
    });
  }

  /// Process earnings deposit from completed delivery
  Future<void> processEarningsDeposit({
    required String orderId,
    required double grossEarnings,
    required double netEarnings,
    required Map<String, dynamic> earningsBreakdown,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Processing earnings deposit for order: $orderId');
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Net earnings: RM ${netEarnings.toStringAsFixed(2)}');

      // Ensure wallet exists
      final wallet = await getOrCreateDriverWallet();

      // Call Edge Function to process earnings deposit
      final response = await supabase.functions.invoke(
        'driver-wallet-operations',
        body: {
          'action': 'process_earnings_deposit',
          'wallet_id': wallet.id,
          'order_id': orderId,
          'amount': netEarnings,
          'earnings_breakdown': earningsBreakdown,
          'metadata': {
            'gross_earnings': grossEarnings,
            'net_earnings': netEarnings,
            'deposit_source': 'delivery_completion',
            'processed_at': DateTime.now().toIso8601String(),
          },
        },
      );

      if (response.data == null || response.data['success'] != true) {
        throw Exception('Failed to process earnings deposit: ${response.data?['error'] ?? 'Unknown error'}');
      }

      debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Earnings deposited successfully');
    });
  }

  /// Process withdrawal request
  Future<String> processWithdrawalRequest({
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> destinationDetails,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Processing withdrawal request: RM ${amount.toStringAsFixed(2)}');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get wallet and validate balance
      final wallet = await getDriverWallet();
      if (wallet == null) {
        throw Exception('Driver wallet not found');
      }

      // Validate withdrawal amount
      if (!wallet.hasSufficientBalance(amount)) {
        throw Exception('Insufficient balance for withdrawal');
      }

      // Create withdrawal request using repository
      final request = await _repository.createWithdrawalRequest(
        amount: amount,
        withdrawalMethod: withdrawalMethod,
        destinationDetails: destinationDetails,
      );

      debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Withdrawal request created: ${request.id}');
      return request.id;
    });
  }

  /// Stream driver wallet updates for real-time balance monitoring
  Stream<DriverWallet?> streamDriverWallet() {
    return executeStreamQuery(() {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Setting up wallet stream');
      return _repository.streamDriverWallet();
    });
  }

  /// Get driver wallet settings
  Future<DriverWalletSettings?> getDriverWalletSettings() async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Getting wallet settings');
      return await _repository.getDriverWalletSettings();
    });
  }

  /// Update driver wallet settings
  Future<DriverWalletSettings> updateDriverWalletSettings(
    DriverWalletSettings settings,
  ) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Updating wallet settings');
      return await _repository.updateDriverWalletSettings(settings);
    });
  }

  /// Get driver withdrawal requests
  Future<List<DriverWithdrawalRequest>> getWithdrawalRequests({
    int limit = 50,
    int offset = 0,
    DriverWithdrawalStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Getting withdrawal requests');
      return await _repository.getDriverWithdrawalRequests(
        limit: limit,
        offset: offset,
        status: status,
        startDate: startDate,
        endDate: endDate,
      );
    });
  }

  /// Get withdrawal request by ID
  Future<DriverWithdrawalRequest?> getWithdrawalRequestById(String requestId) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Getting withdrawal request: $requestId');
      return await _repository.getWithdrawalRequestById(requestId);
    });
  }

  /// Validate withdrawal request
  Future<Map<String, dynamic>> validateWithdrawalRequest({
    required double amount,
    required String withdrawalMethod,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [ENHANCED-DRIVER-WALLET-SERVICE] Validating withdrawal request');

      final wallet = await getDriverWallet();
      if (wallet == null) {
        throw Exception('Driver wallet not found');
      }

      final settings = await getDriverWalletSettings();
      final minimumAmount = settings?.minimumWithdrawalAmount ?? 10.00;
      final maximumDaily = settings?.maximumDailyWithdrawal ?? 1000.00;

      // Get today's withdrawal total
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final todayRequests = await getWithdrawalRequests(
        startDate: startOfDay,
        endDate: endOfDay,
        status: null, // Get all statuses except cancelled/failed
      );

      final todayTotal = todayRequests
          .where((r) => r.status != DriverWithdrawalStatus.cancelled && 
                       r.status != DriverWithdrawalStatus.failed)
          .fold<double>(0.0, (sum, request) => sum + request.amount);

      final validation = {
        'is_valid': wallet.hasSufficientBalance(amount) &&
                   amount >= minimumAmount &&
                   (todayTotal + amount) <= maximumDaily,
        'available_balance': wallet.availableBalance,
        'minimum_amount': minimumAmount,
        'maximum_daily': maximumDaily,
        'today_total': todayTotal,
        'remaining_daily_limit': maximumDaily - todayTotal,
        'errors': <String>[],
      };

      // Add specific error messages
      final errors = <String>[];
      if (!wallet.hasSufficientBalance(amount)) {
        errors.add('Insufficient wallet balance');
      }
      if (amount < minimumAmount) {
        errors.add('Amount below minimum withdrawal limit of RM ${minimumAmount.toStringAsFixed(2)}');
      }
      if ((todayTotal + amount) > maximumDaily) {
        errors.add('Amount exceeds daily withdrawal limit');
      }

      validation['errors'] = errors;

      debugPrint('✅ [ENHANCED-DRIVER-WALLET-SERVICE] Withdrawal validation completed');
      return validation;
    });
  }
}
