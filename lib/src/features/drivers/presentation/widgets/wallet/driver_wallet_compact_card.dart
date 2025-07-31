import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/driver_wallet_provider.dart';
import '../../providers/driver_wallet_transaction_provider.dart';

/// Compact wallet card for driver dashboard
class DriverWalletCompactCard extends ConsumerWidget {
  const DriverWalletCompactCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletAsync = ref.watch(driverWalletProvider);

    debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] ========== WIDGET BUILD ==========');
    debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] Wallet state: hasWallet=${walletAsync.wallet != null}');
    debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] Loading state: ${walletAsync.isLoading}');
    debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] Error message: ${walletAsync.errorMessage}');

    if (walletAsync.wallet != null) {
      debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] Wallet data available: ${walletAsync.wallet!.formattedAvailableBalance}');
    }

    // TEST: Trigger transaction loading to test our fix
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] TEST: Triggering transaction loading to test authentication fix...');
      try {
        ref.read(driverWalletTransactionProvider.notifier).loadTransactions();
        debugPrint('✅ [DRIVER-WALLET-COMPACT-CARD] TEST: Transaction loading triggered successfully');
      } catch (e) {
        debugPrint('❌ [DRIVER-WALLET-COMPACT-CARD] TEST: Transaction loading failed: $e');
      }
    });

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: InkWell(
          onTap: () {
            debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] Wallet card tapped, navigating to /driver/wallet');
            debugPrint('🔍 [DRIVER-WALLET-COMPACT-CARD] Testing route navigation...');
            try {
              context.push('/driver/wallet');
              debugPrint('✅ [DRIVER-WALLET-COMPACT-CARD] Navigation to /driver/wallet successful');
            } catch (e) {
              debugPrint('❌ [DRIVER-WALLET-COMPACT-CARD] Navigation failed: $e');
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: walletAsync.wallet != null
                ? _buildWalletContent(context, theme, walletAsync.wallet!)
                : walletAsync.isLoading
                    ? _buildLoadingContent(theme)
                    : _buildErrorContent(theme, walletAsync.errorMessage ?? 'Unknown error'),
          ),
        ),
      ),
    );
  }

  Widget _buildWalletContent(BuildContext context, ThemeData theme, wallet) {
    final availableBalance = wallet?.availableBalance ?? 0.0;
    final pendingBalance = wallet?.pendingBalance ?? 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Wallet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const Spacer(),
            Icon(
              Icons.chevron_right,
              color: theme.colorScheme.onSurfaceVariant,
              size: 16,
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Balance information
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Available',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'RM ${availableBalance.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            
            if (pendingBalance > 0) ...[
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pending',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'RM ${pendingBalance.toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Quick actions
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.push('/driver/wallet/transactions'),
                icon: const Icon(Icons.history, size: 16),
                label: const Text('History'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            Expanded(
              child: ElevatedButton.icon(
                onPressed: wallet.isActive && wallet.isVerified
                    ? () => context.push('/driver/wallet/withdraw')
                    : null,
                icon: const Icon(Icons.account_balance, size: 16),
                label: const Text('Withdraw'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingContent(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Wallet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildErrorContent(ThemeData theme, Object error) {
    debugPrint('❌ [DRIVER-WALLET-COMPACT-CARD] Building error content');
    debugPrint('❌ [DRIVER-WALLET-COMPACT-CARD] Error details: $error');
    debugPrint('❌ [DRIVER-WALLET-COMPACT-CARD] Error type: ${error.runtimeType}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.account_balance_wallet,
              color: theme.colorScheme.primary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              'Wallet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        Row(
          children: [
            Icon(
              Icons.error_outline,
              color: theme.colorScheme.error,
              size: 16,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Failed to load wallet',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
