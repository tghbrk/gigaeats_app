import 'package:flutter/foundation.dart';

import '../models/loyalty_account.dart';
import '../models/loyalty_transaction.dart';
import '../models/loyalty_program.dart' show
  LoyaltyReward,
  LoyaltyRewardType;
import '../../../../core/data/repositories/base_repository.dart';

/// Repository for loyalty system operations with direct database access
/// Follows GigaEats repository patterns with proper error handling and real-time support
class LoyaltyRepository extends BaseRepository {
  LoyaltyRepository();

  // =====================================================
  // LOYALTY ACCOUNT OPERATIONS
  // =====================================================

  /// Get loyalty account for current user
  Future<LoyaltyAccount?> getLoyaltyAccount() async {
    return executeQuery(() async {
      debugPrint('🔍 [LOYALTY-REPO] Getting loyalty account for current user');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final response = await supabase
          .from('loyalty_accounts')
          .select('*')
          .eq('user_id', currentUser.id)
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [LOYALTY-REPO] No loyalty account found for user');
        return null;
      }

      final loyaltyAccount = LoyaltyAccount.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty account found: ${loyaltyAccount.availablePoints} points');
      return loyaltyAccount;
    });
  }

  /// Get loyalty account stream for real-time updates
  Stream<LoyaltyAccount?> getLoyaltyAccountStream() {
    return executeStreamQuery(() {
      debugPrint('🔍 [LOYALTY-REPO-STREAM] Setting up loyalty account stream');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return Stream.error(Exception('User not authenticated'));
      }

      return supabase
          .from('loyalty_accounts')
          .stream(primaryKey: ['id'])
          .map((data) {
            final filtered = data.where((item) =>
                item['user_id'] == currentUser.id).toList();

            if (filtered.isEmpty) return null;
            return LoyaltyAccount.fromJson(filtered.first);
          });
    });
  }

  /// Create loyalty account for user (typically called by trigger)
  Future<LoyaltyAccount> createLoyaltyAccount({
    required String userId,
    String? walletId,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [LOYALTY-REPO] Creating loyalty account for user: $userId');

      // Generate unique referral code
      final referralCode = await _generateUniqueReferralCode();

      final accountData = {
        'user_id': userId,
        'wallet_id': walletId,
        'available_points': 0,
        'pending_points': 0,
        'lifetime_earned_points': 0,
        'lifetime_redeemed_points': 0,
        'current_tier': 'bronze',
        'tier_progress': 0,
        'next_tier_requirement': 1000,
        'tier_multiplier': 1.00,
        'total_cashback_earned': 0.00,
        'pending_cashback': 0.00,
        'cashback_rate': 0.0200,
        'referral_code': referralCode,
        'successful_referrals': 0,
        'total_referral_bonus': 0.00,
        'status': 'active',
        'is_verified': false,
        'last_activity_at': DateTime.now().toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('loyalty_accounts')
          .insert(accountData)
          .select()
          .single();

      final loyaltyAccount = LoyaltyAccount.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty account created: ${loyaltyAccount.id}');
      return loyaltyAccount;
    });
  }

  /// Update loyalty account
  Future<LoyaltyAccount> updateLoyaltyAccount({
    required String accountId,
    int? availablePoints,
    int? pendingPoints,
    int? lifetimeEarnedPoints,
    int? lifetimeRedeemedPoints,
    LoyaltyTier? currentTier,
    int? tierProgress,
    int? nextTierRequirement,
    double? tierMultiplier,
    double? totalCashbackEarned,
    double? pendingCashback,
    int? successfulReferrals,
    double? totalReferralBonus,
    LoyaltyAccountStatus? status,
    bool? isVerified,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [LOYALTY-REPO] Updating loyalty account: $accountId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        'last_activity_at': DateTime.now().toIso8601String(),
      };

      if (availablePoints != null) updateData['available_points'] = availablePoints;
      if (pendingPoints != null) updateData['pending_points'] = pendingPoints;
      if (lifetimeEarnedPoints != null) updateData['lifetime_earned_points'] = lifetimeEarnedPoints;
      if (lifetimeRedeemedPoints != null) updateData['lifetime_redeemed_points'] = lifetimeRedeemedPoints;
      if (currentTier != null) updateData['current_tier'] = currentTier.name;
      if (tierProgress != null) updateData['tier_progress'] = tierProgress;
      if (nextTierRequirement != null) updateData['next_tier_requirement'] = nextTierRequirement;
      if (tierMultiplier != null) updateData['tier_multiplier'] = tierMultiplier;
      if (totalCashbackEarned != null) updateData['total_cashback_earned'] = totalCashbackEarned;
      if (pendingCashback != null) updateData['pending_cashback'] = pendingCashback;
      if (successfulReferrals != null) updateData['successful_referrals'] = successfulReferrals;
      if (totalReferralBonus != null) updateData['total_referral_bonus'] = totalReferralBonus;
      if (status != null) updateData['status'] = status.name;
      if (isVerified != null) updateData['is_verified'] = isVerified;

      final response = await supabase
          .from('loyalty_accounts')
          .update(updateData)
          .eq('id', accountId)
          .select()
          .single();

      final loyaltyAccount = LoyaltyAccount.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty account updated: ${loyaltyAccount.availablePoints} points');
      return loyaltyAccount;
    });
  }

  // =====================================================
  // LOYALTY TRANSACTIONS OPERATIONS
  // =====================================================

  /// Get loyalty transactions with pagination and filtering
  Future<List<LoyaltyTransaction>> getLoyaltyTransactions({
    String? loyaltyAccountId,
    LoyaltyTransactionType? type,
    String? referenceType,
    String? referenceId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [LOYALTY-REPO] Getting loyalty transactions (limit: $limit, offset: $offset)');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Build basic query first
      var query = supabase
          .from('loyalty_transactions')
          .select('''
            *,
            loyalty_accounts!inner(user_id)
          ''')
          .eq('loyalty_accounts.user_id', currentUser.id);

      // Apply filters
      if (loyaltyAccountId != null) {
        query = query.eq('loyalty_account_id', loyaltyAccountId);
      }

      if (type != null) {
        query = query.eq('transaction_type', type.name);
      }

      if (referenceType != null) {
        query = query.eq('reference_type', referenceType);
      }

      if (referenceId != null) {
        query = query.eq('reference_id', referenceId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final transactions = response
          .map((json) => LoyaltyTransaction.fromJson(json))
          .toList();

      debugPrint('✅ [LOYALTY-REPO] Found ${transactions.length} loyalty transactions');
      return transactions;
    });
  }

  /// Get loyalty transactions stream for real-time updates
  Stream<List<LoyaltyTransaction>> getLoyaltyTransactionsStream({
    String? loyaltyAccountId,
    LoyaltyTransactionType? type,
    int limit = 20,
  }) {
    return executeStreamQuery(() {
      debugPrint('🔍 [LOYALTY-REPO-STREAM] Setting up loyalty transactions stream');

      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        return Stream.error(Exception('User not authenticated'));
      }

      var queryBuilder = supabase
          .from('loyalty_transactions')
          .stream(primaryKey: ['id'])
          .order('created_at', ascending: false);

      return queryBuilder.map((data) {
        // Filter and convert to LoyaltyTransaction objects
        var filtered = data.where((item) {
          // We'll need to check if this transaction belongs to current user
          // This requires a join or separate query, for now we'll filter by account ID if provided
          if (loyaltyAccountId != null) {
            return item['loyalty_account_id'] == loyaltyAccountId;
          }
          return true;
        }).toList();

        if (type != null) {
          filtered = filtered.where((item) => 
              item['transaction_type'] == type.name).toList();
        }

        // Limit results
        if (filtered.length > limit) {
          filtered = filtered.take(limit).toList();
        }

        return filtered
            .map((json) => LoyaltyTransaction.fromJson(json))
            .toList();
      });
    });
  }

  /// Create loyalty transaction
  Future<LoyaltyTransaction> createLoyaltyTransaction({
    required String loyaltyAccountId,
    required LoyaltyTransactionType transactionType,
    required int pointsAmount,
    required int pointsBalanceBefore,
    required int pointsBalanceAfter,
    String? referenceType,
    String? referenceId,
    required String description,
    Map<String, dynamic>? metadata,
    DateTime? expiresAt,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [LOYALTY-REPO] Creating loyalty transaction: $transactionType, $pointsAmount points');

      final transactionData = {
        'loyalty_account_id': loyaltyAccountId,
        'transaction_type': transactionType.name,
        'points_amount': pointsAmount,
        'points_balance_before': pointsBalanceBefore,
        'points_balance_after': pointsBalanceAfter,
        'reference_type': referenceType,
        'reference_id': referenceId,
        'description': description,
        'metadata': metadata ?? {},
        'expires_at': expiresAt?.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await supabase
          .from('loyalty_transactions')
          .insert(transactionData)
          .select()
          .single();

      final transaction = LoyaltyTransaction.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty transaction created: ${transaction.id}');
      return transaction;
    });
  }

  // =====================================================
  // HELPER METHODS
  // =====================================================

  /// Generate unique referral code
  Future<String> _generateUniqueReferralCode() async {
    String code;
    bool exists;
    int attempts = 0;
    const maxAttempts = 10;

    do {
      // Generate 8-character code: GIGA + 4 random chars
      final randomPart = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
      code = 'GIGA$randomPart';

      // Check if code exists
      final response = await supabase
          .from('loyalty_accounts')
          .select('id')
          .eq('referral_code', code)
          .maybeSingle();

      exists = response != null;
      attempts++;

      if (attempts >= maxAttempts) {
        throw Exception('Failed to generate unique referral code after $maxAttempts attempts');
      }
    } while (exists);

    return code;
  }

  /// Calculate points for order amount with tier multiplier
  int calculatePointsForOrder(double orderAmount, {double tierMultiplier = 1.0}) {
    // Base rate: 1 point per RM spent
    final basePoints = orderAmount.floor();
    final totalPoints = (basePoints * tierMultiplier).floor();
    
    debugPrint('🔍 [LOYALTY-REPO] Calculated $totalPoints points for RM $orderAmount (multiplier: $tierMultiplier)');
    return totalPoints;
  }

  /// Get tier multiplier for loyalty tier
  double getTierMultiplier(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 1.0;
      case LoyaltyTier.silver:
        return 1.2;
      case LoyaltyTier.gold:
        return 1.5;
      case LoyaltyTier.platinum:
        return 2.0;
      case LoyaltyTier.diamond:
        return 3.0;
    }
  }

  // =====================================================
  // LOYALTY REWARDS OPERATIONS
  // =====================================================

  /// Get available loyalty rewards
  Future<List<LoyaltyReward>> getAvailableRewards({
    LoyaltyRewardType? rewardType,
    int? maxPointsRequired,
    int limit = 20,
    int offset = 0,
  }) async {
    return executeQuery(() async {
      debugPrint('🔍 [LOYALTY-REPO] Getting available rewards (limit: $limit, offset: $offset)');

      var query = supabase
          .from('loyalty_rewards')
          .select('*')
          .eq('is_active', true)
          .lte('valid_from', DateTime.now().toIso8601String());

      // Apply filters
      if (rewardType != null) {
        query = query.eq('reward_type', rewardType.name);
      }

      if (maxPointsRequired != null) {
        query = query.lte('points_required', maxPointsRequired);
      }

      // Filter by valid_until (null means no expiry)
      query = query.or('valid_until.is.null,valid_until.gt.${DateTime.now().toIso8601String()}');

      // Apply ordering and pagination
      final response = await query
          .order('sort_order', ascending: true)
          .order('points_required', ascending: true)
          .range(offset, offset + limit - 1);

      final rewards = response
          .map((json) => LoyaltyReward.fromJson(json))
          .toList();

      debugPrint('✅ [LOYALTY-REPO] Found ${rewards.length} available rewards');
      return rewards;
    });
  }

  /// Get loyalty reward by ID
  Future<LoyaltyReward?> getLoyaltyReward(String rewardId) async {
    return executeQuery(() async {
      debugPrint('🔍 [LOYALTY-REPO] Getting loyalty reward: $rewardId');

      final response = await supabase
          .from('loyalty_rewards')
          .select('*')
          .eq('id', rewardId)
          .maybeSingle();

      if (response == null) {
        debugPrint('🔍 [LOYALTY-REPO] Loyalty reward not found');
        return null;
      }

      final reward = LoyaltyReward.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty reward found: ${reward.name}');
      return reward;
    });
  }

  // =====================================================
  // LOYALTY REDEMPTIONS OPERATIONS (TEMPORARILY COMMENTED FOR TESTING)
  // =====================================================

  /*
  /// Get user's loyalty redemptions
  Future<Either<Failure, List<LoyaltyRedemption>>> getLoyaltyRedemptions({
    LoyaltyRedemptionStatus? status,
    String? rewardId,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 20,
    int offset = 0,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [LOYALTY-REPO] Getting loyalty redemptions (limit: $limit, offset: $offset)');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = client
          .from('loyalty_redemptions')
          .select('''
            *,
            loyalty_rewards(name, description, reward_type, reward_value)
          ''')
          .eq('customer_id', currentUser.id);

      // Apply filters
      if (status != null) {
        query = query.eq('status', status.name);
      }

      if (rewardId != null) {
        query = query.eq('reward_id', rewardId);
      }

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final redemptions = response
          .map((json) => LoyaltyRedemption.fromJson(json))
          .toList();

      debugPrint('✅ [LOYALTY-REPO] Found ${redemptions.length} loyalty redemptions');
      return redemptions;
    });
  }

  /// Create loyalty redemption
  Future<Either<Failure, LoyaltyRedemption>> createLoyaltyRedemption({
    required String rewardId,
    required String loyaltyAccountId,
    required int pointsUsed,
    double? discountAmount,
    String? orderId,
    DateTime? expiresAt,
    String? voucherCode,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [LOYALTY-REPO] Creating loyalty redemption for reward: $rewardId');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final redemptionData = {
        'customer_id': currentUser.id,
        'loyalty_account_id': loyaltyAccountId,
        'reward_id': rewardId,
        'order_id': orderId,
        'points_used': pointsUsed,
        'discount_amount': discountAmount,
        'status': 'active',
        'expires_at': expiresAt?.toIso8601String(),
        'voucher_code': voucherCode,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('loyalty_redemptions')
          .insert(redemptionData)
          .select('''
            *,
            loyalty_rewards(name, description, reward_type, reward_value)
          ''')
          .single();

      final redemption = LoyaltyRedemption.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty redemption created: ${redemption.id}');
      return redemption;
    });
  }

  /// Update loyalty redemption status
  Future<Either<Failure, LoyaltyRedemption>> updateLoyaltyRedemption({
    required String redemptionId,
    LoyaltyRedemptionStatus? status,
    DateTime? usedAt,
    String? orderId,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [LOYALTY-REPO] Updating loyalty redemption: $redemptionId');

      final updateData = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
      };

      if (status != null) updateData['status'] = status.name;
      if (usedAt != null) updateData['used_at'] = usedAt.toIso8601String();
      if (orderId != null) updateData['order_id'] = orderId;

      final response = await client
          .from('loyalty_redemptions')
          .update(updateData)
          .eq('id', redemptionId)
          .select('''
            *,
            loyalty_rewards(name, description, reward_type, reward_value)
          ''')
          .single();

      final redemption = LoyaltyRedemption.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty redemption updated: ${redemption.status}');
      return redemption;
    });
  }

  // =====================================================
  // LOYALTY REFERRALS OPERATIONS
  // =====================================================

  /// Get user's loyalty referrals
  Future<Either<Failure, List<LoyaltyReferral>>> getLoyaltyReferrals({
    LoyaltyReferralStatus? status,
    bool asReferrer = true,
    int limit = 20,
    int offset = 0,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [LOYALTY-REPO] Getting loyalty referrals (asReferrer: $asReferrer)');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      var query = client
          .from('loyalty_referrals')
          .select('*');

      // Filter by user role (referrer or referee)
      if (asReferrer) {
        query = query.eq('referrer_id', currentUser.id);
      } else {
        query = query.eq('referee_id', currentUser.id);
      }

      // Apply status filter
      if (status != null) {
        query = query.eq('status', status.name);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final referrals = response
          .map((json) => LoyaltyReferral.fromJson(json))
          .toList();

      debugPrint('✅ [LOYALTY-REPO] Found ${referrals.length} loyalty referrals');
      return referrals;
    });
  }

  /// Create loyalty referral
  Future<Either<Failure, LoyaltyReferral>> createLoyaltyReferral({
    required String referralCode,
    String? refereeId,
    int referrerPoints = 500,
    int refereePoints = 200,
    int minRefereeOrders = 1,
    double minRefereeSpend = 50.0,
    DateTime? expiresAt,
  }) async {
    return executeQuerySafe(() async {
      debugPrint('🔍 [LOYALTY-REPO] Creating loyalty referral');

      final currentUser = client.auth.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final referralData = {
        'referrer_id': currentUser.id,
        'referee_id': refereeId,
        'referral_code': referralCode,
        'status': 'pending',
        'referrer_points': referrerPoints,
        'referee_points': refereePoints,
        'min_referee_orders': minRefereeOrders,
        'min_referee_spend': minRefereeSpend,
        'referee_orders_count': 0,
        'referee_total_spend': 0.0,
        'expires_at': (expiresAt ?? DateTime.now().add(const Duration(days: 30))).toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      final response = await client
          .from('loyalty_referrals')
          .insert(referralData)
          .select()
          .single();

      final referral = LoyaltyReferral.fromJson(response);
      debugPrint('✅ [LOYALTY-REPO] Loyalty referral created: ${referral.id}');
      return referral;
    });
  }
  */
}
