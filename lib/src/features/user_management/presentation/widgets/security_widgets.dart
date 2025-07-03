import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_theme.dart';
import '../providers/customer_security_provider.dart';
// TODO: Restore when customer_security.dart is implemented
// import '../../data/models/customer_security.dart';
import '../../data/services/biometric_auth_service.dart';

/// Security score card showing overall security level
class SecurityScoreCard extends ConsumerWidget {
  const SecurityScoreCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(customerSecurityProvider);
    final security = securityState.security;

    if (security == null) {
      return const SizedBox.shrink();
    }

    // TODO: Restore security.securityScore when provider is implemented - commented out for analyzer cleanup
    final score = security['securityScore'] ?? 0; // security.securityScore;
    final scoreColor = _getScoreColor(score);

    return Card(
      elevation: 4,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [scoreColor.withValues(alpha: 0.1), scoreColor.withValues(alpha: 0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.security,
                  color: scoreColor,
                  size: 28,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Security Score',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // TODO: Restore security.securityLevelDescription when provider is implemented - commented out for analyzer cleanup
                        security['securityLevelDescription'] ?? 'Security Level', // security.securityLevelDescription,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$score/100',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: score / 100,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Text(
              _getScoreDescription(score),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppTheme.successColor;
    if (score >= 60) return AppTheme.infoColor;
    if (score >= 40) return AppTheme.warningColor;
    return AppTheme.errorColor;
  }

  String _getScoreDescription(int score) {
    if (score >= 80) return 'Excellent security! Your wallet is well protected.';
    if (score >= 60) return 'Good security. Consider enabling additional features.';
    if (score >= 40) return 'Fair security. We recommend improving your settings.';
    return 'Poor security. Please enable security features to protect your wallet.';
  }
}

/// Biometric authentication settings card
class BiometricAuthenticationCard extends ConsumerWidget {
  const BiometricAuthenticationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(customerSecurityProvider);
    final security = securityState.security;
    final biometricAvailable = securityState.biometricAvailable;
    final availableBiometrics = securityState.availableBiometrics;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.fingerprint,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Biometric Authentication',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        biometricAvailable 
                            ? BiometricAuthHelper.getBiometricDisplayName(availableBiometrics)
                            : 'Not available on this device',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  // TODO: Restore security?.biometricEnabled when provider is implemented - commented out for analyzer cleanup
                  value: (security?['biometricEnabled'] ?? false) as bool, // security?.biometricEnabled ?? false,
                  onChanged: biometricAvailable ? (value) => _toggleBiometric(ref, value) : null,
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            if (!biometricAvailable) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.warningColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.warningColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_outlined,
                      color: AppTheme.warningColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Biometric authentication is not available on this device. Please set up fingerprint or face recognition in your device settings.',
                        style: TextStyle(
                          color: AppTheme.warningColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleBiometric(WidgetRef ref, bool enabled) async {
    try {
      if (enabled) {
        await ref.read(customerSecurityProvider.notifier).enableBiometric();
      } else {
        await ref.read(customerSecurityProvider.notifier).disableBiometric();
      }
    } catch (e) {
      // Error handling is done in the provider
    }
  }
}

/// PIN authentication settings card
class PINAuthenticationCard extends ConsumerWidget {
  const PINAuthenticationCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(customerSecurityProvider);
    final security = securityState.security;

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
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PIN Authentication',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // TODO: Restore security?.pinEnabled when provider is implemented - commented out for analyzer cleanup
                        (security?['pinEnabled'] ?? false) == true // security?.pinEnabled == true
                            ? 'PIN is set and active'
                            : 'Set a PIN for additional security',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  // TODO: Restore security?.pinEnabled when provider is implemented - commented out for analyzer cleanup
                  value: (security?['pinEnabled'] ?? false) as bool, // security?.pinEnabled ?? false,
                  onChanged: (value) => _togglePIN(context, ref, value),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            // TODO: Restore security?.pinEnabled when provider is implemented - commented out for analyzer cleanup
            if ((security?['pinEnabled'] ?? false) == true) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _changePIN(context, ref),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text('Change PIN'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _removePIN(context, ref),
                      icon: const Icon(Icons.delete, size: 16),
                      label: const Text('Remove PIN'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.errorColor,
                        side: BorderSide(color: AppTheme.errorColor),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _togglePIN(BuildContext context, WidgetRef ref, bool enabled) {
    if (enabled) {
      _setPIN(context, ref);
    } else {
      _removePIN(context, ref);
    }
  }

  void _setPIN(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SetPINDialog(
        onPINSet: (pin) async {
          try {
            await ref.read(customerSecurityProvider.notifier).setPIN(pin);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN set successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to set PIN: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _changePIN(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => ChangePINDialog(
        onPINChanged: (oldPin, newPin) async {
          try {
            // Verify old PIN first
            final isValid = await ref.read(customerSecurityProvider.notifier).verifyPIN(oldPin);
            if (!isValid) {
              throw Exception('Current PIN is incorrect');
            }
            
            // Set new PIN
            await ref.read(customerSecurityProvider.notifier).setPIN(newPin);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('PIN changed successfully'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to change PIN: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _removePIN(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove PIN'),
        content: const Text('Are you sure you want to remove your PIN? This will reduce your wallet security.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(customerSecurityProvider.notifier).removePIN();
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN removed successfully'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Failed to remove PIN: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}

/// Transaction security settings card
class TransactionSecurityCard extends ConsumerWidget {
  const TransactionSecurityCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(customerSecurityProvider);
    final security = securityState.security;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.payment,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Transaction Security',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // TODO: Restore security?.transactionPinRequired when provider is implemented - commented out for analyzer cleanup
                        (security?['transactionPinRequired'] ?? false) == true
                            ? 'PIN required for transactions above RM ${((security?['largeTransactionThreshold'] ?? 0) as double).toStringAsFixed(0)}'
                            : 'No additional security for transactions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  // TODO: Restore security?.transactionPinRequired when provider is implemented - commented out for analyzer cleanup
                  value: (security?['transactionPinRequired'] ?? false) as bool, // security?.transactionPinRequired ?? false,
                  onChanged: (value) => _toggleTransactionPIN(context, ref, value),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            // TODO: Restore security?.transactionPinRequired when provider is implemented - commented out for analyzer cleanup
            if ((security?['transactionPinRequired'] ?? false) == true) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _changeTransactionThreshold(context, ref),
                icon: const Icon(Icons.tune, size: 16),
                label: const Text('Change Threshold'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleTransactionPIN(BuildContext context, WidgetRef ref, bool enabled) {
    if (enabled) {
      _setTransactionThreshold(context, ref);
    } else {
      ref.read(customerSecurityProvider.notifier).disableTransactionPIN();
    }
  }

  void _setTransactionThreshold(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SetTransactionThresholdDialog(
        onThresholdSet: (threshold) async {
          try {
            await ref.read(customerSecurityProvider.notifier).enableTransactionPIN(threshold);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Transaction security enabled for amounts above RM ${threshold.toStringAsFixed(0)}'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to set transaction security: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _changeTransactionThreshold(BuildContext context, WidgetRef ref) {
    _setTransactionThreshold(context, ref);
  }
}

/// Auto-lock settings card
class AutoLockSettingsCard extends ConsumerWidget {
  const AutoLockSettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(customerSecurityProvider);
    final security = securityState.security;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lock_clock,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-lock',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // TODO: Restore security?.autoLockEnabled when provider is implemented - commented out for analyzer cleanup
                        (security?['autoLockEnabled'] ?? false) == true
                            ? 'Lock after ${((security?['autoLockTimeoutMinutes'] ?? 0) as int)} minutes of inactivity'
                            : 'App will not auto-lock',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  // TODO: Restore security?.autoLockEnabled when provider is implemented - commented out for analyzer cleanup
                  value: (security?['autoLockEnabled'] ?? false) as bool, // security?.autoLockEnabled ?? false,
                  onChanged: (value) => _toggleAutoLock(context, ref, value),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            // TODO: Restore security?.autoLockEnabled when provider is implemented - commented out for analyzer cleanup
            if ((security?['autoLockEnabled'] ?? false) == true) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _changeAutoLockTimeout(context, ref),
                icon: const Icon(Icons.timer, size: 16),
                label: const Text('Change Timeout'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _toggleAutoLock(BuildContext context, WidgetRef ref, bool enabled) {
    if (enabled) {
      _setAutoLockTimeout(context, ref);
    } else {
      ref.read(customerSecurityProvider.notifier).disableAutoLock();
    }
  }

  void _setAutoLockTimeout(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SetAutoLockTimeoutDialog(
        onTimeoutSet: (timeout) async {
          try {
            await ref.read(customerSecurityProvider.notifier).enableAutoLock(timeout);
            if (context.mounted) {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Auto-lock enabled with $timeout minute timeout'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to set auto-lock: $e'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  void _changeAutoLockTimeout(BuildContext context, WidgetRef ref) {
    _setAutoLockTimeout(context, ref);
  }
}

/// Multi-factor authentication settings card
class MFASettingsCard extends ConsumerWidget {
  const MFASettingsCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final securityState = ref.watch(customerSecurityProvider);
    final security = securityState.security;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.verified_user,
                  color: AppTheme.primaryColor,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Multi-Factor Authentication',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        // TODO: Restore security?.mfaEnabled when provider is implemented - commented out for analyzer cleanup
                        (security?['mfaEnabled'] ?? false) == true // security?.mfaEnabled == true
                            ? 'Additional verification for high-value transactions'
                            : 'Enhanced security for sensitive operations',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  // TODO: Restore security?.mfaEnabled when provider is implemented - commented out for analyzer cleanup
                  value: (security?['mfaEnabled'] ?? false) as bool, // security?.mfaEnabled ?? false,
                  onChanged: (value) => _toggleMFA(ref, value),
                  activeColor: AppTheme.primaryColor,
                ),
              ],
            ),
            // TODO: Restore security?.mfaEnabled when provider is implemented - commented out for analyzer cleanup
            if ((security?['mfaEnabled'] ?? false) != true) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.infoColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outlined,
                      color: AppTheme.infoColor,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MFA adds an extra layer of security by requiring additional verification for sensitive operations.',
                        style: TextStyle(
                          color: AppTheme.infoColor,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _toggleMFA(WidgetRef ref, bool enabled) async {
    try {
      if (enabled) {
        await ref.read(customerSecurityProvider.notifier).enableMFA();
      } else {
        await ref.read(customerSecurityProvider.notifier).disableMFA();
      }
    } catch (e) {
      // Error handling is done in the provider
    }
  }
}

/// Placeholder widgets for other security components
class PrivacyOverviewCard extends StatelessWidget {
  const PrivacyOverviewCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Privacy Overview - Coming Soon'),
      ),
    );
  }
}

class DataProtectionCard extends StatelessWidget {
  const DataProtectionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Data Protection Settings - Coming Soon'),
      ),
    );
  }
}

class DeviceManagementCard extends StatelessWidget {
  const DeviceManagementCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Device Management - Coming Soon'),
      ),
    );
  }
}

class LocationPrivacyCard extends StatelessWidget {
  const LocationPrivacyCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Location Privacy - Coming Soon'),
      ),
    );
  }
}

class CommunicationPreferencesCard extends StatelessWidget {
  const CommunicationPreferencesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Communication Preferences - Coming Soon'),
      ),
    );
  }
}

class SecurityActivityOverview extends StatelessWidget {
  const SecurityActivityOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Security Activity Overview - Coming Soon'),
      ),
    );
  }
}

class RecentSecurityEvents extends StatelessWidget {
  const RecentSecurityEvents({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Recent Security Events - Coming Soon'),
      ),
    );
  }
}

class SuspiciousActivityAlerts extends StatelessWidget {
  const SuspiciousActivityAlerts({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Suspicious Activity Alerts - Coming Soon'),
      ),
    );
  }
}

class SecurityRecommendations extends StatelessWidget {
  const SecurityRecommendations({super.key});

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Text('Security Recommendations - Coming Soon'),
      ),
    );
  }
}

/// Dialog for setting PIN
class SetPINDialog extends StatefulWidget {
  final Function(String) onPINSet;

  const SetPINDialog({super.key, required this.onPINSet});

  @override
  State<SetPINDialog> createState() => _SetPINDialogState();
}

class _SetPINDialogState extends State<SetPINDialog> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _pinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _pinController,
            decoration: InputDecoration(
              labelText: 'Enter PIN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscurePin ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscurePin = !_obscurePin),
              ),
            ),
            obscureText: _obscurePin,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPinController,
            decoration: InputDecoration(
              labelText: 'Confirm PIN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPin ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
              ),
            ),
            obscureText: _obscureConfirmPin,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndSetPIN,
          child: const Text('Set PIN'),
        ),
      ],
    );
  }

  void _validateAndSetPIN() {
    final pin = _pinController.text;
    final confirmPin = _confirmPinController.text;

    if (pin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PIN must be at least 4 digits')),
      );
      return;
    }

    if (pin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PINs do not match')),
      );
      return;
    }

    widget.onPINSet(pin);
  }
}

