import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/loyalty_account.dart';
import '../../data/models/loyalty_transaction.dart';
import '../../data/models/reward_program.dart';
import '../../data/models/reward_redemption.dart';
import '../../data/models/referral_program.dart';
import '../../data/models/promotional_credit.dart';
import '../../data/services/loyalty_service.dart';

/// Loyalty state model
class LoyaltyState {
  final LoyaltyAccount? loyaltyAccount;
  final List<LoyaltyTransaction> transactions;
  final List<RewardProgram> availableRewards;
  final List<RewardRedemption> redemptions;
  final List<ReferralProgram> referrals;
  final List<PromotionalCredit> promotionalCredits;
  final bool isLoading;
  final bool isRefreshing;
  final String? errorMessage;
  final DateTime? lastUpdated;

  const LoyaltyState({
    this.loyaltyAccount,
    this.transactions = const [],
    this.availableRewards = const [],
    this.redemptions = const [],
    this.referrals = const [],
    this.promotionalCredits = const [],
    this.isLoading = false,
    this.isRefreshing = false,
    this.errorMessage,
    this.lastUpdated,
  });

  LoyaltyState copyWith({
    LoyaltyAccount? loyaltyAccount,
    List<LoyaltyTransaction>? transactions,
    List<RewardProgram>? availableRewards,
    List<RewardRedemption>? redemptions,
    List<ReferralProgram>? referrals,
    List<PromotionalCredit>? promotionalCredits,
    bool? isLoading,
    bool? isRefreshing,
    String? errorMessage,
    DateTime? lastUpdated,
  }) {
    return LoyaltyState(
      loyaltyAccount: loyaltyAccount ?? this.loyaltyAccount,
      transactions: transactions ?? this.transactions,
      availableRewards: availableRewards ?? this.availableRewards,
      redemptions: redemptions ?? this.redemptions,
      referrals: referrals ?? this.referrals,
      promotionalCredits: promotionalCredits ?? this.promotionalCredits,
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      errorMessage: errorMessage,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  LoyaltyState clearError() {
    return copyWith(errorMessage: null);
  }

  bool get hasLoyaltyAccount => loyaltyAccount != null;
  bool get hasError => errorMessage != null;
  int get availablePoints => loyaltyAccount?.availablePoints ?? 0;
  String get formattedPoints => loyaltyAccount?.formattedAvailablePoints ?? '0 pts';
  LoyaltyTier get currentTier => loyaltyAccount?.currentTier ?? LoyaltyTier.bronze;
  String get tierDisplayName => loyaltyAccount?.tierDisplayName ?? 'Bronze';
  double get tierProgress => loyaltyAccount?.tierProgressPercentage ?? 0.0;
  String get formattedCashback => loyaltyAccount?.formattedTotalCashback ?? 'RM 0.00';
  String get referralCode => loyaltyAccount?.referralCode ?? '';
  int get successfulReferrals => loyaltyAccount?.successfulReferrals ?? 0;
}

/// Loyalty state notifier
class LoyaltyNotifier extends StateNotifier<LoyaltyState> {
  final LoyaltyService _loyaltyService;
  final Ref _ref;

  LoyaltyNotifier(this._loyaltyService, this._ref) : super(const LoyaltyState());

  /// Load all loyalty data
  Future<void> loadLoyaltyData({bool forceRefresh = false}) async {
    if (state.isLoading && !forceRefresh) return;

    state = state.copyWith(
      isLoading: true,
      isRefreshing: forceRefresh,
      errorMessage: null,
    );

    try {
      final authState = _ref.read(authStateProvider);
      if (authState.user == null) {
        throw Exception('User not authenticated');
      }

      debugPrint('🔍 [LOYALTY-PROVIDER] Loading loyalty data');

      // Load loyalty account (critical - must succeed)
      final loyaltyAccount = await _loyaltyService.getLoyaltyAccount();

      // Load recent transactions (critical - must succeed)
      final transactions = await _loyaltyService.getLoyaltyTransactions(limit: 10);

      // Load available rewards (non-critical - can fail gracefully)
      List<RewardProgram> rewards = [];
      try {
        rewards = await _loyaltyService.getAvailableRewards(limit: 20);
        debugPrint('✅ [LOYALTY-PROVIDER] Loaded ${rewards.length} rewards');
      } catch (e) {
        debugPrint('⚠️ [LOYALTY-PROVIDER] Failed to load rewards: $e');
        debugPrint('🔄 [LOYALTY-PROVIDER] Continuing with empty rewards list');
      }

      // Load redemptions (non-critical - can fail gracefully)
      List<RewardRedemption> redemptions = [];
      try {
        redemptions = await _loyaltyService.getRewardRedemptions(limit: 10);
        debugPrint('✅ [LOYALTY-PROVIDER] Loaded ${redemptions.length} redemptions');
      } catch (e) {
        debugPrint('⚠️ [LOYALTY-PROVIDER] Failed to load redemptions: $e');
        debugPrint('🔄 [LOYALTY-PROVIDER] Continuing with empty redemptions list');
      }

      // Load referrals (non-critical - can fail gracefully)
      List<ReferralProgram> referrals = [];
      try {
        referrals = await _loyaltyService.getReferralPrograms(limit: 10);
        debugPrint('✅ [LOYALTY-PROVIDER] Loaded ${referrals.length} referrals');
      } catch (e) {
        debugPrint('⚠️ [LOYALTY-PROVIDER] Failed to load referrals: $e');
        debugPrint('🔄 [LOYALTY-PROVIDER] Continuing with empty referrals list');
      }

      // Load promotional credits (non-critical - can fail gracefully)
      List<PromotionalCredit> credits = [];
      try {
        credits = await _loyaltyService.getPromotionalCredits(
          activeOnly: true,
          limit: 10,
        );
        debugPrint('✅ [LOYALTY-PROVIDER] Loaded ${credits.length} promotional credits');
      } catch (e) {
        debugPrint('⚠️ [LOYALTY-PROVIDER] Failed to load promotional credits: $e');
        debugPrint('🔄 [LOYALTY-PROVIDER] Continuing with empty credits list');
      }

      state = state.copyWith(
        loyaltyAccount: loyaltyAccount,
        transactions: transactions,
        availableRewards: rewards,
        redemptions: redemptions,
        referrals: referrals,
        promotionalCredits: credits,
        isLoading: false,
        isRefreshing: false,
        lastUpdated: DateTime.now(),
      );

      debugPrint('✅ [LOYALTY-PROVIDER] Loyalty data loaded successfully');
    } catch (e) {
      debugPrint('❌ [LOYALTY-PROVIDER] Error loading critical loyalty data: $e');
      state = state.copyWith(
        isLoading: false,
        isRefreshing: false,
        errorMessage: e.toString(),
      );
    }
  }

  /// Load more transactions
  Future<void> loadMoreTransactions() async {
    try {
      final moreTransactions = await _loyaltyService.getLoyaltyTransactions(
        limit: 20,
        offset: state.transactions.length,
      );

      state = state.copyWith(
        transactions: [...state.transactions, ...moreTransactions],
      );

      debugPrint('✅ [LOYALTY-PROVIDER] Loaded ${moreTransactions.length} more transactions');
    } catch (e) {
      debugPrint('❌ [LOYALTY-PROVIDER] Error loading more transactions: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Load more rewards
  Future<void> loadMoreRewards({RewardCategory? category}) async {
    try {
      final moreRewards = await _loyaltyService.getAvailableRewards(
        category: category,
        limit: 20,
        offset: state.availableRewards.length,
      );

      state = state.copyWith(
        availableRewards: [...state.availableRewards, ...moreRewards],
      );

      debugPrint('✅ [LOYALTY-PROVIDER] Loaded ${moreRewards.length} more rewards');
    } catch (e) {
      debugPrint('❌ [LOYALTY-PROVIDER] Error loading more rewards: $e');
      state = state.copyWith(errorMessage: e.toString());
    }
  }

  /// Redeem a reward
  Future<RewardRedemption?> redeemReward({
    required String rewardProgramId,
    required int pointsCost,
  }) async {
    try {
      debugPrint('🔍 [LOYALTY-PROVIDER] Redeeming reward: $rewardProgramId');

      // Check if user has enough points
      if (state.availablePoints < pointsCost) {
        throw Exception('Insufficient points. You need $pointsCost points but only have ${state.availablePoints}.');
      }

      final redemption = await _loyaltyService.redeemReward(
        rewardProgramId: rewardProgramId,
        pointsCost: pointsCost,
      );

      // Refresh loyalty data to update points balance
      await loadLoyaltyData(forceRefresh: true);

      debugPrint('✅ [LOYALTY-PROVIDER] Reward redeemed successfully');
      return redemption;
    } catch (e) {
      debugPrint('❌ [LOYALTY-PROVIDER] Error redeeming reward: $e');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Create a referral
  Future<ReferralProgram?> createReferral({
    required String refereeEmail,
  }) async {
    try {
      debugPrint('🔍 [LOYALTY-PROVIDER] Creating referral for: $refereeEmail');

      final referral = await _loyaltyService.createReferral(
        refereeEmail: refereeEmail,
      );

      // Add to current referrals list
      state = state.copyWith(
        referrals: [referral, ...state.referrals],
      );

      debugPrint('✅ [LOYALTY-PROVIDER] Referral created successfully');
      return referral;
    } catch (e) {
      debugPrint('❌ [LOYALTY-PROVIDER] Error creating referral: $e');
      state = state.copyWith(errorMessage: e.toString());
      return null;
    }
  }

  /// Filter rewards by category
  List<RewardProgram> getRewardsByCategory(RewardCategory category) {
    return state.availableRewards
        .where((reward) => reward.category == category)
        .toList();
  }

  /// Get featured rewards
  List<RewardProgram> getFeaturedRewards() {
    return state.availableRewards
        .where((reward) => reward.isFeatured)
        .take(5)
        .toList();
  }

  /// Get active promotional credits
  List<PromotionalCredit> getActivePromotionalCredits() {
    return state.promotionalCredits
        .where((credit) => credit.isUsable)
        .toList();
  }

  /// Get pending referrals
  List<ReferralProgram> getPendingReferrals() {
    return state.referrals
        .where((referral) => referral.status == ReferralStatus.pending)
        .toList();
  }

  /// Get completed referrals
  List<ReferralProgram> getCompletedReferrals() {
    return state.referrals
        .where((referral) => referral.isCompleted)
        .toList();
  }

  /// Clear error message
  void clearError() {
    state = state.clearError();
  }

  /// Force reload all data
  Future<void> forceReload() async {
    await loadLoyaltyData(forceRefresh: true);
  }
}

/// Loyalty service provider
final loyaltyServiceProvider = Provider<LoyaltyService>((ref) {
  return LoyaltyService();
});

/// Loyalty state provider
final loyaltyProvider = StateNotifierProvider<LoyaltyNotifier, LoyaltyState>((ref) {
  final loyaltyService = ref.watch(loyaltyServiceProvider);
  return LoyaltyNotifier(loyaltyService, ref);
});

/// Featured rewards provider
final featuredRewardsProvider = Provider<List<RewardProgram>>((ref) {
  final loyaltyState = ref.watch(loyaltyProvider);
  return loyaltyState.availableRewards
      .where((reward) => reward.isFeatured && reward.isCurrentlyAvailable)
      .take(3)
      .toList();
});

/// Active promotional credits provider
final activePromotionalCreditsProvider = Provider<List<PromotionalCredit>>((ref) {
  final loyaltyState = ref.watch(loyaltyProvider);
  return loyaltyState.promotionalCredits
      .where((credit) => credit.isUsable)
      .toList();
});

/// Pending referrals count provider
final pendingReferralsCountProvider = Provider<int>((ref) {
  final loyaltyState = ref.watch(loyaltyProvider);
  return loyaltyState.referrals
      .where((referral) => referral.status == ReferralStatus.pending)
      .length;
});
