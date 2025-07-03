import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../core/theme/app_theme.dart';
import '../../../../auth/presentation/providers/auth_provider.dart';
import '../../providers/customer_wallet_provider.dart';
import '../../providers/customer_payment_methods_provider.dart';
import '../../widgets/customer_wallet_error_widget.dart';
import '../../widgets/customer_wallet_transaction_history_widget.dart';
import '../../widgets/customer_payment_method_card.dart';
import '../../../../customers/presentation/widgets/wallet_analytics_summary_widget.dart';
import '../../../../customers/presentation/widgets/analytics_quick_action_widget.dart';
import 'customer_wallet_transaction_history_screen.dart';
import 'customer_wallet_topup_screen.dart';
import 'customer_wallet_transfer_screen.dart';
import 'customer_wallet_settings_screen.dart';
import 'customer_spending_analytics_screen.dart';
import 'social_wallet_screen.dart';
import '../../../../customers/presentation/screens/loyalty_dashboard_screen.dart';
import '../../../../payments/presentation/screens/customer/customer_payment_methods_screen.dart';

class CustomerWalletScreen extends ConsumerStatefulWidget {
  const CustomerWalletScreen({super.key});

  @override
  ConsumerState<CustomerWalletScreen> createState() => _CustomerWalletScreenState();
}

class _CustomerWalletScreenState extends ConsumerState<CustomerWalletScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [CUSTOMER-WALLET] Screen initialized');

    // Load wallet data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(customerWalletProvider.notifier).loadWallet();
    });
  }

  Future<void> _refreshData() async {
    debugPrint('🔍 [CUSTOMER-WALLET] Refreshing wallet data');
    await ref.read(customerWalletProvider.notifier).refreshWallet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final user = authState.user;

    debugPrint('🔍 [CUSTOMER-WALLET] Building screen for user: ${user?.email}');

    // Show error snackbar if there's an error
    ref.listen<CustomerWalletState>(customerWalletProvider, (previous, next) {
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!.userFriendlyMessage),
            backgroundColor: theme.colorScheme.error,
            duration: Duration(seconds: next.error!.isRetryable ? 6 : 4),
            action: next.error!.isRetryable
                ? SnackBarAction(
                    label: 'Retry',
                    textColor: theme.colorScheme.onError,
                    onPressed: () {
                      ref.read(customerWalletProvider.notifier).clearError();
                      ref.read(customerWalletProvider.notifier).retryLoadWallet();
                    },
                  )
                : null,
          ),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Wallet'),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error banner (if there's an error)
              Consumer(
                builder: (context, ref, child) {
                  final walletState = ref.watch(customerWalletProvider);
                  if (walletState.error != null && !walletState.isLoading) {
                    return CustomerWalletErrorBanner(error: walletState.error!);
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Wallet Balance Card
              _buildWalletBalanceCard(context),
              const SizedBox(height: 24),

              // Quick Actions
              _buildQuickActionsSection(context),
              const SizedBox(height: 24),

              // Analytics Summary
              const WalletAnalyticsSummaryWidget(),
              const SizedBox(height: 24),

              // Enhanced Analytics Quick Action
              const AnalyticsQuickActionWidget(
                actions: [],
              ),
              const SizedBox(height: 24),

              // Recent Transactions
              _buildRecentTransactionsSection(context),
              const SizedBox(height: 24),

              // Payment Methods
              _buildPaymentMethodsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletBalanceCard(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Available Balance',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: Colors.white.withValues(alpha: 0.95),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (walletState.isLoading)
            Row(
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  walletState.isRefreshing ? 'Refreshing...' : 'Loading...',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            )
          else if (walletState.hasError && !walletState.hasWallet)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RM 0.00',
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange.shade200,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Unable to load balance',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.orange.shade200,
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Text(
              walletState.formattedBalance,
              style: theme.textTheme.headlineLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            walletState.hasWallet
                ? 'Last updated: ${_formatLastUpdated(walletState.lastUpdated)}'
                : 'Tap refresh to load wallet data',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.85),
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  String _formatLastUpdated(DateTime? lastUpdated) {
    if (lastUpdated == null) return 'Never';

    final now = DateTime.now();
    final difference = now.difference(lastUpdated);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 1.1,
          children: [
            _buildQuickActionCard(
              context,
              'Top Up',
              Icons.add_circle_outline,
              AppTheme.successColor,
              () => _navigateToTopUp(context),
            ),
            _buildQuickActionCard(
              context,
              'Transfer',
              Icons.send_outlined,
              AppTheme.infoColor,
              () => _navigateToTransfer(context),
            ),
            _buildQuickActionCard(
              context,
              'History',
              Icons.history,
              AppTheme.primaryColor,
              () => _navigateToTransactionHistory(context),
            ),
            _buildQuickActionCard(
              context,
              'Settings',
              Icons.settings_outlined,
              AppTheme.warningColor,
              () => _navigateToWalletSettings(context),
            ),
            _buildQuickActionCard(
              context,
              'Analytics',
              Icons.analytics_outlined,
              AppTheme.successColor,
              () => _navigateToAnalytics(context),
            ),
            _buildQuickActionCard(
              context,
              'Social',
              Icons.groups_outlined,
              AppTheme.infoColor,
              () => _navigateToSocialWallet(context),
            ),
            _buildQuickActionCard(
              context,
              'Loyalty',
              Icons.stars_outlined,
              Colors.purple,
              () => _navigateToLoyalty(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    final theme = Theme.of(context);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    return CustomerWalletTransactionHistoryWidget(
      maxItems: 5,
      onViewAll: () => _navigateToTransactionHistory(context),
    );
  }

  void _navigateToTransactionHistory(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerWalletTransactionHistoryScreen(),
      ),
    );
  }

  void _navigateToTopUp(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerWalletTopupScreen(),
      ),
    );
  }

  void _navigateToTransfer(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerWalletTransferScreen(),
      ),
    );
  }

  void _navigateToWalletSettings(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerWalletSettingsScreen(),
      ),
    );
  }

  void _navigateToAnalytics(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerSpendingAnalyticsScreen(),
      ),
    );
  }

  void _navigateToSocialWallet(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const SocialWalletScreen(),
      ),
    );
  }

  void _navigateToLoyalty(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const LoyaltyDashboardScreen(),
      ),
    );
  }

  Widget _buildPaymentMethodsSection(BuildContext context) {
    final theme = Theme.of(context);
    final paymentMethodsAsync = ref.watch(customerPaymentMethodsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Payment Methods',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => _navigateToPaymentMethods(context),
              child: const Text('Manage'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        paymentMethodsAsync.when(
          data: (paymentMethods) {
            if (paymentMethods.isEmpty) {
              return _buildEmptyPaymentMethodsCard(context);
            }

            // Show up to 2 payment methods
            final displayMethods = paymentMethods.take(2).toList();
            return Column(
              children: displayMethods.map((method) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: CompactPaymentMethodCard(
                  paymentMethod: method,
                  onTap: () => _navigateToPaymentMethods(context),
                ),
              )).toList(),
            );
          },
          loading: () => const Card(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
          error: (error, stack) => _buildEmptyPaymentMethodsCard(context),
        ),
      ],
    );
  }



  Widget _buildEmptyPaymentMethodsCard(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(50),
              ),
              child: Icon(
                Icons.credit_card_outlined,
                size: 32,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No payment methods',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add a payment method to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => _navigateToPaymentMethods(context),
              icon: const Icon(Icons.add),
              label: const Text('Add Payment Method'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToPaymentMethods(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CustomerPaymentMethodsScreen(),
      ),
    );
  }


}
