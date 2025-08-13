import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/customer_wallet_provider.dart';

/// Customer wallet balance card for dashboard display
class CustomerWalletBalanceCard extends ConsumerWidget {
  final bool showActions;
  final bool compact;

  const CustomerWalletBalanceCard({
    super.key,
    this.showActions = true,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(customerWalletProvider);
    final walletStreamAsync = ref.watch(customerWalletStreamProvider);

    // Use real-time data when available, fallback to regular provider
    final effectiveWallet = walletStreamAsync.when(
      data: (streamWallet) => streamWallet ?? walletState.wallet,
      loading: () => walletState.wallet,
      error: (_, _) => walletState.wallet,
    );

    // Create effective state combining stream data with provider state
    final effectiveState = CustomerWalletState(
      wallet: effectiveWallet,
      isLoading: walletState.isLoading && !walletStreamAsync.hasValue,
      errorMessage: walletState.errorMessage,
      error: walletState.error,
      isRefreshing: walletState.isRefreshing,
      lastUpdated: walletState.lastUpdated,
      retryCount: walletState.retryCount,
    );

    return Card(
      elevation: 4,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        splashColor: Colors.white24,
        highlightColor: Colors.white10,
        onTap: () => context.push('/customer/wallet'),
        child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
          padding: EdgeInsets.all(compact ? 16 : 24),
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
                        'Wallet Balance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildWalletStatus(context, effectiveState),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ],
              ),
              SizedBox(height: compact ? 16 : 24),

              // Balance Display
              if (effectiveState.isLoading)
                const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else if (effectiveState.hasError)
                _buildErrorState(context, effectiveState)
              else if (effectiveState.wallet != null)
                _buildBalanceDisplay(context, effectiveState, compact)
              else
                _buildNoWalletState(context),

              if (showActions && effectiveState.wallet != null && !compact) ...[
                SizedBox(height: compact ? 16 : 24),
                _buildActionButtons(context),
              ],
            ],
          ),
        ),
      ),
    ),
  );
  }

  Widget _buildWalletStatus(BuildContext context, CustomerWalletState walletState) {
    final theme = Theme.of(context);
    
    if (walletState.wallet == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'No Wallet',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final wallet = walletState.wallet!;
    Color statusColor;
    String statusText;

    if (!wallet.isActive) {
      statusColor = Colors.red;
      statusText = 'Inactive';
    } else if (!wallet.isVerified) {
      statusColor = Colors.orange;
      statusText = 'Unverified';
    } else {
      statusColor = Colors.green;
      statusText = 'Active';
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
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBalanceDisplay(BuildContext context, CustomerWalletState walletState, bool compact) {
    final theme = Theme.of(context);
    final wallet = walletState.wallet!;
    
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
            fontSize: compact ? 24 : 32,
          ),
        ),
        
        if (!compact && wallet.pendingBalance > 0) ...[
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.schedule,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 4),
              Text(
                'Pending: ${wallet.formattedPendingBalance}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildErrorState(BuildContext context, CustomerWalletState walletState) {
    final theme = Theme.of(context);
    
    return Column(
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.white.withValues(alpha: 0.8),
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          'Failed to load wallet',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          walletState.displayErrorMessage,
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
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
          size: 32,
        ),
        const SizedBox(height: 8),
        Text(
          'No wallet found',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to create your wallet',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/customer/wallet/top-up'),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Top Up'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Theme.of(context).colorScheme.primary,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/customer/wallet'),
            icon: const Icon(Icons.history, size: 18),
            label: const Text('History'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }
}
