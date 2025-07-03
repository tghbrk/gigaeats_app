import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/loyalty_program.dart';
import '../../../../core/utils/logger.dart';

/// Customer loyalty program service
class CustomerLoyaltyService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AppLogger _logger = AppLogger();

  /// Get customer loyalty program summary
  Future<LoyaltyProgramSummary> getLoyaltyProgramSummary() async {
    try {
      _logger.info('CustomerLoyaltyService: Getting loyalty program summary');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get customer profile with current points
      final profileResponse = await _supabase
          .from('customer_profiles')
          .select('loyalty_points')
          .eq('user_id', user.id)
          .single();

      final currentPoints = profileResponse['loyalty_points'] as int? ?? 0;

      // Get current tier and next tier
      final tierResponse = await _supabase.rpc('get_customer_loyalty_tier', 
          params: {'customer_user_id': user.id});

      LoyaltyTier? currentTier;
      if (tierResponse.isNotEmpty) {
        currentTier = LoyaltyTier(
          id: tierResponse[0]['tier_id'],
          name: tierResponse[0]['tier_name'],
          description: tierResponse[0]['tier_description'],
          benefits: tierResponse[0]['tier_benefits'] ?? {},
          icon: tierResponse[0]['tier_icon'] ?? 'star',
          colorCode: tierResponse[0]['tier_color'] ?? '#FFD700',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      // Get next tier
      final nextTierResponse = await _supabase
          .from('loyalty_tiers')
          .select('*')
          .gt('min_points', currentPoints)
          .eq('is_active', true)
          .order('min_points')
          .limit(1);

      LoyaltyTier? nextTier;
      int? pointsToNextTier;
      if (nextTierResponse.isNotEmpty) {
        nextTier = LoyaltyTier.fromJson(nextTierResponse.first);
        pointsToNextTier = nextTier.minPoints - currentPoints;
      }

      // Get recent transactions
      final transactionsResponse = await _supabase
          .from('loyalty_transactions')
          .select('*')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false)
          .limit(10);

      final recentTransactions = transactionsResponse
          .map<LoyaltyTransaction>((data) => LoyaltyTransaction.fromJson(data))
          .toList();

      // Calculate total points earned and redeemed
      final totalEarned = recentTransactions
          .where((t) => t.transactionType.isPositive)
          .fold<int>(0, (sum, t) => sum + t.points);

      final totalRedeemed = recentTransactions
          .where((t) => !t.transactionType.isPositive)
          .fold<int>(0, (sum, t) => sum + t.points.abs());

      // Get available rewards
      final rewardsResponse = await _supabase
          .from('loyalty_rewards')
          .select('*')
          .eq('is_active', true)
          .lte('points_required', currentPoints + 1000) // Show rewards within reach
          .order('points_required');

      final availableRewards = rewardsResponse
          .map<LoyaltyReward>((data) => LoyaltyReward.fromJson(data))
          .toList();

      // Get active redemptions
      final redemptionsResponse = await _supabase
          .from('loyalty_redemptions')
          .select('''
            *,
            loyalty_rewards(*)
          ''')
          .eq('customer_id', user.id)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final activeRedemptions = redemptionsResponse
          .map<LoyaltyRedemption>((data) => LoyaltyRedemption.fromJson(data))
          .toList();

      // Get active referral
      final referralResponse = await _supabase
          .from('loyalty_referrals')
          .select('*')
          .eq('referrer_id', user.id)
          .eq('status', 'pending')
          .order('created_at', ascending: false)
          .limit(1);

      LoyaltyReferral? activeReferral;
      if (referralResponse.isNotEmpty) {
        activeReferral = LoyaltyReferral.fromJson(referralResponse.first);
      }

      return LoyaltyProgramSummary(
        currentPoints: currentPoints,
        currentTier: currentTier ?? _getDefaultTier(),
        nextTier: nextTier,
        pointsToNextTier: pointsToNextTier,
        totalPointsEarned: totalEarned,
        totalPointsRedeemed: totalRedeemed,
        recentTransactions: recentTransactions,
        availableRewards: availableRewards,
        activeRedemptions: activeRedemptions,
        activeReferral: activeReferral,
      );
    } catch (e) {
      _logger.error('CustomerLoyaltyService: Error getting loyalty summary', e);
      rethrow;
    }
  }

  /// Get all available loyalty rewards
  Future<List<LoyaltyReward>> getAvailableRewards() async {
    try {
      _logger.info('CustomerLoyaltyService: Getting available rewards');

      final response = await _supabase
          .from('loyalty_rewards')
          .select('*')
          .eq('is_active', true)
          .order('points_required');

      return response.map<LoyaltyReward>((data) => LoyaltyReward.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerLoyaltyService: Error getting rewards', e);
      rethrow;
    }
  }

  /// Redeem a loyalty reward
  Future<LoyaltyRedemption> redeemReward(String rewardId) async {
    try {
      _logger.info('CustomerLoyaltyService: Redeeming reward $rewardId');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Get reward details
      final rewardResponse = await _supabase
          .from('loyalty_rewards')
          .select('*')
          .eq('id', rewardId)
          .single();

      final reward = LoyaltyReward.fromJson(rewardResponse);

      // Check if user has enough points
      final profileResponse = await _supabase
          .from('customer_profiles')
          .select('loyalty_points')
          .eq('user_id', user.id)
          .single();

      final currentPoints = profileResponse['loyalty_points'] as int? ?? 0;

      if (currentPoints < reward.pointsRequired) {
        throw Exception('Insufficient points for this reward');
      }

      // Check redemption limits
      if (reward.maxRedemptionsPerCustomer != null) {
        final userRedemptionsResponse = await _supabase
            .from('loyalty_redemptions')
            .select('id')
            .eq('customer_id', user.id)
            .eq('reward_id', rewardId);

        if (userRedemptionsResponse.length >= reward.maxRedemptionsPerCustomer!) {
          throw Exception('You have reached the maximum redemptions for this reward');
        }
      }

      if (reward.maxTotalRedemptions != null && 
          reward.currentRedemptions >= reward.maxTotalRedemptions!) {
        throw Exception('This reward is no longer available');
      }

      // Create redemption
      final redemptionData = {
        'customer_id': user.id,
        'reward_id': rewardId,
        'points_used': reward.pointsRequired,
        'status': 'active',
        'expires_at': reward.rewardType == LoyaltyRewardType.voucher 
            ? DateTime.now().add(const Duration(days: 30)).toIso8601String()
            : null,
        'voucher_code': reward.rewardType == LoyaltyRewardType.voucher 
            ? await _generateVoucherCode()
            : null,
      };

      final redemptionResponse = await _supabase
          .from('loyalty_redemptions')
          .insert(redemptionData)
          .select('''
            *,
            loyalty_rewards(*)
          ''')
          .single();

      // Deduct points from customer
      await _supabase.rpc('update_customer_loyalty_points', params: {
        'customer_user_id': user.id,
        'points_change': -reward.pointsRequired,
        'transaction_type': 'redeemed',
        'description': 'Redeemed: ${reward.name}',
        'reward_id': rewardId,
      });

      // Update reward redemption count
      await _supabase
          .from('loyalty_rewards')
          .update({'current_redemptions': reward.currentRedemptions + 1})
          .eq('id', rewardId);

      _logger.info('CustomerLoyaltyService: Reward redeemed successfully');
      return LoyaltyRedemption.fromJson(redemptionResponse);
    } catch (e) {
      _logger.error('CustomerLoyaltyService: Error redeeming reward', e);
      rethrow;
    }
  }

  /// Create a referral code
  Future<LoyaltyReferral> createReferralCode() async {
    try {
      _logger.info('CustomerLoyaltyService: Creating referral code');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Check if user already has an active referral
      final existingResponse = await _supabase
          .from('loyalty_referrals')
          .select('id')
          .eq('referrer_id', user.id)
          .eq('status', 'pending');

      if (existingResponse.isNotEmpty) {
        throw Exception('You already have an active referral code');
      }

      // Generate unique referral code
      final referralCode = await _generateReferralCode();

      final referralData = {
        'referrer_id': user.id,
        'referral_code': referralCode,
        'status': 'pending',
        'referrer_points': 100, // Points for referrer
        'referee_points': 50,   // Points for referee
        'min_referee_orders': 1,
        'min_referee_spend': 25.0,
        'expires_at': DateTime.now().add(const Duration(days: 30)).toIso8601String(),
      };

      final response = await _supabase
          .from('loyalty_referrals')
          .insert(referralData)
          .select()
          .single();

      _logger.info('CustomerLoyaltyService: Referral code created successfully');
      return LoyaltyReferral.fromJson(response);
    } catch (e) {
      _logger.error('CustomerLoyaltyService: Error creating referral code', e);
      rethrow;
    }
  }

  /// Get customer's referral history
  Future<List<LoyaltyReferral>> getReferralHistory() async {
    try {
      _logger.info('CustomerLoyaltyService: Getting referral history');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('loyalty_referrals')
          .select('*')
          .eq('referrer_id', user.id)
          .order('created_at', ascending: false);

      return response.map<LoyaltyReferral>((data) => LoyaltyReferral.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerLoyaltyService: Error getting referral history', e);
      rethrow;
    }
  }

  /// Get loyalty transaction history
  Future<List<LoyaltyTransaction>> getTransactionHistory({int limit = 50}) async {
    try {
      _logger.info('CustomerLoyaltyService: Getting transaction history');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final response = await _supabase
          .from('loyalty_transactions')
          .select('*')
          .eq('customer_id', user.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return response.map<LoyaltyTransaction>((data) => LoyaltyTransaction.fromJson(data)).toList();
    } catch (e) {
      _logger.error('CustomerLoyaltyService: Error getting transaction history', e);
      rethrow;
    }
  }

  /// Apply referral code (for new customers)
  Future<void> applyReferralCode(String referralCode) async {
    try {
      _logger.info('CustomerLoyaltyService: Applying referral code $referralCode');

      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Find the referral
      final referralResponse = await _supabase
          .from('loyalty_referrals')
          .select('*')
          .eq('referral_code', referralCode)
          .eq('status', 'pending')
          .gt('expires_at', DateTime.now().toIso8601String())
          .single();

      final referral = LoyaltyReferral.fromJson(referralResponse);

      // Check if user is not referring themselves
      if (referral.referrerId == user.id) {
        throw Exception('You cannot use your own referral code');
      }

      // Update referral with referee
      await _supabase
          .from('loyalty_referrals')
          .update({
            'referee_id': user.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', referral.id);

      // Award welcome points to referee
      await _supabase.rpc('update_customer_loyalty_points', params: {
        'customer_user_id': user.id,
        'points_change': referral.refereePoints,
        'transaction_type': 'referral',
        'description': 'Welcome bonus from referral code',
        'referral_id': referral.id,
      });

      _logger.info('CustomerLoyaltyService: Referral code applied successfully');
    } catch (e) {
      _logger.error('CustomerLoyaltyService: Error applying referral code', e);
      rethrow;
    }
  }

  /// Generate unique referral code
  Future<String> _generateReferralCode() async {
    final response = await _supabase.rpc('generate_referral_code');
    return response as String;
  }

  /// Generate unique voucher code
  Future<String> _generateVoucherCode() async {
    final response = await _supabase.rpc('generate_voucher_code');
    return response as String;
  }

  /// Get default tier for new customers
  LoyaltyTier _getDefaultTier() {
    return LoyaltyTier(
      id: 'default',
      name: 'Bronze',
      description: 'Welcome to GigaEats!',
      minPoints: 0,
      maxPoints: 999,
      benefits: {'earning_rate': 1.0},
      icon: 'bronze',
      colorCode: '#CD7F32',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
