import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/customer_loyalty_provider.dart';
import '../../data/models/loyalty_program.dart';
import '../widgets/loyalty_tier_card.dart';
import '../widgets/loyalty_points_card.dart';
import '../widgets/loyalty_reward_card.dart';
import '../../../../shared/widgets/custom_error_widget.dart';

/// Main customer loyalty program screen
class CustomerLoyaltyScreen extends ConsumerStatefulWidget {
  const CustomerLoyaltyScreen({super.key});

  @override
  ConsumerState<CustomerLoyaltyScreen> createState() => _CustomerLoyaltyScreenState();
}

class _CustomerLoyaltyScreenState extends ConsumerState<CustomerLoyaltyScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loyaltyState = ref.watch(customerLoyaltyProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loyalty Program'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              ref.read(customerLoyaltyProvider.notifier).refresh();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: theme.colorScheme.onPrimary,
          unselectedLabelColor: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
          indicatorColor: theme.colorScheme.onPrimary,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Rewards'),
            Tab(text: 'History'),
            Tab(text: 'Referrals'),
          ],
        ),
      ),
      body: loyaltyState.isLoading && loyaltyState.summary == null
          ? const Center(child: CircularProgressIndicator())
          : loyaltyState.error != null
              ? CustomErrorWidget(
                  message: loyaltyState.error!,
                  onRetry: () {
                    ref.read(customerLoyaltyProvider.notifier).clearError();
                    ref.read(customerLoyaltyProvider.notifier).refresh();
                  },
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(),
                    _buildRewardsTab(),
                    _buildHistoryTab(),
                    _buildReferralsTab(),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final summary = ref.watch(loyaltyProgramSummaryProvider);
    if (summary == null) return const Center(child: Text('No data available'));

    return RefreshIndicator(
      onRefresh: () => ref.read(customerLoyaltyProvider.notifier).refresh(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Points and tier cards
            LoyaltyPointsCard(
              loyaltyAccount: null, // TODO: Create LoyaltyAccount from summary data
            ),
            
            const SizedBox(height: 16),
            
            LoyaltyTierCard(
              currentTier: summary.currentTier,
              nextTier: summary.nextTier,
              pointsToNextTier: summary.pointsToNextTier ?? 0,
            ),
            
            const SizedBox(height: 24),
            
            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.redeem,
                    title: 'Redeem Rewards',
                    subtitle: '${summary.availableRewards.length} available',
                    onTap: () => _tabController.animateTo(1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildQuickActionCard(
                    icon: Icons.people,
                    title: 'Refer Friends',
                    subtitle: 'Earn bonus points',
                    onTap: () => _tabController.animateTo(3),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Recent transactions
            if (summary.recentTransactions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _tabController.animateTo(2),
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              ...summary.recentTransactions.take(3).map((transaction) {
                return _buildTransactionItem(transaction);
              }),
            ],
            
            // Active redemptions
            if (summary.activeRedemptions.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                'Active Rewards',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              
              ...summary.activeRedemptions.map((redemption) {
                return _buildActiveRedemptionCard(redemption);
              }),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsTab() {
    final rewards = ref.watch(availableLoyaltyRewardsProvider);
    final currentPoints = ref.watch(currentLoyaltyPointsProvider);

    if (rewards.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.redeem, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No rewards available'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(customerLoyaltyProvider.notifier).loadAvailableRewards(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: rewards.length,
        itemBuilder: (context, index) {
          final reward = rewards[index];
          final canAfford = currentPoints >= reward.pointsRequired;
          
          return LoyaltyRewardCard(
            reward: reward,
            canAfford: canAfford,
            onRedeem: () => _redeemReward(reward),
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    final transactions = ref.watch(recentLoyaltyTransactionsProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(customerLoyaltyProvider.notifier).loadTransactionHistory(),
      child: transactions.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No transaction history'),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                return _buildTransactionItem(transactions[index]);
              },
            ),
    );
  }

  Widget _buildReferralsTab() {
    final activeReferral = ref.watch(activeLoyaltyReferralProvider);

    return RefreshIndicator(
      onRefresh: () => ref.read(customerLoyaltyProvider.notifier).loadReferralHistory(),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Referral program info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.people,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Refer & Earn',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Invite friends to GigaEats and earn points when they place their first order!',
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '• You earn 100 points\n'
                      '• Your friend gets 50 points\n'
                      '• Friend must spend at least RM 25',
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Active referral or create new
            if (activeReferral != null)
              _buildActiveReferralCard(activeReferral)
            else
              _buildCreateReferralCard(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionItem(LoyaltyTransaction transaction) {
    final theme = Theme.of(context);
    final isPositive = transaction.transactionType.isPositive;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isPositive ? Colors.green.shade100 : Colors.red.shade100,
          child: Icon(
            _getTransactionIcon(transaction.transactionType),
            color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            size: 20,
          ),
        ),
        title: Text(transaction.description),
        subtitle: Text(_formatDate(transaction.createdAt)),
        trailing: Text(
          '${isPositive ? '+' : ''}${transaction.points}',
          style: theme.textTheme.titleSmall?.copyWith(
            color: isPositive ? Colors.green.shade700 : Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildActiveRedemptionCard(LoyaltyRedemption redemption) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.redeem, color: Colors.orange),
        title: Text(redemption.reward?.name ?? 'Reward'),
        subtitle: redemption.voucherCode != null 
            ? Text('Code: ${redemption.voucherCode}')
            : Text('${redemption.pointsUsed} points used'),
        trailing: redemption.expiresAt != null
            ? Text(
                'Expires ${_formatDate(redemption.expiresAt!)}',
                style: const TextStyle(fontSize: 12),
              )
            : null,
      ),
    );
  }

  Widget _buildActiveReferralCard(LoyaltyReferral referral) {
    return Card(
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
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      referral.referralCode,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      // TODO: Implement share functionality
                    },
                    icon: const Icon(Icons.share),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Share this code with friends to earn points!',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateReferralCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Icon(Icons.people, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            const Text(
              'Create Your Referral Code',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Generate a unique code to share with friends',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _createReferralCode,
              child: const Text('Create Referral Code'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _redeemReward(LoyaltyReward reward) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Reward'),
        content: Text('Redeem "${reward.name}" for ${reward.pointsRequired} points?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final redemption = await ref.read(customerLoyaltyProvider.notifier).redeemReward(reward.id);
      
      if (redemption != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully redeemed ${reward.name}!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  Future<void> _createReferralCode() async {
    final referral = await ref.read(customerLoyaltyProvider.notifier).createReferralCode();
    
    if (referral != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Referral code created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  IconData _getTransactionIcon(LoyaltyTransactionType type) {
    switch (type) {
      case LoyaltyTransactionType.earned:
        return Icons.add_circle;
      case LoyaltyTransactionType.redeemed:
        return Icons.remove_circle;
      case LoyaltyTransactionType.expired:
        return Icons.schedule;
      case LoyaltyTransactionType.bonus:
        return Icons.card_giftcard;
      case LoyaltyTransactionType.referral:
        return Icons.people;
      case LoyaltyTransactionType.adjustment:
        return Icons.tune;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
