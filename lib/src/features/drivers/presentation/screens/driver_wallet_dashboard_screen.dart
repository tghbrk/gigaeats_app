import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/user_role.dart';
import '../../../../shared/widgets/auth_guard.dart';
import '../../../../shared/widgets/dashboard_card.dart';
import '../widgets/wallet/driver_wallet_balance_card.dart';
import '../widgets/wallet/driver_wallet_debug_panel.dart';
import '../widgets/verification/wallet_verification_banner.dart';
import '../../data/models/driver_wallet_transaction.dart';
import '../providers/driver_wallet_provider.dart';
import '../providers/driver_wallet_realtime_provider.dart';
import '../providers/driver_wallet_transaction_provider.dart';

/// Main driver wallet dashboard screen
class DriverWalletDashboardScreen extends ConsumerStatefulWidget {
  const DriverWalletDashboardScreen({super.key});

  @override
  ConsumerState<DriverWalletDashboardScreen> createState() => _DriverWalletDashboardScreenState();
}

class _DriverWalletDashboardScreenState extends ConsumerState<DriverWalletDashboardScreen> {
  @override
  void initState() {
    super.initState();
    debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] ========== SCREEN INIT ==========');
    // Initialize wallet data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] Post-frame callback: Loading wallet data');
      ref.read(driverWalletProvider.notifier).loadWallet();
      ref.read(driverWalletTransactionProvider.notifier).loadTransactions();
      debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] Wallet and transaction loading initiated');
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);

    debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] ========== SCREEN BUILD ==========');
    debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] Wallet state: hasWallet=${walletState.wallet != null}');
    debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] Loading: ${walletState.isLoading}');
    debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] Error: ${walletState.errorMessage}');

    return AuthGuard(
      allowedRoles: const [UserRole.driver, UserRole.admin],
      child: Scaffold(
        backgroundColor: theme.colorScheme.surfaceContainerLowest,
        appBar: AppBar(
          title: const Text('Driver Wallet'),
          backgroundColor: AppTheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          surfaceTintColor: Colors.transparent, // Disable Material 3 surface tinting
          shadowColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
          titleTextStyle: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
          actions: [
            IconButton(
              onPressed: _refreshData,
              icon: const Icon(Icons.refresh),
              color: Colors.white,
              tooltip: 'Refresh',
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
                // Verification banner (if wallet is unverified)
                if (walletState.wallet != null)
                  WalletVerificationBanner(wallet: walletState.wallet!),

                // Wallet Balance Card
                const DriverWalletBalanceCard(),
                const SizedBox(height: 24),

                // Quick Actions
                _buildQuickActions(context),
                const SizedBox(height: 24),

                // Wallet Statistics
                _buildWalletStatistics(context),
                const SizedBox(height: 24),

                // Recent Transactions
                _buildRecentTransactions(context),
                const SizedBox(height: 24),

                // Wallet Management Options
                _buildWalletManagement(context),

                // Debug Panel (only shown in debug mode)
                const DriverWalletDebugPanel(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _refreshData() async {
    debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] ========== REFRESH DATA ==========');
    debugPrint('🔍 [DRIVER-WALLET-DASHBOARD] Starting wallet and transaction refresh');

    try {
      await Future.wait([
        ref.read(driverWalletProvider.notifier).loadWallet(refresh: true),
        ref.read(driverWalletTransactionProvider.notifier).refreshTransactions(),
      ]);
      debugPrint('✅ [DRIVER-WALLET-DASHBOARD] Refresh completed successfully');
    } catch (e, stackTrace) {
      debugPrint('❌ [DRIVER-WALLET-DASHBOARD] Refresh failed: $e');
      debugPrint('❌ [DRIVER-WALLET-DASHBOARD] Stack trace: $stackTrace');
    }
  }

  Widget _buildQuickActions(BuildContext context) {
    final theme = Theme.of(context);
    final quickActions = ref.watch(driverWalletQuickActionsProvider);

    // Debug logging for quick actions
    debugPrint('🔍 [QUICK-ACTIONS-BUILD] ========== QUICK ACTIONS BUILD ==========');
    debugPrint('🔍 [QUICK-ACTIONS-BUILD] Quick actions map: $quickActions');
    debugPrint('🔍 [QUICK-ACTIONS-BUILD] canWithdraw: ${quickActions['canWithdraw']}');
    debugPrint('🔍 [QUICK-ACTIONS-BUILD] canViewTransactions: ${quickActions['canViewTransactions']}');
    debugPrint('🔍 [QUICK-ACTIONS-BUILD] showBalance: ${quickActions['showBalance']}');

    // Also check the wallet status directly
    final walletStatus = ref.watch(driverWalletStatusProvider);
    final walletState = ref.watch(driverWalletProvider);
    debugPrint('🔍 [QUICK-ACTIONS-BUILD] Wallet status: $walletStatus');
    debugPrint('🔍 [QUICK-ACTIONS-BUILD] Wallet state - balance: ${walletState.availableBalance}, active: ${walletState.isWalletActive}, verified: ${walletState.isWalletVerified}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Withdraw',
                subtitle: 'Transfer to bank',
                icon: Icons.account_balance,
                color: theme.colorScheme.primary,
                enabled: quickActions['canWithdraw'] ?? false,
                onTap: () => context.push('/driver/wallet/withdraw'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Transactions',
                subtitle: 'View history',
                icon: Icons.history,
                color: Colors.green,
                enabled: quickActions['canViewTransactions'] ?? false,
                onTap: () => context.push('/driver/wallet/transactions'),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Settings',
                subtitle: 'Manage wallet',
                icon: Icons.settings,
                color: Colors.orange,
                enabled: true,
                onTap: () => context.push('/driver/wallet/settings'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionCard(
                context,
                title: 'Support',
                subtitle: 'Get help',
                icon: Icons.help_outline,
                color: Colors.blue,
                enabled: true,
                onTap: () => context.push('/driver/wallet/support'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    // Debug logging for withdraw button
    if (title == 'Withdraw') {
      debugPrint('🔍 [WALLET-DASHBOARD] ========== WITHDRAW BUTTON DEBUG ==========');
      debugPrint('🔍 [WALLET-DASHBOARD] Button enabled: $enabled');
      debugPrint('🔍 [WALLET-DASHBOARD] Button title: $title');
      debugPrint('🔍 [WALLET-DASHBOARD] Button subtitle: $subtitle');
      debugPrint('🔍 [WALLET-DASHBOARD] Button color: $color');
      debugPrint('🔍 [WALLET-DASHBOARD] onTap callback: ${onTap.toString()}');
    }
    
    return Card(
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: enabled 
                ? color.withValues(alpha: 0.05)
                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: enabled ? color : theme.colorScheme.onSurfaceVariant,
                size: 32,
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: enabled 
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: enabled 
                      ? theme.colorScheme.onSurfaceVariant
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletStatistics(BuildContext context) {
    final theme = Theme.of(context);
    final earningsSummary = ref.watch(driverWalletEarningsSummaryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Statistics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.3, // Reduced from 1.5 to give more height
          children: [
            StatCard(
              title: 'Total Earned',
              value: earningsSummary['formattedTotalEarned'] ?? 'RM 0.00',
              icon: Icons.trending_up,
              color: Colors.green,
              onTap: () => context.push('/driver/wallet/analytics'),
            ),
            StatCard(
              title: 'Total Withdrawn',
              value: earningsSummary['formattedAvailableBalance'] ?? 'RM 0.00',
              icon: Icons.account_balance,
              color: Colors.blue,
              onTap: () => context.push('/driver/wallet/withdrawals'),
            ),
            StatCard(
              title: 'Pending Balance',
              value: 'RM ${earningsSummary['pendingBalance']?.toStringAsFixed(2) ?? '0.00'}',
              icon: Icons.schedule,
              color: Colors.orange,
            ),
            StatCard(
              title: 'Recent Earnings',
              value: earningsSummary['formattedRecentEarnings'] ?? 'RM 0.00',
              icon: Icons.today,
              color: Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentTransactions(BuildContext context) {
    final theme = Theme.of(context);
    final transactionState = ref.watch(driverWalletTransactionProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/driver/wallet/transactions'),
              child: const Text('View All'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        if (transactionState.isLoading)
          const Center(child: CircularProgressIndicator())
        else if (transactionState.transactions.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 48,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No transactions yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your wallet transactions will appear here',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          )
        else
          ...transactionState.transactions.take(3).map((transaction) =>
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: transaction.isCredit 
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  child: Icon(
                    transaction.isCredit ? Icons.add : Icons.remove,
                    color: transaction.isCredit ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(transaction.transactionType.value),
                subtitle: Text(transaction.formattedDateTime),
                trailing: Text(
                  transaction.formattedAmount,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: transaction.isCredit ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWalletManagement(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Wallet Management',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.security),
                title: const Text('Security Settings'),
                subtitle: const Text('Manage PIN and biometric authentication'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/driver/wallet/security'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.notifications),
                title: const Text('Notifications'),
                subtitle: const Text('Configure wallet alerts and updates'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/driver/wallet/notifications'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.help_outline),
                title: const Text('Help & Support'),
                subtitle: const Text('Get help with wallet issues'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/driver/wallet/support'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
