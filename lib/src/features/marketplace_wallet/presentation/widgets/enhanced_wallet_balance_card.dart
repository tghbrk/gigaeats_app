import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/customer_wallet_provider.dart';
import '../../data/models/customer_wallet.dart';

/// Enhanced wallet balance card with Material Design 3 styling
class EnhancedWalletBalanceCard extends ConsumerWidget {
  final VoidCallback? onTopUpPressed;
  final VoidCallback? onTransferPressed;
  final VoidCallback? onPaymentMethodsPressed;
  final bool showActions;
  final bool compact;

  const EnhancedWalletBalanceCard({
    super.key,
    this.onTopUpPressed,
    this.onTransferPressed,
    this.onPaymentMethodsPressed,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);

    return Container(
      margin: EdgeInsets.symmetric(vertical: compact ? 8 : 16),
      child: Card(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
                theme.colorScheme.primaryContainer,
              ],
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(compact ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with wallet status
                _buildHeader(theme, walletState),
                
                SizedBox(height: compact ? 16 : 24),
                
                // Balance display
                if (walletState.isLoading)
                  _buildLoadingState(theme)
                else if (walletState.hasError)
                  _buildErrorState(theme, walletState.errorMessage!)
                else if (walletState.wallet != null)
                  _buildBalanceDisplay(theme, walletState.wallet!, compact)
                else
                  _buildNoWalletState(theme),
                
                if (showActions && walletState.wallet != null && !compact) ...[
                  SizedBox(height: compact ? 16 : 24),
                  _buildActionButtons(theme),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, CustomerWalletState walletState) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: Colors.white,
            size: 24,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'My Wallet',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              _buildWalletStatusChip(theme, walletState),
            ],
          ),
        ),
        if (walletState.wallet != null)
          _buildWalletMenu(theme),
      ],
    );
  }

  Widget _buildWalletStatusChip(ThemeData theme, CustomerWalletState walletState) {
    String statusText;
    Color statusColor;
    IconData statusIcon;

    if (walletState.isLoading) {
      statusText = 'Loading...';
      statusColor = Colors.white.withValues(alpha: 0.7);
      statusIcon = Icons.hourglass_empty;
    } else if (walletState.hasError) {
      statusText = 'Error';
      statusColor = theme.colorScheme.error;
      statusIcon = Icons.error_outline;
    } else if (walletState.wallet == null) {
      statusText = 'Not Found';
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber;
    } else if (walletState.wallet!.isActive) {
      statusText = 'Active';
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else {
      statusText = 'Inactive';
      statusColor = Colors.red;
      statusIcon = Icons.cancel;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 12,
            color: statusColor,
          ),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: theme.textTheme.bodySmall?.copyWith(
              color: statusColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWalletMenu(ThemeData theme) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert,
        color: Colors.white,
      ),
      color: theme.colorScheme.surface,
      onSelected: (value) {
        switch (value) {
          case 'refresh':
            // Handle refresh
            break;
          case 'details':
            // Handle wallet details
            break;
          case 'settings':
            // Handle wallet settings
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'refresh',
          child: Row(
            children: [
              Icon(Icons.refresh),
              SizedBox(width: 8),
              Text('Refresh'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'details',
          child: Row(
            children: [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Text('Details'),
            ],
          ),
        ),
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
      ],
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            strokeWidth: 3,
          ),
          const SizedBox(height: 12),
          Text(
            'Loading wallet...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 32,
          ),
          const SizedBox(height: 8),
          Text(
            'Error Loading Wallet',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            error,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceDisplay(ThemeData theme, CustomerWallet wallet, bool compact) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Available balance
        Text(
          'Available Balance',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          wallet.formattedAvailableBalance,
          style: theme.textTheme.headlineLarge?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: compact ? 28 : 36,
          ),
        ),
        
        if (!compact && wallet.pendingBalance > 0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
                const SizedBox(width: 6),
                Text(
                  'Pending: ${wallet.formattedPendingBalance}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildNoWalletState(ThemeData theme) {
    return Center(
      child: Column(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: Colors.white.withValues(alpha: 0.8),
            size: 48,
          ),
          const SizedBox(height: 12),
          Text(
            'Wallet Not Found',
            style: theme.textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w600,
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
      ),
    );
  }

  Widget _buildActionButtons(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            theme: theme,
            icon: Icons.add_circle_outline,
            label: 'Top Up',
            onPressed: onTopUpPressed,
            isPrimary: true,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            theme: theme,
            icon: Icons.send_outlined,
            label: 'Transfer',
            onPressed: onTransferPressed,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildActionButton(
            theme: theme,
            icon: Icons.credit_card_outlined,
            label: 'Cards',
            onPressed: onPaymentMethodsPressed,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required ThemeData theme,
    required IconData icon,
    required String label,
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isPrimary 
            ? Colors.white
            : Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: isPrimary 
            ? null 
            : Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(
                  icon,
                  color: isPrimary 
                      ? theme.colorScheme.primary
                      : Colors.white,
                  size: 20,
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: isPrimary 
                        ? theme.colorScheme.primary
                        : Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
