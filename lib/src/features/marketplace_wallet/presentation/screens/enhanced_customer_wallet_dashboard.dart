import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/customer_wallet_provider.dart';
import '../providers/customer_transaction_management_provider.dart';
import '../widgets/enhanced_wallet_balance_card.dart';
import '../widgets/wallet_quick_actions_grid.dart';
import '../widgets/wallet_statistics_overview.dart';
import '../widgets/recent_transactions_preview.dart';
import '../widgets/wallet_security_status.dart';
import '../widgets/wallet_promotional_banner.dart';
import '../../../../core/utils/logger.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/models/customer_wallet.dart';

/// Enhanced customer wallet dashboard with Material Design 3 interface
class EnhancedCustomerWalletDashboard extends ConsumerStatefulWidget {
  const EnhancedCustomerWalletDashboard({super.key});

  @override
  ConsumerState<EnhancedCustomerWalletDashboard> createState() => _EnhancedCustomerWalletDashboardState();
}

class _EnhancedCustomerWalletDashboardState extends ConsumerState<EnhancedCustomerWalletDashboard>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final AppLogger _logger = AppLogger();


  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Start animation and load data
    _animationController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadWalletData();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _loadWalletData() {
    _logger.info('🏦 [WALLET-DASHBOARD] Loading wallet data');
    ref.read(customerWalletProvider.notifier).loadWallet();
    ref.read(customerTransactionManagementProvider.notifier).loadTransactions(refresh: true);
  }

  Future<void> _refreshData() async {
    _logger.info('🔄 [WALLET-DASHBOARD] Manual pull-to-refresh triggered');
    debugPrint('🔄 [WALLET-DASHBOARD] Current wallet balance before refresh: ${ref.read(customerWalletProvider).wallet?.formattedAvailableBalance ?? 'null'}');

    try {
      // Show loading state
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 12),
                Text('Refreshing wallet data...'),
              ],
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }

      // Force refresh both wallet and transactions
      await Future.wait([
        ref.read(customerWalletProvider.notifier).refreshWallet(),
        ref.read(customerTransactionManagementProvider.notifier).refresh(),
      ]);

      final newBalance = ref.read(customerWalletProvider).wallet?.formattedAvailableBalance ?? 'null';
      debugPrint('✅ [WALLET-DASHBOARD] Refresh completed. New wallet balance: $newBalance');

      // Show success feedback
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 16,
                ),
                const SizedBox(width: 12),
                Text('Wallet updated: $newBalance'),
              ],
            ),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green,
          ),
        );
      }

    } catch (e) {
      _logger.error('❌ [WALLET-DASHBOARD] Refresh failed: $e');

      // Show error feedback
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.error,
                  color: Theme.of(context).colorScheme.onError,
                  size: 16,
                ),
                const SizedBox(width: 12),
                const Text('Failed to refresh wallet. Please try again.'),
              ],
            ),
            duration: const Duration(seconds: 4),
            backgroundColor: Theme.of(context).colorScheme.error,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Theme.of(context).colorScheme.onError,
              onPressed: () => _refreshData(),
            ),
          ),
        );
      }

      // Re-throw to let RefreshIndicator handle the error state
      rethrow;
    }
  }

  /// Check if wallet data appears stale (older than 5 minutes)
  bool _isWalletDataStale(CustomerWallet wallet) {
    final now = DateTime.now();
    final walletAge = now.difference(wallet.updatedAt);

    // Consider data stale if it's older than 5 minutes
    // This helps users identify when they might need to refresh
    return walletAge.inMinutes > 5;
  }



  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainerLowest,
      appBar: _buildAppBar(theme),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _refreshData,
          color: theme.colorScheme.primary,
          backgroundColor: theme.colorScheme.surface,
          strokeWidth: 3.0,
          displacement: 60.0,
          triggerMode: RefreshIndicatorTriggerMode.anywhere,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Pull-to-refresh instruction banner (only show if wallet has stale data)
              if (walletState.wallet != null && _isWalletDataStale(walletState.wallet!))
                SliverToBoxAdapter(
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.refresh,
                          color: theme.colorScheme.onPrimaryContainer,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Pull down to refresh your wallet balance',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onPrimaryContainer,
                            ),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _refreshData,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Refresh'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Wallet Balance Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: EnhancedWalletBalanceCard(
                    onTopUpPressed: () => _navigateToTopUp(),
                    onTransferPressed: () => _navigateToTransfer(),
                    onPaymentMethodsPressed: () => _navigateToPaymentMethods(),
                  ),
                ),
              ),

              // Security Status Banner
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: WalletSecurityStatus(
                    onSecurityPressed: () => _navigateToSecurity(),
                  ),
                ),
              ),

              // Promotional Banner (if applicable)
              if (_shouldShowPromotionalBanner(walletState))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: WalletPromotionalBanner(
                      onBannerPressed: () => _handlePromotionalAction(),
                    ),
                  ),
                ),

              // Quick Actions Grid
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: WalletQuickActionsGrid(
                    onTopUpPressed: () => _navigateToTopUp(),
                    onTransferPressed: () => _navigateToTransfer(),
                    onTransactionsPressed: () => _navigateToTransactions(),
                    onPaymentMethodsPressed: () => _navigateToPaymentMethods(),
                    onLoyaltyPressed: () => _navigateToLoyalty(),
                    onSettingsPressed: () => _navigateToSettings(),
                    onVerificationPressed: () => _navigateToVerification(),
                  ),
                ),
              ),

              // Statistics Overview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: WalletStatisticsOverview(
                    onViewDetailsPressed: () => _navigateToAnalytics(),
                  ),
                ),
              ),

              // Recent Transactions Preview
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: RecentTransactionsPreview(
                    onViewAllPressed: () => _navigateToTransactions(),
                    onTransactionPressed: (transactionId) => _navigateToTransactionDetails(transactionId),
                  ),
                ),
              ),

              // Bottom padding for FAB
              const SliverToBoxAdapter(
                child: SizedBox(height: 80),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: _buildFloatingActionButton(theme),
    );
  }

  PreferredSizeWidget _buildAppBar(ThemeData theme) {
    return AppBar(
      title: const Text('My Wallet'),
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
          icon: const Icon(Icons.notifications_outlined),
          color: Colors.white,
          onPressed: () => _navigateToNotifications(),
          tooltip: 'Notifications',
        ),
        IconButton(
          icon: const Icon(Icons.help_outline),
          color: Colors.white,
          onPressed: () => _navigateToHelp(),
          tooltip: 'Help & Support',
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: _handleMenuAction,
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  Icon(Icons.settings),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'security',
              child: Row(
                children: [
                  Icon(Icons.security),
                  SizedBox(width: 8),
                  Text('Security'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'export',
              child: Row(
                children: [
                  Icon(Icons.download),
                  SizedBox(width: 8),
                  Text('Export Data'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFloatingActionButton(ThemeData theme) {
    return FloatingActionButton.extended(
      onPressed: () => _showQuickActionBottomSheet(),
      icon: const Icon(Icons.add),
      label: const Text('Quick Action'),
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
    );
  }

  bool _shouldShowPromotionalBanner(CustomerWalletState walletState) {
    // Show promotional banner for new users or special offers
    return walletState.wallet?.availableBalance == 0.0 ||
           walletState.wallet?.createdAt.isAfter(DateTime.now().subtract(const Duration(days: 7))) == true;
  }

  void _showQuickActionBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionButton(
                  icon: Icons.add_circle,
                  label: 'Top Up',
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToTopUp();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.send,
                  label: 'Transfer',
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToTransfer();
                  },
                ),
                _buildQuickActionButton(
                  icon: Icons.receipt_long,
                  label: 'History',
                  onPressed: () {
                    Navigator.pop(context);
                    _navigateToTransactions();
                  },
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            onPressed: onPressed,
            icon: Icon(icon),
            iconSize: 32,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _navigateToSettings();
        break;
      case 'security':
        _navigateToSecurity();
        break;
      case 'export':
        _navigateToExport();
        break;
    }
  }

  // Navigation methods
  void _navigateToTopUp() => context.push('/customer/wallet/top-up');
  void _navigateToTransfer() => context.push('/customer/wallet/transfer');
  // Transfer history navigation removed (was unused)
  void _navigateToTransactions() => context.push('/customer/wallet/transactions');

  void _navigateToPaymentMethods() {
    _logger.info('🔍 [WALLET-DASHBOARD] Attempting to navigate to payment methods');

    // Check authentication before navigation
    final authState = ref.read(authStateProvider);
    _logger.info('🔐 [WALLET-DASHBOARD] Auth status: ${authState.status}');

    if (authState.status != AuthStatus.authenticated || authState.user == null) {
      _logger.warning('❌ [WALLET-DASHBOARD] User not authenticated, showing error');
      _showAuthenticationRequiredDialog();
      return;
    }

    _logger.info('✅ [WALLET-DASHBOARD] User authenticated, navigating to payment methods');
    context.push('/customer/wallet/payment-methods');
  }

  void _navigateToLoyalty() => context.push('/customer/wallet/loyalty');
  void _navigateToSettings() => context.push('/customer/wallet/settings');
  void _navigateToSecurity() => context.push('/customer/wallet/security');
  void _navigateToAnalytics() => context.push('/customer/wallet/analytics');
  void _navigateToVerification() {
    _logger.info('🔐 [WALLET-DASHBOARD] Navigating to wallet verification');
    context.push('/customer/wallet/verification');
  }
  void _navigateToNotifications() => context.push('/customer/wallet/notifications');
  void _navigateToHelp() => context.push('/customer/wallet/help');
  void _navigateToExport() => context.push('/customer/wallet/export');
  void _navigateToTransactionDetails(String transactionId) => context.push('/wallet/transaction/$transactionId');
  void _handlePromotionalAction() => context.push('/wallet/promotions');

  void _showAuthenticationRequiredDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Required'),
        content: const Text(
          'You need to be signed in to access payment methods. Please sign in and try again.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
