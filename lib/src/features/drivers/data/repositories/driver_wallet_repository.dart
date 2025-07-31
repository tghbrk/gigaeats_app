import 'package:flutter/foundation.dart';

import '../../../../core/data/repositories/base_repository.dart';
import '../models/driver_wallet.dart';
import '../models/driver_wallet_settings.dart';
import '../models/driver_withdrawal_request.dart';
import '../models/driver_wallet_transaction.dart';
import '../../security/driver_wallet_security_middleware.dart';

/// Repository for managing driver wallet data and operations
/// Follows the same patterns as CustomerWalletRepository
class DriverWalletRepository extends BaseRepository {
  final DriverWalletSecurityMiddleware _securityMiddleware;

  DriverWalletRepository({
    DriverWalletSecurityMiddleware? securityMiddleware,
  }) : _securityMiddleware = securityMiddleware ?? DriverWalletSecurityMiddleware();
  
  /// Get driver wallet for current user
  Future<DriverWallet?> getDriverWallet() async {
    return executeQuery(() async {
      debugPrint('🔍 [DRIVER-WALLET-REPO] === GETTING DRIVER WALLET ===');

      // Validate session first
      await _securityMiddleware.validateSession();

      // Get current user
      debugPrint('🔍 [DRIVER-WALLET-REPO] Getting current user from auth...');
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('🔍 [DRIVER-WALLET-REPO] ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [DRIVER-WALLET-REPO] Current user ID: ${currentUser.id}');

      // First get driver ID for the current user
      debugPrint('🔍 [DRIVER-WALLET-REPO] Getting driver profile...');
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (driverResponse == null) {
        debugPrint('❌ [DRIVER-WALLET-REPO] No driver profile found for user');
        return null;
      }

      final driverId = driverResponse['id'] as String;
      debugPrint('🔍 [DRIVER-WALLET-REPO] Driver ID: $driverId');

      // Execute secure wallet query
      return await _securityMiddleware.executeSecureOperation<DriverWallet?>(
        operation: 'view_balance',
        walletId: 'pending_lookup', // Will be updated after query
        operationFunction: () async {
          final queryStartTime = DateTime.now();
          debugPrint('🔍 [DRIVER-WALLET-REPO] Executing wallet query at ${queryStartTime.toIso8601String()}...');
          debugPrint('🔍 [DRIVER-WALLET-REPO] Query: SELECT specific_fields FROM stakeholder_wallets WHERE user_id = ${currentUser.id} AND user_role = driver');

          // Use the database function to get or create the wallet
          debugPrint('🔍 [DRIVER-WALLET-REPO] ========== REPOSITORY WALLET QUERY START ==========');
          debugPrint('🔍 [DRIVER-WALLET-REPO] Calling Supabase RPC: get_or_create_driver_wallet');
          debugPrint('🔍 [DRIVER-WALLET-REPO] RPC parameters: p_user_id = ${currentUser.id}');
          debugPrint('🔍 [DRIVER-WALLET-REPO] Driver ID: $driverId');

          final response = await supabase
              .rpc('get_or_create_driver_wallet', params: {
                'p_user_id': currentUser.id,
              });

          debugPrint('🔍 [DRIVER-WALLET-REPO] RPC call completed successfully');
          debugPrint('🔍 [DRIVER-WALLET-REPO] Response type: ${response.runtimeType}');
          debugPrint('🔍 [DRIVER-WALLET-REPO] Response content: $response');

          final queryEndTime = DateTime.now();
          final queryDuration = queryEndTime.difference(queryStartTime);
          debugPrint('🔍 [DRIVER-WALLET-REPO] Query completed in ${queryDuration.inMilliseconds}ms');

          if (response == null || response.isEmpty) {
            debugPrint('❌ [DRIVER-WALLET-REPO] No wallet found for driver');
            debugPrint('❌ [DRIVER-WALLET-REPO] ========== REPOSITORY WALLET QUERY FAILED ==========');
            return null;
          }

          // RPC function returns an array, get the first item
          final walletData = response[0];
          debugPrint('🔍 [DRIVER-WALLET-REPO] Wallet data extracted: $walletData');

          final driverWallet = DriverWallet.fromStakeholderWallet(walletData, driverId);
          debugPrint('✅ [DRIVER-WALLET-REPO] SUCCESS: Driver wallet object created');
          debugPrint('🔍 [DRIVER-WALLET-REPO] Wallet balance: ${driverWallet.formattedAvailableBalance}');
          debugPrint('🔍 [DRIVER-WALLET-REPO] Wallet details - ID: ${driverWallet.id}, Active: ${driverWallet.isActive}, Verified: ${driverWallet.isVerified}');
          debugPrint('🔍 [DRIVER-WALLET-REPO] ========== REPOSITORY WALLET QUERY SUCCESS ==========');

          return driverWallet;
        },
        context: {
          'user_id': currentUser.id,
          'driver_id': driverId,
          'operation_type': 'wallet_query',
        },
      );
    });
  }

