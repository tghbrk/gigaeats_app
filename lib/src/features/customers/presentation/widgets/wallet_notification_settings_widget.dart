import 'package:flutter/material.dart';

/// Wallet notification settings widget
class WalletNotificationSettingsWidget extends StatefulWidget {
  final bool transactionNotifications;
  final bool lowBalanceAlerts;
  final bool promotionalOffers;
  final bool securityAlerts;
  final double lowBalanceThreshold;
  final Function(bool)? onTransactionNotificationsToggle;
  final Function(bool)? onLowBalanceAlertsToggle;
  final Function(bool)? onPromotionalOffersToggle;
  final Function(bool)? onSecurityAlertsToggle;
  final Function(double)? onLowBalanceThresholdChanged;

  const WalletNotificationSettingsWidget({
    super.key,
    required this.transactionNotifications,
    required this.lowBalanceAlerts,
    required this.promotionalOffers,
    required this.securityAlerts,
    required this.lowBalanceThreshold,
    this.onTransactionNotificationsToggle,
    this.onLowBalanceAlertsToggle,
    this.onPromotionalOffersToggle,
    this.onSecurityAlertsToggle,
    this.onLowBalanceThresholdChanged,
  });

  @override
  State<WalletNotificationSettingsWidget> createState() => _WalletNotificationSettingsWidgetState();
}

class _WalletNotificationSettingsWidgetState extends State<WalletNotificationSettingsWidget> {
  late TextEditingController _thresholdController;

  @override
  void initState() {
    super.initState();
    _thresholdController = TextEditingController(
      text: widget.lowBalanceThreshold.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.notifications,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Notification Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Transaction Notifications
            _NotificationSettingTile(
              title: 'Transaction Notifications',
              subtitle: 'Get notified for all wallet transactions',
              icon: Icons.receipt,
              value: widget.transactionNotifications,
              onChanged: widget.onTransactionNotificationsToggle,
            ),
            
            const SizedBox(height: 16),
            
            // Low Balance Alerts
            _NotificationSettingTile(
              title: 'Low Balance Alerts',
              subtitle: 'Alert when balance falls below threshold',
              icon: Icons.warning,
              value: widget.lowBalanceAlerts,
              onChanged: widget.onLowBalanceAlertsToggle,
            ),
            
            if (widget.lowBalanceAlerts) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: Row(
                  children: [
                    Text(
                      'Threshold: RM ',
                      style: theme.textTheme.bodyMedium,
                    ),
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _thresholdController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 8,
                          ),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) {
                          final threshold = double.tryParse(value) ?? 0.0;
                          widget.onLowBalanceThresholdChanged?.call(threshold);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Security Alerts
            _NotificationSettingTile(
              title: 'Security Alerts',
              subtitle: 'Important security notifications',
              icon: Icons.security,
              value: widget.securityAlerts,
              onChanged: widget.onSecurityAlertsToggle,
            ),
            
            const SizedBox(height: 16),
            
            // Promotional Offers
            _NotificationSettingTile(
              title: 'Promotional Offers',
              subtitle: 'Deals and special offers',
              icon: Icons.local_offer,
              value: widget.promotionalOffers,
              onChanged: widget.onPromotionalOffersToggle,
            ),
            
            const SizedBox(height: 16),
            
            // Notification Preferences Info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Notification Preferences',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Security alerts cannot be disabled for your protection. '
                    'You can manage notification delivery methods in your device settings.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationSettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool)? onChanged;

  const _NotificationSettingTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 24,
          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
