import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/services/customer_loyalty_service.dart';
import '../../data/models/loyalty_program.dart';
import '../../../../core/utils/logger.dart';

/// Provider for CustomerLoyaltyService
final customerLoyaltyServiceProvider = Provider<CustomerLoyaltyService>((ref) {
  return CustomerLoyaltyService();
});

/// State for customer loyalty program
class CustomerLoyaltyState {
  final LoyaltyProgramSummary? summary;
  final List<LoyaltyReward> availableRewards;
  final List<LoyaltyTransaction> transactionHistory;
  final List<LoyaltyReferral> referralHistory;
  final bool isLoading;
  final String? error;

  const CustomerLoyaltyState({
    this.summary,
    this.availableRewards = const [],
    this.transactionHistory = const [],
    this.referralHistory = const [],
    this.isLoading = false,
    this.error,
  });

  CustomerLoyaltyState copyWith({
    LoyaltyProgramSummary? summary,
    List<LoyaltyReward>? availableRewards,
    List<LoyaltyTransaction>? transactionHistory,
    List<LoyaltyReferral>? referralHistory,
    bool? isLoading,
    String? error,
  }) {
    return CustomerLoyaltyState(
      summary: summary ?? this.summary,
      availableRewards: availableRewards ?? this.availableRewards,
      transactionHistory: transactionHistory ?? this.transactionHistory,
      referralHistory: referralHistory ?? this.referralHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Notifier for customer loyalty program
class CustomerLoyaltyNotifier extends StateNotifier<CustomerLoyaltyState> {
  final CustomerLoyaltyService _loyaltyService;
  final AppLogger _logger = AppLogger();

  CustomerLoyaltyNotifier(this._loyaltyService) : super(const CustomerLoyaltyState()) {
    _initialize();
  }

  /// Initialize loyalty program data
  Future<void> _initialize() async {
    try {
      state = state.copyWith(isLoading: true);
      
      // Load loyalty program summary
      final summary = await _loyaltyService.getLoyaltyProgramSummary();
      
      state = state.copyWith(
        summary: summary,
        availableRewards: summary.availableRewards,
        transactionHistory: summary.recentTransactions,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      _logger.error('CustomerLoyaltyNotifier: Error initializing', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh loyalty program data
  Future<void> refresh() async {
    await _initialize();
  }

  /// Load all available rewards
  Future<void> loadAvailableRewards() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final rewards = await _loyaltyService.getAvailableRewards();
      
      state = state.copyWith(
        availableRewards: rewards,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      _logger.error('CustomerLoyaltyNotifier: Error loading rewards', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Redeem a loyalty reward
  Future<LoyaltyRedemption?> redeemReward(String rewardId) async {
    try {
      state = state.copyWith(isLoading: true);
      
      final redemption = await _loyaltyService.redeemReward(rewardId);
      
      // Refresh summary to update points and redemptions
      await _initialize();
      
      return redemption;
    } catch (e) {
      _logger.error('CustomerLoyaltyNotifier: Error redeeming reward', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Create a referral code
  Future<LoyaltyReferral?> createReferralCode() async {
    try {
      state = state.copyWith(isLoading: true);
      
      final referral = await _loyaltyService.createReferralCode();
      
      // Refresh summary to update active referral
      await _initialize();
      
      return referral;
    } catch (e) {
      _logger.error('CustomerLoyaltyNotifier: Error creating referral code', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return null;
    }
  }

  /// Load referral history
  Future<void> loadReferralHistory() async {
    try {
      final referrals = await _loyaltyService.getReferralHistory();
      
      state = state.copyWith(
        referralHistory: referrals,
        error: null,
      );
    } catch (e) {
      _logger.error('CustomerLoyaltyNotifier: Error loading referral history', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Load transaction history
  Future<void> loadTransactionHistory({int limit = 50}) async {
    try {
      final transactions = await _loyaltyService.getTransactionHistory(limit: limit);
      
      state = state.copyWith(
        transactionHistory: transactions,
        error: null,
      );
    } catch (e) {
      _logger.error('CustomerLoyaltyNotifier: Error loading transaction history', e);
      state = state.copyWith(error: e.toString());
    }
  }

  /// Apply referral code
  Future<bool> applyReferralCode(String referralCode) async {
    try {
      state = state.copyWith(isLoading: true);
      
      await _loyaltyService.applyReferralCode(referralCode);
      
      // Refresh summary to update points
      await _initialize();
      
      return true;
    } catch (e) {
      _logger.error('CustomerLoyaltyNotifier: Error applying referral code', e);
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for customer loyalty program
final customerLoyaltyProvider = StateNotifierProvider<CustomerLoyaltyNotifier, CustomerLoyaltyState>((ref) {
  final loyaltyService = ref.watch(customerLoyaltyServiceProvider);
  return CustomerLoyaltyNotifier(loyaltyService);
});

/// Provider for loyalty program summary
final loyaltyProgramSummaryProvider = Provider<LoyaltyProgramSummary?>((ref) {
  final loyaltyState = ref.watch(customerLoyaltyProvider);
  return loyaltyState.summary;
});

/// Provider for current loyalty points
final currentLoyaltyPointsProvider = Provider<int>((ref) {
  final summary = ref.watch(loyaltyProgramSummaryProvider);
  return summary?.currentPoints ?? 0;
});

/// Provider for current loyalty tier
final currentLoyaltyTierProvider = Provider<LoyaltyTier?>((ref) {
  final summary = ref.watch(loyaltyProgramSummaryProvider);
  return summary?.currentTier;
});

/// Provider for next loyalty tier
final nextLoyaltyTierProvider = Provider<LoyaltyTier?>((ref) {
  final summary = ref.watch(loyaltyProgramSummaryProvider);
  return summary?.nextTier;
});

/// Provider for points to next tier
final pointsToNextTierProvider = Provider<int?>((ref) {
  final summary = ref.watch(loyaltyProgramSummaryProvider);
  return summary?.pointsToNextTier;
});

/// Provider for available rewards
final availableLoyaltyRewardsProvider = Provider<List<LoyaltyReward>>((ref) {
  final loyaltyState = ref.watch(customerLoyaltyProvider);
  return loyaltyState.availableRewards;
});

/// Provider for affordable rewards (user has enough points)
final affordableLoyaltyRewardsProvider = Provider<List<LoyaltyReward>>((ref) {
  final rewards = ref.watch(availableLoyaltyRewardsProvider);
  final currentPoints = ref.watch(currentLoyaltyPointsProvider);
  
  return rewards.where((reward) => reward.pointsRequired <= currentPoints).toList();
});

/// Provider for active redemptions
final activeLoyaltyRedemptionsProvider = Provider<List<LoyaltyRedemption>>((ref) {
  final summary = ref.watch(loyaltyProgramSummaryProvider);
  return summary?.activeRedemptions ?? [];
});

/// Provider for active referral
final activeLoyaltyReferralProvider = Provider<LoyaltyReferral?>((ref) {
  final summary = ref.watch(loyaltyProgramSummaryProvider);
  return summary?.activeReferral;
});

/// Provider for recent transactions
final recentLoyaltyTransactionsProvider = Provider<List<LoyaltyTransaction>>((ref) {
  final loyaltyState = ref.watch(customerLoyaltyProvider);
  return loyaltyState.transactionHistory;
});

/// Provider for referral history
final loyaltyReferralHistoryProvider = Provider<List<LoyaltyReferral>>((ref) {
  final loyaltyState = ref.watch(customerLoyaltyProvider);
  return loyaltyState.referralHistory;
});

/// Provider for tier progress percentage
final tierProgressPercentageProvider = Provider<double>((ref) {
  final summary = ref.watch(loyaltyProgramSummaryProvider);
  if (summary == null || summary.nextTier == null) return 1.0;
  
  final currentPoints = summary.currentPoints;
  final currentTierMin = summary.currentTier.minPoints;
  final nextTierMin = summary.nextTier!.minPoints;
  
  final progress = (currentPoints - currentTierMin) / (nextTierMin - currentTierMin);
  return progress.clamp(0.0, 1.0);
});

/// Provider for checking if user can afford a specific reward
final canAffordRewardProvider = Provider.family<bool, String>((ref, rewardId) {
  final rewards = ref.watch(availableLoyaltyRewardsProvider);
  final currentPoints = ref.watch(currentLoyaltyPointsProvider);
  
  final reward = rewards.firstWhere(
    (r) => r.id == rewardId,
    orElse: () => throw Exception('Reward not found'),
  );
  
  return currentPoints >= reward.pointsRequired;
});
