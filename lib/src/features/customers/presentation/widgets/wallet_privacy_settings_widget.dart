import 'package:flutter/material.dart';

/// Wallet privacy settings widget
class WalletPrivacySettingsWidget extends StatefulWidget {
  final bool hideBalance;
  final bool hideTransactionHistory;
  final bool allowDataSharing;
  final bool allowAnalytics;
  final bool allowMarketing;
  final Function(bool)? onHideBalanceToggle;
  final Function(bool)? onHideTransactionHistoryToggle;
  final Function(bool)? onAllowDataSharingToggle;
  final Function(bool)? onAllowAnalyticsToggle;
  final Function(bool)? onAllowMarketingToggle;
  final VoidCallback? onExportData;
  final VoidCallback? onDeleteData;

  const WalletPrivacySettingsWidget({
    super.key,
    required this.hideBalance,
    required this.hideTransactionHistory,
    required this.allowDataSharing,
    required this.allowAnalytics,
    required this.allowMarketing,
    this.onHideBalanceToggle,
    this.onHideTransactionHistoryToggle,
    this.onAllowDataSharingToggle,
    this.onAllowAnalyticsToggle,
    this.onAllowMarketingToggle,
    this.onExportData,
    this.onDeleteData,
  });

  @override
  State<WalletPrivacySettingsWidget> createState() => _WalletPrivacySettingsWidgetState();
}

class _WalletPrivacySettingsWidgetState extends State<WalletPrivacySettingsWidget> {
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
                  Icons.privacy_tip,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Privacy Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Display Privacy Section
            Text(
              'Display Privacy',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            _PrivacySettingTile(
              title: 'Hide Wallet Balance',
              subtitle: 'Show *** instead of actual balance',
              icon: Icons.visibility_off,
              value: widget.hideBalance,
              onChanged: widget.onHideBalanceToggle,
            ),
            
            const SizedBox(height: 12),
            
            _PrivacySettingTile(
              title: 'Hide Transaction History',
              subtitle: 'Require authentication to view transactions',
              icon: Icons.history,
              value: widget.hideTransactionHistory,
              onChanged: widget.onHideTransactionHistoryToggle,
            ),
            
            const SizedBox(height: 24),
            
            // Data Privacy Section
            Text(
              'Data Privacy',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            _PrivacySettingTile(
              title: 'Allow Data Sharing',
              subtitle: 'Share anonymized data for service improvement',
              icon: Icons.share,
              value: widget.allowDataSharing,
              onChanged: widget.onAllowDataSharingToggle,
            ),
            
            const SizedBox(height: 12),
            
            _PrivacySettingTile(
              title: 'Allow Analytics',
              subtitle: 'Help us improve with usage analytics',
              icon: Icons.analytics,
              value: widget.allowAnalytics,
              onChanged: widget.onAllowAnalyticsToggle,
            ),
            
            const SizedBox(height: 12),
            
            _PrivacySettingTile(
              title: 'Allow Marketing Communications',
              subtitle: 'Receive personalized offers and updates',
              icon: Icons.campaign,
              value: widget.allowMarketing,
              onChanged: widget.onAllowMarketingToggle,
            ),
            
            const SizedBox(height: 24),
            
            // Data Management Section
            Text(
              'Data Management',
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            
            // Export Data Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onExportData,
                icon: const Icon(Icons.download),
                label: const Text('Export My Data'),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Delete Data Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _showDeleteDataDialog(context),
                icon: const Icon(Icons.delete_forever, color: Colors.red),
                label: const Text(
                  'Delete My Data',
                  style: TextStyle(color: Colors.red),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Privacy Policy Info
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
                        'Privacy Information',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your privacy is important to us. We only collect data necessary for providing our services. '
                    'You can review our Privacy Policy for detailed information about data handling.',
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      // TODO: Open privacy policy
                    },
                    child: const Text('View Privacy Policy'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDataDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete My Data'),
        content: const Text(
          'Are you sure you want to delete all your wallet data? '
          'This action cannot be undone and will permanently remove:\n\n'
          '• Transaction history\n'
          '• Wallet preferences\n'
          '• Analytics data\n'
          '• Saved payment methods\n\n'
          'Your wallet balance will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              widget.onDeleteData?.call();
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _PrivacySettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool)? onChanged;

  const _PrivacySettingTile({
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