  /// Stream driver wallet updates for real-time balance monitoring
  Stream<DriverWallet?> streamDriverWallet() {
    return executeStreamQuery(() async* {
      debugPrint('🔍 [DRIVER-WALLET-REPO] Setting up driver wallet stream');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [DRIVER-WALLET-REPO] User not authenticated for stream');
        return;
      }

      // Get driver ID first (this is a limitation - we need to cache this)
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (driverResponse == null) {
        debugPrint('❌ [DRIVER-WALLET-REPO] No driver profile found for stream');
        yield null;
        return;
      }

      final driverId = driverResponse['id'] as String;
      debugPrint('🔍 [DRIVER-WALLET-REPO] Driver ID for stream: $driverId');

      yield* supabase
          .from('stakeholder_wallets')
          .stream(primaryKey: ['id'])
          .map((data) {
            try {
              // Efficiently filter for current user and driver role
              for (final item in data) {
                if (item['user_id'] == currentUser.id && item['user_role'] == 'driver') {
                  final wallet = DriverWallet.fromStakeholderWallet(item, driverId);
                  debugPrint('🔄 [DRIVER-WALLET-REPO] Stream update: ${wallet.formattedAvailableBalance}');
                  return wallet;
                }
              }
              return null;
            } catch (e) {
              debugPrint('❌ [DRIVER-WALLET-REPO] Stream error: $e');
              return null;
            }
          });
    });
  }

  /// Get driver wallet settings
  Future<DriverWalletSettings?> getDriverWalletSettings() async {
    return executeQuery(() async {
      debugPrint('🔍 [DRIVER-WALLET-REPO] Getting driver wallet settings');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('driver_wallet_settings')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [DRIVER-WALLET-REPO] No wallet settings found');
        return null;
      }

      final settings = DriverWalletSettings.fromJson(response);
      debugPrint('✅ [DRIVER-WALLET-REPO] Wallet settings retrieved');
      return settings;
    });
  }

  /// Update driver wallet settings
  Future<DriverWalletSettings> updateDriverWalletSettings(
    DriverWalletSettings settings,
  ) async {
    return executeQuery(() async {
      debugPrint('🔍 [DRIVER-WALLET-REPO] Updating driver wallet settings');

      final updateData = settings.toJson();
      updateData['updated_at'] = DateTime.now().toIso8601String();

      final response = await supabase
          .from('driver_wallet_settings')
          .update(updateData)
          .eq('id', settings.id)
          .select()
          .single();

      final updatedSettings = DriverWalletSettings.fromJson(response);
      debugPrint('✅ [DRIVER-WALLET-REPO] Wallet settings updated');
      return updatedSettings;
    });
  }

  /// Get driver withdrawal requests with pagination
  Future<List<DriverWithdrawalRequest>> getDriverWithdrawalRequests({
    int limit = 50,
    int offset = 0,
    DriverWithdrawalStatus? status,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [DRIVER-WALLET-REPO] Getting driver withdrawal requests');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get driver ID
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();

      final driverId = driverResponse['id'] as String;

      var queryBuilder = supabase
          .from('driver_withdrawal_requests')
          .select('*')
          .eq('driver_id', driverId);

      // Apply filters
      if (status != null) {
        queryBuilder = queryBuilder.eq('status', status.name);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('requested_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('requested_at', endDate.toIso8601String());
      }

      // Apply ordering and pagination
      final response = await queryBuilder
          .order('requested_at', ascending: false)
          .range(offset, offset + limit - 1);

      final requests = response
          .map((json) => DriverWithdrawalRequest.fromJson(json))
          .toList();

      debugPrint('✅ [DRIVER-WALLET-REPO] Retrieved ${requests.length} withdrawal requests');
      return requests;
    });
  }

  /// Create a new withdrawal request
  Future<DriverWithdrawalRequest> createWithdrawalRequest({
    required double amount,
    required String withdrawalMethod,
    required Map<String, dynamic> destinationDetails,
    String? notes,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [DRIVER-WALLET-REPO] Creating withdrawal request');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get driver and wallet info
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();

      final driverId = driverResponse['id'] as String;

      final walletResponse = await supabase
          .from('stakeholder_wallets')
          .select('id')
          .eq('user_id', currentUser.id)
          .eq('user_role', 'driver')
          .single();

      final walletId = walletResponse['id'] as String;

      // Create withdrawal request
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
      };

      final response = await supabase
          .from('driver_withdrawal_requests')
          .insert(requestData)
          .select()
          .single();

      final request = DriverWithdrawalRequest.fromJson(response);
      debugPrint('✅ [DRIVER-WALLET-REPO] Withdrawal request created: ${request.id}');
      return request;
    });
  }

  /// Get withdrawal request by ID
  Future<DriverWithdrawalRequest?> getWithdrawalRequestById(String requestId) async {
    return executeQuery(() async {
      debugPrint('🔍 [DRIVER-WALLET-REPO] Getting withdrawal request: $requestId');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Get driver ID
      final driverResponse = await supabase
          .from('drivers')
          .select('id')
          .eq('user_id', currentUser.id)
          .single();

      final driverId = driverResponse['id'] as String;

      final response = await supabase
          .from('driver_withdrawal_requests')
          .select('*')
          .eq('id', requestId)
          .eq('driver_id', driverId) // Ensure user can only access their own requests
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [DRIVER-WALLET-REPO] Withdrawal request not found');
        return null;
      }

      final request = DriverWithdrawalRequest.fromJson(response);
      debugPrint('✅ [DRIVER-WALLET-REPO] Withdrawal request retrieved');
      return request;
    });
  }

  /// Get driver wallet transactions with pagination and filtering
  Future<List<DriverWalletTransaction>> getDriverWalletTransactions({
    int limit = 20,
    int offset = 0,
    DriverWalletTransactionType? type,
    DateTime? startDate,
    DateTime? endDate,
    String? searchQuery,
    double? minAmount,
    double? maxAmount,
    String sortBy = 'created_at',
    bool ascending = false,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [DRIVER-WALLET-REPO] ========== GETTING DRIVER WALLET TRANSACTIONS ==========');
      debugPrint('🔍 [DRIVER-WALLET-REPO] Transaction query parameters: limit=$limit, offset=$offset, type=$type');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [DRIVER-WALLET-REPO] ERROR: User not authenticated');
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [DRIVER-WALLET-REPO] Current user ID: ${currentUser.id}');
      debugPrint('🔍 [DRIVER-WALLET-REPO] Current user email: ${currentUser.email}');

      // Get driver ID
      debugPrint('🔍 [DRIVER-WALLET-REPO] Querying drivers table for user_id: ${currentUser.id}');
      late String driverId;
      try {
        final driverResponse = await supabase
            .from('drivers')
            .select('id, status, is_active')
            .eq('user_id', currentUser.id)
            .single();

        debugPrint('🔍 [DRIVER-WALLET-REPO] Driver query response: $driverResponse');
        driverId = driverResponse['id'] as String;
        debugPrint('✅ [DRIVER-WALLET-REPO] Driver ID found: $driverId, status: ${driverResponse['status']}, is_active: ${driverResponse['is_active']}');
      } catch (e) {
        debugPrint('❌ [DRIVER-WALLET-REPO] ERROR: Failed to get driver ID: $e');
        throw Exception('Failed to get driver profile: $e');
      }

      // Get wallet first
      debugPrint('🔍 [DRIVER-WALLET-REPO] Getting driver wallet...');
      final wallet = await getDriverWallet();
      if (wallet == null) {
        debugPrint('❌ [DRIVER-WALLET-REPO] No wallet found for driver');
        return <DriverWalletTransaction>[];
      }
      debugPrint('✅ [DRIVER-WALLET-REPO] Wallet found: ${wallet.id}, balance: ${wallet.formattedAvailableBalance}');

      // Build query with filters
      debugPrint('🔍 [DRIVER-WALLET-REPO] Building transaction query for wallet_id: ${wallet.id}');
      var queryBuilder = supabase
          .from('wallet_transactions')
          .select('''
            id,
            wallet_id,
            transaction_type,
            amount,
            currency,
            balance_before,
            balance_after,
            reference_type,
            reference_id,
            description,
            metadata,
            processed_by,
            processing_fee,
            created_at,
            processed_at
          ''')
          .eq('wallet_id', wallet.id);

      debugPrint('🔍 [DRIVER-WALLET-REPO] Base query built for wallet_id: ${wallet.id}');

      // Apply filters
      if (type != null) {
        queryBuilder = queryBuilder.eq('transaction_type', type.value);
      }

      if (startDate != null) {
        queryBuilder = queryBuilder.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        queryBuilder = queryBuilder.lte('created_at', endDate.toIso8601String());
      }

      if (minAmount != null) {
        queryBuilder = queryBuilder.gte('amount', minAmount);
      }

      if (maxAmount != null) {
        queryBuilder = queryBuilder.lte('amount', maxAmount);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryBuilder = queryBuilder.or('description.ilike.%$searchQuery%,reference_id.ilike.%$searchQuery%');
      }

      debugPrint('🔍 [DRIVER-WALLET-REPO] Executing final transaction query...');
      try {
        final response = await queryBuilder
            .order(sortBy, ascending: ascending)
            .range(offset, offset + limit - 1);

        debugPrint('🔍 [DRIVER-WALLET-REPO] Query response received: ${response.length} items');

        final transactions = (response as List)
            .map((item) => DriverWalletTransaction.fromJson({
                  ...item,
                  'driver_id': driverId,
                }))
            .toList();

        debugPrint('✅ [DRIVER-WALLET-REPO] Successfully retrieved ${transactions.length} transactions');
        debugPrint('🔍 [DRIVER-WALLET-REPO] ========== TRANSACTION QUERY COMPLETED ==========');
        return transactions;
      } catch (e) {
        debugPrint('❌ [DRIVER-WALLET-REPO] ERROR: Transaction query failed: $e');
        debugPrint('🔍 [DRIVER-WALLET-REPO] ========== TRANSACTION QUERY FAILED ==========');
        rethrow;
      }
    });
  }

  /// Stream driver wallet transactions for real-time updates
  Stream<List<DriverWalletTransaction>> streamDriverWalletTransactions({
    int limit = 10,
    DriverWalletTransactionType? type,
  }) {
    return executeStreamQuery(() async* {
      debugPrint('🔍 [DRIVER-WALLET-REPO] ========== SETTING UP TRANSACTIONS STREAM ==========');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        debugPrint('❌ [DRIVER-WALLET-REPO] ERROR: User not authenticated for stream');
        yield <DriverWalletTransaction>[];
        return;
      }

      debugPrint('🔍 [DRIVER-WALLET-REPO] Stream user ID: ${currentUser.id}');

      // Get driver ID and wallet ID
      late String driverId;
      late DriverWallet? wallet;
      try {
        final driverResponse = await supabase
            .from('drivers')
            .select('id, status, is_active')
            .eq('user_id', currentUser.id)
            .single();

        driverId = driverResponse['id'] as String;
        debugPrint('✅ [DRIVER-WALLET-REPO] Stream driver ID found: $driverId');

        wallet = await getDriverWallet();
        debugPrint('🔍 [DRIVER-WALLET-REPO] Stream wallet lookup result: ${wallet?.id}');
      } catch (e) {
        debugPrint('❌ [DRIVER-WALLET-REPO] ERROR: Stream driver/wallet lookup failed: $e');
        yield <DriverWalletTransaction>[];
        return;
      }

      if (wallet == null) {
        yield <DriverWalletTransaction>[];
        return;
      }

      yield* supabase
          .from('wallet_transactions')
          .stream(primaryKey: ['id'])
          .eq('wallet_id', wallet.id)
          .order('created_at', ascending: false)
          .limit(limit)
          .map((data) {
            return data
                .map((item) => DriverWalletTransaction.fromJson({
                      ...item,
                      'driver_id': driverId,
                    }))
                .toList();
          });
    });
  }
}
