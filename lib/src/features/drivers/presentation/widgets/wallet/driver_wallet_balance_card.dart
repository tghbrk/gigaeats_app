import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/driver_wallet.dart';
import '../../providers/driver_wallet_provider.dart';
import '../../providers/driver_wallet_realtime_provider.dart';

import 'realtime_balance_display.dart';

/// Driver wallet balance card widget following Material Design 3 patterns
/// Integrates with existing driver dashboard design
class DriverWalletBalanceCard extends ConsumerWidget {
  final bool showActions;
  final bool isCompact;

  const DriverWalletBalanceCard({
    super.key,
    this.showActions = true,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);
    final realtimeConnected = ref.watch(driverWalletRealtimeProvider);

    return Card(
      margin: EdgeInsets.zero,
      elevation: isCompact ? 1 : 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primary.withValues(alpha: 0.8),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(isCompact ? 16 : 24),
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
                        'Driver Wallet',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      _buildWalletStatus(context, walletState.wallet, realtimeConnected),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.account_balance_wallet,
                      color: Colors.white,
                      size: isCompact ? 20 : 24,
                    ),
                  ),
                ],
              ),
              
              SizedBox(height: isCompact ? 16 : 24),

              // Real-time Balance Display
              RealtimeBalanceDisplay(
                showChangeIndicator: true,
                showConnectionStatus: false, // We show status separately
                balanceTextStyle: theme.textTheme.headlineLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
                padding: EdgeInsets.zero,
              ),

              if (showActions && walletState.wallet != null && !isCompact) ...[
                const SizedBox(height: 24),
                _buildActionButtons(context, walletState.wallet!),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalletStatus(BuildContext context, DriverWallet? wallet, bool realtimeConnected) {
    final theme = Theme.of(context);
    
    if (wallet == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Not Found',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    Color statusColor;
    String statusText;

    if (!wallet.isActive) {
      statusColor = Colors.red;
      statusText = 'Inactive';
    } else if (!wallet.isVerified) {
      statusColor = Colors.orange;
      statusText = 'Unverified';
    } else if (!realtimeConnected) {
      statusColor = Colors.yellow;
      statusText = 'Offline';
    } else {
      statusColor = Colors.green;
      statusText = 'Active';
    }

    return Row(
      children: [
        Container(
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
        ),
        if (realtimeConnected) ...[
          const SizedBox(width: 8),
          Icon(
            Icons.wifi,
            size: 16,
            color: Colors.green.withValues(alpha: 0.8),
          ),
        ],
      ],
    );
  }





  Widget _buildActionButtons(BuildContext context, DriverWallet wallet) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: wallet.isActive && wallet.isVerified
                ? () => context.push('/driver/wallet/withdraw')
                : null,
            icon: const Icon(Icons.account_balance),
            label: const Text('Withdraw'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => context.push('/driver/wallet'),
            icon: const Icon(Icons.history),
            label: const Text('View Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: theme.colorScheme.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
      ],
    );
  }


}