/// Dialog for changing PIN
class ChangePINDialog extends StatefulWidget {
  final Function(String, String) onPINChanged;

  const ChangePINDialog({super.key, required this.onPINChanged});

  @override
  State<ChangePINDialog> createState() => _ChangePINDialogState();
}

class _ChangePINDialogState extends State<ChangePINDialog> {
  final _currentPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  bool _obscureCurrentPin = true;
  bool _obscureNewPin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _currentPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Change PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _currentPinController,
            decoration: InputDecoration(
              labelText: 'Current PIN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureCurrentPin ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureCurrentPin = !_obscureCurrentPin),
              ),
            ),
            obscureText: _obscureCurrentPin,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _newPinController,
            decoration: InputDecoration(
              labelText: 'New PIN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureNewPin ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureNewPin = !_obscureNewPin),
              ),
            ),
            obscureText: _obscureNewPin,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _confirmPinController,
            decoration: InputDecoration(
              labelText: 'Confirm New PIN',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureConfirmPin ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
              ),
            ),
            obscureText: _obscureConfirmPin,
            keyboardType: TextInputType.number,
            maxLength: 6,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndChangePIN,
          child: const Text('Change PIN'),
        ),
      ],
    );
  }

  void _validateAndChangePIN() {
    final currentPin = _currentPinController.text;
    final newPin = _newPinController.text;
    final confirmPin = _confirmPinController.text;

    if (currentPin.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your current PIN')),
      );
      return;
    }

    if (newPin.length < 4) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN must be at least 4 digits')),
      );
      return;
    }

    if (newPin != confirmPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PINs do not match')),
      );
      return;
    }

    if (currentPin == newPin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New PIN must be different from current PIN')),
      );
      return;
    }

    widget.onPINChanged(currentPin, newPin);
  }
}

