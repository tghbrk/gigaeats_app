import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/loyalty_account.dart';
import '../models/loyalty_transaction.dart';
import '../models/reward_program.dart';
import '../models/reward_redemption.dart';
import '../models/referral_program.dart';
import '../models/promotional_credit.dart';

/// Comprehensive loyalty service for managing loyalty programs
class LoyaltyService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Get loyalty account for current user
  Future<LoyaltyAccount?> getLoyaltyAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Loading loyalty account for user: ${user.id}');

      final response = await _supabase.functions.invoke(
        'loyalty-account-manager',
        body: {
          'action': 'get',
          'user_id': user.id,
        },
      );

      if (response.data == null) {
        debugPrint('🔍 [LOYALTY-SERVICE] No loyalty account found');
        return null;
      }

      final data = response.data as Map<String, dynamic>;
      debugPrint('🔍 [LOYALTY-SERVICE] Raw response data: $data');

      if (data['error'] != null) {
        throw Exception('Failed to load loyalty account: ${data['error']}');
      }

      if (data['loyalty_account'] == null) {
        debugPrint('🔍 [LOYALTY-SERVICE] No loyalty account data');
        return null;
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Loyalty account data: ${data['loyalty_account']}');
      final loyaltyAccount = LoyaltyAccount.fromJson(data['loyalty_account']);
      debugPrint('✅ [LOYALTY-SERVICE] Loyalty account loaded: ${loyaltyAccount.formattedAvailablePoints}');
      return loyaltyAccount;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error loading loyalty account: $e');
      rethrow;
    }
  }

  /// Get loyalty transactions with pagination
  Future<List<LoyaltyTransaction>> getLoyaltyTransactions({
    int limit = 20,
    int offset = 0,
    LoyaltyTransactionType? type,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Loading loyalty transactions (limit: $limit, offset: $offset)');

      final response = await _supabase.functions.invoke(
        'loyalty-transactions',
        body: {
          'action': 'list',
          'user_id': user.id,
          'limit': limit,
          'offset': offset,
          if (type != null) 'transaction_type': type.name,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load loyalty transactions');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load loyalty transactions: ${data['error']}');
      }

      final transactionsData = data['transactions'] as List<dynamic>? ?? [];
      final transactions = transactionsData
          .map((json) => LoyaltyTransaction.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [LOYALTY-SERVICE] Loaded ${transactions.length} loyalty transactions');
      return transactions;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error loading loyalty transactions: $e');
      rethrow;
    }
  }

  /// Get available rewards
  Future<List<RewardProgram>> getAvailableRewards({
    RewardCategory? category,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      debugPrint('🔍 [LOYALTY-SERVICE] Loading available rewards');

      final response = await _supabase.functions.invoke(
        'loyalty-rewards',
        body: {
          'action': 'list_available',
          'limit': limit,
          'offset': offset,
          if (category != null) 'category': category.name,
        },
      );

      if (response.data == null) {
        debugPrint('⚠️ [LOYALTY-SERVICE] No response data for rewards, returning empty list');
        return [];
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        debugPrint('⚠️ [LOYALTY-SERVICE] Rewards service error: ${data['error']}, returning empty list');
        return [];
      }

      final rewardsData = data['rewards'] as List<dynamic>? ?? [];
      final rewards = rewardsData
          .map((json) => RewardProgram.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [LOYALTY-SERVICE] Loaded ${rewards.length} available rewards');
      return rewards;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error loading rewards: $e');
      debugPrint('🔄 [LOYALTY-SERVICE] Returning empty rewards list to allow other features to work');
      return [];
    }
  }

  /// Redeem a reward
  Future<RewardRedemption> redeemReward({
    required String rewardProgramId,
    required int pointsCost,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Redeeming reward: $rewardProgramId for $pointsCost points');

      final response = await _supabase.functions.invoke(
        'loyalty-redeem-reward',
        body: {
          'user_id': user.id,
          'reward_program_id': rewardProgramId,
          'points_cost': pointsCost,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to redeem reward');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to redeem reward: ${data['error']}');
      }

      final redemption = RewardRedemption.fromJson(data['redemption']);
      debugPrint('✅ [LOYALTY-SERVICE] Reward redeemed successfully: ${redemption.id}');
      return redemption;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error redeeming reward: $e');
      rethrow;
    }
  }

  /// Get user's reward redemptions
  Future<List<RewardRedemption>> getRewardRedemptions({
    RewardRedemptionStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Loading reward redemptions');

      final response = await _supabase.functions.invoke(
        'loyalty-redemptions',
        body: {
          'action': 'list',
          'user_id': user.id,
          'limit': limit,
          'offset': offset,
          if (status != null) 'status': status.name,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load redemptions');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load redemptions: ${data['error']}');
      }

      final redemptionsData = data['redemptions'] as List<dynamic>? ?? [];
      final redemptions = redemptionsData
          .map((json) => RewardRedemption.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [LOYALTY-SERVICE] Loaded ${redemptions.length} reward redemptions');
      return redemptions;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error loading redemptions: $e');
      rethrow;
    }
  }

  /// Get user's referral programs
  Future<List<ReferralProgram>> getReferralPrograms({
    ReferralStatus? status,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Loading referral programs');

      final response = await _supabase.functions.invoke(
        'loyalty-referrals',
        body: {
          'action': 'list',
          'user_id': user.id,
          'limit': limit,
          'offset': offset,
          if (status != null) 'status': status.name,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load referrals');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load referrals: ${data['error']}');
      }

      final referralsData = data['referrals'] as List<dynamic>? ?? [];
      final referrals = referralsData
          .map((json) => ReferralProgram.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [LOYALTY-SERVICE] Loaded ${referrals.length} referral programs');
      return referrals;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error loading referrals: $e');
      rethrow;
    }
  }

  /// Create a new referral
  Future<ReferralProgram> createReferral({
    required String refereeEmail,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Creating referral for: $refereeEmail');

      final response = await _supabase.functions.invoke(
        'loyalty-create-referral',
        body: {
          'referrer_user_id': user.id,
          'referee_email': refereeEmail,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to create referral');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to create referral: ${data['error']}');
      }

      final referral = ReferralProgram.fromJson(data['referral']);
      debugPrint('✅ [LOYALTY-SERVICE] Referral created successfully: ${referral.id}');
      return referral;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error creating referral: $e');
      rethrow;
    }
  }

  /// Get user's promotional credits
  Future<List<PromotionalCredit>> getPromotionalCredits({
    PromotionalCreditStatus? status,
    bool activeOnly = false,
    int limit = 20,
    int offset = 0,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-SERVICE] Loading promotional credits');

      final response = await _supabase.functions.invoke(
        'loyalty-promotional-credits',
        body: {
          'action': 'list',
          'user_id': user.id,
          'limit': limit,
          'offset': offset,
          'active_only': activeOnly,
          if (status != null) 'status': status.name,
        },
      );

      if (response.data == null) {
        throw Exception('Failed to load promotional credits');
      }

      final data = response.data as Map<String, dynamic>;

      if (data['error'] != null) {
        throw Exception('Failed to load promotional credits: ${data['error']}');
      }

      final creditsData = data['credits'] as List<dynamic>? ?? [];
      final credits = creditsData
          .map((json) => PromotionalCredit.fromJson(json as Map<String, dynamic>))
          .toList();

      debugPrint('✅ [LOYALTY-SERVICE] Loaded ${credits.length} promotional credits');
      return credits;
    } catch (e) {
      debugPrint('❌ [LOYALTY-SERVICE] Error loading promotional credits: $e');
      rethrow;
    }
  }

  /// Calculate points for an order amount
  int calculatePointsForOrder(double orderAmount, {double multiplier = 1.0}) {
    // Base rate: 1 point per RM spent
    final basePoints = orderAmount.floor();
    final totalPoints = (basePoints * multiplier).floor();
    
    debugPrint('🔍 [LOYALTY-SERVICE] Calculated $totalPoints points for RM $orderAmount (multiplier: $multiplier)');
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

  /// Get cashback rate for loyalty tier
  double getCashbackRate(LoyaltyTier tier) {
    switch (tier) {
      case LoyaltyTier.bronze:
        return 0.01; // 1%
      case LoyaltyTier.silver:
        return 0.015; // 1.5%
      case LoyaltyTier.gold:
        return 0.02; // 2%
      case LoyaltyTier.platinum:
        return 0.025; // 2.5%
      case LoyaltyTier.diamond:
        return 0.03; // 3%
    }
  }
}
