import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/loyalty_provider.dart';
import '../widgets/loyalty_points_card.dart';
import '../widgets/cashback_overview_card.dart';
import '../widgets/rewards_catalog_card.dart';
import '../widgets/referral_program_card.dart';
import '../widgets/promotional_credits_card.dart';
import '../widgets/loyalty_transactions_list.dart';
import '../../data/models/referral_program.dart';

/// Comprehensive loyalty dashboard screen
class LoyaltyDashboardScreen extends ConsumerStatefulWidget {
  const LoyaltyDashboardScreen({super.key});

  @override
  ConsumerState<LoyaltyDashboardScreen> createState() => _LoyaltyDashboardScreenState();
}

class _LoyaltyDashboardScreenState extends ConsumerState<LoyaltyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    
    // Load loyalty data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(loyaltyProvider.notifier).loadLoyaltyData();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loyaltyState = ref.watch(loyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty & Rewards'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _refreshLoyaltyData(),
            icon: loyaltyState.isRefreshing
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        theme.colorScheme.onSurface,
                      ),
                    ),
                  )
                : const Icon(Icons.refresh),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Rewards'),
            Tab(text: 'Referrals'),
            Tab(text: 'History'),
          ],
        ),
      ),
      body: loyaltyState.isLoading && !loyaltyState.isRefreshing
          ? const Center(child: CircularProgressIndicator())
          : loyaltyState.hasError
              ? _buildErrorWidget(context)
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(context),
                    _buildRewardsTab(context),
                    _buildReferralsTab(context),
                    _buildHistoryTab(context),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);

    return RefreshIndicator(
      onRefresh: _refreshLoyaltyData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Loyalty Points Card
            LoyaltyPointsCard(loyaltyAccount: loyaltyState.loyaltyAccount),
            const SizedBox(height: 16),

            // Cashback Overview
            CashbackOverviewCard(loyaltyAccount: loyaltyState.loyaltyAccount),
            const SizedBox(height: 16),

            // Quick Actions Row
            Row(
              children: [
                Expanded(
                  child: RewardsCatalogCard(
                    featuredRewards: ref.watch(featuredRewardsProvider),
                    onViewAll: () => _tabController.animateTo(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ReferralProgramCard(
                    loyaltyAccount: loyaltyState.loyaltyAccount,
                    pendingReferralsCount: ref.watch(pendingReferralsCountProvider),
                    onViewReferrals: () => _tabController.animateTo(2),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Promotional Credits
            PromotionalCreditsCard(
              promotionalCredits: ref.watch(activePromotionalCreditsProvider),
            ),
            const SizedBox(height: 16),

            // Recent Transactions
            _buildRecentTransactionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsTab(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);

    return RefreshIndicator(
      onRefresh: _refreshLoyaltyData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points Balance Summary
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.stars,
                      color: AppTheme.primaryColor,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Available Points',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                        Text(
                          loyaltyState.formattedPoints,
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Rewards Grid
            _buildRewardsGrid(context, loyaltyState.availableRewards),
          ],
        ),
      ),
    );
  }

  Widget _buildReferralsTab(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);

    return RefreshIndicator(
      onRefresh: _refreshLoyaltyData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Referral Code Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Referral Code',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            loyaltyState.referralCode,
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                              letterSpacing: 2,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _copyReferralCode(loyaltyState.referralCode),
                            icon: const Icon(Icons.copy, size: 20),
                            color: AppTheme.primaryColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => _shareReferralCode(loyaltyState.referralCode),
                      icon: const Icon(Icons.share),
                      label: const Text('Share & Earn'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Referral Stats
            Row(
              children: [
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${loyaltyState.successfulReferrals}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.successColor,
                            ),
                          ),
                          Text(
                            'Successful Referrals',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Text(
                            '${ref.watch(pendingReferralsCountProvider)}',
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.warningColor,
                            ),
                          ),
                          Text(
                            'Pending Referrals',
                            style: Theme.of(context).textTheme.bodySmall,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Referrals List
            _buildReferralsList(context, loyaltyState.referrals),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    final loyaltyState = ref.watch(loyaltyProvider);

    return RefreshIndicator(
      onRefresh: _refreshLoyaltyData,
      child: LoyaltyTransactionsList(
        transactions: loyaltyState.transactions,
        onLoadMore: () => ref.read(loyaltyProvider.notifier).loadMoreTransactions(),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final loyaltyState = ref.watch(loyaltyProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Activity',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _tabController.animateTo(3),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LoyaltyTransactionsList(
          transactions: loyaltyState.transactions.take(5).toList(),
          showLoadMore: false,
        ),
      ],
    );
  }

  Widget _buildRewardsGrid(BuildContext context, List rewards) {
    if (rewards.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No rewards available at the moment'),
          ),
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: rewards.length,
      itemBuilder: (context, index) {
        final reward = rewards[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reward.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  reward.formattedPointsCost,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => _redeemReward(reward),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Redeem'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReferralsList(BuildContext context, List referrals) {
    if (referrals.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No referrals yet. Start sharing your code!'),
          ),
        ),
      );
    }

    return Column(
      children: referrals.map((referral) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getReferralStatusColor(referral.status),
              child: Icon(
                _getReferralStatusIcon(referral.status),
                color: Colors.white,
                size: 20,
              ),
            ),
            title: Text(referral.refereeDisplayName),
            subtitle: Text(referral.statusDisplayName),
            trailing: Text(
              referral.formattedReferrerBonus,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppTheme.successColor,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildErrorWidget(BuildContext context) {
    final theme = Theme.of(context);
    final loyaltyState = ref.watch(loyaltyProvider);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load loyalty data',
              style: theme.textTheme.titleLarge?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              loyaltyState.errorMessage ?? 'Unknown error occurred',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.read(loyaltyProvider.notifier).forceReload(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refreshLoyaltyData() async {
    await ref.read(loyaltyProvider.notifier).loadLoyaltyData(forceRefresh: true);
  }

  void _copyReferralCode(String code) {
    // TODO: Implement clipboard copy
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Referral code $code copied to clipboard')),
    );
  }

  void _shareReferralCode(String code) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon')),
    );
  }

  void _redeemReward(dynamic reward) {
    // TODO: Implement reward redemption dialog
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Redeeming ${reward.title}...')),
    );
  }

  Color _getReferralStatusColor(ReferralStatus status) {
    switch (status.toString()) {
      case 'ReferralStatus.completed':
      case 'ReferralStatus.rewarded':
        return AppTheme.successColor;
      case 'ReferralStatus.pending':
        return AppTheme.warningColor;
      default:
        return AppTheme.errorColor;
    }
  }

  IconData _getReferralStatusIcon(ReferralStatus status) {
    switch (status.toString()) {
      case 'ReferralStatus.completed':
      case 'ReferralStatus.rewarded':
        return Icons.check;
      case 'ReferralStatus.pending':
        return Icons.hourglass_empty;
      default:
        return Icons.close;
    }
  }
}
