import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/dashboard_card.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/wallet_state_provider.dart';
import '../providers/wallet_transactions_provider.dart';
import '../providers/payout_management_provider.dart';
import '../providers/wallet_notifications_provider.dart';
import '../widgets/wallet_balance_card.dart';
import '../widgets/wallet_quick_actions.dart';
import '../widgets/recent_transactions_widget.dart';
import '../widgets/wallet_notifications_widget.dart';
import '../widgets/commission_summary_widget.dart';
import '../../../customers/presentation/widgets/wallet_analytics_summary_widget.dart';

class WalletDashboardScreen extends ConsumerStatefulWidget {
  const WalletDashboardScreen({super.key});

  @override
  ConsumerState<WalletDashboardScreen> createState() => _WalletDashboardScreenState();
}

class _WalletDashboardScreenState extends ConsumerState<WalletDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Trigger initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final walletActions = ref.read(walletActionsProvider);
    await walletActions.refreshCurrentUserWallet();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authStateProvider);
    final walletState = ref.watch(currentUserWalletProvider);
    final userRole = authState.user?.role.value ?? 'customer';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Wallet'),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        actions: [
          // Notifications badge
          Consumer(
            builder: (context, ref, child) {
              final unreadCount = ref.watch(currentUserUnreadNotificationsCountProvider);
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () => context.push('/wallet/notifications'),
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 99 ? '99+' : unreadCount.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/wallet/settings'),
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
              // Wallet Balance Card
              WalletBalanceCard(userRole: userRole),
              const SizedBox(height: 24),

              // Quick Actions
              WalletQuickActions(userRole: userRole),
              const SizedBox(height: 24),

              // Commission Summary (for earning roles)
              if (_shouldShowCommissionSummary(userRole)) ...[
                CommissionSummaryWidget(userRole: userRole),
                const SizedBox(height: 24),
              ],

              // Stats Section
              _buildStatsSection(context, userRole),
              const SizedBox(height: 24),

              // Analytics Summary (for customers)
              if (userRole == 'customer') ...[
                const WalletAnalyticsSummaryWidget(showHeader: true),
                const SizedBox(height: 24),
              ],

              // Recent Transactions
              _buildRecentTransactionsSection(context),
              const SizedBox(height: 24),

              // Notifications
              _buildNotificationsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  bool _shouldShowCommissionSummary(String userRole) {
    return ['vendor', 'sales_agent', 'driver'].contains(userRole);
  }

  Widget _buildStatsSection(BuildContext context, String userRole) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        _buildStatsGrid(context, userRole),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, String userRole) {
    return Consumer(
      builder: (context, ref, child) {
        final walletState = ref.watch(currentUserWalletProvider);
        final transactionState = ref.watch(currentUserTransactionHistoryProvider);
        final payoutState = ref.watch(currentUserPayoutManagementProvider);

        if (walletState.wallet == null) {
          return const LoadingWidget();
        }

        final wallet = walletState.wallet!;

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            // Total Earned
            StatCard(
              title: 'Total Earned',
              value: wallet.formattedTotalEarned,
              icon: Icons.trending_up,
              color: AppTheme.successColor,
              onTap: () => context.push('/wallet/analytics'),
            ),

            // Total Withdrawn
            StatCard(
              title: 'Total Withdrawn',
              value: wallet.formattedTotalWithdrawn,
              icon: Icons.account_balance,
              color: AppTheme.infoColor,
              onTap: () => context.push('/wallet/payouts'),
            ),

            // Recent Transactions
            StatCard(
              title: 'Transactions',
              value: transactionState.transactions.length.toString(),
              subtitle: 'This month',
              icon: Icons.receipt_long,
              color: AppTheme.primaryColor,
              onTap: () => context.push('/wallet/transactions'),
            ),

            // Pending Payouts
            StatCard(
              title: 'Pending Payouts',
              value: payoutState.payoutRequests
                  .where((p) => p.status.name == 'pending')
                  .length
                  .toString(),
              icon: Icons.schedule,
              color: AppTheme.warningColor,
              onTap: () => context.push('/wallet/payouts'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecentTransactionsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/wallet/transactions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const RecentTransactionsWidget(limit: 5),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Notifications',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/wallet/notifications'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        const WalletNotificationsWidget(limit: 3),
      ],
    );
  }
}

/// Role-specific wallet dashboard variants
class VendorWalletDashboard extends ConsumerWidget {
  const VendorWalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletDashboardScreen();
  }
}

class SalesAgentWalletDashboard extends ConsumerWidget {
  const SalesAgentWalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletDashboardScreen();
  }
}

class DriverWalletDashboard extends ConsumerWidget {
  const DriverWalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletDashboardScreen();
  }
}

class CustomerWalletDashboard extends ConsumerWidget {
  const CustomerWalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletDashboardScreen();
  }
}

class AdminWalletDashboard extends ConsumerWidget {
  const AdminWalletDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const WalletDashboardScreen();
  }
}
