import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';

import '../providers/wallet_state_provider.dart';
import '../../data/models/stakeholder_wallet.dart';

class WalletBalanceCard extends ConsumerWidget {
  final String userRole;
  final bool showActions;

  const WalletBalanceCard({
    super.key,
    required this.userRole,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(currentUserWalletProvider);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryColor,
            AppTheme.primaryColor.withValues(alpha: 0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getRoleDisplayName(userRole)} Wallet',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildWalletStatus(context, walletState.wallet),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getRoleIcon(userRole),
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Balance Display
            if (walletState.isLoading)
              const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            else if (walletState.errorMessage != null)
              _buildErrorState(context, walletState.errorMessage!)
            else if (walletState.wallet != null)
              _buildBalanceDisplay(context, walletState.wallet!)
            else
              _buildNoWalletState(context),

            if (showActions && walletState.wallet != null) ...[
              const SizedBox(height: 24),
              _buildActionButtons(context, walletState.wallet!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWalletStatus(BuildContext context, StakeholderWallet? wallet) {
    final theme = Theme.of(context);
    
    if (wallet == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Setting up...',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.orange[100],
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final status = wallet.status;
    Color statusColor;
    String statusText;

    switch (status) {
      case WalletStatus.active:
        statusColor = Colors.green;
        statusText = 'Active';
        break;
      case WalletStatus.inactive:
        statusColor = Colors.red;
        statusText = 'Inactive';
        break;
      case WalletStatus.unverified:
        statusColor = Colors.orange;
        statusText = 'Unverified';
        break;
      case WalletStatus.empty:
        statusColor = Colors.grey;
        statusText = 'Empty';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        statusText,
        style: theme.textTheme.bodySmall?.copyWith(
          color: statusColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay(BuildContext context, StakeholderWallet wallet) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available Balance
        Text(
          'Available Balance',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          wallet.formattedAvailableBalance,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        // Pending Balance (if any)
        if (wallet.pendingBalance > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'Pending: MYR ${wallet.pendingBalance.toStringAsFixed(2)}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],

        // Auto Payout Status
        if (wallet.autoPayoutEnabled && wallet.autoPayoutThreshold != null) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.autorenew,
                size: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 4),
              Text(
                'Auto payout at MYR ${wallet.autoPayoutThreshold!.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.white.withValues(alpha: 0.8),
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'Failed to load wallet',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          error,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildNoWalletState(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          Icons.account_balance_wallet_outlined,
          color: Colors.white.withValues(alpha: 0.8),
          size: 48,
        ),
        const SizedBox(height: 12),
        Text(
          'Wallet not found',
          style: theme.textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Your wallet is being set up',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, StakeholderWallet wallet) {
    return Row(
      children: [
        // Request Payout Button
        if (wallet.canRequestPayout) ...[
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () => context.push('/wallet/payout/create'),
              icon: const Icon(Icons.account_balance),
              label: const Text('Request Payout'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
        ],

        // View Transactions Button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/wallet/transactions'),
            icon: const Icon(Icons.receipt_long),
            label: const Text('Transactions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getRoleDisplayName(String role) {
    switch (role) {
      case 'vendor':
        return 'Vendor';
      case 'sales_agent':
        return 'Sales Agent';
      case 'driver':
        return 'Driver';
      case 'customer':
        return 'Customer';
      case 'admin':
        return 'Admin';
      default:
        return role.toUpperCase();
    }
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'vendor':
        return Icons.store;
      case 'sales_agent':
        return Icons.person_outline;
      case 'driver':
        return Icons.local_shipping;
      case 'customer':
        return Icons.person;
      case 'admin':
        return Icons.admin_panel_settings;
      default:
        return Icons.account_balance_wallet;
    }
  }
}