/// Dialog for setting transaction threshold
class SetTransactionThresholdDialog extends StatefulWidget {
  final Function(double) onThresholdSet;

  const SetTransactionThresholdDialog({super.key, required this.onThresholdSet});

  @override
  State<SetTransactionThresholdDialog> createState() => _SetTransactionThresholdDialogState();
}

class _SetTransactionThresholdDialogState extends State<SetTransactionThresholdDialog> {
  final _thresholdController = TextEditingController(text: '500');
  double _selectedThreshold = 500.0;

  @override
  void dispose() {
    _thresholdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Transaction Security Threshold'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'PIN will be required for transactions above this amount:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _thresholdController,
            decoration: const InputDecoration(
              labelText: 'Threshold Amount',
              prefixText: 'RM ',
              border: OutlineInputBorder(),
              helperText: 'Minimum: RM 50, Maximum: RM 10,000',
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: (value) {
              final amount = double.tryParse(value);
              if (amount != null) {
                setState(() => _selectedThreshold = amount);
              }
            },
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [100, 250, 500, 1000, 2500].map((amount) {
              return FilterChip(
                label: Text('RM $amount'),
                selected: _selectedThreshold == amount.toDouble(),
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedThreshold = amount.toDouble();
                      _thresholdController.text = amount.toString();
                    });
                  }
                },
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _validateAndSetThreshold,
          child: const Text('Set Threshold'),
        ),
      ],
    );
  }

  void _validateAndSetThreshold() {
    final threshold = double.tryParse(_thresholdController.text);

    if (threshold == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (threshold < 50) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Minimum threshold is RM 50')),
      );
      return;
    }

    if (threshold > 10000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum threshold is RM 10,000')),
      );
      return;
    }

    widget.onThresholdSet(threshold);
  }
}

