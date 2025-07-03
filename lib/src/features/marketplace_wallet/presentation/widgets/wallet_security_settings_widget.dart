import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../shared/widgets/loading_widget.dart';
import '../../../user_management/presentation/providers/customer_security_provider.dart';
import '../providers/customer_wallet_settings_provider.dart';
import 'wallet_security_dialogs.dart';

/// Comprehensive security settings widget for wallet
class WalletSecuritySettingsWidget extends ConsumerWidget {
  const WalletSecuritySettingsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(customerSecurityProvider);
    final settingsState = ref.watch(customerWalletSettingsProvider);

    if (securityState.isLoading || settingsState.isLoading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: LoadingWidget()),
        ),
      );
    }

    if (securityState.errorMessage != null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(
                Icons.error_outline,
                color: AppTheme.errorColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'Failed to load security settings',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                securityState.errorMessage!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(customerSecurityProvider.notifier).loadSecuritySettings();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final security = securityState.security;
    final settings = settingsState.settings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Security Settings',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // PIN Authentication Section
        _buildPinAuthenticationCard(context, ref, security),
        const SizedBox(height: 16),

        // Biometric Authentication Section
        BiometricAuthenticationWidget(
          // TODO: Restore when biometricEnabled is implemented in security model
          isEnabled: security?['biometricEnabled'] ?? false,
          onChanged: () {
            ref.read(customerSecurityProvider.notifier).loadSecuritySettings();
          },
        ),
        const SizedBox(height: 16),

        // Transaction Security Settings
        _buildTransactionSecurityCard(context, ref, settings),
        const SizedBox(height: 16),

        // Auto-lock Settings
        _buildAutoLockCard(context, ref, settings),
      ],
    );
  }

  Widget _buildPinAuthenticationCard(BuildContext context, WidgetRef ref, dynamic security) {
    final theme = Theme.of(context);
    final isPinEnabled = security?.pinEnabled ?? false;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.pin,
                  color: isPinEnabled ? AppTheme.primaryColor : Colors.grey,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PIN Authentication',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isPinEnabled 
                            ? 'PIN is set up for wallet transactions'
                            : 'Set up a PIN for wallet transactions',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isPinEnabled) ...[
                  TextButton(
                    onPressed: () => _showChangePinDialog(context),
                    child: const Text('Change'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => _showRemovePinDialog(context, ref),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.errorColor,
                    ),
                    child: const Text('Remove'),
                  ),
                ] else ...[
                  ElevatedButton(
                    onPressed: () => _showSetupPinDialog(context),
                    child: const Text('Set Up'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionSecurityCard(BuildContext context, WidgetRef ref, dynamic settings) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Security',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Require PIN for transactions
            SwitchListTile(
              title: const Text('Require PIN for transactions'),
              subtitle: const Text('Ask for PIN before processing any transaction'),
              value: settings?.requirePinForTransactions ?? false,
              onChanged: (value) {
                ref.read(customerWalletSettingsProvider.notifier)
                    .updateSecuritySettings({'requirePinForTransactions': value});
              },
              contentPadding: EdgeInsets.zero,
            ),

            // Require biometric for transactions
            SwitchListTile(
              title: const Text('Require biometric for transactions'),
              subtitle: const Text('Ask for biometric authentication before processing transactions'),
              value: settings?.enableBiometricAuth ?? false,
              onChanged: (value) {
                ref.read(customerWalletSettingsProvider.notifier)
                    .updateSecuritySettings({'enableBiometricAuth': value});
              },
              contentPadding: EdgeInsets.zero,
            ),

            const Divider(),

            // Large amount confirmation
            ListTile(
              title: const Text('Large amount confirmation'),
              subtitle: Text('Require confirmation for amounts above RM ${settings?.largeAmountThreshold?.toStringAsFixed(2) ?? '500.00'}'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showLargeAmountThresholdDialog(context, ref, settings?.largeAmountThreshold ?? 500.0),
              contentPadding: EdgeInsets.zero,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoLockCard(BuildContext context, WidgetRef ref, dynamic settings) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Auto-lock Settings',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            SwitchListTile(
              title: const Text('Auto-lock wallet'),
              subtitle: const Text('Automatically lock wallet after inactivity'),
              value: settings?.autoLockWallet ?? false,
              onChanged: (value) {
                ref.read(customerWalletSettingsProvider.notifier)
                    .updateSecuritySettings({'autoLockWallet': value});
              },
              contentPadding: EdgeInsets.zero,
            ),

            if (settings?.autoLockWallet ?? false) ...[
              const Divider(),
              ListTile(
                title: const Text('Auto-lock timeout'),
                subtitle: Text('Lock after ${_getTimeoutDisplayText(15)} of inactivity'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _showAutoLockTimeoutDialog(context, ref),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getTimeoutDisplayText(int minutes) {
    if (minutes < 60) {
      return '$minutes minutes';
    } else {
      final hours = minutes ~/ 60;
      final remainingMinutes = minutes % 60;
      if (remainingMinutes == 0) {
        return '$hours ${hours == 1 ? 'hour' : 'hours'}';
      } else {
        return '$hours ${hours == 1 ? 'hour' : 'hours'} $remainingMinutes minutes';
      }
    }
  }

  void _showSetupPinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PinSetupDialog(),
    );
  }

  void _showChangePinDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PinChangeDialog(),
    );
  }

  void _showRemovePinDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove your PIN? This will disable PIN authentication for wallet transactions.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                await ref.read(customerSecurityProvider.notifier).removePIN();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN removed successfully'),
                      backgroundColor: AppTheme.warningColor,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove PIN: ${e.toString()}'),
                      backgroundColor: AppTheme.errorColor,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showLargeAmountThresholdDialog(BuildContext context, WidgetRef ref, double currentThreshold) {
    final controller = TextEditingController(text: currentThreshold.toStringAsFixed(2));
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Large Amount Threshold'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Set the amount above which confirmation is required for transactions.'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Threshold Amount (RM)',
                prefixText: 'RM ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text);
              if (amount != null && amount > 0) {
                ref.read(customerWalletSettingsProvider.notifier)
                    .updateSecuritySettings({'largeAmountThreshold': amount});
                Navigator.of(context).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAutoLockTimeoutDialog(BuildContext context, WidgetRef ref) {
    // Implementation for auto-lock timeout dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Auto-lock timeout setting coming soon')),
    );
  }
}
