import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/driver_wallet_notification_provider.dart';
import '../providers/driver_wallet_provider.dart';

/// Widget to display real-time wallet notifications for drivers
class DriverWalletNotificationWidget extends ConsumerWidget {
  final bool showAsCard;
  final bool showDismissButton;
  final VoidCallback? onDismiss;

  const DriverWalletNotificationWidget({
    super.key,
    this.showAsCard = true,
    this.showDismissButton = true,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lowBalanceAlert = ref.watch(driverWalletLowBalanceAlertProvider);
    final notificationState = ref.watch(driverWalletNotificationProvider);

    // Don't show if notifications are disabled
    if (!notificationState.isEnabled) {
      return const SizedBox.shrink();
    }

    // Show low balance alert if present
    if (lowBalanceAlert != null) {
      return _buildLowBalanceAlert(context, theme, lowBalanceAlert);
    }

    return const SizedBox.shrink();
  }

  Widget _buildLowBalanceAlert(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> alertData,
  ) {
    final severity = alertData['severity'] as String;
    final isCritical = severity == 'critical';
    final currentBalance = alertData['current_balance'] as double;
    // Removed unused variable threshold

    final alertColor = isCritical ? Colors.red : Colors.orange;
    final alertIcon = isCritical ? Icons.warning : Icons.info_outline;
    final title = alertData['title'] as String;
    final message = alertData['message'] as String;

    if (showAsCard) {
      return Card(
        margin: const EdgeInsets.all(16),
        color: alertColor.withValues(alpha: 0.1),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    alertIcon,
                    color: alertColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: alertColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (showDismissButton)
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: onDismiss,
                      iconSize: 20,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                message,
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('/driver/wallet'),
                      icon: const Icon(Icons.account_balance_wallet),
                      label: const Text('View Wallet'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => context.push('/driver/wallet/withdraw'),
                      icon: const Icon(Icons.money),
                      label: const Text('Withdraw'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: alertColor,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: alertColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: alertColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(
              alertIcon,
              color: alertColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: alertColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Balance: RM ${currentBalance.toStringAsFixed(2)}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () => context.push('/driver/wallet'),
              child: const Text('View'),
            ),
          ],
        ),
      );
    }
  }
}

/// Compact notification banner for driver dashboard
class DriverWalletNotificationBanner extends ConsumerWidget {
  const DriverWalletNotificationBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final lowBalanceAlert = ref.watch(driverWalletLowBalanceAlertProvider);
    final walletState = ref.watch(driverWalletProvider);

    if (lowBalanceAlert == null || walletState.wallet == null) {
      return const SizedBox.shrink();
    }

    final severity = lowBalanceAlert['severity'] as String;
    final isCritical = severity == 'critical';
    final alertColor = isCritical ? Colors.red : Colors.orange;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: alertColor.withValues(alpha: 0.1),
      child: Row(
        children: [
          Icon(
            isCritical ? Icons.warning : Icons.info_outline,
            color: alertColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Low Balance: ${walletState.wallet!.formattedAvailableBalance}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: alertColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          TextButton(
            onPressed: () => context.push('/driver/wallet'),
            style: TextButton.styleFrom(
              foregroundColor: alertColor,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
            child: const Text('View Wallet'),
          ),
        ],
      ),
    );
  }
}

/// Real-time earnings notification popup
class EarningsNotificationPopup extends StatelessWidget {
  final double earningsAmount;
  final double newBalance;
  final String orderId;
  final VoidCallback? onDismiss;

  const EarningsNotificationPopup({
    super.key,
    required this.earningsAmount,
    required this.newBalance,
    required this.orderId,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.monetization_on,
                color: Colors.green,
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            
            // Title
            Text(
              '💰 Earnings Received!',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // Earnings amount
            Text(
              'RM ${earningsAmount.toStringAsFixed(2)}',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // New balance
            Text(
              'New Balance: RM ${newBalance.toStringAsFixed(2)}',
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            
            // Order reference
            Text(
              'Order: $orderId',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onDismiss?.call();
                    },
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      context.push('/driver/wallet');
                      onDismiss?.call();
                    },
                    child: const Text('View Wallet'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Show earnings notification popup
  static void show(
    BuildContext context, {
    required double earningsAmount,
    required double newBalance,
    required String orderId,
    VoidCallback? onDismiss,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => EarningsNotificationPopup(
        earningsAmount: earningsAmount,
        newBalance: newBalance,
        orderId: orderId,
        onDismiss: onDismiss,
      ),
    );
  }
}