/// Dialog for setting auto-lock timeout
class SetAutoLockTimeoutDialog extends StatefulWidget {
  final Function(int) onTimeoutSet;

  const SetAutoLockTimeoutDialog({super.key, required this.onTimeoutSet});

  @override
  State<SetAutoLockTimeoutDialog> createState() => _SetAutoLockTimeoutDialogState();
}

class _SetAutoLockTimeoutDialogState extends State<SetAutoLockTimeoutDialog> {
  int _selectedTimeout = 5;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Set Auto-lock Timeout'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'App will automatically lock after this period of inactivity:',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [1, 2, 5, 10, 15, 30].map((minutes) {
              return FilterChip(
                label: Text('$minutes min${minutes == 1 ? '' : 's'}'),
                selected: _selectedTimeout == minutes,
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _selectedTimeout = minutes);
                  }
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppTheme.infoColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outlined,
                  color: AppTheme.infoColor,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Shorter timeouts provide better security but may be less convenient.',
                    style: TextStyle(
                      color: AppTheme.infoColor,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
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
          onPressed: () => widget.onTimeoutSet(_selectedTimeout),
          child: const Text('Set Timeout'),
        ),
      ],
    );
  }
}

/// Security audit log card
class SecurityAuditLogCard extends StatelessWidget {
  // TODO: Restore when SecurityAuditLog is implemented
  final dynamic log; // was: SecurityAuditLog

