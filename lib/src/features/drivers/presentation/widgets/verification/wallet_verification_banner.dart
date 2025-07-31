import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/driver_wallet.dart';

/// Banner widget that prompts users to verify their wallet when unverified
class WalletVerificationBanner extends StatelessWidget {
  final DriverWallet wallet;
  final VoidCallback? onDismiss;

  const WalletVerificationBanner({
    super.key,
    required this.wallet,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    // Only show banner if wallet is not verified
    if (wallet.isVerified) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 2,
        color: Colors.orange.shade50,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and dismiss button
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.shield_outlined,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Wallet Verification Required',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Verify your wallet to enable withdrawals',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.orange.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (onDismiss != null)
                    IconButton(
                      icon: Icon(
                        Icons.close,
                        color: Colors.orange.shade600,
                        size: 20,
                      ),
                      onPressed: onDismiss,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // Description
              Text(
                'To withdraw funds from your wallet, you need to complete the verification process. '
                'This helps us ensure secure transactions and comply with financial regulations.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.orange.shade700,
                ),
              ),

              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showVerificationInfo(context),
                      icon: const Icon(Icons.info_outline),
                      label: const Text('Learn More'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange.shade700,
                        side: BorderSide(color: Colors.orange.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () {
                        debugPrint('🚀 [WALLET-VERIFICATION-BANNER] Verify Now button pressed - navigating to /driver/wallet/verification');
                        context.push('/driver/wallet/verification');
                      },
                      icon: const Icon(Icons.verified_user),
                      label: const Text('Verify Now'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
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

  void _showVerificationInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Why Verify Your Wallet?'),
        content: const Text(
          'Wallet verification is required for:\n\n'
          '• Withdrawing funds to your bank account\n'
          '• Ensuring secure financial transactions\n'
          '• Complying with financial regulations\n'
          '• Protecting your earnings\n\n'
          'The verification process is quick and secure, typically taking 1-3 business days to complete.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
          FilledButton(
            onPressed: () {
              debugPrint('🚀 [WALLET-VERIFICATION-BANNER] Start Verification button pressed from dialog - navigating to /driver/wallet/verification');
              Navigator.of(context).pop();
              context.push('/driver/wallet/verification');
            },
            child: const Text('Start Verification'),
          ),
        ],
      ),
    );
  }
}
