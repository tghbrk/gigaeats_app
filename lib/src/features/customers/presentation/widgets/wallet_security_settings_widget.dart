import 'package:flutter/material.dart';

/// Wallet security settings widget
class WalletSecuritySettingsWidget extends StatefulWidget {
  final bool pinEnabled;
  final bool biometricEnabled;
  final bool twoFactorEnabled;
  final Function(bool)? onPinToggle;
  final Function(bool)? onBiometricToggle;
  final Function(bool)? onTwoFactorToggle;
  final VoidCallback? onChangePin;

  const WalletSecuritySettingsWidget({
    super.key,
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.twoFactorEnabled,
    this.onPinToggle,
    this.onBiometricToggle,
    this.onTwoFactorToggle,
    this.onChangePin,
  });

  @override
  State<WalletSecuritySettingsWidget> createState() => _WalletSecuritySettingsWidgetState();
}

class _WalletSecuritySettingsWidgetState extends State<WalletSecuritySettingsWidget> {
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
                  Icons.security,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Security Settings',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // PIN Protection
            _SecuritySettingTile(
              title: 'PIN Protection',
              subtitle: 'Require PIN for wallet access',
              icon: Icons.pin,
              value: widget.pinEnabled,
              onChanged: widget.onPinToggle,
            ),
            
            if (widget.pinEnabled) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: TextButton(
                  onPressed: widget.onChangePin,
                  child: const Text('Change PIN'),
                ),
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Biometric Authentication
            _SecuritySettingTile(
              title: 'Biometric Authentication',
              subtitle: 'Use fingerprint or face recognition',
              icon: Icons.fingerprint,
              value: widget.biometricEnabled,
              onChanged: widget.onBiometricToggle,
            ),
            
            const SizedBox(height: 16),
            
            // Two-Factor Authentication
            _SecuritySettingTile(
              title: 'Two-Factor Authentication',
              subtitle: 'Extra security for transactions',
              icon: Icons.verified_user,
              value: widget.twoFactorEnabled,
              onChanged: widget.onTwoFactorToggle,
            ),
            
            const SizedBox(height: 16),
            
            // Security Tips
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
                        Icons.lightbulb_outline,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Security Tips',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Enable all security features for maximum protection\n'
                    '• Use a unique PIN that others cannot guess\n'
                    '• Never share your security credentials\n'
                    '• Regularly review your transaction history',
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

class _SecuritySettingTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final Function(bool)? onChanged;

  const _SecuritySettingTile({
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