  const SecurityAuditLogCard({super.key, required this.log});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final riskColor = _getRiskColor(log.riskLevel);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: riskColor.withValues(alpha: 0.1),
          child: Icon(
            _getEventIcon(log.eventType),
            color: riskColor,
            size: 20,
          ),
        ),
        title: Text(
          log.action,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(log.description),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  DateFormat('MMM dd, yyyy HH:mm').format(log.timestamp),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (log.deviceId != null) ...[
                  const SizedBox(width: 12),
                  Icon(
                    Icons.devices,
                    size: 12,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    log.deviceId!.substring(0, 8),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: riskColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            log.riskLevel.displayName,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: riskColor,
            ),
          ),
        ),
      ),
    );
  }

  // TODO: Restore when SecurityRiskLevel is implemented
  Color _getRiskColor(dynamic riskLevel) { // was: SecurityRiskLevel
    // switch (riskLevel) {
    //   case SecurityRiskLevel.low:
    //     return AppTheme.successColor;
    //   case SecurityRiskLevel.medium:
    //     return AppTheme.warningColor;
    //   case SecurityRiskLevel.high:
    //     return AppTheme.errorColor;
    //   case SecurityRiskLevel.critical:
    //     return Colors.red.shade800;
    // }
    return Colors.grey; // Default color placeholder
  }

  // TODO: Restore when SecurityEventType is implemented
  IconData _getEventIcon(dynamic eventType) { // was: SecurityEventType
    // switch (eventType) {
    //   case SecurityEventType.authentication:
    //     return Icons.login;
    //   case SecurityEventType.transaction:
    //     return Icons.payment;
    //   case SecurityEventType.settings:
    //     return Icons.settings;
    //   case SecurityEventType.device:
    //     return Icons.devices;
    //   case SecurityEventType.suspicious:
    //     return Icons.warning;
    // }
    return Icons.info; // Default icon placeholder
  }
}

/// Device info card
class DeviceInfoCard extends StatelessWidget {
  // TODO: Restore when DeviceInfo is implemented
  final dynamic device; // was: DeviceInfo

  const DeviceInfoCard({super.key, required this.device});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: device.isTrusted
              ? AppTheme.successColor.withValues(alpha: 0.1)
              : AppTheme.infoColor.withValues(alpha: 0.1),
          child: Icon(
            _getPlatformIcon(device.platform),
            color: device.isTrusted ? AppTheme.successColor : AppTheme.infoColor,
            size: 20,
          ),
        ),
        title: Text(
          device.displayName,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${device.platform} ${device.osVersion ?? ''}'),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.schedule,
                  size: 12,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 4),
                Text(
                  'Last seen: ${DateFormat('MMM dd, yyyy').format(device.lastSeen)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                if (device.isCurrent) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppTheme.successColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Current',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: device.isTrusted
            ? Icon(
                Icons.verified,
                color: AppTheme.successColor,
                size: 20,
              )
            : IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Show device options
                },
              ),
      ),
    );
  }

  IconData _getPlatformIcon(String platform) {
    switch (platform.toLowerCase()) {
      case 'android':
        return Icons.android;
      case 'ios':
        return Icons.phone_iphone;
      case 'web':
        return Icons.web;
      case 'windows':
        return Icons.desktop_windows;
      case 'macos':
        return Icons.desktop_mac;
      case 'linux':
        return Icons.computer;
      default:
        return Icons.device_unknown;
    }
  }
}
