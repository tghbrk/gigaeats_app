import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../providers/driver_wallet_provider.dart';
import '../../providers/driver_wallet_realtime_provider.dart';

/// Quick wallet summary widget for integration into dashboard header
/// Displays balance and status in a compact format
class DriverWalletQuickSummary extends ConsumerWidget {
  final bool showIcon;
  final bool isClickable;

  const DriverWalletQuickSummary({
    super.key,
    this.showIcon = true,
    this.isClickable = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);

    Widget content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Reduced padding
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6), // Smaller border radius
        border: Border.all(
          color: theme.colorScheme.onPrimary.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIcon) ...[
            Icon(
              Icons.account_balance_wallet,
              size: 14, // Smaller icon
              color: theme.colorScheme.onPrimary,
            ),
            const SizedBox(width: 4), // Reduced spacing
          ],

          if (walletState.isLoading)
            SizedBox(
              width: 10, // Smaller loading indicator
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  theme.colorScheme.onPrimary,
                ),
              ),
            )
          else if (walletState.errorMessage != null)
            Text(
              'ERROR',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w500,
                fontSize: 10, // Smaller font for error
              ),
            )
          else
            Text(
              walletState.formattedAvailableBalance,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
                fontSize: 11, // Slightly smaller font
              ),
              overflow: TextOverflow.ellipsis, // Handle long amounts
              maxLines: 1,
            ),

          if (isClickable) ...[
            const SizedBox(width: 3), // Reduced spacing
            Icon(
              Icons.chevron_right,
              size: 12, // Smaller chevron
              color: theme.colorScheme.onPrimary.withValues(alpha: 0.7),
            ),
          ],
        ],
      ),
    );

    if (isClickable) {
      return GestureDetector(
        onTap: () => context.push('/driver/wallet'),
        child: content,
      );
    }

    return content;
  }
}

/// Wallet status indicator for dashboard
class DriverWalletStatusIndicator extends ConsumerWidget {
  const DriverWalletStatusIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletStatus = ref.watch(driverWalletStatusProvider);
    final notification = ref.watch(driverWalletNotificationProvider);

    Color statusColor;
    IconData statusIcon;
    String tooltip;

    switch (walletStatus) {
      case 'active':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        tooltip = 'Wallet Active';
        break;
      case 'unverified':
        statusColor = Colors.orange;
        statusIcon = Icons.warning;
        tooltip = 'Wallet Unverified';
        break;
      case 'inactive':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        tooltip = 'Wallet Inactive';
        break;
      case 'offline':
        statusColor = Colors.grey;
        statusIcon = Icons.wifi_off;
        tooltip = 'Offline';
        break;
      case 'loading':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        tooltip = 'Loading...';
        break;
      case 'error':
        statusColor = Colors.red;
        statusIcon = Icons.error_outline;
        tooltip = 'Error';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        tooltip = 'Unknown Status';
    }

    return Stack(
      children: [
        Tooltip(
          message: tooltip,
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              statusIcon,
              size: 16,
              color: statusColor,
            ),
          ),
        ),
        
        // Notification badge
        if (notification != null)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: notification['severity'] == 'error' 
                    ? Colors.red 
                    : notification['severity'] == 'warning'
                        ? Colors.orange
                        : Colors.blue,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
      ],
    );
  }
}

/// Compact wallet card for dashboard integration
class DriverWalletCompactCard extends ConsumerWidget {
  const DriverWalletCompactCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final walletState = ref.watch(driverWalletProvider);
    final earningsSummary = ref.watch(driverWalletEarningsSummaryProvider);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () => context.push('/driver/wallet'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                        ),
                      ),
                    ],
                  ),
                  const DriverWalletStatusIndicator(),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Balance and Recent Earnings
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
                          walletState.formattedAvailableBalance,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  Container(
                    width: 1,
                    height: 40,
                    color: theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Recent (7d)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          earningsSummary['formattedRecentEarnings'] ?? 'RM 0.00',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              
              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: walletState.isWalletActive && walletState.isWalletVerified
                          ? () => context.push('/driver/wallet/withdraw')
                          : null,
                      icon: const Icon(Icons.account_balance, size: 16),
                      label: const Text('Withdraw'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/driver/wallet/transactions'),
                      icon: const Icon(Icons.history, size: 16),
                      label: const Text('History'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
