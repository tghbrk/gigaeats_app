import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/driver_wallet_notification_provider.dart';

/// Widget for managing driver wallet notification preferences
class DriverWalletNotificationSettingsWidget extends ConsumerWidget {
  const DriverWalletNotificationSettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationState = ref.watch(driverWalletNotificationProvider);
    final notificationNotifier = ref.read(driverWalletNotificationProvider.notifier);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.notifications_active,
                  color: theme.primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'Wallet Notifications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Manage how you receive notifications about your wallet activities',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 24),

            // Master toggle
            _buildMasterToggle(
              context,
              theme,
              notificationState,
              notificationNotifier,
            ),
            const SizedBox(height: 16),

            // Individual notification settings
            if (notificationState.isEnabled) ...[
              _buildNotificationToggle(
                context,
                theme,
                'Earnings Notifications',
                'Get notified when you receive earnings from deliveries',
                Icons.monetization_on,
                notificationState.earningsNotificationsEnabled,
                (value) => notificationNotifier.updateNotificationPreferences(
                  earningsNotificationsEnabled: value,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildNotificationToggle(
                context,
                theme,
                'Low Balance Alerts',
                'Receive alerts when your wallet balance is low',
                Icons.warning_amber,
                notificationState.lowBalanceAlertsEnabled,
                (value) => notificationNotifier.updateNotificationPreferences(
                  lowBalanceAlertsEnabled: value,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildNotificationToggle(
                context,
                theme,
                'Balance Updates',
                'Get notified about significant balance changes',
                Icons.account_balance_wallet,
                notificationState.balanceUpdatesEnabled,
                (value) => notificationNotifier.updateNotificationPreferences(
                  balanceUpdatesEnabled: value,
                ),
              ),
              const SizedBox(height: 12),
              
              _buildNotificationToggle(
                context,
                theme,
                'Withdrawal Updates',
                'Receive updates about your withdrawal requests',
                Icons.money,
                notificationState.withdrawalNotificationsEnabled,
                (value) => notificationNotifier.updateNotificationPreferences(
                  withdrawalNotificationsEnabled: value,
                ),
              ),
              const SizedBox(height: 24),

              // Low balance threshold setting
              if (notificationState.lowBalanceAlertsEnabled)
                _buildLowBalanceThresholdSetting(
                  context,
                  theme,
                  notificationState,
                  notificationNotifier,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMasterToggle(
    BuildContext context,
    ThemeData theme,
    DriverWalletNotificationState state,
    DriverWalletNotificationNotifier notifier,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: state.isEnabled
            ? theme.primaryColor.withValues(alpha: 0.1)
            : Colors.grey.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: state.isEnabled
              ? theme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            state.isEnabled ? Icons.notifications_active : Icons.notifications_off,
            color: state.isEnabled ? theme.primaryColor : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enable Wallet Notifications',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  state.isEnabled 
                      ? 'All wallet notifications are enabled'
                      : 'All wallet notifications are disabled',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: state.isEnabled,
            onChanged: (value) => notifier.setNotificationsEnabled(value),
            activeColor: theme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationToggle(
    BuildContext context,
    ThemeData theme,
    String title,
    String description,
    IconData icon,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      children: [
        Icon(
          icon,
          color: value ? theme.primaryColor : Colors.grey,
          size: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeColor: theme.primaryColor,
        ),
      ],
    );
  }

  Widget _buildLowBalanceThresholdSetting(
    BuildContext context,
    ThemeData theme,
    DriverWalletNotificationState state,
    DriverWalletNotificationNotifier notifier,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Low Balance Threshold',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Get alerted when your balance falls below this amount',
          style: theme.textTheme.bodySmall?.copyWith(
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Icon(Icons.warning_amber, color: Colors.orange),
                  const SizedBox(width: 8),
                  Text(
                    'RM ${state.lowBalanceThreshold.toStringAsFixed(2)}',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              Slider(
                value: state.lowBalanceThreshold,
                min: 5.0,
                max: 100.0,
                divisions: 19,
                label: 'RM ${state.lowBalanceThreshold.toStringAsFixed(2)}',
                onChanged: (value) {
                  notifier.updateNotificationPreferences(
                    lowBalanceThreshold: value,
                  );
                },
              ),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'RM 5.00',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    'RM 100.00',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Compact notification settings for driver dashboard
class DriverWalletNotificationQuickSettings extends ConsumerWidget {
  const DriverWalletNotificationQuickSettings({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationState = ref.watch(driverWalletNotificationProvider);
    final notificationNotifier = ref.read(driverWalletNotificationProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              notificationState.isEnabled 
                  ? Icons.notifications_active 
                  : Icons.notifications_off,
              color: notificationState.isEnabled 
                  ? theme.primaryColor 
                  : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Wallet Notifications',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Switch(
              value: notificationState.isEnabled,
              onChanged: (value) => notificationNotifier.setNotificationsEnabled(value),
              activeColor: theme.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}
